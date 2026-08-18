import SwiftUI

struct TodayView: View {
    private let environment: AppEnvironment
    @State private var viewModel: TodayViewModel
    @State private var isChangingSelection = false

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

                    if viewModel.selectedState == nil || isChangingSelection {
                        CheckInStateGrid { state in
                            viewModel.select(state)
                            if viewModel.errorMessage == nil {
                                isChangingSelection = false
                            }
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
        VStack(alignment: .leading, spacing: 16) {
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
                Spacer()
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(state.tetherColor)
            }
            .padding(16)
            .background(TetherTheme.surface, in: RoundedRectangle(cornerRadius: 20))
            .overlay {
                RoundedRectangle(cornerRadius: 20)
                    .stroke(state.tetherColor, lineWidth: 1)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(state.title), selected, \(state.helper)")
            .accessibilityIdentifier("today.selectedState")

            Button(AppCopy.changeAction) {
                isChangingSelection = true
            }
            .buttonStyle(.bordered)
            .tint(TetherTheme.accent)
            .accessibilityIdentifier("checkin.change")
        }
    }
}
