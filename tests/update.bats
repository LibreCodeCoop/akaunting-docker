#!/usr/bin/env bats

load test_helper

setup() {
  setup_test_bin
}

@test "host update wrapper uses akaunting.php by default" {
  stub_command docker

  run bash "${BATS_TEST_DIRNAME}/../scripts/update-akaunting.sh"

  [ "$status" -eq 0 ]
  grep -q '^docker compose exec akaunting.php /usr/local/bin/update-akaunting.sh$' "${CALL_LOG}"
}

@test "host update wrapper honors AKAUNTING_SERVICE" {
  stub_command docker

  AKAUNTING_SERVICE=custom.php run bash "${BATS_TEST_DIRNAME}/../scripts/update-akaunting.sh"

  [ "$status" -eq 0 ]
  grep -q '^docker compose exec custom.php /usr/local/bin/update-akaunting.sh$' "${CALL_LOG}"
}

@test "container update runs lifecycle in deterministic order" {
  create_fake_lifecycle_lib

  AKAUNTING_VERSION=3.2.4 AKAUNTING_LIB="${TEST_LIFECYCLE_LIB}" \
    run bash "${BATS_TEST_DIRNAME}/../.docker/php/update-akaunting.sh"

  [ "$status" -eq 0 ]
  expected=$'checkout\npatches\nrefresh-dependencies\nupgrade\nownership'
  [ "$(cat "${TEST_LIFECYCLE_LOG}")" = "$expected" ]
}

@test "container update requires AKAUNTING_VERSION" {
  create_fake_lifecycle_lib

  AKAUNTING_LIB="${TEST_LIFECYCLE_LIB}" run bash "${BATS_TEST_DIRNAME}/../.docker/php/update-akaunting.sh"

  [ "$status" -ne 0 ]
  [[ "$output" == *"AKAUNTING_VERSION is not set"* ]]
}
