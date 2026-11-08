# 04 · Recherche

## Objet

Débloquer bâtiments, défenses, vaisseaux et bonus via un arbre de technologies. Propulsion
et Espionnage (V3b) : spec 15.

## Règles

- Technologies **globales à la partie** (pas par planète).
- Coût du niveau N : `floor(base × 2^(N−1))`, débité au lancement.
- Durée : `(M + C) / (1000 × (1 + labo) × vitesse) × (1 − Technocrate)` heures (spec 12).
- **File de recherche** : 1 slot, en parallèle de la construction. Annulation avec
  remboursement intégral. Règle du labo : spec 03.
- Prérequis : bâtiments et technos (`requires`), labo 1 au minimum.
- **Palier** d'une techno = 1 + palier maximal de ses prérequis technologiques (les prérequis
  de bâtiments ne comptent pas). Calculé, jamais saisi.
- **« Débloque »** : prérequis inversés directs (bâtiments, technos, défenses).
- Effets en jeu :
  - Énergie : rendement de la fusion ;
  - Plasma : bonus de production des mines (`production_bonus` par niveau) ;
  - Armes, Bouclier, Protection : +10 % par niveau sur l'attaque, les boucliers et la coque
    des unités (spec 06) ;
  - Laser, Ions, Informatique : prérequis uniquement pour l'instant.

## Catégories

| Catégorie | Technos |
| --- | --- |
| Fondamentales | Énergie, Laser, Ions, Plasma |
| Combat | Armes, Bouclier, Protection |
| Avancées | Informatique |

## Données

`research.<clé>` : `name`, `description`, `category`, `cost`, `factor`, `requires`,
`production_bonus`. `categories.research`.

## Code

`lib/domain/game_data.dart` (`TechKind`, `TechSpec`), `lib/domain/tech_tree.dart`
(`unlockedBy`, `tier`, `techsByTier`).

## UI

Onglet Recherche : cartes avec étiquette « Palier N » (explication au tap), lignes
« Requiert » et « Débloque ». Pastille de l'onglet : verte si libre, rouge si le labo
s'agrandit, aucune sans labo.

## Tests

`tech_tree_test.dart`, `engine_test.dart` (groupe recherche).

## Points ouverts

- Objectif épinglé (« viser une techno ») : écarté pour l'instant, à reconsidérer en jouant.
