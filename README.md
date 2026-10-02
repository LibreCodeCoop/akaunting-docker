# Akaunting with Docker

Docker runtime and Compose configuration maintained by LibreCodeCoop for running [Akaunting](https://github.com/akaunting/akaunting/) with PHP-FPM and Nginx.

The repository publishes reusable PHP and Nginx runtime images to GHCR. The Akaunting application itself remains in `./volumes/akaunting`, so application data and source are independent from the runtime image lifecycle.

## Requirements

- Docker Engine
- Docker Compose v2 (`docker compose`)

## Quick start

Clone this repository, create your local Compose override from the example, and start the stack:

```bash
cp docker-compose.override.example.yml docker-compose.override.yml
docker compose pull
docker compose up -d
```

`docker-compose.override.yml` is intentionally ignored by Git. Docker Compose loads it automatically together with `docker-compose.yml`, so the normal workflow remains:

```bash
docker compose up -d
docker compose down
```

The example override adds the development/homologation services used by this project:

- Mailpit;
- OpenBao;
- OpenBao initialization for the `nfse` KV v2 mount;
- Dufs;
- local Composer and npm caches.

Because the local override is not versioned, each environment can change networks, external database settings, reverse-proxy configuration, ports, domains, or development services without modifying the repository.

Akaunting is installed into `volumes/akaunting` on the first start.

The runtime compatibility line is controlled by `RUNTIME_VERSION`. Akaunting 3 currently uses runtime line `3`:

```text
ghcr.io/librecodecoop/akaunting-docker-php:3
ghcr.io/librecodecoop/akaunting-docker-nginx:3
```

The exact Akaunting release used for a new installation is controlled separately by `AKAUNTING_VERSION`.

## Application version

The default application version is declared in `docker-compose.yml`:

```yaml
AKAUNTING_VERSION=${AKAUNTING_VERSION:-3.2.4}
```

Renovate monitors upstream Akaunting releases and proposes updates to this value.

Changing `AKAUNTING_VERSION` does **not** automatically upgrade an existing installation when the container restarts. This is intentional: upgrades are explicit operations.

To update an existing installation after reviewing and merging an Akaunting version update:

```bash
bash scripts/update-akaunting.sh
```

The update command checks out the selected Akaunting tag, applies the repository patch, refreshes Composer and frontend dependencies, runs Akaunting's update command and database migrations, and clears optimized caches.

If the patch no longer applies to a new upstream release, the update stops instead of continuing with a partially patched installation.

## Local Compose override

The repository intentionally does **not** version `docker-compose.override.yml`.

Use the tracked example as a starting point:

```bash
cp docker-compose.override.example.yml docker-compose.override.yml
```

Then edit `docker-compose.override.yml` for the local environment. Since Docker Compose loads this file automatically, no extra `-f` arguments are needed.

Typical local customizations include:

- external reverse-proxy networks;
- an external MySQL service;
- local domain names;
- host port mappings;
- OpenBao, Mailpit and Dufs settings;
- deployment-specific environment variables.

The tracked `docker-compose.override.example.yml` documents the supported development/homologation setup without forcing those choices on every checkout.

A root-level `.env` is optional and is used by Docker Compose to override variable defaults.

Akaunting keeps its own application environment file at:

```text
volumes/akaunting/.env
```

## Building the runtime locally

The default Compose file consumes published GHCR images and intentionally does not contain `build:` entries.

To test local runtime changes, build the images using the same names expected by Compose:

```bash
docker build \
  -t ghcr.io/librecodecoop/akaunting-docker-php:3 \
  .docker/php

docker build \
  --build-arg NGINX_CONF=http \
  -t ghcr.io/librecodecoop/akaunting-docker-nginx:3 \
  .docker/nginx

docker compose up -d
```

## Database

The base stack stores MySQL data in:

```text
volumes/mysql/data
```

SQL files placed in:

```text
volumes/mysql/dump
```

are made available to the MySQL image through `/docker-entrypoint-initdb.d`.

The MySQL port is not published on the host by default. If direct host access is required for development, expose it in `docker-compose.override.yml`.

To use an external database, override `DB_HOST`, credentials and networks as needed and disable the `akaunting.mysql` service in the local deployment configuration.

## Application patch

`patches/akaunting-modifications.patch` contains the patch distributed with this repository. Deployment-specific patches belong in `volumes/patches/`, which is ignored by Git and mounted read-only into the PHP container.

Patches are applied in two stages:

1. committed `patches/*.patch` files;
2. private deployment patches from `volumes/patches/*.patch`.

Both are applied automatically during first setup and explicit upgrades. Files under `volumes/patches/` are persistent local deployment state and are never versioned because the entire `volumes/` tree is ignored by Git. Removing a local patch file does not reverse a patch that is already present in the persistent Akaunting checkout; run `bash scripts/update-akaunting.sh` for the selected version to reset the upstream checkout and apply the current patch set again.

Do not manually `git pull` the Akaunting `master` branch inside `volumes/akaunting`. The installation is intentionally tied to the release selected by `AKAUNTING_VERSION`.

## Dependency updates

Dependency maintenance is split deliberately:

- **Renovate** updates only `AKAUNTING_VERSION`;
- **Dependabot** updates Docker Compose images, Dockerfile images and GitHub Actions.

Docker base images are pinned by immutable digest while retaining a readable tag. Dependabot can update the tag/digest pair when a supported update is available.

PHP stays on the Akaunting-supported 8.3 line unless compatibility is intentionally reviewed. Node.js stays on the upstream-supported Node 20 line.

## Continuous integration

Pull requests run two kinds of validation:

1. runtime image builds;
2. an integration smoke test that:
   - validates Compose and scripts;
   - builds the branch PHP and Nginx images;
   - installs the selected Akaunting release;
   - verifies that the patch applies;
   - starts the stack and checks the HTTP endpoint.

This is especially important for automated Akaunting and dependency update pull requests.

## Troubleshooting

Inspect the effective Compose configuration:

```bash
docker compose config
```

Inspect container state and logs:

```bash
docker compose ps
docker compose logs
```

