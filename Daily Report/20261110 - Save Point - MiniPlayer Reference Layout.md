# Save Point — MiniPlayer Reference Layout

- Timestamp: 2026-11-10 (Asia/Makassar)
- Project: `/Users/christambayong/Downloads/Project/Not BitChord`
- Active objective: finish the NotMusic desktop edit from the user's annotated request through the latest messages; keep app version `1.0.0`, final build `3` (build 2 already exists and user says edited builds must increment).
- Existing source changes: icon alpha cleanup and ICNS bundling, sidebar wordmark fit, main-player header/lyrics controls, removed full-width gradient behind the bottom capsule, centered Settings footer, stable local signing support.
- User clarification: do not change the cover+lyrics main layout or the contents/style inside the bottom capsule. Only remove the separate rectangle behind it. Keep the capsule untouched.
- User also requested the BitChord-style square floating MiniPlayer: full artwork background, title/artist, reveal-on-hover control deck, playback/seek/like/volume plus accessible window controls.
- Previous verification: `cargo check`, `git diff --check`, and `sh -n macos/bundle.sh` passed. `cargo build --release` passed before the latest footer/signing/MiniPlayer edits.
- Risks: UI runtime has not yet been visually exercised after edits. Keychain will require the user to authorize the existing `ytm-rs` Keychain item once with “Always Allow”; the stable signer should make later launches/rebuilds use a consistent identity.
- Next: square MiniPlayer has now been implemented. Rebuild, package and verify the build 3 DMG, update report, review and push authorized private repo.
