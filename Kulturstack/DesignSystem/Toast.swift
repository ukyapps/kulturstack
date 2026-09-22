import SwiftUI

struct Toast: View {
    struct Action {
        let title: String
        let handler: () -> Void
    }

    let text: String
    var isError = false
    var action: Action? = nil

    var body: some View {
        HStack(spacing: Spacing.s) {
            Image(systemName: isError ? "exclamationmark.circle.fill" : "checkmark.circle.fill")
            Text(text)
                .font(.subheadline.weight(.medium))
                .lineLimit(1)
                .truncationMode(.middle)
            if let action {
                Spacer(minLength: Spacing.s)
                Button(action.title, action: action.handler)
                    .font(.subheadline.weight(.bold))
            }
        }
        .foregroundStyle(Color.white)
        .padding(.horizontal, Spacing.m)
        .padding(.vertical, Spacing.s + Spacing.xs)
        .background(isError ? Color.red : Color.accent, in: RoundedRectangle(cornerRadius: Radius.m))
        .shadow(radius: 4, y: 2)
        .accessibilityElement(children: .contain)
    }
}

#Preview {
    VStack {
        Toast(text: "Loggé ✓")
        Toast(text: "Loggé ✓", action: .init(title: "Modifier") {})
        Toast(text: "Impossible de logger. Réessaie.", isError: true)
    }
}
