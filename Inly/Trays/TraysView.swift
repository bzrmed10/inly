import SwiftData
import SwiftUI

struct TraysView: View {
    @Query(sort: \Tray.number, order: .reverse) private var trays: [Tray]
    @Query private var sessions: [WearSession]

    @State private var settings = WearSettings.load()
    @State private var showStart = false
    @State private var undo: SessionService.TrayUndo?
    @State private var toastTask: Task<Void, Never>?

    private var current: Tray? { trays.first(where: { $0.endDate == nil }) }
    private var finished: [Tray] { trays.filter { $0.endDate != nil } }
    private var spans: [SessionSpan] { sessions.map { SessionSpan(start: $0.start, end: $0.end) } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    segments
                    if let current { currentCard(current) }
                    if !finished.isEmpty { history }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .background(Theme.night.ignoresSafeArea())
            .navigationTitle("Trays")
            .overlay(alignment: .bottom) { toast }
            .sheet(isPresented: $showStart) {
                StartTraySheet(
                    current: current,
                    nextNumber: (trays.first?.number ?? 0) + 1,
                    defaultDays: settings.defaultTrayDays
                ) { date, days in
                    TrayNotifications.requestPermission()
                    let u = SessionService.shared.startNextTray(on: date, plannedDays: days)
                    withAnimation(.smooth) { undo = u }
                    toastTask?.cancel()
                    toastTask = Task {
                        try? await Task.sleep(for: .seconds(7))
                        if !Task.isCancelled { withAnimation(.smooth) { undo = nil } }
                    }
                }
            }
        }
        .onAppear { settings = WearSettings.load() }
        .sensoryFeedback(.success, trigger: undo?.newTrayID)
    }

    private var segments: some View {
        let total = max(settings.totalTrays, trays.first?.number ?? 0)
        let currentNumber = current?.number ?? 0
        return VStack(alignment: .leading, spacing: 10) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 12), spacing: 4) {
                ForEach(1...max(1, total), id: \.self) { n in
                    Capsule()
                        .fill(n < currentNumber ? Theme.trayColor : n == currentNumber ? Theme.trayColor.opacity(0.55) : Theme.raised)
                        .frame(height: 8)
                }
            }
            Text("\(max(0, currentNumber - 1)) of \(total) trays finished")
                .font(Theme.font(13, .medium))
                .foregroundStyle(Theme.muted)
        }
    }

    private func currentCard(_ tray: Tray) -> some View {
        let day = TrayLogic.dayNumber(start: tray.startDate, now: .now, calendar: .current)
        let due = TrayLogic.switchDate(start: tray.startDate, plannedDays: tray.plannedDays, calendar: .current)
        let avg = WearCalculator.averageWornHours(from: tray.startDate, to: .now, sessions: spans, now: .now, calendar: .current)
        return Card {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("TRAY \(tray.number)")
                        .font(Theme.font(12, .heavy)).tracking(1.2)
                        .foregroundStyle(Theme.trayColor)
                    Spacer()
                    Text("Day \(day) of \(tray.plannedDays)")
                        .font(Theme.font(15, .heavy))
                }
                ProgressView(value: min(1, Double(day) / Double(max(1, tray.plannedDays))))
                    .tint(Theme.trayColor)
                HStack {
                    info("Started", tray.startDate.formatted(.dateTime.month(.abbreviated).day()))
                    info("Switch", due.formatted(.dateTime.month(.abbreviated).day()))
                    info("Avg wear", String(format: "%.1fh", avg))
                }
                Button("Start tray \(tray.number + 1)") { showStart = true }
                    .buttonStyle(PillButtonStyle(color: Theme.trayColor))
            }
        }
    }

    private func info(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title.uppercased()).font(Theme.font(11, .heavy)).tracking(1).foregroundStyle(Theme.muted)
            Text(value).font(Theme.font(17, .heavy).monospacedDigit())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var history: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("History").font(Theme.font(20, .heavy))
            ForEach(finished) { tray in
                let days = TrayLogic.daysSpent(start: tray.startDate, end: tray.endDate, now: .now, calendar: .current)
                let avg = WearCalculator.averageWornHours(from: tray.startDate, to: tray.endDate ?? .now, sessions: spans, now: .now, calendar: .current)
                Card {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Tray \(tray.number)").font(Theme.font(17, .heavy))
                            Text("\(tray.startDate.formatted(.dateTime.month(.abbreviated).day())) – \((tray.endDate ?? .now).formatted(.dateTime.month(.abbreviated).day()))")
                                .font(Theme.font(13, .medium)).foregroundStyle(Theme.muted)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 3) {
                            Text("\(days) days")
                                .font(Theme.font(17, .heavy))
                                .foregroundStyle(days == tray.plannedDays ? Theme.text : Theme.outColor)
                            Text("plan \(tray.plannedDays) · \(String(format: "%.1f", avg))h avg")
                                .font(Theme.font(13, .medium)).foregroundStyle(Theme.muted)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var toast: some View {
        if let undo {
            HStack {
                Label("New tray started", systemImage: "checkmark.circle.fill")
                    .font(Theme.font(15, .semibold))
                Spacer()
                Button("Undo") {
                    SessionService.shared.undoStartTray(undo)
                    withAnimation(.smooth) { self.undo = nil }
                }
                .font(Theme.font(15, .heavy))
                .foregroundStyle(Theme.inColor)
            }
            .padding(.horizontal, 18).padding(.vertical, 14)
            .glassEffect(.regular, in: Capsule())
            .padding(.horizontal, 20).padding(.bottom, 12)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}
