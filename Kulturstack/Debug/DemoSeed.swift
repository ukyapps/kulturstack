#if DEBUG
import Foundation
import SwiftData

@MainActor
struct DemoSeed {
    let context: ModelContext
    var now: Date = .now

    func fill() throws {
        try wipe()
        for entry in Self.catalog {
            let item = MediaItem(kind: entry.kind, title: entry.title, originalTitle: entry.originalTitle,
                                 year: entry.year, creators: entry.creators, coverURL: entry.cover.flatMap(URL.init))
            context.insert(item)
            for (provider, value) in entry.refs {
                context.insert(ExternalRef(provider: provider, value: value, item: item))
            }
            for log in entry.logs {
                context.insert(try LogEntry.make(item: item, status: log.status, date: date(daysAgo: log.daysAgo),
                                                 rating: log.rating, note: log.note, source: "demo"))
            }
            try fill(entry.seasons, of: item)
        }
        try context.save()
    }

    // Les saisons et les épisodes sont du cache de source : ici on les pose à la main, puisque
    // le seed ne va pas sur Internet. Cocher un épisode reste un log qui porte son œuvre.
    private func fill(_ plans: [SeasonPlan], of item: MediaItem) throws {
        for plan in plans {
            let season = try Season.make(number: plan.number, title: plan.title, item: item)
            context.insert(season)
            for plannedEpisode in plan.episodes {
                let episode = Episode(number: plannedEpisode.number, title: plannedEpisode.title,
                                      airDate: plannedEpisode.airedDaysAgo.map(date(daysAgo:)),
                                      runtimeMinutes: plannedEpisode.runtimeMinutes,
                                      externalID: plannedEpisode.externalID, season: season)
                context.insert(episode)
                guard let watched = plannedEpisode.watchedDaysAgo else { continue }
                context.insert(try LogEntry.make(item: item, status: .done, date: date(daysAgo: watched),
                                                 source: "demo", episode: episode))
            }
        }
    }

    private func date(daysAgo days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -days, to: now) ?? now
    }

    func wipe() throws {
        try WipeUseCase(repository: SwiftDataMediaRepository(context: context)).wipe()
    }

    private struct Entry {
        let kind: MediaKind
        let title: String
        var originalTitle: String? = nil
        let year: Int
        let creators: [String]
        var cover: String? = nil
        var refs: [(String, String)] = []
        let logs: [Log]
        var seasons: [SeasonPlan] = []
    }

    private struct SeasonPlan {
        let number: Int
        var title: String? = nil
        let episodes: [PlannedEpisode]
    }

    private struct PlannedEpisode {
        let number: Int
        let title: String
        var airedDaysAgo: Int? = nil
        var runtimeMinutes: Int? = nil
        // Les épisodes de podcast portent l'identité de leur flux ; ceux des séries, rien.
        var externalID: String? = nil
        var watchedDaysAgo: Int? = nil
    }

    private struct Log {
        let daysAgo: Int
        var status: LogStatus = .done
        var rating: Int? = nil
        var note: String? = nil
    }

    private static let tmdb = "https://image.tmdb.org/t/p/w342"
    private static let openLibrary = "https://covers.openlibrary.org/b/isbn"

    private static let catalog: [Entry] = [
        Entry(kind: .film, title: "Dune", year: 2021, creators: ["Denis Villeneuve"],
              cover: "\(tmdb)/d5NXSklXo0qyIYkgV94XAgMIckC.jpg", refs: [("tmdb", "movie:438631")],
              logs: [Log(daysAgo: 300, rating: 9), Log(daysAgo: 40, rating: 9, note: "Revu avant la suite.")]),
        Entry(kind: .film, title: "Dune : deuxième partie", originalTitle: "Dune: Part Two", year: 2024,
              creators: ["Denis Villeneuve"], cover: "\(tmdb)/8b8R8l88Qje9dn9OE8PY05Nxl1X.jpg",
              refs: [("tmdb", "movie:693134")], logs: [Log(daysAgo: 38, rating: 9, note: "Vu en IMAX.")]),
        Entry(kind: .film, title: "Oppenheimer", year: 2023, creators: ["Christopher Nolan"],
              cover: "\(tmdb)/8Gxv8gSFCU0XGDykEGv7zR1n2ua.jpg", refs: [("tmdb", "movie:872585")],
              logs: [Log(daysAgo: 200, rating: 8)]),
        Entry(kind: .film, title: "Parasite", originalTitle: "기생충", year: 2019, creators: ["Bong Joon-ho"],
              cover: "\(tmdb)/7IiTTgloJzvGI1TAYymCfbfl3vT.jpg", refs: [("tmdb", "movie:496243")],
              logs: [Log(daysAgo: 150, rating: 10)]),
        Entry(kind: .film, title: "Everything Everywhere All at Once", year: 2022,
              creators: ["Daniel Kwan", "Daniel Scheinert"], cover: "\(tmdb)/w3LxiVYdWWRvEVdn5RYq6jIqkb1.jpg",
              refs: [("tmdb", "movie:545611")], logs: [Log(daysAgo: 90, rating: 7)]),
        Entry(kind: .film, title: "Anatomie d'une chute", year: 2023, creators: ["Justine Triet"],
              cover: "\(tmdb)/kQs6keheMwCxJxrzV83VUwFtHkB.jpg", refs: [("tmdb", "movie:915935")],
              logs: [Log(daysAgo: 12, rating: 8, note: "Le chien mérite un César.")]),
        Entry(kind: .film, title: "Past Lives", year: 2023, creators: ["Celine Song"],
              cover: "\(tmdb)/k3waqVXSnvCZWfJYNtdamTgTtTA.jpg", refs: [("tmdb", "movie:666277")],
              logs: [Log(daysAgo: 5, status: .wishlist)]),
        Entry(kind: .film, title: "Portrait de la jeune fille en feu", year: 2019, creators: ["Céline Sciamma"],
              refs: [("tmdb", "movie:531428")], logs: [Log(daysAgo: 250, rating: 9)]),
        Entry(kind: .series, title: "Severance", year: 2022, creators: ["Dan Erickson"],
              refs: [("tmdb", "tv:95396")], logs: [Log(daysAgo: 330, rating: 8), Log(daysAgo: 3, status: .inProgress)],
              // Saison 1 finie, saison 2 commencée : c'est ce qui remplit « En cours » et la
              // carte « prochain épisode » — ici, S2 E4.
              seasons: [SeasonPlan(number: 1, episodes: severanceSeason1),
                        SeasonPlan(number: 2, episodes: severanceSeason2)]),
        Entry(kind: .series, title: "Succession", year: 2018, creators: ["Jesse Armstrong"],
              cover: "\(tmdb)/7HW47XbkNQ5fiwQFYGWdw9gs144.jpg", refs: [("tmdb", "tv:76331")],
              logs: [Log(daysAgo: 120, rating: 9)]),
        Entry(kind: .series, title: "Fleabag", year: 2016, creators: ["Phoebe Waller-Bridge"],
              cover: "\(tmdb)/27vEYsRKa3eAniwmoccOoluEXQ1.jpg", refs: [("tmdb", "tv:67070")],
              logs: [Log(daysAgo: 1, rating: 10, note: "Deux saisons parfaites.")]),
        Entry(kind: .series, title: "Shōgun", year: 2024, creators: ["Rachel Kondo", "Justin Marks"],
              cover: "\(tmdb)/7O4iVfOMQmdCSxhOg1WnzG1AgYT.jpg", refs: [("tmdb", "tv:126308")],
              logs: [Log(daysAgo: 60, status: .dropped)]),
        Entry(kind: .series, title: "The Bear", year: 2022, creators: ["Christopher Storer"],
              refs: [("tmdb", "tv:136315")], logs: [Log(daysAgo: 20, status: .wishlist)]),
        Entry(kind: .book, title: "Dune", year: 1965, creators: ["Frank Herbert"],
              cover: "\(openLibrary)/9780441172719-M.jpg", refs: [("isbn13", "9780441172719")],
              logs: [Log(daysAgo: 320, rating: 9)]),
        Entry(kind: .book, title: "Le Messie de Dune", originalTitle: "Dune Messiah", year: 1969,
              creators: ["Frank Herbert"], cover: "\(openLibrary)/9780441172696-M.jpg",
              refs: [("isbn13", "9780441172696")], logs: [Log(daysAgo: 0, rating: 7)]),
        Entry(kind: .book, title: "L'Étranger", year: 1942, creators: ["Albert Camus"],
              cover: "\(openLibrary)/9782070360024-M.jpg", refs: [("isbn13", "9782070360024")],
              logs: [Log(daysAgo: 180, rating: 8)]),
        Entry(kind: .book, title: "Kafka sur le rivage", originalTitle: "海辺のカフカ", year: 2002,
              creators: ["Haruki Murakami"], cover: "\(openLibrary)/9781400079278-M.jpg",
              refs: [("isbn13", "9781400079278")], logs: [Log(daysAgo: 100, rating: 8)]),
        Entry(kind: .book, title: "Sapiens", year: 2011, creators: ["Yuval Noah Harari"],
              cover: "\(openLibrary)/9780062316097-M.jpg", refs: [("isbn13", "9780062316097")],
              logs: [Log(daysAgo: 70, status: .dropped, note: "Lâché au chapitre 6.")]),
        Entry(kind: .book, title: "La Main gauche de la nuit", originalTitle: "The Left Hand of Darkness",
              year: 1969, creators: ["Ursula K. Le Guin"], cover: "\(openLibrary)/9780441478125-M.jpg",
              refs: [("isbn13", "9780441478125")], logs: [Log(daysAgo: 8, status: .inProgress)]),
        Entry(kind: .book, title: "Piranesi", year: 2020, creators: ["Susanna Clarke"],
              cover: "\(openLibrary)/9781635575637-M.jpg", refs: [("isbn13", "9781635575637")],
              logs: [Log(daysAgo: 45, rating: 9, note: "Lu d'une traite.")]),
        Entry(kind: .book, title: "Normal People", year: 2018, creators: ["Sally Rooney"],
              cover: "\(openLibrary)/9780571334650-M.jpg", refs: [("isbn13", "9780571334650")],
              logs: [Log(daysAgo: 210, rating: 6)]),
        Entry(kind: .book, title: "Les Années", year: 2008, creators: ["Annie Ernaux"],
              cover: "\(openLibrary)/9782070402472-M.jpg", refs: [("isbn13", "9782070402472")],
              logs: [Log(daysAgo: 30, rating: 8)]),
        Entry(kind: .book, title: "Chanson douce", year: 2016, creators: ["Leïla Slimani"],
              cover: "\(openLibrary)/9782070196678-M.jpg", refs: [("isbn13", "9782070196678")],
              logs: [Log(daysAgo: 15, rating: 7)]),
        // Le podcast du seed : sans lui, « Remplir données démo » ne montre ni la liste
        // d'épisodes à plat, ni les années repliables, ni le compteur « Podcasts » du Journal.
        Entry(kind: .podcast, title: "Le code a changé", year: 2020, creators: ["France Inter"],
              refs: [("itunes", "1498344139")],
              logs: [Log(daysAgo: 2, status: .inProgress)],
              // Une seule saison, invisible à l'écran : un podcast est une liste à plat, que
              // la fiche range par année. Deux années, donc, pour que ça se voie.
              seasons: [SeasonPlan(number: 1, episodes: podcastEpisodes)]),
    ]

    // Severance saison 1 : vue en entier, il y a un an.
    private static let severanceSeason1: [PlannedEpisode] = [
        "Good News About Hell", "Half Loop", "In Perpetuity", "The You You Are", "The Grim Barbarity of Optics and Design",
        "Hide and Seek", "Defiant Jazz", "What's for Dinner?", "The We We Are",
    ].enumerated().map { index, title in
        PlannedEpisode(number: index + 1, title: title, airedDaysAgo: 400 - index * 7,
                       runtimeMinutes: 45 + index % 7, watchedDaysAgo: 340 - index * 2)
    }

    // Saison 2 : trois épisodes vus, la suite attend. Le quatrième est « le prochain ».
    private static let severanceSeason2: [PlannedEpisode] = [
        "Hello, Ms. Cobel", "Goodbye, Mrs. Selvig", "Who Is Alive?", "Woe's Hollow", "Trojan's Horse",
        "Attila", "Chikhai Bardo", "Sweet Vitriol", "The After Hours", "Cold Harbor",
    ].enumerated().map { index, title in
        PlannedEpisode(number: index + 1, title: title, airedDaysAgo: 120 - index * 7,
                       runtimeMinutes: 48 + index % 9, watchedDaysAgo: index < 3 ? 12 - index * 3 : nil)
    }

    // Huit épisodes sur deux ans, du plus ancien au plus récent, trois écoutés. Les identités
    // imitent les `guid` d'un vrai flux : c'est par elles que les coches tiennent.
    private static let podcastEpisodes: [PlannedEpisode] = [
        ("Le Français qui a vu naître Google", 500), ("Les vaches aussi innovent", 430),
        ("Les chevaux s'expriment du bout des lèvres", 400), ("Ce que font les animaux sans nous", 370),
        ("Et si nous vivions dans une simulation", 300), ("Ce qu'on gagne à interroger notre réalité", 120),
        ("La tech a-t-elle un genre ?", 60), ("Bande annonce de la nouvelle saison", 9),
    ].enumerated().map { index, episode in
        PlannedEpisode(number: index + 1, title: episode.0, airedDaysAgo: episode.1,
                       runtimeMinutes: 16 + index % 5, externalID: "demo-guid-\(index + 1)",
                       watchedDaysAgo: index < 3 ? 20 - index * 6 : nil)
    }
}
#endif
