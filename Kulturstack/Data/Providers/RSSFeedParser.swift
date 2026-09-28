import Foundation

// Un lecteur de flux RSS de podcast, sans dépendance : XMLParser suffit. On ne garde que ce
// qui sert à cocher un épisode — titre, date, durée, identité.
enum RSSFeedParser {
    static func parse(_ data: Data, limit: Int) -> [EpisodeSummary] {
        let collector = Collector(limit: limit)
        let parser = XMLParser(data: data)
        parser.delegate = collector
        parser.shouldProcessNamespaces = false
        parser.parse()
        // Le flux est publié du plus récent au plus ancien : c'est l'ordre dans lequel on
        // écoute un podcast, et donc celui de la liste.
        return collector.episodes.enumerated().map { index, item in
            EpisodeSummary(number: index + 1, title: item.title, airDate: item.date,
                           runtimeMinutes: item.runtimeMinutes, externalID: item.identity)
        }
    }

    // Une durée peut être « 00:16:57 », « 16:57 » ou un nombre de secondes.
    static func minutes(from duration: String?) -> Int? {
        guard let duration = duration?.trimmingCharacters(in: .whitespacesAndNewlines), !duration.isEmpty else { return nil }
        let parts = duration.split(separator: ":").compactMap { Int($0) }
        guard !parts.isEmpty else { return nil }
        let seconds = parts.reduce(0) { $0 * 60 + $1 }
        guard seconds > 0 else { return nil }
        // Un épisode d'une minute et demie n'en dure pas zéro : on ne descend jamais sous 1.
        return max(1, Int((Double(seconds) / 60).rounded()))
    }

    static func date(from text: String?) -> Date? {
        guard let text = text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else { return nil }
        for formatter in formatters {
            if let date = formatter.date(from: text) { return date }
        }
        return nil
    }

    // Les flux datent en RFC 822, avec ou sans jour de la semaine, en décalage ou en sigle.
    private static let formatters: [DateFormatter] = ["EEE, d MMM yyyy HH:mm:ss Z",
                                                      "EEE, d MMM yyyy HH:mm:ss zzz",
                                                      "d MMM yyyy HH:mm:ss Z",
                                                      "EEE, d MMM yyyy HH:mm Z"].map {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = $0
        return formatter
    }

    private struct Item {
        var title: String?
        var date: Date?
        var runtimeMinutes: Int?
        // Le guid du flux, sinon le lien : un épisode sans identité ne peut pas rester coché.
        var identity: String?
    }

    private final class Collector: NSObject, XMLParserDelegate {
        private(set) var episodes: [Item] = []
        private let limit: Int
        private var current: Item?
        private var text = ""
        private var link: String?

        init(limit: Int) { self.limit = limit }

        func parser(_ parser: XMLParser, didStartElement element: String, namespaceURI: String?,
                    qualifiedName: String?, attributes: [String: String] = [:]) {
            text = ""
            if element == "item" {
                current = Item()
                link = nil
            }
        }

        func parser(_ parser: XMLParser, foundCharacters string: String) { text += string }

        func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
            text += String(data: CDATABlock, encoding: .utf8) ?? ""
        }

        func parser(_ parser: XMLParser, didEndElement element: String, namespaceURI: String?, qualifiedName: String?) {
            let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
            text = ""
            guard current != nil else { return }
            switch element {
            case "title": current?.title = value.isEmpty ? nil : value
            case "pubDate": current?.date = RSSFeedParser.date(from: value)
            case "itunes:duration": current?.runtimeMinutes = RSSFeedParser.minutes(from: value)
            case "guid": current?.identity = value.isEmpty ? nil : value
            case "link": link = value.isEmpty ? nil : value
            case "item":
                if var item = current {
                    item.identity = item.identity ?? link
                    if episodes.count < limit { episodes.append(item) }
                }
                current = nil
            default: break
            }
            if episodes.count >= limit { parser.abortParsing() }
        }
    }
}
