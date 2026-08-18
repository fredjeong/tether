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
                    .foregroundStyle(state.tetherColor)

                VStack(alignment: .leading, spacing: 4) {
                    Text(state.title)
                        .font(.headline)
                    Text(state.helper)
                        .font(.subheadline)
                        .foregroundStyle(TetherTheme.textSecondary)
                }

                Spacer()

                Image(systemName: "circle")
                    .font(.title3)
                    .foregroundStyle(TetherTheme.missed)
            }
            .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
            .padding(16)
            .background(TetherTheme.surface, in: RoundedRectangle(cornerRadius: 20))
            .overlay {
                RoundedRectangle(cornerRadius: 20)
                    .stroke(TetherTheme.separator, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
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

    var tetherColor: Color {
        switch self {
        case .done: TetherTheme.done
        case .light: TetherTheme.light
        case .rest: TetherTheme.rest
        }
    }
}
