# 13 · File d'attente d'ordres

> **À implémenter** (V2c, suite). Aujourd'hui chaque file (construction, recherche,
> chantier) a **un seul** ordre (spec 03, 04, 05).

## Objet

Enchaîner plusieurs ordres dans une même file pour ne pas devoir revenir dans l'app à la fin
de chaque construction (confort d'idle mobile).

## Décidé

- **Aucun paiement réel**, jamais (spec 00). La file se gagne en jeu, par des officiers
  (spec 12) :
  - file de **construction** : **Commandant** ;
  - files de **recherche** et du **chantier** : un second officier (nom proposé :
    **Logisticien**).
- **Taille** : 1 ordre sans l'officier (comme aujourd'hui), **1 + niveau** avec lui
  (jusqu'à 6 au niveau 5). Pas de file d'emblée.
- **Paiement au démarrage effectif** de chaque ordre (règle OGame) : tant qu'il attend, rien
  n'est réservé, les ressources restent **pillables**.
- **Ordre impossible à son tour** (ressources manquantes au démarrage) : **la file est
  annulée** et une **notification** le signale.

## Proposé

- Coût et durée de chaque ordre calculés **au démarrage** (niveaux, technos et officiers du
  moment). Plusieurs niveaux du même bâtiment autorisés à la suite.
- **Ajout** : refusé si la file est pleine ou si les prérequis ne sont pas remplis en
  comptant les ordres placés avant (ex. Laboratoire 1 en file, puis Technologie Énergie).
  Les ressources ne sont pas vérifiées à l'ajout.
- **Autres blocages au démarrage** (prérequis, labo ou chantier en agrandissement, limite
  par planète) : même règle que les ressources, file annulée et notifiée.
- **Annulation** : un ordre en attente se retire sans frais (rien n'est payé) ; annuler
  l'ordre en cours le rembourse comme aujourd'hui et démarre le suivant tout de suite.
- **Chantier** : la file enchaîne des lots (unité, quantité).
- **Notifications** : fin de chaque ordre comme aujourd'hui, plus l'annulation d'une file.
  À la mise en arrière-plan, les échéances futures sont prévues en simulant `advance()`
  (déterministe, raids compris) sur un horizon.
- **UI** : écran File, ordres en attente sous l'ordre en cours (position, élément, retrait) ;
  sur une carte, « Ajouter à la file » quand la file est occupée et pas pleine ;
  « File : 2 / 4 » dans la carte « En cours ».
- **Technique** : ordres en attente dans l'état et une table dédiée, id d'événement réservé
  à l'ajout ; dans `advance()`, la fin d'un ordre démarre le suivant à cet instant ;
  `AdvanceResult` liste les files annulées.
