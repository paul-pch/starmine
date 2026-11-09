# Série 05 : mine de métal

Fichiers : fichier de série supprimé, prompts dans `run.json`, charte `art/style/base_prompt.md`. Qwen-Image-2.1, seeds 4242
et 7777, 1024 × 1024, 25 passes, cfg 1, `euler` / `simple`. 2 images. Prompts complets : `run.json`,
dans le dossier de sortie.

## Fiche

Réponses de l'utilisateur aux questions proposées : mine à flanc de falaise, foreuse géante,
high-tech empoussiéré, filons dans la paroi.

```yaml
id: building.metal_mine.t1
sujet: mine ouverte dans la falaise, autour d'une foreuse colossale
élément clé: la tête de forage qui attaque la roche
cadrage: charte (vue basse de trois quarts, de loin, installation entière)
interdit: aspect abandonné ou post-apocalyptique
critères:
  - la foreuse domine l'image et se reconnaît à 512 px
  - l'installation est ancrée dans la falaise
  - les filons se lisent comme du métal dans la roche, pas comme des plaques plates
  - poussiéreux mais en activité (machines éclairées), jamais abandonné
  - les 2 seeds respectent les mêmes critères
```

## Essai 1

Dérogation à la charte : `state`, avec des machines couvertes de poussière de roche.

Hypothèse : un seul élément nommé, la foreuse, donne une mine reconnaissable sans revenir à l'aspect
post-apocalyptique.

### Notes proposées par Claude

2 images vues en taille réelle et à 512 px. L'utilisateur n'a pas encore noté.

| Critère | 4242 | 7777 |
| --- | --- | --- |
| Foreuse dominante, reconnue à 512 px | oui | moyen : tête en boule, moins lisible |
| Ancrée dans la falaise | moyen : machine qui perce la paroi, pas un bâtiment | moyen : idem |
| Filons lisibles comme du métal | oui | moyen : plaques plus épaisses, au motif de trame |
| En activité, machines éclairées | non : presque aucune lumière | non : presque aucune lumière |
| Jamais abandonné | oui : véhicules et personnel | oui : véhicules et personnel |
| Mêmes critères sur les 2 seeds | non | non |

### Observations

- 4242 est nettement la meilleure : foreuse cylindrique, argent et cuivre bien lisibles dans la paroi.
- Les « light strips » ne ressortent plus quand le prompt demande de la poussière et des machines
  sombres.
- La poussière se voit peu sur les machines : elles sont plutôt sombres que poussiéreuses.
- La mine se lit comme une machine devant une falaise, sans bâtiment.
- Trame fine visible au zoom sur 7777, sur le terrain et les filons, déjà notée en série 01. Cause
  non établie.

## Retour de l'utilisateur

Le rendu de 4242 est nettement meilleur. L'utilisateur la verrait avec un bâtiment plutôt qu'une
grosse machine seule, en mixant les deux. Suite : série 06.
