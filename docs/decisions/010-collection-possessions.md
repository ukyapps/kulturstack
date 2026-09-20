# ADR-010 — « Ma bibliothèque » : entité `OwnedCopy` à côté des logs

- Statut : **accepted**
- Date : 2026-09-20

## Contexte

Ajout de la founder le 2026-09-20 : garder trace de ce qu'on **possède** (CD, vinyles, cassettes, DVD, Blu-ray, livres, jeux en boîte), comme Discogs le fait pour les disques.

## Décision

Ce n'est pas un nouveau type de contenu ni un statut : c'est une **deuxième relation à l'œuvre**.

```
MediaItem (l'œuvre)
├── LogEntry   → je l'ai consommée (date, statut, note)
└── OwnedCopy  → je la possède (format, édition, date d'acquisition)
```

- Indépendants : possédé sans consommé, consommé sans possédé, ou les deux.
- `OwnedCopy { id, format: String (vinyl, cd, cassette, dvd, bluray, paperback, hardcover, boxed…), editionRef: String? (isbn13 exact, discogs:release:…), acquiredAt: Date?, notes: String?, item }`.
- La fiche reste au niveau de l'**œuvre** (ADR-004) ; `OwnedCopy` porte l'**édition**. Alignement exact avec Discogs master/release.
- À l'ajout : deux cases indépendantes « Je l'ai vu/lu/écouté » (cochée par défaut au 1 tap) et « Je le possède » (un tap de plus, optionnel). Au scan de code-barres (T5), c'est « je le possède » qui est coché par défaut.

## Conséquences

- Arrive en **Tranche 5** (SchemaV3, migration lightweight) avec l'import de la collection Discogs et le scan ISBN/EAN (OpenLibrary + Discogs cherchent par code-barres ; TMDB non → DVD par titre).
- Aucun impact sur T1 hormis : la fiche ne doit pas supposer qu'un item a forcément un log.
- Ergonomie détaillée à concevoir plus tard.
