import SwiftUI

struct JournalRow: View {
    let model: JournalRowModel

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.m) {
            CoverThumbnail(url: model.coverURL, placeholderSymbol: model.symbol)
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(model.title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(2)
                Text(model.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
                HStack(spacing: Spacing.s) {
                    Text(model.date, format: .dateTime.day().month().year())
                    if model.status != .done {
                        Text(model.status.label)
                            .padding(.horizontal, Spacing.s)
                            .padding(.vertical, 2)
                            .background(Color.surfaceSecondary, in: Capsule())
                    }
                }
                .font(.caption)
                .foregroundStyle(Color.textSecondary)
            }
            Spacer(minLength: 0)
            if let rating = model.rating {
                StarRating(rating: rating)
            }
        }
        .padding(.vertical, Spacing.xs)
    }
}
