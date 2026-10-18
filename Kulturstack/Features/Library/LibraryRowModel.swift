import Foundation

struct LibraryRowModel: Identifiable, Equatable {
    let id: UUID
    let kind: MediaKind
    let title: String
    let subtitle: String
    let coverURL: URL?

    init(item: MediaItem) {
        id = item.id
        kind = item.kind
        title = item.title
        coverURL = item.coverURL
        let parts = [kind.label, item.year.map(String.init), item.creators.first].compactMap { $0 }
        subtitle = parts.joined(separator: String(localized: "common.separator"))
    }
}
