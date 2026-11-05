import Charts
import SwiftData
import SwiftUI

struct HistoryView: View {
    @Query private var sessions: [WearSession]
    @Query private var trays: [Tray]
    @State private var settings = WearSettings.load()

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
    }

    @ViewBuilder
    private func content(now: Date) -> some View {
        let month = WearCalculator.dailyWear(endingOn: now, days: 28, sessions: spans, calendar: .current)
            .filter { $0.day >= trackingStart }
        let week = Array(month.suffix(7))
        let finished = month.filter { $0.elapsedSeconds >= 86_400 - 1 }
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
                heatmap(month, goal: goal)
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

    private func heatmap(_ days: [DayWear], goal: Double) -> some View {
        let cal = Calendar.current
        let byDay = Dictionary(uniqueKeysWithValues: days.map { ($0.day, $0) })
        let today = cal.startOfDay(for: .now)
        // 4 weeks ending this week, weeks start on the calendar's first weekday.
        let weekStart = cal.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        let first = cal.date(byAdding: .day, value: -21, to: weekStart) ?? weekStart
        let cells: [Date] = (0..<28).compactMap { cal.date(byAdding: .day, value: $0, to: first) }
        let symbols = cal.veryShortWeekdaySymbols
        let order = (0..<7).map { symbols[(cal.firstWeekday - 1 + $0) % 7] }

        return Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("Last 4 weeks").font(Theme.font(17, .heavy))
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
                    ForEach(Array(order.enumerated()), id: \.offset) { _, s in
                        Text(s).font(Theme.font(11, .heavy)).foregroundStyle(Theme.muted)
                    }
                    ForEach(cells, id: \.self) { day in
                        cell(day: day, wear: byDay[day], goal: goal, isFuture: day > today)
                    }
                }
            }
        }
    }

    private func cell(day: Date, wear: DayWear?, goal: Double, isFuture: Bool) -> some View {
        let number = Calendar.current.component(.day, from: day)
        let color: Color = {
            guard let wear, !isFuture else { return Theme.raised.opacity(0.5) }
            if Calendar.current.isDateInToday(day) { return Theme.inColor.opacity(0.85) }
            if wear.wornHours >= goal { return Theme.trayColor }
            if wear.wornHours >= goal - 2 { return Theme.outColor }
            return Theme.overColor
        }()
        let filled = wear != nil && !isFuture
        return Text("\(number)")
            .font(Theme.font(13, .heavy).monospacedDigit())
            .foregroundStyle(filled ? Theme.night : Theme.muted)
            .frame(maxWidth: .infinity)
            .frame(height: 36)
            .background(color, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .accessibilityLabel(
                wear.map { "\(day.formatted(.dateTime.month().day())): \(String(format: "%.1f", $0.wornHours)) hours worn" }
                ?? "\(day.formatted(.dateTime.month().day())): no data"
            )
    }
}
