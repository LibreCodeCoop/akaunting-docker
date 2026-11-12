#!/usr/bin/env bats

load test_helper

setup() {
  setup_test_bin
  stub_command docker
}

@test "artisan wrapper executes as the same user as PHP-FPM" {
  run bash "${BATS_TEST_DIRNAME}/../scripts/artisan.sh" cache:clear
  [ "$status" -eq 0 ]
  grep -q '^docker compose exec -u www-data akaunting.php php artisan cache:clear$' "${CALL_LOG}"
}

@test "artisan wrapper preserves arguments and selected service" {
  AKAUNTING_SERVICE=custom.php run bash "${BATS_TEST_DIRNAME}/../scripts/artisan.sh" route:list --path=api
  [ "$status" -eq 0 ]
  grep -q '^docker compose exec -u www-data custom.php php artisan route:list --path=api$' "${CALL_LOG}"
}

@test "artisan wrapper refuses empty commands" {
  run bash "${BATS_TEST_DIRNAME}/../scripts/artisan.sh"
  [ "$status" -eq 2 ]
  [[ "$output" == *"Usage:"* ]]
  [ ! -s "${CALL_LOG}" ]
}
