import Foundation
import Testing
@testable import Inly

struct WatchComplicationTests {
    private var cal: Calendar { var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(identifier: "UTC")!; return c }

    private func payload(isOut: Bool, worn: TimeInterval, asOf: Date) -> WatchPayload {
        WatchPayload(isOut: isOut, outStart: asOf, budgetEnd: asOf.addingTimeInterval(3600), wornSeconds: worn,
                     wornFraction: 0, leftSeconds: 3600, goalHours: 22, trayLine: nil, asOf: asOf, plus: true)
    }

    @Test func wornTimeGrowsWhileIn() {
        let t0 = cal.date(from: DateComponents(year: 2026, month: 3, day: 10, hour: 10))!
        let p = payload(isOut: false, worn: 9 * 3600, asOf: t0)
        #expect(p.wornSeconds(at: t0.addingTimeInterval(1800), calendar: cal) == 9 * 3600 + 1800)
    }

    @Test func wornTimeRestartsAtMidnight() {
        let t0 = cal.date(from: DateComponents(year: 2026, month: 3, day: 10, hour: 23))!
        let p = payload(isOut: false, worn: 20 * 3600, asOf: t0)
        let next = cal.date(from: DateComponents(year: 2026, month: 3, day: 11, hour: 0, minute: 30))!
        #expect(p.wornSeconds(at: next, calendar: cal) == 1800)
    }

    @Test func wornTimeFrozenWhileOut() {
        let t0 = Date(timeIntervalSince1970: 1_700_000_000)
        let p = payload(isOut: true, worn: 5 * 3600, asOf: t0)
        #expect(p.wornSeconds(at: t0.addingTimeInterval(900)) == 5 * 3600)
    }

    @Test func olderPayloadDecodesAsPlus() throws {
        let old = #"{"isOut":false,"outStart":0,"budgetEnd":0,"wornSeconds":0,"wornFraction":0,"leftSeconds":0,"goalHours":22}"#
        let p = try JSONDecoder().decode(WatchPayload.self, from: Data(old.utf8))
        #expect(p.isPlus)
        #expect(p.asOf == nil)
    }
}
