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
- First TestFlight upload: archive works; export blocked on API key role (see Blockers)

## Blockers
- **TestFlight export fails: "Cloud signing permission error".** The App Store Connect API key has the App Manager role, which cannot create the cloud-managed distribution certificate. Fix: create a new API key with the **Admin** role and replace the `ASC_KEY_ID` and `ASC_KEY_P8` secrets (`ASC_ISSUER_ID` stays the same).

## How to test
Builds are uploaded to TestFlight at the end of each milestone. Install the TestFlight app on your iPhone and accept the invite for `Inly`.
