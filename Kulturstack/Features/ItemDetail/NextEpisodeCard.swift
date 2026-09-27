import SwiftUI

// « Je veux une option qui dit à quel épisode j'en suis, genre en haut, et j'appuie dessus et
// ça dit que j'ai vu cet épisode » (founder, 27/09). La carte entière est le bouton.
struct NextEpisodeCard: View {
    let next: SeriesEpisodesViewModel.Next
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
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityHint(String(localized: "series.next.hint"))
    }

    private var label: String {
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
