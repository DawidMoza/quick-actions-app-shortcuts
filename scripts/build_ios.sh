#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLUGIN_DIR="$ROOT_DIR/ios/plugin"
OUT_DIR="$ROOT_DIR/ios/plugins"
BUILD_DIR="$PLUGIN_DIR/build"
FRAMEWORK_NAME="QuickActionsAppShortcutsPlugin"
MIN_IOS="17.0"

mkdir -p "$BUILD_DIR/obj" "$OUT_DIR"

# Localization overlays are generated at export time by the EditorExportPlugin
# (addons/.../generated/ios). Do not ship .lproj next to the .gdip — that
# duplicates bundle_file injection and breaks Xcode ("Multiple commands produce").
rm -rf "$OUT_DIR"/*.lproj

SDK_PATH="$(xcrun --sdk iphoneos --show-sdk-path)"
CLANG="$(xcrun --sdk iphoneos --find clang)"

rm -rf "$BUILD_DIR/obj"
mkdir -p "$BUILD_DIR/obj"

compile_one() {
	local src="$1"
	local base
	base="$(basename "$src")"
	base="${base%.*}"
	local lang_flags=()
	case "$src" in
		*.mm) lang_flags=(-x objective-c++) ;;
		*.m) lang_flags=(-x objective-c) ;;
		*.cpp|*.cc) lang_flags=(-x c++) ;;
	esac
	# Language must come before the input file.
	"$CLANG" "${lang_flags[@]}" -c "$src" \
		-o "$BUILD_DIR/obj/${base}.o" \
		-isysroot "$SDK_PATH" \
		-arch arm64 \
		-miphoneos-version-min="$MIN_IOS" \
		-fobjc-arc \
		-fmodules \
		-fcxx-modules \
		-I"$PLUGIN_DIR" \
		-O2
}

SOURCES=(
	"$PLUGIN_DIR/QAASFeedbackHandler.m"
	"$PLUGIN_DIR/QuickActionsAppShortcutsPlugin.mm"
)

for src in "${SOURCES[@]}"; do
	compile_one "$src"
done

DEVICE_LIB="$BUILD_DIR/lib${FRAMEWORK_NAME}.a"
libtool -static -o "$DEVICE_LIB" "$BUILD_DIR"/obj/*.o

HEADERS_DIR="$BUILD_DIR/headers"
rm -rf "$HEADERS_DIR"
mkdir -p "$HEADERS_DIR"
cp "$PLUGIN_DIR/QuickActionsAppShortcutsPlugin.h" "$HEADERS_DIR/"
cp "$PLUGIN_DIR/QAASFeedbackHandler.h" "$HEADERS_DIR/"

rm -rf "$OUT_DIR/$FRAMEWORK_NAME.xcframework"
xcodebuild -create-xcframework \
	-library "$DEVICE_LIB" \
	-headers "$HEADERS_DIR" \
	-output "$OUT_DIR/$FRAMEWORK_NAME.xcframework"

echo "iOS xcframework ready:"
ls -la "$OUT_DIR/$FRAMEWORK_NAME.xcframework"
