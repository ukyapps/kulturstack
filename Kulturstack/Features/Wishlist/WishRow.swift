import SwiftUI

struct WishRow: View {
    let model: JournalRowModel
    let onSeen: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: Spacing.m) {
            CoverThumbnail(url: model.coverURL, placeholderSymbol: model.symbol)
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(model.title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(2)
                Text(model.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
                Text(String(localized: "wishlist.added \(model.date.formatted(.dateTime.day().month()))"))
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
            }
            Spacer(minLength: 0)
            Button(model.kind.seenActionLabel, action: onSeen)
                .buttonStyle(.borderedProminent)
                .font(.subheadline.weight(.semibold))
        }
        .padding(.vertical, Spacing.xs)
        .contentShape(Rectangle())
    }
}
