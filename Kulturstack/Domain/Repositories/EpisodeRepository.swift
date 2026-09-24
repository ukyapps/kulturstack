import Foundation

@MainActor
protocol EpisodeRepository {
    func season(ofItem itemID: UUID, number: Int) throws -> Season?
    func add(_ season: Season) throws
    func add(_ episodes: [Episode]) throws
    func save() throws
}
