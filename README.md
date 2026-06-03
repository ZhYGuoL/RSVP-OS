# RSVP-OS

A native macOS menu bar app that turns any on-screen text into fast RSVP reading. Select a region, OCR runs locally, and words stream one at a time from a drop-down notch UI.

**Requires macOS 14 or later.**

## Download

Get the latest build from [Releases](https://github.com/ZhYGuoL/RSVP-OS/releases/latest):

1. Download `RSVP-OS-*-macOS.dmg` (or the `.zip` fallback)
2. Open the DMG and drag **RSVP-OS** to Applications
3. Launch the app (see [First launch](#first-launch) below)

## Quick start

1. Launch RSVP-OS — it lives in the menu bar (text viewfinder icon)
2. Press **⌘⇧R** or choose **Read Selected Region…** from the menu
3. Drag to select the text you want to read
4. When the notch opens, press **Space** to start
5. Use **← / →** to step words, **↑ / ↓** to change speed, **Esc** to close

## First launch

Because RSVP-OS is distributed outside the App Store, macOS may block it the first time:

1. Right-click **RSVP-OS.app** in Applications
2. Choose **Open**
3. Confirm **Open** in the dialog

You only need to do this once.

### Permissions

RSVP-OS needs **Screen Recording** permission to capture the region you select. macOS will prompt you, or you can enable it in **System Settings → Privacy & Security → Screen Recording**.

All OCR runs on-device with Apple Vision — nothing is sent to the cloud.

## Build from source

```bash
brew install xcodegen   # if needed
xcodegen generate
xcodebuild -project RSVP-OS.xcodeproj -scheme RSVP-OS -configuration Release build
```

The app bundle is written to `build/DerivedData/Build/Products/Release/RSVP-OS.app`.

### Signed release (no Gatekeeper warning)

Public downloads must be signed with a **Developer ID Application** certificate and notarized by Apple:

```bash
brew install xcodegen create-dmg
export APPLE_ID="you@example.com"
export APPLE_APP_SPECIFIC_PASSWORD="xxxx-xxxx-xxxx-xxxx"
export APPLE_TEAM_ID="YOUR_TEAM_ID"
./Scripts/package-release.sh
```

Add the same values as GitHub Actions secrets (`APPLE_ID`, `APPLE_APP_SPECIFIC_PASSWORD`, `APPLE_TEAM_ID`, `APPLE_CERTIFICATE_BASE64`, `APPLE_CERTIFICATE_PASSWORD`, `DEVELOPER_ID_APPLICATION`) to produce signed releases on tag push.

## License

MIT — see [LICENSE](LICENSE) if present.
