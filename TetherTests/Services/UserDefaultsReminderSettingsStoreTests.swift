import Foundation
import Testing
@testable import Tether

struct UserDefaultsReminderSettingsStoreTests {
    @Test
    func initialValuesAreDisabledAtTwentyHundred() throws {
        let fixture = try UserDefaultsReminderFixture()
        defer { fixture.cleanUp() }

        #expect(fixture.store.load() == .defaultValue)
        #expect(fixture.store.load() == ReminderSettings(
            isEnabled: false,
            hour: 20,
            minute: 0
        ))
    }

    @Test
    func savedValuesRoundTripExactly() throws {
        let fixture = try UserDefaultsReminderFixture()
        defer { fixture.cleanUp() }
        let settings = ReminderSettings(isEnabled: true, hour: 7, minute: 45)

        fixture.store.save(settings)

        let domain = try #require(
            fixture.defaults.persistentDomain(forName: fixture.suiteName)
        )
        #expect(fixture.store.load() == settings)
        #expect(Set(domain.keys) == [
            "reminder.enabled",
            "reminder.hour",
            "reminder.minute",
        ])
        #expect(domain["reminder.enabled"] as? Bool == true)
        #expect(domain["reminder.hour"] as? Int == 7)
        #expect(domain["reminder.minute"] as? Int == 45)
    }

    @Test
    func resetReturnsToDefaultValues() throws {
        let fixture = try UserDefaultsReminderFixture()
        defer { fixture.cleanUp() }
        fixture.store.save(ReminderSettings(isEnabled: true, hour: 6, minute: 30))

        fixture.store.reset()

        #expect(fixture.store.load() == .defaultValue)
        #expect(fixture.defaults.persistentDomain(forName: fixture.suiteName)?.isEmpty != false)
    }

    @Test
    func uniqueSuitesDoNotShareReminderState() throws {
        let first = try UserDefaultsReminderFixture()
        let second = try UserDefaultsReminderFixture()
        defer {
            first.cleanUp()
            second.cleanUp()
        }
        let firstSettings = ReminderSettings(isEnabled: true, hour: 9, minute: 15)

        first.store.save(firstSettings)

        #expect(first.store.load() == firstSettings)
        #expect(second.store.load() == .defaultValue)
    }
}

private struct UserDefaultsReminderFixture {
    let suiteName: String
    let defaults: UserDefaults
    let store: UserDefaultsReminderSettingsStore

    init() throws {
        let suiteName = "com.fredjeong.tether.tests.reminder.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)

        self.suiteName = suiteName
        self.defaults = defaults
        store = UserDefaultsReminderSettingsStore(userDefaults: defaults)
    }

    func cleanUp() {
        defaults.removePersistentDomain(forName: suiteName)
    }
}
