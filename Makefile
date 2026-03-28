REGISTRY := ghcr.io/sqltgen
TAG      := local

SQLTGEN  ?= ../sqltgen

.PHONY: build-all build-dev-node build-dev-python build-dev-jvm build-dev-go build-dev-rust build-db-postgres build-db-mysql
.PHONY: test-all  test-dev-node  test-dev-python  test-dev-jvm  test-dev-go  test-dev-rust  test-db-postgres  test-db-mysql
.PHONY: verify-node verify-python verify-jvm verify-go verify-rust
.PHONY: ci-build

# ── CI build simulation ────────────────────────────────────────────────────────
# Builds one image using the docker-container BuildKit driver, which matches
# what GitHub Actions uses. Catches issues that the default local driver hides.
#
# Usage:
#   make ci-build IMAGE=db/mysql
#   make ci-build IMAGE=toolchain/rust

IMAGE ?= (set IMAGE to a context path, e.g. db/mysql)

ci-build:
	docker buildx create --name ci-builder --driver docker-container --use
	docker buildx build --load -t $(REGISTRY)/$(subst /,-,$(IMAGE)):$(TAG) $(IMAGE); \
	  docker buildx rm ci-builder

# ── Build ──────────────────────────────────────────────────────────────────────

build-all: build-dev-node build-dev-python build-dev-jvm build-dev-go build-dev-rust build-db-postgres build-db-mysql

build-dev-node:
	docker build -t $(REGISTRY)/dev-node:$(TAG) toolchain/node

build-dev-python:
	docker build -t $(REGISTRY)/dev-python:$(TAG) toolchain/python

build-dev-jvm:
	docker build -t $(REGISTRY)/dev-jvm:$(TAG) toolchain/jvm

build-dev-go:
	docker build -t $(REGISTRY)/dev-go:$(TAG) toolchain/go

build-dev-rust:
	docker build -t $(REGISTRY)/dev-rust:$(TAG) toolchain/rust

build-db-postgres:
	docker build -t $(REGISTRY)/db-postgres:$(TAG) db/postgres

build-db-mysql:
	docker build -t $(REGISTRY)/db-mysql:$(TAG) db/mysql

# ── Smoke test ─────────────────────────────────────────────────────────────────
# Verifies the image starts and the expected toolchain is present.

test-all: test-dev-node test-dev-python test-dev-jvm test-dev-go test-dev-rust test-db-postgres test-db-mysql

test-dev-node:
	docker run --rm $(REGISTRY)/dev-node:$(TAG) sh -c "node --version && npm --version"

test-dev-python:
	docker run --rm $(REGISTRY)/dev-python:$(TAG) sh -c "python3 --version && pip3 --version"

test-dev-jvm:
	docker run --rm $(REGISTRY)/dev-jvm:$(TAG) sh -c "java --version && mvn --version"

test-dev-go:
	docker run --rm $(REGISTRY)/dev-go:$(TAG) go version

test-dev-rust:
	docker run --rm $(REGISTRY)/dev-rust:$(TAG) sh -c "rustc --version && cargo --version"

test-db-postgres:
	docker run -d --name pg-smoke -p 5432:5432 $(REGISTRY)/db-postgres:$(TAG)
	@until docker exec pg-smoke pg_isready -U sqltgen -q; do sleep 0.1; done
	docker exec pg-smoke psql -U sqltgen -c "SELECT 1;"
	docker rm -f pg-smoke

test-db-mysql:
	docker run -d --name mysql-smoke -p 3306:3306 $(REGISTRY)/db-mysql:$(TAG)
	@until docker exec mysql-smoke mysqladmin ping -u sqltgen -psqltgen --silent 2>/dev/null; do sleep 0.2; done
	docker exec mysql-smoke mysql -u sqltgen -psqltgen -e "SELECT 1;"
	docker rm -f mysql-smoke

# ── Cache verification ─────────────────────────────────────────────────────────
# Runs the package install with --network=none to confirm the pre-warmed cache
# in the image is sufficient. Mount an actual example to get real manifests.
#
# Usage:
#   make verify-node    EXAMPLE=examples/typescript/postgresql
#   make verify-python  EXAMPLE=examples/python/postgresql
#   make verify-jvm     EXAMPLE=examples/java/postgresql
#   make verify-go      EXAMPLE=examples/go/postgresql
#   make verify-rust    EXAMPLE=examples/rust/postgresql

EXAMPLE ?= (set EXAMPLE to a path under $(SQLTGEN))

verify-node:
	docker run --rm --network=none \
	  -v $(abspath $(SQLTGEN)/$(EXAMPLE)):/work -w /work \
	  $(REGISTRY)/dev-node:$(TAG) \
	  npm install

verify-python:
	docker run --rm --network=none \
	  -v $(abspath $(SQLTGEN)/$(EXAMPLE)):/work -w /work \
	  $(REGISTRY)/dev-python:$(TAG) \
	  pip install -r requirements.txt --no-index --find-links /root/.cache/pip/wheels

verify-jvm:
	docker run --rm --network=none \
	  -v $(abspath $(SQLTGEN)/$(EXAMPLE)):/work -w /work \
	  $(REGISTRY)/dev-jvm:$(TAG) \
	  mvn dependency:go-offline -q

verify-go:
	docker run --rm --network=none \
	  -v $(abspath $(SQLTGEN)/$(EXAMPLE)):/work -w /work \
	  -e GOFLAGS=-mod=mod \
	  -e GONOSUMDB='*' \
	  $(REGISTRY)/dev-go:$(TAG) \
	  go mod download all

verify-rust:
	docker run --rm --network=none \
	  -v $(abspath $(SQLTGEN)):/sqltgen -w /sqltgen/$(EXAMPLE) \
	  $(REGISTRY)/dev-rust:$(TAG) \
	  cargo build --offline 2>&1 | grep -v "^warning:"
