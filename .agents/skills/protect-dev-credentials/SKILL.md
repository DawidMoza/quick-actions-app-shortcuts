---
name: protect-dev-credentials
description: Protect credentials when creating temporary files, running experiments or previews, cleaning a project, or migrating keys. Use before writing disposable artifacts or touching .dev; .dev is credentials-only and temporary/ is the scratch directory.
---

# Credentials and temporary work

- `.dev/` is exclusively for passwords, private keys, signing files, authentication data, and their backups. Never put logs, captures, reports, helper scripts, experiments, builds, or caches there.
- Put disposable work in the project-root `temporary/` directory. Ensure `/temporary/` is gitignored before creating contents. For Godot projects, keep `temporary/.gdignore` and exclude `temporary/*` from export presets.
- Keep maintained tools, tests, features, fixtures, and their supporting assets versioned. Existing product/build destinations are separate from scratch work; do not move them merely because they are named `output`.
- Before cleanup, inventory files and classify them by purpose and dependencies. Move only identified disposable work into `temporary/`; preserve unknown files for review. Being gitignored never makes a file disposable.
- Never run blanket deletion or cleanup against `.dev/`, including `git clean -fdx`. Keep `.dev/` out of recursive cleanup targets even if it appears empty.
- When migrating credentials, copy them and preserve the originals and backups. Verify the copy without printing secret contents. Never overwrite a different key, commit credentials, or reveal passwords, private keys, authentication cookies, or signed upload URLs.
- Before finishing, confirm `.dev/` contains only credentials and authentication backups, temporary files are ignored, and staged changes contain no secrets or disposable artifacts.
