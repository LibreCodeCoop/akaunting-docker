#!/usr/bin/env bats

setup() {
  export TEST_BIN="${BATS_TEST_TMPDIR}/bin"
  mkdir -p "${TEST_BIN}"

  cat > "${TEST_BIN}/docker" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*"
EOF
  chmod +x "${TEST_BIN}/docker"

  export PATH="${TEST_BIN}:${PATH}"
}

@test "update script uses akaunting.php by default" {
  run bash scripts/update-akaunting.sh

  [ "$status" -eq 0 ]
  [[ "$output" == *"compose exec akaunting.php bash -lc"* ]]
}

@test "update script honors AKAUNTING_SERVICE" {
  AKAUNTING_SERVICE=custom.php run bash scripts/update-akaunting.sh

  [ "$status" -eq 0 ]
  [[ "$output" == *"compose exec custom.php bash -lc"* ]]
}

@test "database readiness exits immediately for sqlite" {
  DB_CONNECTION=sqlite run php .docker/php/wait-for-db.php

  [ "$status" -eq 0 ]
}

@test "database readiness rejects unsupported drivers" {
  DB_CONNECTION=unsupported run php .docker/php/wait-for-db.php

  [ "$status" -ne 0 ]
  [[ "$output" == *"Unsupported DB_CONNECTION"* ]]
}
