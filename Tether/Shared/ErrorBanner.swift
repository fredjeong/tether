import SwiftUI

struct ErrorBanner: View {
    let message: String

    var body: some View {
        Label(message, systemImage: "exclamationmark.circle")
            .font(.subheadline)
            .foregroundStyle(TetherTheme.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(TetherTheme.surface, in: RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(TetherTheme.separator, lineWidth: 1)
            }
            .accessibilityElement(children: .combine)
    }
}
