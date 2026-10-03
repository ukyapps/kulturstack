import SwiftUI

struct JournalRow: View {
    let model: JournalRowModel
    var onAdvance: (() -> Void)?

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
                // Une œuvre n'a qu'une ligne : c'est ici que se dit ce qu'on aurait lu en
                // comptant les lignes d'avant — « vu 3 fois » plutôt que trois fois la même.
                if model.timesSeen > 1 {
                    Text(String(localized: "journal.row.times \(model.timesSeen)"))
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                }
                if model.status != .done {
                    Text(model.status.label)
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                        .padding(.horizontal, Spacing.s)
                        .padding(.vertical, 2)
                        .background(Color.surfaceSecondary, in: Capsule())
                }
                // Une série suivie dit où elle en est ici aussi : « comme dans en cours » (27/09).
                if let position = model.watch?.position {
                    Text(position.label)
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                    ProgressBar(fraction: position.fraction)
                }
                if let next = model.watch?.next {
                    Text(next.label)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.accent)
                }
                // La date du log est déjà l'en-tête de sa section : la place va au commentaire.
                if let note = model.note {
                    Text(note)
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                        .lineLimit(2)
                }
            }
            Spacer(minLength: 0)
            VStack(alignment: .trailing, spacing: Spacing.s) {
                if let rating = model.rating {
                    StarRating(rating: rating)
                }
                if let next = model.watch?.next, let onAdvance {
                    Button(action: onAdvance) {
                        Image(systemName: "checkmark")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Color.surface)
                            .frame(width: 40, height: 40)
                            .background(Color.accent, in: Circle())
                    }
                    .buttonStyle(.press)
                    .accessibilityLabel(next.label)
                    .accessibilityHint(String(localized: "inprogress.advance.hint"))
                }
            }
        }
        .padding(.vertical, Spacing.xs)
        .contentShape(Rectangle())
    }
}
