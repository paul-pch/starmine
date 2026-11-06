# 14 · Événements ponctuels

> **À implémenter** — version V2d, après les officiers (spec 12). Rien n'est codé.

## Objet

Dynamiser la partie par des événements justifiés par l'histoire, qui donnent un **effet
temporaire** positif ou négatif (bump ou perte de production, durées modifiées, gain ou
perte ponctuels). Pas de monnaie : ce sont les « accélérations » du jeu, gagnées ou subies.
Le catalogue est appelé à s'enrichir beaucoup.

## Décidé

- **Fréquence** : environ **2 par semaine** à ×1 (`events.interval_hours`).
- **50 / 50** entre événements positifs et négatifs (poids dans le YAML).
- **Certains événements proposent un choix** au joueur.
- **Lien avec les officiers** : un officier peut atténuer, amplifier ou prolonger un effet.
- **Debug** : bouton « Événement maintenant » (tirage aléatoire immédiat).

## Règles proposées

- **Chaîne d'événements** comme les raids (spec 07) : un événement est toujours planifié,
  même id d'un tirage à l'autre ; type et paramètres tirés avec une **graine stockée**.
- **Effet = modificateur temporaire** appliqué par les formules existantes : production d'une
  ressource, énergie, durée de construction / recherche / chantier, ou gain / perte immédiat
  de ressources. La fin d'un effet est elle-même une échéance de la file : `advance()`
  découpe le temps à chaque début et fin d'effet (production exacte app fermée).
- **Choix** : l'événement arrive avec une échéance de réponse (`answer_hours`). Sans réponse
  à l'échéance, l'**option par défaut** (prudente, définie dans le YAML) s'applique, pour
  que l'app fermée reste jouable.
- **Cumul** : plusieurs effets d'événements différents peuvent coexister ; un même type ne
  se cumule pas (le nouveau remplace l'ancien).
- Notification à l'arrivée (app fermée), et à l'approche de l'échéance d'un choix.

## Catalogue initial (proposé)

| Événement | Sens | Effet | Officier lié |
| --- | --- | --- | --- |
| Filon riche | + | Production de métal augmentée quelques heures | Géologue : plus long |
| Geyser de deutérium | + | Production de deutérium augmentée | Géologue |
| Découverte archéologique | + | Recherche en cours raccourcie | Technocrate : plus fort |
| Convoi marchand | choix | Échanger une ressource contre une autre à bon taux, ou refuser | — |
| Escorte demandée | choix | Accepter : gain de cristal, mais raid avancé ; refuser : rien | Ingénieur |
| Tempête solaire | − | Énergie réduite quelques heures | Ingénieur : atténuée |
| Effondrement de galerie | − | Une mine à production réduite | Géologue : atténué |
| Sabotage | − | Chantier ou construction en cours retardés | Architecte |
| Fuite de stockage | − | Perte d'une part d'un stock | — |

## Données

Section `events` du YAML : `interval_hours`, poids positif / négatif, et par événement
`name`, `description` (texte d'histoire + infobulle), `kind` (bonus, malus, choix), effet
(cible, valeur, durée), options de choix et option par défaut, officier lié et son effet.

## UI

- Bandeau des **effets actifs** (sous le bandeau de raid) : nom, effet en clair, temps
  restant ; tap → feuille avec le texte d'histoire et l'effet chiffré (`InfoButton`).
- Événement à choix : feuille avec les options, leurs effets chiffrés, l'échéance et
  l'option par défaut.
- Historique des événements : avec les rapports (à trancher).
- Illustration éventuelle : registre d'images (spec 11), jamais porteuse d'information.

## Persistance

Événement planifié dans la file `events` ; effets actifs (type, fin, valeur) et choix en
attente : nouvelle table et sauvegarde JSON. Spec 08 à mettre à jour.

## À trancher

1. Historique des événements : dans l'écran Rapports, ou nulle part ?
2. Un événement négatif peut-il tomber pendant un raid annoncé ? Recommandation : oui (le
   hasard crée des situations), mais jamais deux négatifs actifs à la fois.
3. Les événements peuvent-ils dépendre de la progression (ex. Geyser seulement avec un
   synthétiseur) ? Recommandation : oui, via `requires` comme les technos.

## Code

À venir : `lib/domain/story_events.dart` (nom indicatif ; `GameEvent` désigne déjà la file
d'échéances).
