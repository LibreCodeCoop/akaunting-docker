#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=akaunting.sh
source "${AKAUNTING_LIB:-/usr/local/lib/akaunting.sh}"

: "${AKAUNTING_VERSION:?AKAUNTING_VERSION is not set}"

echo "Updating Akaunting to ${AKAUNTING_VERSION}..."

akaunting_update_checkout
akaunting_apply_patches
akaunting_refresh_dependencies
akaunting_run_upgrade
akaunting_fix_ownership

echo "Akaunting ${AKAUNTING_VERSION} update completed."
