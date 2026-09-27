import Foundation
import SwiftData
import Testing
@testable import Kulturstack

struct SchemaMigrationTests {
    // T-01 : la base de la founder contient ses vrais logs depuis le 23/09. Une migration
    // ne se teste pas à vide — on écrit un store V1 peuplé, puis on le rouvre avec le plan.
    @Test @MainActor func storeCreatedWithV1SurvivesReopeningWithCurrentPlan() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("migration-\(UUID().uuidString).store")
        defer { try? FileManager.default.removeItem(at: url) }

        do {
            let v1 = try ModelContainer(
                for: Schema(versionedSchema: KulturstackSchemaV1.self),
                configurations: ModelConfiguration(url: url)
            )
            let dune = KulturstackSchemaV1.MediaItem(kind: .film, title: "Dune")
            let severance = KulturstackSchemaV1.MediaItem(kind: .series, title: "Severance")
            v1.mainContext.insert(dune)
            v1.mainContext.insert(severance)
            v1.mainContext.insert(KulturstackSchemaV1.ExternalRef(provider: "tmdb", value: "movie:438631", item: dune))
            v1.mainContext.insert(KulturstackSchemaV1.LogEntry(item: dune, status: .done, rating: 9, note: "Enfin vu."))
            v1.mainContext.insert(KulturstackSchemaV1.LogEntry(item: severance, status: .inProgress))
            try v1.mainContext.save()
        }

        let current = try ModelContainerFactory.onDisk(url: url)
        let items = try current.mainContext.fetch(FetchDescriptor<MediaItem>(sortBy: [SortDescriptor(\.title)]))
        let logs = try current.mainContext.fetch(FetchDescriptor<LogEntry>())
        let refs = try current.mainContext.fetch(FetchDescriptor<ExternalRef>())

        #expect(items.map(\.title) == ["Dune", "Severance"])
        #expect(refs.first?.key == "tmdb:movie:438631")
        #expect(refs.first?.item?.title == "Dune")
        #expect(logs.count == 2)
        #expect(logs.first(where: { $0.rating == 9 })?.note == "Enfin vu.")
        #expect(logs.contains { $0.status == .inProgress })
        // Le champ ajouté par la V2 existe et ne casse rien : il est simplement vide.
        #expect(logs.allSatisfy { $0.episode == nil })
        #expect(try current.mainContext.fetchCount(FetchDescriptor<Season>()) == 0)
        #expect(try current.mainContext.fetchCount(FetchDescriptor<Episode>()) == 0)
    }

    // T-01, deuxième étage : la base de la founder est en V2 depuis le 24/09, avec ses
    // épisodes cochés. C'est celle-là qui migrera sur son téléphone, pas une base vide.
    @Test @MainActor func storeCreatedWithV2KeepsItsCheckedEpisodes() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("migration-v2-\(UUID().uuidString).store")
        defer { try? FileManager.default.removeItem(at: url) }
        let severanceID = UUID()

        do {
            let v2 = try ModelContainer(
                for: Schema(versionedSchema: KulturstackSchemaV2.self),
                configurations: ModelConfiguration(url: url)
            )
            let context = v2.mainContext
            let severance = KulturstackSchemaV2.MediaItem(kind: .series, title: "Severance")
            severance.id = severanceID
            context.insert(severance)
            context.insert(KulturstackSchemaV2.ExternalRef(provider: "tmdb", value: "tv:95396", item: severance))
            let season = KulturstackSchemaV2.Season(key: "\(severanceID.uuidString):s2", number: 2, item: severance)
            context.insert(season)
            var episodes: [KulturstackSchemaV2.Episode] = []
            for number in 1...3 {
                let episode = KulturstackSchemaV2.Episode(key: "\(season.key):e\(number)", number: number,
                                                          title: "Épisode \(number)", season: season)
                context.insert(episode)
                episodes.append(episode)
            }
            context.insert(KulturstackSchemaV2.LogEntry(item: severance, status: .done, episode: episodes[0]))
            context.insert(KulturstackSchemaV2.LogEntry(item: severance, status: .done, episode: episodes[1]))
            context.insert(KulturstackSchemaV2.LogEntry(item: severance, status: .inProgress, source: "episodes"))
            try context.save()
        }

        let current = try ModelContainerFactory.onDisk(url: url)
        let context = current.mainContext
        let item = try #require(try context.fetch(FetchDescriptor<MediaItem>()).first)
        let episodes = try context.fetch(FetchDescriptor<Episode>(sortBy: [SortDescriptor(\.number)]))
        let logs = try context.fetch(FetchDescriptor<LogEntry>())

        #expect(item.title == "Severance")
        #expect(episodes.map(\.number) == [1, 2, 3])
        #expect(episodes.map(\.title) == ["Épisode 1", "Épisode 2", "Épisode 3"])
        // Ce qui était coché l'est toujours : c'est tout l'enjeu de cette migration.
        #expect(episodes.map(\.isWatched) == [true, true, false])
        #expect(logs.count == 3)
        #expect(logs.contains { $0.status == .inProgress && $0.episode == nil })
        // Le champ ajouté par la V3 existe et ne casse rien : il est simplement vide.
        #expect(episodes.allSatisfy { $0.externalID == nil })
        // Et les clés n'ont pas bougé : une clé réécrite, c'est une coche perdue.
        #expect(episodes.first?.key == "\(severanceID.uuidString):s2:e1")
    }

    @Test func currentSchemaIsTheLastOfThePlan() {
        #expect(KulturstackMigrationPlan.schemas.count == 3)
        #expect(KulturstackMigrationPlan.schemas.last == KulturstackMigrationPlan.current)
        #expect(KulturstackMigrationPlan.current.versionIdentifier == KulturstackSchemaV3.versionIdentifier)
        #expect(KulturstackMigrationPlan.stages.count == 2)
    }

    // MARK: - L'identité d'un épisode de podcast (tranche Podcasts, PR 30)

    @Test @MainActor func aPodcastEpisodeIsIdentifiedByItsFeedIdentifier() throws {
        let container = try ModelContainerFactory.inMemory()
        let context = container.mainContext
        let podcast = MediaItem(kind: .podcast, title: "Le code a changé")
        context.insert(podcast)
        let season = try Season.make(number: 1, item: podcast)
        context.insert(season)
        let episode = Episode(number: 1, title: "Un épisode", externalID: "guid-abc", season: season)
        context.insert(episode)
        try context.save()

        #expect(episode.key == "\(season.key):gguid-abc")
        #expect(episode.externalID == "guid-abc")
        withExtendedLifetime(container) {}
    }

    // Le flux publie trois épisodes de plus : les positions se décalent, pas les identités.
    // Sans ça, une coche posée sur « épisode 1 » atterrirait sur un autre épisode.
    @Test @MainActor func aCheckedPodcastEpisodeSurvivesTheFeedMovingOn() throws {
        let container = try ModelContainerFactory.inMemory()
        let context = container.mainContext
        let podcast = MediaItem(kind: .podcast, title: "Le code a changé")
        context.insert(podcast)
        let season = try Season.make(number: 1, item: podcast)
        context.insert(season)
        let listened = Episode(number: 1, title: "Le plus récent", externalID: "guid-abc", season: season)
        context.insert(listened)
        context.insert(try LogEntry.make(item: podcast, status: .done, episode: listened))
        try context.save()

        // Le même épisode, redescendu en quatrième position après trois publications.
        let sameEpisode = Episode(number: 4, title: "Le plus récent", externalID: "guid-abc", season: season)

        #expect(sameEpisode.key == listened.key)
        #expect(listened.isWatched)
        withExtendedLifetime(container) {}
    }

    @Test @MainActor func twoEpisodesOfTheSameSeasonCannotShareAnIdentifier() throws {
        let container = try ModelContainerFactory.inMemory()
        let context = container.mainContext
        let podcast = MediaItem(kind: .podcast, title: "Le code a changé")
        context.insert(podcast)
        let season = try Season.make(number: 1, item: podcast)
        context.insert(season)
        context.insert(Episode(number: 1, externalID: "guid-abc", season: season))
        context.insert(Episode(number: 2, externalID: "guid-abc", season: season))
        try context.save()

        // Même mécanique que la clé d'ExternalRef : le doublon est écrasé, pas ajouté.
        let episodes = try context.fetch(FetchDescriptor<Episode>())
        #expect(episodes.count == 1)
        #expect(episodes.first?.externalID == "guid-abc")
        withExtendedLifetime(container) {}
    }

    // Un épisode de série garde la clé qu'il avait en V2 : sinon la migration perdrait les coches.
    @Test @MainActor func aSeriesEpisodeKeepsItsNumberedKey() throws {
        let container = try ModelContainerFactory.inMemory()
        let context = container.mainContext
        let series = MediaItem(kind: .series, title: "Severance")
        context.insert(series)
        let season = try Season.make(number: 2, item: series)
        context.insert(season)
        let episode = Episode(number: 5, season: season)

        #expect(episode.key == "\(season.key):e5")
        #expect(episode.externalID == nil)
        withExtendedLifetime(container) {}
    }

    @Test @MainActor func externalRefKeyIsUnique() throws {
        let container = try ModelContainerFactory.inMemory()
        let context = container.mainContext
        let dune = MediaItem(kind: .film, title: "Dune")
        let other = MediaItem(kind: .film, title: "Autre")
        context.insert(dune)
        context.insert(other)
        context.insert(ExternalRef(provider: "tmdb", value: "movie:438631", item: dune))
        context.insert(ExternalRef(provider: "tmdb", value: "movie:438631", item: other))
        try context.save()

        let refs = try context.fetch(FetchDescriptor<ExternalRef>())
        #expect(refs.count == 1)
        #expect(refs.first?.key == "tmdb:movie:438631")
    }
}
