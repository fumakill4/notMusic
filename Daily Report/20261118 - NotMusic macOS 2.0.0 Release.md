# Daily Report — 18 November 2026

## notMusic macOS 2.0.0

- Improved mini-player artwork frosting so the gradient reaches behind the metadata while keeping the lower blur stronger.
- Fixed mini-player resizing stutter by waiting for native window resizing to settle before restoring the square aspect ratio.
- Kept mini-player controls at stable sizes and disabled always-on-top by default.
- Added update availability notices and an in-app DMG download flow. The DMG downloads from the matching GitHub release asset into Downloads, reports progress in Version & Updates, and can be revealed in Finder after completion.
- Bumped the app version to 2.0.0 and generated the Apple Silicon release DMG with the notMusic pink note icon embedded in `Contents/Resources/notmusic.icns`.

## Release artifacts

- App: `dist/release/NotMusic.app`
- DMG: `dist/release/NotMusic-v2.0.0-macos-arm64.dmg`
- Manifest: `release.json`
- DMG SHA-256: `7e280716ee4da8883578cdd8f2c755b26cd4a09715f725fbb3577b8a702a82e9`

The DMG checksum and mounted contents were verified. The app bundle signature verifies and the bundle icon file is present. This is an Apple Development signed test build; no notarization credentials were available on this Mac.
