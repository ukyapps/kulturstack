import Foundation
import Synchronization
@testable import Kulturstack

final class StubHTTPClient: HTTPClient, Sendable {
    struct Call: Sendable {
        let url: URL
        let headers: [String: String]
    }

    private let respond: @Sendable (URL) -> Result<Data, Error>
    private let recorded = Mutex<[Call]>([])

    init(data: Data) { respond = { _ in .success(data) } }
    init(error: Error) { respond = { _ in .failure(error) } }

    // Une réponse par route, reconnue à un morceau de chemin : « search/multi », « combined_credits »…
    init(routes: [String: Result<Data, Error>]) {
        respond = { url in
            routes.first { url.path().contains($0.key) }?.value ?? .failure(HTTPError.status(404))
        }
    }

    var calls: [Call] { recorded.withLock { $0 } }

    func get(_ url: URL, headers: [String: String]) async throws -> Data {
        recorded.withLock { $0.append(Call(url: url, headers: headers)) }
        return try respond(url).get()
    }
}
