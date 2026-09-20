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
}
