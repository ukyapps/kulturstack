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
        context.delete(log)
        try context.save()
    }
}
