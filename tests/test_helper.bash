setup_test_bin() {
  export TEST_BIN="${BATS_TEST_TMPDIR}/bin"
  export CALL_LOG="${BATS_TEST_TMPDIR}/calls.log"
  mkdir -p "${TEST_BIN}"
  : > "${CALL_LOG}"
  export PATH="${TEST_BIN}:${PATH}"
}

stub_command() {
  local command_name="$1"

  cat > "${TEST_BIN}/${command_name}" <<EOF
#!/usr/bin/env bash
printf '%s %s\n' '${command_name}' "\$*" >> "${CALL_LOG}"
EOF
  chmod +x "${TEST_BIN}/${command_name}"
}

create_fake_lifecycle_lib() {
  export TEST_APP_ROOT="${BATS_TEST_TMPDIR}/app"
  export TEST_LIFECYCLE_LOG="${BATS_TEST_TMPDIR}/lifecycle.log"
  export TEST_LIFECYCLE_LIB="${BATS_TEST_TMPDIR}/fake-akaunting.sh"

  mkdir -p "${TEST_APP_ROOT}"
  : > "${TEST_LIFECYCLE_LOG}"

  cat > "${TEST_LIFECYCLE_LIB}" <<'EOF'
APP_ROOT="${TEST_APP_ROOT}"

record_lifecycle() {
  printf '%s\n' "$1" >> "${TEST_LIFECYCLE_LOG}"
}

akaunting_clone() {
  record_lifecycle clone
  touch "${APP_ROOT}/artisan"
}

akaunting_apply_patches() {
  record_lifecycle patches
}

akaunting_install_php_dependencies() {
  record_lifecycle php-dependencies
  mkdir -p "${APP_ROOT}/vendor"
  touch "${APP_ROOT}/vendor/autoload.php"
}

akaunting_install_application() {
  record_lifecycle install
  touch "${APP_ROOT}/.env"
}

akaunting_fix_ownership() {
  record_lifecycle ownership
}

akaunting_update_checkout() {
  record_lifecycle checkout
}

akaunting_refresh_dependencies() {
  record_lifecycle refresh-dependencies
}

akaunting_run_upgrade() {
  record_lifecycle upgrade
}
EOF
}
