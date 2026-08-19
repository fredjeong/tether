import SwiftUI

struct TodayView: View {
    private let environment: AppEnvironment
    @State private var viewModel: TodayViewModel

    init(environment: AppEnvironment) {
        self.environment = environment
        _viewModel = State(initialValue: TodayViewModel(environment: environment))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if let habit = viewModel.habit {
                    TodayTetherSummary(
                        habit: habit,
                        snapshot: viewModel.snapshot,
                        days: viewModel.recentDays,
                        calendar: environment.dayProvider.calendar,
                        supportingCopy: viewModel.supportingCopy
                    )

                    if let errorMessage = viewModel.errorMessage {
                        ErrorBanner(message: errorMessage)
                            .accessibilityIdentifier("today.error")
                    }

                    Text(AppCopy.todayPrompt)
                        .font(.title2.bold())
                        .foregroundStyle(TetherTheme.textPrimary)

                    if viewModel.selectedState == nil {
                        CheckInStateGrid { state in
                            viewModel.select(state)
                        }
                    } else if let selectedState = viewModel.selectedState {
                        savedState(selectedState)
                    }
                } else if let errorMessage = viewModel.errorMessage {
                    ErrorBanner(message: errorMessage)
                        .accessibilityIdentifier("today.error")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .background(TetherTheme.canvas)
        .navigationTitle("Today")
        .onAppear {
            viewModel.load()
        }
    }

    private func savedState(_ state: CheckInState) -> some View {
        HStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: state.systemImage)
                    .foregroundStyle(state.tetherColor)
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(state.title)
                            .font(.headline)
                        Text(AppCopy.selectionStatus)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(TetherTheme.accent)
                    }
                    Text(state.helper)
                        .font(.subheadline)
                        .foregroundStyle(TetherTheme.textSecondary)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(state.title), selected, \(state.helper)")
            .accessibilityIdentifier("today.selectedState")

            Spacer(minLength: 0)

            Button {
                viewModel.clearTodayCheckIn()
            } label: {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(state.tetherColor)
                    .frame(width: 44, height: 44)
                    .contentShape(Circle())
            }
            .buttonStyle(CheckInStateButtonStyle())
            .accessibilityLabel(AppCopy.removeCheckInAccessibilityLabel(for: state))
            .accessibilityHint(AppCopy.removeCheckInAccessibilityHint)
            .accessibilityIdentifier("checkin.cancel")
        }
        .padding(16)
        .background(TetherTheme.surface, in: RoundedRectangle(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(state.tetherColor, lineWidth: 1)
        }
    }
}
