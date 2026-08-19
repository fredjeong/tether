import SwiftUI

enum CheckInGridLayout {
    static func usesVerticalLayout(for dynamicTypeSize: DynamicTypeSize) -> Bool {
        dynamicTypeSize.isAccessibilitySize
    }
}

struct CheckInStateGrid: View {
    let action: (CheckInState) -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Group {
            if CheckInGridLayout.usesVerticalLayout(for: dynamicTypeSize) {
                VStack(spacing: 8) {
                    ForEach(CheckInState.allCases, id: \.self) { state in
                        stateButton(for: state)
                    }
                }
            } else {
                HStack(spacing: 8) {
                    ForEach(CheckInState.allCases, id: \.self) { state in
                        stateButton(for: state)
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("today.checkInGrid")
    }

    private func stateButton(for state: CheckInState) -> some View {
        Button {
            action(state)
        } label: {
            VStack(spacing: 8) {
                Image(systemName: state.systemImage)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(state.tetherColor)
                    .frame(width: 32, height: 32)
                    .background {
                        Circle()
                            .fill(state == .rest ? TetherTheme.accent.opacity(0.14) : TetherTheme.canvas)
                    }

                Text(state.title)
                    .font(.headline)
                    .foregroundStyle(TetherTheme.textPrimary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, minHeight: 88)
            .padding(12)
            .background(TetherTheme.surface, in: RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(TetherTheme.separator, lineWidth: 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(CheckInStateButtonStyle())
        .accessibilityLabel("\(state.title), \(state.helper)")
        .accessibilityIdentifier(state.buttonIdentifier)
    }
}

struct CheckInStateButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.82 : 1)
            .scaleEffect(reduceMotion || !configuration.isPressed ? 1 : 0.98)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
