#!/bin/bash
if [ ! -f "vendor/autoload.php" ]; then
    git clone --progress -b "${AKAUNTING_VERSION}" --single-branch --depth 1 https://github.com/akaunting/akaunting /tmp/akaunting
    rsync -r /tmp/akaunting/ .
    rm -rf /tmp/akaunting
    composer install
    php artisan install --no-interaction --db-host="${DB_HOST}" --db-port="${DB_PORT}" --db-name="${DB_DATABASE}" --db-username="${DB_USERNAME}" --db-password="${DB_PASSWORD}" --db-prefix="${DB_PREFIX}" --admin-email="${ADM_EMAIL}" --admin-password="${ADM_PASSWD}"
    php artisan key:generate
    chown -R www-data:www-data .
fi
php-fpm
