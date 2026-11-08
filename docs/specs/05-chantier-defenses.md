# 05 · Chantier et défenses

## Objet

Produire des unités au chantier spatial : défenses en V2, vaisseaux à partir de la V3.

## Règles

- **Lot** : une commande de N unités d'un type, payée intégralement à la commande,
  livrée **unité par unité**. Un seul lot à la fois. **Pas d'annulation** (comme OGame).
- Durée par unité : `(M + C) / (2500 × (1 + chantier) × 2^nanites × vitesse)` heures, figée à
  la commande.
- Règle du chantier : spec 03.
- **Limite par planète** : `max` (dômes : 1 chacun).
- **Vaisseaux** constructibles depuis la V3a (spec 15) : transporteurs, chasseurs,
  croiseur, vaisseau de bataille, recycleur, sonde d'espionnage (V3b). Prérequis OGame
  (chantier, réacteurs, technos).
- Quantité commandable : bornée par les ressources et la limite (`maxOrderable`).
- Caractéristiques d'une unité : attaque, bouclier, coque = `(M + C) / 10`, soute (vaisseaux),
  tir rapide (spec 06).

## Catégories

| Catégorie | Défenses |
| --- | --- |
| Légères | Lanceur de missiles, Laser léger |
| Lourdes | Laser lourd, Canon de Gauss, Artillerie à ions, Lanceur de plasma |
| Boucliers | Petit bouclier, Grand bouclier |
| Civils (`fleet`) | Petit et grand transporteur, Recycleur |
| Combat (`fleet`) | Chasseurs léger et lourd, Croiseur, Vaisseau de bataille |

## Données

`units.<clé>` : `name`, `description`, `category`, `defense`, `cost`, `attack`, `shield`,
`cargo`, `max`, `requires`, `rapid_fire`. `categories.defense`, `categories.fleet`.

## Code

`lib/domain/events.dart` (`ShipyardBatch`), `lib/domain/engine.dart` (`checkBatch`,
`startBatch`, `maxOrderable`, `unitDuration`).

## UI

Onglet **Chantier** : défenses puis vaisseaux (soute affichée), carte du champ de débris
en tête (spec 15) ; carte par unité (nombre possédé, attaque / bouclier / coque avec technos,
coût unitaire, durée par unité), feuille de quantité (curseur, 1 / 10 / 100 / Max, coût et
durée totaux). File : emplacement Chantier (progression « 3 / 20 », prochaine unité, fin).

## Tests

`engine_test.dart` (groupe chantier), `game_repository_test.dart` (lot persisté).
