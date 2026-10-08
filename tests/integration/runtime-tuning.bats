#!/usr/bin/env bats

setup_file() {
  export RUNTIME_TEST_BASE_URL="${RUNTIME_TEST_BASE_URL:-http://127.0.0.1:8080}"

  docker compose exec -T akaunting.php sh -lc '
    printf "%s\n" "console.log(\"cache test\");" > public/runtime-cache-test.js
    mkdir -p modules/RuntimeCacheTest
    printf "%s\n" "console.log(\"module cache test\");" > modules/RuntimeCacheTest/runtime-cache-test.js
    printf "%s\n" "console.log(\"must stay protected\");" > config/runtime-cache-test.js
  '
}

teardown_file() {
  docker compose exec -T akaunting.php sh -lc '
    rm -f public/runtime-cache-test.js
    rm -f modules/RuntimeCacheTest/runtime-cache-test.js
    rmdir modules/RuntimeCacheTest 2>/dev/null || true
    rm -f config/runtime-cache-test.js
  ' >/dev/null 2>&1 || true
}

@test "base PHP runtime keeps Xdebug disabled" {
  run docker compose exec -T akaunting.php php -r '
    $modes = xdebug_info("mode");

    if ($modes !== []) {
        fwrite(STDERR, "Enabled Xdebug modes: " . implode(", ", $modes) . PHP_EOL);
        exit(1);
    }
  '

  [ "$status" -eq 0 ]
}

@test "public static assets receive browser cache headers" {
  run curl --fail --silent --show-error --head     "${RUNTIME_TEST_BASE_URL}/public/runtime-cache-test.js"

  [ "$status" -eq 0 ]
  grep -qi '^Cache-Control: max-age=2592000' <<<"$output"
  grep -qi '^Expires:' <<<"$output"
}

@test "module static assets receive browser cache headers" {
  run curl --fail --silent --show-error --head     "${RUNTIME_TEST_BASE_URL}/modules/RuntimeCacheTest/runtime-cache-test.js"

  [ "$status" -eq 0 ]
  grep -qi '^Cache-Control: max-age=2592000' <<<"$output"
}

@test "protected application directories remain inaccessible" {
  run curl --silent --output /dev/null --write-out '%{http_code}'     "${RUNTIME_TEST_BASE_URL}/config/runtime-cache-test.js"

  [ "$status" -eq 0 ]
  [ "$output" = "403" ]
}
