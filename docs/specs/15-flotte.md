# 15 · Flotte (V3)

> **V3a, V3b, V3c et V3d livrées** (V3c décidée et implémentée le 2026-11-10, V3d le 2026-11-18). Les vaisseaux existent déjà dans les données
> (flottes pirates, spec 07).

## Objet

Passer de la défense à l'action : construire des vaisseaux, défendre la planète avec eux,
attaquer les bases pirates (le pillage devient un revenu), recycler les débris, explorer.

## Découpage proposé

| Lot | Contenu |
| --- | --- |
| V3a | Vaisseaux constructibles au chantier (6 existants), flotte stationnée qui défend la planète avec les défenses, champ de débris après un combat, recycleur |
| V3b | Bases pirates : cibles générées, technos de propulsion (durée des trajets) et d'espionnage, missions d'attaque avec aller-retour, consommation de deutérium, pillage rapporté |
| V3c | Expéditions (résultat aléatoire à graine), officier **Amiral**, plafond de vaisseaux par mission, risque du recyclage |
| V3d | Recyclage avec transporteurs : soute ajoutée, durée de collecte selon le débit des recycleurs, rappel pendant la collecte, champ de la planète en mission de flotte |

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
- **Recyclage** (remplacé en V3d) : « Envoyer N recycleurs » ; mission `RecycleMission` de
  `debris.collect_hours` (1 h à ×1). Une mission à la fois.
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
- **Places de flotte** : remplacées en V3c (limites par type de mission, plafond de vaisseaux).
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

## V3c (implémentée)

### Limites de missions (remplace « places de flotte = 1 + Informatique »)

| Mission | En vol en même temps | Plafond de vaisseaux |
| --- | --- | --- |
| Attaque | `fleet.attack_slots` (1) | Oui |
| Expédition | 1 + niveau d'Amiral (5 au plus) | Oui |
| Recyclage d'une base | Illimité | Escorte seulement (recycleurs exclus) |
| Espionnage | Illimité | Non |
| Mise à l'abri | Illimitée | Non |

- **Plafond de vaisseaux par mission** = `fleet.ships_base` + `fleet.ships_per_level` ×
  min(Informatique, `fleet.ships_max_level`). Les sondes et les recycleurs n'y comptent pas.
  Un vaisseau compte pour un, quel que soit son type.
- L'Informatique ne donne plus de places de flotte ; `fleet.base_slots` disparaît.
- Mission refusée en clair : « Attaque déjà en vol », « Toutes les places d'expédition sont
  occupées », « Plafond : N vaisseaux par mission (Informatique) ».

### Expéditions

- **Destination unique** « Espace profond », à `expedition.systems` systèmes : trajet et
  carburant aller-retour comme une mission (formule V3b).
- **Durée d'exploration** au choix parmi `expedition.hours` (1, 2, 4, 8 h à ×1), entre
  l'arrivée et le départ du retour. Plus longue : butin proportionnel à la durée, et moins
  de chances de ne rien trouver.
- **Résultat** tiré à la fin de l'exploration avec la graine de la mission, selon les poids
  `expedition.outcomes` :
  - **rien** (poids divisé par la durée en heures) ;
  - **ressources** : `resource_hours` × durée heures de ta production (métal, cristal,
    deutérium), dans la limite de la soute envoyée ;
  - **vaisseaux trouvés** : une valeur de `ship_hours` × durée heures de ta production, en
    vaisseaux de types débloqués au chantier (tirés au hasard), qui rentrent avec la flotte
    et ne comptent pas dans le plafond ;
  - **embuscade pirate** : combat contre une flotte pirate d'une valeur tirée dans
    `ambush_strength` × le butin espéré (`resource_hours` × durée heures de production),
    technos des raids : le risque suit le gain, une escorte armée le couvre ; les survivants
    poursuivent (sans butin) ;
  - **retour retardé** ou **anticipé** : durée du retour × `delay_factor` ou
    `early_factor` ;
  - **trou noir** (rare) : toute la flotte est perdue.
- Au retour : popover et rapport d'expédition dans le journal (résultat, texte d'histoire,
  butin ou pertes ; rapport de combat en cas d'embuscade). Notification du retour (spec 09).
- Compteur `expeditions` : expéditions terminées, trou noir compris (prérequis de l'Amiral).
- Vaisseaux trouvés : types sans prérequis manquant (hors sondes) ; aucun débloqué : types
  de la flotte envoyée.
- Rappel pendant l'exploration : retour direct, durée d'un aller.
- Notification : retour de l'expédition seulement, prévu par la simulation (déterministe).

### Amiral (spec 12)

- Bonus `expedition_slots`, +1 place d'expédition par niveau, **4 niveaux** (5 places).
- Prérequis par niveau : compteur `expeditions`, Informatique et chantier croissants
  (seuils dans le YAML).

### Risque du recyclage d'une base

- À l'arrivée sur le champ d'une base (détruite ou non), une **patrouille pirate** surgit
  avec la probabilité `pirate_bases.patrol_chance` (graine de la mission). Invisible à
  l'espionnage.
- Patrouille : vaisseaux seulement, d'une valeur de `patrol_strength` × celle de la base
  (budget de génération), technos des raids.
- **Escorte** : la mission de recyclage accepte des vaisseaux de combat avec les
  recycleurs ; l'escorte compte dans le plafond.
- Combat recycleurs + escorte contre la patrouille, rapport dans le journal. Gagné : collecte
  normale, débris de la patrouille ajoutés au champ. Perdu : survivants rentrent à vide.
- Recyclage du champ de la planète : inchangé, sans risque.

### UI

- Onglet Flotte, en tête : carte **Ta flotte** (nom, nombre à quai, nombre en vol, pour
  chaque type de vaisseau possédé, sans image ; « Aucun vaisseau » sinon).
- **Mission en vol** : étapes (Aller › Exploration › Retour pour une expédition, Aller ›
  Retour, Absence pour une mise à l'abri ; étape en cours en couleur d'action, passées
  cochées), barre d'avancée de l'étape en cours (début de phase `phase_at` de la mission),
  « <étape> · reste … » et heure de fin.
- **Bases pirates** compactes : une ligne par base (nom ; systèmes, état, débris, dernier
  espionnage) ; tap → feuille avec le rapport d'espionnage complet, le champ de débris et
  les actions Espionner / Recycler / Attaquer.
- Onglet Flotte : ligne de limites « Attaques 0 / 1 · Expéditions 0 / N · N vaisseaux par
  mission » (infobulle : Informatique et Amiral) ; carte **Expédition** (bouton
  « Explorer »).
- Feuille d'envoi : puces de durée d'exploration ; compteur « n / plafond » ; recyclage :
  recycleurs et vaisseaux de combat (escorte à 0 par défaut). Sélection par défaut : tous
  les vaisseaux adaptés, dans la limite du plafond.
- Rapports d'expédition et de patrouille dans le journal (icône, verdict, butin, vaisseaux
  trouvés, combat le cas échéant) et en popover.

### Données, persistance, tests

- YAML : `fleet` (`attack_slots`, `ships_base`, `ships_per_level`, `ships_max_level`),
  section `expedition`, `pirate_bases` (`patrol_chance`, `patrol_strength`), officier
  `admiral`, compteur `expeditions`.
- `FleetMission` : type `expedition` et durée d'exploration dans la charge utile ; rapport
  d'expédition stocké avec les rapports (JSON, type distinct) ; sauvegarde v11. Une
  sauvegarde antérieure reste importable.
- Tests : plafond et limites (refus, mise à l'abri et sondes exclues), chaque résultat
  d'expédition (déterministe à graine), trou noir, embuscade, poids selon la durée, Amiral,
  patrouille avec et sans escorte, rattrapage d'une expédition app fermée. Équilibrage :
  chaque base reste prenable avec le plafond atteignable à ce stade (`test/balance`), une
  expédition est rentable en moyenne, escorter le recyclage aussi.

## V3d (implémentée)

Les débris s'accumulent plus vite que la soute des recycleurs : les transporteurs (et toute
la flotte envoyée) ajoutent de la soute, les recycleurs restent seuls à ramasser.

### Collecte

- Une mission de recyclage demande **au moins un recycleur** ; elle accepte tous les
  vaisseaux sauf les sondes. Les recycleurs ne comptent pas dans le plafond, les autres
  (transporteurs, escorte) si.
- **Quantité** Q = min(champ, soute totale de la flotte), au prorata du métal et du cristal.
- **Débit** : un recycleur remplit sa soute en `debris.collect_hours` (1 h à ×1) ; débit de
  la flotte = recycleurs × soute du recycleur / `collect_hours`.
- **Durée de collecte** = `collect_hours` × max(1, Q / (recycleurs × soute du recycleur)),
  divisée par la vitesse de jeu. Pas de plafond : 1 recycleur et 3 fois sa soute en
  transporteurs collectent 3 fois plus longtemps.
- **Réservation** : Q est retirée du champ au début de la collecte (arrivée sur une base,
  départ pour la planète). Ce qui arrive ensuite dans le champ reste pour une autre mission ;
  plusieurs missions peuvent viser le même champ sans se disputer les débris.
- **Rappel pendant la collecte** : la flotte rapporte Q × avancée de la collecte (arrondi
  par défaut), le reste retourne au champ. Sur une base, le retour dure un aller ; sur la
  planète, les vaisseaux sont déposés tout de suite.

### Champ de la planète

- C'est une `FleetMission` de recyclage **sans cible** : pas de trajet ni de carburant, la
  collecte commence au départ, les vaisseaux et le chargement sont déposés à sa fin. Plus de
  limite d'une mission à la fois.
- Une `RecycleMission` en cours dans une sauvegarde antérieure se termine selon l'ancienne
  règle (aucune migration de schéma).

### Champ d'une base

- Le champ d'une base **détruite** reste recyclable (envoi et collecte) ; l'attaque et
  l'espionnage, eux, attendent sa réapparition.
- Étapes Aller › Collecte › Retour. La patrouille (V3c) surgit à l'arrivée, avant la
  collecte : gagnée, ses débris s'ajoutent au champ et les survivants collectent ; perdue,
  les survivants rentrent à vide. Un champ vidé entre-temps : retour direct, à vide.

### UI

- **Feuille d'envoi « Recyclage »** (planète ou base) : sélection par défaut « Juste
  assez » (tous les recycleurs, puis grands puis petits transporteurs jusqu'à couvrir le
  champ, dans la limite du plafond ; escorte à 0), puce « Juste assez » en plus de « Tout »
  et « Aucun » ; compteur « n / plafond (recycleurs sans limite) ». Bloc de prévision :
  champ, quantité collectée et soute, « Reste dans le champ X » ou « Soute inutilisée X »,
  « Aller · collecte · retour » (planète : « Collecte » seule, ni vitesse ni carburant),
  débit horaire. Infobulle sur la règle.
- **Mission en vol** : étapes Aller › Collecte › Retour (planète : Collecte), « Collecté X /
  Q » pendant la collecte, rappel possible jusqu'au retour. Les missions de la planète
  apparaissent dans l'onglet Flotte et dans « Ta flotte » (en vol).
- **Carte « Champ de débris »** (onglet Flotte, après les missions en vol ; déplacée du
  Chantier) : vignette, champ, bouton « Recycler » qui ouvre la feuille d'envoi. Absente sans
  débris ; les collectes en cours sont des missions en vol.

### Tests

- Durée selon le débit (plancher, ×3 avec 3 fois la soute), réservation au départ, deux
  missions sur le même champ, rappel partiel (planète et base), patrouille puis collecte,
  transporteurs comptés dans le plafond, ancienne `RecycleMission` encore appliquée.
