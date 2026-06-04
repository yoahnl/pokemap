# NS-SCENES-V1-70 — Evidence Pack

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
875404af feat(narrative): add cinematic timeline duration resize handles v0 (NS-SCENES-V1-69)
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
```

## Fichiers lus

```text
AGENTS.md
agent_rules.md
/Users/karim/.codex/attachments/c36aeb20-3dc4-4942-95b6-7bd4d7f426a1/pasted-text.txt
skills/README.md
skills/test-driven-development/SKILL.md
skills/verification-before-completion/SKILL.md
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/ns_scenes_v1_69_cinematic_timeline_duration_resize_handles_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_69_evidence_pack.md
reports/narrativeStudio/scenes/ns_scenes_v1_68_cinematic_timeline_duration_inspector_editing_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_67_cinematic_timeline_duration_editing_resize_prep_contract.md
packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart
packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart
packages/map_core/lib/src/read_models/cinematic_timeline_time_layout_read_model.dart
packages/map_core/lib/src/read_models/cinematic_timeline_lane_read_model.dart
packages/map_core/test/cinematic_diagnostics_test.dart
packages/map_core/test/cinematic_authoring_operations_test.dart
packages/map_core/test/cinematic_timeline_time_layout_read_model_test.dart
packages/map_core/test/cinematic_timeline_lane_read_model_test.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
packages/map_editor/test/cinematics_library_workspace_test.dart
```

## RED test output

Commande editor :

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'shows duration validation guidance and rejects invalid duration without mutation'
```

Sortie RED :

```text
Expected: exactly one matching candidate
  Actual: _TextWidgetFinder:<Found 0 widgets with text "Bornes : 100–30000 ms · pas 100 ms": []>
   Which: means none were found but one was expected
...
The test description was:
  shows duration validation guidance and rejects invalid duration without mutation
00:03 +0 -1: Some tests failed.
```

Commande core :

```bash
cd packages/map_core && dart test --reporter=compact test/cinematic_diagnostics_test.dart --plain-name 'diagnoses wait duration below minimum'
```

Sortie RED :

```text
Bad state: No element
test/cinematic_diagnostics_test.dart 78:16  main.<fn>.<fn>
00:00 +0 -1: Some tests failed.
```

Note de durcissement apres implementation : l'ajout du test `diagnostics use the same bounds as authoring validation` a d'abord echoue au chargement parce que `validateCinematicTimelineDurationMs` exige `argumentName` et parce que deux constantes metadata actorMove etaient mal nommees. Le test a ete corrige pour utiliser les constantes authoring existantes, puis la suite diagnostics est passee a `+19`.

## GREEN test output

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'shows duration validation guidance and rejects invalid duration without mutation'
```

Sortie :

```text
00:02 +1: All tests passed!
```

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name 'duration validation guidance|actorMove specific minimum|maximum duration guidance|non editable duration reason|inline error|resize minimum clamp feedback|resize maximum clamp feedback'
```

Sortie :

```text
00:04 +10: All tests passed!
```

Commande :

```bash
cd packages/map_core && dart test --reporter=compact test/cinematic_diagnostics_test.dart
```

Sortie finale apres ajout du test contractuel :

```text
00:00 +19: All tests passed!
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
00:13 +93: All tests passed!

cd packages/map_editor && flutter test --reporter=compact test/cinematics_library_workspace_test.dart
00:04 +10: All tests passed!

cd packages/map_editor && flutter test --update-goldens --dart-define=NS_SCENES_V1_70_CAPTURE_CINEMATIC_TIMELINE_DURATION_VALIDATION=true --reporter=compact test/cinematic_builder_workspace_test.dart
00:13 +93: All tests passed!
```

## Analyze cible et global

Analyse cible :

```text
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart test/cinematic_builder_workspace_test.dart
Analyzing 2 items...
No issues found! (ran in 1.8s)
```

Analyse globale :

```text
cd packages/map_editor && flutter analyze
Analyzing map_editor...
error • The named parameter 'dbSymbol' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:58:7
error • The named parameter 'battleEngineAimedTarget' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:64:7
error • The named parameter 'battleEngineMethod' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:72:7
error • The named parameter 'effectChance' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:73:7
error • The named parameter 'studioFlags' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:74:7
error • The named parameter 'battleStageMods' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:75:7
error • The named parameter 'moveStatuses' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:76:7
error • The method 'fetchPokemonSdkStudioProjectPayload' isn't defined for the type 'PokemonExternalSourceRepository' • lib/src/application/use_cases/sync_pokemon_sdk_moves_catalog_use_case.dart:58:10
344 issues found. (ran in 3.1s)
```

## Visual Gate preuve

Chemin :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_70_cinematic_timeline_duration_validation_diagnostics_polish_v0.png
```

Preuve fichier :

```text
ls -l reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_70_cinematic_timeline_duration_validation_diagnostics_polish_v0.png
-rw-r--r--  1 karim  staff  224570 Jun  4 00:26 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_70_cinematic_timeline_duration_validation_diagnostics_polish_v0.png

file reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_70_cinematic_timeline_duration_validation_diagnostics_polish_v0.png
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_70_cinematic_timeline_duration_validation_diagnostics_polish_v0.png: PNG image data, 1663 x 926, 8-bit/color RGBA, non-interlaced

shasum -a 256 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_70_cinematic_timeline_duration_validation_diagnostics_polish_v0.png
5e9841cc0e31be8dcf2b03f6c5303a74c8a4e0aadc863d885b5065955bfc9cfc  reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_70_cinematic_timeline_duration_validation_diagnostics_polish_v0.png
```

## Hunks fonctionnels complets — inventaire

Fichier `packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart` :

```text
313      _diagnoseTimeline appelle maintenant _diagnoseStepDuration pour chaque step.
360-407  _diagnoseStepDuration ajoute la validation durationMs non-actorMove, avec minimum authoring quand applicable et max 30000 ms.
409-416  _diagnosticDurationMinimumMs mappe basic blocks et actorFace vers cinematicTimelineMinimumDurationMs.
459-474  _diagnoseActorMoveStep refuse null, <200 ms et >30000 ms avec message/suggestedFix alignes.
```

Hunk exact :

```diff
-    final durationMs = step.durationMs;
-    if (durationMs != null && durationMs < 0) {
-      diagnostics.add(
-        CinematicDiagnostic(
-          code: CinematicDiagnosticCode.cinematicInvalidStepDuration,
-          severity: CinematicDiagnosticSeverity.error,
-          message: 'Une durée de step cinematic ne peut pas être négative.',
-          cinematicId: cinematic.id,
-          stepId: step.id,
-          target: CinematicDiagnosticTarget.step,
-          suggestedFixLabel: 'Utiliser une durée en millisecondes positive.',
-        ),
-      );
-    }
+    _diagnoseStepDuration(cinematic, step, diagnostics);
```

```diff
+void _diagnoseStepDuration(
+  CinematicAsset cinematic,
+  CinematicTimelineStep step,
+  List<CinematicDiagnostic> diagnostics,
+) {
+  if (step.kind == CinematicTimelineStepKind.actorMove) {
+    return;
+  }
+  final durationMs = step.durationMs;
+  if (durationMs == null) {
+    return;
+  }
+  final minDurationMs = _diagnosticDurationMinimumMs(step);
+  final isBelowMinimum =
+      minDurationMs == null ? durationMs < 0 : durationMs < minDurationMs;
+  final isAboveMaximum = durationMs > cinematicTimelineMaximumDurationMs;
+  if (!isBelowMinimum && !isAboveMaximum) {
+    return;
+  }
+  final message = minDurationMs == null
+      ? 'Une durée cinematic ne peut pas être négative.'
+      : 'Une durée cinematic doit être comprise entre '
+          '$minDurationMs ms et $cinematicTimelineMaximumDurationMs ms.';
+  final suggestedFixLabel = minDurationMs == null
+      ? 'Utiliser une durée en millisecondes positive.'
+      : 'Choisir une durée entre '
+          '$minDurationMs ms et $cinematicTimelineMaximumDurationMs ms.';
+  diagnostics.add(
+    CinematicDiagnostic(
+      code: CinematicDiagnosticCode.cinematicInvalidStepDuration,
+      severity: CinematicDiagnosticSeverity.error,
+      message: message,
+      cinematicId: cinematic.id,
+      stepId: step.id,
+      target: CinematicDiagnosticTarget.step,
+      suggestedFixLabel: suggestedFixLabel,
+    ),
+  );
+}
+
+int? _diagnosticDurationMinimumMs(CinematicTimelineStep step) {
+  if (cinematicTimelineBasicBlockKindOf(step) != null ||
+      isCinematicTimelineActorFacingStep(step)) {
+    return cinematicTimelineMinimumDurationMs;
+  }
+  return null;
+}
```

```diff
-  if (durationMs == null || durationMs <= 0) {
+  if (durationMs == null ||
+      durationMs < cinematicTimelineActorMoveMinimumDurationMs ||
+      durationMs > cinematicTimelineMaximumDurationMs) {
...
-        message: 'Un déplacement acteur doit avoir une durée positive.',
+        message: 'Un déplacement acteur doit durer entre '
+            '$cinematicTimelineActorMoveMinimumDurationMs ms et '
+            '$cinematicTimelineMaximumDurationMs ms.',
...
-        suggestedFixLabel: 'Choisir une durée via les presets.',
+        suggestedFixLabel: 'Choisir une durée entre '
+            '$cinematicTimelineActorMoveMinimumDurationMs ms et '
+            '$cinematicTimelineMaximumDurationMs ms.',
```

Fichier `packages/map_core/test/cinematic_diagnostics_test.dart` :

```text
52-286   tests duration diagnostics : wait min, actorMove min, max, fallback sans duree, marker draft, alignement validation authoring.
742-778  helper _actorMoveDiagnosticCinematic.
```

Fichier `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart` :

```text
3605-3677  raison non-editable injectee dans l'inspecteur.
3690       marker draft affiche le nouveau message brouillon sans effet moteur.
3923-3947  aide bornes/pas et feedback boundary dans _DurationEditorControls.
3956       retrait du digitsOnly pour permettre l'erreur non-entier.
4567       _MutedText accepte une key.
4690-4706  messages de validation inline remplaces.
4713-4743  helpers _durationGuidanceLabel, _durationBoundaryFeedback, _durationNonEditableReason.
```

Fichier `packages/map_editor/test/cinematic_builder_workspace_test.dart` :

```text
1128-1417  tests V1-70 pour guidance, min actorMove, max, non-editables, erreurs inline, feedback min/max resize.
3374-3378  attente diagnostic UI mise a jour avec le message 100..30000 ms.
3419       attente marker draft mise a jour.
5192-5257  Visual Gate V1-70.
6177-6183  fixture diagnostic step_bad enrichie en metadata authoring.
```

Nouveaux petits fichiers : aucun nouveau fichier source Dart. Les nouveaux fichiers texte sont ce rapport principal, cette annexe et la capture PNG listee plus haut.

## Checks anti-scope

Commande :

```bash
git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle examples
```

Sortie :

```text
<vide>
```

Commande anti-runtime :

```bash
rg -n "PlayableMapGame|SceneRuntimeExecutor|SceneEventRuntimeHook|SceneCinematicRuntimeAwaitableAdapter|SceneCinematicRuntimeNoVisualPlayer|playCinematic" packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart packages/map_core/test/cinematic_diagnostics_test.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/test/cinematic_builder_workspace_test.dart || true
```

Sortie :

```text
<vide>
```

Commande anti-playback :

```bash
rg -n "startPlayback|stopPlayback|pausePlayback|resumePlayback|runtimePreview|previewRuntime|playCinematic|PlaybackController|Timer\\(|Ticker|AnimationController|isPlaying|currentTimeMs|playbackTimeMs" packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart packages/map_core/test/cinematic_diagnostics_test.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/test/cinematic_builder_workspace_test.dart || true
```

Sortie :

```text
<vide>
```

Commande anti-seek/scrubber :

```bash
rg -n "seek|scrub|scrubber|runtimeSeek|seekTo|scrubTo" packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart packages/map_core/test/cinematic_diagnostics_test.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/test/cinematic_builder_workspace_test.dart || true
```

Sortie :

```text
packages/map_editor/test/cinematic_builder_workspace_test.dart:1489:    expect(find.text('seek'), findsNothing);
packages/map_editor/test/cinematic_builder_workspace_test.dart:1490:    expect(find.text('scrub'), findsNothing);
```

Commande anti-drag/timeline libre :

```bash
rg -n "Draggable|LongPressDraggable|DragTarget|drag.*block|drag.*bar|moveBlock|moveStep|reorder|moveUp|moveDown|overlap|persistedStartMs|persistedEndMs" packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart packages/map_core/test/cinematic_diagnostics_test.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/test/cinematic_builder_workspace_test.dart || true
```

Sortie :

```text
packages/map_editor/test/cinematic_builder_workspace_test.dart:1807:  testWidgets('snap chooses nearest semantic target when boundaries overlap',
packages/map_editor/test/cinematic_builder_workspace_test.dart:2074:  testWidgets('dragging a timeline block does not move or resize it',
packages/map_editor/test/cinematic_builder_workspace_test.dart:2109:    expect(find.text('reorder'), findsNothing);
```

Commande anti-persistance temporelle :

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
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:4878:        timeMs: block.startMs,
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:4886:        timeMs: block.endMs,
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:4999:    'Début : ${_shortTimeLabel(block.startMs)}',
```

Interpretation : occurrences existantes de projection/affichage derive `startMs/endMs`, aucune nouvelle persistance dans models/authoring.

Commande anti-couleurs hardcodees :

```bash
rg -n "Color\\(|Colors\\.|0xFF|0xff" packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart packages/map_core/test/cinematic_diagnostics_test.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/test/cinematic_builder_workspace_test.dart || true
```

Sortie :

```text
<vide>
```

Commande anti-image IA :

```bash
rg -n "gpt-image-2|image_generation|generate image|AI image|image model" packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart packages/map_core/test/cinematic_diagnostics_test.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/test/cinematic_builder_workspace_test.dart || true
```

Sortie :

```text
<vide>
```

Commande anti-Selbrume :

```bash
rg -n "selbrume|mael|maël|lysa|port_brisants|bourg_selbrume|phare|brume|marais" packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart packages/map_core/test/cinematic_diagnostics_test.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/test/cinematic_builder_workspace_test.dart || true
```

Sortie :

```text
<vide>
```

## Auto-review critique

1. V1-70 a modifie map_runtime ? Non.
2. V1-70 a modifie map_gameplay/map_battle/examples ? Non.
3. V1-70 a modifie le modele JSON ? Non.
4. V1-70 a lance build_runner ? Non.
5. V1-70 a ajoute du playback ? Non.
6. V1-70 a ajoute un timer ? Non.
7. V1-70 a ajoute isPlaying/currentTimeMs/playbackTimeMs ? Non.
8. V1-70 a ajoute un seek runtime ? Non.
9. V1-70 a ajoute un scrubber runtime ? Non.
10. V1-70 a rendu les transport controls fonctionnels ? Non.
11. V1-70 a ajoute du drag de bloc ? Non.
12. V1-70 a ajoute du resize supplementaire ? Non.
13. V1-70 a ajoute du reorder ? Non.
14. V1-70 a ajoute startMs/endMs persistants ? Non.
15. V1-70 a change les bornes V1-68 ? Non.
16. V1-70 a change le pas 100 ms V1-69 ? Non.
17. L'aide min/max est visible ? Oui.
18. Les erreurs de saisie sont claires ? Oui.
19. Le feedback clamp resize est clair ? Oui.
20. Les blocs non editables sont expliques ? Oui.
21. Les diagnostics core duree sont coherents ? Oui.
22. Le resize V1-69 reste fonctionnel ? Oui.
23. L'inspecteur V1-68 reste fonctionnel ? Oui.
24. Hover/probe/aides/transports restent fonctionnels ? Oui.
25. Le design system est respecte ? Oui.
26. La Visual Gate prouve le polish duree ? Oui.
27. L'Evidence Pack est complet sans placeholders ? Oui.
28. Prochain lot exact recommande : `NS-SCENES-V1-71 — Cinematic Stage / Map Context Prep Contract`.

## Commandes finales

Les commandes finales ont ete executees apres creation des rapports :

```text
git diff --check
<vide>
```

```text
git diff --stat
 .../lib/src/diagnostics/cinematic_diagnostics.dart |  75 ++++-
 .../map_core/test/cinematic_diagnostics_test.dart  | 272 +++++++++++++++
 .../cinematics/cinematic_builder_workspace.dart    |  75 ++++-
 .../test/cinematic_builder_workspace_test.dart     | 371 ++++++++++++++++++++-
 .../scenes/road_map_scene_builder_authoring.md     |  19 +-
 reports/narrativeStudio/scenes/road_map_scenes.md  |  23 +-
 6 files changed, 800 insertions(+), 35 deletions(-)
```

```text
git diff --name-only
packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart
packages/map_core/test/cinematic_diagnostics_test.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

```text
git status --short --untracked-files=all
 M packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart
 M packages/map_core/test/cinematic_diagnostics_test.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
 M packages/map_editor/test/cinematic_builder_workspace_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_70_cinematic_timeline_duration_validation_diagnostics_polish_v0.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_70_evidence_pack.md
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_70_cinematic_timeline_duration_validation_diagnostics_polish_v0.png
```
