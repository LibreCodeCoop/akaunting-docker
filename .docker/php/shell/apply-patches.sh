#!/usr/bin/env bash
set -euo pipefail

if [ ! -d .git ]; then
    echo "Patch application requires an Akaunting Git checkout." >&2
    exit 1
fi

apply_patch_dir() {
    local patch_dir="$1"

    [ -d "$patch_dir" ] || return 0

    while IFS= read -r -d '' patch_file; do
        if git apply --reverse --check "$patch_file" >/dev/null 2>&1; then
            echo "Patch already applied: $(basename "$patch_file")"
            continue
        fi

        if ! git apply --check "$patch_file"; then
            echo "Patch does not apply cleanly: $(basename "$patch_file")" >&2
            exit 1
        fi

        git apply "$patch_file"
        echo "Patch applied: $(basename "$patch_file")"
    done < <(find "$patch_dir" -maxdepth 1 -type f -name '*.patch' -print0 | sort -z)
}

apply_patch_dir "${PATCH_DIR:-/opt/akaunting/patches}"
apply_patch_dir "${LOCAL_PATCH_DIR:-/opt/akaunting/patches.local}"
