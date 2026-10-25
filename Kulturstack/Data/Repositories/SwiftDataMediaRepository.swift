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
        try add([log])
    }

    func add(_ logs: [LogEntry]) throws {
        guard !logs.isEmpty else { return }
        for log in logs { context.insert(log) }
        try context.save()
    }

    func add(_ copy: OwnedCopy) throws {
        context.insert(copy)
        try context.save()
    }

    func delete(_ copies: [OwnedCopy]) throws {
        guard !copies.isEmpty else { return }
        for copy in copies { context.delete(copy) }
        try context.save()
    }

    // Une œuvre possédée en deux exemplaires reste une ligne : c'est l'œuvre qu'on range,
    // pas le pressage.
    func ownedItems() throws -> [MediaItem] {
        var seen = Set<UUID>()
        return try context.fetch(FetchDescriptor<OwnedCopy>())
            .compactMap(\.item)
            .filter { seen.insert($0.id).inserted }
            .sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
    }

    func allItems() throws -> [MediaItem] {
        try context.fetch(FetchDescriptor<MediaItem>())
    }

    func save() throws {
        try context.save()
    }

    // Pas de delete(model:) en masse : les relations obligatoires le font échouer. Objet par objet, logs d'abord.
    func deleteAll() throws {
        for copy in try context.fetch(FetchDescriptor<OwnedCopy>()) { context.delete(copy) }
        for log in try context.fetch(FetchDescriptor<LogEntry>()) { context.delete(log) }
        for ref in try context.fetch(FetchDescriptor<ExternalRef>()) { context.delete(ref) }
        for episode in try context.fetch(FetchDescriptor<Episode>()) { context.delete(episode) }
        for season in try context.fetch(FetchDescriptor<Season>()) { context.delete(season) }
        for item in try context.fetch(FetchDescriptor<MediaItem>()) { context.delete(item) }
        try context.save()
    }
}
