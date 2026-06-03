# NS-SCENES-V1-69 — Evidence Pack

## Gate 0 complet

```text
pwd
/Users/karim/Project/pokemonProject

git branch --show-current
main

git status --short --untracked-files=all
<vide>

git diff --stat
<vide>

git diff --name-only
<vide>

git log --oneline -n 15
263233b4 feat(narrative): add cinematic timeline duration inspector editing v0 (NS-SCENES-V1-68)
c8bb19a2 feat(narrative): add cinematic timeline duration editing resize prep contract (NS-SCENES-V1-67)
e67e71c7 feat(narrative): add cinematic timeline mouse probe help selection explanation v0 (NS-SCENES-V1-66)
46cc0eb4 feat(narrative): add cinematic timeline mouse probe UX polish clear controls v0 (NS-SCENES-V1-65)
95e79063 feat(narrative): add cinematic timeline mouse probe boundary snap v0 (NS-SCENES-V1-64)
86004392 feat(narrative): add cinematic timeline mouse probe polish boundary snap prep v0 (NS-SCENES-V1-63)
79414165 feat(narrative): add cinematic timeline mouse time probe playhead drag v0 (NS-SCENES-V1-62)
044155fc feat(narrative): add cinematic timeline mouse playhead scrub prep contract (NS-SCENES-V1-61)
32f92c54 feat(narrative): add cinematic timeline keyboard navigation polish help overlay v0 (NS-SCENES-V1-60)
ede69519 feat(narrative): add cinematic timeline lane vertical navigation v0 (NS-SCENES-V1-59)
e1e83cd9 feat(narrative): add cinematic timeline lane vertical navigation prep contract (NS-SCENES-V1-58)
26958d88 feat(narrative): add cinematic timeline keyboard navigation selection polish v0 (NS-SCENES-V1-57)
af8a3bf9 feat(narrative): add cinematic timeline bar geometry duration scale correction v0 (NS-SCENES-V1-56)
16a888b1 feat(narrative): add cinematic timeline visual polish density pass and interaction polish hover details v0 (NS-SCENES-V1-54-V1-55)
13f423c1 feat(narrative): add cinematic timeline transport controls placeholder v0 (NS-SCENES-V1-53)
```

## Fichiers lus

```text
AGENTS.md
agent_rules.md
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/ns_scenes_v1_68_cinematic_timeline_duration_inspector_editing_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_67_cinematic_timeline_duration_editing_resize_prep_contract.md
reports/narrativeStudio/scenes/ns_scenes_v1_66_cinematic_timeline_mouse_probe_help_selection_explanation_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_65_cinematic_timeline_mouse_probe_ux_polish_clear_controls_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_64_cinematic_timeline_mouse_probe_boundary_snap_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_62_cinematic_timeline_mouse_time_probe_playhead_drag_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_56_cinematic_timeline_bar_geometry_duration_scale_correction_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_51_cinematic_timeline_time_axis_bar_layout_v0.md
packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart
packages/map_core/lib/src/read_models/cinematic_timeline_time_layout_read_model.dart
packages/map_core/lib/src/read_models/cinematic_timeline_lane_read_model.dart
packages/map_core/test/cinematic_authoring_operations_test.dart
packages/map_core/test/cinematic_timeline_time_layout_read_model_test.dart
packages/map_core/test/cinematic_timeline_lane_read_model_test.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
packages/map_editor/test/cinematics_library_workspace_test.dart
```

## RED test output

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'resizes selected cinematic block duration from right handle'
```

Sortie RED :

```text
Expected: exactly one matching candidate
  Actual: _KeyWidgetFinder:<Found 0 widgets with key
[<'cinematic-builder-duration-resize-handle-step_wait'>]: []>
   Which: means none were found but one was expected
...
The test description was:
  resizes selected cinematic block duration from right handle
00:06 +0 -1: Some tests failed.
```

Note : apres implementation, la fixture de test cible `actorFace` (`step_face`) plutot que `wait`, pour garder le hit-test du handle loin des controles transport sur la surface de reference.

## GREEN test output

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'resizes selected cinematic block duration from right handle'
```

Sortie :

```text
00:00 +0: loading ...
00:01 +0: loading ...
00:01 +0: resizes selected cinematic block duration from right handle
00:02 +0: resizes selected cinematic block duration from right handle
00:02 +1: resizes selected cinematic block duration from right handle
00:02 +1: All tests passed!
```

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name 'right resize handle|non-owned block|marker draft|right handle decreases|duration clamps|duration snaps|left edge is not draggable|hover details remain functional after resize|keyboard navigation remains functional after resize'
```

Sortie :

```text
00:03 +10: All tests passed!
```

Commandes core :

```text
cd packages/map_core && dart test --reporter=compact test/cinematic_authoring_operations_test.dart
00:00 +34: All tests passed!

cd packages/map_core && dart test --reporter=compact test/cinematic_timeline_time_layout_read_model_test.dart
00:00 +4: All tests passed!

cd packages/map_core && dart test --reporter=compact test/cinematic_timeline_lane_read_model_test.dart
00:00 +2: All tests passed!

cd packages/map_core && dart analyze
Analyzing map_core...
No issues found!
```

Commandes editor :

```text
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
00:10 +82: All tests passed!

cd packages/map_editor && flutter test --reporter=compact test/cinematics_library_workspace_test.dart
00:04 +10: All tests passed!
```

Visual Gate :

```text
cd packages/map_editor && flutter test --update-goldens --dart-define=NS_SCENES_V1_69_CAPTURE_CINEMATIC_TIMELINE_DURATION_RESIZE=true --reporter=compact test/cinematic_builder_workspace_test.dart
00:13 +82: All tests passed!
```

## Analyze cible et global

Analyse cible :

```text
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart test/cinematic_builder_workspace_test.dart
Analyzing 2 items...
No issues found! (ran in 2.2s)
```

Analyse globale :

```text
cd packages/map_editor && flutter analyze
Analyzing map_editor...
error • The named parameter 'dbSymbol' isn't defined • lib/src/application/pokemon/pokemon_sdk_move_catalog_converter.dart:58:7
error • The named parameter 'battleEngineAimedTarget' isn't defined • lib/src/application/pokemon/pokemon_sdk_move_catalog_converter.dart:64:7
error • The method 'fetchPokemonSdkStudioProjectPayload' isn't defined • lib/src/application/pokemon/sync_pokemon_sdk_moves_catalog_use_case.dart:58:10
344 issues found. (ran in 3.1s)
```

## Visual Gate preuve

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_69_cinematic_timeline_duration_resize_handles_v0.png
```

```text
ls -l reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_69_cinematic_timeline_duration_resize_handles_v0.png
-rw-r--r--  1 karim  staff  224491 Jun  3 23:21 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_69_cinematic_timeline_duration_resize_handles_v0.png

file reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_69_cinematic_timeline_duration_resize_handles_v0.png
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_69_cinematic_timeline_duration_resize_handles_v0.png: PNG image data, 1663 x 926, 8-bit/color RGBA, non-interlaced

shasum -a 256 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_69_cinematic_timeline_duration_resize_handles_v0.png
795a4363fb3f6f6f4b8692de6015826af01b8173b4510fc528722d9fb4f01995  reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_69_cinematic_timeline_duration_resize_handles_v0.png
```

## Hunks fonctionnels complets — inventaire

Fichier `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart` :

```text
518-550   _resizeTimelineStepDuration : dispatch V1-68 vers basicBlock / actorFace / actorMove, puis clear probe.
3139-3188 _TimelineStepCardState : etat local drag start/update/end/cancel.
3264-3283 insertion du handle droit seulement si selected + editable.
3311-3383 _TimelineDurationResizeDrag et _TimelineDurationResizeHandle.
4620-4652 helpers minimum, eligibility, deltaX -> duration, quantification 100 ms.
```

Fichier `packages/map_editor/test/cinematic_builder_workspace_test.dart` :

```text
678-795   test principal resize droit, mutation durationMs seule, startMs/endMs absents, layout derive, selection/probe/inspecteur/transports.
797-1125  tests presence/absence handle, diminution, min, max, snap, bord gauche, hover, clavier.
4829-4903 Visual Gate V1-69.
5452-5565 fixture neutre _durationResizeCinematic.
```

Les hunks n'ajoutent pas de modele JSON, pas de runtime, pas de playback, pas de lane persistante et pas de start/end persistants.

## Checks anti-scope

Commande :

```bash
git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle examples
```

Sortie :

```text
<vide>
```

Commande :

```bash
rg -n "PlayableMapGame|SceneRuntimeExecutor|SceneEventRuntimeHook|SceneCinematicRuntimeAwaitableAdapter|SceneCinematicRuntimeNoVisualPlayer|playCinematic" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/test/cinematic_builder_workspace_test.dart || true
```

Sortie :

```text
<vide>
```

Commande :

```bash
rg -n "startPlayback|stopPlayback|pausePlayback|resumePlayback|runtimePreview|previewRuntime|playCinematic|PlaybackController|Timer\\(|Ticker|AnimationController|isPlaying|currentTimeMs|playbackTimeMs" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/test/cinematic_builder_workspace_test.dart || true
```

Sortie :

```text
<vide>
```

Commande :

```bash
rg -n "seek|scrub|scrubber|runtimeSeek|seekTo|scrubTo" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/test/cinematic_builder_workspace_test.dart || true
```

Sortie :

```text
packages/map_editor/test/cinematic_builder_workspace_test.dart:1200:    expect(find.text('seek'), findsNothing);
packages/map_editor/test/cinematic_builder_workspace_test.dart:1201:    expect(find.text('scrub'), findsNothing);
```

Interpretation : assertions negatives uniquement.

Commande :

```bash
rg -n "Draggable|LongPressDraggable|DragTarget|drag.*block|drag.*bar|moveBlock|moveStep|reorder|moveUp|moveDown|overlap|persistedStartMs|persistedEndMs" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/test/cinematic_builder_workspace_test.dart || true
```

Sortie :

```text
packages/map_editor/test/cinematic_builder_workspace_test.dart:1518:  testWidgets('snap chooses nearest semantic target when boundaries overlap',
packages/map_editor/test/cinematic_builder_workspace_test.dart:1785:  testWidgets('dragging a timeline block does not move or resize it',
packages/map_editor/test/cinematic_builder_workspace_test.dart:1820:    expect(find.text('reorder'), findsNothing);
```

Interpretation : tests historiques ou assertions negatives, pas de drag de bloc.

Commande :

```bash
rg -n "startMs|endMs|cursorTimeMs|playheadTimeMs|currentTimeMs|playbackTimeMs|isPlaying|persistedStartMs|persistedEndMs" packages/map_core/lib/src/models packages/map_core/lib/src/authoring packages/map_core/lib/src/diagnostics packages/map_editor/lib/src/ui/canvas/cinematics || true
```

Sortie :

```text
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:1685:  return block.startMs + block.visualDurationMs / 2;
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:1822:    final blockLeft = block.startMs * pixelsPerMs;
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:2116:                            'Sélection : ${_shortTimeLabel(selectedBlock.startMs)}',
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:2590:                                    selectedBlock!.startMs,
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:3080:                    left: block.startMs * pixelsPerMs,
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:4817:        timeMs: block.startMs,
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:4825:        timeMs: block.endMs,
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:4938:    'Début : ${_shortTimeLabel(block.startMs)}',
```

Interpretation : affichage/read-model derive uniquement.

Commande :

```bash
rg -n "Color\\(|Colors\\.|0xFF|0xff" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart || true
```

Sortie :

```text
<vide>
```

Commande :

```bash
rg -n "gpt-image-2|image_generation|generate image|AI image|image model" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/test/cinematic_builder_workspace_test.dart || true
```

Sortie :

```text
<vide>
```

Commande :

```bash
rg -n "selbrume|mael|maël|lysa|port_brisants|bourg_selbrume|phare|brume|marais" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/test/cinematic_builder_workspace_test.dart || true
```

Sortie :

```text
<vide>
```

## Diff / status au moment de creation du rapport

Commande `git diff --stat` :

```text
 .../cinematics/cinematic_builder_workspace.dart    | 287 ++++++++-
 .../test/cinematic_builder_workspace_test.dart     | 641 +++++++++++++++++++++
 .../scenes/road_map_scene_builder_authoring.md     |  14 +
 reports/narrativeStudio/scenes/road_map_scenes.md  |   8 +-
 4 files changed, 923 insertions(+), 27 deletions(-)
```

Commande `git diff --name-only` :

```text
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

Commande `git status --short --untracked-files=all` :

```text
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
 M packages/map_editor/test/cinematic_builder_workspace_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_69_cinematic_timeline_duration_resize_handles_v0.png
```

## Auto-review critique

Le lot respecte la frontiere editor/authoring. Le risque principal est la frequence des callbacks pendant drag; elle reste bornee par la quantification 100 ms et par le fait que la mutation reste locale au projet en memoire. Le code cancel existe mais n'a pas ete couvert par un test widget dedie pour eviter un test artificiel fragile.

## Checks finaux apres creation des rapports

Commande :

```bash
git diff --check
```

Sortie :

```text
<vide>
```

Commande :

```bash
git diff --stat
```

Sortie :

```text
 .../cinematics/cinematic_builder_workspace.dart    | 287 ++++++++-
 .../test/cinematic_builder_workspace_test.dart     | 641 +++++++++++++++++++++
 .../scenes/road_map_scene_builder_authoring.md     |  19 +-
 reports/narrativeStudio/scenes/road_map_scenes.md  |   8 +-
 4 files changed, 926 insertions(+), 29 deletions(-)
```

Note : `git diff --stat` ne liste pas les fichiers non suivis. Les nouveaux rapports et la capture apparaissent dans `git status`.

Commande :

```bash
git diff --name-only
```

Sortie :

```text
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
 M packages/map_editor/test/cinematic_builder_workspace_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_69_cinematic_timeline_duration_resize_handles_v0.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_69_evidence_pack.md
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_69_cinematic_timeline_duration_resize_handles_v0.png
```
