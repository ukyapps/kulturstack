import Foundation

// Apple ne publie pas le flux RSS des podcasts de Radio France — mesuré le 27/09 sur dix
// podcasts de France Inter et France Culture, dix sans `feedUrl`, ni par la recherche ni par
// `lookup`. Leur page sur radiofrance.fr, elle, le déclare : c'est la balise `<link
// rel="alternate">` que lit n'importe quel lecteur de podcasts. Reste à retrouver la page, et
// son adresse se déduit du titre et de la station. Mesuré le 03/10 sur les 24 premiers
// résultats de « france inter » et « france culture » : 23 pages retrouvées, 21 du premier
// coup (ADR-014).
enum RadioFrancePage {
    // Chaque essai est une page de 450 Ko. Aucun des 23 podcasts retrouvés n'a demandé plus
    // de trois adresses ; au-delà, c'est du trafic pour rien.
    static let maxAttempts = 3

    private struct Station {
        let appleName: String
        let path: String
    }

    // Le nom est celui que rend `artistName` chez Apple ; le chemin est celui de radiofrance.fr.
    // ICI (ex-France Bleu) n'est pas là : ses podcasts vivent sur ici.fr, avec un autre
    // découpage — aucune de ses pages n'existe sur radiofrance.fr (mesuré le 03/10).
    private static let stations = [
        Station(appleName: "France Inter", path: "franceinter"),
        Station(appleName: "France Culture", path: "franceculture"),
        Station(appleName: "franceinfo", path: "franceinfo"),
        Station(appleName: "France Musique", path: "francemusique"),
        Station(appleName: "FIP", path: "fip"),
        Station(appleName: "Mouv'", path: "mouv"),
    ]

    private static let articles = ["le-", "la-", "les-", "l-", "un-", "une-", "des-", "du-"]

    // Les adresses à essayer, de la plus probable à la moins. Vide quand le producteur n'est
    // pas une station de Radio France : lui a son flux chez Apple, il n'a aucune page à lire ici.
    static func urls(title: String, publisher: String?) -> [URL] {
        guard let publisher, let station = station(named: publisher) else { return [] }
        return slugs(of: title, station: station)
            .prefix(maxAttempts)
            .compactMap { URL(string: "https://www.radiofrance.fr/\(station.path)/podcasts/\($0)") }
    }

    // Le flux que la page déclare. Un seul lien compte : celui qui annonce un flux RSS.
    static func feedURL(inPage data: Data) -> URL? {
        let linkTag = /<link\b[^>]*>/
        let hrefAttribute = /href="([^"]+)"/
        let page = String(decoding: data, as: UTF8.self)
        for match in page.matches(of: linkTag) {
            let tag = String(match.output)
            guard tag.contains("rel=\"alternate\""), tag.contains("application/rss+xml"),
                  let href = tag.firstMatch(of: hrefAttribute)?.output.1 else { continue }
            return URL(string: String(href))
        }
        return nil
    }

    // La comparaison se fait sur la forme sans accent ni ponctuation, pour que « Mouv' » et
    // « Mouv » tombent au même endroit. Égalité stricte, jamais un début de nom : « Rádio FIP »
    // est un autre podcast, qui a son flux, et les pages de FIP ne lui diraient rien.
    private static func station(named publisher: String) -> Station? {
        let wanted = slug(publisher)
        guard !wanted.isEmpty else { return nil }
        return stations.first { slug($0.appleName) == wanted }
    }

    private static func slugs(of title: String, station: Station) -> [String] {
        let base = slug(title)
        guard !base.isEmpty else { return [] }
        // « Les Matins de France Culture » chez Apple, « les-matins » sur radiofrance.fr : la
        // station est dans le titre du podcast, pas dans l'adresse de sa page.
        let name = slug(station.appleName)
        var withoutStation = [base]
        for suffix in ["-de-\(name)", "-sur-\(name)", "-par-\(name)", "-\(name)"] where base.hasSuffix(suffix) {
            withoutStation.append(String(base.dropLast(suffix.count)))
        }
        // « Les Grandes Traversées » chez Apple, « grandes-traversees » sur radiofrance.fr.
        let withoutArticle = withoutStation.compactMap { candidate in
            articles.first { candidate.hasPrefix($0) }.map { String(candidate.dropFirst($0.count)) }
        }
        var ordered: [String] = []
        for candidate in withoutStation + withoutArticle where !candidate.isEmpty && !ordered.contains(candidate) {
            ordered.append(candidate)
        }
        return ordered
    }

    // Les adresses de radiofrance.fr sont en ASCII : les accents tombent, tout le reste devient
    // un tiret. « franceinfo Asie / Amérique » → « franceinfo-asie-amerique ».
    private static func slug(_ text: String) -> String {
        let folded = text.folding(options: [.diacriticInsensitive, .widthInsensitive],
                                 locale: Locale(identifier: "fr_FR")).lowercased()
        var slug = ""
        for character in folded {
            if character.isASCII, character.isLetter || character.isNumber {
                slug.append(character)
            } else if !slug.isEmpty, !slug.hasSuffix("-") {
                slug.append("-")
            }
        }
        while slug.hasSuffix("-") { slug.removeLast() }
        return slug
    }
}
