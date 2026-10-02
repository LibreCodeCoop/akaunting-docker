#!/usr/bin/env bats

load test_helper

@test "committed patches are applied before local patches" {
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
  git add sample.txt
  git commit -qm committed

  printf 'committed\nlocal\n' > sample.txt
  git diff > "${local_dir}/20-local.patch"

  git reset --hard -q HEAD~1

  PATCH_DIR="${committed_dir}" LOCAL_PATCH_DIR="${local_dir}" \
    run bash "${BATS_TEST_DIRNAME}/../.docker/php/shell/apply-patches.sh"

  [ "$status" -eq 0 ]
  [ "$(cat sample.txt)" = $'committed\nlocal' ]
}

@test "patch application is idempotent" {
  repo_dir="${BATS_TEST_TMPDIR}/patch-idempotent-repo"
  patch_dir="${BATS_TEST_TMPDIR}/patch-idempotent"
  empty_local="${BATS_TEST_TMPDIR}/empty-local"

  mkdir -p "${repo_dir}" "${patch_dir}" "${empty_local}"
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

  PATCH_DIR="${patch_dir}" LOCAL_PATCH_DIR="${empty_local}" \
    bash "${BATS_TEST_DIRNAME}/../.docker/php/shell/apply-patches.sh"

  PATCH_DIR="${patch_dir}" LOCAL_PATCH_DIR="${empty_local}" \
    run bash "${BATS_TEST_DIRNAME}/../.docker/php/shell/apply-patches.sh"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Patch already applied: 10.patch"* ]]
}

@test "incompatible patch fails without changing the checkout" {
  repo_dir="${BATS_TEST_TMPDIR}/patch-failure-repo"
  patch_dir="${BATS_TEST_TMPDIR}/patch-failure"

  mkdir -p "${repo_dir}" "${patch_dir}"
  cd "${repo_dir}"

  git init -q
  git config user.email test@example.com
  git config user.name Test
  printf 'base\n' > sample.txt
  git add sample.txt
  git commit -qm base

  cat > "${patch_dir}/10-bad.patch" <<'EOF'
diff --git a/sample.txt b/sample.txt
--- a/sample.txt
+++ b/sample.txt
@@ -1 +1 @@
-not-present
+bad
EOF

  run env PATCH_DIR="${patch_dir}" LOCAL_PATCH_DIR="${BATS_TEST_TMPDIR}/missing" \
    bash "${BATS_TEST_DIRNAME}/../.docker/php/shell/apply-patches.sh"

  [ "$status" -ne 0 ]
  [[ "$output" == *"Patch does not apply cleanly: 10-bad.patch"* ]]
  [ "$(cat sample.txt)" = "base" ]
}
