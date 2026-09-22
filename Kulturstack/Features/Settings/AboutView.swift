import SwiftUI

struct AboutView: View {
    let versionLine: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.l) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(String(localized: "app.name"))
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(Color.textPrimary)
                    Text(versionLine)
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                    Text(String(localized: "about.tagline"))
                        .font(.body)
                        .foregroundStyle(Color.textSecondary)
                }
                VStack(alignment: .leading, spacing: Spacing.s) {
                    Text(String(localized: "about.sources"))
                        .font(.headline)
                        .foregroundStyle(Color.textPrimary)
                    Image("TMDBLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 20)
                        .accessibilityLabel("TMDB")
                    Text(String(localized: "about.tmdb.notice"))
                        .font(.footnote)
                        .foregroundStyle(Color.textSecondary)
                    Text(String(localized: "about.openlibrary.body"))
                        .font(.footnote)
                        .foregroundStyle(Color.textSecondary)
                        .padding(.top, Spacing.s)
                }
            }
            .padding(Spacing.m)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle(String(localized: "settings.about"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack { AboutView(versionLine: "Kulturstack 1.0 (3)") }
}
