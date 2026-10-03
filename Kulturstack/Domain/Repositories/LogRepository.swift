import Foundation

@MainActor
protocol LogRepository {
    func fetchAll() async throws -> [LogEntry]
    func find(id: UUID) throws -> LogEntry?
    func save() throws
    func delete(_ log: LogEntry) throws
    // Supprimer en lot : une seule écriture. Décocher une saison une coche à la fois, c'était
    // une écriture par épisode — et l'attente qui va avec (founder, 03/10).
    func delete(_ logs: [LogEntry]) throws
}
