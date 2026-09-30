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
        // Un épisode identifié par son flux ne montre pas son rang : il change à chaque
        // publication du podcast, et un rang qui bouge ne veut rien dire.
        label = Self.label(number: episode.number, title: episode.title,
                           isNumbered: episode.externalID == nil)
        detail = Self.detail(airDate: episode.airDate, runtime: episode.runtimeMinutes)
        isWatched = episode.isWatched
        canCheckUpTo = episode.season?.orderedEpisodes
            .contains { $0.number < episode.number && !$0.isWatched } ?? false
    }

    private static func label(number: Int, title: String?, isNumbered: Bool) -> String {
        guard let title, !title.isEmpty else { return String(localized: "series.episode \(number)") }
        return isNumbered ? String(localized: "series.episode.titled \(number) \(title)") : title
    }

    private static func detail(airDate: Date?, runtime: Int?) -> String? {
        let parts = [airDate?.formatted(date: .abbreviated, time: .omitted),
                     runtime.map { String(localized: "series.episode.runtime \($0)") }].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: String(localized: "common.separator"))
    }
}
