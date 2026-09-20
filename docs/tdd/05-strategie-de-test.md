---
type: tdd
statut: accepté
créé: 2026-09-20
---

# 05 — Stratégie de test

La founder ne relit pas le Swift en détail. **Les tests sont le filet, pas une option.** TDD strict : test rouge → implémentation → vert → commit.

## Cibles de couverture

| Zone | Cible | Comment on la tient |
|---|---|---|
| `Domain/` (modèles, règles, UseCases) | **≥ 70 %** | tout est pur ou sur container in-memory ; pas d'excuse |
| `Data/` (repositories, providers, importers) | ≥ 70 % | réseau stubbé, fixtures réelles |
| `Features/` (ViewModels) | **≥ 50 %** | ViewModels testés avec providers/repos mockés ; les Views ne sont pas testées unitairement |
| `DesignSystem/` | best-effort | composants triviaux |

Mesure : `make test` produit le rapport `xccov` ; la CI échoue sous les seuils.

## Outils

- **Swift Testing** (`import Testing`, `@Test`, `#expect`) pour tout le nouveau code. XCTest seulement si un outil l'exige.
- **SwiftData in-memory** : `ModelConfiguration(isStoredInMemoryOnly: true)` — un container neuf par test.
- **Réseau** : `URLProtocol` stub (`StubURLProtocol`) qui sert des fixtures JSON. Aucun test n'appelle Internet.
- **Fixtures** : réponses **réelles** capturées (TMDB `search/multi` pour « dune », OpenLibrary `search.json` pour « dune »), stockées dans `KulturstackTests/Fixtures/`. Rejouées, jamais réécrites à la main.
- **Mocks par protocole** : `MockMetadataProvider(results:delay:error:)`, `MockSecrets(values:)`.

## Les tests non négociables de la Tranche 1

| # | Test | Pourquoi |
|---|---|---|
| T-01 | Ouvrir un store créé en `SchemaV1` avec le `MigrationPlan` courant conserve les données | ADR-003 — attrape toute modification de modèle sans migration |
| T-02 | `LogEntry` avec un statut non autorisé pour le `kind` → erreur | ADR-006 |
| T-03 | `rating` hors 1...10 → erreur | ADR-006 |
| T-04 | Logger deux fois le même candidat → **une** fiche, **deux** logs | ADR-004 |
| T-05 | Deux candidats partageant une clé externe → même fiche | ADR-004 |
| T-06 | Log créé sans date → `date ≈ .now` | pilier 1 |
| T-07 | `SearchUseCase` : un provider échoue → sa section est `failed`, l'autre est `loaded` | ADR-005 |
| T-08 | `SearchUseCase` : nouvelle saisie annule la précédente (pas de résultats périmés) | ADR-005 |
| T-09 | `SearchUseCase` : les sections arrivent indépendamment (le lent ne bloque pas le rapide) | ADR-005 |
| T-10 | `TMDBProvider` parse la fixture → candidats `film`/`series` avec `tmdb:movie:`/`tmdb:tv:` | 03 |
| T-11 | `OpenLibraryProvider` parse la fixture → candidats `book` avec `ol:work:` + `isbn13:` | 03 |
| T-12 | `OpenLibraryProvider` envoie le `User-Agent` attendu | obligation |
| T-13 | Secret manquant (env + trousseau mockés vides) → erreur dont le message contient la commande d'ajout | 06 |
| T-14 | Seed DEBUG : `fill()` deux fois = même compte d'objets (idempotent) ; `wipe()` → 0 | règle proto |
| T-15 | Décodage d'une poche `FilmDetails` v1 avec champ manquant → valeur par défaut, pas de crash | 02 |
| T-16 | Stats : compteurs semaine / mois / année comptent les **logs**, pas les fiches (un film revu compte 2) | écrans validés |
| T-17 | Conversion des notes à l'import : Trakt 8/10 → 8 ; Goodreads 4/5 → 8 ; Letterboxd 3.5 → 7 | ADR-006 (posé en T1, utilisé en T3) |

## Ce qu'on ne teste pas

- Le rendu SwiftUI pixel par pixel (pas de snapshot tests en T1).
- Les vraies APIs (réservé à une vérification manuelle avant chaque tranche, voir 04).

## Vérification visuelle (règle proto, non automatisable)

Avant de dire « done » sur une PR qui touche un écran : capture de **l'état vide**, de **l'état rempli** (seed), et de **l'état d'erreur** si l'écran en a un. Les trois dans la description de la PR.
