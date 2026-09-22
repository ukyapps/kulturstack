import Foundation
import SwiftData

@MainActor
struct SwiftDataMediaRepository: MediaRepository {
    let context: ModelContext

    func findItem(withAnyKey keys: [String]) throws -> MediaItem? {
        guard !keys.isEmpty else { return nil }
        var descriptor = FetchDescriptor<ExternalRef>(predicate: #Predicate { keys.contains($0.key) })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first?.item
    }

    func find(itemID: UUID) throws -> MediaItem? {
        var descriptor = FetchDescriptor<MediaItem>(predicate: #Predicate { $0.id == itemID })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    func add(_ item: MediaItem, refs: [ExternalRef]) throws {
        context.insert(item)
        for ref in refs {
            ref.item = item
            context.insert(ref)
        }
        try context.save()
    }

    func add(_ refs: [ExternalRef], to item: MediaItem) throws {
        for ref in refs {
            ref.item = item
            context.insert(ref)
        }
        try context.save()
    }

    func add(_ log: LogEntry) throws {
        context.insert(log)
        try context.save()
    }

    func save() throws {
        try context.save()
    }
}
