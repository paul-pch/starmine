# Série 01 : bâtiments

Série d'exploration demandée par l'utilisateur : garder Qwen-Image-2.1 et la base « planète
rocheuse », tester plusieurs prompts de bâtiments.

Fichiers : `serie-01-batiments.json`, base `art/style/base_prompt.md`, seeds 4242 et 7777, 1024 ×
1024, 25 passes, cfg 1, `euler` / `simple`. Environ 30 s par image.

Hypothèse : le type d'installation et un seul élément fonctionnel nommé suffisent à rendre chaque
bâtiment reconnaissable, en gardant le style. Le cadrage « filling most of the frame » est ajouté à
la base par rapport à l'essai 6 de la mine.

## Notes proposées par Claude

Images vues en taille réelle. Chaque case donne 4242 / 7777. L'utilisateur n'a pas encore noté.

| Bâtiment | Sujet dominant | Structure cohérente | Reconnu à 512 px |
| --- | --- | --- | --- |
| Mine de métal | oui / moyen | oui / oui | oui / oui |
| Mine de cristal | oui / moyen | non / non | oui / oui |
| Synthétiseur de deutérium | oui / oui | oui / oui | oui / oui |
| Centrale solaire | oui / moyen | oui / oui | oui / oui |
| Chantier spatial | oui / oui | oui / oui | oui / oui |
| Laboratoire | oui / moyen | oui / oui | oui / oui |

## Observations

- Hypothèse confirmée : les 6 bâtiments se distinguent sans leur nom, sur les 2 seeds.
- Cohérence de set : même cuvette, même lumière, même roche.
- Le deutérium et le laboratoire sont les plus réussis.
- Mine de cristal : les cristaux portent toute l'identité, le complexe reste un amas de blocs.
- Mine de métal 4242 : les filons au sol ressemblent à des plaques plates.
- Centrale solaire : panneaux en forme de coins, à plat plutôt qu'inclinés.
- Chantier spatial : la coque ressemble à une épave plutôt qu'à un vaisseau en construction.
- Défaut commun : tout paraît abandonné, sombre, presque post-apocalyptique.
- Sur 7777, le sujet reste plus petit, avec une grande zone d'ombre au fond.
- Trame fine sur le terrain, visible au zoom. Cause non établie.
- Le prompt dit « large » pour un palier t1, ce qui ne laisse plus de marge pour t2 et t3.

## Proposition

Essai suivant, un seul changement dans la base : remplacer « gritty » et « weathered » par une
installation active et entretenue, avec de petites lumières. Hypothèse : ces deux mots produisent
l'effet d'abandon. À tester sur les 6 bâtiments, car la base s'applique à tout le set.

## Retour de l'utilisateur

Bon début. L'aspect post-apocalyptique est confirmé comme défaut, et la proposition ci-dessus est
remplacée par une direction par famille :

- poussiéreux : bien pour la mine de métal, et à la rigueur pour la mine de cristal ;
- deutérium : doit être sur la mer ;
- centrale solaire et laboratoire : plus high-tech ;
- chantiers de construction : un grand hangar vu de loin, avec des machines ou des vaisseaux.

Décision : arrêt des tests pour l'instant, sans nouvelle image. La suite est de continuer à
travailler le skill `starmine-prompt`, qui contient cette direction.
