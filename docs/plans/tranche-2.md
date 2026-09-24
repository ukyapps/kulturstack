---
type: plan
tranche: 2 — Épisodes
statut: en cours — lancée le 2026-09-24 ; PR 12 et 13 fusionnées ; « où j'en suis » = un onglet (§ 6 q. 7)
créé: 2026-09-23
---

# Plan Tranche 2 — Épisodes

**Objectif** : à la fin, une série se suit épisode par épisode. On ouvre sa fiche, on déplie une saison, on coche ce qu'on a vu (ou « tout cocher jusqu'ici »), et l'app sait dire **où on en est** et **quel est le prochain épisode**. Une série commencée passe en *en cours* toute seule ; une série qu'on laisse tomber se marque *abandonnée*.

**Ce qui déclenche cette tranche** : le vrai usage. La founder logge des séries à l'œuvre depuis le 21/09 — « Severance » apparaît dans son journal comme une ligne unique, alors qu'elle la regarde épisode par épisode.

## Périmètre

**Dedans** : saisons et épisodes de **séries** (TMDB), cocher un épisode, « tout cocher jusqu'ici », prochain épisode, statuts *en cours* et *abandonné*, écran « où j'en suis ».

**Dehors, même « vite fait »** :
- **Les podcasts.** Le PRD annonce « séries et podcasts » en T2, mais les podcasts n'existent pas avant la T4 (Apple Podcasts + RSS). Le modèle `Season` / `Episode` est écrit pour les deux ; la T2 ne câble que les séries.
- Import (T3), disques (T4), possessions (T5), iPad, widgets, sync.
- Les notes par épisode. Une note, c'est sur l'œuvre ; un épisode se coche, il ne se note pas. À rouvrir si l'usage le demande.

## Règles du plan

Les mêmes qu'en T1, elles ont tenu :
- 1 PR = 1 branche = 1 jour max = **quelque chose de visible à l'écran** à la fin.
- Tests d'abord (rouge → vert), strings FR + EN dans la même PR, captures vide / rempli dans la description.
- Merge quand `test` est vert **et** que la review locale est PASS dans la PR.
- Si une PR déborde d'une journée : la couper.

**Estimation** : 5 PRs ≈ 5 jours de travail → **2 à 3 semaines part-time**. Rien ne se ferme à une date.

---

## PR 12 — Schéma V2 : saisons et épisodes `feat/schema-v2` — ✅ #29

**Livre** : `Season`, `Episode`, `LogEntry.episode`, `KulturstackSchemaV2` et son **étage de migration**. Aucune interface.

- `Season { id, number, title?, item }` · `Episode { id, number, title?, airDate?, runtimeMinutes?, season }` · `LogEntry.episode: Episode?`
- `KulturstackMigrationPlan` : `[V1, V2]`, stage **lightweight** (on ajoute des modèles, on ne touche à rien d'existant).
- Tests : **T-01 étendu** — un store V1 **contenant des fiches et des logs** est rouvert avec le plan V2, les données sont intactes et `episode` vaut `nil` ; unicité d'un épisode dans sa saison ; un log d'épisode porte bien son œuvre.

**Démo** : le badge DEBUG affiche « Base V2 · n fiches · n logs · n épisodes ». Peu spectaculaire, assumé — comme la PR 1.

> **C'est la PR la plus risquée de la tranche, et la première vraie migration.** Jusqu'ici la base de la founder était jetable ; depuis le 23/09 elle contient ses vrais logs. Avant de fusionner : installer la branche sur son iPhone **par-dessus** l'app existante et vérifier que son journal est intact. Une migration ne se teste pas qu'en mémoire.
>
> **Fait le 24/09, et ça a tenu.** Sauvegarde du store depuis l'appareil (`~/Documents/kulturstack-sauvegarde-base-2026-09-24/`), référence prise en SQLite, installation, puis comparaison **ligne à ligne** : 7 œuvres, 11 logs, 10 références, identiques avant et après ; notes et commentaires conservés ; `ZSEASON` et `ZEPISODE` créées et vides. Mode d'emploi dans `docs/journal/2026-09-24-lancement-tranche-2.md`.

## PR 13 — Les épisodes chez TMDB `feat/tmdb-seasons` — ✅ #30, spéciaux en #31

**Livre** : de quoi remplir une saison depuis TMDB, derrière un protocole du `Domain`.

- `EpisodeProvider` (Domain) : `seasons(forKey:) -> [SeasonSummary]`, `episodes(forKey:season:) -> [EpisodeSummary]`.
- `TMDBProvider` l'implémente : `/tv/{id}` donne la liste des saisons (numéro, nom, nombre d'épisodes), `/tv/{id}/season/{n}` donne les épisodes.
- **Une saison n'est chargée qu'au dépliement**, jamais les dix d'un coup : une série longue, c'est dix appels réseau pour rien.
- Tests : fixture réelle capturée sur l'API (une série courte, une série à dix saisons), saison vide, épisodes sans date de diffusion, panne réseau → la fiche reste lisible.

**Démo** : l'écran DEBUG « Test recherche » sait afficher les saisons et les épisodes d'une série.

## PR 14 — Cocher un épisode `feat/series-episodes`

**Livre** : sur la fiche d'une série, la liste des saisons dépliables, une case par épisode, et « tout cocher jusqu'ici ».

> **Les spéciaux vivent en bas, à part** (founder, 24/09). La saison 0 de TMDB — making-of, bonus — arrive en dernier, sous un intitulé « Spéciaux », et se coche comme le reste. Elle ne compte **jamais** comme « prochain épisode » (PR 15 et 16) : `SeasonSummary.isSpecials` est là pour ça. TMDB ne dit pas à quelle saison un spécial se rattache — 37 des 39 de Friends n'ont pas même de date — donc on ne les intercale pas.

- Cocher = un `LogEntry` `done` daté maintenant, portant l'épisode. Décocher = supprimer ce log.
- « Tout cocher jusqu'ici » : crée les logs manquants de la saison jusqu'à l'épisode touché, **sans doublon** si certains sont déjà cochés.
- Trois rendus, comme partout : saison vide (« pas encore d'épisodes annoncés »), erreur de chargement (« Réessayer »), et la liste.
- Tests : cocher, décocher, tout cocher jusqu'ici (avec des trous), idempotence, un épisode déjà coché ne se dédouble pas.

**Démo** : captures fiche série repliée / dépliée / après avoir coché.

## PR 15 — « En cours » et « abandonné » `feat/status-in-progress`

**Livre** : les statuts existent déjà dans le modèle depuis la T1 (`allowedStatuses`) ; ici ils deviennent **automatiques et visibles**.

- Cocher un premier épisode → la série passe *en cours* (un log `inProgress` sur l'œuvre, pas sur l'épisode).
- Cocher le dernier épisode de la dernière saison → proposer *terminé*, sans l'imposer (une série qui continue n'est pas finie).
- *Abandonné* : une action explicite sur la fiche, jamais deviné.
- Le Journal montre déjà la pastille de statut sur la ligne : rien à inventer côté affichage.
- Tests : premier épisode → en cours ; dernier épisode → proposition de terminé ; abandonner puis reprendre ; une série sans épisode coché n'a aucun statut implicite.

**Démo** : captures avant / pendant / après une saison.

## PR 16 — « Où j'en suis » `feat/in-progress`

**Livre** : **un quatrième onglet « En cours »** — l'écran qui répond à « je reprends quoi ce soir ? ». Cartes « Severance · S2 E4 sur 10 · *Prochain : E5* » avec un ✓ qui coche l'épisode suivant sans ouvrir la fiche. Les livres en cours y sont aussi, avec « terminé » en un tap.

- Requête : les `LogEntry` `inProgress` sans log `done` ni `dropped` postérieur sur la même œuvre — exactement la mécanique des envies en attente (`StatsUseCase.pendingWishes`), à généraliser.
- **Le prochain épisode ignore les spéciaux** : une saison marquée `isSpecials` ne fournit jamais « la suite », même cochée en partie.
- État vide conçu avec l'écran : « Rien en cours » + « Chercher ». C'est l'écran d'accueil d'un onglet permanent : il sera vu vide souvent, il se soigne.
- Quatrième onglet dans la `TabView`, avec son icône et son libellé FR + EN.

> **✅ Tranché le 24/09/2026 : un quatrième onglet** (founder), contre la reco du bandeau — comme pour Envie le 22/09. La barre passe à Journal · Envie · En cours · Recherche.
>
> Ce que ça implique pour cette PR : un écran plein, pas un bandeau — liste verticale, une ligne par œuvre en cours avec sa progression (`S2 E4 sur 10`, `p. 212 sur 480`), le bouton qui avance d'un épisode à droite, et l'`EmptyState` « Rien en cours » quand la liste est vide (c'est alors un **onglet vide**, pas un bandeau qui disparaît : l'état vide compte double ici).
>
> **Reste à confirmer à l'écran, à la démo** : sa place dans la barre — troisième (l'ordre actuel ne bouge pas) ou deuxième, si « En cours » devient ce qu'on ouvre le soir.

**Démo** : captures vide / rempli, et le ✓ qui fait avancer une série.

---

## Ordre de dépendance

```
PR12 → PR13 → PR14 → PR15 → PR16
```

Tout est en file : le schéma d'abord, les données ensuite, l'interface après, l'écran de synthèse en dernier. Seule la PR 13 peut se faire en parallèle de la PR 12 si on stub le provider.

## Ce qu'on vérifie avant de dire « shippé »

- [ ] **La base de la founder survit à la migration** — testé sur son iPhone, avec ses vrais logs, pas seulement en mémoire.
- [ ] Test T-01 vert, dans sa version V1 → V2 **avec des données**.
- [ ] Une série de dix saisons ne déclenche pas dix appels réseau à l'ouverture.
- [ ] Cocher puis décocher puis recocher : un seul log, pas trois.
- [ ] Trois rendus distincts sur chaque nouvel écran (vide ≠ erreur ≠ edge).
- [ ] Coverage ≥ 70 % Domain et Data, ≥ 50 % Features.
- [ ] Aucune string en dur, FR + EN dans la même PR.
- [ ] Captures vide **et** rempli dans chaque PR.
- [ ] Les podcasts n'ont pas été câblés « en passant ».

## Ce que cette tranche ne résout pas

La founder regarde aussi des séries **sans les suivre épisode par épisode**. Rien ne l'y oblige : une série peut rester une ligne unique dans le journal, comme aujourd'hui. Les épisodes sont une option, pas un passage obligé — si la T2 rend le log d'une série plus lent qu'avant, elle a raté sa cible.
