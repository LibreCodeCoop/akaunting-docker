#!/usr/bin/env bash
set -euo pipefail

service="${AKAUNTING_SERVICE:-akaunting.php}"

docker compose exec "${service}" bash -lc '
set -euo pipefail

cd /var/www/html
: "${AKAUNTING_VERSION:?AKAUNTING_VERSION is not set}"

patch_file="/opt/akaunting/patches/akaunting-modifications.patch"

echo "Updating Akaunting to ${AKAUNTING_VERSION}..."

git fetch --force --depth 1 origin "refs/tags/${AKAUNTING_VERSION}:refs/tags/${AKAUNTING_VERSION}"
git reset --hard "refs/tags/${AKAUNTING_VERSION}"

if [ -f "${patch_file}" ]; then
    if git apply --check "${patch_file}"; then
        git apply "${patch_file}"
    else
        echo "The patch does not apply cleanly to Akaunting ${AKAUNTING_VERSION}." >&2
        exit 1
    fi
fi

if [ "${APP_ENV}" = "production" ]; then
    composer prod
else
    composer test
fi

npm ci
if [ "${APP_ENV}" = "production" ]; then
    npm run production
else
    npm run dev
fi

php artisan update:all
php artisan optimize:clear
php artisan migrate --force

chown -R www-data:www-data /var/www/html

echo "Akaunting ${AKAUNTING_VERSION} update completed."
'
