import Foundation
import SwiftUI

struct TodayTetherSummary: View {
    let habit: Habit
    let snapshot: TetherSnapshot
    let days: [RecentCheckInDay]
    let calendar: Calendar
    let supportingCopy: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(formattedDate)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(TetherTheme.accent)

            Text(habit.name)
                .font(.title2.weight(.semibold))
                .foregroundStyle(TetherTheme.textPrimary)

            Text(supportingCopy)
                .font(.body)
                .foregroundStyle(TetherTheme.textSecondary)

            weeklyRow

            Text("\(AppCopy.currentTetherLabel) \(snapshot.current)  ·  \(AppCopy.bestTetherLabel) \(snapshot.best)")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(TetherTheme.textSecondary)
                .accessibilityLabel(
                    "\(AppCopy.currentTetherLabel), \(snapshot.current). \(AppCopy.bestTetherLabel), \(snapshot.best)"
                )
                .accessibilityIdentifier("today.tetherStatus")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(TetherTheme.surface, in: RoundedRectangle(cornerRadius: 24))
    }

    private var weeklyRow: some View {
        HStack(spacing: 4) {
            ForEach(days) { recentDay in
                weeklyMarker(for: recentDay, isToday: recentDay.day == days.last?.day)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(AppCopy.recentCheckInsAccessibilityLabel)
        .accessibilityIdentifier("today.week")
    }

    private func weeklyMarker(
        for recentDay: RecentCheckInDay,
        isToday: Bool
    ) -> some View {
        VStack(spacing: 6) {
            Text(weekdaySymbol(for: recentDay.day))
                .font(.caption2.weight(.semibold))
                .foregroundStyle(TetherTheme.textSecondary)

            ZStack {
                Circle()
                    .fill(markerBackground(for: recentDay))
                Circle()
                    .stroke(
                        isToday ? TetherTheme.accent : TetherTheme.separator,
                        lineWidth: isToday ? 2 : 1
                    )

                Image(systemName: markerImage(for: recentDay))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(markerForeground(for: recentDay))
            }
            .frame(width: 28, height: 28)
            .opacity(recentDay.isBeforeHabitStarted ? 0.55 : 1)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel(for: recentDay))
    }

    private var formattedDate: String {
        guard let day = days.last?.day, let date = date(for: day) else {
            return ""
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private func weekdaySymbol(for day: LocalDay) -> String {
        guard let date = date(for: day) else { return "" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "EEEEE"
        return formatter.string(from: date)
    }

    private func accessibilityLabel(for recentDay: RecentCheckInDay) -> String {
        guard let date = date(for: recentDay.day) else {
            return AppCopy.recentCheckInsAccessibilityLabel
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        let stateLabel: String
        if recentDay.isBeforeHabitStarted {
            stateLabel = AppCopy.beforeHabitBeganAccessibilityLabel
        } else if let state = recentDay.state {
            stateLabel = state.title
        } else {
            stateLabel = AppCopy.missedStateLabel
        }
        return "\(formatter.string(from: date)), \(stateLabel)"
    }

    private func markerImage(for recentDay: RecentCheckInDay) -> String {
        if recentDay.isBeforeHabitStarted {
            return "circle"
        }
        return recentDay.state?.systemImage ?? "circle"
    }

    private func markerForeground(for recentDay: RecentCheckInDay) -> Color {
        guard !recentDay.isBeforeHabitStarted else {
            return TetherTheme.separator
        }
        return recentDay.state?.tetherColor ?? TetherTheme.missed
    }

    private func markerBackground(for recentDay: RecentCheckInDay) -> Color {
        guard !recentDay.isBeforeHabitStarted, let state = recentDay.state else {
            return TetherTheme.surface
        }
        return state == .rest ? TetherTheme.accent.opacity(0.14) : TetherTheme.surface
    }

    private func date(for day: LocalDay) -> Date? {
        calendar.date(from: DateComponents(
            era: day.era,
            year: day.year,
            month: day.month,
            day: day.day,
            hour: 12
        ))
    }
}
