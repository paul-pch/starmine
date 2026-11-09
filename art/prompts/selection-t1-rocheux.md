# Sélection t1, roche grise

Première version des 12 bâtiments, choisie par l'utilisateur. Sélection de travail en recherche et évaluation.

Images générées dans `~/ComfyUI/output/starmine_test/<série>/`. Seed et prompt complet dans le `run.json` de
chaque série.

| Bâtiment | Série | Image | Journal |
| --- | --- | --- | --- |
| `metal_mine` | `serie-08-metal-mine` | `metal_mine-4242` | `serie-06-metal-mine.md` |
| `crystal_mine` | `serie-09-crystal-mine` | `crystal_mine-4242` | `serie-09-crystal-mine.md` |
| `deuterium_synthesizer` | `serie-10-deuterium` | `deuterium_synthesizer-4242` | `serie-10-deuterium.md` |
| `solar_plant` | `serie-11-solar` | `solar_plant-4242` | `serie-11-solar.md` |
| `fusion_reactor` | `serie-12-fusion` | `fusion_reactor-4242` | `serie-12-fusion.md` |
| `metal_storage` | `serie-13-metal-storage` | `metal_storage-4242` | `serie-13-metal-storage.md` |
| `crystal_storage` | `serie-14-crystal-storage` | `crystal_storage-4242` | `serie-14-crystal-storage.md` |
| `deuterium_tank` | `serie-16-deuterium-tank` | `deuterium_tank-4242` | `serie-16-deuterium-tank.md` |
| `robotics_factory` | `serie-04-robotics` | `robotics_factory-4242` | `serie-04-robotics.md` |
| `nanite_factory` | `serie-03-construction` | `nanite_factory-4242` | `serie-03-construction.md` |
| `shipyard` | `serie-18-shipyard` | `B-shipyard-4242` | `serie-18-shipyard.md` |
| `research_lab` | `serie-17-research-lab` | `research_lab-7777` | `serie-17-research-lab.md` |

## Déclinaisons de température retenues

Travail bâtiment par bâtiment, décidé par l'utilisateur.

| Bâtiment | Climat | Série | Image | État |
| --- | --- | --- | --- | --- |
| `metal_mine` | froid | `serie-28-metal-mine` | `d90-metal_mine_cold-4242` | retenue |
| `metal_mine` | chaud | `serie-28-metal-mine` | `d90-metal_mine_hot-4242` | retenue |
| `crystal_mine` | froid | `serie-27-crystal-mine` | `d90-crystal_mine_cold-4242` | retenue |
| `crystal_mine` | chaud | `serie-27-crystal-mine` | `d90-crystal_mine_hot-4242` | retenue |
| `research_lab` | froid | `serie-29-research-lab` | `d90-research_lab_cold-7777` | retenue |
| `research_lab` | chaud | `serie-29-research-lab` | `d90-research_lab_hot-7777` | retenue |
| `deuterium_synthesizer` | froid | `serie-19-temperature` | `deuterium_synthesizer_cold-4242` | retenue |
| `deuterium_synthesizer` | chaud | `serie-30-deuterium` | `d90-deuterium_synthesizer_hot-4242` | retenue |
| `solar_plant` | froid | `serie-33-solar-cold-masque` | `raw-solar_plant_cold-4242` | retenue |
| `solar_plant` | chaud | `serie-31-solar` | `d90-solar_plant_hot-4242` | retenue |
| `fusion_reactor` | froid | `serie-35-fusion` | `d90-fusion_reactor_cold-4242` | retenue |
| `fusion_reactor` | chaud | `serie-35-fusion` | `d90-fusion_reactor_hot-4242` | retenue |
| `metal_storage` | froid | `serie-36-metal-storage` | `d90-metal_storage_cold-4242` | retenue |
| `metal_storage` | chaud | `serie-36-metal-storage` | `d90-metal_storage_hot-4242` | retenue |
| `crystal_storage` | froid | `serie-37-crystal-storage` | `d90-crystal_storage_cold-4242` | retenue |
| `crystal_storage` | chaud | `serie-37-crystal-storage` | `d90-crystal_storage_hot-4242` | retenue |
| `deuterium_tank` | froid | `serie-38-deuterium-tank` | `d90-deuterium_tank_cold-4242` | retenue |
| `deuterium_tank` | chaud | `serie-38-deuterium-tank` | `d90-deuterium_tank_hot-4242` | retenue |
| `robotics_factory` | froid | `serie-39-robotics` | `d90-robotics_factory_cold-4242` | retenue |
| `robotics_factory` | chaud | `serie-39-robotics` | `d90-robotics_factory_hot-4242` | retenue |
| `nanite_factory` | froid | `serie-40-nanite` | `d90-nanite_factory_cold-4242` | retenue |
| `nanite_factory` | chaud | `serie-40-nanite` | `d90-nanite_factory_hot-4242` | retenue |
| `shipyard` | froid | `serie-41-shipyard` | `d90-shipyard_cold-4242` | retenue |
| `shipyard` | chaud | `serie-41-shipyard` | `d90-shipyard_hot-4242` | retenue |

Copies dans le dépôt : masters `art/masters/building.<bâtiment>.t1.<temperate|cold|hot>/v1.png`, WebP
`assets/visuels/building.<bâtiment>.t1.<temperate|cold|hot>.webp`, entrées dans `art/registry.yaml`.

Le deutérium froid précède la règle « seed t1 et départ depuis l'image validée » : il a été généré sans image
de départ. Réglage des déclinaisons : `denoise` 0,90, retenu par l'utilisateur.

## Reste à faire

- Paliers t2 et t3 : grandissent par ajouts d'éléments, pas par la taille seule.
- Licence : décider du modèle des images finales avant toute release. Ces 36 images sont packagées
  depuis l'intégration à l'APK, à la demande de l'utilisateur.
