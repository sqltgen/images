FROM rust:slim

# System libs required by sqlx (native-tls + postgres + sqlite drivers).
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        make pkg-config libssl-dev libpq-dev libsqlite3-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Pre-fetch and compile all example dependencies.
# The compiled artifacts stay in the image so CI skips recompiling unchanged deps.
# Uses the dummy-source pattern: compile once, then remove the source fingerprint
# so cargo doesn't consider the warmup crate "up to date" for the real projects.
WORKDIR /warmup
COPY Cargo.toml .
RUN mkdir src && echo 'fn main() {}' > src/main.rs && \
    cargo build --release && \
    rm -rf src target/release/.fingerprint/sqltgen-examples-warmup

# Pre-populate the sparse registry index for ALL packages in each example's
# Cargo.lock, including Windows-only platform crates that cargo build skips on
# Linux. Without this, offline builds fail even though the Linux .crate files
# are already cached.
WORKDIR /fetch/postgresql
COPY postgresql.toml Cargo.toml
COPY postgresql.lock Cargo.lock
RUN mkdir src && echo 'fn main() {}' > src/main.rs && cargo fetch

WORKDIR /fetch/sqlite
COPY sqlite.toml Cargo.toml
COPY sqlite.lock Cargo.lock
RUN mkdir src && echo 'fn main() {}' > src/main.rs && cargo fetch

WORKDIR /fetch/mysql
COPY mysql.toml Cargo.toml
COPY mysql.lock Cargo.lock
RUN mkdir src && echo 'fn main() {}' > src/main.rs && cargo fetch
