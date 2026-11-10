# Save Point — Player Bar Backdrop

- Timestamp: 2026-11-10 (Asia/Makassar)
- Project: `/Users/christambayong/Downloads/Project/Not BitChord`
- Scope: Consolidate requested NotMusic UI corrections from the annotated request through the latest follow-up. Keep the player capsule contents unchanged; remove only its background band.
- Files already changed in the task: icon assets and macOS icon bundling; app version/build remains 1.0.0/build 1; sidebar wordmark sizing; now-playing header and panel controls; `src/ui/shell.rs` player backdrop.
- Latest correction: reverted the capsule opacity/highlight experiment. The pill content/style remains unchanged; only the full-width gradient behind it was removed. Settings footer alignment and the square hover MiniPlayer were also added.
- Checks completed: `cargo check` passed with 39 existing warnings; `git diff --check` passed.
- Build: release rebuild in progress (session 32719).
- Versioning: user clarified that the final edited artifact should advance after existing build 2. Keep version `1.0.0`; final build number is `3`.
- Deliverable: package `NotMusic-v1.0.0-build3-macos-arm64.dmg` in Downloads after the release build completes; verify plist, code signature, DMG, and checksum.
- Known visual limit: the app has not yet been manually launched after the final edit; judge the delivered screenshot/test on whether the backdrop band is gone.
- Next step: finish build, create and verify `NotMusic-v1.0.0-build1-macos-arm64.dmg`, update the daily report, and review Git diff before pushing to the already-authorized private repository.
