FROM golang:1.23-alpine

RUN apk add --no-cache make

# Pre-populate the module cache ($GOPATH/pkg/mod) by downloading exactly the
# modules each example needs. We copy the real go.mod+go.sum from each example
# (renamed to avoid collisions) and run "go mod download all" against each, so
# the cached versions match what the examples' go.sum files require.
WORKDIR /warmup/postgresql
COPY postgresql.mod go.mod
COPY postgresql.sum go.sum
RUN go mod download all

WORKDIR /warmup/sqlite
COPY sqlite.mod go.mod
COPY sqlite.sum go.sum
RUN go mod download all
