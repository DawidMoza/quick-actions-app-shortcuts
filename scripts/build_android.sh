#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ANDROID_DIR="$ROOT_DIR/android"
ADDON_BIN="$ROOT_DIR/addons/QuickActionsAppShortcutsPlugin/bin"

if [[ -z "${ANDROID_HOME:-}" && -d "$HOME/Library/Android/sdk" ]]; then
	export ANDROID_HOME="$HOME/Library/Android/sdk"
fi

if [[ -z "${ANDROID_HOME:-}" ]]; then
	echo "ANDROID_HOME is not set."
	exit 1
fi

# AGP does not support the newest JDKs yet; prefer 17 when available.
if [[ -z "${JAVA_HOME:-}" || "$(java -version 2>&1 | head -n1)" == *"25."* ]]; then
	if [[ -d "/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home" ]]; then
		export JAVA_HOME="/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home"
	elif [[ -d "/opt/homebrew/opt/openjdk@17" ]]; then
		export JAVA_HOME="/opt/homebrew/opt/openjdk@17"
	fi
fi
if [[ -n "${JAVA_HOME:-}" ]]; then
	export PATH="$JAVA_HOME/bin:$PATH"
	echo "Using JAVA_HOME=$JAVA_HOME"
fi

mkdir -p "$ADDON_BIN/debug" "$ADDON_BIN/release"

if [[ ! -f "$ANDROID_DIR/gradlew" ]]; then
	echo "Gradle wrapper missing. Generating..."
	(cd "$ANDROID_DIR" && gradle wrapper --gradle-version 8.9)
fi

(
	cd "$ANDROID_DIR"
	./gradlew --no-daemon clean assembleDebug assembleRelease copyAarToAddon
)

echo "Android AARs copied to:"
ls -la "$ADDON_BIN/debug" "$ADDON_BIN/release"
