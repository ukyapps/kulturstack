---
type: journal
dates: 2026-09-30 (soir) → 2026-10-01
statut: 15 PRs fusionnées (#54 → #68), installée sur l'iPhone le 01/10
---

# Session 20 — Huit retours, une PR perdue, et les saisons qui reviennent

## Ce qui s'est passé

La founder a demandé une vérification : « vérifie que tous les retours que j'ai consigné ont bien été intégré jusqu'à présent ». La vérification a tenu ses promesses et en a cassé une : **un retour documenté comme livré ne l'était pas**.

Puis huit nouveaux retours, traités dans la foulée, et une feature née d'une seule de ses questions.

| | | |
|---|---|---|
| #54 | Les huit retours consignés | docs |
| #55 | **Récupérer la PR 44**, fusionnée dans une branche déjà écrasée | fix |
| #56 | Une œuvre = une ligne dans le Journal | fix |
| #57 | « En cours » passe à la saison suivante | fix |
| #58 | Terminé automatique quand tout est vu | feat |
| #59 | Réapprendre le nombre de saisons à l'ouverture d'une fiche | fix |
| #60 | Cocher une saison repliée et la série entière | feat |
| #61 | Les épisodes d'un podcast à l'endroit et par année | feat |
| #62 | Deux boutons sur la fiche | feat |
| #63 | Un podcast qui veut dire quelque chose dans « En cours » | feat |
| #64 | Le plan « nouvelles saisons » | docs |
| #65 | Une série finie revient quand une saison sort | feat |
| #66 | Réapprendre les saisons au lancement | feat |
| #67 | Ouvrir la fiche d'une série sur ses saisons, sans logger | fix |
| #68 | Chaque année d'un podcast traitée comme une saison | feat |

**596 tests verts** au terme de la session, contre 514 au début. Couverture Domain 96,6 % · Data 95,7 % · Features ~90 %.

**Aucun changement de schéma sur toute la session** — donc aucune migration, et aucune sauvegarde à faire avant d'installer. Première fois depuis la V2 qu'un lot de cette taille passe sans toucher au modèle.

## La PR fusionnée dans le vide

La **#44** (« Cocher le prochain épisode depuis le Journal ») avait pour base `feat/coche-qui-se-voit`, la branche de la #43 — pas `main`. La #43 a été écrasée dans `main` à 20h11 le 27/09 ; la #44 a été fusionnée à 20h30 **dans cette branche morte**. GitHub l'affiche « Merged », son commit existe, et il n'est pas un ancêtre de `main`.

Résultat : un retour de la founder (« le prochain épisode dans le journal aussi, comme dans en cours ») documenté ✅ dans `etat-du-projet.md` n'avait **jamais tourné sur son iPhone**. Trouvé en relisant `JournalRow.swift` pour autre chose : le bouton décrit dans la doc n'était pas dans le fichier.

> **Ce qu'il faut en retenir.** « Merged » sur GitHub ne veut pas dire « sur `main` ». La seule vérification qui vaut : `git merge-base --is-ancestor <commit> origin/main`. L'audit des 52 PRs fusionnées a trouvé **deux** bases autres que `main` ; une seule avait vraiment été perdue.

## Trois tests qui ne pouvaient pas échouer

1. **Une traduction comparée à elle-même.** `#expect(next.label == String(localized: "inprogress.next.season …"))` : ma clé était mal écrite, la chaîne ne se résolvait pas, l'écran affichait **« inprogress.next.season 2 1 »** en clair — et le test était vert, puisque les deux côtés rendaient la clé. **C'est la capture qui l'a vu.** Le test vérifie maintenant que la phrase est traduite (`contains("S2")`).

2. **Une fixture qui rate le seul cas réel.** Mon test du rafraîchissement marquait une série « terminée » sans jamais avoir regardé sa saison 1, puis s'étonnait qu'elle ne revienne pas. C'est normal : sans saison en base, l'app ne sait pas où elle en est. Le code était bon, le scénario était faux.

3. **Une assertion sur le titre au lieu de l'identité.** `#expect(Set(titres).count == titres.count)` sur le seed : il contient un film **et** un livre appelés « Dune ». Ce sont bien deux œuvres. Le test a attrapé ma propre erreur — l'assertion porte maintenant sur l'identifiant.

Même famille que le `#expect(height > 0)` de la Tranche 2. **La règle se généralise : une assertion qui se compare à elle-même ne prouve rien.**

## Les décisions de la founder

- **Une œuvre = une ligne dans le Journal.** Troisième fois qu'elle le demande (23/09 : « on peut mettre sur la même fiche qu'on l'a revu »). Retourne la règle T-16 (« on compte des logs, pas des fiches »).
- **Les podcasts à l'envers, comme les séries.** Ma reco était de garder le plus récent en haut ; elle a tranché l'inverse : « je voulais comme sur les séries donc à l'envers ».
- **« Terminé » automatique.** Inverse la décision du 24/09, qui *proposait* sans imposer.
- **Supprimer « Je le commence ».** Trois dispositions proposées avec maquettes ; elle a choisi celle qui inverse son propre retour du 27/09, en connaissance de cause (l'option le disait).
- **Les podcasts restent dans « En cours ».** Ma reco était de les en retirer, comme le plan le prévoyait.
- **Pas de bandeau « nouvelle saison ».** Voir ci-dessous.

## « Pourquoi tu veux faire un bandeau ? »

Sa question — « c'est pas un flux, ça s'update quand une nouvelle saison arrive ? » — a trouvé un bug : le nombre de saisons n'était récupéré **qu'une fois** et jamais revu. Avec le « terminé » automatique fusionné une heure plus tôt, une série finie serait restée finie **pour toujours**.

Puis, sur ma maquette de bandeau « du nouveau » : **« pourquoi tu veux faire un bandeau ? c'est pas dans suivi que ça apparaît juste quand y'a une suite ? »**

Elle a raison. Un bandeau, c'est un deuxième endroit à consulter pour une information qui a déjà son écran.

> **Quatrième fois qu'elle simplifie une proposition d'écran** : chip → onglet Envie (22/09), bandeau → onglet « En cours » (24/09), geste caché → bouton visible (27/09), bandeau → l'onglet existant (01/10). La leçon tient en une phrase : **quand une information a déjà un écran qui lui va, elle n'a pas besoin du sien.**

## Le retour trouvé en regardant l'app tourner

Le 01/10, en cliquant dans le simulateur : « quand je clique sur une fiche, ça me met pas les saisons, je suis obligée de mettre log… prends exemple sur TV Time ».

La liste des saisons ne s'affichait que si l'œuvre existait **déjà en base**, et elle n'y entrait qu'au premier log. Il fallait donc logger une série entière, avec une note et une date, avant de pouvoir cocher **un seul épisode**.

Corrigé (#67) : ouvrir la fiche d'une série ou d'un podcast suffit à l'enregistrer, **sans écrire de log**. Le Journal, l'Envie et « En cours » lisent des logs, pas des œuvres — l'œuvre reste donc invisible partout tant que rien n'est coché. C'est le test qui a été écrit en premier.

> **Rien ne remplace la regarder s'en servir.** Ce retour-là n'est sorti d'aucune relecture de code ni d'aucun test : il est sorti de trois clics dans le simulateur.

## Pièges

1. **`make device` échoue en `errSecInternalComponent`** quand la commande tourne en tâche de fond : macOS veut demander l'autorisation d'utiliser la clé de signature et ne peut pas afficher sa fenêtre. **Relancer au premier plan** et cliquer « Toujours autoriser ».
2. **Un iPhone « available (paired) » n'est pas « connected ».** Le Makefile cherche `connected` : écran déverrouillé, câble bien enfoncé.
3. **`make device | tail` masque toute la sortie** jusqu'à la fin du pipeline — même famille que le piège du `| tail` sur `make test`. Rediriger vers un fichier.
4. **Un `Set` dans un `Binding` ternaire ne compile pas** : `insert` rend un tuple, `remove` un optionnel. Écrire un `if/else`.

## Ce qui reste à faire

1. **Les retours de la vérification sur l'iPhone** — installée le 01/10 à 16h25. Quatre choses ne se testent pas automatiquement : les zones tactiles des boutons « Tout cocher » (saison et année), les coches de podcast après l'inversion de l'ordre, et les séries terminées qui ne doivent pas réapparaître.
2. **Radio France** (PR 34 de la tranche Podcasts) : cinq minutes d'inscription gratuite à Podcast Index côté founder.
3. **Le seed DEBUG** (PR 35) : il ne crée ni saison, ni épisode, ni podcast.
4. Signature de l'app : renouvelée le 01/10, prochaine échéance **~08/10**.
