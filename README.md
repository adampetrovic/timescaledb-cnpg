# timescaledb-cnpg

TimescaleDB extension image for [CloudNativePG](https://cloudnative-pg.io) `ImageVolume`.

Minimal `FROM scratch` image containing only the TimescaleDB shared libraries (`.so`), extension control file, and SQL migration scripts — mountable via Kubernetes [ImageVolume](https://kubernetes.io/docs/concepts/storage/volumes/#image) into a CNPG PostgreSQL pod.

## Usage

Requires:
- Kubernetes ≥ 1.33 with `ImageVolume` feature gate enabled (GA in 1.35+)
- CloudNativePG ≥ 1.27
- PostgreSQL 18 (for `extension_control_path` GUC)

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: my-cluster
spec:
  imageName: ghcr.io/cloudnative-pg/postgresql:18-minimal-trixie
  instances: 1
  storage:
    size: 10Gi

  postgresql:
    extensions:
      - name: timescaledb
        image:
          reference: ghcr.io/adampetrovic/timescaledb-cnpg:2.26.1-18-trixie
    shared_preload_libraries:
      - timescaledb
    parameters:
      timescaledb.telemetry_level: "off"
---
apiVersion: postgresql.cnpg.io/v1
kind: Database
metadata:
  name: my-cluster-app
spec:
  name: app
  owner: app
  cluster:
    name: my-cluster
  extensions:
    - name: timescaledb
      version: "2.26.1"
```

## How it works

Follows the pattern from [postgres-extensions-containers](https://github.com/cloudnative-pg/postgres-extensions-containers):

1. Installs `postgresql-18-timescaledb` from the [PGDG apt repository](https://apt.postgresql.org) into a builder stage
2. Copies only the extension files into a `FROM scratch` image:
   - `/lib/timescaledb*.so` — shared libraries
   - `/share/extension/timescaledb*` — control file + SQL scripts
   - `/licenses/` — copyright and notice files
3. CNPG mounts the image via `ImageVolume` at `/extensions/timescaledb` and configures `extension_control_path` to find the files

## Automated updates

[Renovate](https://github.com/renovatebot/renovate) monitors the PGDG apt repository for new `postgresql-18-timescaledb` package versions and opens auto-merge PRs. On merge, GitHub Actions builds and publishes the updated image.

## Image tags

Tags follow the CNPG extension convention:

```
ghcr.io/adampetrovic/timescaledb-cnpg:<tsdb_version>-<pg_major>-<debian_codename>
```

Example: `ghcr.io/adampetrovic/timescaledb-cnpg:2.26.1-18-trixie`
