# Repository instructions

## Local experiments

- Keep disposable analysis deliverables (one-off reports, visual comparisons, preview renders, frame dumps, and scripts created solely to produce them) in ignored `temporary/` directories.
- Ignore the entire disposable analysis directory before creating its contents, including one-off helper scripts and configuration. Do not force-add these artifacts.
- This rule does not apply to work-in-progress features, maintained tools, tests, or their supporting code, models, fixtures, and validation reports. Keep those versioned even when they live in a directory named `experiments`.
- Classify files by their purpose and dependencies, not by a directory name or by whether they are unfinished. Do not untrack feature work as analysis cleanup.
- Before committing, inspect staged paths and the diff for disposable analysis artifacts. Unstage any that slipped in while preserving local files.

## Credentials and temporary work

- Before creating temporary files, cleaning files, or touching `.dev/`, read and follow [the credential-protection skill](.agents/skills/protect-dev-credentials/SKILL.md). `.dev/` is exclusively for credentials and their backups; disposable work belongs in ignored `temporary/`.
