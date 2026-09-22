// Ce qu'une source sait ajouter à une fiche après coup (la recherche ne donne pas tout).
struct MediaEnrichment: Sendable {
    let creators: [String]
    let details: any DetailsPayload
}

protocol DetailsProvider: Sendable {
    // nil = cette clé n'est pas de ma forme ; une erreur = j'ai essayé et raté.
    func details(forKey key: String) async throws -> MediaEnrichment?
}
