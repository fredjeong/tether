import SwiftUI

struct ErrorBanner: View {
    let message: String

    var body: some View {
        Label(message, systemImage: "exclamationmark.circle")
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
            .accessibilityElement(children: .combine)
    }
}
