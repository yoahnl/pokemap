# NS-SCENES-V1-62 — Evidence Pack

Date : 2026-06-03

## 1. Gate 0 complet

Commande :

```bash
pwd && git branch --show-current && git status --short --untracked-files=all && git diff --stat && git diff --name-only && git log --oneline -n 15
```

Sortie exacte :

```text
/Users/karim/Project/pokemonProject
main
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
aaa9028f feat(narrative): add cinematic actor movement block v0 prep contract (NS-SCENES-V1-47)
7a4404f6 feat(narrative): add cinematic actor references actor facing v0 (NS-SCENES-V1-46)
c68990a7 feat(narrative): add cinematic wait fade camera basic blocks evidence closure (NS-SCENES-V1-45-BIS)
```

Interpretation : les sorties de `git status --short --untracked-files=all`, `git diff --stat` et `git diff --name-only` etaient vides.

## 2. Fichiers lus

```text
AGENTS.md
agent_rules.md
skills/README.md
skills/test-driven-development/SKILL.md
skills/verification-before-completion/SKILL.md
skills/writing-plans/SKILL.md
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/ns_scenes_v1_61_cinematic_timeline_mouse_playhead_scrub_prep_contract.md
reports/narrativeStudio/scenes/ns_scenes_v1_60_cinematic_timeline_keyboard_navigation_polish_help_overlay_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_60_evidence_pack.md
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

## 3. TDD RED

Test ajoute avant implementation :

```text
sets a local timeline time probe from mouse interaction without changing selection
```

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'sets a local timeline time probe from mouse interaction without changing selection'
```

Sortie RED :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/cinematic_builder_workspace_test.dart
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/cinematic_builder_workspace_test.dart
00:01 +0: sets a local timeline time probe from mouse interaction without changing selection
00:02 +0: sets a local timeline time probe from mouse interaction without changing selection
00:03 +0: sets a local timeline time probe from mouse interaction without changing selection
00:03 +0: sets a local timeline time probe from mouse interaction without changing selection

══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════════════════════════════
The following TestFailure was thrown running a test:
Expected: exactly one matching candidate
  Actual: _TextWidgetFinder:<Found 0 widgets with text "Repère : 750 ms": []>
   Which: means none were found but one was expected

When the exception was thrown, this was the stack:
#4      main.<anonymous closure> (file:///Users/karim/Project/pokemonProject/packages/map_editor/test/cinematic_builder_workspace_test.dart:329:5)
<asynchronous suspension>
#5      testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:192:15)
<asynchronous suspension>
#6      TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1952:5)
<asynchronous suspension>
<asynchronous suspension>
(elided one frame from package:stack_trace)

This was caught by the test expectation on the following line:
  file:///Users/karim/Project/pokemonProject/packages/map_editor/test/cinematic_builder_workspace_test.dart line 329
The test description was:
  sets a local timeline time probe from mouse interaction without changing selection
════════════════════════════════════════════════════════════════════════════════════════════════════
00:03 +0 -1: sets a local timeline time probe from mouse interaction without changing selection [E]
  Test failed. See exception logs above.
  The test description was: sets a local timeline time probe from mouse interaction without changing selection

To run this test again: /opt/homebrew/share/flutter/bin/cache/dart-sdk/bin/dart test /Users/karim/Project/pokemonProject/packages/map_editor/test/cinematic_builder_workspace_test.dart -p vm --plain-name 'sets a local timeline time probe from mouse interaction without changing selection'
00:03 +0 -1: Some tests failed.
```

## 4. GREEN cible

Meme commande apres implementation :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/cinematic_builder_workspace_test.dart
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/cinematic_builder_workspace_test.dart
00:01 +0: sets a local timeline time probe from mouse interaction without changing selection
00:02 +0: sets a local timeline time probe from mouse interaction without changing selection
00:02 +1: sets a local timeline time probe from mouse interaction without changing selection
00:02 +1: All tests passed!
```

## 5. Correction intermediaire

La suite Builder a d'abord echoue sur le test V1-52, car le clic sur axe definit maintenant un probe :

```text
Expected: exactly one matching candidate
Actual: _TextWidgetFinder:<Found 0 widgets with text "Sélection : 1.1 s": []>
test description: shows a non-interactive selection cursor on selected block start
```

Resolution : adapter le test a V1-62. Le clic sur axe ne fait plus un no-op ; il affiche `Repere` sans changer la selection.

## 6. Sorties de validation

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
```

```text
00:11 +52: All tests passed!
```

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematics_library_workspace_test.dart
```

```text
00:05 +10: All tests passed!
```

```bash
cd packages/map_core && dart test test/cinematic_timeline_time_layout_read_model_test.dart
```

```text
00:00 +4: All tests passed!
```

```bash
cd packages/map_core && dart test test/cinematic_timeline_lane_read_model_test.dart
```

```text
00:00 +2: All tests passed!
```

```bash
cd packages/map_core && dart analyze
```

```text
Analyzing map_core...
No issues found!
```

```bash
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart test/cinematic_builder_workspace_test.dart
```

```text
Analyzing 2 items...
No issues found! (ran in 1.3s)
```

## 7. Visual Gate

Commande :

```bash
cd packages/map_editor && flutter test --update-goldens --dart-define=NS_SCENES_V1_62_CAPTURE_CINEMATIC_TIMELINE_MOUSE_TIME_PROBE=true --reporter=compact test/cinematic_builder_workspace_test.dart
```

Sortie :

```text
00:09 +52: All tests passed!
```

Preuve fichier :

```bash
ls -l reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_62_cinematic_timeline_mouse_time_probe_playhead_drag_v0.png
file reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_62_cinematic_timeline_mouse_time_probe_playhead_drag_v0.png
shasum reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_62_cinematic_timeline_mouse_time_probe_playhead_drag_v0.png
```

```text
-rw-r--r--  1 karim  staff  232005 Jun  3 03:07 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_62_cinematic_timeline_mouse_time_probe_playhead_drag_v0.png
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_62_cinematic_timeline_mouse_time_probe_playhead_drag_v0.png: PNG image data, 1663 x 926, 8-bit/color RGBA, non-interlaced
69cd75174fc642ce10c6dd6f55c75a356c2b6322  reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_62_cinematic_timeline_mouse_time_probe_playhead_drag_v0.png
```

Observation visuelle : le screenshot montre `Repere : 750 ms`, le repere vertical, `Repere temporel : 750 ms`, l'inspecteur stable sur `step_face` et les transports disabled.

## 8. Checks anti-scope

```bash
git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle examples
```

```text

```

```bash
rg -n "PlayableMapGame|SceneRuntimeExecutor|SceneEventRuntimeHook|SceneCinematicRuntimeAwaitableAdapter|SceneCinematicRuntimeNoVisualPlayer|playCinematic" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/test/cinematic_builder_workspace_test.dart || true
```

```text

```

```bash
rg -n "startPlayback|stopPlayback|pausePlayback|resumePlayback|runtimePreview|previewRuntime|playCinematic|PlaybackController|Timer\(|Ticker|AnimationController|isPlaying|currentTimeMs|playbackTimeMs" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/test/cinematic_builder_workspace_test.dart || true
```

```text

```

```bash
rg -n "seek|scrub|scrubber|runtimeSeek|seekTo|scrubTo" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/test/cinematic_builder_workspace_test.dart || true
```

```text

```

```bash
rg -n "Draggable|LongPressDraggable|DragTarget|drag.*block|onHorizontalDrag.*block|resize|reorder|moveUp|moveDown|keyframe|overlap" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/test/cinematic_builder_workspace_test.dart || true
```

```text
packages/map_editor/test/cinematic_builder_workspace_test.dart:147:    expect(find.text('resize'), findsNothing);
packages/map_editor/test/cinematic_builder_workspace_test.dart:542:  testWidgets('dragging a timeline block does not move or resize it',
packages/map_editor/test/cinematic_builder_workspace_test.dart:576:    expect(find.text('resize'), findsNothing);
packages/map_editor/test/cinematic_builder_workspace_test.dart:577:    expect(find.text('reorder'), findsNothing);
```

Interpretation : ces sorties sont des assertions negatives de test, pas une capability active de drag/resize/reorder.

```bash
rg -n "timelineProbeTimeMs|mouseProbeTimeMs|cursorTimeMs|playheadTimeMs|currentTimeMs|playbackTimeMs|isPlaying|persistedStartMs|persistedEndMs" packages/map_core/lib/src/models packages/map_core/lib/src/authoring packages/map_core/lib/src/diagnostics || true
```

```text

```

```bash
rg -n "Color\(|Colors\.|0xFF|0xff" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart || true
```

```text

```

```bash
rg -n "gpt-image-2|image_generation|generate image|AI image|image model" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/test/cinematic_builder_workspace_test.dart reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_62_cinematic_timeline_mouse_time_probe_playhead_drag_v0.png || true
```

```text

```

```bash
rg -n "selbrume|mael|maël|lysa|port_brisants|bourg_selbrume|phare|brume|marais" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/test/cinematic_builder_workspace_test.dart || true
```

```text

```

## 9. Hunk UI — etat local et propagation

Fichier : `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`

```text
182 class _CinematicBuilderWorkspaceState extends State<CinematicBuilderWorkspace> {
183   String? _selectedStepId;
184   int? _timelineProbeTimeMs;
187   void didUpdateWidget(CinematicBuilderWorkspace oldWidget) {
189     final sameCinematic = oldWidget.asset.id == widget.asset.id;
190     if (!sameCinematic || !_hasStep(widget.asset, _selectedStepId)) {
191       _selectedStepId = null;
193     if (!sameCinematic) {
194       _timelineProbeTimeMs = null;
251                               child: _PreviewSandbox(
256                                 timelineProbeTimeMs: _timelineProbeTimeMs,
262                               child: _TimelinePlaceholder(
265                                 selectedStepId: _selectedStepId,
266                                 timelineProbeTimeMs: _timelineProbeTimeMs,
267                                 onStepSelected: (step) {
268                                   setState(() {
269                                     _selectedStepId = step.id;
270                                     _timelineProbeTimeMs = null;
273                                 onTimelineProbeChanged: (timeMs) {
274                                   setState(() {
275                                     _timelineProbeTimeMs = timeMs;
```

## 10. Hunk UI — preview sandbox

```text
1297 class _PreviewSandbox extends StatelessWidget {
1298   const _PreviewSandbox({
1303     required this.timelineProbeTimeMs,
1310   final int? timelineProbeTimeMs;
1375                   if (!compact && timelineProbeTimeMs != null) ...[
1376                     const SizedBox(height: 10),
1377                     _MutedText(
1378                       'Repère temporel : '
1379                       '${_shortTimeLabel(timelineProbeTimeMs!)}',
1381                     const SizedBox(height: 5),
1382                     const _MutedText('Preview réelle à venir.'),
```

## 11. Hunk UI — badge et passage grille

```text
1578 class _TimelinePlaceholder extends StatefulWidget {
1583     required this.timelineProbeTimeMs,
1585     required this.onTimelineProbeChanged,
1592   final int? timelineProbeTimeMs;
1594   final ValueChanged<int> onTimelineProbeChanged;
1667     final timelineProbeTimeMs = widget.timelineProbeTimeMs;
1777                     if (timelineProbeTimeMs != null) ...[
1779                       PokeMapBadge(
1780                         key: const ValueKey(
1781                             'cinematic-builder-time-probe-badge'),
1782                         label:
1783                             'Repère : ${_shortTimeLabel(timelineProbeTimeMs)}',
1784                         variant: PokeMapBadgeVariant.narrative,
1786                     ] else if (selectedBlock != null) ...[
1812                               timelineProbeTimeMs: timelineProbeTimeMs,
1820                               onTimelineProbeChanged: (timeMs) {
1821                                 _requestTimelineKeyboardFocus();
1822                                 widget.onTimelineProbeChanged(timeMs);
```

## 12. Hunk UI — grille, scroll, repere

```text
2071 class _TimelineTimeGrid extends StatelessWidget {
2078     required this.timelineProbeTimeMs,
2083     required this.onTimelineProbeChanged,
2091   final int? timelineProbeTimeMs;
2096   final ValueChanged<int> onTimelineProbeChanged;
2134                     key: const ValueKey(
2135                       'cinematic-builder-time-horizontal-scroll',
2147                               _TimelineAxis(
2151                                 totalDurationMs: timeLayout.totalDurationMs,
2152                                 onTimelineProbeChanged: onTimelineProbeChanged,
2155                                 _TimelineTrackRow(
2164                                   contentWidth: contentWidth,
2165                                   totalDurationMs: timeLayout.totalDurationMs,
2168                                   onTimelineProbeChanged:
2169                                       onTimelineProbeChanged,
2173                           if (timelineProbeTimeMs != null)
2174                             Positioned(
2175                               left: _tickLeft(
2176                                     timelineProbeTimeMs!,
2177                                     pixelsPerMs,
2178                                     contentWidth,
2180                                   6,
2183                               child: const _TimelineTimeProbeCursor(),
```

## 13. Hunk UI — axe et curseur probe

```text
2294 class _TimelineAxis extends StatelessWidget {
2299     required this.totalDurationMs,
2300     required this.onTimelineProbeChanged,
2306   final int totalDurationMs;
2307   final ValueChanged<int> onTimelineProbeChanged;
2312     return GestureDetector(
2313       behavior: HitTestBehavior.opaque,
2314       onTapDown: (details) => onTimelineProbeChanged(
2315         _timelineProbeTimeMsFromLocalX(
2316           details.localPosition.dx,
2317           pixelsPerMs: pixelsPerMs,
2318           contentWidth: contentWidth,
2319           totalDurationMs: totalDurationMs,
2322       onPanStart: (details) => onTimelineProbeChanged(
2330       onPanUpdate: (details) => onTimelineProbeChanged(
2391 class _TimelineTimeProbeCursor extends StatelessWidget {
2397     return IgnorePointer(
2407               child: Container(
2408                 key: const ValueKey('cinematic-builder-time-probe-cursor'),
2410                 decoration: BoxDecoration(
2411                   color: colors.narrative.withValues(alpha: 0.9),
2425               child: DecoratedBox(
2426                 key: const ValueKey(
2427                   'cinematic-builder-time-probe-cursor-handle',
2430                   color: colors.narrativeSoft,
2431                   border: Border.all(color: colors.narrative),
```

## 14. Hunk UI — fond des pistes et conversion

```text
2574     required this.stepsById,
2579     required this.contentWidth,
2580     required this.totalDurationMs,
2583     required this.onTimelineProbeChanged,
2594   final double contentWidth;
2595   final int totalDurationMs;
2598   final ValueChanged<int> onTimelineProbeChanged;
2614             Positioned.fill(
2615               child: GestureDetector(
2616                 behavior: HitTestBehavior.opaque,
2617                 onTapDown: (details) => onTimelineProbeChanged(
2618                   _timelineProbeTimeMsFromLocalX(
2619                     details.localPosition.dx,
2620                     pixelsPerMs: pixelsPerMs,
2621                     contentWidth: contentWidth,
2622                     totalDurationMs: totalDurationMs,
2625                 onPanStart: (details) => onTimelineProbeChanged(
2633                 onPanUpdate: (details) => onTimelineProbeChanged(
3910 int _timelineProbeTimeMsFromLocalX(
3911   double localX, {
3912   required double pixelsPerMs,
3913   required double contentWidth,
3914   required int totalDurationMs,
3916   if (totalDurationMs <= 0 || pixelsPerMs <= 0) {
3917     return 0;
3919   final boundedX = localX.clamp(0.0, contentWidth);
3920   final timeMs = boundedX / pixelsPerMs;
3921   return timeMs.clamp(0.0, totalDurationMs.toDouble()).round();
```

## 15. Hunk tests — probe, clamp, clear, scroll, non-drag

Fichier : `packages/map_editor/test/cinematic_builder_workspace_test.dart`

```text
280     expect(find.text('Sélection : 1.1 s'), findsNothing);
281     expect(find.textContaining('Repère :'), findsOneWidget);
287       find.byKey(const ValueKey('cinematic-builder-time-probe-cursor')),
296   testWidgets(
297       'sets a local timeline time probe from mouse interaction without changing selection',
338     expect(find.text('Repère : 750 ms'), findsOneWidget);
339     expect(find.text('Repère temporel : 750 ms'), findsOneWidget);
341     expect(find.text('Sélection : 500 ms'), findsNothing);
351     expect(probeCursorRect.center.dx, closeTo(probeX, 2));
352     expect(projectChangeCount, 0);
353     expect(project.toJson(), before);
360   testWidgets('drags local timeline time probe and clamps to boundaries',
390     expect(find.text('Repère : 500 ms'), findsOneWidget);
394     expect(find.text('Repère : 3 s'), findsOneWidget);
398     expect(find.text('Repère : 0 ms'), findsOneWidget);
406     expect(probeCursorRect.center.dx, closeTo(tick0Rect.left, 2));
415   testWidgets('clears local time probe when selecting blocks or using keyboard',
452     expect(find.text('Repère : 750 ms'), findsOneWidget);
460     _expectTimelineStepSelected(tester, 'step_move');
461     expect(find.text('Repère : 750 ms'), findsNothing);
475     await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
478     _expectTimelineStepSelected(tester, 'step_fade');
479     expect(find.text('Repère : 750 ms'), findsNothing);
488     await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
491     _expectTimelineStepSelected(tester, 'step_face');
492     expect(find.text('Repère : 750 ms'), findsNothing);
498   testWidgets('time probe accounts for horizontal scroll offset',
512     await tester.drag(
513       find.byKey(const ValueKey('cinematic-builder-time-horizontal-scroll')),
533     expect(find.text('Repère : 2.5 s'), findsOneWidget);
537     expect(probeCursorRect.center.dx, closeTo(probeX, 2));
542   testWidgets('dragging a timeline block does not move or resize it',
567     final moveRectAfter = tester.getRect(moveFinder);
568     expect(moveRectAfter.left, closeTo(moveRectBefore.left, 1));
569     expect(moveRectAfter.width, closeTo(moveRectBefore.width, 1));
570     expect(
571       find.byKey(const ValueKey('cinematic-builder-time-probe-cursor')),
572       findsNothing,
```

## 16. Hunk tests — Visual Gate et fixture longue

```text
3041   testWidgets(
3042       'captures V1-62 cinematic timeline mouse time probe when requested',
3044     if (!const bool.fromEnvironment(
3045       'NS_SCENES_V1_62_CAPTURE_CINEMATIC_TIMELINE_MOUSE_TIME_PROBE',
3050     _setLargeSurface(tester, _referenceTimelineSurfaceSize);
3051     await _loadScreenshotFonts();
3062     await tester.tapAt(faceRect.center);
3075     await tester.tapAt(
3076       Offset(tick0Rect.left + pxPer500Ms * 1.5, axisRect.center.dy),
3080     expect(find.text('Repère : 750 ms'), findsOneWidget);
3081     expect(find.text('Repère temporel : 750 ms'), findsOneWidget);
3083       find.byKey(const ValueKey('cinematic-builder-time-probe-cursor')),
3087       find.byKey(const ValueKey('cinematic-builder-keyboard-help-button')),
3091       find.byKey(const ValueKey('cinematic-builder-transport-controls')),
3095     final screenshotFile = File(
3096       '../../reports/narrativeStudio/scenes/screenshots/'
3097       'ns_scenes_v1_62_cinematic_timeline_mouse_time_probe_'
3098       'playhead_drag_v0.png',
3697 CinematicAsset _longTimelineCinematic() {
3699     id: 'cinematic_long_probe',
3701     description: 'Neutral fixture for horizontal probe scroll.',
3705         for (var index = 0; index < 10; index += 1)
3707             id: 'step_wait_$index',
3710             durationMs: 1000,
```

## 17. Hunk roadmaps

```text
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md:12
NS-SCENES-V1-63 — Cinematic Timeline Mouse Probe Polish / Boundary Snap Prep V0

reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md:98
NS-SCENES-V1-62 ... DONE : click/drag axe/fond, clamp 0..totalDurationMs, scroll horizontal, selection/inspecteur preserves, probe clear sur selection bloc/clavier, hover/aide/clavier/transports preserves, non-mutation.

reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md:99
NS-SCENES-V1-63 — Cinematic Timeline Mouse Probe Polish / Boundary Snap Prep V0

reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md:972-984
Mise a jour V1-62 ajoutee avec statut DONE, scope, limites, preuve et prochain lot exact.

reports/narrativeStudio/scenes/road_map_scenes.md:119
NS-SCENES-V1-62 — Cinematic Timeline Mouse Time Probe / Playhead Drag V0 | DONE

reports/narrativeStudio/scenes/road_map_scenes.md:123
NS-SCENES-V1-63 — Cinematic Timeline Mouse Probe Polish / Boundary Snap Prep V0

reports/narrativeStudio/scenes/road_map_scenes.md:287-299
Mise a jour V1-62 ajoutee avec statut DONE, scope, limites, preuve et prochain lot exact.
```

## 18. Auto-review critique

1. map_runtime modifie : non.
2. map_gameplay/map_battle/examples modifies : non.
3. modele JSON modifie : non.
4. build_runner lance : non.
5. playback ajoute : non.
6. timer ajoute : non.
7. `isPlaying/currentTimeMs/playbackTimeMs` ajoutes : non.
8. seek runtime ajoute : non.
9. scrubber runtime ajoute : non.
10. transports fonctionnels : non.
11. drag de bloc ajoute : non.
12. resize ajoute : non.
13. reorder ajoute : non.
14. nouvelle capability authoring : non, inspection temporelle locale uniquement.
15. `timelineProbeTimeMs` editor-only : oui.
16. probe non persiste : oui.
17. click axe/fond definit un repere : oui.
18. drag axe/fond deplace le repere : oui.
19. origine X : oui.
20. scroll horizontal : oui, teste.
21. clamp : oui.
22. selection barre clear probe : oui.
23. navigation clavier clear probe : oui.
24. inspecteur stable : oui.
25. preview sandbox non runtime : oui.
26. hover/help/transport preserves : oui.
27. `ProjectManifest` non mute : oui.
28. design system respecte : oui.
29. Visual Gate prouve le repere : oui.
30. prochain lot exact : `NS-SCENES-V1-63 — Cinematic Timeline Mouse Probe Polish / Boundary Snap Prep V0`.
