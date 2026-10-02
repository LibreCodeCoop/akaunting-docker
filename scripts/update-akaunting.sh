#!/usr/bin/env bash
set -euo pipefail

service="${AKAUNTING_SERVICE:-akaunting.php}"

docker compose exec "${service}" /usr/local/bin/update-akaunting.sh
