# NS-SCENES-V1-72 — Evidence Pack

## Gate 0

```text
pwd => /Users/karim/Project/pokemonProject
branch => main
git status --short --untracked-files=all => <vide>
git diff --stat => <vide>
git diff --name-only => <vide>
```

## RED

```text
Model RED:
cd packages/map_core && dart test --reporter=compact test/cinematic_asset_test.dart --name "serializes cinematic stage context without duplicating map id"
Exit 1
Missing: CinematicStageBackdropMode, CinematicActorBindingKind, CinematicActorBinding,
CinematicActorInitialPlacementKind, CinematicActorInitialPlacement,
CinematicMovementTargetBindingKind, CinematicMovementTargetBinding,
CinematicStageContext, CinematicAsset.stageContext.

Authoring RED:
cd packages/map_core && dart test --reporter=compact test/cinematic_authoring_operations_test.dart --name "updates cinematic stage map and backdrop without mutating timeline|upserts and removes actor bindings with validation|upserts placements and target bindings while preserving legacy bridge"
Exit 1
Missing: updateCinematicStageMap, updateCinematicStageContext,
upsert/remove actor binding, upsert/remove initial placement,
upsert/remove movement target binding.

Diagnostics RED:
cd packages/map_core && dart test --reporter=compact test/cinematic_diagnostics_test.dart --name "diagnoses unknown stage map and projectMap backdrop readiness|allows cinematic without stage context as draft|diagnoses actor binding issues and preview readiness|diagnoses initial placement issues and preview readiness|diagnoses movement target binding issues"
Exit 1
Missing stage diagnostic codes.
```

## GREEN ciblés

```text
cd packages/map_core && dart test --reporter=compact test/cinematic_asset_test.dart
+8: All tests passed!

cd packages/map_core && dart test --reporter=compact test/project_manifest_cinematics_test.dart
+6: All tests passed!

cd packages/map_core && dart test --reporter=compact test/cinematic_authoring_operations_test.dart
+37: All tests passed!

cd packages/map_core && dart test --reporter=compact test/cinematic_diagnostics_test.dart
+24: All tests passed!

cd packages/map_core && dart test --reporter=compact test/cinematic_timeline_time_layout_read_model_test.dart
+4: All tests passed!

cd packages/map_core && dart test --reporter=compact test/cinematic_timeline_lane_read_model_test.dart
+2: All tests passed!
```

## GREEN large

```text
cd packages/map_core && dart test --reporter=compact
+2354: All tests passed!

cd packages/map_core && dart analyze
Analyzing map_core...
No issues found!

cd packages/map_editor && flutter test --reporter=compact test/cinematics_library_workspace_test.dart
+10: All tests passed!

cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
+93: All tests passed!
```

## Analyse editor globale

```text
cd packages/map_editor && flutter analyze
Exit 1
344 issues found. (ran in 3.0s)
```

Signal utile : dette hors lot dans `pokemon_sdk_move_catalog_converter.dart` et `sync_pokemon_sdk_moves_catalog_use_case.dart`. Aucun fichier `packages/map_editor` n'est modifie par V1-72.

## Anti-scope

```text
git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle examples
<vide>

rg runtime/playback/pathfinding/image/Selbrume sur les fichiers modifies
<vide>

rg startMs/endMs/persisted playback sur models/authoring/diagnostics core
<vide>

rg stageContext/mapId
packages/map_core/test/project_manifest_cinematics_test.dart:104: expect(cinematicJson['stageContext'], isNot(contains('mapId')));
```

Interpretation : le seul match `stageContext/mapId` est le test qui verifie que `stageContext` ne contient pas de `mapId`.

## Diff final avant rapport

```text
7 files changed, 1564 insertions(+)
```

Les rapports/roadmaps ajoutent ensuite les artefacts de cloture V1-72.

