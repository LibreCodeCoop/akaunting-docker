<!--
SPDX-FileCopyrightText: 2026 LibreCode coop and contributors
SPDX-License-Identifier: GPL-3.0-or-later
-->

# Local Akaunting NFS-e homologation

This is a **shared local development environment**, not a production deployment. Use
only the existing `akaunting-docker` Compose project; do not create parallel permanent
installations. Coordinate migrations and other database writes with the other development
workstreams. Never issue, cancel or transmit real fiscal documents as part of smoke testing.

## Reproducible component baseline (2026-10-25)

| Component | Validated revision/version |
| --- | --- |
| Akaunting Core | tag `3.2.4`, commit `3940b76b` |
| Laravel / PHP | `10.50.3` / `8.3.36` |
| Installed NFS-e module | `LibreCodeCoop/akaunting-nfse` `main` at `03a1d48`; manifest `0.0.0-dev` |
| Scoped NFS-e library | `librecodeoop/nfse-php` commit `2b52325f253db74a0da2ee18a3e1b27a7bfbe31f` |
| MySQL server | `9.7.0` (do not downgrade the existing datadir) |
| PHP / Nginx runtime | current GHCR `:3` PHP image; Nginx rebuilt from the reviewed source on this workstation |
| Local support services | 9.7.0 MySQL and auxiliary images pinned to SHA-256 digests in the ignored local Compose override |

The source revision, module manifest version, `3rdparty/composer.lock` and scoped
`3rdparty/scoped` runtime are distinct. Check all of them after updating the module.
The module uses the Core's native invoices; it does not yet provide a general `/api/nfse`
resource. API architecture is maintained in the NFS-e module repository, not here.

## Files, secrets and local ownership

- Project: `~/projects/akaunting-docker`.
- Core: `volumes/akaunting`; installed module: `volumes/akaunting/modules/Nfse`.
- Persistent DB: `volumes/mysql/data`. Never delete or force-reset these paths.
- Private backups and test evidence: `.local-state/backups/` and `.local-state/evidence/`.
  They are ignored by Git and directory-access restricted to the workstation user.
  Backups stay **inside the project**, not in `~/.local/share` or `/tmp`.
- `.env` and `docker-compose.override.yml` contain local configuration and are never
  committed. Use the versioned `docker-compose.development.example.yml` for local
  helpers and `docker-compose.openbao.example.yml` for an independently configured
  persistent OpenBao deployment. This workstation retains its previously reviewed
  private dev-only OpenBao override; never replace the live override blindly.
- Certificates, fiscal XMLs, passwords, private keys and actual database records do not
  belong in test fixtures, screenshots, Git history or support requests.

## Starting or reproducing the environment

For an existing installation, **do not recopy** templates onto `.env`, the local Compose
override or data volumes. Verify the current project first:

```sh
cd ~/projects/akaunting-docker
docker compose config -q
docker compose up -d --no-build
docker compose ps
./scripts/apply-core-patches.sh
./scripts/verify-local.sh
```

For a new development machine, copy `docker-compose.development.example.yml` to
`docker-compose.override.yml`, then supply local credentials and host-port settings
in a private root `.env` (`0600`). The current base Compose is intentionally
independent of local credentials. The Core must be
checked out at `3.2.4` and the NFS-e module at a reviewed compatible commit under
`volumes/akaunting/modules/Nfse`. On fresh installs only, build the images, install the
Core's lockfile dependencies and compile assets. Run `composer thirdparty:build:prod`
in the module directory to rebuild its scoped fiscal runtime; avoid an extra blind
`composer update`. Never execute migrations on an existing database before backing it
up and reviewing the pending SQL. Existing client installations can have Core patches
and company-specific migrations that need reconciliation.

The current container entrypoint automatically applies reviewed top-level `patches/*.patch`
idempotently, and `scripts/apply-core-patches.sh` permits a manual verification.
That manual command is tag-guarded and idempotent: it recognizes
already-applied patches, refuses conflicts and applies only to the reviewed Core 3.2.4
commit. The patches address local API `AuthenticationException` returning HTTP 500
instead of 401 and the retained HTML editor behavior. Recompile the Core's frontend
(`npm ci` / `npm run production`) after changing editor source. The old
`patches/legacy/akaunting-modifications.patch` is **legacy** and deliberately excluded
from automatic application because it disabled API throttling. Other historical
local plan-limit bypasses remain in the private pre-upgrade backup, not the active
Core or distributed patches.

## Local endpoints and expected behavior

| Service | Local endpoint |
| --- | --- |
| Akaunting UI | `http://127.0.0.1:8082/auth/login` |
| MySQL | `127.0.0.1:3312` (Compose network: `akaunting.mysql:3306`) |
| Mailpit | `http://127.0.0.1:8026` |
| OpenBao dev | `http://127.0.0.1:8205/v1/sys/health` |
| WebDAV/Dufs | `http://127.0.0.1:5005` |

Akaunting must report `APP_ENV=local`. `APP_DEBUG=true` is allowed for this **localhost-only**
development environment. **This workstation's ignored local Compose override**
binds published ports to `127.0.0.1`; the generic upstream base configuration
must not be interpreted as an internet-safe development installation.
OpenBao `server -dev` is ephemeral, intended only for disposable test secrets; never
assume stored credentials survive a container recreation. The queue currently uses
`sync`; async queue processing was not validated by this workstream.

Use `./scripts/verify-local.sh` for a non-destructive smoke check. It checks Core and
NFS-e migration status, login page, unauthenticated NFS-e redirect, API 401 and assets,
plus denial of protected Core source files. It performs **no fiscal gateway actions**.

## Tests completed on the shared local environment

- Scoped Composer production build and Laravel bootstrap passed.
- Core and NFS-e migrations completed with no pending migrations.
- Standalone NFS-e unit suite: PHPUnit 11.5.55 / PHP 8.3.36,
  **1,124 tests**, **5,257 assertions**, **0 failures**, **5 skipped** because
  Eloquent is not bootstrapped in the standalone unit runtime.
- Browser automation used installed Chrome and Playwright; a **temporary synthetic
  admin account** logged in through the real HTTP login form and viewed the NFS-e
  dashboard, fiscal ledger and settings (200). Real Basic Auth returned 200 for
  native `GET /api/companies` and `GET /api/items`, 401 for company 2 without
  membership. The test account was deleted and no fixture remained.
- NFS-e permissions were missing after replacing an older installed module. The
  existing `FinishInstallation` listener was executed only for company 1 after a
  specific permissions/email-template table backup. NFS-e admin settings now
  return 200 for an authorized admin and 403 for an employee-only principal.
- Company 2 remains deliberately **onboarding-incomplete** (`wizard.completed=0`) and
  has no active user membership. With temporary membership and wizard state in a
  **rolled-back transaction**, all four NFS-e read-only views returned 200.
  Neither membership nor wizard state was persisted. Do not change historical
  company ownership or complete its setup merely to pass a development smoke test.
- Core exception handler regression: `AuthenticationException` 401,
  `AccessDeniedHttpException` 403, `NotFoundHttpException` 404.
- Nginx preserves the forwarded external `Host` header **including its port**,
  avoiding broken JavaScript URLs on `localhost:8082`, and denies direct access
  to source files and private keys while keeping
  `/public/` assets and the Laravel front controller operational.

These tests demonstrate local compatibility, not fiscal issuance readiness or an
end-to-end browser workflow for an actual customer. Production, SEFIN and ADN were
never contacted for emission/cancellation. Separate module issues own new NFS-e APIs,
additional tenancy workflows and Behat/API contract coverage.

## Recovery and coordination

Do not run `docker system prune`, `docker compose down -v`, `php artisan update:all`,
`module:update`, destructive seeders or database resets on the shared project. Use
read-only tests or explicit rollback transactions. Record all maintenance in the local
runbook in `.local-state/backups/` and coordinate changes with other workstreams.
Before restoration, stop application services, verify the archive SHA-256 and identify
which database/volume revisions would be overwritten. Do not restore the archived
3.1.21-era SQL/volumes on top of the live updated Core 3.2.4 installation. Never
publish backups or secrets to GitHub.

## Updated runtime integration (2026-10-25)

The local `akaunting-docker` Git checkout was synchronized to the upstream current
`main` revision `6bf4421`. Its new GHCR PHP `:3` runtime was pulled and started,
with the installed Core 3.2.4 and the existing MySQL 9.7.0 data kept in place.
The Nginx runtime is temporarily built locally from this checked-out hardened
configuration under `akaunting-docker-nginx-local:3`; once reviewed and merged,
the official GHCR Nginx image can be rebuilt and released from CI. Do not change
MySQL to the generic `mysql:26.7` base default on this older local datadir without
an independent data compatibility/migration review.

A Chrome/Playwright rerun after switching PHP/Nginx passed UI login, NFS-e dashboard,
ledger and settings (200), native API GETs (200), denied tenant access (401), and
verified the ephemeral synthetic account was removed.
