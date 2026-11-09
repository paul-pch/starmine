# 11 · Visuels et registre d'images

## Objet

Rendre le jeu plus immersif avec des images SF réalistes, sans toucher à la lisibilité d'un
idle de ressources. Les images sont générées hors du jeu (ComfyUI en local), validées une par une,
puis packagées dans l'APK.

État : registre `art/registry.yaml` et code d'affichage (`lib/ui/visuals.dart`, repli) en place. Les 36
images t1 des bâtiments (12 × 3 climats, liste : `art/prompts/selection-t1-rocheux.md`) sont packagées
en WebP ; les autres catégories restent en repli. Les seuils `tiers` et `temperature_bands` sont repris
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

| Catégorie | Id | Format | Quantité (V2) |
| --- | --- | --- | --- |
| `building` | `building.<clé YAML>.t<1-3>.<cold\|temperate\|hot>` | 1:1, 512 px (B, A) | 12 × 3 paliers × 3 climats |
| `building_wide` | `building_wide.<clé>.t<1-3>.<cold\|temperate\|hot>` | 4:3, 640 × 480 (C) — facultatif, sinon recadrage du 1:1 | — |
| `research` | `research.<clé YAML>` | 1:1, 512 px | 8 |
| `defense` | `defense.<clé YAML>` | 1:1, 512 px | 8 |
| `pirate` | `pirate.<clé YAML>` | 1:1, 512 px (bandeau de raid, rapports) | 6 |
| `planet_hero` | `planet_hero.<cold\|temperate\|hot>` | 21:9, 1260 × 540 | 3 |
| `background` | `background.<cold\|temperate\|hot>` | 9:19.5, 1080 × 2340, sombre en bas | 3 |

Vaisseaux du joueur : V3. Pas d'icône de ressource générée (vectorielles, spec 10).

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

## Points ouverts

- Images 4:3 dédiées à C ou recadrage du 1:1 : à trancher sur les premiers rendus.
- Portraits des officiers (spec 12) : nouvelle catégorie `character` au registre, à prévoir
  avec la V2c.
