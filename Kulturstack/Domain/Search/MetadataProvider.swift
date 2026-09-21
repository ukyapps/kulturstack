protocol MetadataProvider: Sendable {
    var id: String { get }
    var supportedKinds: Set<MediaKind> { get }
    func search(_ query: String) async throws -> [MediaCandidate]
}
