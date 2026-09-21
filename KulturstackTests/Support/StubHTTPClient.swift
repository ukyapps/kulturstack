import Foundation
import Synchronization
@testable import Kulturstack

final class StubHTTPClient: HTTPClient, Sendable {
    struct Call: Sendable {
        let url: URL
        let headers: [String: String]
    }

    private let result: Result<Data, Error>
    private let recorded = Mutex<[Call]>([])

    init(data: Data) { result = .success(data) }
    init(error: Error) { result = .failure(error) }

    var calls: [Call] { recorded.withLock { $0 } }

    func get(_ url: URL, headers: [String: String]) async throws -> Data {
        recorded.withLock { $0.append(Call(url: url, headers: headers)) }
        return try result.get()
    }
}
