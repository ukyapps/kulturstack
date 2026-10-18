import SwiftUI

struct LibraryRow: View {
    let model: LibraryRowModel

    var body: some View {
        HStack(spacing: Spacing.m) {
            CoverThumbnail(url: model.coverURL, placeholderSymbol: model.kind.symbol, width: 44)
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(model.title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(Color.textPrimary)
                Text(model.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, Spacing.xs)
        // Toute la ligne ouvre la fiche, pas seulement l'image ou le titre (retour du 27/09).
        .contentShape(Rectangle())
    }
}
