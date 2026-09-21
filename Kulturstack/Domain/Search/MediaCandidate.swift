import Foundation

struct MediaCandidate: Identifiable, Sendable {
    let id: String
    let kind: MediaKind
    let title: String
    let originalTitle: String?
    let year: Int?
    let creators: [String]
    let coverURL: URL?
    let summary: String?
    let externalKeys: [String]
    let details: any DetailsPayload
    let providerID: String
}

extension MediaCandidate: Hashable {
    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
