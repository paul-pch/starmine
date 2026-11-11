# 11 · Visuels et registre d'images

## Objet

Rendre le jeu plus immersif avec des images SF réalistes, sans toucher à la lisibilité d'un
idle de ressources. Les images sont générées hors du jeu (ComfyUI en local), validées une par une,
puis packagées dans l'APK.

État : registre `art/registry.yaml` et code d'affichage (`lib/ui/visuals.dart`, repli) en place. Les 36
images t1 des bâtiments (12 × 3 climats, liste : `art/prompts/selection-t1-rocheux.md`) sont packagées
en WebP, ainsi que les 12 images des recherches (liste : `art/prompts/selection-recherches.md`, charte
`art/style/research_prompt.md`), les 16 unités du chantier et les 3 hero planète (biome rocheux, série 59,
charte `art/style/hero_prompt.md`) et 15 illustrations d'événements sur 15 (série 60, charte
`art/style/story_prompt.md`) ; les autres catégories restent en repli. Les seuils `tiers` et `temperature_bands` sont repris
dans le code, alignement vérifié par un test.

## Règles

- **Pré-générées** : aucun appel de génération ni réseau au runtime. L'APK ne contient que
  des WebP validés.
- **Décoratives** : l'image ne porte jamais d'information (spec 10).
- **Registre = source de vérité** : `art/registry.yaml`. Seules les entrées `validated` ont
  un fichier packagé.
- **Une image validée n'est jamais écrasée** : toute modification crée une version N+1 ; la
  précédente passe `deprecated` et son master est conservé.
- **Repli** : image absente ou en erreur → surface unie + icône vectorielle de l'élément
  (ambiance « Sobre » = repli partout). Jamais d'espace vide ni de mise en page qui saute.
- **Cohérence** : un prompt de base commun (`art/style/base_prompt.md`) + 3 à 5 images de
  référence de style (`art/style/refs/`) ; chaque entrée n'ajoute que sa partie spécifique.
  Un palier N+1 se génère avec l'image validée du palier N en référence (`parent`).

## Catalogue

| Catégorie | Id | Format | Quantité | Où | État |
| --- | --- | --- | --- | --- | --- |
| `building` | `building.<clé YAML>.t<1-3>.<cold\|temperate\|hot>` | 1:1, 512 px (B, A) | 12 × 3 paliers × 3 climats | Cartes et feuille de détail | t1 packagés (36) ; **t2, t3 à produire (72)** |
| `building_wide` | `building_wide.<clé>.t<1-3>.<cold\|temperate\|hot>` | 4:3, 640 × 480 (C) — facultatif, sinon recadrage du 1:1 | — | Cartes de l'ambiance Immersive | Facultatif, non branché |
| `research` | `research.<clé YAML>` | 1:1, 512 px, sans climat | 12 | Cartes et feuille de détail | Packagées |
| `defense` | `defense.<clé YAML>` | 1:1, 512 px, sans climat | 8 | Cartes du chantier et feuille de détail | Packagées |
| `ship` | `ship.<clé YAML>` | 1:1, 512 px, sans climat | 8 | Cartes du chantier et feuille de détail | Packagées |
| `planet_hero` | `planet_hero.<cold\|temperate\|hot>` | 21:9, 1260 × 540 | 3 | Hero de l'écran principal | Packagées (biome rocheux) |
| `background` | `background.<cold\|temperate\|hot>` | 9:19.5, 1080 × 2340, sombre en bas | 3 | Fond plein écran de l'ambiance Immersive | **À produire**, non branché |
| `pirate` | `pirate.<clé YAML>` : les 6 vaisseaux des flottes pirates (`light_fighter`, `heavy_fighter`, `cruiser`, `battleship`, `small_cargo`, `large_cargo`), version pirate (coque disparate, marquages) | 1:1, 512 px | 6 | Détail du raid, rapport de combat (camp pirate) | **À produire**, non branché |
| `pirate_base` | `pirate_base.<0-3>` (ordre de `pirate_bases.list` : avant-poste, repaire, forteresse, citadelle) | 4:3, 640 × 480 | 4 | Cartes des bases (onglet Flotte) | **À produire**, non branché |
| `character` | `character.<clé YAML de l'officier>` (géologue, technocrate, architecte, ingénieur, commandant, directeur de recherche, chef de chantier) | 1:1, 512 px, portrait buste | 7 | Cartes de l'écran Officiers (spec 12) | **À produire**, non branché |
| `story` | `story.<clé YAML de l'événement>` | 16:9, 1280 × 720, sujet centré | 15 (catalogue actuel) | En-tête de la popover d'événement (spec 10, 14) | **15 packagées** (liste : `art/prompts/selection-story.md`) ; branché |
| `scene` | `scene.<raid_won\|raid_lost\|attack_won\|attack_lost\|debris>` | 16:9, 1280 × 720, sujet centré | 5 | En-tête de la popover de fin de combat ; carte du champ de débris | **À produire**, non branché |

### Visuels manquants (2026-11-10, après la série 59)

Par priorité (impact sur l'écran le plus vu d'abord) :

1. `story` × 8 restantes (`art/prompts/selection-story.md`) et `scene` × 5 — en-tête des popovers, porte
   le narratif.
2. `pirate` × 6 — bandeau de raid et rapports, identité de la menace.
3. `building` t2 et t3 × 72 — déjà branchés par les paliers ; à produire avec le t1 du même
   climat en `parent`.
4. `character` × 7 — écran Officiers.
5. `pirate_base` × 4 — onglet Flotte.
6. `background` × 3 — seulement pour l'ambiance Immersive.

Chaque catégorie non branchée demande, en plus de l'image, une méthode de `Visuals` (id →
chemin) et l'appel `GameImage` à l'endroit indiqué, avec repli icône.

Défenses et vaisseaux : images produites (série 58, charte `art/style/unit_prompt.md`), affichées en vignette
sur les cartes d'unités du chantier ; `Visuals.unit` choisit `defense.` ou `ship.` selon le champ `defense`
du YAML. Pas d'icône de ressource générée (vectorielles, spec 10).

### Paliers de bâtiment

Le palier affiché dépend du niveau ; seuils dans le registre (`tiers`), par défaut
`[1, 10, 20]` : t1 du niveau 0 au 9 (niveau 0 = vignette t1 grisée), t2 de 10 à 19, t3 à
partir de 20. Un bâtiment peut surcharger ses seuils (nanites, labo…). Palier sans image
validée → palier inférieur validé du même climat, sinon repli.

### Tranches de température

D'après Tmax (`start.temp_max` : −40 à 80) : **cold** Tmax < 0, **temperate** 0 ≤ Tmax < 40,
**hot** Tmax ≥ 40. Seuils dans le registre (`temperature_bands`). Un bâtiment s'affiche dans le
climat de sa planète, jamais dans un autre : climat sans image → repli.

## Données

`art/registry.yaml` :

```yaml
version: 1
tiers: { default: [1, 10, 20], nanite_factory: [1, 4, 8] }
temperature_bands: { cold: [-1000, 0], temperate: [0, 40], hot: [40, 1000] }
images:
  - id: building.metal_mine.t1.cold
    category: building
    format: "1:1 512"
    status: validated          # todo | draft | validated | deprecated
    version: 2
    parent: null               # id du palier précédent utilisé en référence
    prompt: "open-pit metal mine, heavy excavators, …"
    refs: [style/refs/01.webp, style/refs/03.webp]
    generation: { model: "…", seed: 1234, job_id: "…", series: "…", code: "…" }
    master: art/masters/building.metal_mine.t1.cold/v2.png
    build: assets/visuels/building.metal_mine.t1.cold.webp
    notes: "v1 trop saturée"
```

- `master` : PNG source pleine résolution, gardé **en local** dans `art/masters/`, ignoré par Git.
  Aucune copie versionnée : l'export ne fonctionne que sur la machine qui détient les masters.
- `build` : WebP qualité 80, dimensions du format, Git normal ; nommé par id **sans
  version** : le code charge `assets/visuels/<id>.webp`. Généré depuis le master par
  `python3 tool/export_visuals.py`.
- Brouillons (`draft`) : pas de fichier commité, seulement l'entrée et le `job_id`.
- La CI n'a pas les masters : ils n'entrent jamais dans le build, et le WebP commité suffit.

## Code

`lib/ui/visuals.dart` (id → chemin d'asset, palier, tranche de température, repli) ;
`VisualsScope` posé au-dessus du Navigator (`MaterialApp.builder`) : feuilles, popovers et
écrans poussés y ont accès ;
`assets/visuels/` déclaré dans `pubspec.yaml`, liste lue dans le manifeste d'assets au
démarrage. Le domaine n'en sait rien.

## Tests

`test/ui/visuals_test.dart` — palier selon le niveau et les seuils, tranche selon Tmax, image du
climat, repli quand l'asset manque, vignette grisée, ambiance « Sobre » sans image.
`test/ui/visuals_registry_test.dart` — chaque entrée `validated` a son fichier `build` et
inversement, t1 de chaque bâtiment dans chaque climat, seuils alignés sur le code, poids total
sous 15 Mo.

## Licence

Images générées avec Qwen-Image-2.1, modèle limité à la recherche et à l'évaluation. Décision de
l'utilisateur (2026-11-09) : packagées dans l'APK, pour un usage non commercial uniquement. Tout
projet d'usage commercial rouvre la question.

### Illustrations de popover

`story` et `scene` sont en 16:9, pas en 21:9 : la popover fait environ 350 dp de large sur un
téléphone vertical, et une image de 21:9 n'y ferait que 150 dp de haut. En 16:9, elle fait environ
197 dp, et la popover défile. Le sujet est centré, sans rien d'important près des bords. Décision de
l'utilisateur (2026-11-10), charte `art/style/story_prompt.md`.

### Hero planète

Panorama au sol vu d'une crête : la colonie au tiers de la largeur, posée sur une falaise, une
géante gazeuse et une lune dans un ciel bleu, avec une ambiance optimiste. Le tiers bas reste un sol
rocheux, parce que le bandeau du nom le couvre. L'image n'est jamais recadrée : elle s'affiche en
entier sur la largeur de l'écran. Le froid et le chaud sont déclinés depuis le tempéré
(`denoise` 0,90).

**Évolution ultérieure (hors V0) : biomes de planète.** D'autres jeux de 3 climats, avec d'autres
paysages (cratère, côte, canyon, mesas…). Le jeu affiché se déduit de Tmax, qui est déjà tirée avec une
graine stockée : jeu = Tmax modulo le nombre de biomes. Pas de migration ni de changement de
sauvegarde. Id envisagé : `planet_hero.<biome>.<climat>`, le biome rocheux restant
`planet_hero.<climat>`. Décision de l'utilisateur (2026-11-10) : reporté, le biome rocheux suffit
pour l'instant.

## Points ouverts

- Images 4:3 dédiées à C ou recadrage du 1:1 : à trancher sur les premiers rendus.
- Charte de prompt des catégories `pirate`, `scene`, `character`, `pirate_base` à
  écrire (`art/style/`), comme `unit_prompt.md` pour les unités.
