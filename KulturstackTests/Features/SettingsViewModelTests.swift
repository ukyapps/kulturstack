import Foundation
import SwiftData
import Testing
@testable import Kulturstack

@MainActor
struct SettingsViewModelTests {
    @Test func wipeErasesEverythingAndReportsSuccess() throws {
        let container = try ModelContainerFactory.inMemory()
        let context = container.mainContext
        try DemoSeed(context: context).fill()
        let viewModel = SettingsViewModel(wipe: WipeUseCase(repository: SwiftDataMediaRepository(context: context)),
                                          version: "1.0", build: "3")

        #expect(viewModel.wipeAll())

        #expect(try context.fetchCount(FetchDescriptor<LogEntry>()) == 0)
        #expect(viewModel.didFailToWipe == false)
    }

    @Test func aWipeFailureIsReported() {
        let viewModel = SettingsViewModel(wipe: WipeUseCase(repository: FailingMediaRepository()), version: "1.0", build: "3")

        #expect(viewModel.wipeAll() == false)

        #expect(viewModel.didFailToWipe)
    }

    @Test func versionLineNamesVersionAndBuild() {
        let viewModel = SettingsViewModel(wipe: WipeUseCase(repository: FailingMediaRepository()), version: "1.0", build: "3")
        #expect(viewModel.versionLine.contains("1.0"))
        #expect(viewModel.versionLine.contains("3"))
    }
}

