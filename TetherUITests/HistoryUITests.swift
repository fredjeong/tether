import XCTest

@MainActor
final class HistoryUITests: XCTestCase {
    func testHistoryToolbarOpensSettings() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing-reset", "-ui-testing-seed-history"]
        app.launch()

        let historyTab = app.tabBars.buttons["tab.history"]
        XCTAssertTrue(historyTab.waitForExistence(timeout: 5))
        historyTab.tap()

        let settings = app.buttons["settings.open"]
        XCTAssertTrue(settings.waitForExistence(timeout: 5))
        settings.tap()

        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
    }

    func testSeededHistoryShowsMetricsCountsAndAllDayStates() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing-reset", "-ui-testing-seed-history"]
        app.launch()

        let historyTab = app.tabBars.buttons["tab.history"]
        XCTAssertTrue(historyTab.waitForExistence(timeout: 5))
        historyTab.tap()

        let current = app.descendants(matching: .any)["history.current"]
        let best = app.descendants(matching: .any)["history.best"]
        assertLabel("Current Tether, 3", for: current)
        assertLabel("Best Tether, 3", for: best)

        let summary = app.otherElements["history.tetherSummary"]
        XCTAssertTrue(summary.waitForExistence(timeout: 5))
        XCTAssertEqual(summary.label, "Current Tether, 3. Best Tether, 3")
        XCTAssertTrue(app.descendants(matching: .any)["history.day.1-2026-08-17"].exists)

        assertLabel(
            "Done, 1",
            for: app.descendants(matching: .any)["history.doneCount"]
        )
        assertLabel(
            "Light, 1",
            for: app.descendants(matching: .any)["history.lightCount"]
        )
        assertLabel(
            "Rest, 1",
            for: app.descendants(matching: .any)["history.restCount"]
        )

        XCTAssertTrue(
            app.descendants(matching: .any)["history.list"].waitForExistence(timeout: 5)
        )
        assertLabel(
            "Aug 17, 2026, Rest",
            for: app.descendants(matching: .any)["history.day.1-2026-08-17"]
        )
        assertLabel(
            "Aug 16, 2026, Light",
            for: app.descendants(matching: .any)["history.day.1-2026-08-16"]
        )
        assertLabel(
            "Aug 15, 2026, Done",
            for: app.descendants(matching: .any)["history.day.1-2026-08-15"]
        )
        assertLabel(
            "Aug 14, 2026, No check-in",
            for: app.descendants(matching: .any)["history.day.1-2026-08-14"]
        )
    }

    func testSeededHistoryRetainsItsStructureAfterSwitchingToDarkAppearance() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing-reset", "-ui-testing-seed-history"]
        app.launch()

        app.buttons["settings.open"].tap()
        let appearance = app.segmentedControls["settings.appearance"]
        XCTAssertTrue(appearance.waitForExistence(timeout: 5))
        appearance.buttons["Dark"].tap()
        app.buttons["settings.done"].tap()
        app.tabBars.buttons["tab.history"].tap()

        XCTAssertTrue(app.otherElements["history.tetherSummary"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any)["history.day.1-2026-08-17"].exists)
    }

    private func assertLabel(
        _ expectedLabel: String,
        for element: XCUIElement,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label == %@", expectedLabel),
            object: element
        )
        XCTAssertEqual(
            XCTWaiter.wait(for: [expectation], timeout: 5),
            .completed,
            file: file,
            line: line
        )
    }
}
