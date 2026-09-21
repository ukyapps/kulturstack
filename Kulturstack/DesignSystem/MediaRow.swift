import SwiftUI

struct MediaRow<Accessory: View>: View {
    let coverURL: URL?
    let placeholderSymbol: String
    let title: String
    let subtitle: String
    @ViewBuilder var accessory: () -> Accessory

    init(coverURL: URL?, placeholderSymbol: String, title: String, subtitle: String,
         @ViewBuilder accessory: @escaping () -> Accessory = { EmptyView() }) {
        self.coverURL = coverURL
        self.placeholderSymbol = placeholderSymbol
        self.title = title
        self.subtitle = subtitle
        self.accessory = accessory
    }

    var body: some View {
        HStack(alignment: .center, spacing: Spacing.m) {
            CoverThumbnail(url: coverURL, placeholderSymbol: placeholderSymbol)
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(2)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            accessory()
        }
        .padding(.vertical, Spacing.xs)
        .contentShape(Rectangle())
    }
}

#Preview {
    List {
        MediaRow(coverURL: nil, placeholderSymbol: "film", title: "Dune", subtitle: "Film · 2021 · Denis Villeneuve")
        MediaRow(coverURL: nil, placeholderSymbol: "book.closed", title: "Dune", subtitle: "Livre · 1965 · Frank Herbert") {
            Image(systemName: "heart")
        }
    }
    .listStyle(.plain)
}
