import SwiftUI

struct HabitEditView: View {
    private enum Field: Hashable {
        case name
        case doneMeaning
        case lightMeaning
    }

    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: SettingsViewModel
    @FocusState private var focusedField: Field?

    var body: some View {
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
                .onSubmit(save)
            }

            if let errorMessage = viewModel.errorMessage {
                ErrorBanner(message: errorMessage)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }
        }
        .navigationTitle(AppCopy.editHabitAction)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(AppCopy.saveAction, action: save)
                    .disabled(!viewModel.canSave)
                    .accessibilityIdentifier("habit.save")
            }
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

    private func save() {
        if viewModel.saveHabit() != nil {
            dismiss()
        }
    }
}
