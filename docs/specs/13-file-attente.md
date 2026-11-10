# 13 · File d'attente d'ordres

## Objet

Enchaîner plusieurs ordres dans une même file pour ne pas devoir revenir dans l'app à la fin
de chaque construction (confort d'idle mobile).

## Règles

- **Aucun paiement réel**, jamais (spec 00). La file se gagne en jeu, **un officier par
  file** (spec 12) : **Commandant** (construction), **Directeur scientifique** (recherche),
  **Chef de chantier** (chantier).
- **Taille** : 1 ordre sans l'officier (comme avant), **1 + niveau** avec lui (jusqu'à 6 au
  niveau 5), ordre en cours compris.
- **Ajout** : une commande sur une file libre démarre tout de suite ; sur une file occupée,
  elle va en file d'attente. Refusée si la file est pleine ou si les prérequis ne sont pas
  remplis **en comptant les ordres placés avant** (en cours et en attente, toutes files :
  ex. Usine de robots 2 en file, puis Chantier). Ressources non vérifiées à l'ajout.
- **Paiement au démarrage effectif** de chaque ordre (règle OGame) : tant qu'il attend,
  rien n'est réservé, les ressources restent **pillables**. Coût et durée calculés au
  démarrage (niveaux, technos, officiers du moment).
- **Démarrage** : dans `advance()`, la fin d'un ordre (dernière unité pour un lot) démarre
  le premier ordre en attente de la même file, **à cet instant** ; l'événement reprend l'id
  réservé à l'ajout.
- **Ordre impossible à son tour** (ressources, prérequis, labo ou chantier en
  agrandissement, limite par planète) : **toute la file est annulée** et une notification
  le signale (popover dans l'app si elle est ouverte, spec 10).
- **Annulation** : un ordre en attente se retire sans frais ; annuler l'ordre en cours le
  rembourse et démarre le suivant tout de suite (avec la même règle d'annulation).
- **Chantier** : la file enchaîne des lots (unité, quantité).

## Notifications

Fin de chaque ordre comme avant, plus l'annulation d'une file. À la mise en arrière-plan, les
ordres en attente n'ont pas d'échéance : `advance()` est simulé sur 7 jours (déterministe,
raids compris) pour prévoir leurs fins et une éventuelle annulation (spec 09).

## Persistance

Table `queued_orders` (schéma v6 : id réservé, position, payload), sauvegarde JSON v6
(`queue`). `nextEventId` tient compte des ids réservés (spec 08).

## UI

- Carte d'élément : quand la file est occupée, le bouton devient « Ajouter à la file »
  (icône liste), avec coût et durée du niveau prévu après la file ; « File pleine : N
  ordres » quand il n'y a plus de place.
- Carte « En cours » : « · file 2 / 4 » quand l'officier de la file est recruté.
- Écran File : sous l'ordre en cours, « File d'attente · n / N », ordres en attente
  (position, élément → niveau visé, ou lot), retrait (croix) ; rappel « Chaque ordre est payé
  à son démarrage ».

## Code

`lib/domain/engine.dart` (`QueuedOrder`, `placeOrder`, `placeBatch`, `checkPlacement`,
`startNextQueued`, `cancelOrQueue`, `queueCapacity`, `projectedLevel`), `advance()`
(`AdvanceResult.cancelled`), `GameController._scheduleAll`, `lib/ui/screens/queue_screen.dart`.

## Tests

`queue_test.dart` : sans officier, file pleine, prérequis projetés, enchaînement et paiement
au démarrage, annulation sur ressources et sur labo occupé, retrait et annulation de l'ordre
en cours, chantier et limite, déterminisme pas à pas. `game_controller_test.dart` :
notifications prévues app fermée. Persistance : `save_codec_test.dart`,
`game_repository_test.dart`.
