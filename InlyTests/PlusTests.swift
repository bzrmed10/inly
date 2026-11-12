import Foundation
import Testing
@testable import Inly

struct PlusTests {
    @Test func freeHistoryCoversFourteenDays() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let now = cal.date(from: DateComponents(year: 2026, month: 11, day: 20, hour: 15))!
        let first = FreeLimits.firstFreeDay(now: now, calendar: cal)
        #expect(first == cal.date(from: DateComponents(year: 2026, month: 11, day: 7)))
        let days = cal.dateComponents([.day], from: first, to: cal.startOfDay(for: now)).day
        #expect(days == FreeLimits.historyDays - 1)
    }

    @Test func freePhotoLimitAllowsCompare() {
        #expect(FreeLimits.photos >= 2)
    }

    @Test func paywallReasonsAreUnique() {
        #expect(Set(PaywallReason.allCases.map(\.id)).count == PaywallReason.allCases.count)
    }
}
