import SwiftUI

struct WelcomeView: View {
    let onStart: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(AppCopy.productName)
                    .font(.largeTitle.weight(.bold))

                Text(AppCopy.productOneLiner)
                    .font(.title3.weight(.medium))

                Text(AppCopy.welcomeHeadline)
                    .font(.title2.weight(.semibold))

                Text(AppCopy.welcomeSupportingCopy)
                    .font(.body)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 16) {
                    StateDescription(
                        title: AppCopy.doneLabel,
                        detail: AppCopy.doneHelper
                    )
                    StateDescription(
                        title: AppCopy.lightLabel,
                        detail: AppCopy.lightHelper
                    )
                    StateDescription(
                        title: AppCopy.restLabel,
                        detail: AppCopy.restHelper
                    )
                }

                Button(AppCopy.welcomePrimaryAction, action: onStart)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .accessibilityIdentifier("onboarding.start")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .navigationTitle(AppCopy.productName)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct StateDescription: View {
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
            Text(detail)
                .foregroundStyle(.secondary)
        }
    }
}
