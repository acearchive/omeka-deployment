# Omeka S Deployment Template

Ace Archive uses a collection management system called [Omeka
S](https://omeka.org/s/) on the backend. We deploy Omeka S using [this Docker
template](https://github.com/AM-Digital-Research-Environment/omeka-s-docker),
which is included here as a submodule, pinned to the commit we have deployed.
This repo additionally contains project-specific configuration overlays.

## Omeka

We use the [Homosaurus](https://homosaurus.org/) vocabulary via the [Value
Suggest](https://omeka.org/s/docs/user-manual/modules/valuesuggest/) module.
This module needs to be installed by following the instructions in
[`./template/README.md`](/template/README.md). The Homosaurus v5 vocabulary is
included with the module by default.

## Caddy

This deployment uses a Caddy reverse proxy for TLS termination. You'll need to
install Caddy and its [`Caddyfile`](./Caddyfile) when you set up the Omeka
server.

## Custom vocabulary

Ace Archive uses a custom RDF vocabulary for a few key pieces of metadata that
the Data Connector needs to be able to interpret. This vocabulary is in
[`vocabulary.ttl`](./vocabulary.ttl), and you import it into Omeka from within
the application.

## Data Connector

The Data Connector is a sidecar service which talks to the Omeka API. See the
[acearchive/services](https://github.com/acearchive/services) repo for details.

To deploy the Data Connector, you must overlay
[`compose.acearchive.yml`](./compose.acearchive.yml) on top of the Omeka
compose file via the `COMPOSE_FILE` env var, as described in
[`./template/README.md`](/template/README.md).

You'll additionally need to set the `ACEARCHIVE_CONNECTOR_IMAGE` env var to
point to the Data Connector image in GHCR.

## Backups

Nightly backups are uploaded to a Cloudflare R2 bucket by a systemd timer.
Bucket lifecycle rules automatically prune old backups, and bucket locks
prevent backups from being overwritten or deleted prematurely.

The systemd timer pings [Healthchecks.io](https://healthchecks.io) on success.
If a backup fails or doesn't run on a given day, that service notifies us.

To set up backups, the server must have the following tools installed:

- `curl`
- [Nushell](https://www.nushell.sh/book/installation.html)
- [rclone](https://rclone.org/install/)

Then you must create `/etc/omeka-backup.env` with mode `0600` to store env vars
for the systemd timer and backup script.

```sh
BACKUP_BUCKET=
HEALTHCHECK_PING_URL=
RCLONE_CONFIG_R2_TYPE=s3
RCLONE_CONFIG_R2_PROVIDER=Cloudflare
RCLONE_CONFIG_R2_ENDPOINT=
RCLONE_CONFIG_R2_ACCESS_KEY_ID=
RCLONE_CONFIG_R2_SECRET_ACCESS_KEY=
RCLONE_CONFIG_R2_NO_CHECK_BUCKET=true
```

Then install and start the systemd timer. The timer expects this repo to be
cloned to `/root/omeka`.

```sh
cp ./omeka-backup.service ./omeka-backup.timer /etc/systemd/system/
systemctl daemon-reload
systemctl enable --now omeka-backup.timer
```

## Analytics

We collect privacy-preserving analytics via a self-hosted instance of
[Umami](https://umami.is/), hosted at <https://umami.acearchive.lgbt>.

To deploy Umami, you must overlay [`compose.umami.yml`](./compose.umami.yml) on
top of the Omeka compose file via the `COMPOSE_FILE` env var, as described in
[`./template/README.md`](/template/README.md).

You'll additionally need to set the `UMAMI_APP_SECRET` and
`UMAMI_TWO_FACTOR_ENCRYPTION_KEY` env vars.

## Configuration

To deploy Omeka, the Omeka Data Connector, and Umami, you'll need to set the
following environment variables in the `.env` file in the docker template.

```sh
# Use a strong, random secret. (e.g. `openssl rand -hex 32`)
MYSQL_PASSWORD=
NGINX_PORT=8080
OMEKA_TZ=America/New_York
OMEKA_LOCALE=en_US
OMEKA_TITLE="Ace Archive"
SERVER_NAME=omeka.acearchive.lgbt
COMPOSE_FILE=docker-compose.yml:compose.immutable.yml:../compose.acearchive.yml:../compose.umami.yml
# In an actual deployment, always pin to a specific commit.
ACEARCHIVE_CONNECTOR_IMAGE=ghcr.io/acearchive/omeka-connector:latest
# Use a strong, random secret. (e.g. `openssl rand -hex 32`)
UMAMI_APP_SECRET=
# Use a strong, random secret. (e.g. `openssl rand -hex 32`)
UMAMI_TWO_FACTOR_ENCRYPTION_KEY=
```
