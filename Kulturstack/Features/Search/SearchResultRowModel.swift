import Foundation

struct SearchResultRowModel: Identifiable, Equatable {
    let id: String
    let kind: MediaKind
    let title: String
    let subtitle: String
    let coverURL: URL?
    let lastLoggedAt: Date?
    let loggedLabel: String?

    init(candidate: MediaCandidate, lastLoggedAt: Date? = nil) {
        id = candidate.id
        kind = candidate.kind
        title = candidate.title
        coverURL = candidate.coverURL
        let parts = [candidate.kind.label, candidate.year.map(String.init), candidate.creators.first].compactMap { $0 }
        subtitle = parts.joined(separator: String(localized: "common.separator"))
        self.lastLoggedAt = lastLoggedAt
        loggedLabel = lastLoggedAt.map { candidate.kind.loggedLabel(on: $0) }
    }
}
