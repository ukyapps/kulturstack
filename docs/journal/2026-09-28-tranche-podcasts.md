---
type: journal
dates: 2026-09-27 (nuit) → 2026-09-30
statut: tranche Podcasts à 4 PRs sur 6 (#48 → #51) ; restent Radio France et le seed
---

# Session 19 — La tranche Podcasts, ouverte et menée aux trois quarts

## Ce qui s'est passé

La founder a tranché : **les podcasts avant l'import** (« maintenant je voudrais qu'on ajoute les podcasts et tout »). La tranche a été cadrée, puis menée jusqu'au vocabulaire, dans la foulée des huit correctifs.

| PR | Ce qui change | État |
|---|---|---|
| #47 | Le **plan** de la tranche, écrit après avoir interrogé les vraies API | ✅ |
| #48 | **Schéma V3** : `Episode.externalID`, l'identité d'un épisode de podcast | ✅ — migration vérifiée sur l'iPhone |
| #49 | **Chercher un podcast** chez Apple, sans clé ni compte | ✅ |
| #50 | **Les épisodes par le flux RSS**, `XMLParser`, sans dépendance | ✅ |
| #51 | **Le vocabulaire des podcasts** : liste à plat, « J'ai tout écouté » | ✅ (30/09) |
| 34 | **Radio France** — résolveur de flux + clé gratuite au Trousseau | ⏳ attend 5 min de la founder |
| 35 | Seed DEBUG avec un podcast, finitions FR / EN | ⏳ |

**420 tests** sur `main`, couverture Domain 96,6 % · Data 95,6 % · Features 90,4 %.

## Ce que les API ont dit avant qu'on écrive une ligne

Cinq mesures, prises le 27/09, qui ont décidé de toute la tranche (détail dans l'ADR-013) :

1. **Apple cherche très bien les podcasts français**, sans clé ni compte.
2. **Sauf Radio France** : France Inter et France Culture, **10 podcasts testés, 10 sans `feedUrl`** — ni par `search`, ni par `lookup`. Tous les autres producteurs testés en ont un.
3. **Un flux se lit avec `XMLParser`**, sans dépendance : 96 épisodes datés et minutés pour « Le code a changé ».
4. **Les épisodes ne sont pas numérotés** : ni `itunes:episode`, ni `itunes:season`. Liste plate.
5. **Les flux sont tronqués par leurs éditeurs** : The Daily a publié des milliers d'épisodes, son flux n'en garde que **64**.

C'est la cinquième qui a coûté le plus cher et rapporté le plus : elle impose que **l'identité d'un épisode de podcast soit le `guid` de son flux**, pas sa position — donc un schéma V3, donc une migration. Trouvé **avant** de coder, pas au milieu de la tranche.

## La migration V3, sur l'appareil

Deuxième vraie migration de la base de la founder, qui contenait ses logs depuis le 23/09 et ses épisodes cochés depuis le 24/09. Procédure du 24/09, suivie à la lettre — avec deux ajustements appris sur le tas.

1. **Le store ne s'appelle pas `default.store`** mais `Library/Application Support/Kulturstack.store`. Pour le trouver sans deviner : `xcrun devicectl device info files --device <id> --domain-type appDataContainer --domain-identifier com.ukyapps.kulturstack`. Les trois fichiers se copient (`.store`, `-shm`, `-wal`) : le WAL faisait 3,8 Mo et portait des écritures non fusionnées.
2. **Référence prise en SQLite** : 13 œuvres, 37 logs, 34 références, 6 saisons, 48 épisodes, 16 épisodes cochés.
3. `make device`, puis lancement à distance pour déclencher la migration.
4. **Comparaison ligne à ligne** : **0 ligne perdue**, `ZEXTERNALID` créée et vide partout, et surtout **les clés d'épisodes inchangées à l'octet** — une clé réécrite, c'est une coche perdue.

> **Le piège qui a failli passer pour une perte de données.** La comparaison montrait *une œuvre de plus* (Peaky Blinders), *20 logs de plus*, *6 épisodes cochés de plus*. Ce n'était pas la migration : c'était la founder, en train de logger sa soirée **entre ma sauvegarde (23h07) et la migration**, les logs sont datés de 23h13 à 23h16. Elle utilise l'app pendant qu'on code. **Le verdict utile n'est pas « même total » mais « 0 perdu »** : une migration qui perd des données retire des lignes, elle n'en ajoute pas. Prendre la référence **juste avant** de migrer, et regarder les horodatages avant de crier.

## Sur l'iPhone

Le 28/09 à 12h30, la version complète (recherche Apple + épisodes RSS + vocabulaire) a été installée depuis la branche de la #51. **Aucune migration** ce coup-ci : l'app installée était déjà en V3, la nouvelle aussi — donc pas de sauvegarde ni de comparaison à refaire. La signature personnelle est repartie pour 7 jours à cette occasion.

## Ce qu'on a appris

1. **`make test | tail` renvoie le code de sortie de `tail`.** Un test rouge passe alors pour vert : c'est arrivé avec le badge DEBUG resté à « Base V2 », et ça n'a été vu qu'en relisant le décompte du `.xcresult`. Ce qui fait foi : `xcrun xcresulttool get test-results summary`. Écrit dans `CLAUDE.md`.

2. **Le simulateur garde la base d'une autre branche.** Après avoir testé la V3, revenir sur une branche antérieure fait hurler CoreData (« Cannot use staged migration with an unknown model version ») **sans faire échouer un seul test** — juste des centaines de lignes de log qui noient la sortie. `xcrun simctl uninstall booted com.ukyapps.kulturstack` nettoie.

3. **Une PR empilée se rebase après le squash de sa base.** La #42 était basée sur la branche de la #39 ; une fois la #39 écrasée en un commit, git voyait les mêmes changements deux fois. `git rebase --onto origin/main <ancienne base> <branche>` ne rejoue que le travail propre à la PR. **Empiler reste la bonne réponse** quand deux PRs touchent les mêmes fichiers — il faut juste savoir rebaser ensuite.

4. **Le vocabulaire est une feature.** La #50 livrait des épisodes de podcast parfaitement fonctionnels, sous un écran qui disait « SAISONS », « Saison 1 » et « J'ai vu toute la saison ». Ça marchait et ça parlait mal. Livrer la donnée d'abord et la langue ensuite était le bon découpage — à condition que la deuxième PR suive **tout de suite**, et que la première le dise dans sa description.

5. **Un rang qui bouge ne veut rien dire.** Même raison que le schéma V3, appliquée à l'écran : le numéro d'un épisode de podcast a disparu de la ligne. La règle vaut au-delà des podcasts — ne jamais afficher une position calculée depuis une source qui se réordonne.

## Pièges

1. `KeyPath` n'est pas `Sendable` : un `@Test(arguments:)` qui en prend un ne compile pas dans une suite `@MainActor`. Boucler sur un tableau de valeurs à l'intérieur d'un seul test.
2. `#require` **imbriqué** dans un autre `#require` : « recursive expansion of macro ».
3. `#expect(x.allSatisfy(\.propriété))` ne compile pas — le key path rend l'appel `rethrows` ambigu dans la macro. Utiliser une fermeture.
4. Ajouter des tests « à la fin du fichier » par script les met dans la **dernière structure** du fichier, pas dans la structure de tests, quand le fichier se termine par un stub.
5. `-resultBundlePath` échoue si le bundle existe déjà : le `rm -rf` du Makefile n'est pas décoratif.
6. Une branche créée « depuis `main` » pendant que la founder fusionne peut naître **en retard d'une PR**. `git fetch` puis `git log origin/main` avant de brancher, pas seulement en début de session.

## Ce qui reste à faire

1. **Fusionner la #52** (documents produit à jour : design, modèle, ADR-013).
2. **Radio France** (PR 34) : cinq minutes d'inscription gratuite à Podcast Index côté founder, puis vérifier **avec la clé en main** que l'index couvre bien Radio France avant d'écrire la PR. Un ADR accompagnera celle-ci — elle introduit un secret.
3. **Le seed DEBUG** (PR 35) : aujourd'hui il ne crée ni saison, ni épisode, ni podcast.
4. **Demander ce que deux jours d'usage des podcasts ont donné**, et l'écrire dans `retours-utilisateurs.md` avant de coder — comme le 23/09 et le 27/09.
5. Signature de l'app : renouvelée le 28/09, prochaine échéance **~05/10**.
