#!/usr/bin/env bash
set -euo pipefail

base_url="${RUNTIME_TEST_BASE_URL:-http://127.0.0.1:8080}"

docker compose exec -T akaunting.php php -r '
    if (ini_get("xdebug.mode") !== "off") {
        fwrite(STDERR, "Xdebug must be disabled by default in the base runtime.\n");
        exit(1);
    }
'

docker compose exec -T akaunting.php sh -lc '
    printf "%s\n" "console.log(\"cache test\");" > public/runtime-cache-test.js
    mkdir -p modules/RuntimeCacheTest
    printf "%s\n" "console.log(\"module cache test\");" > modules/RuntimeCacheTest/runtime-cache-test.js
    printf "%s\n" "console.log(\"must stay protected\");" > config/runtime-cache-test.js
'

public_headers="$(curl --fail --silent --show-error --head     "${base_url}/public/runtime-cache-test.js")"
printf '%s\n' "$public_headers"
grep -qi '^Cache-Control: max-age=2592000' <<<"$public_headers"
grep -qi '^Expires:' <<<"$public_headers"

module_headers="$(curl --fail --silent --show-error --head     "${base_url}/modules/RuntimeCacheTest/runtime-cache-test.js")"
printf '%s\n' "$module_headers"
grep -qi '^Cache-Control: max-age=2592000' <<<"$module_headers"

protected_status="$(curl --silent --output /dev/null --write-out '%{http_code}'     "${base_url}/config/runtime-cache-test.js")"
test "$protected_status" = "403"
