#!/usr/bin/env bash
set -euo pipefail

: "${AKAUNTING_VERSION:?AKAUNTING_VERSION is required}"

src_dir="/tmp/akaunting-src"
dest_dir="/opt/akaunting"

rm -rf "${src_dir}" "${dest_dir}"
git clone --progress -b "${AKAUNTING_VERSION}" --single-branch --depth 1 https://github.com/akaunting/akaunting "${src_dir}"

cd "${src_dir}"
git apply /tmp/akaunting-modifications.patch

composer install --no-dev --no-scripts --prefer-dist --no-interaction --no-progress
npm ci
npm run production
composer dump-autoload --optimize

rm -rf .git node_modules
mkdir -p "${dest_dir}"
rsync -a "${src_dir}/" "${dest_dir}/"
chown -R www-data:www-data "${dest_dir}"
