# TimescaleDB extension image for CloudNativePG ImageVolume
#
# Follows the postgres-extensions-containers pattern:
# https://github.com/cloudnative-pg/postgres-extensions-containers
#
# Produces a FROM scratch image containing only the TimescaleDB
# extension files (.so + .control + .sql), mountable via Kubernetes
# ImageVolume into a CNPG minimal PostgreSQL pod.

ARG BASE=ghcr.io/cloudnative-pg/postgresql:18-minimal-trixie
FROM $BASE AS builder

ARG PG_MAJOR=18
ARG EXT_VERSION

USER 0

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        "postgresql-${PG_MAJOR}-timescaledb=${EXT_VERSION}" && \
    rm -rf /var/lib/apt/lists/*

FROM scratch
ARG PG_MAJOR=18

# Licenses
COPY --from=builder /usr/share/doc/postgresql-${PG_MAJOR}-timescaledb/copyright /licenses/postgresql-${PG_MAJOR}-timescaledb/

# Shared libraries
COPY --from=builder /usr/lib/postgresql/${PG_MAJOR}/lib/timescaledb*.so /lib/

# Extension control + SQL files
COPY --from=builder /usr/share/postgresql/${PG_MAJOR}/extension/timescaledb* /share/extension/

USER 65532:65532
