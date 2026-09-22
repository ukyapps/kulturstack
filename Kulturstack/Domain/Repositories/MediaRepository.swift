import Foundation

@MainActor
protocol MediaRepository {
    func findItem(withAnyKey keys: [String]) throws -> MediaItem?
    func find(itemID: UUID) throws -> MediaItem?
    func add(_ item: MediaItem, refs: [ExternalRef]) throws
    func add(_ refs: [ExternalRef], to item: MediaItem) throws
    func add(_ log: LogEntry) throws
}
