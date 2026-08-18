import SwiftUI

struct WelcomeView: View {
    let onStart: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(AppCopy.productName)
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(TetherTheme.textPrimary)

                Text(AppCopy.productOneLiner)
                    .font(.title3.weight(.medium))
                    .foregroundStyle(TetherTheme.textPrimary)

                Text(AppCopy.welcomeHeadline)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(TetherTheme.textPrimary)

                Text(AppCopy.welcomeSupportingCopy)
                    .font(.body)
                    .foregroundStyle(TetherTheme.textSecondary)

                VStack(alignment: .leading, spacing: 16) {
                    StateDescription(
                        state: .done,
                        title: AppCopy.doneLabel,
                        detail: AppCopy.doneHelper
                    )
                    StateDescription(
                        state: .light,
                        title: AppCopy.lightLabel,
                        detail: AppCopy.lightHelper
                    )
                    StateDescription(
                        state: .rest,
                        title: AppCopy.restLabel,
                        detail: AppCopy.restHelper
                    )
                }

                Button(AppCopy.welcomePrimaryAction, action: onStart)
                    .buttonStyle(.borderedProminent)
                    .tint(TetherTheme.accent)
                    .controlSize(.large)
                    .accessibilityIdentifier("onboarding.start")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .background(TetherTheme.canvas)
        .navigationTitle(AppCopy.productName)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct StateDescription: View {
    let state: CheckInState
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: state.systemImage)
                .font(.title3)
                .foregroundStyle(state.tetherColor)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(TetherTheme.textPrimary)
                Text(detail)
                    .foregroundStyle(TetherTheme.textSecondary)
            }
        }
    }
}
