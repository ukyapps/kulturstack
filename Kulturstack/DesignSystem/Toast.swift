import SwiftUI

struct Toast: View {
    let text: String
    var isError = false

    var body: some View {
        HStack(spacing: Spacing.s) {
            Image(systemName: isError ? "exclamationmark.circle.fill" : "checkmark.circle.fill")
            Text(text)
                .font(.subheadline.weight(.medium))
                .lineLimit(2)
        }
        .foregroundStyle(Color.white)
        .padding(.horizontal, Spacing.m)
        .padding(.vertical, Spacing.s + Spacing.xs)
        .background(isError ? Color.red : Color.accent, in: RoundedRectangle(cornerRadius: Radius.m))
        .shadow(radius: 4, y: 2)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    VStack {
        Toast(text: "Dune loggé ✓")
        Toast(text: "Impossible de logger Dune", isError: true)
    }
}
