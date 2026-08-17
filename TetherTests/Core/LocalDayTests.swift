import Foundation
import Testing
@testable import Tether

struct LocalDayTests {
    @Test func timesOnTheSameLocalDayProduceEqualValues() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "Asia/Seoul"))
        let early = try #require(calendar.date(
            from: DateComponents(year: 2026, month: 8, day: 17, hour: 0, minute: 1)
        ))
        let late = try #require(calendar.date(
            from: DateComponents(year: 2026, month: 8, day: 17, hour: 23, minute: 59)
        ))

        #expect(LocalDay(date: early, calendar: calendar) == LocalDay(date: late, calendar: calendar))
    }

    @Test func addsOneCalendarDayAcrossMonthBoundary() {
        let calendar = utcCalendar()
        let day = LocalDay(era: 1, year: 2026, month: 1, day: 31)

        #expect(
            day.adding(days: 1, calendar: calendar)
                == LocalDay(era: 1, year: 2026, month: 2, day: 1)
        )
    }

    @Test func addsOneCalendarDayAcrossYearBoundary() {
        let calendar = utcCalendar()
        let day = LocalDay(era: 1, year: 2026, month: 12, day: 31)

        #expect(
            day.adding(days: 1, calendar: calendar)
                == LocalDay(era: 1, year: 2027, month: 1, day: 1)
        )
    }

    @Test func addsOneCalendarDayAcrossSpringDaylightSavingTransition() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "America/Los_Angeles"))
        let day = LocalDay(era: 1, year: 2026, month: 3, day: 8)

        #expect(
            day.adding(days: 1, calendar: calendar)
                == LocalDay(era: 1, year: 2026, month: 3, day: 9)
        )
    }

    @Test func storageKeyIsStableAndZeroPadded() {
        let day = LocalDay(era: 1, year: 2026, month: 3, day: 8)

        #expect(day.storageKey == "1-2026-03-08")
    }

    @Test func comparisonUsesEraYearMonthAndDayOrder() {
        let days = [
            LocalDay(era: 1, year: 2026, month: 2, day: 1),
            LocalDay(era: 0, year: 2026, month: 1, day: 1),
            LocalDay(era: 1, year: 2025, month: 12, day: 31),
            LocalDay(era: 1, year: 2026, month: 1, day: 2),
            LocalDay(era: 1, year: 2026, month: 1, day: 1),
        ]

        #expect(days.sorted() == [
            LocalDay(era: 0, year: 2026, month: 1, day: 1),
            LocalDay(era: 1, year: 2025, month: 12, day: 31),
            LocalDay(era: 1, year: 2026, month: 1, day: 1),
            LocalDay(era: 1, year: 2026, month: 1, day: 2),
            LocalDay(era: 1, year: 2026, month: 2, day: 1),
        ])
    }

    private func utcCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }
}
