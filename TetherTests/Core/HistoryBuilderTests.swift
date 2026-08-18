import Foundation
import Testing
@testable import Tether

struct HistoryBuilderTests {
    @Test
    func rowsStartTodayAndDescendToHabitCreationAcrossMonthBoundary() throws {
        let fixture = HistoryFixture()
        let habit = fixture.makeHabit(createdOn: fixture.day(year: 2026, month: 1, day: 29))
        let today = fixture.day(year: 2026, month: 2, day: 2)
        let checkIns = [
            fixture.makeCheckIn(habitID: habit.id, on: today, state: .done),
            fixture.makeCheckIn(
                habitID: habit.id,
                on: fixture.day(year: 2026, month: 1, day: 31),
                state: .light
            ),
        ]

        let result = HistoryBuilder.build(
            habit: habit,
            checkIns: checkIns,
            today: today,
            calendar: fixture.calendar,
            limit: 30
        )

        #expect(result.days == [
            HistoryDay(day: fixture.day(year: 2026, month: 2, day: 2), state: .done),
            HistoryDay(day: fixture.day(year: 2026, month: 2, day: 1), state: nil),
            HistoryDay(day: fixture.day(year: 2026, month: 1, day: 31), state: .light),
            HistoryDay(day: fixture.day(year: 2026, month: 1, day: 30), state: nil),
            HistoryDay(day: fixture.day(year: 2026, month: 1, day: 29), state: nil),
        ])
    }

    @Test
    func rowsNeverExceedThirtyEvenWhenLimitIsLarger() {
        let fixture = HistoryFixture()
        let habit = fixture.makeHabit(createdOn: fixture.day(year: 2026, month: 1, day: 1))
        let today = fixture.day(year: 2026, month: 3, day: 1)

        let result = HistoryBuilder.build(
            habit: habit,
            checkIns: [],
            today: today,
            calendar: fixture.calendar,
            limit: 90
        )

        #expect(result.days.count == 30)
        #expect(result.days.first?.day == today)
        #expect(result.days.last?.day == today.adding(days: -29, calendar: fixture.calendar))
    }

    @Test
    func countsUseAllNormalizedRecordsRatherThanOnlyVisibleRows() {
        let fixture = HistoryFixture()
        let habit = fixture.makeHabit(createdOn: fixture.day(year: 2026, month: 1, day: 1))
        let today = fixture.day(year: 2026, month: 2, day: 15)
        let checkIns = [
            fixture.makeCheckIn(
                habitID: habit.id,
                on: fixture.day(year: 2026, month: 1, day: 1),
                state: .done
            ),
            fixture.makeCheckIn(
                habitID: habit.id,
                on: fixture.day(year: 2026, month: 1, day: 2),
                state: .light
            ),
            fixture.makeCheckIn(
                habitID: habit.id,
                on: fixture.day(year: 2026, month: 1, day: 3),
                state: .rest
            ),
            fixture.makeCheckIn(habitID: habit.id, on: today, state: .done),
        ]

        let result = HistoryBuilder.build(
            habit: habit,
            checkIns: checkIns,
            today: today,
            calendar: fixture.calendar,
            limit: 3
        )

        #expect(result.days.count == 3)
        #expect(result.doneCount == 2)
        #expect(result.lightCount == 1)
        #expect(result.restCount == 1)
    }

    @Test
    func duplicateDaysUseTheMostRecentlyUpdatedRecord() {
        let fixture = HistoryFixture()
        let today = fixture.day(year: 2026, month: 8, day: 17)
        let habit = fixture.makeHabit(createdOn: today)
        let checkIns = [
            fixture.makeCheckIn(
                habitID: habit.id,
                on: today,
                state: .done,
                updatedAt: Date(timeIntervalSince1970: 10)
            ),
            fixture.makeCheckIn(
                habitID: habit.id,
                on: today,
                state: .rest,
                updatedAt: Date(timeIntervalSince1970: 20)
            ),
        ]

        let result = HistoryBuilder.build(
            habit: habit,
            checkIns: checkIns,
            today: today,
            calendar: fixture.calendar,
            limit: 30
        )

        #expect(result.days == [HistoryDay(day: today, state: .rest)])
        #expect(result.doneCount == 0)
        #expect(result.restCount == 1)
    }

    @Test
    func futureAndPreCreationRecordsAreExcludedFromRowsCountsAndMetrics() {
        let fixture = HistoryFixture()
        let creationDay = fixture.day(year: 2026, month: 8, day: 16)
        let today = fixture.day(year: 2026, month: 8, day: 17)
        let habit = fixture.makeHabit(createdOn: creationDay)
        let checkIns = [
            fixture.makeCheckIn(
                habitID: habit.id,
                on: fixture.day(year: 2026, month: 8, day: 15),
                state: .done
            ),
            fixture.makeCheckIn(habitID: habit.id, on: today, state: .light),
            fixture.makeCheckIn(
                habitID: habit.id,
                on: fixture.day(year: 2026, month: 8, day: 18),
                state: .rest
            ),
        ]

        let result = HistoryBuilder.build(
            habit: habit,
            checkIns: checkIns,
            today: today,
            calendar: fixture.calendar,
            limit: 30
        )

        #expect(result.days == [
            HistoryDay(day: today, state: .light),
            HistoryDay(day: creationDay, state: nil),
        ])
        #expect(result.current == 1)
        #expect(result.best == 1)
        #expect(result.doneCount == 0)
        #expect(result.lightCount == 1)
        #expect(result.restCount == 0)
    }

    @Test
    func currentAndBestMatchTheTetherCalculatorAcrossAllNormalizedRecords() {
        let fixture = HistoryFixture()
        let habit = fixture.makeHabit(createdOn: fixture.day(year: 2026, month: 8, day: 10))
        let today = fixture.day(year: 2026, month: 8, day: 17)
        let checkIns = [
            fixture.makeCheckIn(habitID: habit.id, on: fixture.day(year: 2026, month: 8, day: 10), state: .done),
            fixture.makeCheckIn(habitID: habit.id, on: fixture.day(year: 2026, month: 8, day: 11), state: .light),
            fixture.makeCheckIn(habitID: habit.id, on: fixture.day(year: 2026, month: 8, day: 12), state: .rest),
            fixture.makeCheckIn(habitID: habit.id, on: fixture.day(year: 2026, month: 8, day: 16), state: .done),
            fixture.makeCheckIn(habitID: habit.id, on: today, state: .light),
        ]

        let result = HistoryBuilder.build(
            habit: habit,
            checkIns: checkIns,
            today: today,
            calendar: fixture.calendar,
            limit: 30
        )

        #expect(result.current == 2)
        #expect(result.best == 3)
    }

    @Test
    func recentDaysReturnsExactlySevenOldestToNewestDays() throws {
        let fixture = HistoryFixture()
        let today = fixture.day(year: 2026, month: 8, day: 17)
        let habit = fixture.makeHabit(
            createdOn: fixture.day(year: 2026, month: 8, day: 14)
        )
        let checkIns = [
            fixture.makeCheckIn(
                habitID: habit.id,
                on: fixture.day(year: 2026, month: 8, day: 15),
                state: .rest
            ),
            fixture.makeCheckIn(
                habitID: habit.id,
                on: fixture.day(year: 2026, month: 8, day: 16),
                state: .light
            ),
        ]

        let days = HistoryBuilder.recentDays(
            habit: habit,
            checkIns: checkIns,
            today: today,
            calendar: fixture.calendar
        )

        #expect(days.count == 7)
        #expect(days.map(\.day) == (-6...0).map {
            today.adding(days: $0, calendar: fixture.calendar)
        })
        #expect(days.suffix(3).map(\.state) == [.rest, .light, nil])
    }

    @Test
    func recentDaysMarksDatesBeforeHabitCreationWithoutCallingThemMissed() throws {
        let fixture = HistoryFixture()
        let today = fixture.day(year: 2026, month: 8, day: 17)
        let habit = fixture.makeHabit(
            createdOn: fixture.day(year: 2026, month: 8, day: 15)
        )

        let days = HistoryBuilder.recentDays(
            habit: habit,
            checkIns: [],
            today: today,
            calendar: fixture.calendar
        )

        #expect(days.prefix(4).allSatisfy { $0.isBeforeHabitStarted })
        #expect(days.suffix(3).allSatisfy { !$0.isBeforeHabitStarted })
        #expect(days.allSatisfy { $0.state == nil })
    }

    @Test
    func recentDaysUsesTheMostRecentlyUpdatedRecordForADay() throws {
        let fixture = HistoryFixture()
        let today = fixture.day(year: 2026, month: 8, day: 17)
        let habit = fixture.makeHabit(
            createdOn: fixture.day(year: 2026, month: 8, day: 7)
        )
        let targetDay = fixture.day(year: 2026, month: 8, day: 16)
        let earlier = fixture.makeCheckIn(
            habitID: habit.id,
            on: targetDay,
            state: .done,
            updatedAt: Date(timeIntervalSince1970: 10)
        )
        let later = fixture.makeCheckIn(
            habitID: habit.id,
            on: targetDay,
            state: .rest,
            updatedAt: Date(timeIntervalSince1970: 20)
        )

        let days = HistoryBuilder.recentDays(
            habit: habit,
            checkIns: [earlier, later],
            today: today,
            calendar: fixture.calendar
        )

        #expect(days[5].state == .rest)
    }

    @Test
    func recentDaysReturnsNoDaysForANonPositiveCount() throws {
        let fixture = HistoryFixture()
        let today = fixture.day(year: 2026, month: 8, day: 17)
        let habit = fixture.makeHabit(createdOn: today)

        let zeroDays = HistoryBuilder.recentDays(
            habit: habit,
            checkIns: [],
            today: today,
            calendar: fixture.calendar,
            count: 0
        )
        let negativeDays = HistoryBuilder.recentDays(
            habit: habit,
            checkIns: [],
            today: today,
            calendar: fixture.calendar,
            count: -1
        )

        #expect(zeroDays.isEmpty)
        #expect(negativeDays.isEmpty)
    }
}

private struct HistoryFixture {
    let calendar: Calendar

    init() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        self.calendar = calendar
    }

    func day(year: Int, month: Int, day: Int) -> LocalDay {
        LocalDay(era: 1, year: year, month: month, day: day)
    }

    func makeHabit(createdOn day: LocalDay) -> Habit {
        let createdAt = date(for: day)
        return Habit(
            id: UUID(uuidString: "1E311C68-189D-4B03-A579-DA3D2AA36397")!,
            name: "Workout",
            doneMeaning: "A full workout",
            lightMeaning: "Move for 10 minutes",
            createdAt: createdAt,
            updatedAt: createdAt
        )
    }

    func makeCheckIn(
        habitID: UUID,
        on day: LocalDay,
        state: CheckInState,
        updatedAt: Date = Date(timeIntervalSince1970: 0)
    ) -> DailyCheckIn {
        DailyCheckIn(
            id: UUID(),
            habitID: habitID,
            day: day,
            state: state,
            createdAt: updatedAt,
            updatedAt: updatedAt
        )
    }

    private func date(for day: LocalDay) -> Date {
        calendar.date(from: DateComponents(
            era: day.era,
            year: day.year,
            month: day.month,
            day: day.day,
            hour: 12
        ))!
    }
}
