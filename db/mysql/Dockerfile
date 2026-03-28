FROM mysql:8.0

# Use a path outside the VOLUME declared by the base image (/var/lib/mysql),
# otherwise Docker discards RUN writes to that path at build time.
#
# BuildKit's docker-container driver runs with no locale set. Without an
# explicit locale, mysqld looks for errmsg.sys directly in lc-messages-dir
# instead of the english/ subdir. Passing --lc-messages-dir and --lc-messages
# explicitly avoids any dependence on the OS locale environment.
RUN mkdir -p /mysqldata && chown mysql:mysql /mysqldata && \
    ls /usr/share/mysql-8.0/ && \
    mysqld --initialize-insecure --datadir=/mysqldata --user=mysql \
           --lc-messages-dir=/usr/share/mysql-8.0 --lc-messages=en_US && \
    mysqld --datadir=/mysqldata --user=mysql --skip-networking \
           --lc-messages-dir=/usr/share/mysql-8.0 --lc-messages=en_US & \
    until mysqladmin -u root ping --silent 2>/dev/null; do sleep 0.1; done && \
    mysql -u root -p"" -e "ALTER USER 'root'@'localhost' IDENTIFIED BY 'sqltgen_root';" && \
    mysql -u root -psqltgen_root -e "CREATE USER 'root'@'%' IDENTIFIED BY 'sqltgen_root';" && \
    mysql -u root -psqltgen_root -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;" && \
    mysql -u root -psqltgen_root -e "CREATE USER 'sqltgen'@'%' IDENTIFIED BY 'sqltgen';" && \
    mysql -u root -psqltgen_root -e "CREATE DATABASE sqltgen;" && \
    mysql -u root -psqltgen_root -e "GRANT ALL PRIVILEGES ON *.* TO 'sqltgen'@'%' WITH GRANT OPTION;" && \
    mysql -u root -psqltgen_root -e "FLUSH PRIVILEGES;" && \
    mysqladmin -u root -psqltgen_root shutdown && \
    wait

# Pass --datadir so the official entrypoint finds the pre-initialised data
# instead of defaulting to the empty /var/lib/mysql VOLUME.
# Remaining flags are test-optimised performance settings.
CMD ["--datadir=/mysqldata", \
     "--innodb-flush-log-at-trx-commit=0", \
     "--innodb-doublewrite=0", \
     "--innodb-buffer-pool-size=8M", \
     "--skip-ssl", \
     "--skip-log-bin", \
     "--skip-performance-schema", \
     "--skip-name-resolve"]
