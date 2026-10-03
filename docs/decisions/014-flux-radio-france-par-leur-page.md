# ADR-014 — Les flux de Radio France se lisent dans leur page, pas dans un deuxième index

- Statut : **accepted**
- Date : 2026-10-03
- Contexte : tranche Podcasts, PR 34. Remplace le point 5 de l'[ADR-013](013-sources-des-podcasts.md), et est **prolongé par l'[ADR-015](015-podcast-index-en-second-recours.md)**, qui va chercher ailleurs ce que la page ne donne pas (76 % → 97 %).

## Contexte

L'ADR-013 laissait un trou nommé : **Apple ne publie pas le flux RSS des podcasts de Radio France**. Mesuré le 27/09 sur dix podcasts de France Inter et France Culture, dix sans `feedUrl`, ni par `search`, ni par `lookup`. Ces podcasts se cherchent et se loggent, mais **sans liste d'épisodes**.

La piste retenue alors était **Podcast Index** : un index ouvert des flux, avec un endpoint « donne-moi le flux de ce podcast Apple ». Inscription gratuite, clé au Trousseau comme TMDB. Coût : **cinq minutes de la founder** avant toute ligne de code, une clé de plus à maintenir, et une couverture **invérifiable tant que la clé n'est pas là** — l'API refuse toute requête sans elle.

Avant de demander ces cinq minutes, une autre piste a été mesurée le 03/10.

## Ce qui a été mesuré le 03/10

| Question | Mesure |
|---|---|
| La page d'un podcast Radio France déclare-t-elle son flux ? | **Oui.** Une balise `<link rel="alternate" type="application/rss+xml">` dans son `<head>` — celle que lit n'importe quel lecteur de podcasts. Une seule par page, aucune ambiguïté. |
| Peut-on retrouver la page depuis un résultat Apple ? | **Oui, dans 76 % des cas.** L'adresse se déduit du producteur (`artistName` → `franceinter`) et du titre (`collectionName` → `le-code-a-change`). Chiffre mesuré sur un **échantillon aléatoire de 106 podcasts** tiré des **514** que Radio France publie chez Apple sans flux. |
| Combien d'essais ? | **Trois au plus**, et la grande majorité du premier coup. Deux variantes suffisent aux cas tordus : « Les Matins de France Culture » → `les-matins`, « Les Grandes Traversées » → `grandes-traversees`. |
| Ça marche pour quoi ? | Les **émissions**. Affaires sensibles, Le code a changé, Les Pieds sur terre, LSD, Le Cours de l'histoire : toutes retrouvées. |
| Ça rate pour quoi ? | Les **chroniques, billets et mixes** — « Le Billet de Thomas Poitevin », « L'édito politique VSD », « Mouv' DJ : Guest ». Deux causes mesurées : soit la page n'existe pas (compilations propres à Apple), soit **elle existe et ne déclare aucun flux** (« L'instant M », « Le pas de côté » : page correcte, zéro balise RSS). Le deuxième cas n'est **pas réparable par du code**. |
| Les autres stations ? | **ICI (ex-France Bleu) : 0** — ses podcasts vivent sur ici.fr, avec un autre découpage, et ne sont pas couverts. |

Le détail par station, sur le même échantillon :

| Station | Testés | Retrouvés |
|---|---|---|
| FIP | 8 | 8 (100 %) |
| France Musique | 15 | 14 (93 %) |
| franceinfo | 15 | 13 (87 %) |
| France Culture | 30 | 23 (77 %) |
| France Inter | 30 | 20 (67 %) |
| Mouv' | 8 | 3 (38 %) |
| **Total** | **106** | **81 (76 %)** |

**Les 25 qui restent, classés le 03/10 après la question de la founder (« je veux qu'on vise les 100 % »)** :

| Cause | Nombre | Récupérable ? |
|---|---|---|
| La page existe et **ne déclare aucun flux RSS** (« L'instant M », « Le pas de côté ») | 8 | Pas par cette source — il n'y a rien à lire sur la page. |
| L'adresse de la page ne se déduit pas du titre Apple (« Théâtre », « Les journaux de France Culture ») | 17 | Pas par cette source — il faudrait un **index des pages** de Radio France. |

> **Correction du 03/10, le soir même.** J'avais écrit ici que les 8 premiers « ne se récupéreront jamais, un flux que Radio France ne publie pas n'existe nulle part ». **C'était faux, et déduit au lieu d'être vérifié** : la page ne déclare pas le flux, mais le flux existe et **Podcast Index en a 7 sur 8**. Mesuré une fois la clé de la founder en main. Ne jamais conclure « ça n'existe pas » depuis « cette source ne l'a pas » — voir la section suivante.

> **Construire cet index est exclu.** Le `robots.txt` de radiofrance.fr interdit explicitement « scraping, crawling, or systematic extraction of content ». Lire **une** page quand l'utilisatrice ouvre **une** fiche, pour y prendre le lien de flux que Radio France publie à destination des lecteurs de podcasts, reste ce que fait n'importe quelle application de podcast. Parcourir leur sitemap pour s'en faire une table, non. **Le plafond de cette source est donc 76 %**, et ce qui manque ne se comblera, s'il se comble, que par une autre source.

> **Une première mesure annonçait « 23 sur 24 ».** Elle portait sur les 24 premiers résultats d'Apple pour « france inter » et « france culture » — c'est-à-dire les podcasts les plus connus, qui ont tous une page. Le chiffre était juste pour eux et **faux pour le catalogue**. Corrigé le 03/10 après la question de la founder : « tous tous ? ». La leçon est celle de l'ADR-013, retournée contre moi : **un échantillon choisi n'est pas une mesure.**

## Décision

1. **Le flux d'un podcast Radio France se lit dans sa page**, par la balise `rel="alternate"` qu'elle publie pour les lecteurs de flux. Pas de deuxième API, **pas de clé, pas de compte, pas de secret**. Ça couvre **76 %** du catalogue, les émissions plutôt que les chroniques — et c'est 76 % de plus qu'avant.
2. **Trois adresses au plus sont essayées**, dans cet ordre : le titre entier, puis le titre sans sa parenthèse de fin (« Micro européen (2007-2025) » → `micro-europeen` : les podcasts archivés portent leurs années dans leur titre chez Apple, jamais dans l'adresse de leur page), puis sans le nom de la station, puis sans l'article. Le titre entier d'abord : la parenthèse est parfois le vrai nom.
2. **Le résolveur part de la clé `itunes:<collectionId>`** que porte déjà tout podcast en base. Il demande son nom et son producteur à Apple (`lookup`, ~2 Ko), puis essaie **au plus trois adresses** de page. Conséquence voulue : ça marche aussi pour les podcasts **déjà loggés** avant cette PR, sans qu'il faille les rechercher.
3. **Il n'est appelé que quand le flux manque.** Un podcast dont Apple donne le flux porte une clé `feed:`, et `RSSEpisodeProvider` répond avant lui — il est le dernier des `episodeSources`. Un producteur hors Radio France ne fait charger **aucune page**.
4. **Une absence n'est pas une panne.** Une page qui n'existe pas (404) fait passer à l'orthographe suivante ; les trois épuisées, la fiche montre son état vide, qui dit déjà « son flux ne les donne pas ». **Toute autre panne remonte** et donne « Impossible de charger les épisodes ». Vide ≠ erreur, comme partout ailleurs.
5. **ICI (ex-France Bleu) n'est pas couvert**, et c'est écrit : ses podcasts sont sur un autre site, avec un autre découpage. Ils restent cherchables et loggables, sans liste d'épisodes.

## Conséquences

- **Zéro minute de la founder, zéro secret de plus.** Le point 4 de l'ADR-013 (« ni clé, ni compte, ni secret ») tient pour la tranche entière, Radio France comprise.
- **Un podcast Radio France coûte deux requêtes de plus à la première ouverture de sa fiche** : le `lookup` (2 Ko) et sa page (450 Ko). La réponse est retenue pour la session, absence comprise — sinon un podcast sans page la chercherait à chaque visite.
- **Une chronique sur quatre reste sans épisodes**, et sa fiche le dit (« Aucun épisode … ou son flux ne les donne pas »). Ce n'est pas un bug à corriger : quand la page de Radio France ne déclare pas de flux, il n'y a rien à lire. Podcast Index pourrait en récupérer une partie — à mesurer **si** l'usage montre que ça manque, pas avant.
- **La fragilité est réelle et assumée** : si Radio France change la forme de ses adresses ou retire la balise, les épisodes disparaissent. La panne est **visible** (la fiche dit « Aucun épisode ») et se répare en une PR — le calcul d'adresse est une fonction pure, testée contre les 31 cas mesurés sur le vrai site. **Podcast Index reste le recours**, et l'ADR-013 en garde le mode d'emploi.
- Le résolveur ne lit **rien d'autre** que l'adresse du flux : pas de titre, pas de résumé, pas de contenu de page. Ce que Radio France publie pour les lecteurs de podcasts est lu par un lecteur de podcasts.

## Ce que ça corrige dans l'ADR-013

L'ADR-013 écartait cette piste en deux mots : « c'est du scraping, et **rien dans ce que rend Apple ne permet de remonter jusqu'à la page** ». La deuxième moitié était **fausse** : le producteur et le titre y suffisent, 23 fois sur 24. Elle n'avait pas été mesurée, seulement supposée.

## Alternatives écartées

- **Podcast Index** (la piste de l'ADR-013) : demande une inscription, une clé au Trousseau, un secret de plus dans le pipeline `make secrets`, et sa couverture de Radio France ne peut pas être vérifiée avant. Reste le recours si la page cesse de marcher.
- **L'API ouverte de Radio France** (openapi.radiofrance.fr) : demande elle aussi un compte et une clé, pour le même résultat.
- **fyyd**, réessayé le 03/10 — mais cette fois pour **résoudre**, pas pour chercher, ce qui est un usage différent de celui que l'ADR-013 avait écarté. Mesuré sur les 25 podcasts qui manquent, avec une correspondance **stricte** (titre identique **et** flux hébergé chez `radiofrance-podcast.net`, sans quoi il rend « L'instant cinéma » pour « L'instant M ») : **2 récupérés sur 25**. Une deuxième source, un ADR, un risque de mauvais appariement, et le risque d'afficher les épisodes d'un autre podcast — pour deux podcasts. Écarté.
- **Podcast Index** : plus une alternative écartée mais **la suite**. L'inscription s'est avérée fermée aux adresses email gratuites ; la founder en a obtenu une le 03/10 au soir. Mesuré aussitôt sur les 25 podcasts manquants, avec une correspondance stricte (titre identique **et** flux hébergé chez `radiofrance-podcast.net`) : **22 récupérés sur 25**, soit un plafond de **97 %** au lieu de 76 %. Deux réserves à traiter dans son propre ADR : il introduit **deux secrets** dans le binaire (comme TMDB, ADR-001, mais sur le compte personnel de la founder), et sa correspondance **par identifiant Apple est très incomplète** (1 sur 4 testés) — il faut passer par la recherche par titre, donc par un appariement strict sur le titre **et** le producteur, sinon on affiche les épisodes d'un autre podcast.
- **Les deux ensemble** : deux sources à maintenir pour un podcast sur 24. Proposé à la founder le 03/10, écarté par elle.
- **Lire la page par morceaux** pour éviter les 450 Ko : radiofrance.fr n'honore pas l'en-tête `Range` (vérifié le 03/10, la réponse est la page entière), et `HTTPClient` rend un `Data`, pas un flux d'octets. À revoir si le poids devient un sujet.
