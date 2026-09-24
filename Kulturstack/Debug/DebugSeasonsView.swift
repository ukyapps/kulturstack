#if DEBUG
import SwiftUI

// Démo de la PR 13 : montre qu'une série se découpe, et qu'une saison n'est chargée
// qu'au dépliement — jamais les dix d'un coup.
struct DebugSeasonsView: View {
    let title: String
    let key: String
    let provider: any EpisodeProvider

    @State private var seasons: [SeasonSummary] = []
    @State private var episodes: [Int: [EpisodeSummary]] = [:]
    @State private var expanded: Set<Int> = []
    @State private var failure: String?
    @State private var isLoading = true

    var body: some View {
        content
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .task { await loadSeasons() }
    }

    @ViewBuilder private var content: some View {
        if isLoading {
            ProgressView()
        } else if let failure {
            VStack(spacing: Spacing.s) {
                Text(String(localized: "debug.seasons.failed"))
                Text(failure).font(.caption).foregroundStyle(Color.textSecondary)
                Button(String(localized: "common.retry")) { Task { await loadSeasons() } }
            }
            .padding(Spacing.m)
        } else if seasons.isEmpty {
            EmptyState(
                icon: "rectangle.stack",
                title: String(localized: "debug.seasons.empty.title"),
                message: String(localized: "debug.seasons.empty.message")
            )
        } else {
            List(seasons) { season in
                DisclosureGroup(isExpanded: binding(for: season.number)) {
                    episodeRows(season)
                } label: {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(season.title ?? String(localized: "debug.seasons.season \(season.number)"))
                        Text(String(localized: "debug.seasons.count \(season.episodeCount)"))
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)
                    }
                }
            }
        }
    }

    @ViewBuilder private func episodeRows(_ season: SeasonSummary) -> some View {
        if let loaded = episodes[season.number] {
            if loaded.isEmpty {
                Text(String(localized: "debug.seasons.no.episode")).font(.caption).foregroundStyle(Color.textSecondary)
            } else {
                ForEach(loaded) { episode in
                    Text(episode.title.map { "\(episode.number) · \($0)" }
                        ?? String(localized: "debug.seasons.episode \(episode.number)"))
                        .font(.caption.monospaced())
                }
            }
        } else {
            ProgressView().task { await loadEpisodes(of: season.number) }
        }
    }

    private func binding(for number: Int) -> Binding<Bool> {
        Binding(
            get: { expanded.contains(number) },
            set: { isOpen in
                if isOpen { expanded.insert(number) } else { expanded.remove(number) }
            }
        )
    }

    private func loadSeasons() async {
        isLoading = true
        failure = nil
        do {
            seasons = try await provider.seasons(forKey: key)
        } catch {
            failure = error.localizedDescription
        }
        isLoading = false
    }

    private func loadEpisodes(of number: Int) async {
        episodes[number] = (try? await provider.episodes(forKey: key, season: number)) ?? []
    }
}
#endif
