---
type: tdd
statut: accepté
créé: 2026-09-20
---

# 02 — Modèle de données

## Principe (ADR-002, ADR-004, ADR-010)

Une **Fiche** (`MediaItem`) = une œuvre, quel que soit son type. Deux familles d'entités pointent vers elle :
- **`LogEntry`** — *je l'ai consommée* (date, statut, note). Plusieurs par fiche (revisionnage, relecture).
- **`OwnedCopy`** *(T5)* — *je la possède* (format, édition, date d'acquisition). Indépendant des logs.

Les champs **communs** vivent sur la fiche et sont interrogeables. Les champs **spécifiques au type** vivent dans une **poche Codable** (`detailsData`) qui sert à l'affichage, jamais aux requêtes.

La seule exception : `Season` / `Episode` *(T2)* sont de vrais modèles, parce qu'on les interroge (progression, prochain épisode).

## Schéma V1 (Tranche 1)

```swift
enum MediaKind: String, Codable, CaseIterable, Sendable {
    case film, series, book, album, podcast, game, concert, theatre, exhibition

    var hasEpisodes: Bool { self == .series || self == .podcast }
    var hasDuration: Bool { [.series, .book, .podcast, .game].contains(self) }
    var allowedStatuses: [LogStatus] {
        hasDuration ? [.wishlist, .inProgress, .done, .dropped] : [.wishlist, .done]
    }
    var searchFamily: SearchFamily  // .screen (film+series), .books, .music, .podcasts, .games, .live
}

enum LogStatus: String, Codable, CaseIterable, Sendable {
    case wishlist, inProgress, done, dropped
}

@Model final class MediaItem {
    @Attribute(.unique) var id: UUID
    var kindRaw: String                 // MediaKind.rawValue — SwiftData préfère les String aux enums
    var title: String
    var originalTitle: String?
    var year: Int?
    var creators: [String]              // réalisateur·ices, auteur·ices, artistes — affichage
    var summary: String?
    var coverURL: URL?
    var detailsVersion: Int             // version de la poche, pour évoluer sans casser
    var detailsData: Data?              // payload Codable typé par kind
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \ExternalRef.item) var externalRefs: [ExternalRef]
    @Relationship(deleteRule: .cascade, inverse: \LogEntry.item)    var logs: [LogEntry]

    var kind: MediaKind { get { MediaKind(rawValue: kindRaw)! } set { kindRaw = newValue.rawValue } }
}

@Model final class ExternalRef {
    @Attribute(.unique) var key: String  // "tmdb:movie:438631", "imdb:tt1160419", "ol:work:OL893415W", "isbn13:9782266320481"
    var provider: String                 // "tmdb", "imdb", "ol", "isbn13", "discogs", "itunes", "igdb", "setlistfm"
    var value: String
    var item: MediaItem?
}

@Model final class LogEntry {
    @Attribute(.unique) var id: UUID
    var date: Date                       // défaut = .now à la création, éditable
    var statusRaw: String                // LogStatus.rawValue
    var rating: Int?                     // 1...10 = 0,5 à 5 ★ (ADR-006)
    var note: String?
    var source: String                   // "manual" | "import:trakt" | "import:csv:goodreads"…
    var createdAt: Date
    var item: MediaItem?

    var status: LogStatus { get { LogStatus(rawValue: statusRaw)! } set { statusRaw = newValue.rawValue } }
}
```

### Pourquoi `ExternalRef` est un modèle et pas un tableau sur la fiche

La dédup (ADR-004) a besoin de répondre vite à « existe-t-il déjà une fiche avec `tmdb:movie:438631` ? ». Un `#Predicate` sur un tableau de structs Codable n'est pas supporté ; un modèle avec `key` unique répond en une requête indexée. Le `.unique` sur `key` garantit aussi qu'un même identifiant externe ne peut pas pointer vers deux fiches.

### Format de `key`

`<provider>:<value>` — sauf TMDB où le type est nécessaire (`tmdb:movie:…` / `tmdb:tv:…`) car les espaces d'identifiants film et série se chevauchent.

## Poches de détails (Codable, version 1)

```swift
struct FilmDetails: Codable    { var runtimeMinutes: Int?; var genres: [String]; var directors: [String] }
struct SeriesDetails: Codable  { var seasonCount: Int?; var episodeCount: Int?; var status: String?; var genres: [String] }
struct BookDetails: Codable    { var pageCount: Int?; var publisher: String?; var firstPublishYear: Int?; var subjects: [String] }
struct AlbumDetails: Codable   { var label: String?; var genres: [String]; var trackCount: Int? }            // T4
struct PodcastDetails: Codable { var feedURL: URL?; var publisher: String? }                                 // T4
struct GameDetails: Codable    { var platforms: [String]; var developers: [String] }                         // T6
struct ConcertDetails: Codable { var venue: String?; var city: String?; var setlist: [String] }              // T6
struct LiveDetails: Codable    { var venue: String?; var city: String?; var company: String? }               // T7 théâtre/expo
```

Décodage : `switch item.kind` → le bon type. Un champ manquant dans un vieux payload = valeur par défaut (tous les champs sont optionnels ou ont un défaut). `detailsVersion` permet un décodage conditionnel si un jour la forme change vraiment.

## Règles métier posées en T1 (testées)

1. `LogEntry.status` ∈ `item.kind.allowedStatuses`, sinon `DomainError.statusNotAllowed`.
2. `rating` ∈ 1...10 ou nil.
3. Créer une fiche avec un `ExternalRef.key` déjà présent → renvoie la fiche existante (pas de doublon).
4. Un log créé sans date reçoit `.now`.
5. Deux logs importés pour la même fiche **le même jour civil** avec la même source → un seul est gardé (ADR-004).

## Ce qui arrive plus tard (pour ne pas se coincer)

| Tranche | Entité | Schéma |
|---|---|---|
| 2 | `Season { number, title?, item }`, `Episode { number, title?, airDate?, season }`, et `LogEntry.episode: Episode?` | V2, lightweight |
| 5 | `OwnedCopy { id, format: String, editionRef: String?, acquiredAt: Date?, notes, item }` | V3, lightweight |
| 7 | rien de nouveau : théâtre/expos = `MediaItem` sans `ExternalRef`, `LiveDetails` | — |

## Requêtes que l'app doit savoir faire (et qui n'utilisent que les champs communs)

| Écran | Requête |
|---|---|
| Journal par période | `LogEntry` où `date ∈ [a, b]`, tri date desc |
| Journal par type | `LogEntry` où `item.kindRaw == "book"` |
| Compteurs semaine / mois / année | count des mêmes prédicats |
| Envie | `LogEntry` où `statusRaw == "wishlist"` |
| Où j'en suis (T2) | `LogEntry` où `statusRaw == "inProgress"` |
| Ma bibliothèque (T5) | `OwnedCopy` groupé par `format` |
| Dédup | `ExternalRef` où `key == …` |
