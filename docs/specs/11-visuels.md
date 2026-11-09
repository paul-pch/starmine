# 11 · Visuels et registre d'images

## Objet

Rendre le jeu plus immersif avec des images SF réalistes, sans toucher à la lisibilité d'un
idle de ressources. Les images sont générées hors du jeu (ComfyUI en local), validées une par une,
puis packagées dans l'APK.

État : code d'affichage implémenté (`lib/ui/visuals.dart`, repli) ; **aucune image ni registre
dans le dépôt pour l'instant**. Les seuils `tiers` et `temperature_bands` sont repris dans le
code, à garder alignés sur le registre quand il existera.

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
| `building` | `building.<clé YAML>.t<1-3>` | 1:1, 512 px (B, A) | 12 × 3 paliers |
| `building_wide` | `building_wide.<clé>.t<1-3>` | 4:3, 640 × 480 (C) — facultatif, sinon recadrage du 1:1 | — |
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
validée → palier inférieur validé, sinon repli.

### Tranches de température

D'après Tmax (`start.temp_max` : −40 à 80) : **cold** Tmax < 0, **temperate** 0 ≤ Tmax < 40,
**hot** Tmax ≥ 40. Seuils dans le registre (`temperature_bands`).

## Données

`art/registry.yaml` :

```yaml
version: 1
tiers: { default: [1, 10, 20], nanite_factory: [1, 4, 8] }
temperature_bands: { cold: [-1000, 0], temperate: [0, 40], hot: [40, 1000] }
images:
  - id: building.metal_mine.t1
    category: building
    format: "1:1 512"
    status: validated          # todo | draft | validated | deprecated
    version: 2
    parent: null               # id du palier précédent utilisé en référence
    prompt: "open-pit metal mine, heavy excavators, …"
    refs: [style/refs/01.webp, style/refs/03.webp]
    generation: { model: "…", seed: 1234, job_id: "…" }
    master: art/masters/building.metal_mine.t1/v2.png
    build: assets/visuels/building.metal_mine.t1.webp
    notes: "v1 trop saturée"
```

- `master` : PNG source pleine résolution, suivi par **Git LFS** (`art/masters/**`).
- `build` : WebP qualité 80, dimensions du format, Git normal ; nommé par id **sans
  version** : le code charge `assets/visuels/<id>.webp`.
- Brouillons (`draft`) : pas de fichier commité, seulement l'entrée et le `job_id`.
- La CI ne récupère pas LFS (`actions/checkout` par défaut) : les masters n'entrent jamais
  dans le build.

## Code

`lib/ui/visuals.dart` (id → chemin d'asset, palier, tranche de température, repli) ;
`assets/visuels/` déclaré dans `pubspec.yaml`, liste lue dans le manifeste d'assets au
démarrage. Le domaine n'en sait rien.

## Tests

`test/ui/visuals_test.dart` — palier selon le niveau et les seuils, tranche selon Tmax, repli
quand l'asset manque, ambiance « Sobre » sans image. À créer avec le registre : un test de
cohérence vérifiant que chaque entrée `validated` a son fichier `build` et inversement.

## Points ouverts

- Poids total de l'APK à surveiller (cible : < 15 Mo d'images).
- Images 4:3 dédiées à C ou recadrage du 1:1 : à trancher sur les premiers rendus.
- Portraits des officiers (spec 12) : nouvelle catégorie `character` au registre, à prévoir
  avec la V2c.
