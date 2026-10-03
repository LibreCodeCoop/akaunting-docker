#!/usr/bin/env bash
set -euo pipefail

OPENBAO_SERVICE="${OPENBAO_SERVICE:-openbao}"
OPENBAO_UID="${OPENBAO_UID:-100}"
OPENBAO_GID="${OPENBAO_GID:-100}"
SEAL_KEY_FILE="${OPENBAO_STATIC_SEAL_KEY_FILE:-./secrets/openbao_static_seal_key}"
OPENBAO_DATA_DIR="${OPENBAO_DATA_DIR:-./volumes/openbao}"
OPENBAO_CONFIG_FILE="${OPENBAO_CONFIG_FILE:-./deploy/openbao/openbao.hcl}"
NFSE_MOUNT="${NFSE_MOUNT:-nfse}"
NFSE_POLICY="${NFSE_POLICY:-nfse}"
NFSE_ROLE="${NFSE_ROLE:-nfse}"

compose() {
    docker compose "$@"
}

wait_for_status() {
    local attempts=30
    local output=""

    for ((i = 1; i <= attempts; i++)); do
        output="$(compose exec -T "${OPENBAO_SERVICE}" bao status 2>&1 || true)"
        if grep -q "Initialized" <<<"${output}"; then
            printf '%s\n' "${output}"
            return 0
        fi
        sleep 1
    done

    echo "OpenBao did not become reachable." >&2
    compose logs --tail=100 "${OPENBAO_SERVICE}" >&2 || true
    return 1
}

bao_admin() {
    compose exec -T -e BAO_TOKEN="${root_token}" "${OPENBAO_SERVICE}" bao "$@"
}

if [ ! -f "${OPENBAO_CONFIG_FILE}" ]; then
    echo "OpenBao config is missing or is not a regular file: ${OPENBAO_CONFIG_FILE}" >&2
    exit 1
fi

if ! grep -q 'storage "pebbledb"' "${OPENBAO_CONFIG_FILE}"; then
    echo "OpenBao config does not declare the expected PebbleDB storage backend." >&2
    exit 1
fi

install -d -m 700 "$(dirname "${SEAL_KEY_FILE}")"
install -d -m 700 -o "${OPENBAO_UID}" -g "${OPENBAO_GID}" "${OPENBAO_DATA_DIR}"

if [ ! -e "${SEAL_KEY_FILE}" ]; then
    (
        umask 077
        openssl rand -out "${SEAL_KEY_FILE}" 32
    )
    chmod 0444 "${SEAL_KEY_FILE}"
    echo "Created static seal key: ${SEAL_KEY_FILE}"
else
    echo "Using existing static seal key: ${SEAL_KEY_FILE}"
fi

if [ ! -f "${SEAL_KEY_FILE}" ] || [ "$(wc -c < "${SEAL_KEY_FILE}")" -ne 32 ]; then
    echo "Static seal key must be a regular 32-byte file." >&2
    exit 1
fi

compose config --quiet
compose up -d "${OPENBAO_SERVICE}"

status_output="$(wait_for_status)"
printf '%s\n' "${status_output}"

root_token="${BAO_ROOT_TOKEN:-}"

if grep -Eq 'Initialized[[:space:]]+false' <<<"${status_output}"; then
    echo
    echo "Initializing OpenBao exactly once..."
    init_output="$(
        compose exec -T "${OPENBAO_SERVICE}"             bao operator init             -recovery-shares=1             -recovery-threshold=1
    )"
    printf '%s\n' "${init_output}"

    root_token="$(
        sed -n 's/^Initial Root Token:[[:space:]]*//p' <<<"${init_output}"
    )"

    if [ -z "${root_token}" ]; then
        echo "Could not extract the initial root token from initialization output." >&2
        exit 1
    fi

    echo
    echo "Store the recovery key and initial root token outside this VPS."
    echo "Also keep a recovery copy of ${SEAL_KEY_FILE} separately from ${OPENBAO_DATA_DIR}."
else
    if [ -z "${root_token}" ]; then
        read -r -s -p "OpenBao root token for bootstrap: " root_token
        echo
    fi
fi

if [ -z "${root_token}" ]; then
    echo "A root token is required to configure the initial NFSe policy and AppRole." >&2
    exit 1
fi

bao_admin token lookup >/dev/null

if ! bao_admin secrets list -format=json | grep -q "\"\${NFSE_MOUNT}/\""; then
    bao_admin secrets enable -path="${NFSE_MOUNT}" kv-v2
else
    echo "KV v2 mount already enabled at ${NFSE_MOUNT}/"
fi

if ! bao_admin auth list -format=json | grep -q '"approle/"'; then
    bao_admin auth enable approle
else
    echo "AppRole auth method already enabled."
fi

printf 'path "%s/*" {\n  capabilities = ["create", "read", "update", "delete", "list"]\n}\n' "${NFSE_MOUNT}" |
    compose exec -T -e BAO_TOKEN="${root_token}" "${OPENBAO_SERVICE}"         bao policy write "${NFSE_POLICY}" -

bao_admin write "auth/approle/role/${NFSE_ROLE}"     token_policies="${NFSE_POLICY}"     token_ttl=1h     token_max_ttl=4h >/dev/null

role_id="$(bao_admin read -field=role_id "auth/approle/role/${NFSE_ROLE}/role-id")"
secret_id="$(bao_admin write -field=secret_id -f "auth/approle/role/${NFSE_ROLE}/secret-id")"

echo
echo "NFSe AppRole credentials"
echo "Role ID:   ${role_id}"
echo "Secret ID: ${secret_id}"
echo
echo "Configure Akaunting NFS-e with:"
echo "  Address:  http://openbao:8200"
echo "  KV mount: /${NFSE_MOUNT}"
echo "  Token:    leave empty"
echo "  Role ID:  value printed above"
echo "  Secret ID:value printed above"

unset root_token
unset BAO_ROOT_TOKEN 2>/dev/null || true

echo
echo "Restarting OpenBao to verify Static Key Auto Unseal..."
compose restart "${OPENBAO_SERVICE}" >/dev/null

status_output="$(wait_for_status)"
printf '%s\n' "${status_output}"

if ! grep -Eq 'Initialized[[:space:]]+true' <<<"${status_output}" ||
   ! grep -Eq 'Sealed[[:space:]]+false' <<<"${status_output}"; then
    echo "OpenBao did not return initialized and unsealed after restart." >&2
    exit 1
fi

echo
echo "OpenBao bootstrap completed successfully."
