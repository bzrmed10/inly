# Inly — Roadmap

One task = one commit. Mark `[x]` when committed and CI is green. Progress is summarized in `REPORT.md`.

## Milestone 0 — Foundation
- [x] M0.1 README
- [x] M0.2 SPEC.md, ROADMAP.md, REPORT.md
- [x] M0.3 Xcode project via XcodeGen (`project.yml`): app target `Inly`, extension `InlyWidgets`, iOS 26, App Group, Live Activities + push entitlements, minimal SwiftUI app
- [x] M0.4 CI: build + test on macOS runner on every push
- [ ] M0.5 TestFlight workflow (manual trigger and on tag): archive, sign with ASC API key, upload
- [ ] M0.6 Setup guide for secrets and first TestFlight install (`docs/SETUP.md`)

## Milestone 1 — Core tracking + Dynamic Island (first TestFlight)
- [ ] M1.1 Design system in code: color tokens, rounded type styles, `GlowRing` view with animation
- [ ] M1.2 Data layer: SwiftData models (`WearSession`, `Tray`, `Settings`) in the App Group store
- [ ] M1.3 Wear math (`WearCalculator`) + unit tests (midnight split, budget, averages)
- [ ] M1.4 Today screen: ring, timer, reason chips, stat cards, Take out / Put back in, haptics
- [ ] M1.5 Liquid Glass tab bar and navigation shell (Today, Trays, History, Settings)
- [ ] M1.6 Live Activity: attributes, start/end on state change, compact / minimal / expanded / Lock Screen views
- [ ] M1.7 `PutBackInIntent` (App Intent) wired into the Live Activity button
- [ ] M1.8 Screenshot job in CI (simulator screenshots of key screens attached to the run)
- [ ] M1.9 TestFlight build 1

## Milestone 2 — Trays
- [ ] M2.1 Tray model logic: current tray, planned days, switch date
- [ ] M2.2 Trays screen: segments, current tray card, history list
- [ ] M2.3 Start tray sheet with Undo toast and early/late warnings
- [ ] M2.4 Tray switch notification

## Milestone 3 — Widgets and controls
- [ ] M3.1 Home Screen widgets (small, medium interactive)
- [ ] M3.2 Lock Screen accessory widgets
- [ ] M3.3 Control Center toggle + Action Button intent
- [ ] M3.4 Out-time reminder notifications (time-sensitive)

## Milestone 4 — History and polish
- [ ] M4.1 History screen: 7-day bars, 4-week heatmap, stats
- [ ] M4.2 Settings screen
- [ ] M4.3 Accessibility pass (VoiceOver, Dynamic Type, contrast)
- [ ] M4.4 App icon, launch screen, App Store metadata draft
