import XCTest

@MainActor
final class OnboardingUITests: XCTestCase {
    func testOnboardingCreatesAHabitAndReachesTheMainTabShell() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing-reset"]

        app.launch()

        XCTAssertTrue(
            app.staticTexts["Stay connected to who you want to become."].waitForExistence(timeout: 5)
        )
        XCTAssertTrue(app.staticTexts["A habit tracker where rest counts."].exists)

        app.buttons["onboarding.start"].tap()

        let name = app.textFields["habit.name"]
        name.tap()
        name.typeText("Workout")

        let doneMeaning = app.textFields["habit.doneMeaning"]
        doneMeaning.tap()
        doneMeaning.typeText("A full workout")

        let lightMeaning = app.textFields["habit.lightMeaning"]
        lightMeaning.tap()
        lightMeaning.typeText("Move for 10 minutes")

        app.buttons["habit.submit"].tap()

        XCTAssertTrue(app.tabBars.buttons["tab.today"].waitForExistence(timeout: 5))
    }

    func testOnboardingReminderControlsUseTheFakeSchedulerConfiguration() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing-reset"]
        app.launch()

        app.buttons["onboarding.start"].tap()
        let reminder = app.switches["reminder.toggle"]
        XCTAssertTrue(reminder.waitForExistence(timeout: 5))
        XCTAssertFalse(reminder.value as? String == "1")

        reminder.tap()

        XCTAssertTrue(app.datePickers["reminder.time"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Notifications are turned off in iOS Settings."].exists)
    }
}
