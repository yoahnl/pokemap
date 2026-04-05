# Architecture propre — règles PokeMap

## Séparation des responsabilités

- **UI** : composition, état d’écran, navigation ; pas de règles métier lourdes inline.
- **Authoring / domaine** : modèles, codecs, mutations pures, parse/compile vers formats persistés.
- **Runtime** : exécution ; ne pas simuler des effets dans l’éditeur sans le dire.
- **Persistence** : sérialisation explicite (JSON, metadata) dans des modules dédiés, pas éparpillée dans les `build()` Flutter.

## Fichiers

- **Pas de fichiers « décharge »** au-delà d’~400–600 lignes sans plan de découpe. Si un fichier mélange 3 responsabilités, le découper **physiquement**.
- **Barrel files** (`export ...`) : légers, un seul niveau d’agrégation lisible ; pas de logique dans le barrel.
- **Nommage** : fichiers et symboles qui disent *ce que c’est* (`cutscene_studio_compiler.dart`, pas `utils2.dart`).

## Mutations et pureté

- Préférer des **fonctions pures** pour transformer le graphe / le document (retourner une nouvelle structure plutôt que muter en place sauf cas très local).
- **Mutations isolées** dans un module clair (ex. `cutscene_studio_flow_mutations.dart`).

## Source de vérité

- Une seule **autorité** par donnée (ex. flow canonique vs projection dérivée). Documenter dans le type ou le module, pas seulement dans un vieux chat.
- **Legacy** : chemins de compatibilité **isolés** et identifiables (parse linéaire, clés metadata, commentaires `// Legacy`).

## Runtime et honnêteté

- Interdit : compiler un bloc en **faux** `wait 0 ms` pour « faire passer » le graphe.
- Obligatoire : **actionKind** explicites (`flowMerge`, `authoringPlaceholder`, etc.) + message ou advisory UI quand le MVP ne fait pas encore l’effet gameplay attendu.

## Modularité vs confort ponctuel

- Si le choix est « un gros fichier pratique aujourd’hui » vs « trois fichiers stables demain », choisir **la modularité**.
- Refactor **physique** plutôt que sections commentées dans un monolithe.

## Exemple de référence (Cutscene Studio)

`packages/map_editor/lib/src/features/narrative/application/cutscene_studio/` :

- `cutscene_studio_models.dart` — types métier, constantes, trim/outcome partagés.
- `cutscene_studio_flow.dart` — projection tronc / flow effectif.
- `cutscene_studio_flow_codec.dart` — JSON metadata.
- `cutscene_studio_flow_mutations.dart` — DnD / édition structurelle.
- `cutscene_studio_parser.dart` / `cutscene_studio_compiler.dart` — allers-retours `ScenarioAsset`.
- `cutscene_studio_templates.dart` — seeds.
- `cutscene_studio_runtime_advisories.dart` — honnêteté MVP.
- `cutscene_studio_authoring.dart` — barrel.
