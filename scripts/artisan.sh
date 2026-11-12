#!/usr/bin/env bash
set -euo pipefail

# Always run Artisan as the PHP-FPM user. Invoking it as root can create
# root-owned Laravel cache directories, making ordinary web requests fail 500.
if [ "$#" -eq 0 ]; then
    echo "Usage: scripts/artisan.sh <artisan-command> [arguments...]" >&2
    exit 2
fi
service="${AKAUNTING_SERVICE:-akaunting.php}"
docker compose exec -u www-data "${service}" php artisan "$@"
