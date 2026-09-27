import Foundation

struct SearchResultRowModel: Identifiable, Equatable {
    let id: String
    let kind: MediaKind
    let title: String
    let subtitle: String
    let coverURL: URL?
    let lastLoggedAt: Date?
    let loggedLabel: String?

    // Une série ne se logge pas d'un bloc comme un film : le « + » mène à ses épisodes,
    // où elle dit ce qu'elle a vu (retour du 27/09). Logger la série entière reste possible
    // depuis sa fiche, pour une série qu'on ne suit pas épisode par épisode.
    var leadsToEpisodes: Bool { kind.hasEpisodes }

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
