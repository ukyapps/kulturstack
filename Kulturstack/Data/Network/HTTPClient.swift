import Foundation

protocol HTTPClient: Sendable {
    func get(_ url: URL, headers: [String: String]) async throws -> Data
}

enum HTTPError: Error, Equatable {
    case notHTTP
    case status(Int)
}
