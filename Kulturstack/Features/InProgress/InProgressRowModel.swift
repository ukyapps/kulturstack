import Foundation

struct InProgressRowModel: Identifiable, Equatable {
    struct Next: Equatable {
        let season: Int
        let number: Int
        let label: String
    }

    let itemID: UUID
    let kind: MediaKind
    let title: String
    let coverURL: URL?
    let detail: String
    let next: Next?

    var id: UUID { itemID }

    init(item: MediaItem) {
        itemID = item.id
        kind = item.kind
        title = item.title
        coverURL = item.coverURL
        // Sans épisode vu, il n'y a rien à dire de plus précis que le type de l'œuvre.
        detail = InProgressUseCase.lastWatched(of: item).flatMap(Self.progress) ?? item.kind.label
        next = InProgressUseCase.next(for: item).map {
            Next(season: $0.season?.number ?? 0, number: $0.number,
                 label: String(localized: "inprogress.next \($0.number)"))
        }
    }

    private static func progress(_ episode: Episode) -> String? {
        guard let season = episode.season else { return nil }
        return String(localized: "inprogress.progress \(season.number) \(episode.number) \(season.episodes.count)")
    }
}
