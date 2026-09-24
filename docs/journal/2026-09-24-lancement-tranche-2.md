---
type: journal
dates: 2026-09-24
statut: Tranche 2 lancée — PR 12 et 13 fusionnées (#29, #30), spéciaux en attente (#31)
---

# Session 16 — Remise à plat des docs, puis lancement de la Tranche 2

## Ce qui s'est passé

Deux moitiés très différentes. La journée a remis les documents d'aplomb ; la soirée a lancé la Tranche 2 et installé sa première migration sur l'iPhone de la founder.

### Les documents (#25, #27, #28)

| PR | Ce qui a changé |
|---|---|
| #25 | Le design porte le tableau des sept retours du 23/09. Une **erreur de rangement corrigée** : le changement de la PR #20 (« Logger » ouvre le formulaire) était décrit dans l'encadré du Journal alors qu'il concerne la fiche. L'état du projet décrit l'app d'aujourd'hui ; la checklist de la T1 est cochée, datée, et sa ligne « installé via TestFlight » corrigée — c'était par câble, et c'était une décision. |
| #27 | **Question 7 tranchée par la founder : « où j'en suis » sera un quatrième onglet « En cours »**, contre la reco du bandeau. La liste du § 6 du design a été remise dans l'ordre 1 → 9 : elle était numérotée 1, 2, 6, 3, 4, 5, 7, 8, et GitHub renumérote les listes ordonnées — les renvois « § 6, question 7 », cités dans quatre documents, ne tombaient pas sur la bonne ligne. |
| #28 | `CLAUDE.md` bascule : la T2 est lancée, la PR 12 ne se fusionne pas sans l'iPhone. |

### La Tranche 2 (#29, #30, #31)

**PR 12 — schéma V2 (#29).** `Season`, `Episode`, `LogEntry.episode`, et l'étage de migration. Les modèles de la V1 sont **figés** dans `Domain/Schema/V1/`, recopiés sans leurs règles. Sans ça, une classe partagée entre les deux versions porterait déjà les nouveaux champs et T-01 écrirait une fausse base « V1 » contenant déjà la V2 : le test ne testerait plus rien.

**PR 13 — saisons et épisodes chez TMDB (#30).** `EpisodeProvider` dans le `Domain`, rendu en valeurs (`SeasonSummary`, `EpisodeSummary`), implémenté par TMDB. Une saison n'est chargée qu'au dépliement — vérifié en comptant les requêtes, pas affirmé.

**Les spéciaux (#31, ouverte).** La founder a demandé pourquoi les épisodes spéciaux ne pouvaient pas être répartis dans les saisons auxquelles ils appartiennent. Vérification sur les vraies données : TMDB n'a **aucun champ** disant à quelle saison un spécial se rattache, et la date de diffusion — seul indice exploitable — **manque pour 37 des 39** spéciaux de Friends ; en français ils n'ont même pas de titre. Décision : une section « Spéciaux » en bas, cochable, jamais « le prochain épisode ». `SeasonSummary.isSpecials` porte la règle.

215 tests au début de la journée, **242 à la fin**. Couverture 82,9 %.

### La migration, sur l'appareil

La base de la founder contenait **7 œuvres, 11 logs, 10 références externes** depuis le 23/09. Procédure suivie avant de fusionner la #29 :

1. Sauvegarde du store depuis l'iPhone vers `~/Documents/kulturstack-sauvegarde-base-2026-09-24/`.
2. Lecture du store sauvegardé en SQLite pour prendre une référence exacte (titres, statuts, notes, dates).
3. `make device` sur la branche, puis lancement à distance pour déclencher la migration.
4. Re-téléchargement du store et **comparaison ligne à ligne**, pas seulement des totaux.

Résultat : identique à la ligne près. `ZSEASON` et `ZEPISODE` créées et vides, `ZLOGENTRY.ZEPISODE` présente et nulle partout. La founder a ensuite vérifié à l'écran ses six lignes de Journal, ses deux notes, l'onglet Envie et le badge « Base V2 · 7 fiches · 11 logs · 0 épisodes ».

La signature personnelle est repartie pour 7 jours à cette occasion : prochaine échéance **~01/10**.

## Ce qu'on a appris

1. **Vérifier l'état d'une PR avant de pousser sur sa branche.** La founder fusionne vite, dans le navigateur, sans le dire. La #30 était fusionnée depuis 11 minutes quand j'y ai poussé le commit des spéciaux : il est resté orphelin, et j'ai en plus modifié la description d'une PR fusionnée pour décrire du code absent de `main`. Coût : une quatrième PR et une description à corriger. **Un `gh pr view --json state` avant tout `git push` sur une branche déjà partie en revue.**

2. **Une migration se vérifie sur les données réelles, et se compare ligne à ligne.** Les totaux ne suffisent pas : sept œuvres avant et sept après peut cacher un échange. La comparaison par tuples (titre, statut, note, date) est cinq lignes de Python et donne une certitude, pas une impression.

3. **Sauvegarder avant de migrer, même quand le test est vert.** `xcrun devicectl device copy from --domain-type appDataContainer` récupère le store d'une app en développement. Trois fichiers : `.store`, `-shm`, `-wal`. Le WAL fait 1,5 Mo et contient des écritures non encore fusionnées — le copier aussi, sinon la sauvegarde est incomplète.

4. **Un conteneur SwiftData doit vivre aussi longtemps que son contexte.** `try ModelContainerFactory.inMemory().mainContext` dans une fonction helper laisse un contexte orphelin : dix tests ont planté d'un coup (`signal trap`) sur une simple insertion. Le conteneur se garde dans une propriété du `struct` de test, créée dans son `init`.

5. **Interroger la vraie API avant de répondre à une question produit.** « Pourquoi pas répartis dans les saisons ? » appelait une réponse technique plausible ; la réponse honnête (37 spéciaux sans date sur 39, aucun titre français) ne s'obtenait qu'en regardant les données. Même leçon que pour `combined_credits` le 23/09.

6. **Deux sessions ont posé la même question à la founder le même jour.** Une session de 17h a obtenu « pour où j'en suis fais un nouvel onglet » et ouvert la **PR #26** ; une session de 20h a reposé la question avec trois maquettes et ouvert les **#27** et **#28**. Même réponse, travail fait deux fois, et une PR périmée qui annulerait du travail si on la fusionnait. **Lire `gh pr list --state open` en début de session**, pas seulement l'état du projet : une PR ouverte est du travail en cours que la photo ne montre pas.

7. **Une liste markdown numérotée dans le désordre ment à l'écran.** GitHub renumérote séquentiellement : un item écrit « 7. » affiché en septième position seulement si les six précédents sont dans l'ordre. Quatre documents renvoyaient à « § 6, question 7 ».

## Pièges

1. `git push` sur une branche dont la PR est fusionnée **recrée la branche** côté GitHub (elle avait été supprimée à la fusion). D'où la branche fantôme `feat/tmdb-seasons`, supprimée en fin de session.
2. `gh pr view --json headRefOid` peut renvoyer une valeur périmée juste après un push ; `git ls-remote origin refs/heads/<branche>` dit la vérité.
3. `select name from sqlite_master where name not like 'Z_%'` n'exclut pas ce qu'on croit : dans `LIKE`, `_` est un joker. Les tables `ZMEDIAITEM` et consorts disparaissaient du listing.
4. Deux `@Model` du même nom dans deux `VersionedSchema` (V1 et V2) cohabitent sans problème — vérifié par T-01 et par la migration réelle sur l'appareil.
5. `curl` a échoué en « command not found » dans une commande composée avant de fonctionner en chemin absolu : utiliser `/usr/bin/curl` pour capturer une fixture.

## Ce qui n'a pas été fait

- La **PR 14** (cocher un épisode sur la fiche d'une série) n'est pas commencée. C'est la première de la T2 qui se verra à l'écran, et c'est une journée entière.
- Le seed DEBUG ne crée ni saison ni épisode — inutile tant qu'aucun écran ne les affiche. À faire avec la PR 14.
- Les spéciaux s'afficheront « Épisode 3 » en français, faute de titre chez TMDB. Secours possible par le titre anglais : une requête de plus par série, à peser si ça gêne à l'usage.

## À faire — prochaine session Claude

1. **Fusionner #31** si elle ne l'est pas : sans elle, `main` jette toujours la saison 0 et la décision du 24/09 n'est pas appliquée.
2. Demander à la founder ce que l'usage a donné depuis, et l'écrire dans `retours-utilisateurs.md` avant de coder.
3. **PR 14** — `docs/plans/tranche-2.md` : saisons dépliables sur la fiche d'une série, case par épisode, « tout cocher jusqu'ici », section « Spéciaux » en bas.
4. Vérifier l'état d'une PR (`gh pr view --json state`) avant tout push sur sa branche.
5. Signature de l'app à renouveler vers le **01/10** : iPhone branché, `make device`.
