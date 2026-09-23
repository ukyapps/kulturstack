---
type: journal
dates: 2026-09-23 (soir)
statut: 5 PRs de correction (#18 → #22) — les 7 retours du premier usage réel sont traités
---

# Session 15 — Les premiers retours d'usage (PR #18 → #22)

## Ce qui s'est passé

La founder a utilisé l'app sur son iPhone pendant deux jours, puis a envoyé **sept retours d'un coup**. Tous sont notés mot pour mot dans `docs/product/retours-utilisateurs.md`. Cette session ne fait qu'une chose : les traiter, une PR par sujet.

| PR | Retour | Ce qui a changé |
|---|---|---|
| #18 | « J'ai log la planète sauvage, ça n'apparaît pas dans mon journal » + « un tap devrait ouvrir la fiche » | Le Journal s'ouvre sur **Tout** (segments Tout · Semaine · Mois · Année) ; tap sur une ligne = la fiche ; modifier passe à l'appui long. Même geste dans Envie. |
| #19 | « À la place de la date en petit, je voudrais un aperçu du commentaire » | La ligne montre les deux premières lignes du commentaire ; la date reste l'en-tête du jour. |
| #20 | « La date oui, mais pas l'heure, c'est un peu abusé » + « Logger depuis la fiche devrait ouvrir le log avec les notes » | Sélecteur de date au jour près ; « Logger » ouvre le formulaire et **n'écrit rien avant « Enregistrer »**. |
| #21 | « Si je mets wes anderson, je n'ai pas tous les films de Wes Anderson » | Une personne reconnue par TMDB ramène sa filmographie, filtrée par son métier. |
| #22 | « On peut enregistrer les trucs en double, on devrait pas » | Le `+` d'une œuvre déjà loggée demande confirmation en rappelant la date. |

Le septième retour (« la recherche par auteur marche pour les livres ») ne demandait rien : OpenLibrary cherche nativement dans les auteurs.

195 tests au début de la session, **215 à la fin**.

## Ce qu'on a appris

1. **Le bug n° 1 n'était pas un bug.** « La Planète sauvage » était bien en base, avec sa date et son commentaire : le Journal s'ouvrait filtré sur *Semaine* et le log était daté avant. Un filtre par défaut qui cache sans le dire coûte plus cher qu'il ne rapporte. D'où l'ouverture sur *Tout*.

2. **L'usage a inversé une décision vieille d'un jour.** Le 22/09, la founder avait choisi « tap sur une ligne du Journal = modifier ». Après deux jours d'usage : « je voudrais que ça ouvre la fiche » — le geste d'origine du design. C'est sain, et c'est tracé dans `design.md` §6.6 et question 6 : on garde l'historique des allers-retours, pas seulement la dernière position.

3. **Interroger la vraie API avant d'écrire les fixtures.** Pour la recherche par personne, `combined_credits` mélange tout ce à quoi quelqu'un a touché : sans filtre, « wes anderson » sortait **Tous en scène 2 en deuxième position** (il y double un personnage). Les fixtures écrites de mémoire n'auraient jamais montré ça. Le filtre par `known_for_department` (Directing → job Director, Acting → cast) est né de cette vérification.

4. **Les homonymes sont un vrai risque.** La fixture réelle « dune » contient cinq personnes nommées Dune. Chercher une filmographie dès qu'une personne apparaît aurait injecté leurs films dans une recherche de titre. D'où la règle : seulement si TMDB met la personne dans les **trois premiers** résultats.

5. **Rien n'est écrit avant « Enregistrer ».** Pour « Logger » depuis la fiche, la solution facile (créer le log puis ouvrir la feuille) laissait un log derrière en cas d'Annuler. Le formulaire sait maintenant viser une fiche **ou un candidat pas encore en base**, et n'écrit qu'à la validation.

## Pièges

1. `build/DerivedData` contenait un binaire périmé : l'app installée sur le simulateur n'était pas celle qu'on venait de compiler (segments dans l'ancien ordre sur la capture). Toujours construire avec un `-derivedDataPath` explicite avant d'installer.
2. Pour semer le simulateur sans passer par l'interface : `ModelContainerFactory.onDisk(url:)` dans un test jetable, puis copier le `.store` dans `Library/Application Support/Kulturstack.store` du conteneur (`xcrun simctl get_app_container`). Ouvrir un deuxième `ModelContainer` sur le store de production depuis un test fait planter l'app hôte.
3. `window.drawHierarchy(afterScreenUpdates:)` rend une image blanche dans un test ; `window.layer.render(in:)` après quelques tours de `RunLoop` fonctionne.
4. **Les PRs empilées coûtent cher quand la founder fusionne vite.** Trois PRs ont touché la même ligne (« ## 4. Tests — N ») : deux rebases `--onto` pour rattraper. Si deux PRs se suivent dans la même session, soit on empile dès le départ, soit on ne touche pas au compteur.

## Ce qui n'a pas été fait

- **Aucune capture pour #21 et #22** : il faut taper dans l'app pour les déclencher, et le simulateur ne se pilote pas au clavier depuis un script. Les deux PRs disent pourquoi et donnent le texte exact à la place.
- La question « faut-il aussi confirmer un double log depuis la fiche ? » est tranchée non : le bouton s'appelle « Logger à nouveau » et ouvre un formulaire, la confirmation ferait doublon.

## À faire — founder

- [ ] Fusionner **#22** (les doublons), puis **#23** (cette page).
- [ ] Fusionner **#17** — *toujours ouverte*, elle apporte `make device` pour réinstaller l'app quand la signature de 7 jours expire (vers le 30/09). Elle réécrit aussi le § 1 de l'état du projet.
- [ ] Réserver `kulturstack.com` + `kulturstack.app`.
- [ ] Continuer à utiliser l'app et noter ce qui coince.

## À faire — prochaine session Claude

1. **Rafraîchir `docs/etat-du-projet.md` § 1 et § 8** — à faire une fois #17 fusionnée, sinon conflit garanti : nombre de PRs, 215 tests, et remplacer « reprendre le jalon iPhone » (fait) par l'état réel.
2. Demander à la founder ce que **deux jours de plus** ont donné, et l'écrire dans `retours-utilisateurs.md` avant de coder quoi que ce soit.
3. Seulement ensuite : écrire `docs/plans/tranche-2.md` (épisodes de séries — saisons, « où j'en suis », statuts en cours / abandonné).
4. Si l'app ne s'ouvre plus sur l'iPhone : la signature personnelle a expiré. iPhone branché et déverrouillé, puis `make device` (disponible après #17).
