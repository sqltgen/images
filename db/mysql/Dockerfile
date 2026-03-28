FROM mysql:8.0

# Use a path outside the VOLUME declared by the base image (/var/lib/mysql),
# otherwise Docker discards RUN writes to that path at build time.
# Initialize and create the sqltgen user/database WITHOUT any custom config
# so that MySQL can find its own message files in BuildKit's environment.
RUN mkdir -p /mysqldata && chown mysql:mysql /mysqldata && \
    mysqld --initialize-insecure --datadir=/mysqldata --user=mysql --lc-messages=en_US && \
    mysqld --datadir=/mysqldata --user=mysql --lc-messages=en_US --skip-networking & \
    until mysqladmin -u root ping --silent 2>/dev/null; do sleep 0.2; done && \
    mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED BY 'sqltgen_root';" && \
    mysql -u root -psqltgen_root -e "CREATE USER 'root'@'%' IDENTIFIED BY 'sqltgen_root';" && \
    mysql -u root -psqltgen_root -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;" && \
    mysql -u root -psqltgen_root -e "CREATE USER 'sqltgen'@'%' IDENTIFIED BY 'sqltgen';" && \
    mysql -u root -psqltgen_root -e "CREATE DATABASE sqltgen;" && \
    mysql -u root -psqltgen_root -e "GRANT ALL PRIVILEGES ON sqltgen.* TO 'sqltgen'@'%';" && \
    mysqladmin -u root -psqltgen_root shutdown && \
    wait

# Bake test-optimised settings after initialization so they don't interfere
# with mysqld's ability to locate its own message files during --initialize.
COPY sqltgen-perf.cnf /etc/mysql/conf.d/sqltgen-perf.cnf
