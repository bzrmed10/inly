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
