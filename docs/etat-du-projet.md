---
type: état des lieux
maj: 2026-09-20
règle: mis à jour à chaque PR fusionnée — c'est la photo du projet, pas son histoire (l'histoire est dans docs/journal/)
---

# État du projet

## 1. En deux lignes

Le cadrage est complet (12 ADRs, PRD, design, TDD, plan T1). Le code contient les **fondations** : projet Xcode, design system minimal, schéma de base V1 avec plan de migration, 21 tests. **Aucune fonctionnalité utilisable** encore : l'app se lance sur un écran vide et affiche « Base V1 · 0 fiches · 0 logs ».

## 2. Features — planifié vs livré

### Tranche 1 — Le log magique (en cours, 2 PRs sur 12)

| PR | Feature | État |
|---|---|---|
| 0 | Bootstrap : projet, Makefile, secrets, `EmptyState`, FR/EN, CI tests | ✅ fusionnée (#1, 2026-09-20) |
| 1 | Schéma V1 + plan de migration + règles métier | ✅ fusionnée (#2, 2026-09-20) |
| 2 | Journal vide + seed DEBUG | ⏳ prochaine |
| 3 | Secrets + client TMDB | — |
| 4 | OpenLibrary + recherche unifiée | — |
| 5 | Écran Recherche | — |
| 6 | Log en 1 tap | — |
| 7 | Modifier un log (date, demi-étoiles, statut, note, supprimer) | — |
| 8 | Fiche d'une œuvre | — |
| 9 | Journal par période et par type, compteurs | — |
| 10 | Envie | — |
| 11 | Réglages, À propos, Confidentialité, finitions | — |
| — | TestFlight | — |

### Tranches suivantes (rien de commencé)

| # | Tranche | Contenu | Serveur |
|---|---|---|---|
| 2 | Épisodes | saisons / épisodes (séries, podcasts), « où j'en suis », statuts en cours / abandonné | non |
| 3 | Import du passé | Trakt ZIP JSON, CSV Goodreads / IMDb / Letterboxd / générique, file « à confirmer », export JSON | non |
| 4 | Disques + Podcasts | Discogs, Apple Podcasts + RSS | non |
| 5 | Collection | `OwnedCopy`, formats, import collection Discogs, scan code-barres, « Ma bibliothèque » | non |
| 6 | Jeux + Concerts | IGDB, Setlist.fm, **proxy Supabase** | oui |
| 7 | Théâtre / Expos + IA | saisie assistée, enrichissement LLM, recos, export Obsidian | oui |
| 8 | Social | comptes, partage, sync — nice-to-have | oui |

Le détail de chaque feature : `docs/product/prd.md` §6. Les écrans : `docs/product/design.md`.

## 3. Architecture — telle qu'implémentée

```
Kulturstack/
├── App/
│   ├── KulturstackApp.swift          ouvre le ModelContainer de prod ; EmptyState d'erreur si échec
│   ├── RootView.swift                placeholder + badge DEBUG « Base V1 · n fiches · n logs »
│   └── ModelContainerFactory.swift   production() / onDisk(url:) / inMemory() — toujours avec le plan de migration
├── Domain/
│   ├── Models/
│   │   ├── MediaKind.swift           9 types ; hasEpisodes, hasDuration, allowedStatuses, searchFamily
│   │   ├── LogStatus.swift           wishlist · inProgress · done · dropped
│   │   ├── MediaItem.swift           la fiche : champs communs + detailsData (poche) ; relations externalRefs / logs
│   │   ├── ExternalRef.swift         clé unique "provider:value"
│   │   └── LogEntry.swift            fabrique make() qui valide statut et note ; date = .now par défaut
│   ├── Details/
│   │   ├── DetailsPayload.swift      FilmDetails · SeriesDetails · BookDetails · GenericDetails (tolérants)
│   │   └── DetailsCodec.swift        encode / decode(kind:) ; currentVersion = 1
│   ├── Rules/
│   │   ├── LogRules.swift            validate(status:for:) · validate(rating:)
│   │   └── DomainError.swift
│   └── Schema/
│       ├── KulturstackSchemaV1.swift 3 modèles ; typealias MediaItem / ExternalRef / LogEntry
│       └── KulturstackMigrationPlan.swift  schemas [V1], stages [], current
├── DesignSystem/
│   ├── Tokens.swift                  Spacing, Radius, Color.*
│   └── EmptyState.swift              icône + titre + message + action optionnelle
└── Resources/
    ├── Localizable.xcstrings         6 clés FR + EN
    ├── PrivacyInfo.xcprivacy         aucune donnée collectée
    └── Assets.xcassets               AccentColor, AppIcon (vide)
```

**Pas encore là** (prévu par `docs/tdd/01-architecture.md`) : `Data/` (providers, repositories, réseau), `Features/` (Search, Journal, ItemDetail, LogEdit, Settings), `Debug/` (seed), `Domain/UseCases/`.

652 lignes de Swift, tests compris.

## 4. Tests — 21, tous verts

| Fichier | Tests | Couvre |
|---|---|---|
| `SmokeTests` | 2 | `EmptyState` garde son contenu ; FR et EN existent |
| `MediaKindTests` | 4 (paramétrés : 9 cas) | statuts par type, épisodes, familles de recherche |
| `LogRulesTests` | 7 (paramétrés : 11 cas) | **T-02** statut interdit, **T-03** note hors plage, **T-06** date = maintenant, fabrique refuse un statut interdit |
| `DetailsCodecTests` | 5 | round-trip, **T-15** champs manquants → défauts, `{}` → défauts, décodage par type, `MediaItem.details` |
| `SchemaMigrationTests` | 3 | **T-01** store V1 rouvert avec le plan → données intactes ; schéma courant = dernier du plan ; clé `ExternalRef` unique |

Couverture : `Domain/` 81-100 % par fichier, app 91 % global. Cibles (≥ 70 % Domain, ≥ 50 % Features) tenues.

Tests du plan pas encore écrits : T-04, T-05 (dédup, PR 6), T-07 à T-12 (recherche et providers, PR 3-4), T-13 (secrets, PR 3), T-14 (seed, PR 2), T-16 (stats, PR 9), T-17 (conversion des notes, PR 3 ou T3).

## 5. Infrastructure

| | État |
|---|---|
| Repo | `ukyapps/kulturstack`, public, `main` par défaut |
| Protection de `main` | ruleset `protect-main` : PR obligatoire, check `test` requis, pas de bypass, pas de force-push, pas de suppression |
| CI | `tests.yml` : macos-26, Xcode 26.3, `make test`, ~5 min. **Vert.** |
| Review | **locale**, par Claude, avant chaque push (CLAUDE.md § Review locale). Plus de review en CI (ADR-012). |
| Secrets GitHub | aucun |
| Secrets locaux | Trousseau `kulturstack` : **`TMDB_READ_TOKEN` pas encore posé** (nécessaire avant PR 3). `Config/Secrets.xcconfig` généré, gitignoré. |
| Outils locaux | Xcode 26.3, Swift 6.2, XcodeGen 2.46, simulateur iPhone 17 Pro (iOS 26.2), hook pre-commit installé |
| Identité git | `ukyapps` + email noreply |
| Domaines | kulturstack.com / .app / .io / .fr **libres au 19/09, pas réservés** |

## 6. Décisions (12 ADRs)

001 clé TMDB embarquée · 002 modèle générique + poche · 003 migration dès la PR 1 · 004 identité et dédup · 005 recherche unifiée · 006 notation et statuts · 007 iOS 18 + FR/EN · 008 nom Kulturstack · 009 Trakt par export JSON · 010 collection `OwnedCopy` · 011 ordre des tranches · 012 review locale, pas de review CI.

## 7. Carte de la documentation

| Fichier | Quoi | Quand le lire |
|---|---|---|
| `README.md` | carte du projet, identité | en arrivant |
| `CLAUDE.md` | conventions, review locale, contexte founder | **à chaque session** |
| `docs/etat-du-projet.md` | **ce fichier** — la photo à date | à chaque session |
| `docs/journal/` | une page par session : décisions, pièges, à-faire | pour reprendre |
| `docs/product/prd.md` | le produit : problème, principes, périmètre, exigences | avant de planifier |
| `docs/product/design.md` | l'expérience : écrans, états, design system | avant un écran |
| `docs/product/retours-utilisateurs.md` | ce que la founder (et plus tard d'autres) a dit, et ce qu'on en a fait | avant de trancher |
| `docs/tdd/01…07` | architecture, modèle, protocoles, sources, tests, secrets, RGPD | avant de coder une couche |
| `docs/decisions/001…012` | les ADRs | quand on se demande « pourquoi » |
| `docs/plans/tranche-1.md` | les 12 PRs de T1 | avant chaque PR |

## 8. Ouvert / à faire

**Founder** : réserver les domaines · poser la clé TMDB dans le Trousseau · (optionnel) désinstaller l'app GitHub « Claude » · recherche INPI avant le store.

**Prochaine session** : PR 2 — Journal vide + seed DEBUG.

**Questions produit ouvertes** (PRD §9, design §6) : musique écoutée vs possédée ; recherche = onglet ou « + » ; tap immédiat vs délai annulable ; journal groupé par jour ; Envie en chip.
