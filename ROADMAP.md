# Inly — Roadmap

One task = one commit. Mark `[x]` when committed and CI is green. Progress is summarized in `REPORT.md`.

## Milestone 0 — Foundation
- [x] M0.1 README
- [x] M0.2 SPEC.md, ROADMAP.md, REPORT.md
- [x] M0.3 Xcode project via XcodeGen (`project.yml`): app target `Inly`, extension `InlyWidgets`, iOS 26, App Group, Live Activities + push entitlements, minimal SwiftUI app
- [x] M0.4 CI: build + test on macOS runner on every push
- [x] M0.5 TestFlight workflow (manual trigger and on tag): archive, sign with ASC API key, upload
- [x] M0.6 Setup guide for secrets and first TestFlight install (`docs/SETUP.md`)

## Milestone 1 — Core tracking + Dynamic Island (first TestFlight)
- [x] M1.1 Design system in code: color tokens, rounded type styles, `GlowRing` view with animation
- [x] M1.2 Data layer: SwiftData models (`WearSession`, `Tray`, `Settings`) in the App Group store
- [x] M1.3 Wear math (`WearCalculator`) + unit tests (midnight split, budget, averages)
- [x] M1.4 Today screen: ring, timer, reason chips, stat cards, Take out / Put back in, haptics
- [x] M1.5 Liquid Glass tab bar and navigation shell (Today, Trays, History, Settings)
- [x] M1.6 Live Activity: attributes, start/end on state change, compact / minimal / expanded / Lock Screen views
- [x] M1.7 `PutBackInIntent` (App Intent) wired into the Live Activity button
- [x] M1.8 Screenshot job in CI (simulator screenshots of key screens attached to the run)
- [x] M1.9 TestFlight build 1

## Milestone 2 — Trays
- [x] M2.1 Tray model logic: current tray, planned days, switch date
- [x] M2.2 Trays screen: segments, current tray card, history list
- [x] M2.3 Start tray sheet with Undo toast and early/late warnings
- [x] M2.4 Tray switch notification

## Milestone 3 — Widgets and controls
- [x] M3.1 Home Screen widgets (small, medium interactive)
- [x] M3.2 Lock Screen accessory widgets
- [x] M3.3 Control Center toggle + Action Button intent
- [x] M3.4 Out-time reminder notifications (time-sensitive)

## Milestone 4 — History and polish
- [x] M4.1 History screen: 7-day bars, 4-week heatmap, stats
- [x] M4.2 Settings screen
- [x] M4.3 Accessibility pass (VoiceOver, Dynamic Type, contrast)
- [x] M4.4 App icon, launch screen, App Store metadata draft

## Milestone 5 — Feedback round 1 (after first TestFlight test)
Order: quick fixes first, then the bigger screens.
- [x] M5.1 Colors and ring: ring shows worn time against the daily goal (worn ÷ 22h, no longer always full); "Take out" is blue (matches the in-ring), "Put back in" is orange (matches the out-ring) in the app, widgets and Live Activity
- [x] M5.2 Widgets: show out-time left today ("35m left") on small, medium and Lock Screen rectangular
- [ ] M5.3 First-launch setup: pick current tray number, total trays, planned days for this tray and which day you are on; no more silent "tray 1, day 1"
- [ ] M5.4 Tray overage and extend: after the planned days the tray counts "+1 day, +2 days" automatically; "Extend" button adds planned days on purpose; Today card and reminder follow
- [ ] M5.5 Trays screen rebuilt to match the design exactly (header, dotted progress, glowing current card, history rows with number badge, days, progress bar, average wear, on plan / −N days / +N days)
- [ ] M5.6 Swipe left to delete a tray (with Undo)
- [ ] M5.7 Settings as the detached glass circle next to the tab bar (as in the design); gear button removed
- [ ] M5.8 Greeting with the user's name: "Good morning / afternoon / evening, Name!" with the small date line above (asked in setup, editable in Settings)
- [ ] M5.9 Today cards redesigned: richer tray card (badge, day dots, "switch in N days", +N days chip, tap opens Trays) and a 24-hour day strip showing today's out periods
- [x] M5.10 History calendar: real monthly calendar (swipe between months, today highlighted, tray start/switch markers); tap a day for its sessions and totals; replaces the 4-week grid
- [x] M5.11 Fix forgotten taps: edit or add a session (start/end/reason) from the day view; Undo toast after Take out / Put back in
- [x] M5.12 Screenshot review against the design, TestFlight build

### Decisions taken (change any of these)
- Ring = worn today ÷ daily goal while the aligners are in; while out it stays out-time used ÷ out-time budget.
- Deleting a finished tray only removes it from history. Deleting the current tray makes the previous tray current again.
- Days on a tray are counted by calendar day; overage = days on tray − planned days.
- Tray history is only what you log in the app. Trays before the one you start on are shown as done in the progress dots but have no history rows.

## Milestone 6 — Ideas for later (not scheduled)
- Streak: days in a row the goal was met, shown on Today and History
- CSV / PDF export of wear time per tray for the orthodontist
- iCloud sync (new phone, backup)
- Languages (French, Arabic with right-to-left)
- Notes per tray (sore teeth, attachments, checkup date) and a next-appointment reminder
- Evening summary notification ("You wore them 22h 10m today")
- StandBy / Lock Screen polish, Apple Watch, retainer mode
- Real app icon artwork
