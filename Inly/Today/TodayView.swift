import SwiftData
import SwiftUI

struct TodayView: View {
    @Query(sort: \WearSession.start) private var sessions: [WearSession]
    @Query(filter: #Predicate<Tray> { $0.endDate == nil }, sort: \Tray.startDate, order: .reverse)
    private var currentTrays: [Tray]

    @State private var settings = WearSettings.load()
    @State private var showSettings = false
    @State private var toggles = 0

    private var openSession: WearSession? { sessions.last(where: { $0.end == nil }) }

    var body: some View {
        NavigationStack {
            TimelineView(.periodic(from: .now, by: 1)) { timeline in
                content(now: timeline.date)
            }
            .background(Theme.night.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: { Image(systemName: "gearshape.fill") }
                        .accessibilityLabel("Settings")
                }
            }
            .toolbarTitleDisplayMode(.inline)
            .sheet(isPresented: $showSettings, onDismiss: { settings = WearSettings.load() }) {
                SettingsSheet()
            }
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: toggles)
    }

    @ViewBuilder
    private func content(now: Date) -> some View {
        let spans = sessions.map { SessionSpan(start: $0.start, end: $0.end) }
        let snap = WearCalculator.snapshot(
            sessions: spans, now: now, budgetSeconds: settings.budgetSeconds, calendar: .current
        )
        let color = ringColor(snap)

        ScrollView {
            VStack(spacing: 18) {
                header(now: now)
                trayCard
                if snap.isOut { reasonChips }
                hero(snap: snap, color: color, now: now)
                statusPill(snap: snap, color: color)
                stats(snap: snap)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .safeAreaInset(edge: .bottom) {
            actionButton(snap: snap)
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
        }
    }

    private func ringColor(_ snap: WearSnapshot) -> Color {
        if snap.isOut { return snap.isOverBudget ? Theme.overColor : Theme.outColor }
        return Theme.inColor
    }

    private func header(now: Date) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(now.formatted(.dateTime.weekday(.wide)))
                .font(Theme.font(34, .heavy))
            Text(now.formatted(.dateTime.month(.wide).day()))
                .font(Theme.font(17, .medium))
                .foregroundStyle(Theme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var trayCard: some View {
        if let tray = currentTrays.first {
            let day = max(1, (Calendar.current.dateComponents([.day], from: tray.startDate, to: .now).day ?? 0) + 1)
            Card {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Tray \(tray.number) of \(settings.totalTrays)")
                            .font(Theme.font(17, .heavy))
                        Text("Day \(day) of \(tray.plannedDays)")
                            .font(Theme.font(14, .medium))
                            .foregroundStyle(Theme.muted)
                    }
                    Spacer()
                    ProgressView(value: min(1, Double(day) / Double(max(1, tray.plannedDays))))
                        .tint(Theme.trayColor)
                        .frame(width: 90)
                }
            }
        }
    }

    private var reasonChips: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(OutReason.allCases, id: \.self) { reason in
                    Button {
                        SessionService.shared.setReason(reason)
                    } label: {
                        Label(reason.title, systemImage: reason.symbol)
                    }
                    .buttonStyle(ChipStyle(selected: openSession?.reason == reason, color: Theme.outColor))
                }
            }
        }
        .scrollIndicators(.hidden)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    private func hero(snap: WearSnapshot, color: Color, now: Date) -> some View {
        let seconds: TimeInterval = {
            if snap.isOut, let s = openSession { return now.timeIntervalSince(s.start) }
            return snap.wornSeconds
        }()
        return ZStack {
            GlowRing(progress: snap.isOut ? snap.budgetUsed : snap.goalProgress, color: color)
            VStack(spacing: 4) {
                Text(snap.isOut ? "OUT FOR" : "WORN TODAY")
                    .font(Theme.font(13, .heavy))
                    .tracking(1.4)
                    .foregroundStyle(color)
                Text(TimeFormat.clock(seconds))
                    .font(Theme.timerFont(40))
                    .contentTransition(.numericText(countsDown: false))
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
            }
        }
        .frame(width: 230, height: 230)
        .padding(.vertical, 12)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(snap.isOut ? "Aligners out" : "Worn today")
        .accessibilityValue(TimeFormat.hoursMinutes(seconds))
    }

    private func statusPill(snap: WearSnapshot, color: Color) -> some View {
        let text: String = {
            if snap.isOverBudget { return "Over today's budget" }
            if snap.isOut { return "\(TimeFormat.hoursMinutes(snap.leftSeconds)) of out-time left" }
            return "Aligners in · \(TimeFormat.hoursMinutes(snap.leftSeconds)) out-time left"
        }()
        return Text(text)
            .font(Theme.font(15, .semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .background(color.opacity(0.14), in: Capsule())
            .animation(.smooth, value: text)
    }

    private func stats(snap: WearSnapshot) -> some View {
        HStack(spacing: 12) {
            statCard("Worn", TimeFormat.hoursMinutes(snap.wornSeconds), Theme.inColor)
            statCard("Out", TimeFormat.hoursMinutes(snap.outSeconds), Theme.outColor)
            statCard("Goal", "\(settings.goalHours)h", Theme.trayColor)
        }
    }

    private func statCard(_ title: String, _ value: String, _ color: Color) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 6) {
                Text(title.uppercased())
                    .font(Theme.font(11, .heavy))
                    .tracking(1)
                    .foregroundStyle(color)
                Text(value)
                    .font(Theme.font(20, .heavy).monospacedDigit())
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
            }
        }
    }

    private func actionButton(snap: WearSnapshot) -> some View {
        Button {
            withAnimation(.smooth) {
                if snap.isOut {
                    SessionService.shared.putBackIn()
                } else {
                    TrayNotifications.requestPermission()
                    SessionService.shared.takeOut()
                }
            }
            toggles += 1
        } label: {
            Text(snap.isOut ? "Put back in" : "Take out")
        }
        .buttonStyle(PillButtonStyle(color: snap.isOut ? Theme.outColor : Theme.inColor))
        .accessibilityHint(snap.isOut ? "Records that your aligners are back in" : "Starts timing how long your aligners are out")
    }
}
