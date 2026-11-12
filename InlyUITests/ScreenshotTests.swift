import XCTest

final class ScreenshotTests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    private func save(_ name: String) {
        let png = XCUIScreen.main.screenshot().pngRepresentation
        let dir = ProcessInfo.processInfo.environment["SCREENSHOT_DIR"] ?? NSTemporaryDirectory()
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        try? png.write(to: URL(fileURLWithPath: dir).appendingPathComponent("\(name).png"))
    }

    func testTodayIn() {
        let app = XCUIApplication()
        app.launchArguments = ["-demoData"]
        app.launch()
        sleep(2)
        save("01-today-in")
    }

    func testTodayOut() {
        let app = XCUIApplication()
        app.launchArguments = ["-demoData", "-demoOut"]
        app.launch()
        sleep(2)
        save("02-today-out")
    }

    func testTakeOutTapAndSettings() {
        let app = XCUIApplication()
        app.launchArguments = ["-demoData"]
        app.launch()
        app.buttons["Take out"].tap()
        sleep(2)
        save("03-after-take-out")
        app.tabBars.buttons["Settings"].tap()
        sleep(1)
        save("04-settings")
    }
}

extension ScreenshotTests {
    func testTraysScreen() {
        let app = XCUIApplication()
        app.launchArguments = ["-demoData"]
        app.launch()
        app.tabBars.buttons["Trays"].tap()
        sleep(2)
        save("05-trays")
        app.buttons["Start tray 8"].tap()
        sleep(1)
        save("06-start-tray")
    }
}

extension ScreenshotTests {
    func testHistoryScreen() {
        let app = XCUIApplication()
        app.launchArguments = ["-demoData"]
        app.launch()
        app.tabBars.buttons["History"].tap()
        sleep(2)
        save("07-history")
    }
}

extension ScreenshotTests {
    func testOnboarding() {
        let app = XCUIApplication()
        app.launchArguments = ["-freshStart"]
        app.launch()
        sleep(2)
        save("00-onboarding")
    }
}

extension ScreenshotTests {
    func testCalendarAndDay() {
        let app = XCUIApplication()
        app.launchArguments = ["-demoData"]
        app.launch()
        app.tabBars.buttons["History"].tap()
        sleep(1)
        app.swipeUp()
        sleep(1)
        save("08-history-calendar")
        let cell = app.buttons["day-3"]
        if cell.waitForExistence(timeout: 3) {
            cell.tap()
            sleep(1)
            save("09-day-detail")
        }
    }

    func testOnboardingTour() {
        let app = XCUIApplication()
        app.launchArguments = ["-freshStart"]
        app.launch()
        sleep(1)
        save("10-onboarding-welcome")
        for (i, name) in ["11-onboarding-island", "12-onboarding-widgets", "13-onboarding-name", "14-onboarding-tray", "15-onboarding-goal", "16-onboarding-reminders", "17-onboarding-done"].enumerated() {
            let next = app.buttons[i == 0 ? "Get started" : "Next"]
            if next.waitForExistence(timeout: 3) { next.tap() }
            sleep(1)
            save(name)
        }
    }
}

extension ScreenshotTests {
    private func localized(_ code: String, start: String, next: String) {
        let app = XCUIApplication()
        app.launchArguments = ["-demoData", "-appLanguage", code]
        app.launch()
        sleep(2)
        save("20-\(code)-today")

        let out = XCUIApplication()
        out.launchArguments = ["-demoData", "-demoOut", "-appLanguage", code]
        out.launch()
        sleep(2)
        save("28-\(code)-today-out")
        out.tabBars.buttons.element(boundBy: 2).tap()
        sleep(1)
        out.swipeUp()
        sleep(1)
        save("29-\(code)-calendar")

        app.launch()
        sleep(2)
        let tabs = app.tabBars.buttons
        for (i, name) in ["trays", "history", "settings"].enumerated() where tabs.count > i + 1 {
            tabs.element(boundBy: i + 1).tap()
            sleep(2)
            save("2\(i + 1)-\(code)-\(name)")
        }

        let fresh = XCUIApplication()
        fresh.launchArguments = ["-freshStart", "-appLanguage", code]
        fresh.launch()
        sleep(1)
        save("25-\(code)-onboarding-welcome")
        for step in 0..<6 {
            let button = fresh.buttons[step == 0 ? start : next]
            if button.waitForExistence(timeout: 3) { button.tap() }
            sleep(1)
            if step == 3 { save("26-\(code)-onboarding-goal") }
            if step == 4 { save("27-\(code)-onboarding-reminders") }
        }
    }

    func testFrench() { localized("fr", start: "Commencer", next: "Suivant") }
    func testArabic() { localized("ar", start: "ابدأ", next: "التالي") }
    func testSpanish() { localized("es", start: "Empezar", next: "Siguiente") }
}
