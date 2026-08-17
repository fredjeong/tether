import Foundation
import SwiftUI

struct HistoryDayRow: View {
    let day: HistoryDay
    let calendar: Calendar

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .frame(width: 24)

            Text(formattedDate)

            Spacer()

            Text(stateLabel)
                .foregroundStyle(day.state == nil ? .secondary : .primary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(formattedDate), \(stateLabel)")
        .accessibilityIdentifier("history.day.\(day.id)")
    }

    private var stateLabel: String {
        day.state?.title ?? AppCopy.missedStateLabel
    }

    private var systemImage: String {
        day.state?.systemImage ?? "circle"
    }

    private var formattedDate: String {
        var components = DateComponents()
        components.era = day.day.era
        components.year = day.day.year
        components.month = day.day.month
        components.day = day.day.day
        components.hour = 12

        guard let date = calendar.date(from: components) else {
            return day.day.storageKey
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
