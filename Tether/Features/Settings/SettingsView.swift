import SwiftUI

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
        List {
            Section(AppCopy.habitSettingsSection) {
                NavigationLink {
                    HabitEditView(viewModel: viewModel)
                } label: {
                    Text(AppCopy.editHabitAction)
                }
                .accessibilityIdentifier("settings.editHabit")
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
        }
        .alert(
            AppCopy.resetTitle,
            isPresented: $isConfirmingReset
        ) {
            Button(AppCopy.cancelAction, role: .cancel) {}
            Button(AppCopy.resetConfirmation, role: .destructive) {
                viewModel.resetAll()
            }
            .accessibilityIdentifier("settings.resetConfirm")
        } message: {
            Text(AppCopy.resetBody)
        }
    }
}
