#!/usr/bin/env bash
# Builds a drag-to-Applications DMG for RSVP-OS.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_PATH="${1:?Usage: create-dmg.sh /path/to/RSVP-OS.app [version] [output.dmg]}"
VERSION="${2:-$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$APP_PATH/Contents/Info.plist")}"
OUTPUT="${3:-$ROOT/dist/RSVP-OS-${VERSION}-macOS.dmg}"
BACKGROUND="$ROOT/Scripts/dmg-background.png"
STAGING="$(mktemp -d)"

cleanup() { rm -rf "$STAGING"; }
trap cleanup EXIT

mkdir -p "$(dirname "$OUTPUT")"
cp -R "$APP_PATH" "$STAGING/RSVP-OS.app"
ln -s /Applications "$STAGING/Applications"

if command -v create-dmg >/dev/null 2>&1 && [[ -f "$BACKGROUND" ]]; then
  create-dmg \
    --volname "RSVP-OS" \
    --background "$BACKGROUND" \
    --window-pos 200 120 \
    --window-size 660 400 \
    --icon-size 96 \
    --icon "RSVP-OS.app" 170 190 \
    --hide-extension "RSVP-OS.app" \
    --app-drop-link 490 190 \
    --no-internet-enable \
    --skip-jenkins \
    "$OUTPUT" \
    "$STAGING"
else
  echo "Using simple DMG layout (install create-dmg for drag-and-drop background)." >&2
  hdiutil create -volname "RSVP-OS" -srcfolder "$STAGING" -ov -format UDZO "$OUTPUT" >/dev/null
fi

echo "Created $OUTPUT"
