---
type: tdd
statut: accepté
créé: 2026-09-20
---

# 01 — Architecture

## En une phrase

App iOS **local-first** : toutes les données vivent dans SwiftData sur l'iPhone. Le réseau ne sert qu'à **chercher des métadonnées** (TMDB, OpenLibrary, plus tard Discogs, Apple Podcasts…). Aucun serveur Kulturstack en Tranches 1 à 5 ; un proxy mince (edge function Supabase) arrive en Tranche 6 pour porter les clés secrètes (IGDB, Setlist.fm) et l'IA (Tranche 7).

## Stack

| Couche | Choix | Pourquoi |
|---|---|---|
| Langage | Swift 5.9+, `async/await` partout | Convention §6 |
| UI | SwiftUI, MVVM | Convention §6 |
| Persistance | SwiftData, `VersionedSchema` + `SchemaMigrationPlan` dès la PR 1 | ADR-003 |
| Accès aux données | Repository (protocoles), injection par initializer | Testabilité, pas de singleton |
| Réseau | `URLSession` + clients par source derrière `MetadataProvider` | ADR-005 |
| Projet Xcode | XcodeGen (`project.yml`), `Makefile` | Convention §6 |
| Cible | iOS 18.0, iPhone only (`TARGETED_DEVICE_FAMILY: "1"`) | ADR-007 |
| Langues | `Localizable.xcstrings`, `developmentLanguage: fr`, FR + EN | ADR-007 |
| Tests | Swift Testing (`@Test`) pour le nouveau code ; XCTest accepté si un outil l'impose | Voir 05 |

## Découpage en couches

```
Kulturstack/
├── App/                    KulturstackApp, ModelContainer, injection racine
├── Domain/                 Modèles SwiftData, enums, règles métier pures, UseCases
│   ├── Models/             MediaItem, ExternalRef, LogEntry (+ Season/Episode en T2, OwnedCopy en T5)
│   ├── Schema/             SchemaV1, KulturstackMigrationPlan
│   ├── Details/            FilmDetails, SeriesDetails, BookDetails… (payloads Codable)
│   └── UseCases/           SearchUseCase, LogUseCase, DedupUseCase, StatsUseCase
├── Data/
│   ├── Repositories/       MediaRepository, LogRepository (protocoles + impl SwiftData)
│   ├── Providers/          MetadataProvider + TMDBProvider, OpenLibraryProvider
│   ├── Importers/          HistoryImporter (T3)
│   └── Network/            HTTPClient, Secrets, UserAgent
├── Features/               dossiers PAR FEATURE (Views + ViewModels + sous-modèles)
│   ├── Search/
│   ├── Journal/
│   ├── ItemDetail/
│   ├── LogEdit/
│   └── Settings/
├── DesignSystem/           tokens, EmptyState, StarRating, KindBadge, composants réutilisables
└── Debug/                  DebugMenu (seed / wipe), compilé hors Release
```

Règle : `Domain` ne dépend de rien. `Data` dépend de `Domain`. `Features` dépend des deux via protocoles injectés. `DesignSystem` ne connaît pas le domaine.

## Flux principal (Tranche 1)

```
Saisie "dune"
   → SearchUseCase lance TOUS les providers en parallèle (TaskGroup)
   → chaque provider renvoie [MediaCandidate] ou une erreur
   → l'écran reçoit des SearchSection (par famille de types), chacune avec son état
Tap sur un candidat
   → LogUseCase.logNow(candidate)
        → DedupUseCase : cherche un MediaItem existant par ExternalRef
        → sinon crée MediaItem + ExternalRef(s) + details payload
        → crée LogEntry(status: .done, date: .now)
   → bandeau "Loggé ✓ — modifier"
Journal
   → LogRepository.fetch(period:, kind:) → sections + compteurs
```

## Ce qui est volontairement absent en T1

- Pas de compte, pas de sync, pas d'analytics, pas de crash reporter tiers.
- Pas de cache image maison : `AsyncImage` + cache `URLCache` par défaut.
- Pas d'iPad, pas de widget, pas de Siri.
- Pas d'épisodes (T2), pas d'import (T3), pas de possessions (T5).

## Évolutions prévues et où elles se branchent

| Tranche | Ajout | Point de branchement |
|---|---|---|
| 2 | Season / Episode | nouveaux `@Model` + relation sur MediaItem → SchemaV2 |
| 3 | Import | `HistoryImporter` + `ImportResolver` réutilisant `DedupUseCase` |
| 4 | Discogs, Apple Podcasts | deux `MetadataProvider` de plus, deux cases de `MediaKind` déjà présentes |
| 5 | Collection | `OwnedCopy` `@Model` → SchemaV3, scan code-barres → `MetadataProvider.lookup(barcode:)` |
| 6 | IGDB, Setlist.fm | proxy Supabase ; `HTTPClient` prend une base URL par provider |
| 7 | Théâtre/expos + LLM | saisie assistée, `LLMEnrichmentProvider` derrière le proxy |
