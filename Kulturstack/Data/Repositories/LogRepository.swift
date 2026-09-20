@MainActor
protocol LogRepository {
    func fetchAll() async throws -> [LogEntry]
}
