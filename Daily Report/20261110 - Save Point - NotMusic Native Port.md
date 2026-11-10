# Save Point — NotMusic Native Port

Date: 2026-11-10 (Asia/Makassar)
Project: `/Users/christambayong/Downloads/Project/Not BitChord`
Source: `/Users/christambayong/Downloads/Project/BitChord Sample`
Objective: create NotMusic 1.0.0 as a native Rust desktop app, preserve the Sample architecture, enrich the cover/lyrics player and floating MiniPlayer with controls from the existing BitChord macOS project, and add in-app update check/download.

## Starting state

- The destination contains the user-provided `Glossy Pink Musical Note Icon.png` and an empty `Daily Report/` folder.
- BitChord Sample is a Rust/egui/rodio application; no React frontend is present in that source tree.
- The Sample already has a synced-lyrics full-screen overlay, a separate floating MiniPlayer, and an automatic GitHub updater. Its updater currently targets another repository and will need a NotMusic-specific release target.
- The user confirmed the future updater repository should be `fumakill4/NotMusic` and requested the GitHub repository be private initially.
- Private GitHub Releases require authentication. Never embed a personal token in the app. The user confirmed updater access should become active after the repository is public. The implementation checks the public repository endpoint without storing a token; GitHub returns 404 while it is private.

## Files changed

- The Sample project has been copied into this destination. The detailed implementation and verification are recorded in `20261110 - NotMusic 1.0.0 Native Rust Port.md`.

## Verification

- Inspected source manifests, now-playing UI, MiniPlayer, updater, app bundle metadata, and existing BitChord macOS updater.
- No build or test run yet.

## Risks / next step

- Determine a secure private-release update path. Then mirror the Sample source into this destination, preserving the user icon and reports folder, and apply NotMusic branding/version 1.0.0 plus the requested player enhancements.
