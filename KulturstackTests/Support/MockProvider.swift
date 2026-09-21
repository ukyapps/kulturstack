import Foundation
import Synchronization
@testable import Kulturstack

final class MockProvider: MetadataProvider, Sendable {
    let id: String
    let supportedKinds: Set<MediaKind>
    private let delay: Duration
    private let result: Result<[MediaCandidate], Error>
    private let state = Mutex<(calls: [String], cancelled: Bool)>(([], false))

    init(id: String, kinds: Set<MediaKind>, delay: Duration = .zero, result: Result<[MediaCandidate], Error>) {
        self.id = id
        self.supportedKinds = kinds
        self.delay = delay
        self.result = result
    }

    var calls: [String] { state.withLock { $0.calls } }
    var wasCancelled: Bool { state.withLock { $0.cancelled } }

    func search(_ query: String) async throws -> [MediaCandidate] {
        state.withLock { $0.calls.append(query) }
        do {
            try await Task.sleep(for: delay)
        } catch {
            state.withLock { $0.cancelled = true }
            throw error
        }
        return try result.get()
    }

    static func candidate(_ id: String, kind: MediaKind = .film, title: String = "Titre") -> MediaCandidate {
        MediaCandidate(id: id, kind: kind, title: title, originalTitle: nil, year: nil, creators: [], coverURL: nil,
                       summary: nil, externalKeys: [id], details: FilmDetails(), providerID: "mock")
    }
}
