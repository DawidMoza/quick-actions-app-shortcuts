# Quick Actions App Shortcuts

Godot 4 plugin that adds a **Send feedback** shortcut to the iOS / Android app-icon long-press menu. Tapping it opens the system mail composer with a pre-filled recipient, subject, and diagnostics.

Full documentation, demo project, and source:  
https://github.com/DawidMoza/quick-actions-app-shortcuts

## Requirements

- Godot **4.7+**
- Android: Gradle Build enabled (shortcuts need API 25+)
- iOS **17.0+**: enable **QuickActionsAppShortcutsPlugin** in the iOS export preset

## Installation

Unpack so your project contains:

- `addons/QuickActionsAppShortcutsPlugin/`
- `ios/plugins/QuickActionsAppShortcutsPlugin.gdip`
- `ios/plugins/QuickActionsAppShortcutsPlugin.xcframework`

Then:

1. Project → Project Settings → Plugins → enable **Quick Actions App Shortcuts**
2. Copy `quick_actions_app_shortcuts.cfg.example` from this folder to
   `res://quick_actions_app_shortcuts.cfg` and set `recipient`
3. Export Android / iOS as usual

Keep the `.cfg` **outside** `addons/` so plugin updates do not overwrite your email settings.

## Usage

```ini
# res://quick_actions_app_shortcuts.cfg
[feedback]
recipient="feedback@example.com"
title="Send feedback"
icon="compose"
subject_template="{{APP_NAME}} feedback"
body_template="Please share your feedback above this line.\n\nApp: {{APP_NAME}}\nVersion: {{APP_VERSION}}\nOS: {{OS_VERSION}}\nDevice: {{DEVICE_MODEL}}"
```

Subject/body templates are **plain text** (mailto), not HTML — use `\n` for line breaks.

## In-game API

Reuse the same config from game code:

```gdscript
var feedback := QuickActionsAppShortcuts.get_feedback_data()
# feedback contains recipient, locale, subject_template, body_template,
# and rendered subject/body with diagnostic placeholders filled.
```

When the editor plugin is enabled, it automatically includes
`res://quick_actions_app_shortcuts.cfg` in exported games. The helper only extracts
localized data; your game remains responsible for opening the mail client.

See [CHANGELOG.md](CHANGELOG.md) for release notes. License: [LICENSE](LICENSE).
