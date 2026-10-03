import Foundation
import SwiftData

@MainActor
struct SwiftDataLogRepository: LogRepository {
    let context: ModelContext

    func fetchAll() async throws -> [LogEntry] {
        let descriptor = FetchDescriptor<LogEntry>(
            sortBy: [SortDescriptor(\.date, order: .reverse), SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func find(id: UUID) throws -> LogEntry? {
        var descriptor = FetchDescriptor<LogEntry>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    func save() throws {
        try context.save()
    }

    func delete(_ log: LogEntry) throws {
        try delete([log])
    }

    func delete(_ logs: [LogEntry]) throws {
        guard !logs.isEmpty else { return }
        for log in logs { context.delete(log) }
        try context.save()
    }
}
