import SwiftUI
import UIKit

struct HabitSetupView: View {
    private enum Field: Hashable {
        case name
        case doneMeaning
        case lightMeaning
    }

    @State private var viewModel: OnboardingViewModel
    @FocusState private var focusedField: Field?

    init(
        environment: AppEnvironment,
        onCreated: @escaping (Habit) -> Void,
        onReminderError: @escaping (String?) -> Void = { _ in }
    ) {
        _viewModel = State(
            initialValue: OnboardingViewModel(
                environment: environment,
                onCreated: onCreated,
                onReminderError: onReminderError
            )
        )
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        Form {
            Section {
                TextField(
                    AppCopy.habitNameLabel,
                    text: limitedBinding(for: $viewModel.name, limit: 40)
                )
                .textContentType(nil)
                .textInputAutocapitalization(.sentences)
                .autocorrectionDisabled(false)
                .submitLabel(.next)
                .focused($focusedField, equals: .name)
                .accessibilityIdentifier("habit.name")
                .onSubmit {
                    focusedField = .doneMeaning
                }

                TextField(
                    AppCopy.doneMeaningLabel,
                    text: limitedBinding(for: $viewModel.doneMeaning, limit: 80)
                )
                .textContentType(nil)
                .textInputAutocapitalization(.sentences)
                .autocorrectionDisabled(false)
                .submitLabel(.next)
                .focused($focusedField, equals: .doneMeaning)
                .accessibilityIdentifier("habit.doneMeaning")
                .onSubmit {
                    focusedField = .lightMeaning
                }

                TextField(
                    AppCopy.lightMeaningLabel,
                    text: limitedBinding(for: $viewModel.lightMeaning, limit: 80)
                )
                .textContentType(nil)
                .textInputAutocapitalization(.sentences)
                .autocorrectionDisabled(false)
                .submitLabel(.done)
                .focused($focusedField, equals: .lightMeaning)
                .accessibilityIdentifier("habit.lightMeaning")
                .onSubmit(submit)
            } header: {
                Text(AppCopy.habitSetupTitle)
            }

            Section(AppCopy.reminderSettingsSection) {
                Toggle(
                    AppCopy.dailyReminderLabel,
                    isOn: Binding(
                        get: { viewModel.isReminderEnabled },
                        set: { isEnabled in
                            Task {
                                await viewModel.setReminderEnabled(isEnabled)
                            }
                        }
                    )
                )
                .accessibilityIdentifier("reminder.toggle")

                if viewModel.isReminderEnabled {
                    DatePicker(
                        "Reminder time",
                        selection: $viewModel.reminderTime,
                        displayedComponents: .hourAndMinute
                    )
                    .accessibilityIdentifier("reminder.time")
                }

                if let message = viewModel.reminderPermissionMessage {
                    Text(message)
                        .accessibilityIdentifier("reminder.permissionMessage")
                }

                if viewModel.showsOpenSettingsAction {
                    Button(AppCopy.openIOSSettingsAction, action: openIOSSettings)
                        .accessibilityIdentifier("reminder.openSettings")
                }
            }

            if let errorMessage = viewModel.errorMessage {
                ErrorBanner(message: errorMessage)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }

            Section {
                Button(AppCopy.habitSetupSubmitAction, action: submit)
                    .frame(maxWidth: .infinity)
                    .disabled(!viewModel.canSubmit)
                    .accessibilityIdentifier("habit.submit")
            }
        }
        .navigationTitle(AppCopy.habitSetupTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            focusedField = .name
        }
    }

    private func limitedBinding(
        for binding: Binding<String>,
        limit: Int
    ) -> Binding<String> {
        Binding(
            get: { binding.wrappedValue },
            set: { binding.wrappedValue = String($0.prefix(limit)) }
        )
    }

    private func submit() {
        Task {
            _ = await viewModel.submitWithReminderReconciliation()
        }
    }

    private func openIOSSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        UIApplication.shared.open(url)
    }
}
