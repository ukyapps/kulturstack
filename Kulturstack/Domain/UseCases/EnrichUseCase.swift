import Foundation

@MainActor
struct EnrichUseCase {
    let repository: any MediaRepository
    let providers: [any DetailsProvider]

    // Films et séries venus d'une recherche TMDB n'ont ni créateur ni détails : à compléter à l'ouverture de la fiche.
    static func needsEnrichment(_ item: MediaItem) -> Bool {
        switch item.details {
        case let film as FilmDetails:
            return film.runtimeMinutes == nil && film.directors.isEmpty
        case let series as SeriesDetails:
            return series.seasonCount == nil && series.episodeCount == nil
        case nil:
            return item.kind == .film || item.kind == .series
        default:
            return false
        }
    }

    // Meilleur effort : une panne ne remonte pas, la fiche reste telle quelle.
    func enrich(_ item: MediaItem) async -> Bool {
        let keys = item.externalRefs.map(\.key)
        for provider in providers {
            for key in keys {
                guard let enrichment = try? await provider.details(forKey: key) else { continue }
                do {
                    if item.creators.isEmpty { item.creators = enrichment.creators }
                    try item.setDetails(enrichment.details)
                    item.updatedAt = .now
                    try repository.save()
                    return true
                } catch {
                    return false
                }
            }
        }
        return false
    }
}
