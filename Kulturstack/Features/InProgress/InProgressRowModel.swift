import Foundation

struct InProgressRowModel: Identifiable, Equatable {
    struct Next: Equatable {
        let season: Int
        let number: Int
        let label: String
    }

    // La barre dit la même chose que la ligne — « S2 · E4 sur 10 » —, mais elle se remplit
    // sous le pouce : c'est ce qui manquait pour voir qu'on avait bien appuyé (founder, 27/09).
    struct Progress: Equatable {
        let position: Int
        let total: Int

        var fraction: Double { total > 0 ? Double(position) / Double(total) : 0 }
    }

    let itemID: UUID
    let kind: MediaKind
    let title: String
    let coverURL: URL?
    let detail: String
    let progress: Progress?
    let next: Next?

    var id: UUID { itemID }

    init(item: MediaItem) {
        itemID = item.id
        kind = item.kind
        title = item.title
        coverURL = item.coverURL
        // Sans épisode vu, il n'y a rien à dire de plus précis que le type de l'œuvre.
        let watched = InProgressUseCase.lastWatched(of: item)
        detail = watched.flatMap(Self.progress) ?? item.kind.label
        progress = watched.flatMap(Self.bar)
        next = InProgressUseCase.next(for: item).map {
            Next(season: $0.season?.number ?? 0, number: $0.number,
                 label: String(localized: "inprogress.next \($0.number)"))
        }
    }

    private static func progress(_ episode: Episode) -> String? {
        guard let season = episode.season else { return nil }
        return String(localized: "inprogress.progress \(season.number) \(episode.number) \(season.episodes.count)")
    }

    private static func bar(_ episode: Episode) -> Progress? {
        guard let season = episode.season, !season.episodes.isEmpty else { return nil }
        return Progress(position: episode.number, total: season.episodes.count)
    }
}
