#!/bin/bash
set -e

# Set uid of host machine
usermod --non-unique --uid "${HOST_UID}" www-data
groupmod --non-unique --gid "${HOST_GID}" www-data

AKAUNTING_DATA_DIR="${AKAUNTING_DATA_DIR:-/var/www/akaunting-data}"

mkdir -p "${AKAUNTING_DATA_DIR}/storage" "${AKAUNTING_DATA_DIR}/bootstrap/cache" "${AKAUNTING_DATA_DIR}/modules"

if [ ! -f "${AKAUNTING_DATA_DIR}/.env" ]; then
    cp /var/www/html/.env.example "${AKAUNTING_DATA_DIR}/.env"
fi

if [ ! -e /var/www/html/.env ] || [ ! /var/www/html/.env -ef "${AKAUNTING_DATA_DIR}/.env" ]; then
    rm -f /var/www/html/.env
    ln -s "${AKAUNTING_DATA_DIR}/.env" /var/www/html/.env
fi

if [ ! -e /var/www/html/storage ] || [ ! /var/www/html/storage -ef "${AKAUNTING_DATA_DIR}/storage" ]; then
    if [ -d /var/www/html/storage ] && [ ! -d "${AKAUNTING_DATA_DIR}/storage/framework" ]; then
        rsync -a /var/www/html/storage/ "${AKAUNTING_DATA_DIR}/storage/"
    fi
    rm -rf /var/www/html/storage
    ln -s "${AKAUNTING_DATA_DIR}/storage" /var/www/html/storage
fi

if [ ! -e /var/www/html/bootstrap/cache ] || [ ! /var/www/html/bootstrap/cache -ef "${AKAUNTING_DATA_DIR}/bootstrap/cache" ]; then
    if [ -d /var/www/html/bootstrap/cache ]; then
        rsync -a /var/www/html/bootstrap/cache/ "${AKAUNTING_DATA_DIR}/bootstrap/cache/"
    fi
    rm -rf /var/www/html/bootstrap/cache
    ln -s "${AKAUNTING_DATA_DIR}/bootstrap/cache" /var/www/html/bootstrap/cache
fi

if [ ! -e /var/www/html/modules ] || [ ! /var/www/html/modules -ef "${AKAUNTING_DATA_DIR}/modules" ]; then
    if [ -d /var/www/html/modules ] && [ -z "$(find "${AKAUNTING_DATA_DIR}/modules" -mindepth 1 -maxdepth 1 -print -quit)" ]; then
        rsync -a /var/www/html/modules/ "${AKAUNTING_DATA_DIR}/modules/"
    fi
    rm -rf /var/www/html/modules
    ln -s "${AKAUNTING_DATA_DIR}/modules" /var/www/html/modules
fi

chown -R www-data:www-data "${AKAUNTING_DATA_DIR}" /var/www/html

php /usr/local/bin/wait-for-db.php

if ! grep -q '^APP_KEY=base64:' "${AKAUNTING_DATA_DIR}/.env"; then
    php artisan key:generate
fi

if ! grep -q '^APP_INSTALLED=true' "${AKAUNTING_DATA_DIR}/.env"; then
    php artisan install --no-interaction --db-host="${DB_HOST}" --db-port="${DB_PORT}" --db-name="${DB_DATABASE}" --db-username="${DB_USERNAME}" --db-password="${DB_PASSWORD}" --db-prefix="${DB_PREFIX}" --admin-email="${ADM_EMAIL}" --admin-password="${ADM_PASSWD}"
fi

exec php-fpm
