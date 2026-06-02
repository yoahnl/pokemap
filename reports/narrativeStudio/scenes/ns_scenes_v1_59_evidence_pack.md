# NS-SCENES-V1-59 — Evidence Pack

## 1. Gate 0

Commande :

```bash
pwd && git branch --show-current && git status --short --untracked-files=all && git diff --stat && git diff --name-only && git log --oneline -n 15
```

Sortie exacte :

```text
/Users/karim/Project/pokemonProject
main
e1e83cd9 feat(narrative): add cinematic timeline lane vertical navigation prep contract (NS-SCENES-V1-58)
26958d88 feat(narrative): add cinematic timeline keyboard navigation selection polish v0 (NS-SCENES-V1-57)
af8a3bf9 feat(narrative): add cinematic timeline bar geometry duration scale correction v0 (NS-SCENES-V1-56)
16a888b1 feat(narrative): add cinematic timeline visual polish density pass and interaction polish hover details v0 (NS-SCENES-V1-54-V1-55)
13f423c1 feat(narrative): add cinematic timeline transport controls placeholder v0 (NS-SCENES-V1-53)
df27cccb feat(narrative): add cinematic timeline selection cursor playhead placeholder v0 (NS-SCENES-V1-52)
8ce1a417 feat(narrative): add cinematic actor movement inspector polish and timeline time axis bar layout v0 (NS-SCENES-V1-50-V1-51)
7d6c94cf feat(narrative): add cinematic actor movement block v0 (NS-SCENES-V1-49)
77d12c69 feat(narrative): add cinematic timeline lane grouping v0 (NS-SCENES-V1-48)
aaa9028f feat(narrative): add cinematic actor movement block v0 prep contract (NS-SCENES-V1-47)
7a4404f6 feat(narrative): add cinematic actor references actor facing v0 (NS-SCENES-V1-46)
c68990a7 feat(narrative): add cinematic wait fade camera basic blocks evidence closure (NS-SCENES-V1-45-BIS)
88cb3a54 feat(narrative): add cinematic wait fade camera basic blocks v0 (NS-SCENES-V1-45)
6e66a66d feat(narrative): add cinematic timeline authoring drafts evidence closure (NS-SCENES-V1-44-BIS)
eb0ea9b6 feat(narrative): add cinematic timeline authoring drafts v0 (NS-SCENES-V1-44)
```

Interpretation : `git status --short --untracked-files=all`, `git diff --stat` et `git diff --name-only` etaient vides.

## 2. Fichiers lus

```text
AGENTS.md
agent_rules.md
skills/README.md
skills/test-driven-development/SKILL.md
skills/verification-before-completion/SKILL.md
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/ns_scenes_v1_58_cinematic_timeline_lane_vertical_navigation_prep_contract.md
reports/narrativeStudio/scenes/ns_scenes_v1_57_cinematic_timeline_keyboard_navigation_selection_polish_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_57_evidence_pack.md
reports/narrativeStudio/scenes/ns_scenes_v1_56_cinematic_timeline_bar_geometry_duration_scale_correction_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_56_evidence_pack.md
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/lib/src/ui/design_system/pokemap_card.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
packages/map_editor/test/cinematics_library_workspace_test.dart
packages/map_core/lib/src/read_models/cinematic_timeline_time_layout_read_model.dart
packages/map_core/lib/src/read_models/cinematic_timeline_lane_read_model.dart
packages/map_core/test/cinematic_timeline_time_layout_read_model_test.dart
packages/map_core/test/cinematic_timeline_lane_read_model_test.dart
```

## 3. TDD RED

Test ajoute avant implementation :

```text
navigates selected timeline blocks vertically with local keyboard focus
```

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'navigates selected timeline blocks vertically with local keyboard focus'
```

Sortie RED :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/cinematic_builder_workspace_test.dart
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/cinematic_builder_workspace_test.dart
00:01 +0: navigates selected timeline blocks vertically with local keyboard focus
00:02 +0: navigates selected timeline blocks vertically with local keyboard focus
00:02 +0: navigates selected timeline blocks vertically with local keyboard focus
══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════════════════════════════
The following TestFailure was thrown running a test:
Expected: true
  Actual: <false>

When the exception was thrown, this was the stack:
#4      _expectTimelineStepSelected (file:///Users/karim/Project/pokemonProject/packages/map_editor/test/cinematic_builder_workspace_test.dart:3392:3)
#5      main.<anonymous closure> (file:///Users/karim/Project/pokemonProject/packages/map_editor/test/cinematic_builder_workspace_test.dart:736:5)
<asynchronous suspension>
#6      testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:192:15)
<asynchronous suspension>
#7      TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1952:5)
<asynchronous suspension>
<asynchronous suspension>
(elided one frame from package:stack_trace)

This was caught by the test expectation on the following line:
  file:///Users/karim/Project/pokemonProject/packages/map_editor/test/cinematic_builder_workspace_test.dart line 3392
The test description was:
  navigates selected timeline blocks vertically with local keyboard focus
════════════════════════════════════════════════════════════════════════════════════════════════════
00:02 +0 -1: navigates selected timeline blocks vertically with local keyboard focus [E]
  Test failed. See exception logs above.
  The test description was: navigates selected timeline blocks vertically with local keyboard focus

To run this test again: /opt/homebrew/share/flutter/bin/cache/dart-sdk/bin/dart test /Users/karim/Project/pokemonProject/packages/map_editor/test/cinematic_builder_workspace_test.dart -p vm --plain-name 'navigates selected timeline blocks vertically with local keyboard focus'
00:02 +0 -1: Some tests failed.
```

Interpretation : le test echoue car ArrowDown ne mappe encore aucune selection verticale.

## 4. Hunk production complet

Fichier : `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`

```diff
@@ -1419,6 +1419,8 @@ const _timelinePixelsPerMsFloor = 0.32;
 enum _TimelineKeyboardNavigation {
   previous,
   next,
+  up,
+  down,
   first,
   last,
 }
@@ -1432,6 +1434,12 @@ _TimelineKeyboardNavigation? _timelineKeyboardNavigationForKey(
   if (key == LogicalKeyboardKey.arrowRight) {
     return _TimelineKeyboardNavigation.next;
   }
+  if (key == LogicalKeyboardKey.arrowUp) {
+    return _TimelineKeyboardNavigation.up;
+  }
+  if (key == LogicalKeyboardKey.arrowDown) {
+    return _TimelineKeyboardNavigation.down;
+  }
   if (key == LogicalKeyboardKey.home) {
     return _TimelineKeyboardNavigation.first;
   }
@@ -1462,9 +1470,86 @@ CinematicTimelineTimeBlock? _timelineKeyboardTargetBlock(
         : blocks[math.min(selectedIndex + 1, blocks.length - 1)],
     _TimelineKeyboardNavigation.previous =>
       selectedIndex < 0 ? blocks.last : blocks[math.max(selectedIndex - 1, 0)],
+    _TimelineKeyboardNavigation.up => _timelineVerticalKeyboardTargetBlock(
+        timeLayout,
+        selectedStepId,
+        up: true,
+      ),
+    _TimelineKeyboardNavigation.down => _timelineVerticalKeyboardTargetBlock(
+        timeLayout,
+        selectedStepId,
+        up: false,
+      ),
   };
 }
 
+CinematicTimelineTimeBlock? _timelineVerticalKeyboardTargetBlock(
+  CinematicTimelineTimeLayoutReadModel timeLayout,
+  String? selectedStepId, {
+  required bool up,
+}) {
+  final selectedBlock = _selectedTimeBlock(timeLayout, selectedStepId);
+  if (selectedBlock == null) {
+    return _timelineVerticalFallbackTargetBlock(timeLayout, up: up);
+  }
+  final currentLaneIndex = timeLayout.lanes.indexWhere(
+    (lane) => lane.laneId == selectedBlock.laneId,
+  );
+  if (currentLaneIndex < 0) {
+    return _timelineVerticalFallbackTargetBlock(timeLayout, up: up);
+  }
+  final currentCenterMs = _timelineBlockCenterMs(selectedBlock);
+  final direction = up ? -1 : 1;
+  for (var laneIndex = currentLaneIndex + direction;
+      laneIndex >= 0 && laneIndex < timeLayout.lanes.length;
+      laneIndex += direction) {
+    final lane = timeLayout.lanes[laneIndex];
+    if (lane.blocks.isEmpty) {
+      continue;
+    }
+    return _timelineClosestBlockInLane(lane, currentCenterMs);
+  }
+  return selectedBlock;
+}
+
+CinematicTimelineTimeBlock? _timelineVerticalFallbackTargetBlock(
+  CinematicTimelineTimeLayoutReadModel timeLayout, {
+  required bool up,
+}) {
+  final lanes = up ? timeLayout.lanes.reversed : timeLayout.lanes;
+  for (final lane in lanes) {
+    if (lane.blocks.isEmpty) {
+      continue;
+    }
+    return up ? lane.blocks.last : lane.blocks.first;
+  }
+  return null;
+}
+
+CinematicTimelineTimeBlock _timelineClosestBlockInLane(
+  CinematicTimelineTimeLane lane,
+  double currentCenterMs,
+) {
+  var bestBlock = lane.blocks.first;
+  var bestDistance =
+      (_timelineBlockCenterMs(bestBlock) - currentCenterMs).abs();
+  for (final candidate in lane.blocks.skip(1)) {
+    final candidateDistance =
+        (_timelineBlockCenterMs(candidate) - currentCenterMs).abs();
+    final distanceOrder = candidateDistance.compareTo(bestDistance);
+    if (distanceOrder < 0 ||
+        (distanceOrder == 0 && candidate.stepIndex < bestBlock.stepIndex)) {
+      bestBlock = candidate;
+      bestDistance = candidateDistance;
+    }
+  }
+  return bestBlock;
+}
+
+double _timelineBlockCenterMs(CinematicTimelineTimeBlock block) {
+  return block.startMs + block.visualDurationMs / 2;
+}
+
 class _TimelinePlaceholder extends StatefulWidget {
@@ -1661,7 +1746,7 @@ class _TimelinePlaceholderState extends State<_TimelinePlaceholder> {
                         key: ValueKey(
                           'cinematic-builder-keyboard-navigation-badge',
                         ),
-                        label: 'Navigation clavier : ← → Home End',
+                        label: 'Navigation clavier : ← → ↑ ↓ Home End',
                         variant: PokeMapBadgeVariant.info,
                       ),
@@ -2380,7 +2465,7 @@ class _TimelineStepCard extends StatelessWidget {
     }
     return Semantics(
       label: _timelineHoverSemanticsLabel(asset, block, step, lane),
-      hint: 'Utilisez les flèches gauche et droite pour changer de bloc.',
+      hint: 'Utilisez les flèches pour changer de bloc.',
       selected: selected,
```

## 5. Hunk tests ajoutés

Fichier : `packages/map_editor/test/cinematic_builder_workspace_test.dart`

Tests ajoutes dans le diff :

```text
navigates selected timeline blocks vertically with local keyboard focus
uses step index as vertical navigation tie break
handles vertical navigation without selection and empty timelines
keeps vertical keyboard shortcuts local and protects text fields
captures V1-59 cinematic timeline lane vertical navigation when requested
```

Fixture ajoutee :

```text
_verticalTieBreakCinematic()
```

Helper ajoute :

```text
_expectTimelineStepSelected(WidgetTester tester, String stepId)
```

Attentes modifiees :

```text
Navigation clavier : ← → Home End
Navigation clavier : ← → ↑ ↓ Home End
```

## 6. GREEN ciblés

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'navigates selected timeline blocks vertically with local keyboard focus'
```

Sortie :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/cinematic_builder_workspace_test.dart
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/cinematic_builder_workspace_test.dart
00:01 +0: navigates selected timeline blocks vertically with local keyboard focus
00:02 +0: navigates selected timeline blocks vertically with local keyboard focus
00:03 +0: navigates selected timeline blocks vertically with local keyboard focus
00:03 +1: navigates selected timeline blocks vertically with local keyboard focus
00:03 +1: All tests passed!
```

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'keeps vertical keyboard shortcuts local and protects text fields'
```

Sortie :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/cinematic_builder_workspace_test.dart
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/cinematic_builder_workspace_test.dart
00:01 +0: keeps vertical keyboard shortcuts local and protects text fields
00:02 +0: keeps vertical keyboard shortcuts local and protects text fields
00:02 +1: keeps vertical keyboard shortcuts local and protects text fields
00:02 +1: All tests passed!
```

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'uses step index as vertical navigation tie break'
```

Sortie :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/cinematic_builder_workspace_test.dart
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/cinematic_builder_workspace_test.dart
00:01 +0: uses step index as vertical navigation tie break
00:02 +0: uses step index as vertical navigation tie break
00:02 +1: uses step index as vertical navigation tie break
00:02 +1: All tests passed!
```

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'handles vertical navigation without selection and empty timelines'
```

Sortie :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/cinematic_builder_workspace_test.dart
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/cinematic_builder_workspace_test.dart
00:01 +0: handles vertical navigation without selection and empty timelines
00:02 +0: handles vertical navigation without selection and empty timelines
00:02 +1: handles vertical navigation without selection and empty timelines
00:02 +1: All tests passed!
```

## 7. Suite Builder

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
```

Sortie utile :

```text
00:06 +44: captures V1-59 cinematic timeline lane vertical navigation when requested
00:06 +44: All tests passed!
```

## 8. Suite Library

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematics_library_workspace_test.dart
```

Sortie utile :

```text
00:04 +10: captures V1-38 Cinematics Library screenshot when requested
00:04 +10: All tests passed!
```

## 9. Core non-régression

Commande :

```bash
cd packages/map_core && dart test test/cinematic_timeline_time_layout_read_model_test.dart && dart test test/cinematic_timeline_lane_read_model_test.dart && dart analyze
```

Sortie utile :

```text
00:00 +4: All tests passed!
00:00 +2: All tests passed!
Analyzing map_core...
No issues found!
```

## 10. Analyze editor ciblé

Commande :

```bash
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart test/cinematic_builder_workspace_test.dart
```

Sortie :

```text
Analyzing 2 items...
No issues found! (ran in 1.7s)
```

## 11. Visual Gate

Commande :

```bash
cd packages/map_editor && flutter test --update-goldens --dart-define=NS_SCENES_V1_59_CAPTURE_CINEMATIC_TIMELINE_VERTICAL_NAVIGATION=true --reporter=compact test/cinematic_builder_workspace_test.dart
```

Sortie utile :

```text
00:07 +44: captures V1-59 cinematic timeline lane vertical navigation when requested
00:07 +44: All tests passed!
```

Fichier :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_59_cinematic_timeline_lane_vertical_navigation_v0.png
```

Preuve :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_59_cinematic_timeline_lane_vertical_navigation_v0.png: PNG image data, 1663 x 926, 8-bit/color RGBA, non-interlaced
-rw-r--r--  1 karim  staff  228485 Jun  3 01:00 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_59_cinematic_timeline_lane_vertical_navigation_v0.png
491f92d2ee245e92015d73ff6afc8b4d7356079045085606e23d2c15d06d1da9  reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_59_cinematic_timeline_lane_vertical_navigation_v0.png
```

## 12. Checks anti-scope

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
rg -n "startPlayback|stopPlayback|pausePlayback|resumePlayback|seek|scrub|scrubber|runtimePreview|previewRuntime|playCinematic|PlaybackController|Timer\\(|Ticker|AnimationController|isPlaying|currentTimeMs|playbackTimeMs" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/test/cinematic_builder_workspace_test.dart || true
```

Sortie :

```text
```

Commande :

```bash
rg -n "Draggable|LongPressDraggable|DragTarget|onHorizontalDrag|onPanUpdate|onScaleUpdate|gesture.*timeline|drag.*cursor|drag.*playhead|resize|reorder|moveUp|moveDown|keyframe|overlap" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/test/cinematic_builder_workspace_test.dart || true
```

Sortie :

```text
packages/map_editor/test/cinematic_builder_workspace_test.dart:147:    expect(find.text('resize'), findsNothing);
packages/map_editor/test/cinematic_builder_workspace_test.dart:555:    await gesture.moveTo(timelineRect.topLeft - const Offset(16, 16));
```

Interpretation : ces deux lignes sont des tests anti-capability / hover preexistants, pas du drag/drop, resize ou reorder produit.

Commande :

```bash
rg -n "cursorTimeMs|playheadTimeMs|currentTimeMs|playbackTimeMs|timelineLayout|laneLayout|transportState|isPlaying|persistedStartMs|persistedEndMs|keyboardSelection|focusedStepId|centerMs" packages/map_core/lib/src/models packages/map_core/lib/src/authoring packages/map_core/lib/src/diagnostics || true
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
rg -n "selbrume|mael|maël|lysa|port_brisants|bourg_selbrume|phare|brume|marais" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/test/cinematic_builder_workspace_test.dart || true
```

Sortie :

```text
```

## 13. Fichiers créés

```text
reports/narrativeStudio/scenes/ns_scenes_v1_59_cinematic_timeline_lane_vertical_navigation_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_59_evidence_pack.md
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_59_cinematic_timeline_lane_vertical_navigation_v0.png
```

## 14. Fichiers modifiés

```text
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
```

## 15. Auto-review critique

- ArrowUp / ArrowDown utilisent uniquement les read models derives.
- Aucun pixel, hover, souris ou ordre DOM n'est source de navigation.
- La timeline vide ne crashe pas.
- Les bords gardent la selection.
- Le cas sans selection est teste.
- Les TextFields restent proteges.
- Le curseur, l'inspecteur et la preview suivent la selection via le chemin existant.
- Le projet n'est pas mute par la navigation.
- Les roadmaps recommandent un seul prochain lot : `NS-SCENES-V1-60 — Cinematic Timeline Keyboard Navigation Polish / Help Overlay V0`.

## 16. Final git / diff checks

Commande :

```bash
git diff --check
```

Sortie :

```text
```

Commande :

```bash
git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle examples
```

Sortie :

```text
```

Commande :

```bash
git diff --stat && git diff --name-only && git status --short --untracked-files=all
```

Sortie :

```text
 .../cinematics/cinematic_builder_workspace.dart    |  89 ++++-
 .../test/cinematic_builder_workspace_test.dart     | 364 ++++++++++++++++++++-
 .../scenes/road_map_scene_builder_authoring.md     |  17 +-
 reports/narrativeStudio/scenes/road_map_scenes.md  |  23 +-
 4 files changed, 484 insertions(+), 9 deletions(-)
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
 M packages/map_editor/test/cinematic_builder_workspace_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_59_cinematic_timeline_lane_vertical_navigation_v0.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_59_evidence_pack.md
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_59_cinematic_timeline_lane_vertical_navigation_v0.png
```
