# Kulturstack — conventions du repo

Journal de consommation culturelle multi-média, sans friction, local-first, iOS. Lis ce fichier à chaque session, puis `docs/etat-du-projet.md` (la photo) et la dernière page de `docs/journal/` (l'histoire) pour reprendre là où on s'est arrêté. Le produit est décrit dans `docs/product/` (PRD + design), les décisions dans `docs/decisions/`, le cadrage dans `docs/tdd/`, le plan courant dans `docs/plans/`.

> Pas de review automatique en CI (décision du 2026-09-20, ADR-012). **Chaque PR est relue par Claude en local, avec la grille du §« Review locale », avant d'être poussée.** La CI ne fait tourner que les tests.

## Identité

| | |
|---|---|
| Bundle id | `com.ukyapps.kulturstack` |
| iOS minimum | 18.0 — iPhone uniquement |
| Langues | français (référence) + anglais, `Localizable.xcstrings` |
| Service Trousseau | `kulturstack` |

## Stack

Swift 6 (Xcode 26) · SwiftUI · MVVM + Repository · SwiftData (`VersionedSchema` + `SchemaMigrationPlan`, toujours) · `async/await` partout · Swift Testing.

**XcodeGen** : le `.xcodeproj` est généré depuis `project.yml`, jamais édité à la main.
```
make generate            # secrets + xcodegen
make build
make test SIM="iPhone 17 Pro"
make coverage
```

## Architecture (voir `docs/tdd/01-architecture.md`)

- `Domain/` ne dépend de rien. `Data/` dépend de `Domain`. `Features/` consomme les deux via protocoles injectés.
- Dossiers **par feature**, pas par couche : `Features/Journal/` contient ses Views + ViewModels + sous-modèles.
- 1 type principal par fichier, nom du fichier = nom du type.
- Injection **par initializer**. Zéro singleton.
- Sources externes uniquement derrière `MetadataProvider` / `HistoryImporter`.

## Modèle (voir `docs/tdd/02-modele-de-donnees.md`)

- `MediaItem` = l'œuvre, tous types. Champs communs interrogeables + poche `detailsData` Codable par type, jamais interrogée.
- `LogEntry` = je l'ai consommée. `OwnedCopy` (T5) = je la possède. Indépendants.
- `ExternalRef.key` unique, format `<provider>:<value>` → dédup.
- **Toute modification d'un `@Model` = nouveau `SchemaVN` + stage de migration.** Pas d'exception. Le test T-01 doit rester vert.
- Un statut doit appartenir à `kind.allowedStatuses`. `rating` ∈ 1…10.

## TDD strict

La founder ne relit pas le Swift en détail : **les tests sont le filet**. Pour chaque feature : écrire le(s) test(s) → vérifier qu'ils échouent → implémenter jusqu'au vert → commit. Cibles : **≥ 70 %** `Domain/` et `Data/`, **≥ 50 %** `Features/`. Aucun test n'appelle Internet (fixtures + `StubURLProtocol`). Les tests de secrets utilisent `MockSecrets`, jamais `BundleSecrets`.

## Prototype utilisable dès le jour 1 — non négociable

- **Jamais de seed au boot.** Premier lancement = base vide, réelle.
- Seed derrière un bouton DEBUG « Remplir données démo » / « Tout effacer », compilé hors Release, **idempotent** (remplir = wipe puis seed), testé.
- **Empty state conçu avec l'écran**, jamais après : `EmptyState` du design system (icône + titre + message + CTA optionnel). Pas un blanc, pas une ligne grise.
- Trois rendus distincts : **vide** (rien loggé) ≠ **erreur** (chargement raté) ≠ **edge** (filtre sans résultat).
- Avant « done » : captures de l'état vide **et** de l'état rempli dans la PR.

## Strings

**100 % via `Localizable.xcstrings`**, FR + EN dans la même PR. Jamais de texte UI en dur.

## Secrets (voir `docs/tdd/06-secrets.md`)

- **Jamais** dans le chat, un `.env`, un fichier versionné, un plist launchd.
- Trousseau → `make secrets` → `Config/Secrets.xcconfig` (gitignoré) → `Info.plist`. Env d'abord (`TMDB_READ_TOKEN`), trousseau sinon.
  ```bash
  security add-generic-password -s kulturstack -a TMDB_READ_TOKEN -w "$(pbpaste)"   # jamais en collant à l'invite : coupé à 128 caractères
  ```
- Un secret qui a transité en clair est à faire tourner.
- Clé TMDB embarquée = risque accepté (ADR-001). Proxy en T6.

## Git

- `main` protégée, **jamais** de commit direct. Branches `feat/` · `fix/` · `chore/`. 1 branche = 1 PR = 1 changement focalisé ; jamais réutiliser un nom de branche.
- Messages à l'infinitif, première ligne < 72 caractères, 1 commit = 1 changement logique.
- Merge quand le check `test` est vert **et** que la review locale (ci-dessous) est PASS, collée dans la description de la PR. La founder fusionne dans le navigateur (Squash and merge).
- Jamais de `--force`, `reset --hard` destructif, `--no-verify`, ni de secret committé.

## Review locale — avant chaque push

Relire le diff complet (`git diff main...HEAD`) contre ce fichier et écrire la fiche dans la description de la PR :

```
VERDICT: PASS | FAIL
## Bloquant   (liste ou « aucun »)
## Mineur     (liste ou « aucun »)
## Bien       (1 à 3 points)
```

Bloquant = bug ; secret ou `Config/Secrets.xcconfig` dans le diff ; code de feature sans test ; `@Model` modifié sans `SchemaVN` + stage ; string UI en dur ou FR sans EN ; seed au boot ou non idempotent ; écran sans `EmptyState` ou qui confond vide / erreur / edge ; statut hors `allowedStatuses` ; note hors 1…10 ; singleton ; completion handler ; SDK analytics / crash / pub. Un FAIL ne se pousse pas.

## Code

- Zéro commentaire par défaut. Un commentaire explique un *pourquoi* non évident, jamais un *quoi*.
- `async/await`, pas de completion handlers.
- Pas de SDK d'analytics / crash / pub sans ADR (voir `docs/tdd/07-rgpd.md`).

## Poids du process

| Tâche | Process |
|---|---|
| Feature / bugfix | issue, TDD, coverage, PR, ADR si structurant |
| Docs / design / recherche | branche + PR pour la review du diff ; pas d'issue, pas de TDD |
| Chore / config | branche + PR, léger |

## Périmètre courant

**Tranche 1 livrée** (`docs/plans/tranche-1.md`), installée sur l'iPhone de la founder et corrigée après deux jours d'usage réel (#18 → #22). **Rien n'est en cours.**

La Tranche 2 — épisodes — est planifiée (`docs/plans/tranche-2.md`) mais **pas lancée** : ne rien coder dessus avant le feu vert de la founder, et avant qu'elle ait tranché où vit « où j'en suis » (design § 6, question 7). Le jour où elle lance la T2, mettre ce paragraphe à jour.

**Hors périmètre** : épisodes et « en cours » (T2, pas lancée), import (T3), disques et podcasts (T4), possessions (T5), iPad, widgets, sync. Si une PR déborde d'une journée, la couper.

## Contexte founder — à garder en tête

Retour de burn-out, recherche d'emploi en parallèle, deux produits iOS co-prioritaires (Mealkin + Kulturstack). Le risque identifié est la **dispersion**.

- Time-box les blocs ; pas de mélange Mealkin / Kulturstack dans une même session.
- **Pas d'urgence artificielle.** Rien ne se ferme en 90 jours.
- Après 22h ou si la founder exprime de la fatigue : suggérer d'arrêter.
- Si une tranche dépasse largement l'estimation : le dire franchement, ne pas rassurer.
- Red flags à nommer : session > 4h sans pause, « on s'en fout, on fait le truc rapide », raccourci sur les tests ou le RGPD.
- La founder n'est pas développeuse iOS : expliquer en langage simple, une question à la fois, avec une reco. Pas de listes de 8 questions d'un coup.
