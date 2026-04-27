# Phase 9 Mini-Fix Report

## Résumé exécutif

Mini-fix post-review appliqué sans rouvrir la phase 9.

Corrigé :
- compatibilité legacy au chargement pour les anciennes saves contenant un `PlayerPokemon` pré-phase-9
- couverture de non-régression sur le chemin réel `JSON disque -> repository runtime -> GameState -> save`
- suppression des commentaires dans les fichiers manuels effectivement touchés
- réalignement du seul fixture phase-9 prouvé incohérent côté ids (`quick_attack`)

Non modifié :
- `project.json`
- la stack save/runtime hors besoin direct
- les lots 48+
- `analysis_options.yaml` en état final

## Problèmes corrigés exactement

1. Une ancienne save pouvait casser au load dès qu’un `PlayerPokemon` ne portait pas encore `natureId` et `abilityId`.
2. Le chemin runtime complet ne prouvait pas encore que les champs hors phase 9 restaient préservés après migration legacy.
3. Les fichiers touchés contenaient encore des commentaires malgré la discipline demandée.
4. Un fixture phase-9 utilisait `quick-attack` alors que les `moveId` multi-mots du repo sont normalisés en `snake_case`.

## Périmètre inclus

- `packages/map_core/lib/src/models/save_data.dart`
- `packages/map_core/test/save_data_test.dart`
- `packages/map_runtime/test/file_game_save_repository_test.dart`
- ce report

## Périmètre exclu

- toute réimplémentation des lots 44 à 47
- tout nouveau modèle concurrent `OwnedPokemon` ou `SaveGame`
- `project.json`
- les lots 48 à 51
- `examples/playable_runtime_host`
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- tout refactor transverse `map_core` / `map_runtime` / `map_gameplay`

## Audit legacy

Audit réel du shape pré-phase-9 :
- via `git show HEAD^:packages/map_core/lib/src/models/save_data.dart`
- l’ancien `PlayerPokemon` ne portait que `id`, `speciesId`, `nickname`, `level`, `knownMoveIds`, `isFainted`

Décision retenue :
- la migration doit vivre au bord du parse JSON de `PlayerPokemon`
- pas dans un second modèle
- pas dans un second système de save
- pas dans le repository runtime

Fallbacks retenus après audit :
- `natureId` manquant sur save legacy : `hardy`
- `abilityId` manquant sur save legacy : `unknown`
- `currentHp` manquant sur save legacy : dérivé de `isFainted`

Règle appliquée :
- la tolérance n’existe que pour un shape legacy identifiable
- un JSON non legacy mais incomplet continue d’échouer

## Audit conventions d’ids

Audit réel du repo :
- `moveId` multi-mots : `snake_case`
- `natureId` : tokens simples lowercase
- `itemId` dans les fixtures phase-9 : `kebab-case`
- `abilityId` : mixte selon les couches ; le pipeline Pokédex pousse plutôt vers `snake_case`, mais les fixtures runtime/save existantes restent en `kebab-case`

Décision retenue :
- pas de mass rename transverse
- pas de normalisation arbitraire des `abilityId` et `itemId` dans ce mini-fix
- correction uniquement du cas prouvé incohérent :
  - `quick-attack` -> `quick_attack`

## Décision sur `analysis_options.yaml`

Décision finale :
- changement conservé en l’état
- aucun diff final sur `packages/map_core/analysis_options.yaml`

Preuve réelle :
- ignore retiré temporairement
- `dart analyze lib/src/models/save_data.dart test/save_data_test.dart`
- résultat : 8 warnings `invalid_annotation_target` sur `save_data.dart`
- ignore restauré ensuite

Conclusion :
- l’ignore package-local reste nécessaire à l’état actuel
- ce mini-fix ne l’élargit pas et ne le modifie pas en sortie

## Sub-agents utilisés

- `Laplace` : audit compatibilité legacy
- `Kierkegaard` : audit conventions d’ids
- `Newton` : revue de discipline / commentaires / `analysis_options.yaml`
- `Bacon` : revue de couverture de tests

Intégration finale :
- une seule implémentation conservée
- aucune variante concurrente laissée dans le working tree

## Justification fichier par fichier

### `packages/map_core/lib/src/models/save_data.dart`

- ajout d’un shim minimal de migration legacy dans `PlayerPokemon.fromJson`
- aucun nouveau modèle
- suppression des commentaires présents dans le fichier

### `packages/map_core/test/save_data_test.dart`

- ajout d’un test unitaire de migration legacy
- ajout d’un test prouvant qu’un JSON non legacy incomplet continue d’échouer
- réalignement de `quick_attack`

### `packages/map_runtime/test/file_game_save_repository_test.dart`

- ajout d’un test E2E de load legacy puis resave normalisé
- ajout d’un test de corruption réelle au load sans réécriture parasite
- suppression des commentaires présents dans le fichier

## Commandes réellement exécutées

Audit :
- `git status --short`
- `git diff --stat`
- `git show HEAD^:packages/map_core/lib/src/models/save_data.dart | sed -n '1,220p'`
- `sed -n '1,260p' packages/map_core/lib/src/models/save_data.dart`
- `sed -n '1,260p' packages/map_runtime/test/file_game_save_repository_test.dart`
- `sed -n '1,240p' packages/map_core/test/save_data_test.dart`
- `sed -n '1,220p' packages/map_core/lib/src/operations/game_state_persistence.dart`
- `sed -n '1,220p' packages/map_runtime/lib/src/infrastructure/file_game_save_repository.dart`
- `rg -n "water-absorb|mystic-water|poke-ball|quick-attack|water_absorb|mystic_water|poke_ball|quick_attack" ...`
- `sed -n '220,310p' packages/map_editor/lib/src/application/services/external_pokemon_catalog_normalizer.dart`
- `sed -n '340,390p' packages/map_editor/lib/src/application/services/showdown_pokemon_species_converter.dart`
- `cat packages/map_core/analysis_options.yaml`

Validation :
- `dart format packages/map_core/lib/src/models/save_data.dart packages/map_core/test/save_data_test.dart packages/map_runtime/test/file_game_save_repository_test.dart`
- `cd packages/map_core && dart test test/save_data_test.dart`
- `cd packages/map_runtime && flutter test test/file_game_save_repository_test.dart`
- `cd packages/map_core && dart analyze lib/src/models/save_data.dart test/save_data_test.dart`
- `cd packages/map_runtime && flutter analyze --no-pub test/file_game_save_repository_test.dart`

Contrôle spécifique `analysis_options.yaml` :
- retrait temporaire local de l’ignore
- `cd packages/map_core && dart analyze lib/src/models/save_data.dart test/save_data_test.dart`
- restauration immédiate de l’ignore
- `cd packages/map_core && dart analyze lib/src/models/save_data.dart test/save_data_test.dart`

## Résultats réels

- `dart format`
  - `Formatted /Users/karim/Project/pokemonProject/packages/map_runtime/test/file_game_save_repository_test.dart`
  - `Formatted 3 files (1 changed) in 0.02 seconds.`
  - `Formatted 1 file (0 changed) in 0.01 seconds.`

- `cd packages/map_core && dart test test/save_data_test.dart`
  - `00:00 +21: All tests passed!`

- `cd packages/map_runtime && flutter test test/file_game_save_repository_test.dart`
  - passe finale : `00:01 +13: All tests passed!`

- `cd packages/map_core && dart analyze lib/src/models/save_data.dart test/save_data_test.dart`
  - avec ignore : `No issues found!`
  - sans ignore : `8 issues found.` avec `invalid_annotation_target`

- `cd packages/map_runtime && flutter analyze --no-pub test/file_game_save_repository_test.dart`
  - première passe : `1 issue found.` (`prefer_const_constructors`)
  - passe finale : `No issues found! (ran in 1.5s)`

## Incidents rencontrés

- un seul incident réel pendant la validation :
  - `flutter analyze` a signalé un `prefer_const_constructors` dans le nouveau test runtime
  - corrigé immédiatement

## État Git utile

`git status --short`

```text
 M packages/map_core/lib/src/models/save_data.dart
 M packages/map_core/test/save_data_test.dart
 M packages/map_runtime/test/file_game_save_repository_test.dart
?? reports/phase-9-mini-fix-report.md
```

`git diff --stat`

```text
 packages/map_core/lib/src/models/save_data.dart    |  49 ++++---
 packages/map_core/test/save_data_test.dart         |  29 +++-
 .../test/file_game_save_repository_test.dart       | 150 +++++++++++++++++++--
 3 files changed, 197 insertions(+), 31 deletions(-)
```

## Limites restantes

- la migration legacy ne reconstitue pas une vraie `abilityId` historique, faute de source de vérité disponible dans l’ancienne save ; elle injecte un fallback stable `unknown`
- le mini-fix ne tente pas de normaliser globalement les ids `abilityId` / `itemId` à l’échelle du repo, parce que l’audit a montré un état mixte selon les couches

