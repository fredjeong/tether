import XCTest
import UIKit

@MainActor
final class SettingsUITests: XCTestCase {
    func testEditingHabitPersistsAndPreservesSeededHistory() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing-reset", "-ui-testing-seed-history"]
        app.launch()

        openSettings(in: app)

        let version = app.descendants(matching: .any)["settings.version"]
        XCTAssertTrue(version.waitForExistence(timeout: 5))
        XCTAssertEqual(version.label, "Version 0.1 (1)")
        app.buttons["settings.editHabit"].tap()

        let name = app.textFields["habit.name"]
        let doneMeaning = app.textFields["habit.doneMeaning"]
        let lightMeaning = app.textFields["habit.lightMeaning"]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        XCTAssertTrue(doneMeaning.exists)
        XCTAssertTrue(lightMeaning.exists)
        XCTAssertEqual(name.value as? String, "Workout")
        XCTAssertEqual(doneMeaning.value as? String, "A full workout")
        XCTAssertEqual(lightMeaning.value as? String, "Move for 10 minutes")
        XCTAssertFalse(app.buttons["habit.save"].isEnabled)
        replaceText(in: name, with: "Training")
        replaceText(in: doneMeaning, with: "Complete the program")
        replaceText(in: lightMeaning, with: "Do one set")
        XCTAssertTrue(app.buttons["habit.save"].isEnabled)

        app.buttons["habit.save"].tap()

        XCTAssertTrue(app.buttons["settings.editHabit"].waitForExistence(timeout: 5))
        app.buttons["settings.done"].tap()
        XCTAssertTrue(app.staticTexts["Training"].waitForExistence(timeout: 5))

        app.tabBars.buttons["tab.history"].tap()
        assertLabel(
            "Current Tether, 3",
            for: app.descendants(matching: .any)["history.current"]
        )
        assertLabel(
            "Best Tether, 3",
            for: app.descendants(matching: .any)["history.best"]
        )
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

        app.terminate()
        app.launchArguments = ["-ui-testing-runtime"]
        app.launch()

        XCTAssertTrue(app.staticTexts["Training"].waitForExistence(timeout: 5))
        openSettings(in: app)
        app.buttons["settings.editHabit"].tap()
        let persistedName = app.textFields["habit.name"]
        XCTAssertTrue(persistedName.waitForExistence(timeout: 5))
        XCTAssertEqual(persistedName.value as? String, "Training")
        XCTAssertEqual(
            app.textFields["habit.doneMeaning"].value as? String,
            "Complete the program"
        )
        XCTAssertEqual(
            app.textFields["habit.lightMeaning"].value as? String,
            "Do one set"
        )
    }

    func testResetConfirmationCopyCancelAndCleanOnboardingPersistence() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing-reset", "-ui-testing-seed-history"]
        app.launch()

        openSettings(in: app)
        app.buttons["settings.reset"].tap()

        assertResetAlert(in: app)
        app.alerts.buttons["Cancel"].tap()
        XCTAssertTrue(app.buttons["settings.reset"].waitForExistence(timeout: 5))

        app.buttons["settings.reset"].tap()
        assertResetAlert(in: app)
        app.alerts.buttons.matching(identifier: "settings.resetConfirm").firstMatch.tap()

        XCTAssertTrue(
            app.staticTexts["Stay connected to who you want to become."]
                .waitForExistence(timeout: 5)
        )
        XCTAssertFalse(app.tabBars.buttons["tab.history"].exists)

        app.terminate()
        app.launchArguments = ["-ui-testing-runtime"]
        app.launch()

        XCTAssertTrue(
            app.staticTexts["Stay connected to who you want to become."]
                .waitForExistence(timeout: 5)
        )
        XCTAssertFalse(app.staticTexts["Workout"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["history.list"].exists)

        createHabit(named: "Reading", in: app)
        app.tabBars.buttons["tab.history"].tap()
        assertLabel(
            "Current Tether, 0",
            for: app.descendants(matching: .any)["history.current"]
        )
        assertLabel(
            "Best Tether, 0",
            for: app.descendants(matching: .any)["history.best"]
        )
        assertLabel(
            "Done, 0",
            for: app.descendants(matching: .any)["history.doneCount"]
        )
        assertLabel(
            "Light, 0",
            for: app.descendants(matching: .any)["history.lightCount"]
        )
        assertLabel(
            "Rest, 0",
            for: app.descendants(matching: .any)["history.restCount"]
        )
    }

    func testReminderToggleShowsTimeWithoutARealPermissionAlert() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-ui-testing-reset",
            "-ui-testing-seed-habit",
            "-ui-testing-seed-reminder"
        ]
        app.launch()

        openSettings(in: app)
        let reminder = app.switches["reminder.toggle"]
        XCTAssertTrue(reminder.waitForExistence(timeout: 5))
        XCTAssertEqual(reminder.value as? String, "1")

        XCTAssertTrue(
            app.descendants(matching: .any)["reminder.time"].waitForExistence(timeout: 5)
        )
        XCTAssertFalse(app.alerts.element.exists)
    }

    func testAppearanceControlPersistsDarkSelection() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing-reset", "-ui-testing-seed-habit"]
        app.launch()

        openSettings(in: app)
        let appearance = app.segmentedControls["settings.appearance"]
        XCTAssertTrue(appearance.waitForExistence(timeout: 5))

        appearance.buttons["Dark"].tap()
        XCTAssertTrue(appearance.buttons["Dark"].isSelected)
        XCTAssertTrue(app.segmentedControls["settings.appearance"].exists)
        XCTAssertTrue(app.buttons["settings.editHabit"].exists)
        XCTAssertTrue(app.switches["reminder.toggle"].exists)
        XCTAssertTrue(app.buttons["settings.reset"].exists)

        app.terminate()
        app.launchArguments = ["-ui-testing-runtime"]
        app.launch()

        openSettings(in: app)
        XCTAssertTrue(
            app.segmentedControls["settings.appearance"].buttons["Dark"].isSelected
        )
    }

    func testAppearanceControlPersistsSystemSelection() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing-reset", "-ui-testing-seed-habit"]
        app.launch()

        openSettings(in: app)
        let appearance = app.segmentedControls["settings.appearance"]
        XCTAssertTrue(appearance.waitForExistence(timeout: 5))
        appearance.buttons["System"].tap()
        XCTAssertTrue(appearance.buttons["System"].isSelected)

        app.terminate()
        app.launchArguments = ["-ui-testing-runtime"]
        app.launch()

        openSettings(in: app)
        XCTAssertTrue(
            app.segmentedControls["settings.appearance"].buttons["System"].isSelected
        )
    }

    func testAppearanceSelectionUpdatesOpenSettingsColorScheme() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing-reset", "-ui-testing-seed-habit"]
        app.launch()

        openSettings(in: app)
        let appearance = app.segmentedControls["settings.appearance"]
        XCTAssertTrue(appearance.waitForExistence(timeout: 5))

        appearance.buttons["Dark"].tap()
        XCTAssertTrue(appearance.buttons["Dark"].isSelected)
        let darkLuminance = settingsLuminance(in: app)

        appearance.buttons["Light"].tap()
        XCTAssertTrue(appearance.buttons["Light"].isSelected)
        let lightLuminance = settingsLuminance(in: app)

        XCTAssertGreaterThan(lightLuminance, darkLuminance + 80)
    }

    func testSystemSelectionRestoresOpenSettingsToSystemAppearance() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing-reset", "-ui-testing-seed-habit"]
        app.launch()

        openSettings(in: app)
        let appearance = app.segmentedControls["settings.appearance"]
        XCTAssertTrue(appearance.waitForExistence(timeout: 5))

        appearance.buttons["Dark"].tap()
        XCTAssertTrue(appearance.buttons["Dark"].isSelected)
        let darkLuminance = settingsLuminance(in: app)

        appearance.buttons["System"].tap()
        XCTAssertTrue(appearance.buttons["System"].isSelected)
        let systemLuminance = settingsLuminance(in: app)

        switch UIScreen.main.traitCollection.userInterfaceStyle {
        case .light:
            XCTAssertGreaterThan(systemLuminance, darkLuminance + 80)
        case .dark:
            XCTAssertEqual(systemLuminance, darkLuminance, accuracy: 20)
        default:
            XCTFail("Expected a concrete system appearance.")
        }
    }

    private func openSettings(in app: XCUIApplication) {
        let settings = app.buttons["settings.open"]
        XCTAssertTrue(settings.waitForExistence(timeout: 5))
        settings.tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
    }

    private func settingsLuminance(in app: XCUIApplication) -> CGFloat {
        let screenshot = XCUIScreen.main.screenshot()
        guard let image = UIImage(data: screenshot.pngRepresentation),
              let cgImage = image.cgImage else {
            XCTFail("Expected a settings screenshot.")
            return 0
        }

        let point = CGPoint(
            x: CGFloat(cgImage.width) * 0.05,
            y: CGFloat(cgImage.height) * 0.30
        )
        var pixel = [UInt8](repeating: 0, count: 4)
        guard let context = CGContext(
            data: &pixel,
            width: 1,
            height: 1,
            bitsPerComponent: 8,
            bytesPerRow: 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            XCTFail("Expected a bitmap context.")
            return 0
        }

        context.translateBy(x: -point.x, y: -point.y)
        context.draw(cgImage, in: CGRect(
            x: 0,
            y: 0,
            width: cgImage.width,
            height: cgImage.height
        ))
        return 0.2126 * CGFloat(pixel[0])
            + 0.7152 * CGFloat(pixel[1])
            + 0.0722 * CGFloat(pixel[2])
    }

    private func assertResetAlert(in app: XCUIApplication) {
        let alert = app.alerts["Reset Tether?"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        XCTAssertTrue(
            alert.staticTexts[
                "This will permanently delete your habit and all check-ins from this iPhone."
            ].exists
        )
        XCTAssertTrue(alert.buttons["settings.resetConfirm"].exists)
        XCTAssertTrue(alert.buttons["Cancel"].exists)
    }

    private func replaceText(in field: XCUIElement, with value: String) {
        guard let currentValue = field.value as? String else {
            XCTFail("Expected an editable text value.")
            return
        }
        field.tap()
        field.typeText(String(
            repeating: XCUIKeyboardKey.delete.rawValue,
            count: currentValue.count
        ))
        field.typeText(value)
        XCTAssertEqual(field.value as? String, value)
    }

    private func createHabit(named name: String, in app: XCUIApplication) {
        app.buttons["onboarding.start"].tap()

        let nameField = app.textFields["habit.name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeText(name)
        app.textFields["habit.doneMeaning"].tap()
        app.textFields["habit.doneMeaning"].typeText("Read a chapter")
        app.textFields["habit.lightMeaning"].tap()
        app.textFields["habit.lightMeaning"].typeText("Read one page")
        app.buttons["habit.submit"].tap()

        XCTAssertTrue(app.staticTexts[name].waitForExistence(timeout: 5))
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
