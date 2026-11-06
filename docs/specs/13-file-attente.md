# 13 · File d'attente d'ordres

> **À spécifier** — rien n'est implémenté. Aujourd'hui chaque file (construction, recherche,
> chantier) a **un seul** ordre (spec 03, 04, 05).

## Objet

Enchaîner plusieurs ordres dans une même file pour ne pas devoir revenir dans l'app à la fin
de chaque construction (confort d'idle mobile).

## Décidé

- **Aucun paiement réel**, jamais (spec 00). Dans OGame la file est un avantage premium du
  Commandant ; ici elle se gagne en jeu.

## Proposé

- Débloquée par l'officier **Commandant** (spec 12).
- 5 ordres par file, pour les trois files (le chantier enchaîne des lots).
- Plusieurs niveaux du même bâtiment autorisés ; coût et durée de chaque ordre calculés
  avec les ordres placés avant lui.
- Annulation possible de n'importe quel ordre en attente.
- Notification quand la **file se vide**, pas à chaque ordre.
- Technique : table des ordres en attente ; dans `advance()`, chaque fin d'ordre démarre le
  suivant (déterministe, testable comme le reste).

## À trancher

1. **Débit des ressources du jeu** : au lancement effectif de l'ordre (règle OGame ; ordre
   sauté et notifié si les ressources manquent) ou à la mise en file (réservation ; les
   ressources engagées échappent au pillage) ? Recommandation : au lancement effectif.
2. Taille fixe, ou extensible (rangs du Commandant, techno) ?
3. Débloquée d'emblée (confort) ou seulement via le Commandant ?
