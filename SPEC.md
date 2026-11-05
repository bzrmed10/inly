# Inly — Product Spec (v1)

Design reference (interactive canvas): https://claude.ai/artifact/FJ3kaHBD2sYHDkuQ9ZJDgo

## Goal
Track how long clear aligners are **in** and **out**, per day and per tray, with the best Dynamic Island / Live Activity / widget experience in the category. One job, done beautifully.

## Platform and stack
- iOS 26+, iPhone only (v1). Swift 6, SwiftUI, SwiftData, ActivityKit, WidgetKit, App Intents.
- No backend, no accounts. All data on device (SwiftData store in the shared App Group container so the app, widgets and Live Activity read the same data).
- Bundle IDs: app `com.bzrmed.inly`, widgets `com.bzrmed.inly.widgets`, App Group `group.com.bzrmed.inly`.

## Core concepts
- **Session**: a period where aligners are OUT. Fields: `start`, `end?`, `reason` (meal, brushing, drink, other).
- **Wear time** for a day = 24h minus out-time inside that day (day boundaries use the user's calendar; sessions crossing midnight are split).
- **Daily goal**: default 22h wear, i.e. 2h out-time budget. Adjustable (16–23h).
- **Tray**: number, start date, planned days (default 14), index within total trays (default 24). Switching trays closes the current tray and records days spent.
- Aligners are IN whenever there is no open session. App never loses state if killed: state is derived from stored sessions, not an in-memory stopwatch.

## Screens
1. **Today**: hero ring + glow. In: wear time toward goal. Out: live count-up timer, ring = out-time budget used. Reason chips while out. Stat cards (out today, left today, this tray). One big button: Take out / Put back in. Tray summary card links to Trays.
2. **Trays**: progress segments for all trays; current tray card (day X of plan, started, switch date, avg wear); "Start tray N" sheet (today/yesterday, planned days stepper, reminder date, early-switch warning); toast with Undo; history list (dates, days on tray vs plan, avg wear).
3. **History**: 7-day bars vs goal line, 4-week calendar heatmap, daily average, goal-met count.
4. **Settings**: goal, reminders, total trays, default days per tray.
5. Navigation: iOS 26 Liquid Glass floating tab bar (Today, Trays, History) + glass Settings button.

## Dynamic Island / Live Activity (the hero feature)
- Starts when aligners come OUT, ends when they go IN (always under the 8h system limit).
- Compact: leading = ring (out-time budget used), trailing = count-up timer. Colors: amber normally, yellow when under 10 min left, coral when over budget.
- Minimal: ring only.
- Expanded: ring + "Aligners out" + reason + since time; large timer; budget bar; "back by" time; **Put back in** button (App Intent, works without opening the app).
- Lock Screen / banner: same content as expanded.
- Timer uses system-rendered `Text(timerInterval:)` so it counts without app updates and costs no battery.
- Follow Apple HIG: essential info only, no ads, tap opens the app at Today.

## Widgets and controls
- Home Screen small: wear ring (in) or out timer (out). Medium: ring + tray info + interactive Take out / Put back in button.
- Lock Screen accessory circular (wear ring) and rectangular.
- Control Center toggle (In/Out) and Action Button support via App Intent.
- Widgets update through shared SwiftData + `WidgetCenter.reloadAllTimelines()` on every state change.

## Notifications
- Out-time reminder: "Put them back in" when the budget is nearly used or a user-set time out has passed (time-sensitive).
- Tray switch reminder on the switch date.

## Design system
Dark, calm, friendly (inspired by How We Feel). Tokens: Night `#0B0B0F`, Surface `#17171C`, Raised `#23232B`, Text `#FFFFFF`, Muted `#9A9AA6`, In `#5B9DFF`, Out `#FFB547`, Tray `#3DDC97`, Over `#FF6B5E`. SF Pro Rounded, heavy weights, tabular numbers. Pill buttons, radius 22–28 cards. Soft state-colored glow behind the ring. Liquid Glass only on the navigation layer (`.glassEffect()`, system TabView).

## Out of scope for v1
Apple Watch, photos/Teethie, doctor export, iCloud sync, Android, retainer mode. Planned later.

## Quality bar
- Unit tests for wear-time math (midnight splits, budget, tray day counts).
- Accessibility: VoiceOver labels on rings and buttons, Dynamic Type for body text, color never the only signal.
- Data safety: no destructive actions without Undo.
