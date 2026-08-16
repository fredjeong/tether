import XCTest

@MainActor
final class TetherUITests: XCTestCase {
    func testLaunchesToEnglishFoundationScreen() {
        let app = XCUIApplication()

        app.launch()

        XCTAssertTrue(app.staticTexts["Tether"].waitForExistence(timeout: 5))
    }
}
