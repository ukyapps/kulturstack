---
type: journal
date: 2026-09-24 (soir) → 2026-09-27
prs: "#33, #34, #35"
---

# Fin de la Tranche 2 — les épisodes, du schéma à l'onglet

Trois PRs, trois jours, et la Tranche 2 est livrée. On était parti sur cinq PRs estimées à « 2 à 3 semaines part-time » : il en aura fallu **quatre jours calendaires** (24 → 27/09), parce que les PR 12 et 13 avaient déjà posé la fondation la veille et que les trois dernières se sont enchaînées sans surprise de modèle.

## Ce qui a été livré

| PR | Ce que ça fait | Fusionnée |
|---|---|---|
| 14 | Cocher un épisode : saisons dépliables sur la fiche, une case par épisode, « tout cocher jusqu'ici » | #33, 24/09 |
| 15 | Statuts : en cours automatique, proposition de « terminé », abandonner / reprendre | #34, 25/09 |
| 16 | Onglet « En cours » : progression, prochain épisode, ✓ qui avance sans ouvrir la fiche | #35, 27/09 |

**338 tests verts** (415 exécutions), 0 échec. Couverture : Domain 97 %, Data 95 %, Features 88 %, DesignSystem 86 %.

## Le rythme, et ce qu'il a coûté

Le 24/09 à 21h41, j'ai recommandé d'arrêter plutôt que d'entamer la PR 14 — une grosse journée, coupée en deux au milieu. La founder a répondu « lançons ». On a fait le **bloc invisible** ce soir-là (`EpisodeRepository`, `EpisodeUseCase`, `Episode.isWatched`), l'écran le lendemain. Le découpage a tenu : le commit de 22h ne contenait aucune interface, celui du lendemain n'a rien eu à défaire.

Leçon gardée : proposer l'arrêt **une fois**, avec ce que ça coûte et une option intermédiaire, puis suivre sa décision sans y revenir. Le garde-fou burn-out du CLAUDE.md reste, mais c'est un garde-fou, pas un veto.

## Trois choses apprises

### 1. Un test de rendu qui ne peut pas échouer n'est pas un filet

Les tests de rendu de la Tranche 1 se contentaient de `#expect(host.view.bounds.height > 0)`. En écrivant la PR 14, ça a laissé passer une `SeasonsSection` qui rendait « Aucune saison » au lieu de la liste : la clé externe de l'œuvre de test (`tmdb:tv:9`) ne correspondait pas à celle du stub (`tmdb:tv:95396`), donc le provider ne répondait jamais. Vert, et ne prouvant rien.

Les tests de rendu comparent maintenant les **images entre elles** :

```swift
#expect(Set(shots).count == 3)   // vide ≠ erreur ≠ liste
```

Ça tient directement la règle « trois rendus distincts » du CLAUDE.md : deux états qui donnent le même pixel ne sont pas deux états. C'est ce test-là qui a attrapé le bug, pas la relecture.

### 2. Comment faire des captures quand le simulateur ne se pilote pas

Le CLAUDE.md demande les captures vide **et** rempli dans chaque PR. Or tout écran qui demande un tap (déplier une saison, cocher un épisode) est hors de portée de `xcrun simctl io booted screenshot`.

La méthode retenue : un fichier `KulturstackTests/Features/CaptureHarness.swift` **temporaire**, lancé par `make test`, **supprimé avant le commit**. Il rend les vraies vues dans une `UIWindow` de 393 × 852 points et écrit des PNG dans `docs/captures/t2-pr-NN/` (le préfixe de tranche évite la collision avec les `pr-14` de la Tranche 1).

Deux pièges, un aller-retour chacun :

- `window.drawHierarchy(in:afterScreenUpdates:)` rend **blanc** hors écran. Utiliser `window.layer.render(in:)`.
- **Un `NavigationStack` hors écran ne déclenche pas les `.task` de son contenu** : la vue reste sur son rond qui tourne, quelle que soit l'attente. Il faut rendre la vue sans sa pile de navigation — au prix de la barre de titre, ce qui se signale dans la PR. `InProgressViewRenderingTests` le documente en commentaire pour la prochaine fois.

### 3. Une feature peut en salir une autre à distance

La PR 14 a introduit un effet de bord que personne n'avait prévu : un épisode coché est un `LogEntry`, donc **chaque épisode coché créait une ligne dans le Journal**. Une saison de dix épisodes suivie, c'était dix lignes « Severance » identiques — et la même chose dans « Tes logs » sur la fiche.

Trouvé en relisant ce que la PR 14 avait produit, avant que l'usage ne le trouve. Corrigé dans la PR 15 : le Journal et la fiche filtrent les logs qui portent un épisode. Ce qui apparaît dans le Journal, c'est le **statut de l'œuvre**, une fois. Trois tests tiennent la règle.

## Les décisions prises en chemin

- **`source` porte l'automatique.** Un statut posé par l'app (`"episodes"`) se distingue d'un statut dit à la main (`"manual"`). C'est ce qui permet de reprendre le « en cours » quand on décoche tout, **sans** annuler un « abandonnée » explicite. Le champ existait depuis la V1 : aucun changement de schéma, aucune migration sur toute la tranche.
- **Une série finie qui repart revient en cours.** Saison 1 terminée, saison 2 qui sort, un épisode coché après coup → la série repasse en cours. Sans cette règle, l'onglet « En cours » ne l'aurait jamais vue revenir. C'est exactement le cas Severance qui a déclenché la tranche.
- **Le ✓ de l'onglet coche une seule chose : la suite.** Il ne comble pas les trous derrière. Si E1 et E3 sont vus, la suite est **E2**. « Tout cocher jusqu'ici » existe sur la fiche pour l'autre besoin.
- **Le prochain épisode ne vient que des saisons déjà ouvertes.** L'onglet ne va pas sur le réseau : il ferait sinon dix appels à son ouverture. En pratique on coche depuis la fiche, donc la saison courante est en cache.

## Ce qui reste ouvert, à regarder sur l'iPhone

1. **La place de l'onglet dans la barre.** Mis en **troisième** (Journal · Envie · En cours · Recherche), conformément au plan, pour ne déplacer ni Journal ni Envie. Si « En cours » devient ce qu'on ouvre le soir, il a sa place en deuxième. Une ligne à changer — design § 6, q. 7.
2. **« Tout cocher jusqu'ici » est derrière un appui long.** C'est l'idiome iOS et ça n'encombre pas la ligne, mais ça ne se devine pas. Si la founder ne le trouve pas seule à l'usage, le rendre visible.
3. **Pas de « p. 212 sur 480 » pour les livres.** Le modèle ne sait pas où on en est dans un livre : il faudrait un champ de page courante, donc un `SchemaV3` et une migration. Un livre en cours montre son type et se termine d'un tap. À rouvrir si ça manque.

## La suite

La Tranche 2 est close. Avant d'ouvrir la Tranche 3 (import du passé), **utiliser l'app quelques jours et noter ce qui coince** — le 23/09 a montré ce que ça vaut : sept retours, cinq corrections, dont un « bug » qui n'en était pas un. La signature personnelle expire vers le **01/10** : `make device`, iPhone branché.
