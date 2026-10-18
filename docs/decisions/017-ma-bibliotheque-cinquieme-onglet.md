# ADR-017 — « Ma bibliothèque » prend un cinquième onglet

- Statut : **accepted**
- Date : 2026-10-17
- Contexte : tranche Bibliothèque (T5 du PRD, avancée). Met en œuvre l'[ADR-010](010-collection-possessions.md), qui décrivait `OwnedCopy` sans trancher son ergonomie — « à concevoir plus tard ». C'est plus tard.

## Ce qui a déclenché la décision

La founder, le 17/10, une heure après la livraison de la recherche de disques :

> « les disques, je les écoute pas, je les ai dans ma bibliothèque. d'ailleurs sur les livres, rajoute une option sur j'ai dans ma bibliothèque »

**Elle corrige une prémisse, pas un détail.** La tranche Disques avait été construite sur « un disque se logge comme un film » ([ADR-016](016-disques-par-apple-pas-discogs.md), plan `docs/plans/disques.md`). Pour elle, un disque n'est pas une séance qu'on journalise : c'est un **objet qu'on possède**. Et le même besoin existe pour les livres, qu'elle lit *et* possède.

C'est exactement la deuxième relation que l'ADR-010 avait dessinée le 20/09 et rangée en T5. L'usage l'a rappelée onze mois de travail plus tôt que prévu — enfin, trois semaines.

## Décision

### 1. Un cinquième onglet, contre ma recommandation

Trois dispositions lui ont été proposées avec leurs maquettes : un **segment dans l'onglet Envie** (ma reco), un **cinquième onglet**, un **filtre dans le Journal**. Elle a choisi le cinquième onglet, en sachant que l'option disait noir sur blanc qu'il **inverse son verdict du 27/09** (« l'onglet En cours reste troisième, la barre ne bouge plus »).

La barre devient : **Journal · Envie · En cours · Bibliothèque · Recherche**.

> **C'est la première fois qu'elle ne replie pas une information dans un écran existant.** Quatre fois sur quatre auparavant — chip → onglet Envie (22/09), bandeau → onglet En cours (24/09), geste caché → bouton visible (27/09), bandeau → l'onglet existant (01/10) — elle avait pris l'écran qui existait déjà. La règle qu'on en avait tirée (« quand une information a déjà un écran qui lui va, elle n'a pas besoin du sien ») **tient toujours** : ici, aucun écran existant ne lui allait. Le Journal liste des **logs**, et un disque possédé jamais écouté n'a pas de log. Ce n'est pas une vue dérivée, c'est une autre relation à l'œuvre.

Conséquence assumée : à cinq onglets, les libellés rétrécissent et l'icône porte davantage. À rouvrir si la barre devient illisible à l'usage.

### 2. Ce qui se possède, et ce qui ne se possède pas

`MediaKind.canBeOwned` : **films, séries, livres, disques, jeux** — ce qui s'achète et se range sur une étagère. **Pas** les podcasts, concerts, pièces et expos. Le modèle le **refuse** (`DomainError.ownershipNotAllowed`) plutôt que de l'autoriser en silence, et la fiche n'affichera pas le bouton. Même forme que `allowedStatuses` et `hasEpisodes`, qui bornent déjà ce qu'un type accepte.

### 3. Le format reste vide tant que rien ne le demande

L'ADR-010 donnait `format: String` obligatoire (vinyl, cd, dvd, paperback…). Il devient **optionnel** : elle a demandé « j'ai dans ma bibliothèque », pas « j'ai en vinyle ». Le champ existe, `editionRef`, `acquiredAt` et `notes` aussi, et **une œuvre peut déjà porter plusieurs exemplaires** — le vinyle et le CD sont deux lignes. Mais rien ne les demande à l'écran avant qu'elle les réclame.

C'est la règle « une part utilisable maintenant » : le modèle complet, l'interface minimale. Ajouter un sélecteur de format qu'elle n'a pas demandé, c'est ajouter du code non testé à l'usage.

### 4. Schéma V4, migration légère

`OwnedCopy` est un nouveau modèle, plus un lien optionnel depuis `MediaItem` : **étage lightweight**, aucune ligne existante réécrite. T-01 gagne son troisième étage — un store V3 **peuplé** (podcast, épisodes cochés, logs notés) rouvert avec le plan V4, tout intact, bibliothèque vide.

**La migration se vérifie sur l'iPhone avant fusion**, procédure du 24/09 : sauvegarde du store, comparaison ligne à ligne. C'est la première depuis le 27/09.

## Conséquences

- **La tranche Disques ne devient pas inutile** : on ne peut pas dire « je l'ai » d'une œuvre qu'on ne sait pas trouver. La recherche, la fiche et la dédup de la PR 37 sont la fondation. Ce qui change, c'est **l'action mise en avant** sur une fiche de disque — et ça se décide à l'usage, pas sur le papier.
- L'**ADR-016** et `docs/plans/disques.md` portent une prémisse à amender : « un disque se logge comme un film » n'est pas ce qu'elle fait. À corriger une fois la PR 37 fusionnée, pour ne pas écrire sur une branche ouverte.
- La question d'ergonomie n° 9 du design (« où va la Bibliothèque ») est **close**.
- **Discogs redevient pertinent**, et c'est exactement ce que l'ADR-016 annonçait : quand elle voudra le format et l'édition, son catalogue de pressages est irremplaçable, et un token s'y justifie.
- Rien ne change pour les logs : les deux relations ne se parlent pas.

## Écartées

- **Un segment dans l'onglet Envie** (ma reco) : zéro onglet de plus, mais Envie veut dire « je voudrais », pas « je l'ai ». Elle a tranché contre.
- **Un filtre dans le Journal** : le Journal est bâti sur les logs ; un disque possédé jamais écouté n'y a aucune ligne. Il aurait fallu mélanger deux choses différentes dans un même écran.
- **Un booléen `isOwned` sur `MediaItem`** plutôt qu'une entité : moins cher d'une ligne aujourd'hui, et impossible à faire porter un format, une édition ou une date d'acquisition demain. L'ADR-010 avait déjà écarté ce raccourci.
