import SwiftUI

struct EpisodeRow: View {
    let model: EpisodeRowModel
    let toggle: () -> Void
    let checkUpTo: () -> Void

    var body: some View {
        HStack(spacing: Spacing.s) {
            Button(action: toggle) {
                HStack(spacing: Spacing.s) {
                    Image(systemName: model.isWatched ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(model.isWatched ? Color.accent : Color.textSecondary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(model.label)
                            .font(.subheadline)
                            .foregroundStyle(Color.textPrimary)
                            .multilineTextAlignment(.leading)
                        if let detail = model.detail {
                            Text(detail)
                                .font(.caption)
                                .foregroundStyle(Color.textSecondary)
                        }
                    }
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(model.isWatched ? [.isButton, .isSelected] : .isButton)
            .accessibilityHint(String(localized: "series.episode.hint"))

            // Un geste caché n'existe pas : l'appui long n'avait jamais été trouvé (founder, 27/09).
            // Le bouton ne s'affiche que là où il sert — s'il reste un épisode à combler derrière.
            if model.canCheckUpTo {
                Button(String(localized: "series.checkUpTo.short"), action: checkUpTo)
                    .buttonStyle(.bordered)
                    .font(.caption.weight(.semibold))
                    .accessibilityLabel(String(localized: "series.checkUpTo"))
            }
        }
        .padding(.vertical, Spacing.s)
    }
}

#Preview {
    VStack(alignment: .leading) {
        EpisodeRow(model: EpisodeRowModel(Episode(number: 1, title: "Good News About Hell",
                                                  season: try! Season.make(number: 1, item: MediaItem(kind: .series, title: "Severance")))),
                   toggle: {}, checkUpTo: {})
    }
    .padding()
}
