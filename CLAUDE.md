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

**Tranches 1 et 2 livrées.** T1 (`docs/plans/tranche-1.md`) installée sur l'iPhone de la founder et corrigée après deux jours d'usage réel (#18 → #22). **T2 — épisodes — close le 27/09/2026** (`docs/plans/tranche-2.md`) : les cinq PRs sont fusionnées (#29, #30, #31, #33, #34, #35). **338 tests verts**, couverture Domain 97 % · Data 95 % · Features 88 %.

**Les corrections d'usage du 27/09 sont livrées.** Huit retours après trois jours d'épisodes (`docs/product/retours-utilisateurs.md`), traités en sept petites PRs (#38 → #45) — tableau et état dans `docs/etat-du-projet.md` § 2. **384 tests verts**, couverture Domain 97 % · Data 95,5 % · Features 89,7 %.

**La suivante, ce sont les podcasts** (décision founder du 27/09 : avant l'import). Plan : `docs/plans/podcasts.md`. Les **numéros de tranche du PRD ne bougent pas**, seul l'ordre d'exécution change. Une **question attend la founder** avant la PR 3 du plan : Apple ne publie pas les flux RSS de Radio France.

**Ses deux verdicts du 27/09** : l'onglet « En cours » **reste troisième** ; l'appui long « tout cocher jusqu'ici » **n'avait jamais été trouvé** — il est devenu un bouton visible. Troisième geste caché abandonné après l'appui long de l'Envie : ici, ce qui ne se voit pas n'existe pas.

**Hors périmètre de la tranche podcasts** : import (T3), disques (T4b), possessions (T5), iPad, widgets, sync. Et, dans la tranche elle-même : les podcasts n'entrent **pas** dans l'onglet « En cours » ni dans « prochain épisode » — on écoute un podcast par le plus récent, pas par le premier non écouté ; à rouvrir après usage. Pas de progression de lecture pour les livres.

> **La migration V2 a été vérifiée sur l'appareil le 24/09** : base sauvegardée, comparée ligne à ligne, rien de perdu. Toute migration suivante se vérifie de la même façon — mode d'emploi dans `docs/journal/2026-09-24-lancement-tranche-2.md`.

> **`git fetch` avant de lire quoi que ce soit.** Un dépôt propre peut être en retard de plusieurs heures. Le 27/09, une session de l'après-midi a lu un `main` vieux de quatre heures, refait une partie des docs que la #36 venait de mettre à jour, et ouvert une PR en conflit. `gh pr list --state open` ne protège pas de ça : une PR **fusionnée** n'y apparaît pas.

> **Lire `gh pr list --state open` en début de session.** Une PR ouverte est du travail en cours que `docs/etat-du-projet.md` ne montre pas. Le 24/09, deux sessions ont posé la même question à la founder et ouvert trois PRs pour la même décision.

> **Vérifier l'état d'une PR avant de pousser sur sa branche** (`gh pr view <n> --json state`). La founder fusionne vite, dans le navigateur, sans le dire : un commit poussé sur une branche déjà fusionnée reste orphelin et recrée la branche côté GitHub. C'est arrivé le 24/09 (#30 → #31).

> **SwiftUI ne laisse pas tester une zone tactile, une animation ni un haptique.** Un `UIHostingController` n'expose qu'une seule `UIView` opaque : `hitTest` y répond pareil avec et sans `contentShape`. Ce qui se teste, c'est la **donnée** qui déclenche l'effet, et le **type du corps de la vue** (`String(describing: type(of: view.body))`) quand il faut prouver qu'un modificateur est là. Le reste se juge sur l'appareil, et se dit tel quel dans la PR.

> **Une PR empilée sur une autre se rebase après le squash de sa base** : `git rebase --onto origin/main <ancienne base> <branche>`. Le squash réécrit l'histoire de la base, et git voit alors les mêmes changements deux fois — conflit garanti sans rebase (27/09, #42).

> **Un test de rendu qui se contente de `#expect(height > 0)` ne peut pas échouer.** Comparer les PNG des états entre eux (`#expect(Set(shots).count == 3)`) — c'est ce qui tient la règle « vide ≠ erreur ≠ edge ». Les captures des PRs se produisent de la même façon, par un `CaptureHarness.swift` temporaire supprimé avant le commit : pièges et mode d'emploi dans `docs/journal/2026-09-27-fin-de-la-tranche-2.md`.

## Contexte founder — à garder en tête

Retour de burn-out, recherche d'emploi en parallèle, deux produits iOS co-prioritaires (Mealkin + Kulturstack). Le risque identifié est la **dispersion**.

- Time-box les blocs ; pas de mélange Mealkin / Kulturstack dans une même session.
- **Pas d'urgence artificielle.** Rien ne se ferme en 90 jours.
- Après 22h ou si la founder exprime de la fatigue : suggérer d'arrêter.
- Si une tranche dépasse largement l'estimation : le dire franchement, ne pas rassurer.
- Red flags à nommer : session > 4h sans pause, « on s'en fout, on fait le truc rapide », raccourci sur les tests ou le RGPD.
- La founder n'est pas développeuse iOS : expliquer en langage simple, une question à la fois, avec une reco. Pas de listes de 8 questions d'un coup.
