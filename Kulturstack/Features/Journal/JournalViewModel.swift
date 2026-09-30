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
    var didFailToAdvance = false
    private let repository: any LogRepository
    private let editUseCase: EditLogUseCase
    // Le Journal ne sait avancer une série que si on lui en donne le moyen : les écrans de
    // test qui ne s'en servent pas ne le fournissent pas, et le bouton ne s'affiche alors pas.
    private let advanceUseCase: AdvanceUseCase?
    private let now: () -> Date
    private let calendar: Calendar

    init(repository: any LogRepository, advance: AdvanceUseCase? = nil,
         now: @escaping () -> Date = { .now }, calendar: Calendar = .current) {
        self.repository = repository
        self.advanceUseCase = advance
        self.now = now
        self.calendar = calendar
        editUseCase = EditLogUseCase(repository: repository)
    }

    var canAdvance: Bool { advanceUseCase != nil }

    // Le même ✓ que dans « En cours », sur la ligne de la série : même use case, mêmes règles.
    func advance(_ row: JournalRowModel) async {
        guard let advanceUseCase, let itemID = row.itemID else { return }
        do {
            try await advanceUseCase.advance(itemID: itemID)
            didFailToAdvance = false
        } catch {
            didFailToAdvance = true
        }
        await load()
    }

    // Vide (rien consommé — les envies vivent dans leur onglet) ≠ edge (filtre sans résultat) ≠ erreur.
    var presentation: Presentation {
        switch state {
        case .loading: return .loading
        case .empty: return .empty
        case .failed: return .failed
        case .loaded(let rows):
            let now = now()
            // Filtrer d'abord, regrouper ensuite : une œuvre appartient à la période de son
            // log le plus récent, pas à celle de son premier.
            let kept = StatsUseCase.groupByItem(
                StatsUseCase.filter(rows, period: period, kind: selectedKind, now: now, calendar: calendar))
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
