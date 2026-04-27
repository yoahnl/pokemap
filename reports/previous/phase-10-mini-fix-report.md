# Phase 10 — Mini-fix post-review

## Résumé exécutif

Le bug corrigé est le parse des types du Pokédex in-game.

Le chargeur runtime lisait `typing.primary` / `typing.secondary`, alors que le schéma consolidé du repo pour les species est `typing.types`.

Le mini-fix remplace ce parse par la lecture de `typing.types`, conserve l’ordre source, filtre les valeurs vides, et laisse le reste de la projection runtime inchangé.

## Bug corrigé exactement

- avant : le chargeur runtime lisait un shape de types incorrect pour le repo actuel
- après : le chargeur runtime lit `typing.types`
- l’ordre des types est conservé
- les chaînes vides ou blanches ne sont pas remontées à l’UI

## Audit du schéma réel de `typing`

Audit local confirmé par sub-agent :

- `packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart`
  - `PokemonSpeciesTyping.fromJson(...)` lit `json['types']`
- `packages/map_editor/lib/src/application/use_cases/seed_pokemon_demo_data_use_case.dart`
  - les seeds écrivent `typing: { "types": [...] }`
- multiples tests editor lisent ou écrivent `typing.types`, par exemple :
  - `packages/map_editor/test/pokemon_database_index_test.dart`
  - `packages/map_editor/test/file_pokemon_read_repository_test.dart`
  - `packages/map_editor/test/list_pokedex_entries_use_case_test.dart`
  - `packages/map_editor/test/pokemon_project_data_reader_test.dart`

Pendant l’audit, le seul usage de `typing.primary/secondary` trouvé dans le repo était :

- `examples/playable_runtime_host/lib/src/runtime_pokedex_loader.dart`
- `examples/playable_runtime_host/test/runtime_pokedex_loader_test.dart`

Verdict : le schéma réel consolidé du repo est `typing.types`.

## Décision sur le fallback de compatibilité

Pas de fallback `primary/secondary` conservé.

Raison :

- l’audit du repo n’a pas montré de shape species legacy réellement supporté aujourd’hui avec `typing.primary/secondary`
- garder ce fallback aurait conservé une compatibilité hypothétique non prouvée
- le mini-fix reste donc strictement aligné sur le contrat réel actuel

## Périmètre inclus

- correction du parse des types dans le chargeur Pokédex runtime
- renforcement du test ciblé pour couvrir le vrai shape `typing.types`
- report concis du mini-fix

## Périmètre exclu

- aucun changement à `main.dart`
- aucun changement à `in_game_menu.dart`
- aucun changement au save/load
- aucun changement à `project.json`
- aucun changement dans `map_core`, `map_runtime`, `map_gameplay` ou `map_editor`
- aucun lot 52+

## Fichiers modifiés

- `examples/playable_runtime_host/lib/src/runtime_pokedex_loader.dart`
- `examples/playable_runtime_host/test/runtime_pokedex_loader_test.dart`
- `reports/phase-10-mini-fix-report.md`

## Justification fichier par fichier

### `examples/playable_runtime_host/lib/src/runtime_pokedex_loader.dart`

- correction de la racine du bug
- ajout d’un helper dédié à la lecture de `typing.types`
- commentaires renforcés sur :
  - le rôle du chargeur runtime
  - l’indépendance vis-à-vis de `map_editor`
  - le contrat réel de parse des types
  - l’absence volontaire de fallback legacy non prouvé

### `examples/playable_runtime_host/test/runtime_pokedex_loader_test.dart`

- la fixture utilisait le mauvais shape `primary/secondary`
- elle a été réalignée sur `typing.types`
- le test vérifie maintenant explicitement :
  - lecture du shape réel
  - ordre conservé
  - filtrage des valeurs vides
  - tri global inchangé par `nationalDex` puis `id`

### `reports/phase-10-mini-fix-report.md`

- report concis du mini-fix post-review

## Commandes réellement exécutées

```bash
sed -n '1,260p' /Users/karim/Project/pokemonProject/examples/playable_runtime_host/lib/src/runtime_pokedex_loader.dart
sed -n '1,260p' /Users/karim/Project/pokemonProject/examples/playable_runtime_host/test/runtime_pokedex_loader_test.dart
sed -n '190,220p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart
sed -n '330,365p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/seed_pokemon_demo_data_use_case.dart
rg -n "typing|types" /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/models /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application /Users/karim/Project/pokemonProject/packages/map_core/lib /Users/karim/Project/pokemonProject -g '*.dart' -g '*.json'
rg -n '\"typing\"\\s*:\\s*\\{[^\\n]*\"primary\"|\"secondary\"|\"types\"\\s*:\\s*\\[' /Users/karim/Project/pokemonProject -g '*.json' -g '*.dart'
dart format /Users/karim/Project/pokemonProject/examples/playable_runtime_host/lib/src/runtime_pokedex_loader.dart /Users/karim/Project/pokemonProject/examples/playable_runtime_host/test/runtime_pokedex_loader_test.dart
cd /Users/karim/Project/pokemonProject/examples/playable_runtime_host && flutter test test/runtime_pokedex_loader_test.dart
cd /Users/karim/Project/pokemonProject/examples/playable_runtime_host && flutter analyze --no-pub lib/src/runtime_pokedex_loader.dart test/runtime_pokedex_loader_test.dart
cd /Users/karim/Project/pokemonProject && git status --short -- examples/playable_runtime_host/lib/src/runtime_pokedex_loader.dart examples/playable_runtime_host/test/runtime_pokedex_loader_test.dart reports/phase-10-mini-fix-report.md
cd /Users/karim/Project/pokemonProject && git diff --stat -- examples/playable_runtime_host/lib/src/runtime_pokedex_loader.dart examples/playable_runtime_host/test/runtime_pokedex_loader_test.dart
cd /Users/karim/Project/pokemonProject && git ls-files --others --exclude-standard -- reports/phase-10-mini-fix-report.md
```

## Résultats réels

- `dart format`
  - `Formatted 2 files (0 changed) in 0.01 seconds.`

- `flutter test test/runtime_pokedex_loader_test.dart`
  - `All tests passed!`

- `flutter analyze --no-pub lib/src/runtime_pokedex_loader.dart test/runtime_pokedex_loader_test.dart`
  - `No issues found! (ran in 1.1s)`

## Incidents rencontrés

- un premier `apply_patch` a timeout ; le fichier a été relu immédiatement pour vérifier qu’aucun demi-patch n’avait été appliqué, puis le patch a été rejoué proprement par morceaux
- un sub-agent de schéma a mis plus de temps à répondre ; l’audit local avait déjà confirmé le verdict, puis le retour du sub-agent l’a confirmé à l’identique

## État Git utile

`git status --short -- examples/playable_runtime_host/lib/src/runtime_pokedex_loader.dart examples/playable_runtime_host/test/runtime_pokedex_loader_test.dart reports/phase-10-mini-fix-report.md`

```text
 M examples/playable_runtime_host/lib/src/runtime_pokedex_loader.dart
 M examples/playable_runtime_host/test/runtime_pokedex_loader_test.dart
```

`git diff --stat -- examples/playable_runtime_host/lib/src/runtime_pokedex_loader.dart examples/playable_runtime_host/test/runtime_pokedex_loader_test.dart`

```text
 .../lib/src/runtime_pokedex_loader.dart            | 39 ++++++++++++++++------
 .../test/runtime_pokedex_loader_test.dart          | 11 +++---
 2 files changed, 36 insertions(+), 14 deletions(-)
```

## Limites restantes

- le mini-fix ne tente pas de supporter un shape `typing.primary/secondary` absent du repo consolidé actuel
- la logique `primaryName` (`en` puis `fr`) a été auditée mais laissée intacte, faute de preuve que ce point soit incohérent ou lié à ce bug
