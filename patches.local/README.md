# Local patches

Place deployment-specific `*.patch` files in this directory.

Patch files in this directory are intentionally ignored by Git. They are mounted read-only into the PHP container and applied automatically after the committed patches in `../patches`.

This allows a local deployment to keep private modifications without publishing them in this repository.

Applying a local patch does not change the license terms that govern Akaunting. The deployment remains responsible for complying with the license that applies to the installed Akaunting version.
