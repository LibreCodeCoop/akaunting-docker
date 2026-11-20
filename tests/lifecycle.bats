#!/usr/bin/env bats

load test_helper

setup() {
  setup_test_bin
  export APP_ROOT="${BATS_TEST_TMPDIR}/app"
  mkdir -p "${APP_ROOT}"
  stub_command composer
  stub_command npm
}

@test "production PHP dependencies exclude dev packages" {
  APP_ENV=production
  source "${BATS_TEST_DIRNAME}/../.docker/php/shell/lib/akaunting.sh"

  akaunting_install_php_dependencies

  grep -q 'composer install .*--no-dev' "${CALL_LOG}"
  grep -q '^composer dump-autoload$' "${CALL_LOG}"
}

@test "local PHP dependencies keep dev packages" {
  APP_ENV=local
  source "${BATS_TEST_DIRNAME}/../.docker/php/shell/lib/akaunting.sh"

  akaunting_install_php_dependencies

  grep -q '^composer install ' "${CALL_LOG}"
  ! grep -q -- '--no-dev' "${CALL_LOG}"
}

@test "asset build selects production command" {
  APP_ENV=production
  source "${BATS_TEST_DIRNAME}/../.docker/php/shell/lib/akaunting.sh"

  akaunting_build_assets

  grep -q '^npm ci$' "${CALL_LOG}"
  grep -q '^npm run production$' "${CALL_LOG}"
}

@test "asset build selects development command" {
  APP_ENV=local
  source "${BATS_TEST_DIRNAME}/../.docker/php/shell/lib/akaunting.sh"

  akaunting_build_assets

  grep -q '^npm ci$' "${CALL_LOG}"
  grep -q '^npm run dev$' "${CALL_LOG}"
}


@test "Composer autoload refresh re-registers the optional public Theme provider" {
  APP_ENV=production
  mkdir -p "${APP_ROOT}/modules/Theme/scripts" "${APP_ROOT}/bootstrap/cache"
  touch "${APP_ROOT}/modules/Theme/scripts/register_guest_provider.php"
  touch "${APP_ROOT}/bootstrap/cache/packages.php"
  stub_command runuser
  source "${BATS_TEST_DIRNAME}/../.docker/php/shell/lib/akaunting.sh"

  akaunting_install_php_dependencies

  grep -q '^composer dump-autoload$' "${CALL_LOG}"
  grep -q "runuser -u www-data -- php .*modules/Theme/scripts/register_guest_provider.php .* install" "${CALL_LOG}"
}

@test "Akaunting update also restores the public Theme provider after Composer scripts" {
  APP_ENV=production
  mkdir -p "${APP_ROOT}/modules/Theme/scripts" "${APP_ROOT}/bootstrap/cache"
  touch "${APP_ROOT}/modules/Theme/scripts/register_guest_provider.php"
  touch "${APP_ROOT}/bootstrap/cache/packages.php"
  stub_command runuser
  source "${BATS_TEST_DIRNAME}/../.docker/php/shell/lib/akaunting.sh"

  akaunting_refresh_dependencies

  grep -q '^composer prod$' "${CALL_LOG}"
  grep -q '^npm run production$' "${CALL_LOG}"
  grep -q "runuser -u www-data -- php .*modules/Theme/scripts/register_guest_provider.php .* install" "${CALL_LOG}"
}
