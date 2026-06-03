#!/usr/bin/env bash
# Build, sign, notarize, and package RSVP-OS for distribution.
#
# Gatekeeper requires a Developer ID Application certificate and Apple notarization.
# Set these environment variables (or GitHub Actions secrets):
#   APPLE_ID                  Apple ID email
#   APPLE_APP_SPECIFIC_PASSWORD  App-specific password
#   APPLE_TEAM_ID             Team ID (e.g. R3ATUM4YN6)
#   DEVELOPER_ID_APPLICATION  Optional; auto-detected if omitted
#
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIST="$ROOT/dist"
DERIVED="$ROOT/build/DerivedData"
APP="$DERIVED/Build/Products/Release/RSVP-OS.app"
ENTITLEMENTS="$ROOT/Sources/RSVP-OS.entitlements"

cd "$ROOT"
mkdir -p "$DIST"

echo "==> Generating Xcode project"
xcodegen generate

echo "==> Building Release"
xcodebuild \
  -project RSVP-OS.xcodeproj \
  -scheme RSVP-OS \
  -configuration Release \
  -derivedDataPath "$DERIVED" \
  clean build \
  CODE_SIGNING_ALLOWED=NO \
  >/dev/null

if [[ ! -d "$APP" ]]; then
  echo "Build failed: $APP not found" >&2
  exit 1
fi

SIGN_IDENTITY="${DEVELOPER_ID_APPLICATION:-}"
if [[ -z "$SIGN_IDENTITY" ]]; then
  SIGN_IDENTITY="$(security find-identity -v -p codesigning | sed -n 's/.*"\(Developer ID Application:.*\)".*/\1/p' | head -1 || true)"
fi

if [[ -z "$SIGN_IDENTITY" ]]; then
  echo "ERROR: No Developer ID Application certificate found." >&2
  echo "Gatekeeper will block downloads until the app is signed and notarized." >&2
  echo "Create one at https://developer.apple.com/account/resources/certificates/list" >&2
  exit 1
fi

echo "==> Signing with: $SIGN_IDENTITY"
codesign --force --options runtime --timestamp \
  --entitlements "$ENTITLEMENTS" \
  --sign "$SIGN_IDENTITY" \
  "$APP"

echo "==> Verifying signature"
codesign --verify --deep --strict --verbose=2 "$APP"
spctl --assess --type execute --verbose=4 "$APP" || true

VERSION="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$APP/Contents/Info.plist")"
ZIP="$DIST/RSVP-OS-${VERSION}-macOS.zip"
DMG="$DIST/RSVP-OS-${VERSION}-macOS.dmg"

if [[ -n "${APPLE_ID:-}" && -n "${APPLE_APP_SPECIFIC_PASSWORD:-}" && -n "${APPLE_TEAM_ID:-}" ]]; then
  echo "==> Notarizing app"
  ZIP_FOR_NOTARY="$(mktemp -d)/RSVP-OS.zip"
  ditto -c -k --keepParent "$APP" "$ZIP_FOR_NOTARY"
  SUBMISSION="$(xcrun notarytool submit "$ZIP_FOR_NOTARY" \
    --apple-id "$APPLE_ID" \
    --password "$APPLE_APP_SPECIFIC_PASSWORD" \
    --team-id "$APPLE_TEAM_ID" \
    --wait \
    --output-format json)"
  echo "$SUBMISSION"
  echo "==> Stapling app"
  xcrun stapler staple "$APP"
else
  echo "WARNING: Skipping notarization (set APPLE_ID, APPLE_APP_SPECIFIC_PASSWORD, APPLE_TEAM_ID)." >&2
fi

echo "==> Creating DMG"
chmod +x "$ROOT/Scripts/create-dmg.sh"
"$ROOT/Scripts/create-dmg.sh" "$APP" "$VERSION" "$DMG"

if [[ -n "${APPLE_ID:-}" && -n "${APPLE_APP_SPECIFIC_PASSWORD:-}" && -n "${APPLE_TEAM_ID:-}" ]]; then
  echo "==> Notarizing DMG"
  xcrun notarytool submit "$DMG" \
    --apple-id "$APPLE_ID" \
    --password "$APPLE_APP_SPECIFIC_PASSWORD" \
    --team-id "$APPLE_TEAM_ID" \
    --wait
  xcrun stapler staple "$DMG"
fi

echo "==> Creating zip"
ditto -c -k --sequesterRsrc --keepParent "$APP" "$ZIP"

echo ""
echo "Done:"
echo "  $DMG"
echo "  $ZIP"
