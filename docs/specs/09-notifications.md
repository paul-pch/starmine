# 09 · Notifications

## Objet

Prévenir le joueur quand quelque chose se termine ou le menace, seulement quand l'app n'est
pas à l'écran.

## Règles

- **App visible : aucune notification.** À la mise en arrière-plan, une notification est
  programmée par événement à venir ; au retour, toutes sont retirées.
- Une notification programmée survit au redémarrage du téléphone (receivers du plugin).
- Alarmes exactes si l'utilisateur les autorise (Debug), sinon décalage de quelques minutes.

| Événement | Moment | Titre | Canal |
| --- | --- | --- | --- |
| Construction | Fin | Construction terminée | Constructions |
| Recherche | Fin | Recherche terminée | Recherches |
| Lot du chantier | Dernière unité | Chantier terminé | Constructions |
| Raid détecté | Détection | Flotte pirate détectée (heure d'arrivée) | Raids pirates |
| Raid | Arrivée | Raid pirate (voir le rapport) | Raids pirates |

- Id de notification = id de l'événement ; l'arrivée d'un raid utilise
  `raidArrivalNotificationId(id)`.

## Code

`lib/ui/notifications.dart`, `GameController.onHidden` / `onVisible`.

## Tests

`game_controller_test.dart` (via `FakeNotifier`).
