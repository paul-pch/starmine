# 15 · Flotte (V3)

> **À spécifier** — rien n'est implémenté. Cette page découpe la V3 et liste les décisions
> à prendre. Les vaisseaux existent déjà dans les données (flottes pirates, spec 07).

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

## À trancher

1. **Découpage** V3a / V3b / V3c : d'accord pour livrer dans cet ordre ?
2. **Débris en V3a** sans trajet : le recycleur collecte le champ de la planète en un
   temps fixe (mission courte, sans distance) — ou on attend les trajets de la V3b ?
   Recommandation : collecte simple dès la V3a.
3. **Raids et flotte** : la flotte stationnée défend automatiquement. Faut-il une option
   « flotte à l'abri » (la retirer avant un raid, comme le *fleet save* d'OGame) ?
   Recommandation : oui, en V3b avec les trajets.
4. **Bases pirates (V3b)** : nombre fixe de bases à proximité, régénérées après un pillage,
   avec une force indexée sur tes points comme les raids ? Ou une carte plus riche ?
   Recommandation : 3 à 5 bases, force et butin croissants, régénération.
5. **Force des raids** : la flotte compte-t-elle dans la base des raids (aujourd'hui les
   unités en sont exclues) ? Recommandation : non, pour garder « bien défendu = tranquille ».
6. **Espionnage** : utile seulement contre les bases pirates (rapport avant attaque) ?
   Recommandation : oui, sans contre-espionnage pirate au début.
7. **Écran Flotte** : nouvel onglet (la barre en a déjà 5 : Bâtiments, Recherche, Défense,
   File, Debug) ? Recommandation : fusionner Défense et Flotte dans un onglet « Chantier »
   avec deux sections, Debug sortant de la barre (accès depuis le hero). À confier au skill
   `starmine-ui`.
