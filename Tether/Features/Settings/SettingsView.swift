import SwiftUI
import UIKit

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: SettingsViewModel
    @State private var isConfirmingReset = false

    init(
        environment: AppEnvironment,
        onHabitSaved: @escaping (Habit) -> Void,
        onReset: @escaping () -> Void
    ) {
        _viewModel = State(initialValue: SettingsViewModel(
            environment: environment,
            onHabitSaved: onHabitSaved,
            onReset: onReset
        ))
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        List {
            Section(AppCopy.habitSettingsSection) {
                NavigationLink {
                    HabitEditView(viewModel: viewModel)
                } label: {
                    Text(AppCopy.editHabitAction)
                }
                .accessibilityIdentifier("settings.editHabit")
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
                    .onChange(of: viewModel.reminderTime) { _, time in
                        Task {
                            await viewModel.setReminderTime(time)
                        }
                    }
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

            Section(AppCopy.aboutSettingsSection) {
                Text(viewModel.versionBuildText)
                    .accessibilityIdentifier("settings.version")
            }

            if let errorMessage = viewModel.errorMessage {
                Section {
                    ErrorBanner(message: errorMessage)
                }
            }

            if let reminderErrorMessage = viewModel.reminderErrorMessage {
                Section {
                    ErrorBanner(message: reminderErrorMessage)
                }
            }

            Section(AppCopy.dataSettingsSection) {
                Button(AppCopy.resetAllDataAction, role: .destructive) {
                    isConfirmingReset = true
                }
                .accessibilityIdentifier("settings.reset")
            }
        }
        .navigationTitle(AppCopy.settingsTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(AppCopy.doneAction) {
                    dismiss()
                }
                .accessibilityIdentifier("settings.done")
            }
        }
        .onAppear {
            viewModel.load()
            Task {
                await viewModel.loadReminderPermission()
            }
        }
        .alert(
            AppCopy.resetTitle,
            isPresented: $isConfirmingReset
        ) {
            Button(AppCopy.cancelAction, role: .cancel) {}
            Button(AppCopy.resetConfirmation, role: .destructive) {
                Task {
                    _ = await viewModel.resetAllAndCancelReminders()
                }
            }
            .accessibilityIdentifier("settings.resetConfirm")
        } message: {
            Text(AppCopy.resetBody)
        }
    }

    private func openIOSSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        UIApplication.shared.open(url)
    }
}
