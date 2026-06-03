# NS-SCENES-V1-64 — Evidence Pack

Date : 2026-06-03

## 1. Gate 0 complet

Commande :

```bash
pwd && git branch --show-current && git status --short --untracked-files=all && git diff --stat && git diff --name-only && git log --oneline -n 15
```

Sortie :

```text
/Users/karim/Project/pokemonProject
main
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
df27cccb feat(narrative): add cinematic timeline selection cursor playhead placeholder v0 (NS-SCENES-V1-52)
8ce1a417 feat(narrative): add cinematic actor movement inspector polish and timeline time axis bar layout v0 (NS-SCENES-V1-50-V1-51)
7d6c94cf feat(narrative): add cinematic actor movement block v0 (NS-SCENES-V1-49)
77d12c69 feat(narrative): add cinematic timeline lane grouping v0 (NS-SCENES-V1-48)
aaa9028f feat(narrative): add cinematic actor references actor facing v0 (NS-SCENES-V1-46)
```

Interpretation : les trois commandes intermediaires `git status --short --untracked-files=all`, `git diff --stat` et `git diff --name-only` n'ont rien imprime, donc le working tree etait propre avant V1-64.

## 2. Fichiers lus

```text
AGENTS.md
agent_rules.md
skills/README.md
skills/using-superpowers/SKILL.md
skills/brainstorming/SKILL.md
skills/writing-plans/SKILL.md
skills/test-driven-development/SKILL.md
skills/verification-before-completion/SKILL.md
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/ns_scenes_v1_63_cinematic_timeline_mouse_probe_polish_boundary_snap_prep_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_62_cinematic_timeline_mouse_time_probe_playhead_drag_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_62_evidence_pack.md
reports/narrativeStudio/scenes/ns_scenes_v1_61_cinematic_timeline_mouse_playhead_scrub_prep_contract.md
reports/narrativeStudio/scenes/ns_scenes_v1_60_cinematic_timeline_keyboard_navigation_polish_help_overlay_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_59_cinematic_timeline_lane_vertical_navigation_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_56_cinematic_timeline_bar_geometry_duration_scale_correction_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_52_cinematic_timeline_selection_cursor_playhead_placeholder_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_51_cinematic_timeline_time_axis_bar_layout_v0.md
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/lib/src/ui/design_system/pokemap_card.dart
packages/map_editor/lib/src/ui/design_system/pokemap_badge.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
packages/map_editor/test/cinematics_library_workspace_test.dart
packages/map_core/lib/src/read_models/cinematic_timeline_time_layout_read_model.dart
packages/map_core/lib/src/read_models/cinematic_timeline_lane_read_model.dart
packages/map_core/test/cinematic_timeline_time_layout_read_model_test.dart
packages/map_core/test/cinematic_timeline_lane_read_model_test.dart
```

## 3. RED test output

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'snaps local timeline time probe to block boundaries without changing selection'
```

Sortie RED :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/cinematic_builder_workspace_test.dart
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/cinematic_builder_workspace_test.dart
00:01 +0: snaps local timeline time probe to block boundaries without changing selection
00:02 +0: snaps local timeline time probe to block boundaries without changing selection
00:03 +0: snaps local timeline time probe to block boundaries without changing selection
00:03 +0: snaps local timeline time probe to block boundaries without changing selection

══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════════════════════════════
The following TestFailure was thrown running a test:
Expected: exactly one matching candidate
  Actual: _TextWidgetFinder:<Found 0 widgets with text "Repère : 500 ms · début bloc": []>
   Which: means none were found but one was expected

When the exception was thrown, this was the stack:
#4      main.<anonymous closure> (file:///Users/karim/Project/pokemonProject/packages/map_editor/test/cinematic_builder_workspace_test.dart:397:5)
<asynchronous suspension>
#5      testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:192:15)
<asynchronous suspension>
#6      TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1952:5)
<asynchronous suspension>
<asynchronous suspension>
(elided one frame from package:stack_trace)

This was caught by the test expectation on the following line:
  file:///Users/karim/Project/pokemonProject/packages/map_editor/test/cinematic_builder_workspace_test.dart line 397
The test description was:
  snaps local timeline time probe to block boundaries without changing selection
════════════════════════════════════════════════════════════════════════════════════════════════════
00:03 +0 -1: snaps local timeline time probe to block boundaries without changing selection [E]
  Test failed. See exception logs above.
  The test description was: snaps local timeline time probe to block boundaries without changing selection

To run this test again: /opt/homebrew/share/flutter/bin/cache/dart-sdk/bin/dart test /Users/karim/Project/pokemonProject/packages/map_editor/test/cinematic_builder_workspace_test.dart -p vm --plain-name 'snaps local timeline time probe to block boundaries without changing selection'
00:03 +0 -1: Some tests failed.
```

## 4. GREEN outputs

Commande GREEN cible :

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'snaps local timeline time probe to block boundaries without changing selection'
```

Sortie :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/cinematic_builder_workspace_test.dart
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/cinematic_builder_workspace_test.dart
00:01 +0: snaps local timeline time probe to block boundaries without changing selection
00:02 +0: snaps local timeline time probe to block boundaries without changing selection
00:02 +1: snaps local timeline time probe to block boundaries without changing selection
00:02 +1: All tests passed!
```

Suite Builder finale :

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
```

Sortie finale :

```text
00:09 +59: captures V1-64 cinematic timeline mouse probe snap when requested
00:09 +59: All tests passed!
```

Suite Library :

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematics_library_workspace_test.dart
```

Sortie finale :

```text
00:03 +10: captures V1-38 Cinematics Library screenshot when requested
00:03 +10: All tests passed!
```

Core non-regression :

```bash
cd packages/map_core && dart test test/cinematic_timeline_time_layout_read_model_test.dart && dart test test/cinematic_timeline_lane_read_model_test.dart && dart analyze
```

Sortie :

```text
00:00 +4: All tests passed!
00:00 +2: All tests passed!
Analyzing map_core...
No issues found!
```

## 5. Analyze cible editor

Commande :

```bash
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart test/cinematic_builder_workspace_test.dart
```

Sortie :

```text
Analyzing 2 items...
No issues found! (ran in 1.1s)
```

## 6. Visual Gate

Commande :

```bash
cd packages/map_editor && flutter test --update-goldens --dart-define=NS_SCENES_V1_64_CAPTURE_CINEMATIC_TIMELINE_MOUSE_PROBE_SNAP=true --reporter=compact test/cinematic_builder_workspace_test.dart
```

Sortie finale :

```text
00:09 +58: captures V1-62 cinematic timeline mouse time probe when requested
00:09 +59: captures V1-64 cinematic timeline mouse probe snap when requested
00:09 +59: All tests passed!
```

Capture :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_64_cinematic_timeline_mouse_probe_boundary_snap_v0.png
```

Preuve fichier :

```bash
ls -l reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_64_cinematic_timeline_mouse_probe_boundary_snap_v0.png && file reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_64_cinematic_timeline_mouse_probe_boundary_snap_v0.png && shasum -a 256 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_64_cinematic_timeline_mouse_probe_boundary_snap_v0.png
```

Sortie :

```text
-rw-r--r--  1 karim  staff  232656 Jun  3 14:49 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_64_cinematic_timeline_mouse_probe_boundary_snap_v0.png
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_64_cinematic_timeline_mouse_probe_boundary_snap_v0.png: PNG image data, 1663 x 926, 8-bit/color RGBA, non-interlaced
f75ed00ff9a5ccce12c88fc66d9d1f7da12df80dc0aa007d3c6cff23414acb77  reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_64_cinematic_timeline_mouse_probe_boundary_snap_v0.png
```

## 7. Diff inventory

Commande :

```bash
git diff --numstat
```

Sortie :

```text
230	14	packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
375	3	packages/map_editor/test/cinematic_builder_workspace_test.dart
17	2	reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
19	4	reports/narrativeStudio/scenes/road_map_scenes.md
```

Points de code principaux :

```text
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:185:  _TimelineProbeSnapHint? _timelineProbeSnapHint;
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:1450:enum _TimelineProbeSnapHint {
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:1457:class _TimelineProbeSnapResult {
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:1467:class _TimelineProbeSnapTarget {
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:3977:_TimelineProbeSnapResult _resolveTimelineProbeSnap(
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:4026:List<_TimelineProbeSnapTarget> _timelineProbeSnapTargets(
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:4120:String _timelineProbeBadgeLabel(
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:4131:String _timelineProbeSnapHintLabel(_TimelineProbeSnapHint hint) {
packages/map_editor/test/cinematic_builder_workspace_test.dart:361:      'snaps local timeline time probe to block boundaries without changing selection',
packages/map_editor/test/cinematic_builder_workspace_test.dart:418:  testWidgets('snaps local timeline time probe to timeline start and end',
packages/map_editor/test/cinematic_builder_workspace_test.dart:479:  testWidgets('snaps local timeline time probe to shared block boundary',
packages/map_editor/test/cinematic_builder_workspace_test.dart:522:  testWidgets('snap chooses nearest semantic target when boundaries overlap',
```

## 8. Checks anti-scope

Commande :

```bash
git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle examples
```

Sortie :

```text
```

Commande :

```bash
rg -n "PlayableMapGame|SceneRuntimeExecutor|SceneEventRuntimeHook|SceneCinematicRuntimeAwaitableAdapter|SceneCinematicRuntimeNoVisualPlayer|playCinematic" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/test/cinematic_builder_workspace_test.dart || true
```

Sortie :

```text
```

Commande :

```bash
rg -n "startPlayback|stopPlayback|pausePlayback|resumePlayback|runtimePreview|previewRuntime|playCinematic|PlaybackController|Timer\\(|Ticker|AnimationController|isPlaying|currentTimeMs|playbackTimeMs" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/test/cinematic_builder_workspace_test.dart || true
```

Sortie :

```text
```

Commande :

```bash
rg -n "seek|scrub|scrubber|runtimeSeek|seekTo|scrubTo" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/test/cinematic_builder_workspace_test.dart || true
```

Sortie :

```text
```

Commande :

```bash
rg -n "Draggable|LongPressDraggable|DragTarget|drag.*block|onHorizontalDrag.*block|resize|reorder|moveUp|moveDown|keyframe|overlap" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/test/cinematic_builder_workspace_test.dart || true
```

Sortie :

```text
packages/map_editor/test/cinematic_builder_workspace_test.dart:147:    expect(find.text('resize'), findsNothing);
packages/map_editor/test/cinematic_builder_workspace_test.dart:522:  testWidgets('snap chooses nearest semantic target when boundaries overlap',
packages/map_editor/test/cinematic_builder_workspace_test.dart:789:  testWidgets('dragging a timeline block does not move or resize it',
packages/map_editor/test/cinematic_builder_workspace_test.dart:823:    expect(find.text('resize'), findsNothing);
packages/map_editor/test/cinematic_builder_workspace_test.dart:824:    expect(find.text('reorder'), findsNothing);
```

Interpretation : les hits sont des assertions/tests negatifs ou le mot `overlap` dans un nom de test de snap. Aucun drag, resize ou reorder de bloc n'est implemente.

Commande :

```bash
rg -n "timelineProbeTimeMs|mouseProbeTimeMs|cursorTimeMs|playheadTimeMs|currentTimeMs|playbackTimeMs|isPlaying|persistedStartMs|persistedEndMs|snapThreshold|snapTarget" packages/map_core/lib/src/models packages/map_core/lib/src/authoring packages/map_core/lib/src/diagnostics || true
```

Sortie :

```text
```

Commande :

```bash
rg -n "Color\\(|Colors\\.|0xFF|0xff" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart || true
```

Sortie :

```text
```

Commande :

```bash
rg -n "gpt-image-2|image_generation|generate image|AI image|image model" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/test/cinematic_builder_workspace_test.dart reports/narrativeStudio/scenes/road_map_scenes.md reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md reports/narrativeStudio/scenes/ns_scenes_v1_64_cinematic_timeline_mouse_probe_boundary_snap_v0.md || true
```

Sortie :

```text
```

Commande :

```bash
rg -n "selbrume|mael|maël|lysa|port_brisants|bourg_selbrume|phare|brume|marais" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/test/cinematic_builder_workspace_test.dart || true
```

Sortie :

```text
```

Note : la meme recherche sur les roadmaps retourne des mentions historiques de Selbrume et des non-objectifs de lots precedents. Elle ne retourne aucun hit dans le code V1-64.

## 9. Git checks

Commande :

```bash
git diff --check
```

Sortie :

```text
```

Commande :

```bash
git diff --stat
```

Sortie :

```text
 .../cinematics/cinematic_builder_workspace.dart    | 244 ++++++++++++-
 .../test/cinematic_builder_workspace_test.dart     | 378 ++++++++++++++++++++-
 .../scenes/road_map_scene_builder_authoring.md     |  19 +-
 reports/narrativeStudio/scenes/road_map_scenes.md  |  23 +-
 4 files changed, 641 insertions(+), 23 deletions(-)
```

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

Status final verifie apres creation de cette annexe :

```text
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
 M packages/map_editor/test/cinematic_builder_workspace_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_64_cinematic_timeline_mouse_probe_boundary_snap_v0.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_64_evidence_pack.md
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_64_cinematic_timeline_mouse_probe_boundary_snap_v0.png
```

## 10. Auto-review critique

```text
1. Est-ce que V1-64 a modifié map_runtime ? Non.
2. Est-ce que V1-64 a modifié map_gameplay/map_battle/examples ? Non.
3. Est-ce que V1-64 a modifié le modèle JSON ? Non.
4. Est-ce que V1-64 a lancé build_runner ? Non.
5. Est-ce que V1-64 a ajouté du playback ? Non.
6. Est-ce que V1-64 a ajouté un timer ? Non.
7. Est-ce que V1-64 a ajouté isPlaying/currentTimeMs/playbackTimeMs ? Non.
8. Est-ce que V1-64 a ajouté un seek runtime ? Non.
9. Est-ce que V1-64 a ajouté un scrubber runtime ? Non.
10. Est-ce que V1-64 a rendu les transport controls fonctionnels ? Non.
11. Est-ce que V1-64 a ajouté du drag de bloc ? Non.
12. Est-ce que V1-64 a ajouté du resize ? Non.
13. Est-ce que V1-64 a ajouté du reorder ? Non.
14. Est-ce que V1-64 a ajouté une nouvelle capability authoring ? Non.
15. Est-ce que le snap est local editor-only ? Oui.
16. Est-ce que le snap est non persisté ? Oui.
17. Est-ce que les ticks sont exclus ? Oui.
18. Est-ce que 0 ms / totalDurationMs sont des targets ? Oui.
19. Est-ce que block.startMs / block.endMs sont des targets ? Oui.
20. Est-ce que le seuil est 8 px ? Oui.
21. Est-ce que les tie-breaks sont implémentés ? Oui.
22. Est-ce que le badge indique le snap ? Oui.
23. Est-ce que selectedStepId reste inchangé ? Oui.
24. Est-ce que l’inspecteur reste stable ? Oui.
25. Est-ce que la preview sandbox reste non-runtime ? Oui.
26. Est-ce que hover/help/transport restent fonctionnels ? Oui.
27. Est-ce que ProjectManifest n’est pas muté ? Oui.
28. Est-ce que le design system est respecté ? Oui.
29. Est-ce que la Visual Gate prouve le snap ? Oui.
30. Est-ce que l’Evidence Pack est complet sans placeholders ? Oui.
31. Quel est le prochain lot exact recommandé ? NS-SCENES-V1-65 — Cinematic Timeline Mouse Probe UX Polish / Clear Controls V0.
```

## 11. Incident note

Une tentative de lancer des commandes Flutter en parallele a provoque une erreur temporaire de lock/native asset. Les validations finales ont ete relancees sequentiellement et sont vertes. Aucun resultat final ne depend de cette execution interrompue.
