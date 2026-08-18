import XCTest

@MainActor
final class TodayUITests: XCTestCase {
    func testDailyCheckInCanBeChangedAndPersistsAcrossRelaunch() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing-reset", "-ui-testing-seed-habit"]
        app.launch()

        let done = app.buttons["checkin.done"]
        let light = app.buttons["checkin.light"]
        let rest = app.buttons["checkin.rest"]

        XCTAssertTrue(done.waitForExistence(timeout: 5))
        XCTAssertTrue(light.exists)
        XCTAssertTrue(rest.exists)
        XCTAssertEqual(done.label, "Done, I did what I planned.")
        XCTAssertEqual(light.label, "Light, I did a smaller version.")
        XCTAssertEqual(rest.label, "Rest, I chose to rest today.")

        done.tap()

        XCTAssertTrue(app.staticTexts["You're still connected."].waitForExistence(timeout: 5))

        app.buttons["checkin.change"].tap()
        app.buttons["checkin.rest"].tap()

        let selectedRest = app.otherElements["today.selectedState"]
        XCTAssertTrue(selectedRest.waitForExistence(timeout: 5))
        XCTAssertEqual(selectedRest.label, "Rest, selected, I chose to rest today.")

        app.terminate()
        app.launchArguments = ["-ui-testing-seed-habit"]
        app.launch()

        let persistedRest = app.otherElements["today.selectedState"]
        XCTAssertTrue(persistedRest.waitForExistence(timeout: 5))
        XCTAssertEqual(persistedRest.label, "Rest, selected, I chose to rest today.")
    }
}
