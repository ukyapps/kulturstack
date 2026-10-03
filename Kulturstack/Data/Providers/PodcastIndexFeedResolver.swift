import CryptoKit
import Foundation

// Le flux d'un podcast de Radio France que sa page ne déclare pas. Podcast Index est un index
// ouvert des flux ; mesuré le 03/10 sur les 25 podcasts que la page laissait sans épisodes,
// il en rend 22 (ADR-015).
//
// Sa correspondance « par identifiant Apple » est trop incomplète pour s'en servir — 1 sur 4
// testés, et les flux de Radio France y portent `itunesId: 0`. On passe donc par la recherche
// par titre, ce qui oblige à un appariement **strict** : sinon « L'instant pour Soi », dont
// l'auteur s'appelle « L'instant M », se retrouverait sur la fiche de l'émission de France Inter.
struct PodcastIndexFeedResolver: Sendable {
    static let searchURL = URL(string: "https://api.podcastindex.org/api/1.0/search/byterm")!
    // Cette source ne sert qu'à Radio France : un flux hébergé ailleurs n'est jamais retenu.
    // C'est ce qui borne les dégâts d'un mauvais appariement.
    static let feedHost = "radiofrance-podcast.net"

    private let credentials: (key: String, secret: String)?
    private let client: any HTTPClient
    private let userAgent: String

    init(secrets: any SecretsProviding, client: any HTTPClient, userAgent: String) {
        self.client = client
        self.userAgent = userAgent
        // Sans clé, cette source se tait : l'app marche, les podcasts dont la page donne le
        // flux continuent, et on n'appelle pas une API qui nous rejettera.
        if let key = try? secrets.value(for: .podcastIndexKey),
           let secret = try? secrets.value(for: .podcastIndexSecret) {
            credentials = (key, secret)
        } else {
            credentials = nil
        }
    }

    func feedURL(title: String, publisher: String?) async throws -> URL? {
        guard let credentials, let publisher else { return nil }
        var components = URLComponents(url: Self.searchURL, resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "q", value: title), URLQueryItem(name: "max", value: "20")]
        let date = String(Int(Date.now.timeIntervalSince1970))
        let data = try await client.get(components.url!, headers: [
            "X-Auth-Key": credentials.key,
            "X-Auth-Date": date,
            "Authorization": Self.signature(key: credentials.key, secret: credentials.secret, date: date),
            // Ils refusent les User-Agent génériques : « Sample code UA strings […] are not allowed ».
            "User-Agent": userAgent,
            "Accept": "application/json",
        ])
        let feeds = (try? JSONDecoder().decode(PodcastIndexSearchResponse.self, from: data).feeds) ?? []
        return Self.best(of: feeds, title: title, publisher: publisher)?.url
    }

    // Podcast Index signe chaque appel par le SHA-1 de la clé, du secret et de l'heure Unix.
    static func signature(key: String, secret: String, date: String) -> String {
        Insecure.SHA1.hash(data: Data((key + secret + date).utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }

    // Le titre **et** le producteur doivent concorder, et le flux être celui de Radio France.
    // Entre deux entrées du même podcast — l'index en garde de vieilles —, celle qui a le plus
    // d'épisodes, puis la plus récemment vue.
    private static func best(of feeds: [PodcastIndexFeed], title: String, publisher: String) -> PodcastIndexFeed? {
        feeds
            .filter { $0.dead == 0 && $0.url?.host()?.hasSuffix(feedHost) == true }
            .filter { compare($0.title, title) && compare($0.author, publisher) }
            .max { ($0.episodeCount ?? 0, $0.lastUpdateTime ?? 0) < ($1.episodeCount ?? 0, $1.lastUpdateTime ?? 0) }
    }

    // Apple et l'index n'écrivent pas pareil : « Ecoutez, révisez ! » contre « Écoutez,
    // révisez ! », l'apostrophe droite contre la courbe. Ne restent que les lettres et les
    // chiffres, sans accent.
    private static func compare(_ one: String?, _ other: String) -> Bool {
        guard let one, !one.isEmpty else { return false }
        return folded(one) == folded(other)
    }

    private static func folded(_ text: String) -> String {
        let plain = text.folding(options: [.diacriticInsensitive, .widthInsensitive],
                                locale: Locale(identifier: "fr_FR")).lowercased()
        return String(plain.filter { $0.isLetter || $0.isNumber })
    }
}
