---
name: starmine-visuals
description: Produire et faire évoluer les images de Starmine avec ComfyUI en local — générer un brouillon, le faire valider, exporter le WebP, tenir le registre art/registry.yaml. À utiliser pour toute nouvelle image, nouveau palier, retouche d'une image validée ou point d'avancement des visuels.
---

# Visuels Starmine

Règles et formats : `docs/specs/11-visuels.md`. Intégration dans l'UI : skill `starmine-ui`.
Style : **SF réaliste**. Seul l'utilisateur valide une image.

Mise au point d'un prompt et génération (ComfyUI, Qwen-Image-2.1) : skill `starmine-prompt`. Ce
modèle est limité à la recherche et à l'évaluation : ses images ne passent pas par la boucle
ci-dessous sans décision explicite de l'utilisateur.

État actuel : 36 images t1 retenues (12 bâtiments × froid, tempéré, chaud), listées dans
`art/prompts/selection-t1-rocheux.md` et inscrites au registre. Masters dans
`art/masters/building.<bâtiment>.t1.<temperate|cold|hot>/v1.png`, WebP chargés par le jeu dans
`assets/visuels/`.

## Avant de générer

- Vérifier que ComfyUI répond sur `localhost:8188`. Sinon : le dire. Ne pas contourner par un
  autre service.
- Lire `art/style/base_prompt.md` et l'entrée du registre ; la créer en `todo` si absente.
- Annoncer le nombre d'images et le temps estimé avant un lot (> 4).

## Boucle d'une image

1. **Prompt** = prompt de base + partie spécifique (sujet, cadrage). Jamais de texte, de
   chiffre, de logo ni d'interface dans l'image. Format et ratio de la spec 11.
2. **Références** : images de `art/style/refs/` ; pour un palier N+1, l'image validée du
   palier N (`parent`) pour garder le même bâtiment, en plus grand / plus avancé.
3. **Brouillon** : 2 à 4 propositions, montrées à l'utilisateur. Entrée `draft` avec
   `prompt_id`, modèle, seed, prompt. Rien d'autre n'est commité.
4. **Validation** par l'utilisateur (explicite). Alors :
   - master PNG → `art/masters/<id>/v<N>.png` (Git LFS). Si la session ne peut pas
     télécharger l'image (réseau restreint) ou pousser l'objet LFS, demander à
     l'utilisateur de déposer / pousser le master, et continuer avec le reste ;
   - entrée `validated`, `version` = N, chemins `master` / `build` ;
   - WebP → `assets/visuels/<id>.webp` aux dimensions du format, qualité 80 :
     `python3 tool/export_visuals.py`.
5. **Retouche d'une image validée** : nouvelle version N+1 (jamais d'écrasement du master) ;
   le WebP `build` est remplacé, l'ancienne version reste décrite dans `notes`.

## Point d'avancement

Sur demande (« où en sont les visuels ? ») : compter les entrées du registre par catégorie
et statut, lister les `todo` du prochain palier logique, donner le poids total de
`assets/visuels/`. Comparer avec le catalogue de la spec 11 (clés du YAML de jeu) : tout
élément de `assets/game_data.yaml` sans entrée est signalé.

## Livrer

- Un commit par image ou petit lot validé : « Visuel : building.metal_mine.t1 v2 ».
- Push sur `main`, puis `tool/ci.sh wait` (skill `starmine-ci`) : le test de cohérence
  registre ↔ fichiers doit passer.
- Mettre à jour le registre dans le même commit que les fichiers.
