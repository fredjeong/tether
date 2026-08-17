import XCTest

@MainActor
final class TetherUITests: XCTestCase {
    func testLaunchesToEnglishFoundationScreen() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing-reset"]
        app.launch()

        XCTAssertTrue(app.staticTexts["Tether"].waitForExistence(timeout: 5))
    }
}
