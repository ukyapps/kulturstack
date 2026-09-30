import Foundation

struct InProgressRowModel: Identifiable, Equatable {
    let itemID: UUID
    let kind: MediaKind
    let title: String
    let coverURL: URL?
    let detail: String
    let progress: WatchProgress.Position?
    let next: WatchProgress.Next?

    var id: UUID { itemID }

    init(item: MediaItem) {
        itemID = item.id
        kind = item.kind
        title = item.title
        coverURL = item.coverURL
        let watch = WatchProgress(item: item)
        // Sans épisode vu, il n'y a rien à dire de plus précis que le type de l'œuvre.
        detail = watch?.position?.label ?? item.kind.label
        progress = watch?.position
        next = watch?.next
    }
}
