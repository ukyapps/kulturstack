import SwiftUI

struct ItemLogRow: View {
    let model: ItemLogRowModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.s) {
                Text(model.date, format: .dateTime.day().month().year())
                    .foregroundStyle(Color.textPrimary)
                if model.status != .done {
                    Text(model.status.label)
                        .font(.caption)
                        .padding(.horizontal, Spacing.s)
                        .padding(.vertical, 2)
                        .background(Color.surfaceSecondary, in: Capsule())
                }
                Spacer()
                if let rating = model.rating {
                    StarRating(rating: rating)
                }
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
            }
            if let note = model.note {
                Text(note)
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, Spacing.s)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityHint(String(localized: "detail.log.hint"))
    }
}
