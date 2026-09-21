import SwiftUI

struct SectionHeader: View {
    let title: String
    var isLoading = false

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.textSecondary)
                .textCase(.uppercase)
            Spacer()
            if isLoading {
                ProgressView().controlSize(.small)
            }
        }
        .padding(.horizontal, Spacing.m)
        .padding(.vertical, Spacing.s)
    }
}

#Preview {
    VStack {
        SectionHeader(title: "Films & séries")
        SectionHeader(title: "Livres", isLoading: true)
    }
}
