import SwiftUI

struct Chip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .padding(.horizontal, Spacing.m)
                .padding(.vertical, Spacing.s)
                .background(isSelected ? Color.accent : Color.surfaceSecondary, in: Capsule())
                .foregroundStyle(isSelected ? Color.white : Color.textPrimary)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    HStack {
        Chip(title: "Tous", isSelected: true) {}
        Chip(title: "Films", isSelected: false) {}
    }
}
