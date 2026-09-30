---
type: plan
tranche: Nouvelles saisons (hors PRD — née d'une question de la founder le 30/09)
statut: proposé — à valider avant d'écrire une ligne
créé: 2026-09-30
---

# Plan — Une saison qui sort revient dans « En cours »

**Objectif** : quand une série que tu as finie publie une nouvelle saison, elle **réapparaît toute seule dans « En cours »**, avec « Prochain : S3 E1 ». Rien de nouveau à regarder, rien à installer, aucune permission.

## Ce qui a déclenché ce plan

> « On est d'accord que c'est un flux et ça s'update quand y'a une nouvelle saison de série qui arrive ? » — puis, sur ma proposition de bandeau : « pourquoi tu veux faire un bandeau ? c'est pas dans suivi que ça apparaît juste quand y'a une suite ? »

**Elle a raison et ma première proposition était plus compliquée que nécessaire.** J'avais proposé un bandeau « du nouveau » en haut de l'onglet — un deuxième endroit à consulter, pour une information qui a déjà son écran. Le plan retenu est le sien : **pas de bandeau**, l'onglet existant suffit.

Écarté au passage, et dit tel quel : une **notification** demanderait que iOS réveille l'app quand elle est fermée. Il le fait quand ça l'arrange — parfois le jour même, parfois jamais. Une notification fiable passe par un serveur, c'est la Tranche 6. Founder : le rafraîchissement à l'ouverture.

## Les deux choses qui bloquent aujourd'hui

| | Ce qui se passe | Pourquoi |
|---|---|---|
| Une série **terminée** ne revient jamais dans « En cours » | `InProgressUseCase.items()` ne garde que les œuvres dont le **dernier log de statut** dit « en cours ». Une série finie en est exclue, même avec une saison en attente. | La règle date de la T2, quand « terminé » voulait dire « je n'y reviens plus ». |
| L'app **n'apprend** qu'une saison est sortie **qu'en ouvrant la fiche** | Depuis la #59, la fiche range le nombre de saisons à jour — mais c'est le seul endroit qui interroge TMDB. | Et c'est précisément la fiche qu'on n'ouvre pas quand on croit la série finie. |

## Périmètre

**Dedans** : les **séries**. Un rafraîchissement au lancement de l'app, et une série terminée qui a du nouveau qui retourne dans « En cours ».

**Dehors, et pourquoi** :
- **Les podcasts** — leur fiche charge le flux à chaque ouverture, et un podcast n'a pas de « nouvelle saison ». Ils ont déjà leur ligne dans « En cours » (#63).
- **Les notifications** et le réveil en tâche de fond : voir plus haut, ça demande le serveur de la T6.
- **Les livres, films, disques** : rien ne « sort » après coup.
- **Un écran « Nouveautés »** : c'est exactement ce que sa question a écarté.

---

## PR 41 — Une série finie qui a du nouveau revient dans « En cours » `feat/retour-dans-en-cours`

**Livre** : la règle, sans aucun appel réseau — testable seule, et utile même sans la PR 42 pour les séries dont la fiche a déjà été rouverte.

- `InProgressUseCase.items()` garde en plus les séries **terminées** dont il reste une saison connue et non vue (`nextUp` répond quelque chose alors que le statut dit « terminé »).
- **Une série abandonnée ne revient pas** : abandonner est un choix explicite, une saison de plus ne le défait pas.
- La ligne dit ce qu'elle a toujours dit : « Prochain : S3 E1 ». Rien de neuf à apprendre.
- Tests : série finie + saison connue non vue → listée ; série finie sans rien de plus → absente ; série abandonnée avec une saison en attente → absente ; série en cours → inchangée.

**Démo** : marquer une série terminée, ouvrir sa fiche sur une saison suivante, elle est de retour dans l'onglet.

## PR 42 — Réapprendre les saisons au lancement `feat/rafraichir-au-lancement`

**Livre** : ce qui fait qu'on n'a **pas** besoin d'ouvrir la fiche.

- Au lancement, en tâche de fond, on redemande à TMDB le nombre de saisons des séries **suivies** — en cours ou terminées, jamais abandonnées.
- **Au plus une fois par jour**, et **20 séries au maximum** par passage, les plus récemment touchées d'abord. Une panne réseau ne se voit pas : l'app s'ouvre pareil.
- Rien ne bloque l'écran : le Journal s'affiche, la liste se met à jour quand la réponse arrive.
- Tests : deux lancements le même jour → un seul passage ; hors ligne → rien ne casse et rien n'est écrasé ; une série abandonnée n'est pas interrogée ; le plafond est respecté ; une saison de plus fait réapparaître la série dans « En cours » (le bout à bout avec la PR 41).

**Démo** : une série terminée dont TMDB annonce une saison de plus se retrouve dans « En cours » **sans avoir ouvert sa fiche**.

---

## Ordre et estimation

```
PR41 → PR42
```

**2 PRs, 1 à 2 jours.** La PR 41 seule apporte déjà quelque chose ; la PR 42 est ce qui rend l'ensemble automatique. Rien ne se ferme à une date.

## Ce qu'on vérifie avant de dire « shippé »

- [ ] Une série **abandonnée** ne revient jamais, même avec trois saisons en attente.
- [ ] Deux lancements dans la même journée ne font **qu'un** passage réseau.
- [ ] Hors ligne, l'app s'ouvre normalement et **aucun compte de saisons n'est écrasé**.
- [ ] Le nombre d'appels au lancement est **plafonné** et mesuré, pas supposé.
- [ ] Coverage ≥ 70 % Domain et Data, ≥ 50 % Features.
- [ ] Aucune string en dur, FR + EN dans la même PR.
- [ ] Aucun changement de schéma — donc aucune migration.

## Ce que ce plan ne résout pas

L'app ne te prévient **pas** quand tu ne l'ouvres pas. Si la vraie demande devient « je veux le savoir sans ouvrir l'app », c'est une notification, donc un serveur, donc la Tranche 6 — et ça se rouvre à ce moment-là, pas en douce ici.
