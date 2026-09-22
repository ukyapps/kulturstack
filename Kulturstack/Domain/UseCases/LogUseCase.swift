import Foundation

@MainActor
struct LogUseCase {
    let repository: any MediaRepository
    let dedup: DedupUseCase

    @discardableResult
    func logNow(_ candidate: MediaCandidate, status: LogStatus = .done, now: Date = .now) throws -> LogEntry {
        try LogRules.validate(status: status, for: candidate.kind)
        let item = try dedup.existingItem(for: candidate) ?? makeItem(from: candidate)
        try addMissingRefs(of: candidate, to: item)
        let log = try LogEntry.make(item: item, status: status, date: now, source: "manual")
        try repository.add(log)
        return log
    }

    @discardableResult
    func wish(_ candidate: MediaCandidate, now: Date = .now) throws -> LogEntry {
        try logNow(candidate, status: .wishlist, now: now)
    }

    // L'envie reste dans l'historique quand l'œuvre est vue ensuite (ADR-006) : on ajoute, on ne remplace pas.
    @discardableResult
    func wish(_ item: MediaItem, now: Date = .now) throws -> LogEntry {
        let log = try LogEntry.make(item: item, status: .wishlist, date: now, source: "manual")
        try repository.add(log)
        return log
    }

    @discardableResult
    func logAgain(_ item: MediaItem, now: Date = .now) throws -> LogEntry {
        let log = try LogEntry.make(item: item, status: .done, date: now, source: "manual")
        try repository.add(log)
        return log
    }

    private func makeItem(from candidate: MediaCandidate) throws -> MediaItem {
        let item = MediaItem(kind: candidate.kind, title: candidate.title, originalTitle: candidate.originalTitle,
                             year: candidate.year, creators: candidate.creators, summary: candidate.summary,
                             coverURL: candidate.coverURL)
        try item.setDetails(candidate.details)
        try repository.add(item, refs: candidate.externalKeys.compactMap(Self.ref(from:)))
        return item
    }

    private func addMissingRefs(of candidate: MediaCandidate, to item: MediaItem) throws {
        let known = Set(item.externalRefs.map(\.key))
        let missing = candidate.externalKeys.filter { !known.contains($0) }.compactMap(Self.ref(from:))
        guard !missing.isEmpty else { return }
        try repository.add(missing, to: item)
    }

    private static func ref(from key: String) -> ExternalRef? {
        guard let separator = key.firstIndex(of: ":") else { return nil }
        let provider = String(key[..<separator])
        let value = String(key[key.index(after: separator)...])
        guard !provider.isEmpty, !value.isEmpty else { return nil }
        return ExternalRef(provider: provider, value: value)
    }
}
