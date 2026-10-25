#!/bin/sh
# SPDX-FileCopyrightText: 2026 LibreCode coop and contributors
# SPDX-License-Identifier: GPL-3.0-or-later
# Reapply the reviewed local dev compatibility fixes to the exact Core 3.2.4 tag.
set -eu
project_dir=$(cd -- "$(dirname -- "$0")/.." && pwd)
core_dir="$project_dir/volumes/akaunting"
if ! git -C "$core_dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo 'Akaunting Core checkout not found' >&2
    exit 1
fi
expected=$(git -C "$core_dir" rev-parse '3.2.4^{commit}' 2>/dev/null || true)
actual=$(git -C "$core_dir" rev-parse HEAD)
if [ -z "$expected" ] || [ "$actual" != "$expected" ]; then
    echo 'Refusing to apply 3.2.4 patches to a different Core commit' >&2
    exit 1
fi
for name in akaunting-3.2.4-api-auth-401.patch akaunting-3.2.4-editor.patch; do
    patch="$project_dir/patches/$name"
    if git -C "$core_dir" apply --reverse --check "$patch" >/dev/null 2>&1; then
        printf 'Already applied: %s\n' "$name"
    elif git -C "$core_dir" apply --check "$patch" >/dev/null 2>&1; then
        git -C "$core_dir" apply "$patch"
        printf 'Applied: %s\n' "$name"
    else
        printf 'Patch conflict, no forced overwrite: %s\n' "$name" >&2
        exit 1
    fi
done
printf 'Core patch check completed. Rebuild assets after editor patch if needed.\n'
