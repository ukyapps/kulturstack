import Foundation
import SwiftData

@MainActor
struct SwiftDataEpisodeRepository: EpisodeRepository {
    let context: ModelContext

    func season(ofItem itemID: UUID, number: Int) throws -> Season? {
        let key = Season.key(itemID: itemID, number: number)
        var descriptor = FetchDescriptor<Season>(predicate: #Predicate { $0.key == key })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    func add(_ season: Season) throws {
        context.insert(season)
        try context.save()
    }

    func add(_ episodes: [Episode]) throws {
        for episode in episodes { context.insert(episode) }
        try context.save()
    }

    func save() throws {
        try context.save()
    }
}
