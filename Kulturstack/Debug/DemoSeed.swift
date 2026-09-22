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
                let date = Calendar.current.date(byAdding: .day, value: -log.daysAgo, to: now) ?? now
                context.insert(try LogEntry.make(item: item, status: log.status, date: date,
                                                 rating: log.rating, note: log.note, source: "demo"))
            }
        }
        try context.save()
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
              refs: [("tmdb", "tv:95396")], logs: [Log(daysAgo: 330, rating: 8), Log(daysAgo: 3, status: .inProgress)]),
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
    ]
}
#endif
