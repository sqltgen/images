FROM mysql:8.0

# mysqldata/ is generated locally by generate-seed.sh (via `make seed-db-mysql`).
# It contains a fully-initialised MySQL data directory with the sqltgen user and
# database already created. Copying it in avoids running mysqld at build time,
# which is unreliable inside BuildKit's docker-container driver.
COPY --chown=mysql:mysql mysqldata/ /mysqldata/

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
