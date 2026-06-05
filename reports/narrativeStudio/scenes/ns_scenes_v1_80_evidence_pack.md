# NS-SCENES-V1-80 — Evidence Pack

## 1. Lot

`NS-SCENES-V1-80 — Cinematic Character Library Picker V0`

Demandeur : Karim.

## 2. Gate 0

```bash
pwd
```

```text
/Users/karim/Project/pokemonProject
```

```bash
git branch --show-current && git status --short --untracked-files=all
```

```text
main
```

```bash
git diff --stat && git diff --name-only && git log --oneline -n 15
```

```text
eb7d47aa feat(narrative): add cinematic character library binding core model v0 (NS-SCENES-V1-79)
92a6c95e feat(narrative): add cinematic character library binding prep contract (NS-SCENES-V1-78)
d5113ec2 feat(narrative): add cinematic stage map entity event pickers v0 (NS-SCENES-V1-77)
01a69fdd feat(narrative): add cinematic stage map source catalog v0 (NS-SCENES-V1-76)
bea04114 feat(narrative): add cinematic map entity event source audit picker prep contract (NS-SCENES-V1-75)
fe619092 feat(narrative): add cinematic stage map context editor and diagnostics preview readiness polish v0 (NS-SCENES-V1-73-V1-74)
632e3747 feat(narrative): add cinematic stage map context core model v0 (NS-SCENES-V1-72)
e77212ff feat(narrative): add cinematic stage map context prep contract (NS-SCENES-V1-71)
edf3d1bd feat(narrative): add cinematic timeline duration validation diagnostics polish v0 (NS-SCENES-V1-70)
875404af feat(narrative): add cinematic timeline duration resize handles v0 (NS-SCENES-V1-69)
263233b4 feat(narrative): add cinematic timeline duration inspector editing v0 (NS-SCENES-V1-68)
c8bb19a2 feat(narrative): add cinematic timeline duration editing resize prep contract (NS-SCENES-V1-67)
e67e71c7 feat(narrative): add cinematic timeline mouse probe help selection explanation v0 (NS-SCENES-V1-66)
46cc0eb4 feat(narrative): add cinematic timeline mouse probe UX polish clear controls v0 (NS-SCENES-V1-65)
95e79063 feat(narrative): add cinematic timeline mouse probe boundary snap v0 (NS-SCENES-V1-64)
```

`git status`, `git diff --stat` et `git diff --name-only` etaient vides avant edition ; seule la sortie `git log` etait imprimee par la commande groupee.

## 3. Fichiers lus/audités

- `AGENTS.md`
- `agent_rules.md`
- prompt V1-80 fourni par Karim
- `skills/README.md`
- `skills/test-driven-development/SKILL.md`
- `skills/verification-before-completion/SKILL.md`
- `skills/systematic-debugging/SKILL.md`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/cinematic_asset.dart`
- `packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart`
- `packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_stage_preview_readiness.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- `packages/map_editor/test/cinematic_builder_workspace_test.dart`
- `packages/map_editor/test/cinematics_library_workspace_test.dart`

## 4. TDD RED

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'selects character library entry for cinematic only actor'
```

Sortie RED observee :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/cinematic_builder_workspace_test.dart
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/cinematic_builder_workspace_test.dart
00:02 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/cinematic_builder_workspace_test.dart
00:02 +0: selects character library entry for cinematic only actor
00:03 +0: selects character library entry for cinematic only actor
00:03 +0: selects character library entry for cinematic only actor
══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════════════════════════════
The following TestFailure was thrown running a test:
Expected: at least one matching candidate
  Actual: _TextWidgetFinder:<Found 0 widgets with text "Apparence": []>
   Which: means none were found but some were expected

When the exception was thrown, this was the stack:
#4      main.<anonymous closure> (file:///Users/karim/Project/pokemonProject/packages/map_editor/test/cinematic_builder_workspace_test.dart:501:5)
<asynchronous suspension>
#5      testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:192:15)
<asynchronous suspension>
#6      TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1952:5)
<asynchronous suspension>
<asynchronous suspension>
(elided one frame from package:stack_trace)

This was caught by the test expectation on the following line:
  file:///Users/karim/Project/pokemonProject/packages/map_editor/test/cinematic_builder_workspace_test.dart line 501
The test description was:
  selects character library entry for cinematic only actor
════════════════════════════════════════════════════════════════════════════════════════════════════
00:03 +0 -1: selects character library entry for cinematic only actor [E]
  Test failed. See exception logs above.
  The test description was: selects character library entry for cinematic only actor

To run this test again: /opt/homebrew/share/flutter/bin/cache/dart-sdk/bin/dart test /Users/karim/Project/pokemonProject/packages/map_editor/test/cinematic_builder_workspace_test.dart -p vm --plain-name 'selects character library entry for cinematic only actor'
00:03 +0 -1: Some tests failed.
```

## 5. TDD GREEN ciblé

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'selects character library entry for cinematic only actor'
```

Sortie :

```text
Waiting for another flutter command to release the startup lock...
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/cinematic_builder_workspace_test.dart
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/cinematic_builder_workspace_test.dart
00:02 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/cinematic_builder_workspace_test.dart
00:02 +0: selects character library entry for cinematic only actor
00:02 +1: selects character library entry for cinematic only actor
00:02 +1: All tests passed!
```

## 6. Visual Gate

Commande demandee :

```bash
cd packages/map_editor && flutter test --update-goldens --dart-define=NS_SCENES_V1_80_CAPTURE_CINEMATIC_CHARACTER_PICKER=true --reporter=compact test/cinematic_builder_workspace_test.dart
```

Sortie terminal pertinente :

```text
00:24 +134: captures V1-80 cinematic character library picker when requested
00:24 +135: captures V1-80 cinematic character library picker when requested
00:24 +135: All tests passed!
```

Fichier produit :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_80_cinematic_character_library_picker_v0.png
```

## 7. Suite Builder

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
```

Sortie finale :

```text
00:23 +134: All tests passed!
```

## 8. Suite Library

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematics_library_workspace_test.dart
```

Sortie :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/cinematics_library_workspace_test.dart
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/cinematics_library_workspace_test.dart
00:01 +0: shows empty state and creates a cinematic shell
00:02 +0: shows empty state and creates a cinematic shell
00:02 +1: shows empty state and creates a cinematic shell
00:02 +1: lists canonical and bridge entries with read-only details
00:02 +2: lists canonical and bridge entries with read-only details
00:02 +2: shows timeline summary and scene usages for canonical entry
00:02 +3: shows timeline summary and scene usages for canonical entry
00:02 +3: shows stage diagnostics count for canonical entry
00:03 +3: shows stage diagnostics count for canonical entry
00:03 +4: shows stage diagnostics count for canonical entry
00:03 +4: shows preview readiness summary for incomplete stage context
00:03 +5: shows preview readiness summary for incomplete stage context
00:03 +5: opens builder shell for canonical cinematic and returns
00:03 +6: opens builder shell for canonical cinematic and returns
00:03 +6: loads stage map source catalog when opening builder
00:03 +7: loads stage map source catalog when opening builder
00:03 +7: adds a draft from builder and refreshes library summary
00:04 +7: adds a draft from builder and refreshes library summary
00:04 +8: adds a draft from builder and refreshes library summary
00:04 +8: adds a basic block from builder and refreshes library summary
00:04 +9: adds a basic block from builder and refreshes library summary
00:04 +9: adds an actor facing block from builder and refreshes summary
00:04 +10: adds an actor facing block from builder and refreshes summary
00:04 +10: keeps legacy bridge out of canonical builder shell
00:04 +11: keeps legacy bridge out of canonical builder shell
00:04 +11: edits metadata and deletes only unused canonicals
00:04 +12: edits metadata and deletes only unused canonicals
00:04 +12: captures V1-38 Cinematics Library screenshot when requested
00:04 +13: captures V1-38 Cinematics Library screenshot when requested
00:04 +13: All tests passed!
```

## 9. Analyse cible

Commande :

```bash
cd packages/map_editor && flutter analyze lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart lib/src/ui/canvas/cinematics/cinematic_stage_preview_readiness.dart lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart lib/src/ui/canvas/narrative_workspace_canvas.dart test/cinematic_builder_workspace_test.dart test/cinematics_library_workspace_test.dart
```

Sortie :

```text
Analyzing 6 items...
No issues found! (ran in 2.1s)
```

## 9-bis. Vérification finale combinée

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart test/cinematics_library_workspace_test.dart
```

Sortie finale :

```text
00:23 +148: All tests passed!
```

## 10. Analyse globale map_editor

Commande :

```bash
cd packages/map_editor && flutter analyze
```

Resultat : exit code 1, dette preexistante hors lot.

Premieres erreurs :

```text
Analyzing map_editor...

  error • The named parameter 'dbSymbol' isn't defined. Try correcting the name to an existing named parameter's name, or defining a named parameter with the name 'dbSymbol' • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:58:7 • undefined_named_parameter
  error • The named parameter 'battleEngineAimedTarget' isn't defined. Try correcting the name to an existing named parameter's name, or defining a named parameter with the name 'battleEngineAimedTarget' • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:64:7 • undefined_named_parameter
  error • The named parameter 'battleEngineMethod' isn't defined. Try correcting the name to an existing named parameter's name, or defining a named parameter with the name 'battleEngineMethod' • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:72:7 • undefined_named_parameter
  error • The named parameter 'effectChance' isn't defined. Try correcting the name to an existing named parameter's name, or defining a named parameter with the name 'effectChance' • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:73:7 • undefined_named_parameter
  error • The named parameter 'studioFlags' isn't defined. Try correcting the name to an existing named parameter's name, or defining a named parameter with the name 'studioFlags' • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:74:7 • undefined_named_parameter
  error • The method 'fetchPokemonSdkStudioProjectPayload' isn't defined for the type 'PokemonExternalSourceRepository'. Try correcting the name to the name of an existing method, or defining a method named 'fetchPokemonSdkStudioProjectPayload' • lib/src/application/use_cases/sync_pokemon_sdk_moves_catalog_use_case.dart:58:10 • undefined_method
```

Synthese terminal :

```text
344 issues found. (ran in 3.9s)
```

Ces erreurs ne sont pas dans les fichiers V1-80.

## 11. Code généré — résumé

Callbacks publics :

```dart
typedef UpsertCinematicActorAppearanceBindingCallback = Future<bool> Function({
  required String cinematicId,
  required CinematicActorAppearanceBinding binding,
});

typedef RemoveCinematicActorAppearanceBindingCallback = Future<bool> Function({
  required String cinematicId,
  required String actorId,
});
```

Operation editor :

```dart
final result = upsertCinematicActorAppearanceBinding(
  project,
  cinematicId: cinematicId,
  binding: binding,
);
widget.editorNotifier.applyInMemoryProjectManifest(
  result.updatedProject,
  statusMessage: 'Cinematic actor appearance updated',
);
```

Picker :

```dart
_StageCharacterPicker(
  actorId: actor.actorId,
  characters: sortedCharacters,
  selectedCharacterId: appearanceBinding?.characterId,
  onCharacterSelected: onCharacterSelected,
)
```

Readiness :

```dart
_actorAppearancesItem(asset, effectiveContext, characters)
```

## 12. Checks anti-scope

Commande :

```bash
rg -n "CharacterLibraryPanel|createCharacter|updateCharacter|deleteCharacter|setPlayerCharacter|currentTimeMs|playbackTimeMs|isPlaying|Ticker|AnimationController|pathfinding|collision|warp|spawn|GameState|Selbrume|Ma[eë]l|Lysa|Port des Brisants|gpt-image-2" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_stage_preview_readiness.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart packages/map_editor/test/cinematic_builder_workspace_test.dart packages/map_editor/test/cinematics_library_workspace_test.dart
```

Sortie : aucune occurrence.

Commande :

```bash
rg -n "character.*TextField|TextField.*character|characterId.*TextField|TextField.*characterId|Character Library.*TextField|Personnage.*TextField" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart packages/map_editor/test/cinematic_builder_workspace_test.dart packages/map_editor/test/cinematics_library_workspace_test.dart
```

Sortie : aucune occurrence.

Commande :

```bash
rg -n "Color\\(0x|Colors\\." packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_stage_preview_readiness.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
```

Sortie : aucune occurrence.

## 13. Diff inventory

```text
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_stage_preview_readiness.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
packages/map_editor/test/cinematics_library_workspace_test.dart
reports/narrativeStudio/scenes/ns_scenes_v1_80_cinematic_character_library_picker_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_80_evidence_pack.md
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_80_cinematic_character_library_picker_v0.png
```

## 14. Statut

`NS-SCENES-V1-80 — Cinematic Character Library Picker V0` : DONE.

Prochain lot recommande :

```text
NS-SCENES-V1-81 — Cinematic Actor Appearance Readiness / Drift Diagnostics Polish V0
```
