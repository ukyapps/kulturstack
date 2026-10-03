# ADR-014 — Les flux de Radio France se lisent dans leur page, pas dans un deuxième index

- Statut : **accepted**
- Date : 2026-10-03
- Contexte : tranche Podcasts, PR 34. Remplace le point 5 de l'[ADR-013](013-sources-des-podcasts.md).

## Contexte

L'ADR-013 laissait un trou nommé : **Apple ne publie pas le flux RSS des podcasts de Radio France**. Mesuré le 27/09 sur dix podcasts de France Inter et France Culture, dix sans `feedUrl`, ni par `search`, ni par `lookup`. Ces podcasts se cherchent et se loggent, mais **sans liste d'épisodes**.

La piste retenue alors était **Podcast Index** : un index ouvert des flux, avec un endpoint « donne-moi le flux de ce podcast Apple ». Inscription gratuite, clé au Trousseau comme TMDB. Coût : **cinq minutes de la founder** avant toute ligne de code, une clé de plus à maintenir, et une couverture **invérifiable tant que la clé n'est pas là** — l'API refuse toute requête sans elle.

Avant de demander ces cinq minutes, une autre piste a été mesurée le 03/10.

## Ce qui a été mesuré le 03/10

| Question | Mesure |
|---|---|
| La page d'un podcast Radio France déclare-t-elle son flux ? | **Oui.** Une balise `<link rel="alternate" type="application/rss+xml">` dans son `<head>` — celle que lit n'importe quel lecteur de podcasts. Une seule par page, aucune ambiguïté. |
| Peut-on retrouver la page depuis un résultat Apple ? | **Oui, dans 23 cas sur 24.** L'adresse se déduit du producteur (`artistName` → `franceinter`) et du titre (`collectionName` → `le-code-a-change`). |
| Combien d'essais ? | **21 des 23 du premier coup.** Deux ont demandé une variante : « Les Matins de France Culture » → `les-matins`, « Les Grandes Traversées » → `grandes-traversees`. Aucun n'a demandé un quatrième essai. |
| Le cas qui rate ? | « Le meilleur de l'histoire », une compilation de 26 épisodes qui n'existe que chez Apple : **aucune page Radio France**. |
| Les autres stations ? | France Musique 5/6, franceinfo 4/6, FIP 2/3, Mouv' 2/6. **ICI (ex-France Bleu) : 0/4** — ses podcasts vivent sur ici.fr, avec un autre découpage. |

## Décision

1. **Le flux d'un podcast Radio France se lit dans sa page**, par la balise `rel="alternate"` qu'elle publie pour les lecteurs de flux. Pas de deuxième API, **pas de clé, pas de compte, pas de secret**.
2. **Le résolveur part de la clé `itunes:<collectionId>`** que porte déjà tout podcast en base. Il demande son nom et son producteur à Apple (`lookup`, ~2 Ko), puis essaie **au plus trois adresses** de page. Conséquence voulue : ça marche aussi pour les podcasts **déjà loggés** avant cette PR, sans qu'il faille les rechercher.
3. **Il n'est appelé que quand le flux manque.** Un podcast dont Apple donne le flux porte une clé `feed:`, et `RSSEpisodeProvider` répond avant lui — il est le dernier des `episodeSources`. Un producteur hors Radio France ne fait charger **aucune page**.
4. **Une absence n'est pas une panne.** Une page qui n'existe pas (404) fait passer à l'orthographe suivante ; les trois épuisées, la fiche montre son état vide, qui dit déjà « son flux ne les donne pas ». **Toute autre panne remonte** et donne « Impossible de charger les épisodes ». Vide ≠ erreur, comme partout ailleurs.
5. **ICI (ex-France Bleu) n'est pas couvert**, et c'est écrit : ses podcasts sont sur un autre site, avec un autre découpage. Ils restent cherchables et loggables, sans liste d'épisodes.

## Conséquences

- **Zéro minute de la founder, zéro secret de plus.** Le point 4 de l'ADR-013 (« ni clé, ni compte, ni secret ») tient pour la tranche entière, Radio France comprise.
- **Un podcast Radio France coûte deux requêtes de plus à la première ouverture de sa fiche** : le `lookup` (2 Ko) et sa page (450 Ko). La réponse est retenue pour la session, absence comprise — sinon un podcast sans page la chercherait à chaque visite.
- **La fragilité est réelle et assumée** : si Radio France change la forme de ses adresses ou retire la balise, les épisodes disparaissent. La panne est **visible** (la fiche dit « Aucun épisode ») et se répare en une PR — le calcul d'adresse est une fonction pure, testée contre les 31 cas mesurés sur le vrai site. **Podcast Index reste le recours**, et l'ADR-013 en garde le mode d'emploi.
- Le résolveur ne lit **rien d'autre** que l'adresse du flux : pas de titre, pas de résumé, pas de contenu de page. Ce que Radio France publie pour les lecteurs de podcasts est lu par un lecteur de podcasts.

## Ce que ça corrige dans l'ADR-013

L'ADR-013 écartait cette piste en deux mots : « c'est du scraping, et **rien dans ce que rend Apple ne permet de remonter jusqu'à la page** ». La deuxième moitié était **fausse** : le producteur et le titre y suffisent, 23 fois sur 24. Elle n'avait pas été mesurée, seulement supposée.

## Alternatives écartées

- **Podcast Index** (la piste de l'ADR-013) : demande une inscription, une clé au Trousseau, un secret de plus dans le pipeline `make secrets`, et sa couverture de Radio France ne peut pas être vérifiée avant. Reste le recours si la page cesse de marcher.
- **L'API ouverte de Radio France** (openapi.radiofrance.fr) : demande elle aussi un compte et une clé, pour le même résultat.
- **Les deux ensemble** : deux sources à maintenir pour un podcast sur 24. Proposé à la founder le 03/10, écarté par elle.
- **Lire la page par morceaux** pour éviter les 450 Ko : radiofrance.fr n'honore pas l'en-tête `Range` (vérifié le 03/10, la réponse est la page entière), et `HTTPClient` rend un `Data`, pas un flux d'octets. À revoir si le poids devient un sujet.
