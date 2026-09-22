import SwiftData

// Les services composés une fois sur le contexte de l'app et injectés aux écrans par initializer.
@MainActor
struct AppServices {
    let logRepository: any LogRepository
    let mediaRepository: any MediaRepository
    let logUseCase: LogUseCase
    let editUseCase: EditLogUseCase
    let logHistory: LogHistoryUseCase

    init(context: ModelContext) {
        let logRepository = SwiftDataLogRepository(context: context)
        let mediaRepository = SwiftDataMediaRepository(context: context)
        let dedup = DedupUseCase(repository: mediaRepository)
        self.logRepository = logRepository
        self.mediaRepository = mediaRepository
        logUseCase = LogUseCase(repository: mediaRepository, dedup: dedup)
        editUseCase = EditLogUseCase(repository: logRepository)
        logHistory = LogHistoryUseCase(dedup: dedup)
    }
}
