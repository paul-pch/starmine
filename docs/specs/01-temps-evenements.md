# 01 · Temps et événements

## Objet

Faire avancer la partie de façon exacte, que l'app soit ouverte ou fermée, sans boucle de jeu.

## Règles

- L'état (`GameState` : planète, technos, événements en attente) est daté par
  `planet.lastUpdate`.
- `advance(state, now, rules)` applique, dans l'ordre (`dueAt`, puis `id`), chaque événement
  échu : production jusqu'à son échéance, application, puis production jusqu'à `now`.
- Une horloge antérieure à `lastUpdate` (horloge reculée) ne fait rien.
- **Chaînes d'événements** : l'application d'un événement peut produire l'événement suivant de
  la même chaîne, **avec le même id**, réinséré dans la file :
  - lot du chantier : unité livrée → même lot pour l'unité suivante (spec 05) ;
  - raid : détection → arrivée → détection du raid suivant (spec 07).
- `advance` renvoie l'état, les événements appliqués et les **rapports de raid** produits.
- **Déterminisme** : tout aléatoire passe par une graine stockée dans l'événement. Rejouer le
  même état donne le même résultat.
- **Vitesse** : `Rules.speed` multiplie production et consommations et divise toutes les
  durées (constructions, recherches, chantier, raids). Changer la vitesse solde d'abord le
  passé ; les échéances déjà programmées ne bougent pas.
- **Précision** : les échéances sont à la milliseconde (précision de la base et de la
  sauvegarde).

## Événements

| Type (base / JSON) | Classe | Effet |
| --- | --- | --- |
| `building_done` | `BuildingDone` | Niveau de bâtiment + 1 |
| `research_done` | `ResearchDone` | Niveau de techno + 1 |
| `shipyard_batch` | `ShipyardBatch` | +1 unité, puis unité suivante |
| `raid_detected` | `RaidDetected` | Composition fixée → `RaidArrival` |
| `raid_arrival` | `RaidArrival` | Combat, pillage, rapport → `RaidDetected` suivant |

`GameEvent` est une classe scellée : ajouter un type casse volontairement la compilation des
`switch` exhaustifs à compléter (voir le skill `starmine-feature`).

## Quand appeler `advance`

À l'ouverture, au retour au premier plan, avant chaque action du joueur (une seule horloge par
action), et quand l'horloge d'affichage (1 s) voit une échéance passée. Entre deux appels,
l'UI **interpole** les stocks sans rien écrire (`GameController.interpolated`).

## Code

`lib/domain/engine.dart` (`advance`, `_apply`, commandes), `lib/domain/events.dart`,
`lib/ui/game_controller.dart` (orchestration, opérations sérialisées).

## Tests

- Rattrapage de 12 h avec construction et recherche = simulation seconde par seconde.
- Rattrapage de 3 jours avec raids : nombre de raids plausible, résultat déterministe.
- Lot interrompu par la fermeture de l'app.
