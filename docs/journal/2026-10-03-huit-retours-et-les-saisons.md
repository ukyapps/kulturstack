---
type: journal
dates: 2026-09-30 (soir) → 2026-10-03
statut: 17 PRs fusionnées (#54 → #70), installée sur l'iPhone le 01/10, retours d'usage traités le 03/10
---

# Session 20 — Huit retours, une PR perdue, et ce que trois clics ont trouvé

## Ce qui s'est passé

La founder a demandé une vérification : « vérifie que tous les retours que j'ai consigné ont bien été intégré jusqu'à présent ». La vérification a tenu ses promesses et en a cassé une : **un retour documenté comme livré ne l'était pas**.

Puis huit nouveaux retours, une feature née d'une seule de ses questions, un bug trouvé en la regardant cliquer, et cinq retours de plus après deux jours d'usage réel.

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
| #67 | **Ouvrir la fiche d'une série sur ses saisons, sans logger** | fix |
| #68 | Chaque année d'un podcast traitée comme une saison | feat |
| #69 | **Cocher une saison en une écriture** au lieu d'une par épisode | perf |
| #70 | **Le retour haptique suit le geste**, pas la donnée | fix |

**601 tests verts**, contre 514 au début. Couverture Domain ~97 % · Data ~96 % · Features ~90 %.

**Aucun changement de schéma sur toute la session** — donc aucune migration, et aucune sauvegarde avant d'installer. Première fois depuis la V2 qu'un lot de cette taille passe sans toucher au modèle.

## La PR fusionnée dans le vide

La **#44** (« Cocher le prochain épisode depuis le Journal ») avait pour base `feat/coche-qui-se-voit`, la branche de la #43 — pas `main`. La #43 a été écrasée dans `main` à 20h11 le 27/09 ; la #44 a été fusionnée à 20h30 **dans cette branche morte**. GitHub l'affiche « Merged », son commit existe, et il n'est pas un ancêtre de `main`.

Résultat : un retour de la founder documenté ✅ dans `etat-du-projet.md` n'avait **jamais tourné sur son iPhone**. Trouvé en relisant `JournalRow.swift` pour autre chose : le bouton décrit dans la doc n'était pas dans le fichier.

> **« Merged » sur GitHub ne veut pas dire « sur `main` ».** La seule vérification qui vaut : `git merge-base --is-ancestor <commit> origin/main`. L'audit des 52 PRs fusionnées a trouvé **deux** bases autres que `main` ; une seule avait vraiment été perdue.

## Ce que trois clics ont trouvé

Le 01/10, en ouvrant l'app dans le simulateur : « quand je clique sur une fiche, ça me met pas les saisons, je suis obligée de mettre log… prends exemple sur TV Time ».

La liste des saisons ne s'affichait que si l'œuvre existait **déjà en base**, et elle n'y entrait qu'au premier log. Il fallait donc logger une série entière, avec une note et une date, avant de pouvoir cocher **un seul épisode**.

Puis le 03/10, après deux jours d'usage : cinq retours, **deux causes**.

- Le **retour haptique** était accroché à une valeur affichée. Muet sur les podcasts (plus de barre de progression depuis la #63) et muet quand la ligne quittait l'écran (dernier épisode → série terminée). Ses exemples étaient le diagnostic : « ça le fait sur Dix pour cent et Peaky Blinders, pas sur Arrested Development ou Transfert » — des séries au milieu d'une saison contre un podcast et une série qui se terminait.
- Le **lag** n'était pas la quantité de données mais le nombre d'**écritures** : une par épisode. « J'ai tout écouté » sur 96 épisodes, c'était 96 enregistrements à la suite.

> **Rien ne remplace la regarder s'en servir.** Aucun de ces trois bugs n'est sorti d'une relecture de code ou d'un test. Une suite verte à 600 tests n'avait rien dit sur « je dois logger avant de pouvoir cocher ».

## Quatre tests qui ne pouvaient pas échouer

1. **Une traduction comparée à elle-même.** Ma clé était mal écrite, la chaîne ne se résolvait pas, l'écran affichait **« inprogress.next.season 2 1 »** en clair — et le test était vert, les deux côtés rendant la clé. **C'est la capture qui l'a vu.**
2. **Une fixture qui rate le seul cas réel.** Mon test du rafraîchissement marquait une série terminée sans jamais avoir regardé sa saison 1, puis s'étonnait qu'elle ne revienne pas. Le code était bon, le scénario était faux.
3. **Une assertion sur le titre au lieu de l'identité.** Le seed contient un film **et** un livre appelés « Dune » : ce sont bien deux œuvres.
4. **Un compteur qui compte les non-erreurs.** Ma première version du retour haptique incrémentait dès qu'aucune erreur n'était levée — or avancer une œuvre arrivée au bout ne lève pas. L'app aurait vibré sans rien cocher. Le test l'a attrapé.

**La règle se généralise : une assertion qui se compare à elle-même ne prouve rien.** Et pour une mesure de performance, ce qui est stable n'est pas le temps écoulé mais le **nombre d'allers-retours en base** — c'est ce que comptent les tests de la #69.

## Les décisions de la founder

- **Une œuvre = une ligne dans le Journal.** Troisième fois qu'elle le demande. Retourne la règle T-16.
- **Les podcasts à l'envers, comme les séries.** Ma reco était l'inverse.
- **« Terminé » automatique.** Inverse la décision du 24/09, qui proposait sans imposer.
- **Supprimer « Je le commence ».** Trois dispositions proposées avec maquettes ; elle a choisi celle qui inverse son propre retour du 27/09, en connaissance de cause.
- **Les podcasts restent dans « En cours »** — ma reco était de les en retirer.
- **Chaque année de podcast devient une saison** : repliable, cochable d'un bloc.
- **Pas de bandeau « nouvelle saison ».** Voir ci-dessous.

## « Pourquoi tu veux faire un bandeau ? »

Sa question — « c'est pas un flux, ça s'update quand une nouvelle saison arrive ? » — a trouvé un bug : le nombre de saisons n'était récupéré **qu'une fois** et jamais revu. Avec le « terminé » automatique fusionné une heure plus tôt, une série finie serait restée finie **pour toujours**.

Puis, sur ma maquette de bandeau « du nouveau » : **« pourquoi tu veux faire un bandeau ? c'est pas dans suivi que ça apparaît juste quand y'a une suite ? »**

> **Quatrième fois qu'elle simplifie une proposition d'écran** : chip → onglet Envie (22/09), bandeau → onglet « En cours » (24/09), geste caché → bouton visible (27/09), bandeau → l'onglet existant (01/10). **Quand une information a déjà un écran qui lui va, elle n'a pas besoin du sien.**

## Pièges

1. **`make device` échoue en `errSecInternalComponent`** quand la commande tourne en tâche de fond : macOS veut demander l'autorisation d'utiliser la clé de signature et ne peut pas afficher sa fenêtre. **Relancer au premier plan** et cliquer « Toujours autoriser ».
2. **Un iPhone « available (paired) » n'est pas « connected ».** Le Makefile cherche `connected` : écran déverrouillé, câble bien enfoncé.
3. **`make device | tail` masque toute la sortie** jusqu'à la fin du pipeline — même famille que le `| tail` sur `make test`. Rediriger vers un fichier.
4. **Un `Set` dans un `Binding` ternaire ne compile pas** : `insert` rend un tuple, `remove` un optionnel. Écrire un `if/else`.
5. **`git stash` n'emporte pas les fichiers non suivis** sans `-u` : un fichier de journal tout neuf se perd au changement de branche.

## Ce qui reste à faire

1. **Vérifier au doigt ce qu'aucun test ne prouve** : les zones tactiles des boutons « Tout cocher » (en-tête de saison et d'année), le retour haptique sur un podcast et sur le dernier épisode d'une série.
2. **Radio France** (PR 34 de la tranche Podcasts) : cinq minutes d'inscription gratuite à Podcast Index côté founder.
3. **Le seed DEBUG** (PR 35) : il ne crée ni saison, ni épisode, ni podcast.
4. Signature de l'app : renouvelée le 01/10, prochaine échéance **~08/10**.
