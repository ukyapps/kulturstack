import Foundation

@MainActor
protocol MediaRepository {
    func findItem(withAnyKey keys: [String]) throws -> MediaItem?
    func find(itemID: UUID) throws -> MediaItem?
    func add(_ item: MediaItem, refs: [ExternalRef]) throws
    func add(_ refs: [ExternalRef], to item: MediaItem) throws
    func add(_ log: LogEntry) throws
    // Écrire en lot : une seule écriture pour toute une saison, ou tout un flux.
    func add(_ logs: [LogEntry]) throws
    // « Je la possède » — l'autre relation à l'œuvre, indépendante des logs (ADR-010).
    func add(_ copy: OwnedCopy) throws
    func delete(_ copies: [OwnedCopy]) throws
    func ownedItems() throws -> [MediaItem]
    // Tout, pour l'export : y compris les œuvres sans aucun log.
    func allItems() throws -> [MediaItem]
    func save() throws
    func deleteAll() throws
}
