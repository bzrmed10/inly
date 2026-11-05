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
- Nothing. Milestone 0 is complete. Next: Milestone 1 (core tracking + Dynamic Island).

## Blockers
None.

## Milestone 0 result
- First build uploaded to App Store Connect (delivery UUID 81202ced-2a0a-4539-aed4-32a5b26c9ad4). It is a placeholder screen; it proves the full pipeline works: build, sign, upload.
- Signing needs no Mac and no registered device: a temporary distribution certificate and profiles are created and revoked in every run.
- The App Group entitlement is verified inside the exported app and widget extension on every run.

## How to test
Builds are uploaded to TestFlight at the end of each milestone. Install the TestFlight app on your iPhone and accept the invite for `Inly`.
