import Foundation

struct ItemDetailModel: Equatable {
    let id: UUID
    let kind: MediaKind
    let title: String
    let year: Int?
    let headline: String
    let facts: [String]
    let summary: String?
    let coverURL: URL?
    let logs: [ItemLogRowModel]
    let source: String?

    private static let maxSubjects = 3
    // Les sources qu'on interroge d'abord, les clés secondaires (IMDb, Trakt…) ensuite.
    private static let providerNames = [("tmdb", "TMDB"), ("ol", "OpenLibrary"), ("isbn13", "OpenLibrary"), ("imdb", "IMDb"), ("trakt", "Trakt")]

    init(item: MediaItem) {
        let details = item.details
        id = item.id
        kind = item.kind
        title = item.title
        year = item.year
        summary = item.summary
        coverURL = item.coverURL
        headline = Self.headline(kind: item.kind, runtime: (details as? FilmDetails)?.runtimeMinutes, creator: item.creators.first)
        facts = Self.facts(for: details)
        logs = item.logs
            .sorted { ($0.date, $0.createdAt) > ($1.date, $1.createdAt) }
            .map(ItemLogRowModel.init)
        source = Self.source(of: item.externalRefs)
    }

    private static func headline(kind: MediaKind, runtime: Int?, creator: String?) -> String {
        let parts = [kind.label, runtime.map(runtimeLabel), creator].compactMap { $0 }
        return parts.joined(separator: String(localized: "common.separator"))
    }

    private static func runtimeLabel(_ minutes: Int) -> String {
        String(localized: "detail.runtime \(String(minutes / 60)) \(String(format: "%02d", minutes % 60))")
    }

    private static func facts(for details: (any DetailsPayload)?) -> [String] {
        switch details {
        case let film as FilmDetails:
            return [list(film.genres)].compactMap { $0 }
        case let series as SeriesDetails:
            let counts = [series.seasonCount.map { String(localized: "detail.seasons \($0)") },
                          series.episodeCount.map { String(localized: "detail.episodes \($0)") }].compactMap { $0 }
            let countLine = counts.isEmpty ? nil : counts.joined(separator: String(localized: "common.separator"))
            return [countLine, list(series.genres)].compactMap { $0 }
        case let book as BookDetails:
            return [book.pageCount.map { String(localized: "detail.pages \($0)") }, book.publisher, list(book.subjects)]
                .compactMap { $0 }
        default:
            return []
        }
    }

    private static func list(_ values: [String]) -> String? {
        values.isEmpty ? nil : values.prefix(maxSubjects).joined(separator: ", ")
    }

    private static func source(of refs: [ExternalRef]) -> String? {
        let providers = Set(refs.map(\.provider))
        let known = providerNames.filter { providers.contains($0.0) }.map(\.1)
        let unknown = providers.filter { provider in !providerNames.contains { $0.0 == provider } }.sorted()
        var names: [String] = []
        for name in known + unknown where !names.contains(name) { names.append(name) }
        return names.isEmpty ? nil : names.joined(separator: ", ")
    }
}
