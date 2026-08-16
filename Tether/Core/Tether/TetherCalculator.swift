import Foundation

enum TetherCalculator {
    static func snapshot(
        habitCreatedOn: LocalDay,
        checkIns: [DailyCheckIn],
        today: LocalDay,
        calendar: Calendar
    ) -> TetherSnapshot {
        let checkInsByDay = checkIns.reduce(into: [LocalDay: DailyCheckIn]()) { result, checkIn in
            guard checkIn.day >= habitCreatedOn, checkIn.day <= today else { return }

            if let existing = result[checkIn.day], existing.updatedAt >= checkIn.updatedAt {
                return
            }
            result[checkIn.day] = checkIn
        }
        let checkedDays = checkInsByDay.keys.sorted()

        guard !checkedDays.isEmpty else {
            return TetherSnapshot(
                current: 0,
                best: 0,
                phase: .start,
                isCheckedInToday: false
            )
        }

        var best = 0
        var currentSegmentLength = 0
        var segmentLengthsByEndDay: [LocalDay: Int] = [:]
        var previousDay: LocalDay?

        for checkedDay in checkedDays {
            if let previousDay,
               previousDay.adding(days: 1, calendar: calendar) == checkedDay {
                currentSegmentLength += 1
            } else {
                currentSegmentLength = 1
            }

            segmentLengthsByEndDay[checkedDay] = currentSegmentLength
            best = max(best, currentSegmentLength)
            previousDay = checkedDay
        }

        if checkInsByDay[today] != nil {
            return TetherSnapshot(
                current: segmentLengthsByEndDay[today] ?? 0,
                best: best,
                phase: .active,
                isCheckedInToday: true
            )
        }

        let yesterday = today.adding(days: -1, calendar: calendar)
        if checkInsByDay[yesterday] != nil {
            return TetherSnapshot(
                current: segmentLengthsByEndDay[yesterday] ?? 0,
                best: best,
                phase: .active,
                isCheckedInToday: false
            )
        }

        return TetherSnapshot(
            current: 0,
            best: best,
            phase: .reconnect,
            isCheckedInToday: false
        )
    }
}
