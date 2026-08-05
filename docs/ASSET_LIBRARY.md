# Godot Asset Library

## Icons

Stores differ on what they call `icon.png`:

| Use | File | Specs |
| --- | --- | --- |
| Plugin / AssetLib **thumbnail** (square) | `addons/QuickActionsAppShortcutsPlugin/icon.png` | 512×512, 1:1, ~16 KB |
| Store **preview / banner** (widescreen) | `icon.png` (repo root) | 1280×720, 16:9, ~100 KB (&lt; 600 KB) |

**Square Icon URL:**

```
https://raw.githubusercontent.com/DawidMoza/quick-actions-app-shortcuts/main/addons/QuickActionsAppShortcutsPlugin/icon.png
```

**16:9 preview URL** (use this if the form requires 1280×720 / 16:9 / ≤600 KB):

```
https://raw.githubusercontent.com/DawidMoza/quick-actions-app-shortcuts/main/icon.png
```


## Description

```
Quick Actions App Shortcuts adds a Send feedback entry to the iOS and Android app-icon long-press menu. Tapping it opens the system mail composer with a pre-filled recipient, subject, and optional device diagnostics.

v0.1 focus: static mailto feedback only. No game-side GDScript or scene node is required. Configuration is a single res://quick_actions_app_shortcuts.cfg file.

Features:
- Home-screen shortcut on Android (App Shortcuts) and iOS (Quick Actions)
- Configurable recipient, menu title, icon, subject, and body templates
- Placeholders filled at tap time: app name, version, OS, device model
- Per-locale overlays for title / subject / body
- Android trampoline opens Mail without starting Godot
- iOS opens Mail from cold and warm quick actions
- Invalid config fails export with a clear error; missing config is a clean no-op

Requirements:
- Godot 4.7+
- Android: Gradle build enabled (shortcuts need API 25+; lower APIs simply omit the shortcut)
- iOS 17.0+: enable QuickActionsAppShortcutsPlugin in the iOS export preset

Install:
1. Unpack into your project root so you get addons/QuickActionsAppShortcutsPlugin/ and ios/plugins/
2. Enable Quick Actions App Shortcuts under Project Settings -> Plugins
3. Copy addons/QuickActionsAppShortcutsPlugin/quick_actions_app_shortcuts.cfg.example to res://quick_actions_app_shortcuts.cfg and set recipient
4. Export Android / iOS as usual

Privacy: no telemetry, network requests, or automatic sending. Mail content is only drafted after the user taps the shortcut and can be edited or discarded.

Docs, changelog, and device testing notes: https://github.com/DawidMoza/quick-actions-app-shortcuts
```

## Download package layout

Asset Library installs use GitHub's archive (or the release zip). Both should contain **only**:

- `addons/QuickActionsAppShortcutsPlugin/` (plugin + LICENSE/README/CHANGELOG inside)
- `ios/plugins/` (`.gdip` + xcframework)

This is enforced by `.gitattributes` `export-ignore` rules. Verify locally:

```bash
git archive --format=zip --output /tmp/qaas-assetlib.zip HEAD
unzip -l /tmp/qaas-assetlib.zip
```

Keep root-level LICENSE/README for the GitHub repo; copies under the addon folder ship with installs.
`./scripts/sync_addon_docs.sh` refreshes LICENSE/CHANGELOG/cfg.example/LICENSES into the addon.
