import Charts
import SwiftData
import SwiftUI

struct HistoryView: View {
    @Query private var sessions: [WearSession]
    @Query private var trays: [Tray]
    @State private var settings = WearSettings.load()
    @State private var month = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: .now)) ?? .now
    @State private var selectedDay: DayID?
    @State private var showExport = false

    private var spans: [SessionSpan] { sessions.map { SessionSpan(start: $0.start, end: $0.end) } }

    /// First day we have any data for; earlier days are not counted as "worn".
    private var trackingMoment: Date? {
        settings.resolvedTrackingStart(firstSession: sessions.map(\.start).min())
    }

    private var trackingStart: Date {
        let cal = Calendar.current
        let dates = trackingMoment.map { [$0] } ?? (sessions.map(\.start) + trays.map(\.startDate))
        return cal.startOfDay(for: dates.min() ?? .now)
    }

    var body: some View {
        NavigationStack {
            TimelineView(.everyMinute) { timeline in
                content(now: timeline.date)
            }
            .background(Theme.night.ignoresSafeArea())
            .navigationTitle(L10n.t("History"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { Store.shared.require(.export) { showExport = true } } label: { Image(systemName: "square.and.arrow.up").foregroundStyle(Theme.text) }
                        .tint(Theme.text)
                        .accessibilityLabel(L10n.t("Share with your orthodontist"))
                }
            }
        }
        .sheet(isPresented: $showExport) { ExportSheet() }
        .onAppear { settings = WearSettings.load() }
        .sheet(item: $selectedDay) { id in
            DayDetailSheet(day: id.date)
        }
    }

    @ViewBuilder
    private func content(now: Date) -> some View {
        let last28 = WearCalculator.dailyWear(endingOn: now, days: 28, sessions: spans, calendar: .current, trackingStart: trackingMoment)
            .filter { $0.day >= trackingStart }
        let week = Array(last28.suffix(7))
        let finished = last28.filter { $0.elapsedSeconds >= 86_400 - 1 }
        let goal = Double(settings.goalHours)
        let metCount = finished.filter { $0.wornHours >= goal }.count
        let avg = finished.isEmpty ? 0 : finished.map(\.wornHours).reduce(0, +) / Double(finished.count)

        ScrollView {
            VStack(spacing: 18) {
                heroCard(now: now, avg: avg, metCount: metCount, finishedCount: finished.count)
                    .plusLocked(!Store.shared.isPlus, reason: .history)
                weekChart(week, goal: goal)
                calendarCard(now: now, goal: goal)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
    }

    private func heroCard(now: Date, avg: Double, metCount: Int, finishedCount: Int) -> some View {
        let days = WearCalculator.dailyWear(endingOn: now, days: 120, sessions: spans, calendar: .current, trackingStart: trackingMoment)
        let streak = Insights.streak(days: days, goalHours: settings.goalHours, today: now, calendar: .current)
        let score = Insights.weekScore(
            days: days, goalHours: settings.goalHours,
            nightsPerWeek: settings.retainerMode && settings.retainerSchedule == .fewNights ? settings.retainerNights : nil,
            today: now, calendar: .current
        )
        let night = settings.isNightRetainer
        let pct = Int((score.fraction * 100).rounded())
        let streakNow = streak.current
        return Card {
            HStack(spacing: 16) {
                VStack(spacing: 8) {
                    ZStack {
                        Circle().stroke(Theme.raised, lineWidth: 10)
                        Circle()
                            .trim(from: 0, to: max(0.001, score.fraction))
                            .stroke(scoreColor(score.fraction), style: StrokeStyle(lineWidth: 10, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        Text("\(pct)%")
                            .font(Theme.font(22, .heavy).monospacedDigit())
                            .lineLimit(1).minimumScaleFactor(0.6)
                            .padding(.horizontal, 22)
                    }
                    .frame(width: 112, height: 112)
                    Text(L10n.t("Weekly score"))
                        .font(Theme.font(11, .heavy)).foregroundStyle(Theme.muted)
                        .lineLimit(1).minimumScaleFactor(0.7)
                }
                .frame(width: 112)
                Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 14) {
                    GridRow {
                        miniStat(L10n.t("This week"), night ? L10n.t("%d of %d nights", score.met, score.target) : L10n.t("%d of %d days", score.met, score.target), Theme.trayColor)
                        miniStat(L10n.t("Daily average"), String(format: "%.1f", avg) + L10n.t("unit.h"), Theme.inColor)
                    }
                    GridRow {
                        miniStat(L10n.t("Goal met"), L10n.t("%d of %d", metCount, finishedCount), Theme.trayColor)
                        miniStat(L10n.t("Streak"), L10n.days(streak.current), Theme.outText, sub: L10n.t("Best streak") + " " + L10n.days(streak.best))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .accessibilityElement(children: .combine)
        .onAppear { if streakNow >= 7 { ReviewPrompter.shared.note(.streak) } }
    }

    private func miniStat(_ title: String, _ value: String, _ color: Color, sub: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased()).font(Theme.font(10, .heavy)).tracking(0.6).foregroundStyle(color)
                .lineLimit(1).minimumScaleFactor(0.7)
            Text(value).font(Theme.font(16, .heavy).monospacedDigit()).lineLimit(1).minimumScaleFactor(0.65)
            if let sub {
                Text(sub).font(Theme.font(10, .bold)).foregroundStyle(Theme.muted).lineLimit(1).minimumScaleFactor(0.65)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func scoreColor(_ f: Double) -> Color { f >= 0.85 ? Theme.trayColor : (f >= 0.6 ? Theme.inColor : Theme.outColor) }

    private func weekChart(_ week: [DayWear], goal: Double) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text(L10n.t("Last 7 days")).font(Theme.font(17, .heavy))
                if week.isEmpty {
                    Text(L10n.t("Your days will show up here.")).foregroundStyle(Theme.muted)
                } else {
                    Chart {
                        ForEach(week) { d in
                            BarMark(
                                x: .value("Day", d.day, unit: .day),
                                y: .value("Hours worn", d.wornHours)
                            )
                            .foregroundStyle(d.wornHours >= goal ? Theme.trayColor : Theme.inColor)
                            .cornerRadius(6)
                        }
                        RuleMark(y: .value("Goal", goal))
                            .foregroundStyle(Theme.outColor)
                            .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                            .annotation(position: .top, alignment: .trailing) {
                                Text(L10n.t("Goal %d", Int(goal)) + L10n.t("unit.h")).font(Theme.font(11, .heavy)).foregroundStyle(Theme.outText)
                            }
                    }
                    .chartYScale(domain: 0...24)
                    .chartYAxis {
                        AxisMarks(values: [0, 8, 16, 24]) { _ in
                            AxisGridLine().foregroundStyle(Theme.raised)
                            AxisValueLabel().foregroundStyle(Theme.muted)
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day)) { value in
                            AxisValueLabel {
                                if let day = value.as(Date.self) {
                                    Text(L10n.date(day, .dateTime.weekday(.narrow))).foregroundStyle(Theme.muted)
                                }
                            }
                        }
                    }
                    .frame(height: 180)
                    .accessibilityLabel(L10n.t("Hours worn per day over the last 7 days, goal %d hours", Int(goal)))
                }
            }
        }
    }
}

struct DayID: Identifiable, Hashable {
    let date: Date
    var id: Date { date }
}

// MARK: - Calendar

extension HistoryView {
    fileprivate func calendarCard(now: Date, goal: Double) -> some View {
        var cal = Calendar.current
        cal.locale = L10n.locale
        let thisMonth = cal.date(from: cal.dateComponents([.year, .month], from: now)) ?? now
        let firstMonth = cal.date(from: cal.dateComponents([.year, .month], from: trackingStart)) ?? thisMonth
        let canGoBack = month > firstMonth
        let canGoForward = month < thisMonth

        let days = cal.range(of: .day, in: .month, for: month)?.count ?? 30
        let weekdayOfFirst = cal.component(.weekday, from: month)
        let blanks = (weekdayOfFirst - cal.firstWeekday + 7) % 7
        let symbols = cal.veryShortWeekdaySymbols
        let order = (0..<7).map { symbols[(cal.firstWeekday - 1 + $0) % 7] }
        let starts = Set(trays.map { cal.startOfDay(for: $0.startDate) })
        let dueDays = Set(trays.filter { $0.endDate == nil }.map {
            TrayLogic.switchDate(start: $0.startDate, plannedDays: $0.plannedDays, calendar: cal)
        })

        return Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    navButton("chevron.backward", enabled: canGoBack) { shift(-1) }
                    Spacer()
                    Text(L10n.date(month, .dateTime.month(.wide).year()))
                        .font(Theme.font(17, .heavy))
                        .contentTransition(.numericText())
                    Spacer()
                    navButton("chevron.forward", enabled: canGoForward) { shift(1) }
                }
                HStack(spacing: 6) {
                    ForEach(Array(order.enumerated()), id: \.offset) { _, s in
                        Text(s).font(Theme.font(11, .heavy)).foregroundStyle(Theme.muted)
                            .frame(maxWidth: .infinity)
                    }
                }
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
                    // Negative ids so the blanks never collide with the day numbers.
                    ForEach((0..<blanks).map { -($0 + 1) }, id: \.self) { _ in Color.clear.frame(height: 40) }
                    ForEach(1...days, id: \.self) { n in
                        let day = cal.date(byAdding: .day, value: n - 1, to: month) ?? month
                        dayCell(
                            number: n, day: day, now: now, goal: goal,
                            tracked: day >= trackingStart,
                            isStart: starts.contains(day),
                            isDue: dueDays.contains(day)
                        )
                    }
                }
                HStack(spacing: 14) {
                    key(Theme.trayColor, L10n.t("Goal met"))
                    key(Theme.outColor, L10n.t("Close"))
                    key(Theme.overColor, L10n.t("Missed"))
                }
                HStack(spacing: 14) {
                    dot(Theme.trayColor, L10n.t("Tray started"))
                    dot(Theme.text, L10n.t("Switch day"))
                }
            }
        }
        .gesture(
            DragGesture(minimumDistance: 30).onEnded { v in
                if v.translation.width < -50, month < thisMonth { shift(1) }
                if v.translation.width > 50, month > firstMonth { shift(-1) }
            }
        )
    }

    fileprivate func shift(_ by: Int) {
        withAnimation(.smooth) {
            month = Calendar.current.date(byAdding: .month, value: by, to: month) ?? month
        }
    }

    private func navButton(_ symbol: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .heavy))
                .frame(width: 40, height: 40)
                .background(Theme.raised, in: Circle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.3)
        .accessibilityLabel(symbol == "chevron.backward" ? L10n.t("Previous month") : L10n.t("Next month"))
    }

    private func dayCell(number: Int, day: Date, now: Date, goal: Double, tracked: Bool, isStart: Bool, isDue: Bool) -> some View {
        let cal = Calendar.current
        let isFuture = day > now
        let isToday = cal.isDateInToday(day)
        let wear = WearCalculator.dayWear(on: day, sessions: spans, now: now, calendar: cal, trackingStart: trackingMoment)
        let locked = !Store.shared.isPlus && day < FreeLimits.firstFreeDay(now: now, calendar: cal)
        let filled = tracked && !isFuture && wear.elapsedSeconds > 0 && !locked
        let color: Color = {
            guard filled else { return Theme.raised.opacity(0.5) }
            if isToday { return Theme.inColor.opacity(0.85) }
            if wear.wornHours >= goal { return Theme.trayColor }
            if wear.wornHours >= goal - 2 { return Theme.outColor }
            return Theme.overColor
        }()
        let label = L10n.date(day, .dateTime.month().day())
        return Button {
            if locked { Store.shared.paywall = .history } else { selectedDay = DayID(date: day) }
        } label: {
            VStack(spacing: 2) {
                Text("\(number)").font(Theme.font(14, .heavy).monospacedDigit())
                Circle()
                    .fill(isStart ? (filled ? Theme.night : Theme.trayColor) : (isDue ? (filled ? Theme.night : Theme.text) : Color.clear))
                    .frame(width: 5, height: 5)
            }
            .foregroundStyle(filled ? Theme.night : Theme.muted)
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(color, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                if isToday { RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Theme.text, lineWidth: 2) }
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("day-\(number)")
        .accessibilityLabel(
            filled ? L10n.t("%@: %@ hours worn", label, String(format: "%.1f", wear.wornHours)) + (isStart ? ", " + L10n.t("tray started") : "") + (isDue ? ", " + L10n.t("switch day") : "")
                   : L10n.t("%@: no data", label)
        )
    }

    private func key(_ color: Color, _ text: String) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 3).fill(color).frame(width: 12, height: 12)
            Text(text).font(Theme.font(12, .semibold)).foregroundStyle(Theme.muted)
        }
    }

    private func dot(_ color: Color, _ text: String) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(text).font(Theme.font(12, .semibold)).foregroundStyle(Theme.muted)
        }
    }
}
