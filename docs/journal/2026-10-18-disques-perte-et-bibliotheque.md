---
type: journal
période: 2026-10-17 → 2026-10-18
PRs: #77, #78, #79, #80
---

# Les disques, une base perdue, et ce qu'on possède

Quatre PRs en deux jours, après deux semaines sans session. Et au milieu, la perte qu'on n'avait pas vue venir.

## 1. Les disques, mesurés avant d'être écrits (#77)

La founder, le 17/10 : « il manque encore pas mal de flux de données ». C'était exact — **4 types d'œuvres sur 9** se cherchaient. Trois sources ont été mesurées sur les vraies API avant d'écrire une ligne, et le tableau a décidé seul :

| Type | Source | Mesure |
|---|---|---|
| **Disques** | **Apple**, sans clé | **24/25**, pochette 600 px après réécriture de l'adresse |
| Disques | Discogs | répond sans token, mais **0 pochette sur 15 résultats** — les images demandent un compte |
| Jeux | Steam sans clé | **9/14**, et **0/4 sur les exclusivités Nintendo** — trou structurel |
| Jeux | IGDB | complet, mais **2 secrets** (Twitch) |
| Concerts | MusicBrainz | **6/15 réels**, deux faux positifs, **0 artiste francophone de taille moyenne** |

Le seul disque raté : **Stromae**, absent du catalogue Apple France, vérifié de trois façons. Trou de licence, écrit dans l'ADR-016 plutôt qu'enterré.

**Un piège de mesure, attrapé de justesse.** Ma première campagne a rendu **0/25** — et c'était faux : `urllib` est bloqué dans le sandbox, mes exceptions étaient avalées, et toutes les absences se ressemblaient. Refaite en `curl` : 24/25. *Une source muette ne prouve pas une absence* — même leçon que le 03/10, autre déguisement.

## 2. « Les disques, je les écoute pas »

Une heure après la fusion de la #77, la founder :

> « les disques, je les écoute pas, je les ai dans ma bibliothèque. d'ailleurs sur les livres, rajoute une option sur j'ai dans ma bibliothèque »

**Les chiffres étaient bons. La question était fausse.** L'ADR-016 avait comparé des sources pour répondre à « avec quoi logge-t-on *j'ai écouté cet album* ». Elle voulait « avec quoi dit-on *j'ai ce disque* ».

Aucune mesure supplémentaire n'aurait corrigé ça : aucune API ne dit ce qu'elle fait de ses disques. Ce qui manquait était une question d'une phrase, posée avant.

> **Avant de choisir une source pour un nouveau type d'œuvre, lui demander ce qu'elle en fait.** Le modèle le disait déjà, d'ailleurs : `MediaKind.album.hasDuration` valait `false` depuis la T1 — un disque ne se suit pas. Je ne l'ai pas lu comme un signal.

La #77 n'est pas perdue : on ne dit pas « je l'ai » d'une œuvre qu'on ne sait pas trouver. L'ADR-016 porte son amendement, le plan des disques est marqué livré, sa PR de seed abandonnée.

### Son choix d'écran, contre ma reco

Trois dispositions proposées avec maquettes. Elle a pris le **cinquième onglet**, en sachant que l'option disait qu'il **inverse son verdict du 27/09** (« la barre ne bouge plus »).

**Première fois sur cinq** qu'elle ne replie pas une information dans un écran existant. La règle tient quand même, et elle est plus claire maintenant : **le Journal est bâti sur les logs**, et un disque possédé jamais écouté n'en a aucun. Ce n'est pas une vue dérivée, c'est une autre relation à l'œuvre. ADR-017.

## 3. La base perdue (#79)

Le 18/10, iPhone branché pour vérifier la migration V4. L'app **n'était pas dans la liste des apps installées**. Réinstallée, lancée, base copiée : **0 œuvre, 0 log, 0 épisode**. Un store de 139 Ko, bien formé, vide.

Trois faits qui se combinent : la signature personnelle dure **7 jours**, la base ne vit **que** sur le téléphone, et **rien** ne la sauvegardait. Le rappel « réinstaller vers le 08/10 » était dans les docs — ce n'est pas une sauvegarde.

**Perdu** : le 28/09 → 08/10, soit la période des podcasts et des huit retours. **Récupéré** : la sauvegarde du 27/09, restaurée et vérifiée ligne à ligne (14 œuvres · 57 logs · 54 épisodes · 31 cochés, tuples identiques).

> **Une première comparaison a dit « identiques » en comparant deux fichiers vides** — la requête SQL échouait des deux côtés. Refaite avec un garde-fou qui refuse de conclure sur un résultat vide ou une requête en erreur. Le piège `#expect(height > 0)`, appliqué à ses vraies données.

La cause est traitée : un agent launchd sauvegarde la base **toutes les 30 minutes** dès que l'iPhone est branché. Deux décisions de conception :

- **Une base vide ne devient jamais « la dernière bonne sauvegarde »** : marquée `-VIDE`, code de sortie 2, le lien `derniere` ne bouge pas. Un script qui aurait écrasé le 27/09 par le vide aurait été pire que pas de script.
- **Les sauvegardes vivent dans `Application Support`, pas dans `~/Documents`** : macOS (TCC) interdit à un agent launchd d'y écrire, et la première version échouait en `Operation not permitted`, code 126. Trouvé en lisant le code de sortie de l'agent, pas en le croyant installé.

**12 tests couvrent les cas d'échec**, `xcrun` simulé, sans iPhone — c'est leur silence qui a coûté dix jours. Ils ont trouvé deux bugs, les deux dans le test : **`seq 1 0` rend « 1 0 » sur macOS**, donc la base « vide » du test contenait deux lignes et le cas qu'on voulait prouver n'était jamais joué.

## 4. Le schéma V4 et la bibliothèque (#78, #80)

`OwnedCopy` — la deuxième relation à l'œuvre, dessinée dans l'**ADR-010** le 20/09 et rangée en T5. L'usage l'a rappelée trois semaines plus tôt.

**La V3 n'a pas été recopiée à l'œil** : ses **41 propriétés stockées** ont été comparées une à une à `main`, attributs `.unique` et règles de suppression compris. **Migration vérifiée sur l'appareil**, ligne à ligne : 14 / 57 / 54 / 31 identiques, `ZOWNEDCOPY` absente avant et présente après — sans cette dernière vérification, j'aurais comparé la V3 à elle-même et annoncé un succès vide.

La PR #78 portait « **ne pas fusionner avant vérification** ». Elle a fusionné les trois d'affilée en 45 minutes. Aucun dégât — fusionner n'installe rien — mais l'ordre de sécurité ne tenait qu'à la chance.

> **Pour ce qui touche à ses données : faire la vérification d'abord, ouvrir la PR ensuite**, avec les chiffres avant/après déjà dedans. Une PR ouverte est une PR fusionnable. Lui reprocher de cliquer vite serait à côté : c'est à moi de ne pas tendre un bouton dangereux.

## 5. Quatre heures sur un crash, et la leçon qui les résume

Les tests de rendu de la bibliothèque plantaient avec pour seul message `Crash: Kulturstack at <external symbol>`. **Trois hypothèses, trois fois faux** : le type d'œuvre, l'absence de `NavigationStack`, la durée de vie du conteneur dans le test.

La réponse tenait en une ligne dans `~/Library/Logs/DiagnosticReports/Kulturstack-*.ips` :

```
SwiftDataMediaRepository.ownedItems()
LibraryViewModel.load()
closure #1 in LibraryView.body.getter
```

**Un écran rendu dans une fenêtre hors écran laisse derrière lui la tâche de son `task`**, qui interroge le dépôt plus tard — sur un conteneur déjà libéré. Et comme **Swift Testing lance les tests en parallèle**, cette tâche fantôme plantait **un autre test, choisi au hasard**. Deux innocents accusés avant de sérialiser les suites et de voir le coupable.

> **Aller chercher le rapport de crash au premier échec, pas au quatrième.** « Crash at external symbol » ne dit rien ; le `.ips` nomme la fonction.

Au passage : un `xcodebuild` direct **saute `xcodegen`**, donc un fichier neuf n'existe pas pour lui — d'où `make test`.

## Nettoyage trouvé en chemin

`FailingMediaRepository` vivait en **trois copies privées identiques**. Chaque méthode ajoutée au protocole les cassait toutes les trois — ce qui a fait échouer le build trois fois de suite. Une seule copie, dans `Support/`.

## Où ça en est

**621 tests, 713 exécutions, 0 échec.** Domain 98,2 % · Data 96,2 % · Features 89,4 %.

L'app tourne sur l'iPhone de la founder avec les disques, la bibliothèque et le schéma V4 — base restaurée, vérifiée, et sauvegardée toutes les 30 minutes.

## Ce qui reste à juger au doigt

1. Le bouton « Dans ma bibliothèque » **se voit-il assez** ? Troisième position, ligne à part, style discret.
2. La **barre à cinq onglets** reste-t-elle lisible ? C'était le risque annoncé dans l'ADR-017.
3. Le **retour haptique** à l'ajout et au retrait.
4. L'absence du bouton sur un podcast n'est **pas** tenue par une capture, seulement par `canBeOwned` et ses tests.

## Ce qui attend la founder

- **Utiliser l'app et noter ce qui coince** — c'est ce qui a donné toutes les vagues de correctifs.
- **Brancher l'iPhone de temps en temps** : la sauvegarde automatique n'a lieu que là. Trois semaines sans câble, et on reperd trois semaines. La parade suivante serait un **export JSON depuis les Réglages**, sans Mac.
- **Réinstaller avant le 25/10** : la signature dure 7 jours. Cette fois, la base est sauvegardée.
