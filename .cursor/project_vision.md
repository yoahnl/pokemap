# Vision produit — PokeMap

## Ce que PokeMap est

PokeMap n’est **pas** « un éditeur de maps » seul. C’est un **outil de création de jeu** dans la veine Pokémon moderne : structuré, guidé, **très no-code**, lisible par une personne qui ne lit pas le code.

## Principes non négociables

1. **Lisibilité** — L’utilisateur comprend *ce qu’il configure* sans traduire du jargon moteur.
2. **Hiérarchie** — Une action a une place claire (où ça vit, à quel niveau du jeu).
3. **Concepts métier** — Parler de scènes, personnages, drapeaux, cartes, pas de « nodes » ou « payloads » dans l’UI grand public.
4. **Séparation des mondes** — Monde / contenu narratif / progression / runtime d’exécution : frontières explicites dans le code comme dans le discours produit.
5. **Pas d’outil dev déguisé** — Si une surface ressemble à un IDE, elle a raté sa cible pour le public no-code.

## Conséquences pour le code

- L’**authoring** (données + UX éditeur) ne doit pas être noyé dans les widgets : modèles et mutations testables à part.
- Le **runtime** doit rester **honnête** : pas de comportement silencieux qui ment sur ce qui s’exécute vraiment.
- Les **compromis** (placeholder, MVP, legacy) doivent être **nommés** et documentés (commentaires, advisories, rapports).

## Références dans le repo

- `AGENTS.md` — périmètre packages et validation.
- `packages/map_editor/reports/` — rapports d’ingénierie après passes structurantes.
- Cutscene Studio — module sous `application/cutscene_studio/` (voir `cutscene_studio_rules.md`).
