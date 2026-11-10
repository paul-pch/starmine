# 14 · Événements ponctuels

> Version V2d ; révision V2e (événements app ouverte, stock, nouveaux effets).

## Objet

Dynamiser la partie par des événements justifiés par l'histoire, qui donnent un **effet
temporaire** positif ou négatif (bump ou perte de production, durées modifiées, gain ou
perte ponctuels). Pas de monnaie : ce sont les « accélérations » du jeu, gagnées ou subies.
Le catalogue est appelé à s'enrichir.

## Règles

> Révision V2e (2026-11-10) : les événements surviennent **app ouverte** ; le temps hors
> ligne remplit un **stock** servi à la connexion. Les effets **s'empilent**.

- **Chaîne** comme les raids (spec 07) : un `StoryEvent` est toujours planifié, même id d'un
  bout à l'autre. Tout aléatoire passe par la graine de l'événement.
- **Stock** : toutes les `story_events.interval_hours` (temps réel, à ×1), app ouverte ou
  non, un événement s'ajoute au stock, plafonné à `max_stock`. C'est la seule chose que
  `advance()` fait de la chaîne (avec l'option par défaut d'un choix échu) : **aucun tirage
  hors ligne**, donc aucun effet subi en idle.
- **Service, app ouverte seulement** : quand le contrôleur rattrape le temps app visible
  (ouverture, horloge d'affichage), il sert **un** événement du stock si le stock n'est pas
  vide, qu'aucun choix n'attend et que le délai de service est passé. Le délai suivant est
  tiré dans `serve_gap_minutes` (temps réel, à ×1) : à l'ouverture après une nuit, un
  événement tout de suite, puis un toutes les 20 à 40 min tant que le stock dure. Jamais plus
  de `max_stock` + ce qui s'accumule pendant la session.
- **Tirage** : sens positif ou négatif **à parts égales** (les choix comptent comme
  positifs), puis un événement **éligible** de ce sens (prérequis `requires` ; un raccourci
  exige un ordre en cours) ; repli sur l'autre sens si aucun n'est éligible. **Jamais deux
  malus actifs à la fois** : positif forcé si un malus est en cours. Le même événement n'est
  pas tiré deux fois d'affilée.
- **Effets** (`StoryEffectType`) :
  - `production` (ressource ou toutes), `energy` : temporaires, pendant `hours` ; ce sont des
    `Modifiers` ; `advance()` découpe la production à la fin de chaque effet ;
  - `shorten` : temps restant de la construction ou de la recherche en cours × (1 − valeur)
    (valeur négative : retard) ;
  - `stock` : stock × (1 + valeur) ; `gain` : `hours` heures de production (à ×1), dans la
    limite du stockage ; `raid` : le prochain raid (non détecté) arrive `hours` plus tôt ;
  - `units` : `value` unités `unit` ajoutées à la planète (négatif : perdues, plancher 0) ;
  - `debris` : `hours` heures de production de métal et de cristal ajoutées au champ de
    débris de la planète (à recycler, spec 15) ;
  - `delayed` : `hours` heures de production de `resource` (toutes si absente), calculées à
    l'application, **versées `delay` heures plus tard**, même au-delà du stockage ; affiché
    comme un effet en cours (« à recevoir ») ;
  - `gamble` : pari, réussi avec la probabilité `chance` (graine de l'événement) ; applique
    les effets `win` ou `lose`. Le résultat est montré dans la popover et le journal.
- **Cumul** : tous les effets s'additionnent, y compris ceux du même événement tiré deux
  fois (production : bonus ajoutés ; énergie : facteurs multipliés).
- **Officier lié** (`officer`) : un bonus est prolongé (durée × (1 + n × niveau), raccourci
  renforcé, plafond 90 %), un malus atténué (valeur × (1 − n × niveau)). Pas d'effet sur les
  options d'un choix.
- **Choix** : servi app ouverte, l'événement attend la réponse jusqu'à `answer_hours` ; sans
  réponse, l'**option par défaut** (prudente) s'applique à l'échéance, même app fermée.
  Répondre applique l'option à l'instant. Le service suivant attend le délai de service.

## Catalogue

| Événement | Sens | Effet | Officier lié |
| --- | --- | --- | --- |
| Filon riche | + | +30 % de production de métal, 12 h | Géologue : plus long |
| Geyser de deutérium | + | +40 % de deutérium, 8 h | Géologue |
| Découverte archéologique | + | −20 % du temps restant de la recherche | Technocrate : plus fort |
| Épave à la dérive | + | 4 h de production de métal et de cristal | — |
| Bataille en orbite proche | + | Débris : 6 h de métal et de cristal | — |
| Convoi marchand | choix | Échanger 15 % du métal contre 8 h de cristal, ou refuser (défaut) | — |
| Escorte demandée | choix | 10 h de cristal mais raid 12 h plus tôt, ou refuser (défaut) | — |
| Épave instable | choix | Fouiller : 60 % 8 h de métal et de cristal, sinon −10 % du cristal ; ou laisser (défaut) | — |
| Déserteurs pirates | choix | Accueillir : 3 chasseurs légers, raid 6 h plus tôt ; ou refuser (défaut) | — |
| Contrat d'avance | choix | Investir 10 % du métal, recevoir 12 h de métal et de cristal dans 24 h ; ou décliner (défaut) | — |
| Prospecteurs | choix | Financer : 50 % 10 h de toutes ressources, sinon −15 % du deutérium ; ou refuser (défaut) | — |
| Signal de détresse | choix | Secourir : 70 % 2 petits transporteurs et 4 h de cristal, sinon raid 8 h plus tôt ; ou ignorer (défaut) | — |
| Tempête solaire | − | −25 % d'énergie, 6 h | Ingénieur : atténuée |
| Effondrement de galerie | − | −50 % de cristal, 8 h | Géologue : atténué |
| Sabotage | − | +25 % du temps restant de la construction | Architecte : atténué |
| Fuite de stockage | − | −10 % du stock de métal | — |

Les nouveaux événements à choix demandent un début de milieu de partie (prérequis dans le
YAML). Valeurs dans le YAML ; à équilibrer en jouant.

## Données

Section `story_events` : `interval_hours` (accumulation du stock), `max_stock`,
`serve_gap_minutes`, `answer_hours`, `catalog` (par événement `name`,
`description` = texte d'histoire, `kind` : `bonus` / `malus` / `choice`, `requires`,
`effects`, ou `options` [`label`, `effects`] et `default`, `officer` [`kind`, `per_level`]).
Un effet : `type`, `resource`, `target`, `value`, `hours`, `unit` (`units`), `delay`
(`delayed`), `chance`, `win`, `lose` (`gamble`).

## UI

- **Bandeau des événements** (sous le bandeau de raid) : « Décision : <nom> · <reste> ·
  Choisir », puis une ligne par effet en cours (nom, effet, temps restant, flèche verte ou
  rouge) ; tap → texte d'histoire et effet chiffré.
- **Feuille de décision** : texte d'histoire, une carte par option (effets en clair, option
  par défaut signalée), bouton par option.
- **Popover** quand un événement survient app ouverte (spec 10) : texte d'histoire et
  effets ; une décision y montre directement ses options (« Plus tard » la laisse en attente).
- **Journal** : écran Rapports, liste unique avec les rapports de combat (date, nom, choix ou
  défaut) ; tap → texte et effets ; « Effacer le journal » efface rapports et événements
  (confirmation ; les effets en cours restent).
- **Bandeau** : un effet `delayed` s'affiche « <montant> à recevoir » avec son reste.
- **Popover** et **journal** : un pari affiche « Réussi » ou « Raté » et les effets obtenus.
- **Debug** : « Événement maintenant » (ajoute un événement au stock et le sert aussitôt),
  stock et délai de service.

## Notifications

Aucune (V2e) : rien ne survient app fermée. L'option par défaut d'un choix échu s'applique
sans notification.

## Persistance

Événement de chaîne dans `events` (`story_event` : graine, choix en attente et son
échéance, stock, prochain ajout au stock, délai de service ; une sauvegarde antérieure sans
ces champs reprend avec un stock vide) ; effets en cours (`active_effects`, JSON : un effet
`delayed` y garde son montant) et journal (`story_log`, colonne `won` du pari en schéma
v10) ; sauvegarde JSON v10 (`effects`), le journal n'en fait pas partie (spec 08).

## Code

`lib/domain/story.dart` (tirage, effets, choix), `StoryEvent` (`events.dart`),
`GameState.effects` et découpage dans `_produceUntil` (`engine.dart`),
`lib/ui/widgets/story_banner.dart`, onglet du journal dans `reports_screen.dart`.

## Tests

`story_test.dart` : config, parts égales et déterminisme, jamais deux malus, éligibilité,
effet temporaire exact puis retiré, cumul du même événement, officiers, raccourci et retard,
stock et gain, unités, débris, versement différé, pari (déterministe, les deux issues),
choix par défaut, réponse, raid avancé, stock plafonné sur 3 semaines sans aucun effet hors
ligne, service (délai, un à la fois, pas pendant un choix), debug.

## Points ouverts

- Enrichir le catalogue (nouveaux événements, événements liés à la progression).
- Équilibrage des nouveaux choix (gains fixes en unités : à indexer sur la progression ?).
- Narratif : la popover accepte une illustration 21:9 (`story.<clé>`, spec 11).
- Illustrations : registre d'images (spec 11), jamais porteuses d'information.
