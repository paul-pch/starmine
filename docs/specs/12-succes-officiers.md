# 12 · Officiers

> **À implémenter** — version V2c. Rien n'est codé. Le nom du fichier reste
> `12-succes-officiers.md` pour ne pas casser les liens.

## Objet

Récompenser la progression : des **officiers**, personnages gagnés en jouant, donnent des
**bonus permanents** qui compensent le ralentissement naturel du jeu (la courbe des durées
de construction et de recherche).

## Décidé

- **Gagnés, jamais achetés ni loués** : pas de monnaie, pas de durée (spec 00).
- **Écran des officiers** : liste de tous les officiers, débloqués ou non, avec leurs
  prérequis et leur progression.
- **Prérequis indexés sur l'arbre d'avancement**, sur le modèle des technos : niveaux de
  bâtiments et de technos (`requires`). Idem pour chaque **niveau** d'officier.
- **Déblocage explicite** : quand les prérequis sont remplis, l'officier (ou son niveau
  suivant) devient *disponible* ; le joueur doit appuyer sur **« Débloquer »** (ou
  « Promouvoir »). Rien ne se débloque sans qu'il le sache. Une pastille signale un officier
  disponible.
- **Niveaux plafonnés** : le bonus croît par niveau jusqu'à un plafond (ex. Technocrate :
  −5 % de durée de recherche par niveau). Bonus par niveau et niveau max dans le YAML.
- **Tous les officiers débloqués sont actifs.** Un nombre limité de places actives reste une
  **option d'équilibrage** : le noter en commentaire dans le code (application des bonus) et
  dans le YAML.
- Les officiers d'abord (V2c), les événements ensuite (V2d, spec 14) ; les officiers
  influencent certains événements.

## Règles proposées

- **Bonus** = modificateurs appliqués par les formules existantes (production, durées,
  reconstruction, énergie), jamais un timer. Un bonus en pourcentage suit la courbe des
  coûts, donc garde sa valeur en fin de partie.
- Le déblocage est une **commande** (comme lancer une construction) : refusée si les
  prérequis ne sont pas remplis, horodatée, effet immédiat (le bonus s'applique à partir de
  cet instant dans `advance()`).
- Déblocage **gratuit** : c'est une récompense, les prérequis suffisent.

| Officier | Prérequis (indicatifs) | Bonus par niveau |
| --- | --- | --- |
| Géologue | Niveaux des mines | Production des mines |
| Technocrate | Labo et niveaux de technos | Durée de recherche réduite |
| Architecte | Usine de robots / nanites | Durée de construction réduite |
| Ingénieur | Chantier et technos de combat | Reconstruction des défenses au-delà de 70 %, énergie |
| Commandant | Progression générale | File d'attente (spec 13) : un ordre de plus par niveau |
| Amiral | V3 (flotte) | Avantages de flotte |

Lien avec les événements (spec 14) : un officier atténue ou prolonge certains événements
(ex. Géologue : filons plus longs ; Ingénieur : tempête solaire atténuée).

## Données

Section `officers` du YAML : par officier `name`, `description` (infobulle), `bonus` (type,
valeur par niveau), `max_level`, et par niveau `requires`.

## Persistance

Niveau par officier (0 = verrouillé) : nouvelle table, sauvegarde JSON (défaut 0 à
l'import d'une ancienne sauvegarde). Spec 08 à mettre à jour.

## UI

- Écran ou onglet **Officiers** : carte par officier (portrait, niveau, bonus actuel et
  suivant, prérequis manquants en rouge comme pour les technos), bouton « Débloquer » /
  « Promouvoir » quand disponible, `InfoButton` sur le bonus.
- Portraits : catégorie `character` du registre d'images (spec 11) ; repli sans image.

## À trancher

1. Place de l'écran : onglet dédié, ou entrée depuis le hero ?
2. Notification (app fermée) quand un officier devient disponible ? Recommandation : oui,
   une seule par officier disponible.
3. Prérequis uniquement sur l'arbre, ou aussi des compteurs (raids repoussés pour
   l'Ingénieur, événements traversés) ? Recommandation : l'arbre d'abord, compteurs plus tard.
4. Liste et seuils exacts des officiers de la V2c (proposition : Géologue, Technocrate,
   Architecte, Ingénieur ; Commandant avec la spec 13).

## Code

À venir : `lib/domain/officers.dart` (nom indicatif).
