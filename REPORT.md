# Inly — Progress report

Last updated: 2026-11-05

## Status
Milestone 0 (foundation) in progress.

## Done
- M0.1 README, repo connected, push access verified
- M0.2 SPEC.md, ROADMAP.md, REPORT.md
- M0.3 Xcode project (XcodeGen): app, widget extension, App Group, tests, placeholder icon. Not yet compiled; first CI run will verify.
- M0.4 CI workflow: XcodeGen, build and unit tests on a macOS runner for every push. First run: green.
- M0.5 TestFlight workflow (manual or on tag): archive, cloud signing with the API key, upload.
- M0.6 Setup guide in `docs/SETUP.md`.

## In progress
- First TestFlight upload. Admin key works: archive, cloud signing, export and upload to Apple all run. Remaining steps below.

## Blockers
- **Register one iPhone** (UDID) in the developer portal. Without a device Apple will not create the development profile, so the archive cannot be signed and the exported app loses its App Group entitlement. Steps in `docs/SETUP.md`.

## Fixed along the way
- App was set to iPhone and iPad; Apple rejected the upload for missing iPad orientations. Now iPhone-only.
- Workflow now fails early if the App Group entitlement is missing, instead of uploading a broken build.

## How to test
Builds are uploaded to TestFlight at the end of each milestone. Install the TestFlight app on your iPhone and accept the invite for `Inly`.
