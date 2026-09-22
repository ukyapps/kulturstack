import Foundation

@MainActor
struct LogHistoryUseCase {
    let dedup: DedupUseCase

    // Une envie n'est pas une consommation : elle ne compte pas comme « vu le … ».
    func lastLogDate(for candidate: MediaCandidate) throws -> Date? {
        try dedup.existingItem(for: candidate)?.logs
            .filter { $0.status != .wishlist }
            .map(\.date)
            .max()
    }
}
