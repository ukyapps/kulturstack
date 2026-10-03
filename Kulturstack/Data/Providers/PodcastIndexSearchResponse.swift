import Foundation

struct PodcastIndexSearchResponse: Decodable {
    let feeds: [PodcastIndexFeed]
}

struct PodcastIndexFeed: Decodable {
    let title: String?
    // Le producteur tel que l'index le connaît : « France Inter ». C'est lui qui empêche
    // d'attraper un podcast homonyme d'un autre éditeur.
    let author: String?
    let url: URL?
    let episodeCount: Int?
    let lastUpdateTime: Int?
    // L'index garde les flux morts et les marque : ils n'ont plus rien à rendre.
    let dead: Int?
}
