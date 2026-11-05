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


## Milestone 1 - Today screen and Dynamic Island (done)

- Design system in code (colors, rounded type, glowing ring, pill buttons).
- SwiftData store in the App Group; wear math with unit tests (midnight split, budget, averages).
- Today screen, Take out / Put back in, reason chips, haptics; Liquid Glass tab bar (Today, Trays, History); Settings as a sheet.
- Live Activity: compact, minimal, expanded and Lock Screen layouts; amber turns coral when the out-time budget ends; "Put back in" button via App Intent.
- CI captures simulator screenshots (branch `ci-screenshots`). Reviewed; fixed the action button hidden under the tab bar.
- Note: Live Activity color uses amber to coral via the stale date (no yellow step); Settings is a toolbar button, not a bottom glass circle.
- Not yet checked on a real iPhone: Dynamic Island animations and the button inside the Live Activity.

## Milestone 2 - Trays (done)

- Tray date maths with unit tests (day number, days spent, switch date, early/late).
- Trays screen: segment progress for all trays, current tray card (day X of Y, started, switch date, average wear), history list showing days on each tray against the plan (off-plan counts in amber).
- Start tray sheet: today or yesterday, planned days, next switch date, early/late warning; glass Undo toast after starting.
- Reminder notification on the switch day at 9:00, rescheduled on start and undo.
- Screenshots reviewed (05-trays, 06-start-tray on the `ci-screenshots` branch).

## Milestone 3 - Widgets and controls (done)

- One widget "Aligner wear": Home Screen small (ring + live timer) and medium (ring, tray line, back-by time, interactive Take out / Put back in button); Lock Screen circular and rectangular.
- Control Center toggle (aligners out on/off) and a Shortcuts action usable on the Action Button.
- Both buttons run in the app process (LiveActivityIntent) so they also start/end the Dynamic Island.
- Out-time reminders: 10 minutes before the budget ends and when it ends; cancelled when the aligners go back in.
- Not verified on a device: widgets cannot be screenshotted in CI, so layout is unreviewed. Reminders use the normal interruption level (time-sensitive needs a special entitlement that the CI signing profile does not include).
