# ADR-013 — Les podcasts : Apple pour chercher, le flux RSS pour les épisodes

- Statut : **accepted** — le point 5 (Radio France par Podcast Index) est **remplacé par l'[ADR-014](014-flux-radio-france-par-leur-page.md)**, qui y arrive sans clé.
- Date : 2026-09-27
- Contexte : tranche Podcasts, avancée avant l'import à la demande de la founder

## Contexte

Le PRD annonçait « Apple Podcasts + RSS » sans dire qui fait quoi. Avant d'écrire le plan, les deux sources ont été interrogées **pour de vrai** le 27/09 :

| Question | Mesure |
|---|---|
| Apple sait-il chercher un podcast français ? | **Oui**, très bien : nom, producteur, jaquette 600 px, nombre d'épisodes, genre. API publique, **sans clé ni compte**. |
| Donne-t-il le flux RSS ? | Oui — **sauf Radio France**. France Inter et France Culture : **10 podcasts testés, 10 sans `feedUrl`**, ni par `search`, ni par `lookup`. Arte Radio, Binge, Louie Media, Simplecast, Megaphone, Ausha : flux fourni. |
| Un flux se lit-il proprement ? | **Oui**, avec `XMLParser`, sans dépendance : 96 épisodes datés et minutés pour « Le code a changé ». |
| Les épisodes sont-ils numérotés ? | **Non.** Ni `itunes:episode`, ni `itunes:season` sur les flux testés. Liste plate. |
| Les flux sont-ils complets ? | **Non.** The Daily a publié des milliers d'épisodes ; son flux n'en garde que **64**. |

## Décision

1. **Apple Podcasts cherche, le flux RSS liste les épisodes.** Deux rôles, deux sources, aucune ne fait le travail de l'autre. `ApplePodcastProvider` est un `MetadataProvider` ; `RSSEpisodeProvider` est un `EpisodeProvider` **qui ne cherche rien** — d'où une deuxième liste dans `ProviderRegistry` (`episodeSources`).
2. **Le flux découvert chez Apple devient une clé externe** (`feed:<url>`), à côté de `itunes:<collectionId>`. C'est par elle que le lecteur RSS est appelé ; une clé qui n'est pas un flux ne déclenche aucune requête.
3. **L'identité d'un épisode de podcast est le `guid` de son flux**, pas sa position — d'où le schéma **V3** (`Episode.externalID`). Un flux tronqué ou qui publie décalerait sinon toutes les coches.
4. **Ni clé, ni compte, ni secret** pour ce qui est livré : les deux sources sont publiques. C'est ce qui a permis de faire la tranche sans rien demander à la founder.
5. **Radio France est traité à part**, plus tard, par un résolveur de flux appelé **uniquement** quand Apple ne donne rien. Piste retenue : Podcast Index (index ouvert, inscription gratuite, clé au Trousseau comme TMDB). **À vérifier avec la clé en main** avant d'écrire la PR ; si l'index ne couvre pas Radio France, on en reparle. Un ADR séparé accompagnera cette PR — elle introduit un secret et une source de plus.

## Conséquences

- Les podcasts entrent dans la recherche **sans changer l'écran** : une famille de recherche apparaît dès qu'une source la sert.
- `kind.hasEpisodes` était déjà vrai pour les podcasts depuis la T1 : le `+` d'un podcast mène à ses épisodes sans une ligne de plus (#42).
- **Coût assumé** : les podcasts de Radio France sont trouvables et loggables, mais **sans liste d'épisodes** tant que le résolveur n'est pas là. La founder a tranché le 27/09 en connaissance de cause (« les deux à parts égales » → le reste d'abord).
- Le flux n'est jamais chargé pendant la recherche (250 à 500 Ko), et jamais plus d'une fois par consultation de fiche.

## Alternatives écartées

- **Podcast Index comme source unique** (recherche + flux) : sa recherche est moins bonne qu'Apple sur le catalogue français, et elle aurait demandé une clé dès la première PR — donc une action de la founder avant tout résultat visible.
- **fyyd** (API ouverte, sans clé) : testée le 27/09, pertinence trop faible — « le code a changé » rend un podcast coréen sans rapport.
- ~~**Deviner l'URL du flux Radio France** depuis la page de l'émission : c'est du scraping, et rien dans ce que rend Apple ne permet de remonter jusqu'à la page.~~ **Écarté à tort** : mesuré le 03/10, le producteur et le titre rendus par Apple suffisent à retrouver la page dans 23 cas sur 24, et la page déclare son flux dans la balise que lisent tous les lecteurs de podcasts. C'est devenu la décision de l'[ADR-014](014-flux-radio-france-par-leur-page.md). La leçon : cette ligne-là n'avait pas été mesurée.
