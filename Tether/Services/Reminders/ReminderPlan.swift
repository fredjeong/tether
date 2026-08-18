import Foundation

struct ReminderPlan: Equatable, Sendable {
    let identifier: String
    let dateComponents: DateComponents
    let title: String
    let body: String
}
