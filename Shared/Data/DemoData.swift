import Foundation
import SwiftData
#if canImport(UIKit)
import UIKit
#endif

/// Launch-argument driven demo data, used by the screenshot UI tests only.
enum DemoData {
    static var isEnabled: Bool { ProcessInfo.processInfo.arguments.contains("-demoData") }
    static var isFresh: Bool { ProcessInfo.processInfo.arguments.contains("-freshStart") }
    static var startsOut: Bool { ProcessInfo.processInfo.arguments.contains("-demoOut") }

    @MainActor
    static func seed(_ context: ModelContext, now: Date = .now) {
        let cal = Calendar.current
        let today = cal.startOfDay(for: now)
        for n in 1...6 {
            let start = cal.date(byAdding: .day, value: -8 - 14 * (7 - n), to: today) ?? today
            let end = cal.date(byAdding: .day, value: n == 3 ? 15 : 14, to: start) ?? today
            context.insert(Tray(number: n, startDate: start, endDate: end, plannedDays: 14))
        }
        context.insert(Tray(number: 7, startDate: cal.date(byAdding: .day, value: -8, to: today) ?? today, plannedDays: 14))
        #if canImport(UIKit)
        if let trays = try? context.fetch(FetchDescriptor<Tray>()) {
            for tray in trays where [1, 4, 7].contains(tray.number) {
                tray.photoData = demoPhoto(alignment: Double(tray.number - 1) / 6)
            }
        }
        #endif
        let outMinutes = [95, 120, 150, 200, 100, 80, 140]
        for back in 1...27 {
            guard let day = cal.date(byAdding: .day, value: -back, to: today),
                  let start = cal.date(bySettingHour: 12, minute: 0, second: 0, of: day) else { continue }
            let m = outMinutes[back % outMinutes.count]
            context.insert(WearSession(start: start, end: start.addingTimeInterval(Double(m) * 60), reason: .meal))
        }
        func at(_ h: Int, _ m: Int) -> Date { cal.date(bySettingHour: h, minute: m, second: 0, of: now) ?? now }
        if at(8, 35) < now {
            context.insert(WearSession(start: at(8, 0), end: at(8, 35), reason: .meal))
        }
        if at(13, 5) < now {
            context.insert(WearSession(start: at(12, 30), end: at(13, 5), reason: .meal))
        }
        if startsOut {
            context.insert(WearSession(start: now.addingTimeInterval(-14 * 60 - 12), reason: .meal))
        }
        var settings = WearSettings()
        settings.userName = "Alex"
        settings.totalTrays = 24
        settings.onboardingDone = true
        settings.save()
        try? context.save()
    }

    #if canImport(UIKit)
    /// An illustrated smile for the store screenshots: `alignment` 0 = crooked, 1 = straight.
    static func demoPhoto(alignment: Double) -> Data? {
        let size = CGSize(width: 1200, height: 900)
        let image = UIGraphicsImageRenderer(size: size).image { ctx in
            let g = ctx.cgContext
            UIColor(red: 0.16, green: 0.12, blue: 0.13, alpha: 1).setFill()
            g.fill(CGRect(origin: .zero, size: size))
            // Lips and mouth.
            UIColor(red: 0.72, green: 0.36, blue: 0.42, alpha: 1).setFill()
            UIBezierPath(ovalIn: CGRect(x: 170, y: 230, width: 860, height: 440)).fill()
            UIColor(red: 0.22, green: 0.06, blue: 0.09, alpha: 1).setFill()
            UIBezierPath(ovalIn: CGRect(x: 240, y: 300, width: 720, height: 300)).fill()
            UIColor(red: 0.85, green: 0.47, blue: 0.52, alpha: 1).setFill()
            UIBezierPath(roundedRect: CGRect(x: 270, y: 318, width: 660, height: 46), cornerRadius: 23).fill()
            let mess = 1 - min(1, max(0, alignment))
            let offsets: [CGFloat] = [0.2, -0.6, 0.9, -0.3, 0.5, -1.0, 0.7, -0.4]
            let tilts: [CGFloat] = [-0.10, 0.16, -0.20, 0.08, -0.12, 0.22, -0.15, 0.10]
            let ivory = UIColor(red: 0.96, green: 0.94, blue: 0.89, alpha: 1)
            func row(y: CGFloat, height: CGFloat, widths: [CGFloat], flip: CGFloat) {
                var x = (size.width - widths.reduce(0, +) - CGFloat(widths.count - 1) * 8) / 2
                for (i, w) in widths.enumerated() {
                    g.saveGState()
                    let dy = offsets[i] * 26 * mess * flip
                    g.translateBy(x: x + w / 2, y: y + height / 2 + dy)
                    g.rotate(by: tilts[i] * mess)
                    ivory.setFill()
                    UIBezierPath(roundedRect: CGRect(x: -w / 2, y: -height / 2, width: w, height: height), cornerRadius: 22).fill()
                    g.restoreGState()
                    x += w + 8
                }
            }
            row(y: 350, height: 120, widths: [64, 74, 84, 104, 104, 84, 74, 64], flip: 1)
            row(y: 482, height: 86, widths: [56, 62, 70, 80, 80, 70, 62, 56], flip: -1)
        }
        return image.jpegData(compressionQuality: 0.85)
    }
    #endif
}
