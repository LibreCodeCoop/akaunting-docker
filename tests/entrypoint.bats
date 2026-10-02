#!/usr/bin/env bats

load test_helper

setup() {
  setup_test_bin
  create_fake_lifecycle_lib

  stub_command usermod
  stub_command groupmod
  stub_command php
  stub_command php-fpm

  export HOST_UID=1000
  export HOST_GID=1000
  export AKAUNTING_LIB="${TEST_LIFECYCLE_LIB}"
}

@test "existing installation only checks patches before starting PHP-FPM" {
  touch "${TEST_APP_ROOT}/artisan" "${TEST_APP_ROOT}/.env"
  mkdir -p "${TEST_APP_ROOT}/vendor"
  touch "${TEST_APP_ROOT}/vendor/autoload.php"

  run bash "${BATS_TEST_DIRNAME}/../.docker/php/shell/entrypoint.sh"

  [ "$status" -eq 0 ]
  [ "$(cat "${TEST_LIFECYCLE_LOG}")" = "patches" ]
  grep -q '^php-fpm ' "${CALL_LOG}"
}

@test "fresh installation runs lifecycle in deterministic order" {
  run bash "${BATS_TEST_DIRNAME}/../.docker/php/shell/entrypoint.sh"

  [ "$status" -eq 0 ]
  expected=$'clone\npatches\nphp-dependencies\ninstall\nownership'
  [ "$(cat "${TEST_LIFECYCLE_LOG}")" = "$expected" ]
}

@test "missing vendor restores dependencies without reinstalling application" {
  touch "${TEST_APP_ROOT}/artisan" "${TEST_APP_ROOT}/.env"

  run bash "${BATS_TEST_DIRNAME}/../.docker/php/shell/entrypoint.sh"

  [ "$status" -eq 0 ]
  expected=$'patches\nphp-dependencies'
  [ "$(cat "${TEST_LIFECYCLE_LOG}")" = "$expected" ]
}

@test "missing env installs application without recloning checkout" {
  touch "${TEST_APP_ROOT}/artisan"
  mkdir -p "${TEST_APP_ROOT}/vendor"
  touch "${TEST_APP_ROOT}/vendor/autoload.php"

  run bash "${BATS_TEST_DIRNAME}/../.docker/php/shell/entrypoint.sh"

  [ "$status" -eq 0 ]
  expected=$'patches\ninstall'
  [ "$(cat "${TEST_LIFECYCLE_LOG}")" = "$expected" ]
}
