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


@test "patch helper applies committed and local patches in order" {
  repo_dir="${BATS_TEST_TMPDIR}/patch-repo"
  committed_dir="${BATS_TEST_TMPDIR}/committed"
  local_dir="${BATS_TEST_TMPDIR}/local"

  mkdir -p "${repo_dir}" "${committed_dir}" "${local_dir}"
  cd "${repo_dir}"

  git init -q
  git config user.email test@example.com
  git config user.name Test

  printf 'base\n' > sample.txt
  git add sample.txt
  git commit -qm base

  printf 'committed\n' > sample.txt
  git diff > "${committed_dir}/10-committed.patch"
  git checkout -- sample.txt

  printf 'base\nlocal\n' > sample.txt
  git diff > "${local_dir}/20-local.patch"
  git checkout -- sample.txt

  mkdir -p /opt/akaunting
  ln -s "${committed_dir}" /opt/akaunting/patches
  ln -s "${local_dir}" /opt/akaunting/patches.local

  run bash "${OLDPWD}/.docker/php/apply-patches.sh"

  rm /opt/akaunting/patches /opt/akaunting/patches.local

  [ "$status" -eq 0 ]
  grep -q '^committed$' sample.txt
  grep -q '^local$' sample.txt
}

@test "patch helper is idempotent" {
  repo_dir="${BATS_TEST_TMPDIR}/patch-idempotent-repo"
  patch_dir="${BATS_TEST_TMPDIR}/patch-idempotent"

  mkdir -p "${repo_dir}" "${patch_dir}"
  cd "${repo_dir}"

  git init -q
  git config user.email test@example.com
  git config user.name Test

  printf 'base\n' > sample.txt
  git add sample.txt
  git commit -qm base

  printf 'patched\n' > sample.txt
  git diff > "${patch_dir}/10.patch"
  git checkout -- sample.txt

  mkdir -p /opt/akaunting
  ln -s "${patch_dir}" /opt/akaunting/patches
  mkdir -p "${BATS_TEST_TMPDIR}/empty-local"
  ln -s "${BATS_TEST_TMPDIR}/empty-local" /opt/akaunting/patches.local

  bash "${OLDPWD}/.docker/php/apply-patches.sh"
  run bash "${OLDPWD}/.docker/php/apply-patches.sh"

  rm /opt/akaunting/patches /opt/akaunting/patches.local

  [ "$status" -eq 0 ]
  [[ "$output" == *"Patch already applied"* ]]
}
