#!/usr/bin/env bash
# Copies root license/docs into the addon folder for Asset Library downloads.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ADDON_DIR="$ROOT_DIR/addons/QuickActionsAppShortcutsPlugin"

cp "$ROOT_DIR/LICENSE" "$ADDON_DIR/LICENSE"
cp "$ROOT_DIR/CHANGELOG.md" "$ADDON_DIR/CHANGELOG.md"
mkdir -p "$ADDON_DIR/LICENSES"
cp "$ROOT_DIR/LICENSES/Apache-2.0.txt" "$ADDON_DIR/LICENSES/Apache-2.0.txt"
cp "$ROOT_DIR/quick_actions_app_shortcuts.cfg.example" \
	"$ADDON_DIR/quick_actions_app_shortcuts.cfg.example"

echo "Synced license/docs into $ADDON_DIR"
echo "Note: addon README.md and THIRD_PARTY_NOTICES.md are addon-specific; edit them in place."
