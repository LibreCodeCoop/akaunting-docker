# Optional OpenBao setup

OpenBao is not required by Akaunting itself. This repository keeps it as an
optional deployment extension for LibreCode-managed services such as the NFS-e
module.

The optional stack uses OpenBao 2.7.1 with PebbleDB and Static Key Auto Unseal.
After the one-time bootstrap, normal container and VPS restarts do not require
manual unseal shares.

## Enable the optional Compose configuration

Use the OpenBao example as the local Compose override:

```bash
cp docker-compose.openbao.example.yml docker-compose.override.yml
install -d -m 700 secrets
install -d -m 700 -o 100 -g 100 volumes/openbao
```

Create the 32-byte static seal key:

```bash
(
  umask 077
  openssl rand -out secrets/openbao_static_seal_key 32
)
chmod 0444 secrets/openbao_static_seal_key
test "$(wc -c < secrets/openbao_static_seal_key)" -eq 32
```

Keep a separate recovery copy of this key outside the VPS. Do not store it in
the same backup object as `volumes/openbao`.

## First initialization

Start only OpenBao:

```bash
docker compose up -d openbao
```

Initialize it exactly once:

```bash
docker compose exec openbao \
  bao operator init \
  -recovery-shares=1 \
  -recovery-threshold=1
```

Store the recovery key and initial root token outside the VPS. Then configure
the required KV v2 mount and application authentication. AppRole is recommended
for production.

For the NFS-e module, use the module documentation for its `nfse` KV mount,
policy, and AppRole configuration.

## Normal restart and update

No manual unseal command is required after the initial setup:

```bash
docker compose up -d
docker compose exec openbao bao status
```

Expected state:

```text
Initialized     true
Sealed          false
```

The static key file and `volumes/openbao` are both required for recovery. A
copy of the data directory alone does not include the static seal key.

## Existing Shamir deployments

Do not reinitialize an existing OpenBao data directory. Migrating an existing
Shamir deployment to Static Key Auto Unseal is a one-time seal migration and
requires a verified backup before running `bao operator unseal -migrate`.

Perform that migration separately from an Akaunting application update.
