import XCTest

/// Captures the screenshots used in README.md. Skipped unless `README_SCREENSHOT_DIR` is set, so it
/// never runs as part of the normal test suite. See `scripts/readme-media.sh`, which seeds demo data,
/// records the GIF and passes the directory as `TEST_RUNNER_README_SCREENSHOT_DIR`.
final class ReadmeScreenshots: XCTestCase {

    private var outputDirectory: URL!
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        guard let path = ProcessInfo.processInfo.environment["README_SCREENSHOT_DIR"], !path.isEmpty else {
            throw XCTSkip("Set README_SCREENSHOT_DIR to capture README screenshots.")
        }
        outputDirectory = URL(fileURLWithPath: path)
        try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    @MainActor
    func testTourForReadme() throws {
        let tabs = app.tabBars.firstMatch
        XCTAssertTrue(tabs.waitForExistence(timeout: 10))
        pause(1.5)
        mark("tour-start")
        save("01-oversikt")

        // Drag from the lower cards: a swipe through the middle lands on the activity chart,
        // which takes the drag for its own value selection instead of scrolling.
        scroll(from: 0.80, to: 0.30)
        save("02-oversikt-volum")
        scroll(from: 0.80, to: 0.30)
        save("03-oversikt-siste")
        scroll(from: 0.30, to: 0.95)
        scroll(from: 0.30, to: 0.95)

        tabs.buttons["Historikk"].tap()
        pause(1)
        save("04-historikk")

        // Open the newest strength session
        let session = app.staticTexts.matching(NSPredicate(format: "label IN %@", ["Push", "Pull", "Bein"])).firstMatch
        if session.waitForExistence(timeout: 3) {
            session.tap()
            pause(1)
            save("05-okt-detaljer")
            app.navigationBars.buttons.firstMatch.tap()
            pause(0.5)
        }

        tabs.buttons["Kalender"].tap()
        pause(1)
        save("06-kalender")

        tabs.buttons["Rekorder"].tap()
        pause(1)
        save("07-rekorder")

        tabs.buttons["Oversikt"].tap()
        pause(0.8)
        app.buttons["Innstillinger"].firstMatch.tap()
        pause(1)
        save("08-innstillinger")
        mark("tour-end")
    }

    private func scroll(from startY: CGFloat, to endY: CGFloat) {
        let window = app.windows.firstMatch
        let start = window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: startY))
        let end = window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: endY))
        start.press(forDuration: 0.05, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.1)
        pause(1)
    }

    /// Writes the current time so scripts/readme-media.sh can cut the GIF to the tour.
    private func mark(_ name: String) {
        try? String(Date().timeIntervalSince1970).write(
            to: outputDirectory.appendingPathComponent(".\(name)"), atomically: true, encoding: .utf8)
    }

    private func save(_ name: String) {
        let png = XCUIScreen.main.screenshot().pngRepresentation
        try? png.write(to: outputDirectory.appendingPathComponent("\(name).png"))
    }

    private func pause(_ seconds: TimeInterval) {
        Thread.sleep(forTimeInterval: seconds)
    }
}
