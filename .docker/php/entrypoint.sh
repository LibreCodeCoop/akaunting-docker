#!/bin/bash
set -euo pipefail

# Match the container user with the host user for bind-mounted files.
usermod --non-unique --uid "${HOST_UID}" www-data
groupmod --non-unique --gid "${HOST_GID}" www-data

php /usr/local/bin/wait-for-db.php

fresh_install=false

if [ ! -f "artisan" ]; then
    fresh_install=true
    rm -rf /tmp/akaunting
    git clone --progress -b "${AKAUNTING_VERSION}" --single-branch --depth 1 https://github.com/akaunting/akaunting /tmp/akaunting
    rsync -a /tmp/akaunting/ .
    rm -rf /tmp/akaunting
fi

/usr/local/bin/apply-patches.sh

if [ ! -f "vendor/autoload.php" ]; then
    if [ "${APP_ENV}" = "production" ]; then
        composer install --prefer-dist --no-interaction --no-scripts --no-progress --no-ansi --no-dev
    else
        composer install --prefer-dist --no-interaction --no-scripts --no-progress --no-ansi
    fi

    composer dump-autoload
fi

if [ ! -f ".env" ]; then
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

    npm ci
    if [ "${APP_ENV}" = "production" ]; then
        npm run production
    else
        npm run dev
    fi
fi

if [ "${fresh_install}" = true ]; then
    chown -R www-data:www-data .
fi

exec php-fpm
