#!/bin/sh
# SPDX-FileCopyrightText: 2026 LibreCode coop and contributors
# SPDX-License-Identifier: GPL-3.0-or-later
# Non-destructive checks; no writes, migrations, authentication or fiscal calls.
set -eu
project_dir=$(cd -- "$(dirname -- "$0")/.." && pwd)
cd "$project_dir"
docker compose config -q
if ! docker compose exec -T -u www-data akaunting.php php artisan env --no-ansi | grep -q '\[local\]'; then
    echo 'Laravel effective environment is not local' >&2
    exit 1
fi
docker compose exec -T -u www-data akaunting.php php artisan --version
if docker compose exec -T -u www-data akaunting.php php artisan migrate:status --path=database/migrations --no-ansi | grep -q Pending; then
    echo 'Core has pending migrations' >&2
    exit 1
fi
if docker compose exec -T -u www-data akaunting.php php artisan module:migrate-status nfse --no-ansi | grep -q Pending; then
    echo 'NFS-e has pending migrations' >&2
    exit 1
fi
base_url=http://127.0.0.1:8082
check_status() {
    path=$1
    expected=$2
    actual=$(curl --silent --show-error --max-time 15 --output /dev/null --write-out '%{http_code}' "$base_url$path")
    printf 'GET %-29s HTTP %s\n' "$path" "$actual"
    if [ "$actual" != "$expected" ]; then
        echo "Unexpected HTTP status for $path (expected $expected)" >&2
        exit 1
    fi
}
check_status /auth/login 200
check_status /1/nfse 302
check_status /api/companies 401
check_status /public/css/app.css 200
check_status /public/js/common/documents.min.js 200
check_status /package.json 403
check_status /client.key.pem 403
printf 'Local Akaunting NFS-e preflight PASS (no fiscal requests made).\n'
