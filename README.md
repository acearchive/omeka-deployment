# Omeka S Docker Template

Ace Archive will eventually be migrating its backend to [Omeka
S](https://omeka.org/s/). We deploy Omeka S using [this Docker
template](https://github.com/AM-Digital-Research-Environment/omeka-s-docker),
which is included here as a submodule. This repo additionally contains
project-specific configuration overlays.

## Caddy

This deployment uses a Caddy reverse proxy for TLS termination. You'll need to
install its [`Caddyfile`](./Caddyfile) when you set up the Omeka server.

## Custom vocabulary

Ace Archive uses a custom RDF vocabulary for a few key pieces of metadata that
the Data Connector needs to be able to interpret. This vocabulary is in
[`vocabulary.ttl`](./vocabulary.ttl), and you import it into Omeka from within
the application.

## Data Connector

The Data Connector is a sidecar service which talks to the Omeka API. See the
[acearchive/services](https://github.com/acearchive/services) repo for details.

To deploy the Data Connector, you must overlay
[`compose.connector.yaml`](./compose.connector.yaml) on top of the Omeka
compose file via the `COMPOSE_FILE` env var, as described in
[`./template/README.md`](/template/README.md).

You'll additionally need to set the `CONNECTOR_IMAGE` env var to point to the
Data Connector image in GHCR.
