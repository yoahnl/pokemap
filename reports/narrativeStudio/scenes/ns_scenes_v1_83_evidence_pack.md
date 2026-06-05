# NS-SCENES-V1-83 — Evidence Pack

## Gate 0

```text
pwd
/Users/karim/Project/pokemonProject

git branch --show-current
main

git status --short --untracked-files=all
<clean>
```

Dernier commit observe :

```text
c76550a6 feat(narrative): update cinematic workspaces, tests, and roadmap reports (NS-SCENES-V1-82)
```

## TDD

RED initial :

```text
cd packages/map_core
dart test --reporter=compact test/cinematic_map_backdrop_preview_model_test.dart

Failed to load "test/cinematic_map_backdrop_preview_model_test.dart":
Method not found: 'buildCinematicMapBackdropPreviewModel'
Undefined name 'CinematicMapBackdropPreviewStatus'
```

GREEN final :

```text
cd packages/map_core
dart test --reporter=compact test/cinematic_map_backdrop_preview_model_test.dart

00:00 +15: All tests passed!
```

## Tests Core

```text
cd packages/map_core
dart test --reporter=compact test/cinematic_stage_map_source_catalog_test.dart

00:00 +7: All tests passed!
```

```text
cd packages/map_core
dart test --reporter=compact test/cinematic_asset_test.dart

00:00 +14: All tests passed!
```

```text
cd packages/map_core
dart test --reporter=compact test/project_manifest_cinematics_test.dart

00:00 +9: All tests passed!
```

```text
cd packages/map_core
dart analyze

Analyzing map_core...
No issues found!
```

## Tests Editor

```text
cd packages/map_editor
flutter test --reporter=compact test/cinematics_library_workspace_test.dart

00:05 +14: All tests passed!
```

```text
cd packages/map_editor
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart

00:25 +140 -1: Some tests failed.
```

Failure unique observee :

```text
Expected: no matching candidates
Actual: Found 1 widget with type "CupertinoTextField" descending from
widget with key [<'cinematic-builder-inspector-placeholder'>]
placeholder: "Nom de l'acteur"

Test description:
lists timeline steps in order with read-only details
```

Interpretation : ce test attendait encore un inspecteur totalement read-only, alors que le champ de renommage acteur a ete ajoute dans un lot precedent a la demande de Karim. Ce n'est pas cause par le read model V1-83, qui ne modifie aucun fichier `map_editor`.

## Analyse Editor

```text
cd packages/map_editor
flutter analyze

344 issues found.
```

Premieres erreurs :

```text
lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:58:7
The named parameter 'dbSymbol' isn't defined.

lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:64:7
The named parameter 'battleEngineAimedTarget' isn't defined.

lib/src/application/use_cases/sync_pokemon_sdk_moves_catalog_use_case.dart:58:10
The method 'fetchPokemonSdkStudioProjectPayload' isn't defined.
```

Interpretation : dette Pokemon SDK preexistante hors V1-83.

## Anti-Scope

Commande :

```text
git diff --name-only -- packages/map_editor packages/map_runtime packages/map_gameplay packages/map_battle examples selbrume
```

Resultat :

```text
<aucune sortie>
```

Scans sur :

```text
packages/map_core/lib/src/read_models/cinematic_map_backdrop_preview_model.dart
packages/map_core/test/cinematic_map_backdrop_preview_model_test.dart
packages/map_core/lib/map_core.dart
```

Resultats :

```text
rg package:flutter|package:flame|GameWidget|FlameGame|PlayableMapGame|RuntimeMapGame|CameraComponent|Component|GameState|SceneCinematicRuntimeAwaitableAdapter|map_runtime
<aucune sortie>

rg Widget|BuildContext|CustomPainter|Canvas|paint\(|renderBackdrop|Renderer|Painter|Sprite|TilesetImage|ImageProvider
<aucune sortie>

rg startPlayback|stopPlayback|playback|currentTimeMs|playbackTimeMs|isPlaying|Timer\(|Ticker|AnimationController|seek|scrub|scrubber
<aucune sortie>

rg stageContext.*mapId|CinematicStageContext\([^\)]*mapId|mapId.*stageContext
<aucune sortie>

rg selbrume|mael|maël|lysa|port_brisants|bourg_selbrume|phare|brume|marais
<aucune sortie>

rg gpt-image-2|image_generation|generate image|AI image|image model
<aucune sortie>
```

## Code Inventory

Ajoute :

```text
packages/map_core/lib/src/read_models/cinematic_map_backdrop_preview_model.dart
packages/map_core/test/cinematic_map_backdrop_preview_model_test.dart
reports/narrativeStudio/scenes/ns_scenes_v1_83_cinematic_map_backdrop_preview_read_model_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_83_evidence_pack.md
```

Modifie :

```text
packages/map_core/lib/map_core.dart
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
```

## Decision Finale

V1-83 peut etre propose DONE : le read model est livre, teste, exporte et documente. Le prochain lot exact recommande est :

```text
NS-SCENES-V1-84 — Cinematic Map Backdrop Preview Renderer V0
```

## Verification Finale

```text
git diff --check
<aucune sortie>
```

```text
git diff --stat
packages/map_core/lib/map_core.dart                |  1 +
.../scenes/road_map_scene_builder_authoring.md     | 21 +++++++++++++++++--
reports/narrativeStudio/scenes/road_map_scenes.md  | 24 +++++++++++++++++++---
3 files changed, 41 insertions(+), 5 deletions(-)
```

Note : `git diff --stat` ne liste pas les fichiers non suivis. Ils sont visibles dans le statut ci-dessous.

```text
git status --short --untracked-files=all
 M packages/map_core/lib/map_core.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? packages/map_core/lib/src/read_models/cinematic_map_backdrop_preview_model.dart
?? packages/map_core/test/cinematic_map_backdrop_preview_model_test.dart
?? reports/narrativeStudio/scenes/ns_scenes_v1_83_cinematic_map_backdrop_preview_read_model_v0.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_83_evidence_pack.md
```
