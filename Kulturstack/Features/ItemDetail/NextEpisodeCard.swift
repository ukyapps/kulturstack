import SwiftUI

// « Je veux une option qui dit à quel épisode j'en suis, genre en haut, et j'appuie dessus et
// ça dit que j'ai vu cet épisode » (founder, 27/09). La carte entière est le bouton.
struct NextEpisodeCard: View {
    let next: SeriesEpisodesViewModel.Next
    var kind: MediaKind = .series
    let check: () -> Void

    var body: some View {
        Button(action: check) {
            HStack(spacing: Spacing.m) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(String(localized: "series.next.title"))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.textSecondary)
                        .textCase(.uppercase)
                    Text(label)
                        .font(.body.weight(.medium))
                        .foregroundStyle(Color.textPrimary)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
                Image(systemName: "checkmark")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.surface)
                    .frame(width: 32, height: 32)
                    .background(Color.accent, in: Circle())
            }
            .padding(Spacing.m)
            .background(Color.surfaceSecondary, in: RoundedRectangle(cornerRadius: Radius.m))
            .contentShape(Rectangle())
        }
        .buttonStyle(.press)
        // Cocher depuis la fiche se sent comme cocher depuis « En cours » : même geste, même retour.
        .sensoryFeedback(.success, trigger: next)
        .accessibilityLabel(label)
        .accessibilityHint(String(localized: "series.next.hint"))
    }

    // Une série se repère à sa position — « S2 · E5 ». Un podcast se repère à son titre :
    // sa position change à chaque publication, elle ne veut rien dire.
    private var label: String {
        guard kind.showsSeasons else {
            return next.title ?? String(localized: "series.episode \(next.number)")
        }
        let position = String(localized: "series.next \(next.season) \(next.number)")
        guard let title = next.title else { return position }
        return position + String(localized: "common.separator") + title
    }
}

#Preview {
    VStack {
        NextEpisodeCard(next: .init(season: 2, number: 5, title: "Woe’s Hollow"), check: {})
        NextEpisodeCard(next: .init(season: 1, number: 1, title: nil), check: {})
    }
    .padding()
}
