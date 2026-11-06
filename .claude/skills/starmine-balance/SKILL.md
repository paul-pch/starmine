---
name: starmine-balance
description: Régler l'équilibrage de Starmine (coûts, production, raids pirates, combat) en modifiant assets/game_data.yaml et en le mesurant par des simulations déterministes. À utiliser quand l'utilisateur trouve un rythme trop lent ou rapide, des raids trop forts ou faibles, ou veut vérifier des valeurs OGame.
---

# Équilibrage Starmine

Tout l'équilibrage est dans `assets/game_data.yaml` ; le code ne contient que des formules.

## Démarche

1. **Reformuler le ressenti en mesure** : « les raids sont trop forts » → « à 200 points,
   la planète est pillée plus de X % du temps avec Y % de ressources investies en défense ».
   Faire confirmer la cible par l'utilisateur.
2. **Mesurer avant de toucher** : écrire un test de mesure (déterministe, graine fixe) qui
   imprime les chiffres utiles, par exemple :
   - `pirateFleet(points, data, Random(seed))` sur une plage de points ;
   - `simulateRaid(state, fleet, data, runs: 200, random: Random(seed))` pour une planète
     type (mines, défenses, technos) ;
   - `advance` sur plusieurs jours pour compter raids et pillage.
   Le lancer en CI (`tool/ci.sh wait`) et lire la sortie.
3. **Changer une seule clé à la fois** et remesurer.
4. **Figer la cible** : transformer la mesure en assertion (fourchette) dans un test, pour
   qu'un réglage futur ne casse pas l'équilibre sans qu'on le voie.

## Leviers

| Ressenti | Clés |
| --- | --- |
| Raids trop fréquents | `pirates.interval_hours` |
| Pas le temps de réagir | `pirates.warning_minutes` |
| Raids trop forts / faibles | `pirates.strength`, `pirates.min_budget`, seuils `pirates.warships` |
| Pillage trop lourd | `pirates.loot_share`, `pirates.cargo_share` |
| Début trop lent | `start.resources`, `formulas.base_production_per_hour` |
| Constructions trop longues | `formulas.build_time_divisor` (préférer la vitesse de jeu pour tester) |

## Fidélité OGame

- Valeur OGame : vérifier sur le wiki OGame (fandom) et citer la source dans le commit ;
  sinon commentaire « à vérifier ».
- Un écart volontaire à OGame se note en commentaire dans le YAML et dans la spec concernée.

## Après un changement

- Mettre à jour la spec (`docs/specs/07-raids.md`, `02-economie.md`…) si une règle change ;
  un simple chiffre n'y figure pas.
- Rappeler à l'utilisateur que les parties en cours prennent les nouvelles valeurs au
  prochain événement (pas de rétroactivité sur un raid déjà détecté).
