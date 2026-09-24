import SwiftUI

struct EpisodeRow: View {
    let model: EpisodeRowModel
    let toggle: () -> Void
    let checkUpTo: () -> Void

    var body: some View {
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
            .padding(.vertical, Spacing.s)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(String(localized: "series.checkUpTo"), systemImage: "checkmark.circle") { checkUpTo() }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(model.isWatched ? [.isButton, .isSelected] : .isButton)
        .accessibilityHint(String(localized: "series.episode.hint"))
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
