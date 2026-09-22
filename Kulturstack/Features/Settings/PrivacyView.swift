import SwiftUI

struct PrivacyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.l) {
                paragraph(title: String(localized: "privacy.leaves.title"), body: String(localized: "privacy.leaves.body"))
                paragraph(title: String(localized: "privacy.stays.title"), body: String(localized: "privacy.stays.body"))
            }
            .padding(Spacing.m)
        }
        .navigationTitle(String(localized: "settings.privacy"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func paragraph(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.textPrimary)
            Text(body)
                .font(.body)
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    NavigationStack { PrivacyView() }
}
