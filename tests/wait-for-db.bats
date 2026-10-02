#!/usr/bin/env bats

@test "database readiness exits immediately for sqlite" {
  DB_CONNECTION=sqlite run php "${BATS_TEST_DIRNAME}/../.docker/php/wait-for-db.php"

  [ "$status" -eq 0 ]
}

@test "database readiness rejects unsupported drivers" {
  DB_CONNECTION=unsupported run php "${BATS_TEST_DIRNAME}/../.docker/php/wait-for-db.php"

  [ "$status" -ne 0 ]
  [[ "$output" == *"Unsupported DB_CONNECTION"* ]]
}

@test "database readiness honors bounded timeout" {
  DB_CONNECTION=mysql \
  DB_HOST=127.0.0.1 \
  DB_PORT=1 \
  DB_DATABASE=test \
  DB_USERNAME=test \
  DB_PASSWORD=test \
  DB_WAIT_TIMEOUT=1 \
    run php "${BATS_TEST_DIRNAME}/../.docker/php/wait-for-db.php"

  [ "$status" -eq 1 ]
  [[ "$output" == *"within 1 seconds"* ]]
  [[ "$output" == *"127.0.0.1:1"* ]]
}
