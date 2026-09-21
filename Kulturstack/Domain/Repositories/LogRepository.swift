import Foundation

@MainActor
protocol LogRepository {
    func fetchAll() async throws -> [LogEntry]
    func find(id: UUID) throws -> LogEntry?
    func save() throws
    func delete(_ log: LogEntry) throws
}
