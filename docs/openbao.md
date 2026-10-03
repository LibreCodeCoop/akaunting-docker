# Optional OpenBao setup

OpenBao is not required by Akaunting itself. This repository keeps it as an
optional deployment extension for LibreCode-managed services such as the NFS-e
module.

The optional stack uses OpenBao 2.7.1 with PebbleDB and Static Key Auto Unseal.
After the one-time bootstrap, normal container and VPS restarts do not require
manual unseal shares.

## Enable the optional Compose configuration

Use the OpenBao example as the local Compose override, or merge its OpenBao
service/network/secret sections into an existing deployment-specific override:

```bash
cp docker-compose.openbao.example.yml docker-compose.override.yml
```

If the deployment already has its own `docker-compose.override.yml` (for
example an external MySQL network), keep those local settings and add only the
OpenBao-specific sections.

## Recommended first bootstrap

For a new OpenBao installation, run:

```bash
bash scripts/bootstrap-openbao.sh
```

The bootstrap script:

1. validates that `deploy/openbao/openbao.hcl` is a regular file with PebbleDB
   storage configured;
2. creates `secrets/openbao_static_seal_key` when it does not already exist;
3. creates the persistent `volumes/openbao` data directory;
4. starts OpenBao;
5. initializes OpenBao exactly once when the storage is new;
6. enables the `nfse` KV v2 mount;
7. enables AppRole;
8. creates the restricted `nfse` policy and role;
9. prints the Role ID and a new Secret ID for the Akaunting NFS-e module;
10. restarts OpenBao and verifies that Static Key Auto Unseal returns it as
    initialized and unsealed.

On a brand-new installation, the OpenBao initialization output includes the
recovery key and initial root token. Store both outside the VPS before
continuing.

If the script is rerun against an already initialized OpenBao, it asks for a
root token only for the administrative bootstrap steps. The token is kept in
the process environment and is not written to Compose or to disk.

The script intentionally does not write AppRole credentials into Akaunting.
Copy the printed Role ID and Secret ID into **NFS-e -> Configuracoes**:

```text
Address:   http://openbao:8200
KV mount:  /nfse
Token:     leave empty
Role ID:   <printed Role ID>
Secret ID: <printed Secret ID>
```

After a clean OpenBao rebuild, upload/configure the ICP-Brasil certificate
again so its password is stored in the new `nfse` KV.

## Recovery material

The static seal key and OpenBao data must be backed up separately.

Keep a recovery copy of:

```text
secrets/openbao_static_seal_key
```

outside the VPS. Do not store that recovery copy in the same backup object as:

```text
volumes/openbao
```

The OpenBao recovery key and initial root token produced by
`bao operator init` should also be kept outside the VPS.

## Manual bootstrap

The automated script is preferred. The equivalent manual flow starts by
creating the storage and 32-byte static seal key:

```bash
install -d -m 700 secrets
install -d -m 700 -o 100 -g 100 volumes/openbao

(
  umask 077
  openssl rand -out secrets/openbao_static_seal_key 32
)
chmod 0444 secrets/openbao_static_seal_key
test "$(wc -c < secrets/openbao_static_seal_key)" -eq 32
```

Start and initialize OpenBao exactly once:

```bash
docker compose up -d openbao

docker compose exec -T openbao \
  bao operator init \
  -recovery-shares=1 \
  -recovery-threshold=1
```

Load the initial root token in the host shell without placing it in shell
history:

```bash
read -r -s -p "Initial Root Token: " BAO_ROOT_TOKEN
echo
```

Then enable the NFS-e KV v2 mount and AppRole:

```bash
docker compose exec -T -e BAO_TOKEN="$BAO_ROOT_TOKEN" openbao \
  bao secrets enable -path=nfse kv-v2

docker compose exec -T -e BAO_TOKEN="$BAO_ROOT_TOKEN" openbao \
  bao auth enable approle
```

Create the policy. `-T` is required because the policy is supplied on stdin:

```bash
docker compose exec -T -e BAO_TOKEN="$BAO_ROOT_TOKEN" openbao \
  bao policy write nfse - <<'EOF'
path "nfse/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
EOF
```

Create the AppRole:

```bash
docker compose exec -T -e BAO_TOKEN="$BAO_ROOT_TOKEN" openbao \
  bao write auth/approle/role/nfse \
  token_policies="nfse" \
  token_ttl=1h \
  token_max_ttl=4h
```

Get the Role ID and create a Secret ID:

```bash
docker compose exec -T -e BAO_TOKEN="$BAO_ROOT_TOKEN" openbao \
  bao read auth/approle/role/nfse/role-id

docker compose exec -T -e BAO_TOKEN="$BAO_ROOT_TOKEN" openbao \
  bao write -f auth/approle/role/nfse/secret-id
```

Remove the administrative token from the shell when finished:

```bash
unset BAO_ROOT_TOKEN
```

## Normal restart and update

No manual unseal command is required after the initial setup:

```bash
docker compose up -d
docker compose exec -T openbao bao status
```

Expected state:

```text
Initialized     true
Sealed          false
```

## Existing Shamir deployments

Do not reinitialize an existing OpenBao data directory. Migrating an existing
Shamir deployment to Static Key Auto Unseal is a one-time seal migration and
requires a verified backup before running `bao operator unseal -migrate`.

Perform that migration separately from an Akaunting application update.
