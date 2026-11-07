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

## Milestone 4 - History and polish (done)

- History: 7-day bars with goal line, 4-week calendar heatmap (green = goal met, amber = within 2h, coral = missed, blue = today in progress), daily average and goals-met count. Days before you started tracking are not counted.
- Settings: goal, reminders on/off, total trays, default days per tray.
- Accessibility: text follows Dynamic Type (up to 20pt styles), the glow animation respects Reduce Motion, VoiceOver labels on the ring, heatmap days and the main button.
- Dark launch screen (no white flash); App Store draft in `docs/APPSTORE.md`.

### What still needs you
- Install the TestFlight build on an iPhone with iOS 26 and try: Take out (Dynamic Island + Lock Screen), Put back in from the Island, widgets, the Control Center toggle, Start tray + Undo.
- Real app icon artwork (the current one is a generated placeholder), support URL and privacy policy URL before any App Store submission.
- Ideas for later: iCloud sync, CSV export for the orthodontist, Apple Watch.

## Milestone 5 - Feedback round 1 (done)

- Ring: worn time against the daily goal (no longer always full). Take out is blue, Put back in is orange (app, widgets, Dynamic Island).
- Widgets and Lock Screen show out-time left today (live countdown while out).
- First-launch setup: name, tray you are on, total trays, planned days, which day you are on, daily goal. Settings has "Redo first-time setup".
- Trays: days over the plan show as "+N days" (Today card, Trays card); "Extend plan" adds days on purpose; the reminder follows.
- Trays screen rebuilt from the design (dotted progress, glowing current card, history rows with on plan / -N / +N), start-tray sheet as designed, swipe left to delete with Undo (deleting the current tray reopens the previous one).
- Settings is now the detached glass circle next to the tab bar (iOS 26 search-role tab); the gear is gone.
- Greeting with your name, richer tray card (tap opens Trays), 24-hour timeline of today's breaks, "Left" stat card.
- History: real monthly calendar (swipe or arrows, tray start and switch-day dots); tap a day to see breaks, edit, delete, or add a missed break. Undo toast after Take out / Put back in.
- Found by screenshot review and fixed: calendar days 1-6 missing (SwiftUI id collision), sheet content centered instead of top-aligned.
- Not verified on device: widgets, Control Center toggle, the Settings tab shape.

## Fixes after build 14 test
- Worn time now counts from the moment setup finished (before it was counted from midnight, so day 1 started at 21h). Days before you started have no data in History and averages.
- Widgets: ring no longer overlaps the text, timer is centered, "left" label sits next to the countdown, one ring instead of two; the out-ring fills every 5 minutes.
- "Put back in" from the widget / Dynamic Island: faster (widget reload first, the Live Activity update is awaited before the process sleeps).
- Not possible: haptics on widget or Dynamic Island buttons (WidgetKit has no API). Control Center toggle and the Action Button give the system haptic.
- Build signing: certificate is kept until the next run (fixes 90721).

## Milestones 6–8 (builds 18–19)

**M6 fixes (build 18):** "Still out?" reminders now have a one-tap switch per reason plus time presets; the notification handler was rewritten (completion-handler delegate) after a tap crash; Settings icon is a gear; widgets read a small App Group snapshot (`WidgetSnapshot`) instead of opening SwiftData.

**Widget empty while out (still open):** build 18 still showed an empty widget during Take out. New theory: widgets and the Live Activity share one extension process, so the out-state timeline was trimmed to ≤7 entries. Needs device confirmation.

**M7 Apple Watch:** `InlyWatch` target (bundle `com.bzrmed.inly.watchkitapp`), WatchConnectivity (application context for state, `sendMessage`/`transferUserInfo` for explicit takeOut/putBackIn commands). CI registers the bundle ID and creates the profile. Limit: a Live Activity cannot be *started* while the app is in the background, so Take out from the watch may not start the Dynamic Island. No complications yet.

**M8 Tray photos, notes, appointment:** `Tray.photoData` (external storage), `TrayNote` model, `TrayDetailSheet` (PhotosPicker + quick-note chips), `AppointmentSheet` with evening-before and morning-of reminders. Unit tests for the reminder planning.

## Milestones 9–11 (build 20)

- **Export:** History → share icon. PDF report (summary, streak, trays, notes, daily table) or CSV per day / per break, over 7 days, 30 days or everything. Shared with the system share sheet.
- **Photos:** camera (system camera, needs the new camera permission text) or library; Trays → "Compare photos" (slider or side by side) once two trays have photos.
- **Insights:** streak and best streak on History; estimated finish date on Trays (remaining days of the current tray plus the default days for each remaining tray). Unit tests cover streaks, forecast, CSV and PDF generation.

## Milestones 12-14: onboarding tour, new icon, backup
- Animated onboarding (welcome, Dynamic Island, widgets, name, tray, goal, reminders, done).
- New app icon: white rounded "inly" wordmark with blue dot on Night (app + watch).
- Backup: Settings > Backup. Back up now / Restore (JSON file via Files or iCloud Drive) and an optional automatic backup into a chosen iCloud Drive folder (at most hourly, when the app goes to background). Restore replaces all data after confirmation. Real-time CloudKit sync is not built (needs iCloud container setup in the Apple developer portal).

## Milestones 15-16: watch hero timer, guided camera
- Watch: the screen edge is the progress ring; large timer, time left, one big button.
- Camera: custom camera with smile guide, faint ghost of the previous tray's photo, 3-second timer, front/back switch, retake/use review.
