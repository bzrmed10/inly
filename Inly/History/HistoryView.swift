import Charts
import SwiftData
import SwiftUI

struct HistoryView: View {
    @Query private var sessions: [WearSession]
    @Query private var trays: [Tray]
    @State private var settings = WearSettings.load()
    @State private var month = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: .now)) ?? .now
    @State private var selectedDay: DayID?

    private var spans: [SessionSpan] { sessions.map { SessionSpan(start: $0.start, end: $0.end) } }

    /// First day we have any data for; earlier days are not counted as "worn".
    private var trackingStart: Date {
        let cal = Calendar.current
        let dates = sessions.map(\.start) + trays.map(\.startDate)
        return cal.startOfDay(for: dates.min() ?? .now)
    }

    var body: some View {
        NavigationStack {
            TimelineView(.everyMinute) { timeline in
                content(now: timeline.date)
            }
            .background(Theme.night.ignoresSafeArea())
            .navigationTitle("History")
        }
        .onAppear { settings = WearSettings.load() }
        .sheet(item: $selectedDay) { id in
            DayDetailSheet(day: id.date)
        }
    }

    @ViewBuilder
    private func content(now: Date) -> some View {
        let last28 = WearCalculator.dailyWear(endingOn: now, days: 28, sessions: spans, calendar: .current)
            .filter { $0.day >= trackingStart }
        let week = Array(last28.suffix(7))
        let finished = last28.filter { $0.elapsedSeconds >= 86_400 - 1 }
        let goal = Double(settings.goalHours)
        let metCount = finished.filter { $0.wornHours >= goal }.count
        let avg = finished.isEmpty ? 0 : finished.map(\.wornHours).reduce(0, +) / Double(finished.count)

        ScrollView {
            VStack(spacing: 18) {
                HStack(spacing: 12) {
                    stat("Daily average", String(format: "%.1fh", avg), Theme.inColor)
                    stat("Goal met", "\(metCount) of \(finished.count)", Theme.trayColor)
                }
                weekChart(week, goal: goal)
                calendarCard(now: now, goal: goal)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
    }

    private func stat(_ title: String, _ value: String, _ color: Color) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 6) {
                Text(title.uppercased()).font(Theme.font(11, .heavy)).tracking(1).foregroundStyle(color)
                Text(value).font(Theme.font(24, .heavy).monospacedDigit())
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func weekChart(_ week: [DayWear], goal: Double) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("Last 7 days").font(Theme.font(17, .heavy))
                if week.isEmpty {
                    Text("Your days will show up here.").foregroundStyle(Theme.muted)
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
                                Text("Goal \(Int(goal))h").font(Theme.font(11, .heavy)).foregroundStyle(Theme.outColor)
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
                        AxisMarks(values: .stride(by: .day)) { _ in
                            AxisValueLabel(format: .dateTime.weekday(.narrow)).foregroundStyle(Theme.muted)
                        }
                    }
                    .frame(height: 180)
                    .accessibilityLabel("Hours worn per day over the last 7 days, goal \(Int(goal)) hours")
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
        let cal = Calendar.current
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
                    navButton("chevron.left", enabled: canGoBack) { shift(-1) }
                    Spacer()
                    Text(month.formatted(.dateTime.month(.wide).year()))
                        .font(Theme.font(17, .heavy))
                        .contentTransition(.numericText())
                    Spacer()
                    navButton("chevron.right", enabled: canGoForward) { shift(1) }
                }
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
                    ForEach(Array(order.enumerated()), id: \.offset) { _, s in
                        Text(s).font(Theme.font(11, .heavy)).foregroundStyle(Theme.muted)
                    }
                    ForEach(0..<blanks, id: \.self) { _ in Color.clear.frame(height: 40) }
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
                    key(Theme.trayColor, "Goal met")
                    key(Theme.outColor, "Close")
                    key(Theme.overColor, "Missed")
                }
                HStack(spacing: 14) {
                    dot(Theme.trayColor, "Tray started")
                    dot(.white, "Switch day")
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
        .accessibilityLabel(symbol == "chevron.left" ? "Previous month" : "Next month")
    }

    private func dayCell(number: Int, day: Date, now: Date, goal: Double, tracked: Bool, isStart: Bool, isDue: Bool) -> some View {
        let cal = Calendar.current
        let isFuture = day > now
        let isToday = cal.isDateInToday(day)
        let wear = WearCalculator.dayWear(on: day, sessions: spans, now: now, calendar: cal)
        let filled = tracked && !isFuture
        let color: Color = {
            guard filled else { return Theme.raised.opacity(0.5) }
            if isToday { return Theme.inColor.opacity(0.85) }
            if wear.wornHours >= goal { return Theme.trayColor }
            if wear.wornHours >= goal - 2 { return Theme.outColor }
            return Theme.overColor
        }()
        let label = day.formatted(.dateTime.month().day())
        return Button {
            selectedDay = DayID(date: day)
        } label: {
            VStack(spacing: 2) {
                Text("\(number)").font(Theme.font(14, .heavy).monospacedDigit())
                Circle()
                    .fill(isStart ? (filled ? Theme.night : Theme.trayColor) : (isDue ? (filled ? Theme.night : Color.white) : Color.clear))
                    .frame(width: 5, height: 5)
            }
            .foregroundStyle(filled ? Theme.night : Theme.muted)
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(color, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                if isToday { RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(.white, lineWidth: 2) }
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("day-\(number)")
        .accessibilityLabel(
            filled ? "\(label): \(String(format: "%.1f", wear.wornHours)) hours worn" + (isStart ? ", tray started" : "") + (isDue ? ", switch day" : "")
                   : "\(label): no data"
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
