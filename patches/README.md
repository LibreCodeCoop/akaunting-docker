# Application patches

Files in this directory are committed patches that are safe to distribute with this repository.

They are applied automatically, in filename order, during first setup and explicit Akaunting upgrades.

The installed Akaunting checkout keeps its upstream `LICENSE.txt`. Applying a patch does not change the license terms that govern the installed Akaunting version. See the upstream license shipped with Akaunting for the applicable terms.

## Local Akaunting 3.2.4 fixes

The two root-level `akaunting-3.2.4-*.patch` files are automatically applied
idempotently at setup by the versioned Docker runtime, with conflict detection:

- `akaunting-3.2.4-api-auth-401.patch` fixes the Core's HTTP status mapping for
  `AuthenticationException` (401 rather than 500), confirmed by regression tests.
- `akaunting-3.2.4-editor.patch` retains the LibreCode HTML editor customization.
  Recompile Akaunting assets after applying this patch to a clean checkout.

`legacy/akaunting-modifications.patch` is archived, **not applied automatically**:
its previous Core behavior disabled API request throttling and no longer matches
Core 3.2.4. Historical changes are preserved for audit. Do not move it back to
this directory without a new technical and security review.

See `docs/local-nfse-homologation.md` for the reviewed Core tag and test steps.
