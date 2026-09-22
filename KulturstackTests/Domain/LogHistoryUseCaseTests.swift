import Foundation
import SwiftData
import Testing
@testable import Kulturstack

@MainActor
struct LogHistoryUseCaseTests {
    private let dune = MockProvider.candidate("tmdb:movie:438631", kind: .film, title: "Dune")

    private func make() throws -> (ModelContainer, LogUseCase, LogHistoryUseCase) {
        let container = try ModelContainerFactory.inMemory()
        let repository = SwiftDataMediaRepository(context: container.mainContext)
        let dedup = DedupUseCase(repository: repository)
        return (container, LogUseCase(repository: repository, dedup: dedup), LogHistoryUseCase(dedup: dedup))
    }

    @Test func aCandidateNeverLoggedHasNoDate() throws {
        let (container, _, history) = try make()
        #expect(try history.lastLogDate(for: dune) == nil)
        withExtendedLifetime(container) {}
    }

    @Test func theMostRecentLogDateIsReturned() throws {
        let (container, useCase, history) = try make()
        let old = Date.now.addingTimeInterval(-86_400 * 30)
        let recent = Date.now.addingTimeInterval(-86_400)
        try useCase.logNow(dune, now: recent)
        try useCase.logNow(dune, now: old)

        #expect(try history.lastLogDate(for: dune) == recent)
        withExtendedLifetime(container) {}
    }

    @Test func aWishIsNotAConsumption() throws {
        let (container, useCase, history) = try make()
        try useCase.logNow(dune, status: .wishlist)

        #expect(try history.lastLogDate(for: dune) == nil)
        withExtendedLifetime(container) {}
    }
}
