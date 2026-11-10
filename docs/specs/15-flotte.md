# 15 · Flotte (V3)

> **V3a et V3b livrées**, V3c à implémenter. Les vaisseaux existent déjà dans les données
> (flottes pirates, spec 07).

## Objet

Passer de la défense à l'action : construire des vaisseaux, défendre la planète avec eux,
attaquer les bases pirates (le pillage devient un revenu), recycler les débris, explorer.

## Découpage proposé

| Lot | Contenu |
| --- | --- |
| V3a | Vaisseaux constructibles au chantier (6 existants), flotte stationnée qui défend la planète avec les défenses, champ de débris après un combat, recycleur |
| V3b | Bases pirates : cibles générées, technos de propulsion (durée des trajets) et d'espionnage, missions d'attaque avec aller-retour, consommation de deutérium, pillage rapporté |
| V3c | Missions d'exploration (résultat aléatoire à graine), officier **Amiral**, places de flotte |

Chaque lot est jouable seul ; V3a ne demande aucun trajet.

## Proposé (règles OGame par défaut)

- **Vaisseaux** : petit et grand transporteur, chasseurs léger et lourd, croiseur, vaisseau
  de bataille (données actuelles), plus le **recycleur** (V3a) et la **sonde d'espionnage**
  (V3b). Prérequis de chantier et de technos selon OGame, chiffres dans le YAML.
- **Défense** : la flotte stationnée combat aux côtés des défenses ; les vaisseaux
  détruits ne sont **pas** reconstruits (seules les défenses le sont à 70 %).
- **Champ de débris** : 30 % du métal et du cristal des **vaisseaux** détruits (des deux
  camps), défenses exclues ; récupéré par des recycleurs (soute 20 000).
- **Trajets (V3b)** : durée selon la distance, la vitesse du plus lent vaisseau et la
  technologie de propulsion ; consommation de deutérium à l'aller et au retour.
- **Pertes** : une flotte détruite est perdue avec sa cargaison.

## Décidé

1. Livraison dans l'ordre **V3a, V3b, V3c**.
2. **Débris dès la V3a** : le recycleur collecte le champ de la planète en un temps fixe
   (mission courte, sans distance).
3. **Flotte à l'abri** (*fleet save*) : en V3b, avec les trajets.
4. **Bases pirates (V3b)** : 3 à 5 bases proches, force et butin croissants, régénération
   après un pillage, force indexée sur les points comme les raids.
5. **Base des raids** : la flotte n'y compte pas (comme les défenses).
6. **Espionnage** : contre les bases pirates seulement, sans contre-espionnage au début.
7. **Navigation** : un onglet **Chantier** (sections Défense et Flotte) remplace Défense ;
   Debug sort de la barre, accessible depuis le hero.

## V3b : décisions

- **Technos** : Réacteur à combustion (+10 %/niv.), Réacteur à impulsion (+20 %/niv.),
  Propulsion hyperespace (+30 %/niv.), Espionnage ; prérequis des vaisseaux selon OGame.
  Nouveau vaisseau : **sonde d'espionnage**.
- **Trajets** : formule OGame (distance, vitesse du plus lent, vitesse réglable de 10 à
  100 %) × `fleet.flight_factor` = **×3** (rythme idle : ~1 h aller-retour) ; carburant
  (deutérium) payé au départ pour l'aller et le retour.
- **4 bases pirates** à 2 à 6 systèmes ; force **et** stock en heures de ta production
  (décision après mesure, remplace « force indexée sur les points ») ; dures à gagner,
  rentables avec la bonne flotte ; il faut les espionner pour connaître leurs défenses ;
  régénération (stock, défenses après 12 h, base détruite remplacée après 24 h).
- **Missions** : attaque, espionnage, recyclage d'un champ de débris de base, **mise à
  l'abri** (durée au choix) ; rappel en route ; places de flotte = 1 + Informatique.
- **5ᵉ onglet « Flotte »**.

## V3a (implémentée)

- **Vaisseaux** constructibles au chantier comme les défenses (lots, file d'attente du Chef
  de chantier), **recycleur** ajouté (soute 20 000). Prérequis provisoires dans le YAML.
- **Défense** : les vaisseaux stationnés combattent avec les défenses ; détruits, ils ne sont
  pas reconstruits. Ils ne comptent pas dans la base des raids.
- **Champ de débris** (`Planet.debris`) : `debris.share` (30 %) du métal et du cristal des
  vaisseaux détruits des deux camps ; affiché dans le rapport de combat.
- **Recyclage** : « Envoyer N recycleurs » (assez pour tout le champ, dans la limite des
  présents) ; mission `RecycleMission` de `debris.collect_hours` (1 h à ×1), recycleurs
  absents pendant ce temps ; au retour, chargement au plus de la soute, au prorata du métal
  et du cristal, ajouté au stock même au-delà du stockage. Une mission à la fois.
- **UI** : onglet Chantier (défenses puis vaisseaux, catégories Civils et Combat), carte du
  champ de débris en tête ; Debug depuis le hero (icône réglages).
- **Persistance** : colonnes de débris de `planets` (schéma v8), sauvegarde v8.
- **Tests** : `fleet_test.dart` (construction, défense par la flotte, débris, recyclage).

## V3b (implémentée)

- **Technos** (`research`, catégorie Propulsion) : Réacteur à combustion, à impulsion,
  Propulsion hyperespace (`drive_bonus` par niveau), Espionnage. Vaisseaux : `speed`,
  `fuel`, `drive`, prérequis OGame ; **sonde d'espionnage**.
- **Trajet** : `(10 + 35 000 / %vitesse × √(distance × 10 / vitesse)) × flight_factor`
  secondes (×3), divisé par la vitesse de jeu ; vitesse = celle du plus lent ; distance =
  2 700 + 95 × systèmes. **Carburant** d'un aller : Σ n × `fuel` × distance / 35 000 ×
  (%vitesse / 100 + 1)², aller et retour payés au départ.
- **Places de flotte** : `fleet.base_slots` + Informatique.
- **Bases pirates** (`pirate_bases`) : 4 bases ; unités d'une valeur de `defense_hours` de ta
  production (×1, plancher `min_budget`), calculées à l'arrivée ; **doctrine** tirée à chaque
  génération (part de vaisseaux 20, 50 ou 80 %, une partie des types débloqués) : deux
  générations ne se ressemblent pas, d'où l'espionnage ; technos pirates des raids ; stock = `stock_hours`
  de ta production, remplissage en `refill_hours`. Attaque gagnée : pillage
  (`loot_share`, dans la limite de la soute), **base détruite**, remplacée après
  `respawn_hours` (nouvelle génération, stock plein). Attaque perdue ou nulle : les
  survivants restent jusqu'à `rebuild_hours`. Débris en orbite de la base.
- **Missions** (`FleetMission`, même id à l'aller et au retour) : attaque (combat, rapport
  dans Rapports → Raids), espionnage (sondes seules ; ressources dès Espionnage 1, flotte 2,
  défenses 4, technos 6), recyclage du champ d'une base, **mise à l'abri** (durée au choix
  parmi `fleet.shelter_hours`, carburant d'un aller-retour vers la base la plus proche).
  **Rappel** à l'aller : retour en autant de temps que parcouru. Retour : vaisseaux et
  chargement déposés (au-delà du stockage possible). Une flotte détruite ne revient pas.
- **Onglet Flotte** (5ᵉ) : places, missions en vol (rappel), mise à l'abri, bases (distance,
  état, débris, dernier rapport d'espionnage, Espionner / Recycler / Attaquer) ; feuille
  d'envoi (vaisseaux, vitesse ou durée d'abri, durée, carburant, soute, refus en clair).
  Sélection des vaisseaux : puces « Tout » / « Aucun », puis par type « n / possédés », un
  curseur de 0 au maximum et − / + pour l'unité ; tous les vaisseaux adaptés par défaut.
- **Persistance** : table `pirate_bases` (schéma v9), événement `fleet_mission`,
  sauvegarde v9. **Notifications** : arrivée et retour.
- **Tests** : `missions_test.dart` ; équilibre mesuré et figé dans `test/balance/`
  (flotte nécessaire plus chère que la base, gain net positif avec la bonne flotte).
