# 14 · Événements ponctuels

> Version V2d.

## Objet

Dynamiser la partie par des événements justifiés par l'histoire, qui donnent un **effet
temporaire** positif ou négatif (bump ou perte de production, durées modifiées, gain ou
perte ponctuels). Pas de monnaie : ce sont les « accélérations » du jeu, gagnées ou subies.
Le catalogue est appelé à s'enrichir.

## Règles

- **Chaîne** comme les raids (spec 07) : un `StoryEvent` est toujours planifié, même id d'un
  tirage à l'autre, intervalle tiré dans `story_events.interval_hours` (~2 par semaine à
  ×1). Tout aléatoire passe par la graine de l'événement.
- **Tirage** : sens positif ou négatif **à parts égales** (les choix comptent comme
  positifs), puis un événement **éligible** de ce sens (prérequis `requires` ; un raccourci
  exige un ordre en cours) ; repli sur l'autre sens si aucun n'est éligible. **Jamais deux
  malus actifs à la fois** : positif forcé si un malus est en cours.
- **Effets** (`StoryEffectType`) :
  - `production` (ressource ou toutes), `energy` : temporaires, pendant `hours` ; ce sont des
    `Modifiers` ; `advance()` découpe la production à la fin de chaque effet ;
  - `shorten` : temps restant de la construction ou de la recherche en cours × (1 − valeur)
    (valeur négative : retard) ;
  - `stock` : stock × (1 + valeur) ; `gain` : `hours` heures de production (à ×1), dans la
    limite du stockage ; `raid` : le prochain raid (non détecté) arrive `hours` plus tôt.
- **Cumul** : effets d'événements différents cumulés ; le même événement ne se cumule pas
  (le nouveau remplace l'ancien).
- **Officier lié** (`officer`) : un bonus est prolongé (durée × (1 + n × niveau), raccourci
  renforcé, plafond 90 %), un malus atténué (valeur × (1 − n × niveau)). Pas d'effet sur les
  options d'un choix.
- **Choix** : l'événement attend la réponse jusqu'à `answer_hours` ; sans réponse,
  l'**option par défaut** (prudente) s'applique à l'échéance. Répondre applique l'option à
  l'instant et planifie l'événement suivant.

## Catalogue

| Événement | Sens | Effet | Officier lié |
| --- | --- | --- | --- |
| Filon riche | + | +30 % de production de métal, 12 h | Géologue : plus long |
| Geyser de deutérium | + | +40 % de deutérium, 8 h | Géologue |
| Découverte archéologique | + | −20 % du temps restant de la recherche | Technocrate : plus fort |
| Épave à la dérive | + | 4 h de production de métal et de cristal | — |
| Convoi marchand | choix | Échanger 15 % du métal contre 8 h de cristal, ou refuser (défaut) | — |
| Escorte demandée | choix | 10 h de cristal mais raid 12 h plus tôt, ou refuser (défaut) | — |
| Tempête solaire | − | −25 % d'énergie, 6 h | Ingénieur : atténuée |
| Effondrement de galerie | − | −50 % de cristal, 8 h | Géologue : atténué |
| Sabotage | − | +25 % du temps restant de la construction | Architecte : atténué |
| Fuite de stockage | − | −10 % du stock de métal | — |

Valeurs dans le YAML ; à équilibrer en jouant.

## Données

Section `story_events` : `interval_hours`, `answer_hours`, `catalog` (par événement `name`,
`description` = texte d'histoire, `kind` : `bonus` / `malus` / `choice`, `requires`,
`effects`, ou `options` [`label`, `effects`] et `default`, `officer` [`kind`, `per_level`]).

## UI

- **Bandeau des événements** (sous le bandeau de raid) : « Décision : <nom> · <reste> ·
  Choisir », puis une ligne par effet en cours (nom, effet, temps restant, flèche verte ou
  rouge) ; tap → texte d'histoire et effet chiffré.
- **Feuille de décision** : texte d'histoire, une carte par option (effets en clair, option
  par défaut signalée), bouton par option.
- **Message** quand un événement survient app ouverte (« Décision attendue » avec accès à
  la feuille).
- **Journal** : écran Rapports, onglet « Événements » (date, nom, choix ou défaut) ; tap →
  texte et effets.
- **Debug** : « Événement maintenant ».

## Notifications

À la mise en arrière-plan, les tirages des 7 jours suivants sont prévus par simulation
(déterministe) et notifiés à leur heure ; un choix en attente a un rappel 1 h avant
l'option par défaut (spec 09).

## Persistance

Événement de chaîne dans `events` (`story_event` : graine, choix en attente) ; effets en
cours (`active_effects`) et journal (`story_log`), schéma v7 ; sauvegarde JSON v7
(`effects`), le journal n'en fait pas partie (spec 08).

## Code

`lib/domain/story.dart` (tirage, effets, choix), `StoryEvent` (`events.dart`),
`GameState.effects` et découpage dans `_produceUntil` (`engine.dart`),
`lib/ui/widgets/story_banner.dart`, onglet du journal dans `reports_screen.dart`.

## Tests

`story_test.dart` : config, parts égales et déterminisme, jamais deux malus, éligibilité,
effet temporaire exact puis retiré, remplacement, officiers, raccourci et retard, stock et
gain, choix par défaut, réponse, raid avancé, chaîne sur 3 semaines, debug.

## Points ouverts

- Enrichir le catalogue (nouveaux événements, événements liés à la progression).
- Illustrations : registre d'images (spec 11), jamais porteuses d'information.
