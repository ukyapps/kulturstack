import Foundation
import Observation

@MainActor @Observable
final class SearchViewModel {
    enum Presentation: Equatable {
        case idle
        case sections([SearchSection])
        case noResults(query: String)
        case noResultsForKind(MediaKind)
    }

    struct Toast: Equatable {
        let title: String
        let isError: Bool
        var logID: UUID? = nil
    }

    static let minimumQueryLength = 2

    var query = "" {
        didSet { queryChanged() }
    }
    var selectedKind: MediaKind?
    private(set) var sections: [SearchSection] = []
    private(set) var toast: Toast?
    private var loggedDates: [String: Date] = [:]

    let availableKinds: [MediaKind]
    private let useCase: SearchUseCase
    private let logNow: (MediaCandidate) throws -> UUID
    private let lastLogDate: (MediaCandidate) throws -> Date?
    private let debounce: Duration
    private let toastDuration: Duration
    private var debounceTask: Task<Void, Never>?
    private var searchTask: Task<Void, Never>?
    private var toastTask: Task<Void, Never>?
    private var activeQuery = ""

    init(useCase: SearchUseCase, logNow: @escaping (MediaCandidate) throws -> UUID,
         lastLogDate: @escaping (MediaCandidate) throws -> Date? = { _ in nil },
         debounce: Duration = .milliseconds(300), toastDuration: Duration = .seconds(4)) {
        self.useCase = useCase
        self.logNow = logNow
        self.lastLogDate = lastLogDate
        self.debounce = debounce
        self.toastDuration = toastDuration
        availableKinds = MediaKind.allCases.filter { useCase.families.contains($0.searchFamily) }
    }

    func row(for candidate: MediaCandidate) -> SearchResultRowModel {
        SearchResultRowModel(candidate: candidate, lastLoggedAt: loggedDates[candidate.id])
    }

    func log(_ candidate: MediaCandidate) {
        do {
            let logID = try logNow(candidate)
            loggedDates[candidate.id] = .now
            show(Toast(title: String(localized: "search.toast.logged \(candidate.title)"), isError: false, logID: logID))
        } catch {
            show(Toast(title: String(localized: "search.toast.failed \(candidate.title)"), isError: true))
        }
    }

    private func show(_ newToast: Toast) {
        toastTask?.cancel()
        toast = newToast
        toastTask = Task {
            try? await Task.sleep(for: toastDuration)
            guard !Task.isCancelled else { return }
            toast = nil
        }
    }

    var presentation: Presentation {
        guard !sections.isEmpty else { return .idle }
        guard let selectedKind else {
            let settled = sections.allSatisfy { $0.state != .loading }
            let allEmpty = sections.allSatisfy { $0.state == .empty }
            return settled && allEmpty ? .noResults(query: activeQuery) : .sections(sections)
        }
        let filtered = sections.compactMap { Self.filter($0, kind: selectedKind) }
        let stillLoading = filtered.contains { $0.state == .loading }
        let anyLoaded = filtered.contains { if case .loaded = $0.state { true } else { false } }
        return anyLoaded || stillLoading ? .sections(filtered) : .noResultsForKind(selectedKind)
    }

    func retry(_ family: SearchFamily) {
        run(useCase.retry(activeQuery, family: family))
    }

    private var trimmedQuery: String { query.trimmingCharacters(in: .whitespacesAndNewlines) }

    private func queryChanged() {
        debounceTask?.cancel()
        let text = trimmedQuery
        guard text.count >= Self.minimumQueryLength else {
            searchTask?.cancel()
            sections = []
            activeQuery = ""
            return
        }
        debounceTask = Task {
            try? await Task.sleep(for: debounce)
            guard !Task.isCancelled else { return }
            activeQuery = text
            sections = []
            run(useCase.search(text))
        }
    }

    private func run(_ stream: AsyncStream<SearchSection>) {
        searchTask?.cancel()
        searchTask = Task {
            for await section in stream {
                guard !Task.isCancelled else { return }
                upsert(section)
            }
        }
    }

    // Une lecture de la base qui rate ne doit pas faire tomber la recherche : la ligne perd juste son « Vu le … ».
    private func rememberLogDates(of section: SearchSection) {
        guard case .loaded(let candidates) = section.state else { return }
        for candidate in candidates {
            loggedDates[candidate.id] = (try? lastLogDate(candidate)) ?? nil
        }
    }

    private func upsert(_ section: SearchSection) {
        rememberLogDates(of: section)
        if let index = sections.firstIndex(where: { $0.family == section.family }) {
            sections[index] = section
        } else {
            sections.append(section)
            sections.sort { Self.order($0.family) < Self.order($1.family) }
        }
    }

    private static func order(_ family: SearchFamily) -> Int {
        SearchFamily.allCases.firstIndex(of: family) ?? .max
    }

    // Une section dont la famille ne contient pas le type filtré disparaît ; les autres gardent
    // leur état, seuls leurs candidats sont filtrés.
    private static func filter(_ section: SearchSection, kind: MediaKind) -> SearchSection? {
        guard kind.searchFamily == section.family else { return nil }
        guard case .loaded(let candidates) = section.state else { return section }
        let kept = candidates.filter { $0.kind == kind }
        return kept.isEmpty ? nil : SearchSection(family: section.family, state: .loaded(kept))
    }
}
