# Contributing

Thanks for helping improve Quick Actions App Shortcuts.

## Requirements

- Godot **4.7+**
- Android builds: JDK **17**, Android SDK
- iOS builds: macOS + Xcode (deployment target **17.0**)

## Project layout

| Path | Role |
| ---- | ---- |
| `addons/QuickActionsAppShortcutsPlugin/` | Editor plugin + shipped AARs |
| `android/` | Android library sources (Kotlin / resources) |
| `ios/plugin/` | iOS ObjC/ObjC++ sources |
| `ios/plugins/` | Built `.gdip` + `.xcframework` for Godot export |
| `demo/` | Runnable sample project |
| `scripts/` | Native build scripts |

`demo/addons` and `demo/ios` symlink to the repo roots so the demo always uses the current plugin.
On Windows, enable Developer Mode and Git symlink support before cloning
(`git config --global core.symlinks true`), or the demo links may be checked out as plain files.

## Build native binaries

```bash
./scripts/build_android.sh   # → addons/.../bin/{debug,release}/*.aar
./scripts/build_ios.sh       # → ios/plugins/*.xcframework (+ cleans leftover .lproj)
```

Commit rebuilt binaries when a release changes native code.

## Demo / device testing

1. Open `demo/` in Godot 4.7+.
2. Set a real inbox in `demo/quick_actions_app_shortcuts.cfg`.
3. Android: **Project → Install Android Build Template**, then Remote Debug.
4. iOS: enable the plugin in the iOS export preset, then Remote Debug.
5. Long-press the app icon → **Send feedback**.

See [docs/TESTING.md](docs/TESTING.md) for the full checklist.

## Automated checks

[`.github/workflows/ci.yml`](.github/workflows/ci.yml) loads the demo in Godot
4.7.1 and rebuilds both native libraries on pushes to `main` and pull requests.

## Pull requests

- Keep changes focused; match existing style.
- Rebuild Android/iOS artifacts if you touch native code or resources.
- Update [CHANGELOG.md](CHANGELOG.md) under `[Unreleased]` when the change is user-visible.
- Do not commit `demo/android/` or `**/generated/` overlays.

## Asset Library package

- `.gitattributes` limits `git archive` / AssetLib downloads to `addons/` + `ios/plugins/`.
- Keep LICENSE / README / CHANGELOG / notices inside `addons/QuickActionsAppShortcutsPlugin/`
  (AssetLib users only keep that folder).
- After editing root `LICENSE`, `CHANGELOG.md`, or the cfg example, run
  `./scripts/sync_addon_docs.sh` (addon `README.md` / `THIRD_PARTY_NOTICES.md` are edited in place).

## Versioning / releases

- Version lives in `addons/QuickActionsAppShortcutsPlugin/plugin.cfg`.
- Tag releases as `v0.1.0`, `v0.2.0`, … (semver).
- Pushing a `v*` tag runs [.github/workflows/release.yml](.github/workflows/release.yml) and publishes a zip.
- Before tagging, update the plugin version, README badge, demo Android/iOS versions,
  and [CHANGELOG.md](CHANGELOG.md), then sync addon docs. The release workflow rejects
  tags that do not match `plugin.cfg`.
