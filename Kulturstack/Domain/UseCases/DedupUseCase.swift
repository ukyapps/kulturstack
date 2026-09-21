@MainActor
struct DedupUseCase {
    let repository: any MediaRepository

    func existingItem(for candidate: MediaCandidate) throws -> MediaItem? {
        try repository.findItem(withAnyKey: candidate.externalKeys)
    }
}
