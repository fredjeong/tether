import Foundation
import Testing
@testable import Tether

struct TetherCalculatorTests {
    @Test func noCheckInsStartsWithZeroTethers() {
        let result = snapshot(checkIns: [], today: day(1))

        #expect(result == TetherSnapshot(
            current: 0,
            best: 0,
            phase: .start,
            isCheckedInToday: false
        ))
    }

    @Test func todayDoneStartsAnActiveTether() {
        let result = snapshot(
            checkIns: [makeCheckIn(on: day(1), state: .done)],
            today: day(1)
        )

        #expect(result == TetherSnapshot(
            current: 1,
            best: 1,
            phase: .active,
            isCheckedInToday: true
        ))
    }

    @Test func doneLightAndRestAllMaintainTheConnection() {
        let result = snapshot(
            checkIns: [
                makeCheckIn(on: day(1), state: .done),
                makeCheckIn(on: day(2), state: .light),
                makeCheckIn(on: day(3), state: .rest),
            ],
            today: day(3)
        )

        #expect(result == TetherSnapshot(
            current: 3,
            best: 3,
            phase: .active,
            isCheckedInToday: true
        ))
    }

    @Test func pendingTodayPreservesTheChainEndingYesterday() {
        let result = snapshot(
            checkIns: [
                makeCheckIn(on: day(1), state: .done),
                makeCheckIn(on: day(2), state: .light),
            ],
            today: day(3)
        )

        #expect(result == TetherSnapshot(
            current: 2,
            best: 2,
            phase: .active,
            isCheckedInToday: false
        ))
    }

    @Test func missedYesterdayWithNoTodayCheckInRequiresReconnect() {
        let result = snapshot(
            checkIns: [makeCheckIn(on: day(1), state: .done)],
            today: day(3)
        )

        #expect(result == TetherSnapshot(
            current: 0,
            best: 1,
            phase: .reconnect,
            isCheckedInToday: false
        ))
    }

    @Test func todayRestStartsANewTetherAfterAMissedDay() {
        let result = snapshot(
            checkIns: [
                makeCheckIn(on: day(1), state: .done),
                makeCheckIn(on: day(3), state: .rest),
            ],
            today: day(3)
        )

        #expect(result == TetherSnapshot(
            current: 1,
            best: 1,
            phase: .active,
            isCheckedInToday: true
        ))
    }

    @Test func bestRemainsTheLongestHistoricalSegment() {
        let result = snapshot(
            checkIns: [
                makeCheckIn(on: day(1), state: .done),
                makeCheckIn(on: day(2), state: .light),
                makeCheckIn(on: day(3), state: .rest),
                makeCheckIn(on: day(5), state: .done),
                makeCheckIn(on: day(6), state: .light),
            ],
            today: day(6)
        )

        #expect(result == TetherSnapshot(
            current: 2,
            best: 3,
            phase: .active,
            isCheckedInToday: true
        ))
    }

    @Test func daysBeforeTheFirstCheckInDoNotAffectCounts() {
        let result = snapshot(
            habitCreatedOn: day(1),
            checkIns: [
                makeCheckIn(on: day(4), state: .done),
                makeCheckIn(on: day(5), state: .light),
            ],
            today: day(5)
        )

        #expect(result == TetherSnapshot(
            current: 2,
            best: 2,
            phase: .active,
            isCheckedInToday: true
        ))
    }

    @Test func duplicateDaysDoNotInflateOrBreakSegments() {
        let result = snapshot(
            checkIns: [
                makeCheckIn(on: day(1), state: .done),
                makeCheckIn(on: day(2), state: .done, updatedAt: timestamp(10)),
                makeCheckIn(on: day(2), state: .rest, updatedAt: timestamp(20)),
                makeCheckIn(on: day(3), state: .light),
            ],
            today: day(3)
        )

        #expect(result == TetherSnapshot(
            current: 3,
            best: 3,
            phase: .active,
            isCheckedInToday: true
        ))
    }

    @Test func anOlderDuplicateAfterTheNewestRecordDoesNotChangeTetherCounts() {
        let result = snapshot(
            checkIns: [
                makeCheckIn(on: day(1), state: .done),
                makeCheckIn(on: day(2), state: .rest, updatedAt: timestamp(20)),
                makeCheckIn(on: day(2), state: .done, updatedAt: timestamp(10)),
                makeCheckIn(on: day(3), state: .light),
            ],
            today: day(3)
        )

        #expect(result == TetherSnapshot(
            current: 3,
            best: 3,
            phase: .active,
            isCheckedInToday: true
        ))
    }

    @Test func checkInsOutsideTheHabitAndTodayRangeAreDiscarded() {
        let result = snapshot(
            habitCreatedOn: day(2),
            checkIns: [
                makeCheckIn(on: day(1), state: .done),
                makeCheckIn(on: day(2), state: .light),
                makeCheckIn(on: day(3), state: .rest),
            ],
            today: day(2)
        )

        #expect(result == TetherSnapshot(
            current: 1,
            best: 1,
            phase: .active,
            isCheckedInToday: true
        ))
    }

    @Test func onlyOutOfRangeCheckInsStillProduceStart() {
        let result = snapshot(
            habitCreatedOn: day(2),
            checkIns: [
                makeCheckIn(on: day(1), state: .done),
                makeCheckIn(on: day(3), state: .rest),
            ],
            today: day(2)
        )

        #expect(result == TetherSnapshot(
            current: 0,
            best: 0,
            phase: .start,
            isCheckedInToday: false
        ))
    }

    private func snapshot(
        habitCreatedOn: LocalDay? = nil,
        checkIns: [DailyCheckIn],
        today: LocalDay
    ) -> TetherSnapshot {
        TetherCalculator.snapshot(
            habitCreatedOn: habitCreatedOn ?? day(1),
            checkIns: checkIns,
            today: today,
            calendar: utcCalendar()
        )
    }

    private func makeCheckIn(
        on day: LocalDay,
        state: CheckInState,
        updatedAt: Date = Date(timeIntervalSince1970: 0)
    ) -> DailyCheckIn {
        DailyCheckIn(
            id: UUID(),
            habitID: UUID(uuidString: "A4B0E90E-B706-4748-8E7D-5706E952BC95")!,
            day: day,
            state: state,
            createdAt: Date(timeIntervalSince1970: 0),
            updatedAt: updatedAt
        )
    }

    private func day(_ value: Int) -> LocalDay {
        LocalDay(era: 1, year: 2026, month: 1, day: value)
    }

    private func timestamp(_ value: TimeInterval) -> Date {
        Date(timeIntervalSince1970: value)
    }

    private func utcCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }
}
