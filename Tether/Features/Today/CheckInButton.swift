import SwiftUI

struct CheckInButton: View {
    let state: CheckInState
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: state.systemImage)
                    .font(.title2)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 4) {
                    Text(state.title)
                        .font(.headline)
                    Text(state.helper)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .padding(.vertical, 8)
        }
        .buttonStyle(.bordered)
        .accessibilityLabel("\(state.title), \(state.helper)")
        .accessibilityIdentifier(state.buttonIdentifier)
    }
}

extension CheckInState {
    var title: String {
        switch self {
        case .done: AppCopy.doneLabel
        case .light: AppCopy.lightLabel
        case .rest: AppCopy.restLabel
        }
    }

    var helper: String {
        switch self {
        case .done: AppCopy.doneHelper
        case .light: AppCopy.lightHelper
        case .rest: AppCopy.restHelper
        }
    }

    var systemImage: String {
        switch self {
        case .done: "checkmark.circle"
        case .light: "leaf"
        case .rest: "moon"
        }
    }

    var buttonIdentifier: String {
        switch self {
        case .done: "checkin.done"
        case .light: "checkin.light"
        case .rest: "checkin.rest"
        }
    }
}
