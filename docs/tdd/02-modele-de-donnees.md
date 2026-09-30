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

**Schéma courant : V3.** V1 (T1) → V2 (T2, saisons et épisodes) → V3 (Podcasts, l'identité d'un épisode). Les trois versions sont figées dans `Domain/Schema/` : les modèles vivants sont ceux de la **V3**, ceux de la V1 et de la V2 sont des copies **qu'on ne modifie plus** — c'est contre elles que le test T-01 fait migrer une base peuplée. Sans ces copies, T-01 écrirait une fausse base « ancienne » contenant déjà la nouvelle version, et ne testerait plus rien.

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
    var source: String                   // "manual" | "episodes" (posé par l'app) | "import:trakt"…
    var createdAt: Date
    var item: MediaItem?
    var episode: Episode?                // V2 — nil pour un log qui parle de l'œuvre entière

    var status: LogStatus { get { LogStatus(rawValue: statusRaw)! } set { statusRaw = newValue.rawValue } }
}

// V2 — livrés le 24/09/2026 (#29). Du cache de source, pas de la donnée utilisatrice.
@Model final class Season {
    @Attribute(.unique) var key: String  // "<itemID>:s<n>" — la saison 0 est celle des spéciaux
    var number: Int
    var title: String?
    var item: MediaItem?
    @Relationship(deleteRule: .cascade, inverse: \Episode.season) var episodes: [Episode]
}

@Model final class Episode {
    @Attribute(.unique) var key: String  // "<seasonKey>:e<n>" — ou "<seasonKey>:g<guid>" si externalID
    var number: Int
    var title: String?
    var airDate: Date?
    var runtimeMinutes: Int?
    var externalID: String?              // V3 — le guid d'un flux RSS ; nil pour une série
    var season: Season?
    // nullify, et pas cascade : recharger une saison détache les logs, ça ne les efface pas.
    @Relationship(deleteRule: .nullify, inverse: \LogEntry.episode) var logs: [LogEntry]

    var isWatched: Bool { logs.contains { $0.status == .done } }
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
struct PodcastDetails: Codable { var feedURL: URL?; var episodeCount: Int?; var publisher: String?; var genre: String? }  // ✅ #49
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

## Règles posées en T2 et dans la tranche Podcasts (testées)

6. Une `Season` n'existe que pour un type à épisodes (`kind.hasEpisodes`), sinon `DomainError.seasonsNotAllowed`.
7. **L'identité d'un épisode dépend de sa source.** Un épisode de série est reconnu à son **numéro** — TMDB le numérote, et cette numérotation est stable. Un épisode de podcast est reconnu à son **`externalID`**, le `guid` de son flux RSS. La clé unique suit : `<saison>:e<numéro>` sans identité, `<saison>:g<guid>` avec. Les clés des épisodes de séries **n'ont pas changé** en V3 — une clé réécrite, c'est une coche perdue.
8. Pourquoi : un flux RSS est **tronqué par son éditeur** (The Daily a publié des milliers d'épisodes, son flux n'en garde que 64) et publie en tête. Une numérotation par position décalerait tout ce qui est déjà coché à la première publication.
9. Cocher un épisode = un `LogEntry` `done` qui le porte ; décocher = supprimer ce log. Le statut de l'œuvre (`en cours`, `terminé`) est un log **sans** épisode, marqué `source = "episodes"` quand il a été posé automatiquement.
10. **Un podcast ne se termine pas** : `WatchStatusUseCase.finishes` ne propose « terminé » que pour une série. Un podcast publiera encore.

## Ce qui arrive plus tard (pour ne pas se coincer)

| Tranche | Entité | Schéma |
|---|---|---|
| 2 | ✅ **fait le 24/09/2026** — `Season`, `Episode`, `LogEntry.episode` | V2, lightweight |
| — | ✅ **fait le 27/09/2026** — `Episode.externalID` (le `guid` d'un flux RSS) | **V3, lightweight** |
| 5 | `OwnedCopy { id, format: String, editionRef: String?, acquiredAt: Date?, notes, item }` | V4, lightweight |
| 7 | rien de nouveau : théâtre/expos = `MediaItem` sans `ExternalRef`, `LiveDetails` | — |

## Requêtes que l'app doit savoir faire (et qui n'utilisent que les champs communs)

| Écran | Requête |
|---|---|
| Journal par période | `LogEntry` où `date ∈ [a, b]`, tri date desc |
| Journal par type | `LogEntry` où `item.kindRaw == "book"` |
| Compteurs semaine / mois / année | count des mêmes prédicats |
| Envie | `LogEntry` où `statusRaw == "wishlist"` |
| Où j'en suis (T2) | les œuvres dont le **dernier** log parlant d'elles (`episode == nil`, envies exclues) dit `inProgress` — un `done` ou un `dropped` postérieur les en sort. `WatchStatusUseCase.status(of:)` est le seul endroit qui en décide. |
| Prochain épisode (T2) | premier `Episode` non coché des saisons **en cache**, saison 0 exclue — aucun appel réseau |
| Ma bibliothèque (T5) | `OwnedCopy` groupé par `format` |
| Dédup | `ExternalRef` où `key == …` |
