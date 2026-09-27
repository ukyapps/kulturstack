import Foundation

struct EpisodeRowModel: Identifiable, Equatable {
    let number: Int
    let label: String
    let detail: String?
    let isWatched: Bool
    // « Tout cocher jusqu'ici » n'a de sens que s'il reste quelque chose à combler derrière —
    // ailleurs, le bouton serait du bruit. Un appui long ne se trouve pas (founder, 27/09).
    let canCheckUpTo: Bool

    var id: Int { number }

    init(_ episode: Episode) {
        number = episode.number
        label = episode.title.map { String(localized: "series.episode.titled \(episode.number) \($0)") }
            ?? String(localized: "series.episode \(episode.number)")
        detail = Self.detail(airDate: episode.airDate, runtime: episode.runtimeMinutes)
        isWatched = episode.isWatched
        canCheckUpTo = episode.season?.orderedEpisodes
            .contains { $0.number < episode.number && !$0.isWatched } ?? false
    }

    private static func detail(airDate: Date?, runtime: Int?) -> String? {
        let parts = [airDate?.formatted(date: .abbreviated, time: .omitted),
                     runtime.map { String(localized: "series.episode.runtime \($0)") }].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: String(localized: "common.separator"))
    }
}
