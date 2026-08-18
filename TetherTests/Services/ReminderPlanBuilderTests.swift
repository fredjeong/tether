import Foundation
import Testing
import UserNotifications
@testable import Tether

struct ReminderPlanBuilderTests {
    @Test
    func disabledSettingsProduceNoPlans() throws {
        let fixture = try ReminderPlanFixture(
            now: DateComponents(year: 2026, month: 8, day: 17, hour: 19)
        )

        let plans = fixture.build(
            settings: ReminderSettings(isEnabled: false, hour: 20, minute: 0)
        )

        #expect(plans.isEmpty)
    }

    @Test
    func beforeReminderTimeIncludesToday() throws {
        let fixture = try ReminderPlanFixture(
            now: DateComponents(year: 2026, month: 8, day: 17, hour: 19, minute: 59)
        )

        let plans = fixture.build()

        #expect(plans.first?.identifier == "tether.daily.1-2026-08-17")
        #expect(plans.first?.dateComponents.day == 17)
        #expect(plans.first?.dateComponents.hour == 20)
        #expect(plans.first?.dateComponents.minute == 0)
    }

    @Test
    func afterReminderTimeStartsTomorrow() throws {
        let fixture = try ReminderPlanFixture(
            now: DateComponents(year: 2026, month: 8, day: 17, hour: 20, minute: 1)
        )

        let plans = fixture.build()

        #expect(plans.first?.identifier == "tether.daily.1-2026-08-18")
        #expect(plans.first?.dateComponents.day == 18)
    }

    @Test
    func atReminderTimeStartsTomorrow() throws {
        let fixture = try ReminderPlanFixture(
            now: DateComponents(year: 2026, month: 8, day: 17, hour: 20, minute: 0)
        )

        let plans = fixture.build()

        #expect(plans.first?.identifier == "tether.daily.1-2026-08-18")
    }

    @Test
    func checkedTodayIsSkippedBeforeReminderTime() throws {
        let fixture = try ReminderPlanFixture(
            now: DateComponents(year: 2026, month: 8, day: 17, hour: 19)
        )
        let checkedToday = LocalDay(era: 1, year: 2026, month: 8, day: 17)

        let plans = fixture.build(checkedDays: [checkedToday])

        #expect(plans.first?.identifier == "tether.daily.1-2026-08-18")
    }

    @Test
    func checkedDaysAreExcludedWhileThirtyEligiblePlansAreProduced() throws {
        let fixture = try ReminderPlanFixture(
            now: DateComponents(year: 2026, month: 1, day: 1, hour: 19)
        )
        let checkedDays: Set<LocalDay> = [
            LocalDay(era: 1, year: 2026, month: 1, day: 2),
            LocalDay(era: 1, year: 2026, month: 1, day: 4),
        ]

        let plans = fixture.build(checkedDays: checkedDays)

        #expect(plans.count == 30)
        #expect(Set(plans.map(\.identifier)).count == 30)
        #expect(plans.prefix(4).map(\.identifier) == [
            "tether.daily.1-2026-01-01",
            "tether.daily.1-2026-01-03",
            "tether.daily.1-2026-01-05",
            "tether.daily.1-2026-01-06",
        ])
        #expect(plans.last?.identifier == "tether.daily.1-2026-02-01")
        #expect(plans.allSatisfy { plan in
            !checkedDays.contains(LocalDay(
                era: plan.dateComponents.era ?? 1,
                year: plan.dateComponents.year ?? 1,
                month: plan.dateComponents.month ?? 1,
                day: plan.dateComponents.day ?? 1
            ))
        })
    }

    @Test
    func daylightSavingTransitionKeepsCalendarDaysAndLocalReminderTime() throws {
        let fixture = try ReminderPlanFixture(
            timeZoneIdentifier: "America/Los_Angeles",
            now: DateComponents(year: 2026, month: 3, day: 7, hour: 19)
        )

        let plans = fixture.build()
        let firstThree = Array(plans.prefix(3))

        #expect(firstThree.map(\.identifier) == [
            "tether.daily.1-2026-03-07",
            "tether.daily.1-2026-03-08",
            "tether.daily.1-2026-03-09",
        ])
        #expect(firstThree.allSatisfy {
            $0.dateComponents.hour == 20 && $0.dateComponents.minute == 0
        })

        let dates = try firstThree.map {
            try #require(fixture.calendar.date(from: $0.dateComponents))
        }
        #expect(dates[1].timeIntervalSince(dates[0]) == 23 * 60 * 60)
        #expect(dates[2].timeIntervalSince(dates[1]) == 24 * 60 * 60)
    }

    @Test
    func monthAndYearBoundariesUseConsecutiveCalendarDays() throws {
        let fixture = try ReminderPlanFixture(
            now: DateComponents(year: 2026, month: 12, day: 31, hour: 19)
        )

        let plans = fixture.build()

        #expect(plans.prefix(3).map(\.identifier) == [
            "tether.daily.1-2026-12-31",
            "tether.daily.1-2027-01-01",
            "tether.daily.1-2027-01-02",
        ])
    }

    @Test
    func identifiersUseTheDailyPrefixAndLocalDayStorageKey() throws {
        let fixture = try ReminderPlanFixture(
            now: DateComponents(year: 2026, month: 3, day: 8, hour: 19)
        )

        let first = try #require(fixture.build().first)

        #expect(first.identifier == "tether.daily.1-2026-03-08")
        #expect(first.dateComponents.calendar == fixture.calendar)
        #expect(first.dateComponents.timeZone == fixture.calendar.timeZone)
    }

    @Test
    func everyPlanUsesTheRequiredNotificationCopy() throws {
        let fixture = try ReminderPlanFixture(
            now: DateComponents(year: 2026, month: 8, day: 17, hour: 19)
        )

        let plans = fixture.build()

        #expect(plans.count == 30)
        #expect(plans.allSatisfy { $0.title == "A moment for your habit" })
        #expect(plans.allSatisfy { $0.body == "Was today Done, Light, or Rest?" })
    }
}

@MainActor
struct FakeReminderSchedulerTests {
    @Test
    func recordsAuthorizationReconciliationAndCancellationWithoutUserNotifications() async throws {
        let scheduler = FakeReminderScheduler(
            permissionResult: .authorized,
            authorizationResult: false
        )
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "Asia/Seoul"))
        let now = try #require(calendar.date(from: DateComponents(
            year: 2026,
            month: 8,
            day: 17,
            hour: 19
        )))
        let settings = ReminderSettings(isEnabled: true, hour: 20, minute: 0)
        let checkedDays: Set<LocalDay> = [
            LocalDay(era: 1, year: 2026, month: 8, day: 17),
        ]

        #expect(await scheduler.permission() == .authorized)
        #expect(try await scheduler.requestAuthorization() == false)
        try await scheduler.reconcile(
            settings: settings,
            now: now,
            calendar: calendar,
            checkedDays: checkedDays
        )
        await scheduler.cancelAll()

        #expect(scheduler.permissionCallCount == 1)
        #expect(scheduler.authorizationRequestCount == 1)
        #expect(scheduler.authorizationResults == [false])
        #expect(scheduler.reconcileCalls == [FakeReminderScheduler.ReconcileCall(
            settings: settings,
            now: now,
            calendar: calendar,
            checkedDays: checkedDays
        )])
        #expect(scheduler.cancelAllCallCount == 1)
    }
}

struct NotificationPermissionMappingTests {
    @Test
    func mapsEveryKnownAuthorizationStatusIntoTheThreeAppStates() {
        #expect(UserNotificationReminderScheduler.permission(from: .notDetermined) == .notDetermined)
        #expect(UserNotificationReminderScheduler.permission(from: .denied) == .denied)
        #expect(UserNotificationReminderScheduler.permission(from: .authorized) == .authorized)
        #expect(UserNotificationReminderScheduler.permission(from: .provisional) == .authorized)
        #expect(UserNotificationReminderScheduler.permission(from: .ephemeral) == .authorized)
    }
}

private struct ReminderPlanFixture {
    let calendar: Calendar
    let now: Date

    init(
        timeZoneIdentifier: String = "UTC",
        now components: DateComponents
    ) throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: timeZoneIdentifier))
        self.calendar = calendar
        now = try #require(calendar.date(from: components))
    }

    func build(
        settings: ReminderSettings = ReminderSettings(
            isEnabled: true,
            hour: 20,
            minute: 0
        ),
        checkedDays: Set<LocalDay> = []
    ) -> [ReminderPlan] {
        ReminderPlanBuilder.build(
            settings: settings,
            now: now,
            calendar: calendar,
            checkedDays: checkedDays
        )
    }
}
