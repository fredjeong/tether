import Foundation

enum ReminderPlanBuilder {
    private static let identifierPrefix = "tether.daily."
    private static let title = "A moment for your habit"
    private static let body = "Was today Done, Light, or Rest?"
    private static let planCount = 30

    static func build(
        settings: ReminderSettings,
        now: Date,
        calendar: Calendar,
        checkedDays: Set<LocalDay>
    ) -> [ReminderPlan] {
        guard settings.isEnabled else {
            return []
        }

        let today = LocalDay(date: now, calendar: calendar)
        let todayReminder = dateComponents(
            for: today,
            settings: settings,
            calendar: calendar
        )
        var candidate = today
        if let reminderDate = calendar.date(from: todayReminder), now >= reminderDate {
            candidate = candidate.adding(days: 1, calendar: calendar)
        }

        var plans: [ReminderPlan] = []
        while plans.count < planCount {
            if !checkedDays.contains(candidate) {
                plans.append(ReminderPlan(
                    identifier: identifierPrefix + candidate.storageKey,
                    dateComponents: dateComponents(
                        for: candidate,
                        settings: settings,
                        calendar: calendar
                    ),
                    title: title,
                    body: body
                ))
            }
            candidate = candidate.adding(days: 1, calendar: calendar)
        }

        return plans
    }

    private static func dateComponents(
        for day: LocalDay,
        settings: ReminderSettings,
        calendar: Calendar
    ) -> DateComponents {
        DateComponents(
            calendar: calendar,
            timeZone: calendar.timeZone,
            era: day.era,
            year: day.year,
            month: day.month,
            day: day.day,
            hour: settings.hour,
            minute: settings.minute
        )
    }
}
