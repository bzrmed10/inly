import Foundation
import UIKit

/// Builds the CSV and PDF files that can be shared with an orthodontist.
enum ReportBuilder {
    struct TrayRow: Equatable {
        var number: Int
        var start: Date
        var end: Date?
        var plannedDays: Int
    }
    struct NoteRow: Equatable {
        var trayNumber: Int
        var date: Date
        var text: String
    }

    struct Input {
        var name: String
        var goalHours: Int
        var from: Date
        var now: Date
        var trackingStart: Date?
        var spans: [SessionSpan]
        var trays: [TrayRow]
        var notes: [NoteRow]
        var appointment: Date?
        var calendar: Calendar = .current
    }

    // MARK: Daily rows

    static func dailyRows(_ input: Input) -> [DayWear] {
        let cal = input.calendar
        let today = cal.startOfDay(for: input.now)
        var start = cal.startOfDay(for: input.from)
        if let t = input.trackingStart { start = max(start, cal.startOfDay(for: t)) }
        var rows: [DayWear] = []
        var cursor = start
        while cursor <= today, rows.count < 400 {
            rows.append(WearCalculator.dayWear(on: cursor, sessions: input.spans, now: input.now, calendar: cal, trackingStart: input.trackingStart))
            guard let next = cal.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }
        return rows.filter { $0.elapsedSeconds > 0 }
    }

    // MARK: CSV

    private static func formatter(_ format: String, _ cal: Calendar, locale: Locale = Locale(identifier: "en_US_POSIX")) -> DateFormatter {
        let f = DateFormatter()
        f.locale = locale
        f.calendar = cal
        f.timeZone = cal.timeZone
        f.dateFormat = format
        return f
    }

    /// One line per day: hours worn, hours out, and whether the goal was met.
    static func dailyCSV(_ input: Input) -> String {
        let f = formatter("yyyy-MM-dd", input.calendar)
        let today = input.calendar.startOfDay(for: input.now)
        var lines = ["date,hours_worn,hours_out,goal_hours,goal_met,day_complete"]
        for d in dailyRows(input) {
            let complete = d.day < today
            let out = max(0, d.elapsedSeconds - d.wornSeconds)
            let met = d.wornSeconds / max(1, d.elapsedSeconds) >= Double(input.goalHours) / 24 - 1e-9
            lines.append([
                f.string(from: d.day),
                String(format: "%.2f", d.wornSeconds / 3600),
                String(format: "%.2f", out / 3600),
                "\(input.goalHours)",
                met ? "yes" : "no",
                complete ? "yes" : "no",
            ].joined(separator: ","))
        }
        return lines.joined(separator: "\n") + "\n"
    }

    // MARK: PDF

    static func pdf(_ input: Input) -> Data {
        let cal = input.calendar
        let page = CGRect(x: 0, y: 0, width: 595, height: 842)
        let margin: CGFloat = 40
        let renderer = UIGraphicsPDFRenderer(bounds: page)
        let days = dailyRows(input)
        let full = days.filter { $0.elapsedSeconds >= 86_400 - 1 }
        let avg = full.isEmpty ? 0 : full.map(\.wornHours).reduce(0, +) / Double(full.count)
        let met = full.filter { $0.wornHours >= Double(input.goalHours) }.count
        let dateFmt = formatter("d MMM yyyy", cal, locale: L10n.locale)
        let shortFmt = formatter("EEE d MMM", cal, locale: L10n.locale)

        let title = UIFont.systemFont(ofSize: 24, weight: .heavy)
        let h2 = UIFont.systemFont(ofSize: 14, weight: .heavy)
        let body = UIFont.systemFont(ofSize: 11, weight: .regular)
        let bold = UIFont.systemFont(ofSize: 11, weight: .semibold)
        let muted = UIColor.darkGray

        return renderer.pdfData { ctx in
            var y: CGFloat = margin

            func newPage() { ctx.beginPage(); y = margin }
            func ensure(_ h: CGFloat) { if y + h > page.height - margin { newPage() } }
            func text(_ s: String, _ font: UIFont, x: CGFloat = margin, width: CGFloat? = nil, color: UIColor = .black) {
                let w = width ?? (page.width - margin - x)
                let rect = CGRect(x: x, y: y, width: w, height: 1000)
                let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
                let size = (s as NSString).boundingRect(with: rect.size, options: .usesLineFragmentOrigin, attributes: attrs, context: nil)
                (s as NSString).draw(in: CGRect(x: x, y: y, width: w, height: ceil(size.height)), withAttributes: attrs)
                y += ceil(size.height) + 4
            }
            func row(_ cells: [String], widths: [CGFloat], font: UIFont) {
                ensure(18)
                var x = margin
                for (i, c) in cells.enumerated() {
                    (c as NSString).draw(in: CGRect(x: x, y: y, width: widths[i] - 4, height: 16),
                                         withAttributes: [.font: font, .foregroundColor: UIColor.black])
                    x += widths[i]
                }
                y += 16
            }

            newPage()
            text(L10n.t("Aligner wear report"), title)
            let who = input.name.trimmingCharacters(in: .whitespaces)
            text("\(who.isEmpty ? L10n.t("Patient") : who) · " + L10n.t("%@ to %@", dateFmt.string(from: days.first?.day ?? input.from), dateFmt.string(from: input.now)), body, color: muted)
            text(L10n.t("Created with Inly on %@", dateFmt.string(from: input.now)), body, color: muted)
            y += 8

            text(L10n.t("Summary"), h2)
            text(L10n.t("Goal: %d hours a day", input.goalHours), body)
            if full.isEmpty {
                text(L10n.t("Not enough complete days yet."), body)
            } else {
                text(L10n.t("Average wear: %@ hours a day over %d complete days", String(format: "%.1f", avg), full.count), body)
                text(L10n.t("Goal reached on %d of %d days (%d%%)", met, full.count, Int((Double(met) / Double(full.count) * 100).rounded())), body)
            }
            let streak = Insights.streak(days: days, goalHours: input.goalHours, today: input.now, calendar: cal)
            text(L10n.t("Current streak: %@ · best: %@", L10n.days(streak.current), L10n.days(streak.best)), body)
            if let appt = input.appointment, appt > input.now {
                text(L10n.t("Next appointment: %@", dateFmt.string(from: appt)), body)
            }
            y += 8

            if !input.trays.isEmpty {
                text(L10n.t("Trays"), h2)
                let w: [CGFloat] = [50, 110, 110, 110, 100]
                row([L10n.t("Tray"), L10n.t("Started"), L10n.t("Switched"), L10n.t("Days (plan)"), L10n.t("Avg wear")], widths: w, font: bold)
                for t in input.trays.sorted(by: { $0.number < $1.number }) {
                    let spent = TrayLogic.daysSpent(start: t.start, end: t.end, now: input.now, calendar: cal)
                    let from = max(t.start, input.trackingStart ?? t.start)
                    let a = WearCalculator.averageWornHours(from: from, to: t.end ?? input.now, sessions: input.spans, now: input.now, calendar: cal)
                    row([
                        "\(t.number)", dateFmt.string(from: t.start), t.end.map { dateFmt.string(from: $0) } ?? L10n.t("current"),
                        "\(spent) (\(t.plannedDays))", a > 0 ? String(format: "%.1f h", a) : "-",
                    ], widths: w, font: body)
                }
                y += 10
            }

            if !input.notes.isEmpty {
                ensure(40)
                text(L10n.t("Notes"), h2)
                for n in input.notes.sorted(by: { $0.date < $1.date }) {
                    ensure(18)
                    text(L10n.t("Tray %d", n.trayNumber) + " · \(dateFmt.string(from: n.date)): \(n.text)", body)
                }
                y += 10
            }

            ensure(60)
            text(L10n.t("Daily wear"), h2)
            let w: [CGFloat] = [130, 100, 100, 100]
            row([L10n.t("Day"), L10n.t("Worn"), L10n.t("Out"), L10n.t("Goal")], widths: w, font: bold)
            for d in days.reversed() {
                let out = max(0, d.elapsedSeconds - d.wornSeconds)
                let ok = d.wornSeconds / max(1, d.elapsedSeconds) >= Double(input.goalHours) / 24 - 1e-9
                let partial = d.elapsedSeconds < 86_400 - 1
                row([
                    shortFmt.string(from: d.day), TimeFormat.hoursMinutes(d.wornSeconds), TimeFormat.hoursMinutes(out),
                    partial ? L10n.t("in progress") : (ok ? L10n.t("met") : L10n.t("missed")),
                ], widths: w, font: body)
            }
            y += 12
            text(L10n.t("Wear times are recorded by the patient in the Inly app and are not a medical record."), UIFont.systemFont(ofSize: 9), color: muted)
        }
    }
}
