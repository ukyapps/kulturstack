import Foundation
import Observation

@MainActor @Observable
final class JournalViewModel {
    enum State: Equatable {
        case loading
        case empty
        case loaded([JournalRowModel])
        case failed
    }

    enum Presentation: Equatable {
        case loading
        case empty
        case failed
        case edge(period: Period, kind: MediaKind?)
        case loaded(JournalContent)
    }

    private(set) var state: State = .loading
    var period: Period = .all
    var selectedKind: MediaKind?
    var didFailToDelete = false
    private let repository: any LogRepository
    private let editUseCase: EditLogUseCase
    private let now: () -> Date
    private let calendar: Calendar

    init(repository: any LogRepository, now: @escaping () -> Date = { .now }, calendar: Calendar = .current) {
        self.repository = repository
        self.now = now
        self.calendar = calendar
        editUseCase = EditLogUseCase(repository: repository)
    }

    // Vide (rien consommé — les envies vivent dans leur onglet) ≠ edge (filtre sans résultat) ≠ erreur.
    var presentation: Presentation {
        switch state {
        case .loading: return .loading
        case .empty: return .empty
        case .failed: return .failed
        case .loaded(let rows):
            let now = now()
            let kept = StatsUseCase.filter(rows, period: period, kind: selectedKind, now: now, calendar: calendar)
            guard !kept.isEmpty else {
                return rows.allSatisfy({ $0.status == .wishlist }) ? .empty : .edge(period: period, kind: selectedKind)
            }
            return .loaded(JournalContent(sections: StatsUseCase.groupByDay(kept, now: now, calendar: calendar), total: kept.count))
        }
    }

    // Les chips restent visibles en edge : c'est par eux qu'on en sort. Un type jamais loggé n'a pas de chip.
    var kindCounts: [JournalContent.KindCount] {
        guard case .loaded(let rows) = state else { return [] }
        let counts = StatsUseCase.count(rows, period: period, now: now(), calendar: calendar)
        return MediaKind.allCases
            .filter { kind in rows.contains { $0.kind == kind } }
            .map { JournalContent.KindCount(kind: $0, count: counts.byKind[$0] ?? 0) }
    }

    func showAll() {
        period = .all
        selectedKind = nil
    }

    func load() async {
        do {
            // Un épisode coché n'est pas une ligne de journal : une saison suivie en ferait dix
            // identiques. C'est le statut de l'œuvre qui s'y montre, une seule fois.
            let logs = try await repository.fetchAll().filter { $0.episode == nil }
            state = logs.isEmpty ? .empty : .loaded(logs.map(JournalRowModel.init))
        } catch {
            state = .failed
        }
    }

    func delete(id: UUID) async {
        do {
            guard let log = try editUseCase.log(id: id) else { return }
            try editUseCase.delete(log)
            await load()
        } catch {
            didFailToDelete = true
        }
    }
}
