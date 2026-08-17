import Foundation

enum HistoryBuilder {
    static func build(
        habit: Habit,
        checkIns: [DailyCheckIn],
        today: LocalDay,
        calendar: Calendar,
        limit: Int = 30
    ) -> HistorySummary {
        let habitCreatedOn = LocalDay(date: habit.createdAt, calendar: calendar)
        let recordsByDay = checkIns.reduce(into: [LocalDay: DailyCheckIn]()) { result, checkIn in
            guard
                checkIn.habitID == habit.id,
                checkIn.day >= habitCreatedOn,
                checkIn.day <= today
            else {
                return
            }

            if let existing = result[checkIn.day], existing.updatedAt >= checkIn.updatedAt {
                return
            }
            result[checkIn.day] = checkIn
        }
        let normalizedCheckIns = Array(recordsByDay.values)
        let snapshot = TetherCalculator.snapshot(
            habitCreatedOn: habitCreatedOn,
            checkIns: normalizedCheckIns,
            today: today,
            calendar: calendar
        )

        let counts = normalizedCheckIns.reduce(
            into: (done: 0, light: 0, rest: 0)
        ) { counts, checkIn in
            switch checkIn.state {
            case .done:
                counts.done += 1
            case .light:
                counts.light += 1
            case .rest:
                counts.rest += 1
            }
        }

        var days: [HistoryDay] = []
        let visibleLimit = min(max(limit, 0), 30)
        var day = today
        while days.count < visibleLimit, day >= habitCreatedOn {
            days.append(HistoryDay(day: day, state: recordsByDay[day]?.state))
            day = day.adding(days: -1, calendar: calendar)
        }

        return HistorySummary(
            current: snapshot.current,
            best: snapshot.best,
            doneCount: counts.done,
            lightCount: counts.light,
            restCount: counts.rest,
            days: days
        )
    }
}
