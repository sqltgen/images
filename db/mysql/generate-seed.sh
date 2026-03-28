#!/usr/bin/env bash
# Generates the MySQL data directory by running mysqld in a regular container,
# then copies the result into db/mysql/mysqldata/ for use by the Dockerfile COPY.
#
# Run this script before building the image:
#   make seed-db-mysql
#   make build-db-mysql
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONTAINER=mysql-seed

# Clean up any leftover container from a previous failed run
docker rm -f "$CONTAINER" 2>/dev/null || true

docker run --name "$CONTAINER" mysql:8.0 bash -c "
  set -euo pipefail
  mkdir -p /mysqldata && chown mysql:mysql /mysqldata
  mysqld --initialize-insecure --datadir=/mysqldata --user=mysql \
         --lc-messages-dir=/usr/share/mysql-8.0/english
  mysqld --datadir=/mysqldata --user=mysql --skip-networking \
         --lc-messages-dir=/usr/share/mysql-8.0/english &
  until mysqladmin -u root ping --silent 2>/dev/null; do sleep 0.1; done
  mysql -u root -p'' -e \"ALTER USER 'root'@'localhost' IDENTIFIED BY 'sqltgen_root';\"
  mysql -u root -psqltgen_root -e \"CREATE USER 'root'@'%' IDENTIFIED BY 'sqltgen_root';\"
  mysql -u root -psqltgen_root -e \"GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;\"
  mysql -u root -psqltgen_root -e \"CREATE USER 'sqltgen'@'%' IDENTIFIED BY 'sqltgen';\"
  mysql -u root -psqltgen_root -e \"CREATE DATABASE sqltgen;\"
  mysql -u root -psqltgen_root -e \"GRANT ALL PRIVILEGES ON *.* TO 'sqltgen'@'%' WITH GRANT OPTION;\"
  mysql -u root -psqltgen_root -e \"FLUSH PRIVILEGES;\"
  mysqladmin -u root -psqltgen_root shutdown
  wait
"

rm -rf "$SCRIPT_DIR/mysqldata"
docker cp "$CONTAINER":/mysqldata "$SCRIPT_DIR/mysqldata"
docker rm "$CONTAINER"

echo "Seed data written to $SCRIPT_DIR/mysqldata"
