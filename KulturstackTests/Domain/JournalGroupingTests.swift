import Foundation
import SwiftData
import Testing
@testable import Kulturstack

// « Une œuvre = une seule fiche dans le journal » (founder, 30/09). Ces tests tiennent cette
// règle : deux logs de la même œuvre ne font qu'une ligne, celle du plus récent, qui garde
// la note et le commentaire du dernier log qui en portait.
@MainActor
struct JournalGroupingTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Paris")!
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }

    @Test func twoLogsOfTheSameWorkMakeOneRow() throws {
        let container = try ModelContainerFactory.inMemory()
        let context = container.mainContext
        let dune = MediaItem(kind: .film, title: "Dune")
        context.insert(dune)
        let logs = [
            try LogEntry.make(item: dune, status: .done, date: date(2026, 9, 22)),
            try LogEntry.make(item: dune, status: .done, date: date(2026, 3, 1)),
        ]
        for log in logs { context.insert(log) }

        let rows = StatsUseCase.groupByItem(logs.map(JournalRowModel.init))

        #expect(rows.count == 1)
        #expect(rows[0].date == date(2026, 9, 22))
        withExtendedLifetime(container) {}
    }

    @Test func twoDifferentWorksStayTwoRows() throws {
        let container = try ModelContainerFactory.inMemory()
        let context = container.mainContext
        let dune = MediaItem(kind: .film, title: "Dune")
        let severance = MediaItem(kind: .series, title: "Severance")
        for item in [dune, severance] { context.insert(item) }
        let logs = [
            try LogEntry.make(item: dune, status: .done, date: date(2026, 9, 22)),
            try LogEntry.make(item: severance, status: .done, date: date(2026, 9, 21)),
        ]
        for log in logs { context.insert(log) }

        let rows = StatsUseCase.groupByItem(logs.map(JournalRowModel.init))

        #expect(rows.map(\.title) == ["Dune", "Severance"])
        withExtendedLifetime(container) {}
    }

    // Son cas exact : cocher les épisodes écrit un log « en cours » sans note, sa note en
    // écrit un autre. Une ligne, et la note est toujours là.
    @Test func theAutomaticInProgressLogDoesNotSwallowHerRatingAndComment() throws {
        let container = try ModelContainerFactory.inMemory()
        let context = container.mainContext
        let severance = MediaItem(kind: .series, title: "Severance")
        context.insert(severance)
        let rated = try LogEntry.make(item: severance, status: .done, date: date(2026, 9, 20),
                                      rating: 9, note: "Deuxième saison parfaite")
        let automatic = try LogEntry.make(item: severance, status: .inProgress, date: date(2026, 9, 22),
                                          source: WatchStatusUseCase.automaticSource)
        for log in [rated, automatic] { context.insert(log) }

        let rows = StatsUseCase.groupByItem([rated, automatic].map(JournalRowModel.init))

        #expect(rows.count == 1)
        #expect(rows[0].status == .inProgress)
        #expect(rows[0].date == date(2026, 9, 22))
        #expect(rows[0].rating == 9)
        #expect(rows[0].note == "Deuxième saison parfaite")
        withExtendedLifetime(container) {}
    }

    // Deux logs du même jour : c'est l'ordre d'écriture qui tranche, sinon la ligne montrerait
    // n'importe lequel des deux — et c'est précisément le cas qu'elle vit (note puis coche).
    @Test func twoLogsOnTheSameDayAreOrderedByWhenTheyWereWritten() throws {
        let container = try ModelContainerFactory.inMemory()
        let context = container.mainContext
        let severance = MediaItem(kind: .series, title: "Severance")
        context.insert(severance)
        let first = try LogEntry.make(item: severance, status: .done, date: date(2026, 9, 22), rating: 8)
        let second = try LogEntry.make(item: severance, status: .inProgress, date: date(2026, 9, 22))
        first.createdAt = date(2026, 9, 22)
        second.createdAt = date(2026, 9, 22).addingTimeInterval(600)
        for log in [first, second] { context.insert(log) }

        let rows = StatsUseCase.groupByItem([first, second].map(JournalRowModel.init))

        #expect(rows.count == 1)
        #expect(rows[0].status == .inProgress)
        #expect(rows[0].rating == 8)
        withExtendedLifetime(container) {}
    }

    // Un film revu reste un film revu : la ligne le dit, elle ne le cache pas.
    @Test func aRewatchIsCountedOnTheSingleRow() throws {
        let container = try ModelContainerFactory.inMemory()
        let context = container.mainContext
        let dune = MediaItem(kind: .film, title: "Dune")
        let once = MediaItem(kind: .film, title: "Arrival")
        for item in [dune, once] { context.insert(item) }
        let logs = [
            try LogEntry.make(item: dune, status: .done, date: date(2026, 9, 22)),
            try LogEntry.make(item: dune, status: .done, date: date(2026, 3, 1)),
            try LogEntry.make(item: dune, status: .done, date: date(2025, 1, 5)),
            try LogEntry.make(item: once, status: .done, date: date(2026, 9, 21)),
        ]
        for log in logs { context.insert(log) }

        let rows = StatsUseCase.groupByItem(logs.map(JournalRowModel.init))

        #expect(rows.count == 2)
        #expect(rows[0].timesSeen == 3)
        #expect(rows[1].timesSeen == 1)
        withExtendedLifetime(container) {}
    }

    // « En cours » puis « terminé » n'est pas « vu deux fois » : seuls les logs qui disent
    // qu'on l'a consommée comptent.
    @Test func aStatusChangeIsNotASecondViewing() throws {
        let container = try ModelContainerFactory.inMemory()
        let context = container.mainContext
        let severance = MediaItem(kind: .series, title: "Severance")
        context.insert(severance)
        let logs = [
            try LogEntry.make(item: severance, status: .inProgress, date: date(2026, 9, 1)),
            try LogEntry.make(item: severance, status: .done, date: date(2026, 9, 22)),
        ]
        for log in logs { context.insert(log) }

        let rows = StatsUseCase.groupByItem(logs.map(JournalRowModel.init))

        #expect(rows.count == 1)
        #expect(rows[0].timesSeen == 1)
        withExtendedLifetime(container) {}
    }

    // Une fiche supprimée laisse des logs orphelins : ils n'ont pas d'œuvre à partager,
    // donc ils ne se regroupent pas entre eux.
    @Test func orphanLogsAreNeverMergedTogether() throws {
        let container = try ModelContainerFactory.inMemory()
        let context = container.mainContext
        let dune = MediaItem(kind: .film, title: "Dune")
        context.insert(dune)
        let logs = [
            try LogEntry.make(item: dune, status: .done, date: date(2026, 9, 22)),
            try LogEntry.make(item: dune, status: .done, date: date(2026, 9, 21)),
        ]
        for log in logs { context.insert(log) }
        for log in logs { log.item = nil }

        let rows = StatsUseCase.groupByItem(logs.map(JournalRowModel.init))

        #expect(rows.count == 2)
        withExtendedLifetime(container) {}
    }
}
