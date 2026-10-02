#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=.docker/php/shell/lib/akaunting.sh
source "${AKAUNTING_LIB:-/usr/local/lib/akaunting.sh}"

usermod --non-unique --uid "${HOST_UID}" www-data
groupmod --non-unique --gid "${HOST_GID}" www-data

php /usr/local/bin/wait-for-db.php

fresh_install=false

if [ ! -f "${APP_ROOT}/artisan" ]; then
    fresh_install=true
    akaunting_clone
fi

akaunting_apply_patches

if [ ! -f "${APP_ROOT}/vendor/autoload.php" ]; then
    akaunting_install_php_dependencies
fi

if [ ! -f "${APP_ROOT}/.env" ]; then
    akaunting_install_application
fi

if [ "${fresh_install}" = true ]; then
    akaunting_fix_ownership
fi

exec php-fpm
