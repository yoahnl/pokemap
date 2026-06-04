# NS-SCENES-V1-73 — Evidence Pack

Date : 2026-06-04

Lot : `NS-SCENES-V1-73 — Cinematic Stage / Map Context Editor V0`

Statut : DONE

## 1. Gate0

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
```

Derniers commits lus :

```text
632e3747 feat(narrative): add cinematic stage map context core model v0 (NS-SCENES-V1-72)
e77212ff feat(narrative): add cinematic stage map context prep contract (NS-SCENES-V1-71)
edf3d1bd feat(narrative): add cinematic timeline duration validation diagnostics polish v0 (NS-SCENES-V1-70)
875404af feat(narrative): add cinematic timeline duration resize handles v0 (NS-SCENES-V1-69)
263233b4 feat(narrative): add cinematic timeline duration inspector editing v0 (NS-SCENES-V1-68)
c8bb19a2 feat(narrative): add cinematic timeline duration editing resize prep contract (NS-SCENES-V1-67)
e67e71c7 feat(narrative): add cinematic timeline mouse probe help selection explanation v0 (NS-SCENES-V1-66)
46cc0eb4 feat(narrative): add cinematic timeline mouse probe UX polish clear controls v0 (NS-SCENES-V1-65)
95e79063 feat(narrative): add cinematic timeline mouse probe boundary snap v0 (NS-SCENES-V1-64)
86004392 feat(narrative): add cinematic timeline mouse probe polish boundary snap v0 (NS-SCENES-V1-63)
79414165 feat(narrative): add cinematic timeline mouse time probe playhead drag v0 (NS-SCENES-V1-62)
044155fc feat(narrative): add cinematic timeline mouse playhead scrub prep contract (NS-SCENES-V1-61)
32f92c54 feat(narrative): add cinematic timeline keyboard navigation polish help overlay v0 (NS-SCENES-V1-60)
ede69519 feat(narrative): add cinematic timeline lane vertical navigation v0 (NS-SCENES-V1-59)
e1e83cd9 feat(narrative): add cinematic timeline lane vertical navigation prep contract (NS-SCENES-V1-58)
```

## 2. Instructions et specs lues

- `AGENTS.md`
- `agent_rules.md`
- `skills/README.md`
- `skills/writing-plans/SKILL.md`
- `skills/test-driven-development/SKILL.md`
- `skills/verification-before-completion/SKILL.md`
- `skills/brainstorming/SKILL.md`
- prompt V1-73 : `/Users/karim/.codex/attachments/74258f57-c0aa-4369-a377-072aa270eb1e/pasted-text.txt`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
- rapports V1-68, V1-69, V1-70, V1-71, V1-72

## 3. Inventaire technique lu

- `packages/map_core/lib/src/models/cinematic_asset.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/map_data.dart`
- `packages/map_core/lib/src/models/map_event_definition.dart`
- `packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart`
- `packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart`
- `packages/map_core/lib/src/read_models/cinematics_library_read_model.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- `packages/map_editor/test/cinematic_builder_workspace_test.dart`
- `packages/map_editor/test/cinematics_library_workspace_test.dart`

## 4. Recherches structurantes

```text
rg -n "updateCinematicStageMap|updateCinematicStageContext|upsertCinematicActorBinding|upsertCinematicActorInitialPlacement|upsertCinematicMovementTargetBinding" packages
```

Resultat : operations V1-72 trouvees dans `map_core`, non encore exposees dans l'UI avant V1-73.

```text
rg -n "ProjectManifest.*maps|maps:" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart packages/map_editor/test/cinematic_builder_workspace_test.dart packages/map_editor/test/cinematics_library_workspace_test.dart
```

Resultat final :

```text
packages/map_editor/test/cinematics_library_workspace_test.dart:752:    maps: const <ProjectMapEntry>[
packages/map_editor/test/cinematic_builder_workspace_test.dart:7216:    maps: const <ProjectMapEntry>[
packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart:570:            _MetadataSummary(entry: entry, maps: widget.project.maps),
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart:725:          maps: maps,
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart:761:          maps: maps,
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart:865:    maps: maps,
```

```text
rg -n "Les entités de cette map seront sélectionnables|Les events de cette map seront sélectionnables|Choisis d’abord une map de scène" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/test/cinematic_builder_workspace_test.dart
```

Resultat final :

```text
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:3956:        ? 'Choisis d’abord une map de scène.'
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:3957:        : 'Les entités de cette map seront sélectionnables dans un lot suivant.';
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:4243:        ? 'Choisis d’abord une map de scène.'
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:4244:        : 'Les entités de cette map seront sélectionnables dans un lot suivant.';
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:4246:        ? 'Choisis d’abord une map de scène.'
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:4247:        : 'Les events de cette map seront sélectionnables dans un lot suivant.';
packages/map_editor/test/cinematic_builder_workspace_test.dart:349:    expect(find.text('Choisis d’abord une map de scène.'), findsWidgets);
packages/map_editor/test/cinematic_builder_workspace_test.dart:368:          'Les entités de cette map seront sélectionnables dans un lot suivant.'),
packages/map_editor/test/cinematic_builder_workspace_test.dart:379:          'Les events de cette map seront sélectionnables dans un lot suivant.'),
```

## 5. RED

Premier RED produit compile apres ajout de fixtures :

```text
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'edits cinematic stage map and backdrop from builder'
Exit 1
Expected: exactly one matching candidate
Actual: Found 0 widgets with text "Contexte de scène"
```

Un RED anterieur a egalement capture l'absence de fixtures `_stageContextCinematic` ; il a servi a completer la base de test avant le RED produit ci-dessus.

## 6. GREEN

```text
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'edits cinematic stage map and backdrop from builder'
+1: All tests passed!
```

```text
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name 'stage|actor binding|initial placement|movement target binding|raw JSON|free ID|duration editor still works|resize handle still works|transport controls|preview playback|durationMs|timeline steps'
+21: All tests passed!
```

## 7. Visual Gate

Commande :

```bash
cd packages/map_editor && flutter test --update-goldens --dart-define=NS_SCENES_V1_73_CAPTURE_CINEMATIC_STAGE_CONTEXT_EDITOR=true --reporter=compact test/cinematic_builder_workspace_test.dart
```

Resultat final :

```text
+119: All tests passed!
```

Fichier :

```text
ls -lh reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_73_cinematic_stage_map_context_editor_v0.png
-rw-r--r--  1 karim  staff   212K Jun  4 16:23 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_73_cinematic_stage_map_context_editor_v0.png

file reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_73_cinematic_stage_map_context_editor_v0.png
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_73_cinematic_stage_map_context_editor_v0.png: PNG image data, 1663 x 926, 8-bit/color RGBA, non-interlaced

shasum -a 256 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_73_cinematic_stage_map_context_editor_v0.png
79621972c1c50ef26ac1f5603b1587a6a2752087bd802d43173488154a3454ed  reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_73_cinematic_stage_map_context_editor_v0.png
```

## 8. Validations map_core

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

cd packages/map_core && dart analyze
Analyzing map_core...
No issues found!
```

## 9. Validations map_editor

```text
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
+119: All tests passed!

cd packages/map_editor && flutter test --reporter=compact test/cinematics_library_workspace_test.dart
+11: All tests passed!

cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart lib/src/ui/canvas/narrative_workspace_canvas.dart test/cinematic_builder_workspace_test.dart test/cinematics_library_workspace_test.dart
Analyzing 5 items...
No issues found! (ran in 2.2s)
```

Note : un lancement parallele de `flutter test test/cinematics_library_workspace_test.dart` a echoue une premiere fois sur un lock Flutter/code signing :

```text
Failed to code sign binary: exit code: 1  /Users/karim/Project/pokemonProject/packages/map_editor/build/native_assets/macos/objective_c.dylib: No such file or directory
```

Le meme test relance seul est vert `+11`.

Analyse globale :

```text
cd packages/map_editor && flutter analyze
Exit 1
344 issues found. (ran in 3.3s)
```

Premieres erreurs globales, hors fichiers modifies :

```text
lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:58:7 undefined_named_parameter dbSymbol
lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:64:7 undefined_named_parameter battleEngineAimedTarget
lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:72:7 undefined_named_parameter battleEngineMethod
lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:73:7 undefined_named_parameter effectChance
lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:74:7 undefined_named_parameter studioFlags
lib/src/application/use_cases/sync_pokemon_sdk_moves_catalog_use_case.dart:58:10 undefined_method fetchPokemonSdkStudioProjectPayload
```

## 10. Anti-scope

```text
git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle examples
<vide>
```

```text
rg -n "PlayableMapGame|SceneRuntimeExecutor|SceneEventRuntimeHook|SceneCinematicRuntimeAwaitableAdapter|playCinematic|startPlayback|stopPlayback|runtimePreview|previewRuntime|PlaybackController|Timer\\(|Ticker|AnimationController|isPlaying|currentTimeMs|playbackTimeMs" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart packages/map_editor/test/cinematic_builder_workspace_test.dart packages/map_editor/test/cinematics_library_workspace_test.dart || true
<vide>
```

```text
rg -n "pathfinding|Pathfinder|collision|warp|spawnRuntime|GameState|PlayableMapGame|MapRuntime|runtimeSpawn" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart packages/map_editor/test/cinematic_builder_workspace_test.dart packages/map_editor/test/cinematics_library_workspace_test.dart || true
<vide>
```

```text
rg -n "stageContext.*mapId|CinematicStageContext\\([^\\)]*mapId|mapId.*stageContext" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart || true
<vide>
```

Recherche ID/JSON large :

```text
rg -n "TextField\\([^\\)]*(mapEntityId|eventId|sourceId|targetId)|json|JSON|raw id|rawId|free.*id" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart || true
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:5625:  final freeX = _tickLeft(freeTimeMs, pixelsPerMs, contentWidth);
```

Interpretation : faux positif. `freeX` appartient au calcul de l'axe temporel, pas a un ID libre. La recherche resserree est vide :

```text
rg -n "TextField\\([^\\)]*(mapEntityId|eventId|sourceId|targetId)|json|JSON|raw id|rawId|free id|freeId|free-id" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart || true
<vide>
```

```text
rg -n "tileX|tileY|coord|coordinate|x/y|positionX|positionY" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart packages/map_editor/test/cinematic_builder_workspace_test.dart packages/map_editor/test/cinematics_library_workspace_test.dart || true
<vide>
```

```text
rg -n "gpt-image-2|image_generation|generate image|AI image|image model" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart packages/map_editor/test/cinematic_builder_workspace_test.dart packages/map_editor/test/cinematics_library_workspace_test.dart || true
<vide>
```

```text
rg -n "selbrume|mael|maël|lysa|port_brisants|bourg_selbrume|phare|brume|marais" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart packages/map_editor/test/cinematic_builder_workspace_test.dart packages/map_editor/test/cinematics_library_workspace_test.dart || true
<vide>
```

```text
rg -n "Color\\(0x|Colors\\." packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart || true
<vide>
```

## 11. Diff inventory final

```text
git diff --stat
 .../cinematics/cinematic_builder_workspace.dart    |  936 +++++++++++++++++-
 .../cinematics/cinematics_library_workspace.dart   |  102 +-
 .../src/ui/canvas/narrative_workspace_canvas.dart  |  126 +++
 .../test/cinematic_builder_workspace_test.dart     | 1004 +++++++++++++++++++-
 .../test/cinematics_library_workspace_test.dart    |   99 ++
 .../scenes/road_map_scene_builder_authoring.md     |   18 +-
 reports/narrativeStudio/scenes/road_map_scenes.md  |   22 +-
 7 files changed, 2285 insertions(+), 22 deletions(-)
```

```text
git diff --name-only
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
packages/map_editor/test/cinematics_library_workspace_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

## 12. Code genere inventorie

Le rapport principal contient les extraits de code produits suivants :

- callbacks Stage Context du Builder ;
- `_StageContextEditor` ;
- `_StageMapSection` ;
- messages map-aware desactives ;
- persistance `updateCinematicStageMap` et upserts dans `NarrativeWorkspaceCanvas` ;
- `_MetadataSummary` Library avec map lisible et diagnostics stage ;
- tests RED/GREEN et Visual Gate.

Le code complet est dans les fichiers sources modifies listés ci-dessus.

## 13. Roadmaps

Modifie :

- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

Statut pose :

```text
NS-SCENES-V1-73 — Cinematic Stage / Map Context Editor V0 : DONE
```

Prochain lot recommande :

```text
NS-SCENES-V1-74 — Cinematic Stage Context Diagnostics / Preview Readiness Polish V0
```

## 14. Final git status avant remise

Statut attendu apres creation de ce rapport :

```text
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
 M packages/map_editor/test/cinematic_builder_workspace_test.dart
 M packages/map_editor/test/cinematics_library_workspace_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_73_cinematic_stage_map_context_editor_v0.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_73_evidence_pack.md
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_73_cinematic_stage_map_context_editor_v0.png
```
