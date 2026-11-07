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
