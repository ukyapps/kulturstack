---
type: journal
dates: 2026-09-27 (après-midi et soirée)
statut: les huit retours traités en sept PRs (#38 → #45) ; tranche suivante tranchée — les podcasts
---

# Session 18 — Huit retours d'usage, sept correctifs

## Ce qui s'est passé

Trois jours d'usage des épisodes, **huit retours** d'un coup, plus les réponses aux deux questions que la Tranche 2 avait laissées ouvertes. Tout a été traité dans la journée : **sept PRs**, de la plus agaçante au quotidien à la plus confortable.

| PR | Ce qui change | État |
|---|---|---|
| #38 | La ligne du Journal répond sur **toute sa largeur** | ✅ |
| #39 | « J'ai vu toute la saison » et « Jusqu'ici » deviennent **visibles** ; l'appui long disparaît | ✅ |
| #40 | Les livres se cherchent dans leur **édition française** | ✅ |
| #42 | La fiche d'une série s'ouvre sur **« Prochain épisode »**, le `+` d'une série y mène | ✅ |
| #43 | Le ✓ **se voit et se sent** : barre animée, bouton qui s'enfonce, retour haptique | ✅ |
| #44 | Le prochain épisode **dans le Journal** aussi | ✅ |
| #45 | **« Je le commence »** sur une fiche | ouverte |
| #41 | Les huit retours consignés, mot pour mot | ✅ |

338 tests au début de la journée, **384 à la fin**. Couverture Domain 97 % · Data 95,5 % · Features 89,7 %.

## Les décisions de la journée

1. **L'onglet « En cours » reste en troisième position** — « oui c'est bien ». La question laissée ouverte par la PR 16 est close.
2. **Un geste caché n'existe pas.** L'appui long « tout cocher jusqu'ici » n'avait jamais été trouvé en trois jours. Il devient un bouton. C'est la **troisième fois** qu'un geste caché tombe, après l'appui long de l'Envie le 22/09 : dans cette app, ce qui ne se voit pas n'existe pas.
3. **« Je le commence » va sur la fiche**, pas dans la ligne de résultat — trois emplacements proposés, celui-là choisi.
4. **Logger une série ne veut plus dire la logger d'un bloc** : le `+` mène à ses épisodes. Une phrase du plan de la T2 s'est retournée contre lui — « les épisodes sont une option, pas un passage obligé » était vrai du *modèle*, pas du *geste* le plus court.
5. **Les podcasts passent avant l'import.** La founder les a demandés ; son historique Trakt ne va nulle part.

## Ce qu'on a appris

1. **`git fetch` avant de lire l'état du projet.** Le dépôt local était propre — et en retard de quatre heures. J'ai lu une photo périmée, refait une partie du travail de la #36 (fusionnée à 10h04), et ouvert une PR en conflit qu'il a fallu fermer. **`gh pr list --state open` ne protège pas de ça** : une PR *fusionnée* n'y apparaît pas. C'est la garde-fou du 24/09 qui montre sa limite.

2. **SwiftUI ne laisse pas observer une zone tactile depuis un test.** Un `UIHostingController` n'expose **qu'une seule `UIView` opaque** : `hitTest` y renvoie la même vue avec et sans `contentShape`. Un premier test écrit là-dessus passait **avant** la correction — il ne testait rien, il a été jeté. Ce qui est observable, c'est le **type du corps de la vue** (`String(describing: type(of: view.body))`), qui porte la liste de ses modificateurs. Compromis assumé : si Apple renomme `_ContentShapeModifier`, le test casse **bruyamment**.

3. **Le squash rend une PR empilée incompatible.** La #42 était basée sur la branche de la #39. Une fois la #39 écrasée en un commit sur `main`, git voyait les mêmes changements écrits deux fois : conflit. La sortie est un `rebase --onto origin/main <ancienne base> <branche>`, qui ne rejoue que le travail propre à la PR. **Empiler reste la bonne réponse quand deux PRs touchent les mêmes fichiers** — il faut juste savoir rebaser après la fusion de la base.

4. **Interroger l'API avant de répondre, encore.** « Les livres c'est bizarre » avait l'air d'un problème de classement. C'en était un de **champ** : OpenLibrary rend le titre de l'œuvre *originale* (`海辺のカフカ`), et le titre français vit dans la sous-requête `editions`, qu'il faut demander explicitement. Trois requêtes sur l'API réelle ont donné la réponse en cinq minutes — et prouvé que le repli sans filtre est **nécessaire** (`refactoring martin fowler language:fre` : 0 résultat ; sans filtre : 11).

5. **Un test de rendu ne prouve une animation ni un haptique.** Ce qui est testable, c'est la **donnée** qui les déclenche (la fraction de la barre) et le fait que deux états rendent deux images différentes. Le reste se juge sur l'appareil, et c'est écrit tel quel dans les PRs plutôt que maquillé.

## Pièges

1. `#expect(x.allSatisfy(\.isWatched))` ne compile pas : dans la macro, le key path rend l'appel *rethrows* ambigu. `allSatisfy { $0.isWatched }` passe.
2. `#require` **imbriqué** dans un autre `#require` : « recursive expansion of macro ». Deux lignes au lieu d'une.
3. Ajouter des tests « à la fin du fichier » par script les met dans la **dernière** structure du fichier, pas dans la structure de tests, quand le fichier se termine par un stub (`FailingMediaRepository`). Le compilateur le dit (« cannot find 'makeEmpty' in scope »), mais il faut le lire.
4. Un harnais de capture qui rend une vue **dans un `NavigationStack`** hors écran ne déclenche pas ses `.task` : la capture montre le rond qui tourne. Rendre la vue **sans** pile de navigation.
5. `WatchStatusUseCase.status(of:)` est `@MainActor` : un modèle de ligne (`struct`, non isolé) ne peut pas l'appeler. Les lectures pures sur le modèle se marquent `nonisolated static`, comme `InProgressUseCase.next`.

## Ce qui reste à faire

- **Fusionner #45**.
- **La Tranche des podcasts** : plan écrit dans `docs/plans/podcasts.md`, et **une question ouverte** — comment couvrir Radio France, dont Apple ne donne pas les flux.
- La dette de documentation des § 3 et § 4 de l'état du projet (arborescence et inventaire des tests) : rattrapée par la #36 pour la T2, à re-vérifier après cette série de correctifs.
- Signature de l'app à renouveler vers le **01/10** : iPhone branché, `make device`.
