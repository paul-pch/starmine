# 15 · Flotte (V3)

> **V3a livrée**, V3b et V3c à implémenter. Les vaisseaux existent déjà dans les données
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
