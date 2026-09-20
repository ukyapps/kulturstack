import SwiftUI

struct EmptyState: View {
    struct Action {
        let title: String
        let handler: () -> Void
    }

    let icon: String
    let title: String
    let message: String
    var action: Action? = nil

    var body: some View {
        VStack(spacing: Spacing.m) {
            Image(systemName: icon)
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(Color.textSecondary)
                .accessibilityHidden(true)
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.textPrimary)
            Text(message)
                .font(.body)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
            if let action {
                Button(action.title, action: action.handler)
                    .buttonStyle(.borderedProminent)
                    .padding(.top, Spacing.s)
            }
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }
}

#Preview("Sans action") {
    EmptyState(icon: "books.vertical", title: "Rien ici", message: "Un message dans le ton.")
}

#Preview("Avec action") {
    EmptyState(icon: "magnifyingglass", title: "Rien ici", message: "Un message dans le ton.",
               action: .init(title: "Chercher") {})
}
