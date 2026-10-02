#!/usr/bin/env bash
set -euo pipefail

APP_ROOT="${APP_ROOT:-/var/www/html}"
AKAUNTING_REPOSITORY="${AKAUNTING_REPOSITORY:-https://github.com/akaunting/akaunting}"
PATCH_COMMAND="${PATCH_COMMAND:-/usr/local/bin/apply-patches.sh}"

akaunting_cd() {
    cd "${APP_ROOT}"
}

akaunting_clone() {
    local tmp_dir="${AKAUNTING_CLONE_TMP:-/tmp/akaunting}"

    rm -rf "${tmp_dir}"
    git clone --progress -b "${AKAUNTING_VERSION}" --single-branch --depth 1 "${AKAUNTING_REPOSITORY}" "${tmp_dir}"
    rsync -a "${tmp_dir}/" "${APP_ROOT}/"
    rm -rf "${tmp_dir}"
}

akaunting_apply_patches() {
    (
        akaunting_cd
        "${PATCH_COMMAND}"
    )
}

akaunting_install_php_dependencies() {
    akaunting_cd

    if [ "${APP_ENV}" = "production" ]; then
        composer install --prefer-dist --no-interaction --no-scripts --no-progress --no-ansi --no-dev
    else
        composer install --prefer-dist --no-interaction --no-scripts --no-progress --no-ansi
    fi

    composer dump-autoload
}

akaunting_build_assets() {
    akaunting_cd

    npm ci

    if [ "${APP_ENV}" = "production" ]; then
        npm run production
    else
        npm run dev
    fi
}

akaunting_install_application() {
    akaunting_cd

    cp .env.example .env
    php artisan key:generate

    php artisan install \
        --no-interaction \
        --db-host="${DB_HOST}" \
        --db-port="${DB_PORT}" \
        --db-name="${DB_DATABASE}" \
        --db-username="${DB_USERNAME}" \
        --db-password="${DB_PASSWORD}" \
        --db-prefix="${DB_PREFIX}" \
        --admin-email="${ADM_EMAIL}" \
        --admin-password="${ADM_PASSWD}"

    akaunting_build_assets
}

akaunting_update_checkout() {
    akaunting_cd

    git fetch --force --depth 1 origin "refs/tags/${AKAUNTING_VERSION}:refs/tags/${AKAUNTING_VERSION}"
    git reset --hard "refs/tags/${AKAUNTING_VERSION}"
}

akaunting_refresh_dependencies() {
    akaunting_cd

    if [ "${APP_ENV}" = "production" ]; then
        composer prod
    else
        composer test
    fi

    akaunting_build_assets
}

akaunting_run_upgrade() {
    akaunting_cd

    php artisan update:all
    php artisan optimize:clear
    php artisan migrate --force
}

akaunting_fix_ownership() {
    chown -R www-data:www-data "${APP_ROOT}"
}
