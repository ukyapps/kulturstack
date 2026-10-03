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
    func save() throws
    func deleteAll() throws
}
