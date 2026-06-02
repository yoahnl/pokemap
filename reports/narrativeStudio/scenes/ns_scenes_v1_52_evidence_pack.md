# NS-SCENES-V1-52 — Evidence Pack

## 1. Gate 0

Commande : `pwd`

```text
/Users/karim/Project/pokemonProject
```

Commande : `git branch --show-current`

```text
main
```

Commande : `git status --short --untracked-files=all` avant edits V1-52

```text
```

Commande : `git diff --stat` avant edits V1-52

```text
```

Commande : `git diff --name-only` avant edits V1-52

```text
```

Commande : `git log --oneline -n 15` avant edits V1-52

```text
8ce1a417 feat(narrative): add cinematic actor movement inspector polish and timeline time axis bar layout v0 (NS-SCENES-V1-50-V1-51)
7d6c94cf feat(narrative): add cinematic actor movement block v0 (NS-SCENES-V1-49)
77d12c69 feat(narrative): add cinematic timeline lane grouping v0 (NS-SCENES-V1-48)
aaa9028f feat(narrative): add cinematic actor movement block v0 prep contract (NS-SCENES-V1-47)
7a4404f6 feat(narrative): add cinematic actor references actor facing v0 (NS-SCENES-V1-46)
c68990a7 feat(narrative): add cinematic wait fade camera basic blocks evidence closure (NS-SCENES-V1-45-BIS)
88cb3a54 feat(narrative): add cinematic wait fade camera basic blocks v0 (NS-SCENES-V1-45)
6e66a66d feat(narrative): add cinematic timeline authoring drafts evidence closure (NS-SCENES-V1-44-BIS)
eb0ea9b6 feat(narrative): add cinematic timeline authoring drafts v0 (NS-SCENES-V1-44)
2805560d feat(narrative): add cinematic timeline read-only step inspector evidence closure (NS-SCENES-V1-43-BIS)
6c3b1074 feat(narrative): add cinematic timeline read-only step inspector v0 (NS-SCENES-V1-43)
e95290ce feat(narrative): add cinematic builder v0 shell evidence closure (NS-SCENES-V1-42-BIS)
c9d44fc8 feat(narrative): add cinematic builder v0 shell (NS-SCENES-V1-42)
38f09efa feat(narrative): add cinematic builder v0 scope and runtime playback contract (NS-SCENES-V1-41)
9e1d45d9 feat(narrative): add cinematic runtime adapter v0 bis evidence closure (NS-SCENES-V1-40)
```

## 2. TDD RED / GREEN

RED cible :

```text
cd packages/map_editor
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'shows a non-interactive selection cursor on selected block start'
```

Resultat RED observe :

```text
Expected: exactly one matching candidate
  Actual: _TextWidgetFinder:<Found 0 widgets with text "Sélection : 500 ms": []>
```

GREEN cible :

```text
cd packages/map_editor
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'shows a non-interactive selection cursor on selected block start'
```

Resultat :

```text
00:02 +1: All tests passed!
```

## 3. Hunk production V1-52

Fichier : `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`

Changements principaux :

```diff
+    final selectedBlock = _selectedTimeBlock(timeLayout, selectedStepId);
+              if (selectedBlock != null)
+                PokeMapBadge(
+                  key: const ValueKey('cinematic-builder-selected-time-badge'),
+                  label:
+                      'Sélection : ${_shortTimeLabel(selectedBlock.startMs)}',
+                  variant: PokeMapBadgeVariant.info,
+                ),
+                    selectedBlock: selectedBlock,
+  final CinematicTimelineTimeBlock? selectedBlock;
+                    child: Stack(
+                        if (selectedBlock != null)
+                          Positioned(
+                            left: _tickLeft(
+                                  selectedBlock!.startMs,
+                                  pixelsPerMs,
+                                  contentWidth,
+                                ) -
+                                6,
+                            top: 0,
+                            bottom: 0,
+                            child: const _TimelineSelectionCursor(),
+                          ),
+      key: const ValueKey('cinematic-builder-time-axis'),
+class _TimelineSelectionCursor extends StatelessWidget {
+  const _TimelineSelectionCursor();
+    return IgnorePointer(
+              child: Container(
+                key: const ValueKey('cinematic-builder-selection-cursor'),
+            Positioned(
+              child: DecoratedBox(
+                key: const ValueKey(
+                  'cinematic-builder-selection-cursor-handle',
+                ),
+CinematicTimelineTimeBlock? _selectedTimeBlock(
+  CinematicTimelineTimeLayoutReadModel timeLayout,
+  String? selectedStepId,
+)
```

Decision : le hunk reste editor-only. Aucun fichier core n'a ete modifie pour V1-52.

## 4. Hunk tests V1-52

Fichier : `packages/map_editor/test/cinematic_builder_workspace_test.dart`

```diff
+  testWidgets(
+      'shows a non-interactive selection cursor on selected block start',
+      (tester) async {
+    expect(find.textContaining('Sélection :'), findsNothing);
+    expect(
+      find.byKey(const ValueKey('cinematic-builder-selection-cursor')),
+      findsNothing,
+    );
+    await tester.tapAt(Offset(faceTapRect.left + 16, faceTapRect.top + 12));
+    expect(find.text('Sélection : 500 ms'), findsOneWidget);
+    expect(
+      find.byKey(const ValueKey('cinematic-builder-selection-cursor-handle')),
+      findsOneWidget,
+    );
+    expect(faceCursorRect.center.dx, closeTo(faceCardRect.left, 1));
+    await tester.tapAt(Offset(moveTapRect.left + 16, moveTapRect.top + 12));
+    expect(find.text('Sélection : 1.1 s'), findsOneWidget);
+    expect(moveCursorRect.center.dx, closeTo(moveCardRect.left, 1));
+    await tester.tapAt(Offset(axisRect.left + 24, axisRect.center.dy));
+    expect(selectedMoveCard.selected, isTrue);
+    expect(find.text('Sélection : 1.1 s'), findsOneWidget);
+    expect(find.text('Playback'), findsNothing);
+    expect(find.text('Lecture'), findsNothing);
+    expect(find.text('Scrubber'), findsNothing);
+    expect(project.toJson(), before);
+  });
+  testWidgets('captures V1-52 timeline selection cursor when requested',
+      (tester) async {
+    if (!const bool.fromEnvironment(
+      'NS_SCENES_V1_52_CAPTURE_CINEMATIC_TIMELINE_SELECTION_CURSOR',
+    )) {
+      return;
+    }
+    await expectLater(
+      find.byKey(const ValueKey('cinematic-builder-workspace')),
+      matchesGoldenFile(screenshotFile.absolute.path),
+    );
+  });
```

## 5. Tests et analyses

Commande : `cd packages/map_core && dart test test/cinematic_timeline_time_layout_read_model_test.dart`

```text
00:00 +4: All tests passed!
```

Commande : `cd packages/map_core && dart test test/cinematic_timeline_lane_read_model_test.dart`

```text
00:00 +2: All tests passed!
```

Commande : `cd packages/map_core && dart analyze`

```text
Analyzing map_core...
No issues found!
```

Commande : `cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart`

```text
00:04 +28: All tests passed!
```

Commande : `cd packages/map_editor && flutter test --reporter=compact test/cinematics_library_workspace_test.dart`

```text
00:03 +10: All tests passed!
```

Commande : `cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart test/cinematic_builder_workspace_test.dart test/cinematics_library_workspace_test.dart`

```text
Analyzing 3 items...
No issues found! (ran in 1.1s)
```

Commande Visual Gate :

```text
cd packages/map_editor
flutter test --update-goldens --dart-define=NS_SCENES_V1_52_CAPTURE_CINEMATIC_TIMELINE_SELECTION_CURSOR=true --reporter=compact test/cinematic_builder_workspace_test.dart
```

Resultat :

```text
00:08 +28: All tests passed!
```

## 6. Visual Gate

Commandes :

```text
ls -l reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_52_cinematic_timeline_selection_cursor_playhead_placeholder_v0.png
```

```text
-rw-r--r--  1 karim  staff  242647 Jun  2 13:36 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_52_cinematic_timeline_selection_cursor_playhead_placeholder_v0.png
```

```text
file reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_52_cinematic_timeline_selection_cursor_playhead_placeholder_v0.png
```

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_52_cinematic_timeline_selection_cursor_playhead_placeholder_v0.png: PNG image data, 1663 x 926, 8-bit/color RGBA, non-interlaced
```

```text
shasum reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_52_cinematic_timeline_selection_cursor_playhead_placeholder_v0.png
```

```text
d9c7d17554a2023876f945cb153a89e85881046d  reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_52_cinematic_timeline_selection_cursor_playhead_placeholder_v0.png
```

```text
shasum -a 256 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_52_cinematic_timeline_selection_cursor_playhead_placeholder_v0.png
```

```text
a7b0a8b6b99e616f14d516f5e07f9262b40703f15edcd7077bea8ecc0cada72b  reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_52_cinematic_timeline_selection_cursor_playhead_placeholder_v0.png
```

## 7. Checks anti-scope

Commande : `git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle examples`

```text
```

Commande anti-runtime code :

```text
rg -n "PlayableMapGame|SceneRuntimeExecutor|SceneEventRuntimeHook|SceneCinematicRuntimeAwaitableAdapter|SceneCinematicRuntimeNoVisualPlayer|playCinematic" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/test/cinematic_builder_workspace_test.dart
```

Resultat : sortie vide.

Commande anti-playback/seek code :

```text
rg -n "startPlayback|stopPlayback|pausePlayback|resumePlayback|seek|scrub|scrubber|runtimePreview|previewRuntime|playCinematic|PlaybackController|Timer\(|Ticker" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/test/cinematic_builder_workspace_test.dart
```

Resultat : sortie vide.

Commande anti-drag cursor / timeline editor :

```text
rg -n "Draggable|LongPressDraggable|DragTarget|onHorizontalDrag|onPanUpdate|onScaleUpdate|gesture.*timeline|drag.*cursor|drag.*playhead|resize|reorder|moveUp|moveDown|keyframe|overlap" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/test/cinematic_builder_workspace_test.dart
```

Resultat :

```text
packages/map_editor/test/cinematic_builder_workspace_test.dart:145:    expect(find.text('resize'), findsNothing);
```

Interpretation : assertion historique de non-resize, pas une capability ajoutee.

Commande anti-couleurs :

```text
rg -n "Color\(|Colors\.|0xFF|0xff" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/test/cinematic_builder_workspace_test.dart
```

Resultat : sortie vide.

Commande anti-Selbrume code :

```text
rg -n "selbrume|mael|maël|lysa|port_brisants|bourg_selbrume|phare|brume|marais" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/test/cinematic_builder_workspace_test.dart
```

Resultat : sortie vide.

Commande anti-persistance temporelle :

```text
rg -n "cursorTimeMs|playheadTimeMs|currentTimeMs|timelineLayout|laneLayout" packages/map_core/lib/src/models packages/map_core/lib/src/authoring packages/map_core/lib/src/diagnostics packages/map_editor/lib/src/ui/canvas/cinematics
```

Resultat : sortie vide.

Commande `startMs/endMs` dans les zones sensibles :

```text
rg -n "startMs|endMs" packages/map_core/lib/src/models packages/map_core/lib/src/authoring packages/map_core/lib/src/diagnostics packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
```

Resultat :

```text
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:1463:                      'Sélection : ${_shortTimeLabel(selectedBlock.startMs)}',
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:1566:                                  selectedBlock!.startMs,
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:1851:                    left: block.startMs * pixelsPerMs,
```

Interpretation : usage UI derive uniquement ; aucun modele JSON, authoring ou diagnostic ne persiste ces valeurs.

## 8. Auto-review obligatoire

1. Est-ce que V1-52 a modifie `map_runtime` ? Non.
2. Est-ce que V1-52 a modifie `map_gameplay`/`map_battle`/`examples` ? Non.
3. Est-ce que V1-52 a modifie le modele JSON ? Non.
4. Est-ce que V1-52 a lance build_runner ? Non.
5. Est-ce que V1-52 a persiste `cursorTimeMs`/`playheadTimeMs` ? Non.
6. Est-ce que V1-52 a ajoute un playhead interactif ? Non.
7. Est-ce que V1-52 a ajoute un scrubber ? Non.
8. Est-ce que V1-52 a ajoute du seek ? Non.
9. Est-ce que V1-52 a ajoute un timer/playback ? Non.
10. Est-ce que V1-52 a ajoute des transport controls fonctionnels ? Non.
11. Est-ce que V1-52 a ajoute du drag/drop ? Non.
12. Est-ce que V1-52 a ajoute du resize ? Non.
13. Est-ce que V1-52 a ajoute du reordonnancement ? Non.
14. Est-ce que le curseur est derive depuis `selectedStepId + startMs` ? Oui.
15. Est-ce que l'inspecteur reste synchronise ? Oui, tests Builder relances.
16. Est-ce que la preview sandbox reste non runtime ? Oui.
17. Est-ce que Wait/Fade/Camera restent fonctionnels ? Oui, suite Builder.
18. Est-ce que ActorFace reste fonctionnel ? Oui, suite Builder.
19. Est-ce que ActorMove reste fonctionnel ? Oui, suite Builder.
20. Est-ce que les labels cible V1-50 restent fonctionnels ? Oui, suite Builder et Library.
21. Est-ce que le bar layout V1-51 reste fonctionnel ? Oui, tests V1-51 relances dans Builder.
22. Est-ce que le design system est respecte ? Oui, aucune couleur hardcodee dans les fichiers UI modifies.
23. Est-ce que la Visual Gate prouve le curseur ? Oui, screenshot 1663x926 avec badge et aiguille.
24. Est-ce que l'Evidence Pack est complet sans placeholders ? Oui.
25. Quel est le prochain lot exact recommande ? `NS-SCENES-V1-53 — Cinematic Timeline Transport Controls Placeholder V0`.

## 9. Statut final Git

Commande : `git diff --check`

```text
```

Commande : `git diff --stat`

```text
 .../cinematics/cinematic_builder_workspace.dart    | 127 ++++++++++++++++++---
 .../test/cinematic_builder_workspace_test.dart     | 107 +++++++++++++++++
 .../scenes/road_map_scene_builder_authoring.md     |  17 ++-
 reports/narrativeStudio/scenes/road_map_scenes.md  |  21 +++-
 4 files changed, 253 insertions(+), 19 deletions(-)
```

Note : `git diff --stat` ne liste pas les fichiers non suivis V1-52. Ils apparaissent dans le statut final ci-dessous.

Commande : `git diff --name-only`

```text
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

Commande : `git status --short --untracked-files=all`

```text
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
 M packages/map_editor/test/cinematic_builder_workspace_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_52_cinematic_timeline_selection_cursor_playhead_placeholder_v0.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_52_evidence_pack.md
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_52_cinematic_timeline_selection_cursor_playhead_placeholder_v0.png
```
