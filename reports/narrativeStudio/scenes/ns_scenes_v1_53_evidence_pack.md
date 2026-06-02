# NS-SCENES-V1-53 — Evidence Pack

## 1. Gate 0

Commande : `pwd`

```text
/Users/karim/Project/pokemonProject
```

Commande : `git branch --show-current`

```text
main
```

Commande : `git status --short --untracked-files=all` avant edits V1-53

```text
```

Commande : `git diff --stat` avant edits V1-53

```text
```

Commande : `git diff --name-only` avant edits V1-53

```text
```

Commande : `git log --oneline -n 15` avant edits V1-53

```text
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
2805560d feat(narrative): add cinematic timeline read-only step inspector evidence closure (NS-SCENES-V1-43-BIS)
6c3b1074 feat(narrative): add cinematic timeline read-only step inspector v0 (NS-SCENES-V1-43)
e95290ce feat(narrative): add cinematic builder v0 shell evidence closure (NS-SCENES-V1-42-BIS)
c9d44fc8 feat(narrative): add cinematic builder v0 shell (NS-SCENES-V1-42)
38f09efa feat(narrative): add cinematic builder v0 scope and runtime playback contract (NS-SCENES-V1-41)
```

## 2. TDD RED / GREEN

Premier essai RED invalide par erreur de test :

```text
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'shows disabled transport placeholders without changing selection'
```

Resultat :

```text
test/cinematic_builder_workspace_test.dart:281:39: Error: No named parameter with the name 'warnIfMissed'.
      await tester.tapAt(rect.center, warnIfMissed: false);
                                      ^^^^^^^^^^^^
```

Correction : retrait de `warnIfMissed`, non supporte par `tapAt` dans cette version Flutter.

RED valide apres correction :

```text
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'shows disabled transport placeholders without changing selection'
```

Resultat :

```text
Expected: exactly one matching candidate
  Actual: _KeyWidgetFinder:<Found 0 widgets with key [<'cinematic-builder-transport-controls'>]: []>
   Which: means none were found but one was expected
```

GREEN cible apres implementation :

```text
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'shows disabled transport placeholders without changing selection'
```

Resultat :

```text
00:02 +1: All tests passed!
```

## 3. Hunk production V1-53

Fichier : `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`

```diff
@@ -1478,6 +1478,8 @@ class _TimelinePlaceholder extends StatelessWidget {
                     onStepSelected: onStepSelected,
                   ),
           ),
+          const SizedBox(height: 10),
+          const _TimelineTransportControlsPlaceholder(),
         ],
       ),
     );
@@ -1793,6 +1795,103 @@ class _TimelineSelectionCursor extends StatelessWidget {
   }
 }
 
+class _TimelineTransportControlsPlaceholder extends StatelessWidget {
+  const _TimelineTransportControlsPlaceholder();
+
+  @override
+  Widget build(BuildContext context) {
+    return Semantics(
+      label: 'Contrôles de lecture à venir',
+      child: const Column(
+        key: ValueKey('cinematic-builder-transport-controls'),
+        mainAxisSize: MainAxisSize.min,
+        children: [
+          PokeMapBadge(
+            label: 'Contrôles de lecture à venir',
+            variant: PokeMapBadgeVariant.neutral,
+          ),
+          SizedBox(height: 8),
+          Wrap(
+            alignment: WrapAlignment.center,
+            spacing: 18,
+            runSpacing: 8,
+            children: [
+              _TimelineTransportAction(
+                buttonKey: ValueKey(
+                  'cinematic-builder-transport-reset-button',
+                ),
+                icon: CupertinoIcons.arrow_counterclockwise,
+                label: 'Reset',
+              ),
+              _TimelineTransportAction(
+                buttonKey: ValueKey(
+                  'cinematic-builder-transport-play-button',
+                ),
+                icon: CupertinoIcons.play_fill,
+                label: 'Play',
+              ),
+              _TimelineTransportAction(
+                buttonKey: ValueKey(
+                  'cinematic-builder-transport-stop-button',
+                ),
+                icon: CupertinoIcons.stop_fill,
+                label: 'Stop',
+              ),
+            ],
+          ),
+        ],
+      ),
+    );
+  }
+}
+
+class _TimelineTransportAction extends StatelessWidget {
+  const _TimelineTransportAction({
+    required this.buttonKey,
+    required this.icon,
+    required this.label,
+  });
+
+  final Key buttonKey;
+  final IconData icon;
+  final String label;
+
+  @override
+  Widget build(BuildContext context) {
+    final colors = context.pokeMapColors;
+    return Tooltip(
+      message: '$label indisponible dans ce lot',
+      child: Column(
+        mainAxisSize: MainAxisSize.min,
+        children: [
+          SizedBox(
+            width: 92,
+            child: PokeMapButton(
+              key: buttonKey,
+              onPressed: null,
+              variant: PokeMapButtonVariant.secondary,
+              size: PokeMapButtonSize.large,
+              leading: Icon(icon),
+              child: const SizedBox.shrink(),
+            ),
+          ),
+          const SizedBox(height: 4),
+          Text(
+            label,
+            maxLines: 1,
+            overflow: TextOverflow.ellipsis,
+            style: DefaultTextStyle.of(context).style.copyWith(
+                  color: colors.textSecondary,
+                  fontSize: 11,
+                  fontWeight: FontWeight.w800,
+                ),
+          ),
+        ],
+      ),
+    );
+  }
+}
```

## 4. Hunk tests V1-53

Fichier : `packages/map_editor/test/cinematic_builder_workspace_test.dart`

```diff
@@ -217,6 +217,88 @@ void main() {
     expect(project.toJson(), before);
   });
 
+  testWidgets(
+      'shows disabled transport placeholders without changing selection',
+      (tester) async {
+    _setLargeSurface(tester, _referenceTimelineSurfaceSize);
+    final project = _project(cinematics: [_timeLayoutCinematic()]);
+    final before = project.toJson();
+    var projectChangeCount = 0;
+    await _pumpBuilderHarness(
+      tester,
+      project,
+      'cinematic_time_layout',
+      surfaceSize: _referenceTimelineSurfaceSize,
+      onProjectChanged: (_) => projectChangeCount += 1,
+    );
+
+    final faceTapRect = tester.getRect(
+      find.byKey(const ValueKey('cinematic-builder-time-block-step_face')),
+    );
+    await tester.tapAt(Offset(faceTapRect.left + 16, faceTapRect.top + 12));
+    await tester.pumpAndSettle();
+
+    expect(find.text('Sélection : 500 ms'), findsOneWidget);
+    expect(
+      find.byKey(const ValueKey('cinematic-builder-transport-controls')),
+      findsOneWidget,
+    );
+    expect(find.text('Contrôles de lecture à venir'), findsOneWidget);
+    expect(find.text('Reset'), findsOneWidget);
+    expect(find.text('Play'), findsOneWidget);
+    expect(find.text('Stop'), findsOneWidget);
+
+    for (final key in <String>[
+      'cinematic-builder-transport-reset-button',
+      'cinematic-builder-transport-play-button',
+      'cinematic-builder-transport-stop-button',
+    ]) {
+      final button = tester.widget<PokeMapButton>(
+        find.byKey(ValueKey<String>(key)),
+      );
+      expect(button.onPressed, isNull);
+    }
+
+    final cursorBefore = tester.getRect(
+      find.byKey(const ValueKey('cinematic-builder-selection-cursor')),
+    );
+    final resetRect = tester.getRect(
+      find.byKey(
+        const ValueKey('cinematic-builder-transport-reset-button'),
+      ),
+    );
+    final playRect = tester.getRect(
+      find.byKey(
+        const ValueKey('cinematic-builder-transport-play-button'),
+      ),
+    );
+    final stopRect = tester.getRect(
+      find.byKey(
+        const ValueKey('cinematic-builder-transport-stop-button'),
+      ),
+    );
+    for (final rect in [resetRect, playRect, stopRect]) {
+      await tester.tapAt(rect.center);
+      await tester.pumpAndSettle();
+    }
+
+    final selectedFaceCard = tester.widget<PokeMapCard>(
+      find.byKey(const ValueKey('cinematic-builder-step-card-step_face')),
+    );
+    final cursorAfter = tester.getRect(
+      find.byKey(const ValueKey('cinematic-builder-selection-cursor')),
+    );
+    expect(selectedFaceCard.selected, isTrue);
+    expect(find.text('Sélection : 500 ms'), findsOneWidget);
+    expect(cursorAfter.left, closeTo(cursorBefore.left, 1));
+    expect(projectChangeCount, 0);
+    expect(project.toJson(), before);
+    expect(find.text('Lecture en cours'), findsNothing);
+    expect(find.text('Playing'), findsNothing);
+    expect(find.text('Scrubber'), findsNothing);
+    expect(find.text('Seek'), findsNothing);
+  });
```

```diff
@@ -1425,6 +1507,43 @@ void main() {
 
     expect(screenshotFile.existsSync(), isTrue);
   });
+
+  testWidgets(
+      'captures V1-53 timeline transport controls placeholder when requested',
+      (tester) async {
+    if (!const bool.fromEnvironment(
+      'NS_SCENES_V1_53_CAPTURE_CINEMATIC_TIMELINE_TRANSPORT_CONTROLS',
+    )) {
+      return;
+    }
+
+    _setLargeSurface(tester, _referenceTimelineSurfaceSize);
+    await _loadScreenshotFonts();
+    await _pumpBuilderHarness(
+      tester,
+      _project(cinematics: [_timeLayoutCinematic()]),
+      'cinematic_time_layout',
+      surfaceSize: _referenceTimelineSurfaceSize,
+    );
+    final faceRect = tester.getRect(
+      find.byKey(const ValueKey('cinematic-builder-time-block-step_face')),
+    );
+    await tester.tapAt(Offset(faceRect.left + 16, faceRect.top + 16));
+    await tester.pumpAndSettle();
+
+    final screenshotFile = File(
+      '../../reports/narrativeStudio/scenes/screenshots/'
+      'ns_scenes_v1_53_cinematic_timeline_transport_controls_'
+      'placeholder_v0.png',
+    );
+    screenshotFile.parent.createSync(recursive: true);
+    await expectLater(
+      find.byKey(const ValueKey('cinematic-builder-workspace')),
+      matchesGoldenFile(screenshotFile.absolute.path),
+    );
+
+    expect(screenshotFile.existsSync(), isTrue);
+  });
 }
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
00:06 +30: All tests passed!
```

Commande : `cd packages/map_editor && flutter test --reporter=compact test/cinematics_library_workspace_test.dart`

```text
00:03 +10: All tests passed!
```

Commande Visual Gate :

```text
cd packages/map_editor
flutter test --update-goldens --dart-define=NS_SCENES_V1_53_CAPTURE_CINEMATIC_TIMELINE_TRANSPORT_CONTROLS=true --reporter=compact test/cinematic_builder_workspace_test.dart
```

Resultat :

```text
00:05 +30: All tests passed!
```

Commande : `cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart test/cinematic_builder_workspace_test.dart test/cinematics_library_workspace_test.dart`

```text
Analyzing 3 items...
No issues found! (ran in 1.2s)
```

Incident relance Library :

```text
Failed to change install names in LocalFile: '/Users/karim/Project/pokemonProject/packages/map_editor/build/native_assets/macos/objective_c.dylib':
id -> /Users/karim/Project/pokemonProject/packages/map_editor/build/native_assets/macos/objective_c.dylib
dependencies -> /Users/karim/Project/pokemonProject/packages/map_editor/build/native_assets/macos/objective_c.dylib
error: /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/install_name_tool: can't open file: /Users/karim/Project/pokemonProject/packages/map_editor/build/native_assets/macos/objective_c.dylib (No such file or directory)
```

Contexte : cette erreur est apparue lors d'un lancement parallele de deux commandes Flutter. La commande Library a ete relancee seule et a passe `+10`.

## 6. Visual Gate

Commandes :

```text
ls -l reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_53_cinematic_timeline_transport_controls_placeholder_v0.png
```

```text
-rw-r--r--  1 karim  staff  233106 Jun  2 14:11 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_53_cinematic_timeline_transport_controls_placeholder_v0.png
```

```text
file reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_53_cinematic_timeline_transport_controls_placeholder_v0.png
```

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_53_cinematic_timeline_transport_controls_placeholder_v0.png: PNG image data, 1663 x 926, 8-bit/color RGBA, non-interlaced
```

```text
shasum reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_53_cinematic_timeline_transport_controls_placeholder_v0.png
```

```text
51ce0a05a501ba129fada044aec8d33a56a4b8e3  reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_53_cinematic_timeline_transport_controls_placeholder_v0.png
```

```text
shasum -a 256 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_53_cinematic_timeline_transport_controls_placeholder_v0.png
```

```text
c9b40a137c5c2ce2947374cad4f62bf61d9e205618bc1c170ceaafb597fc6d33  reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_53_cinematic_timeline_transport_controls_placeholder_v0.png
```

## 7. Checks anti-scope

Commande : `git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle examples`

```text
```

Commande :

```text
rg -n "PlayableMapGame|SceneRuntimeExecutor|SceneEventRuntimeHook|SceneCinematicRuntimeAwaitableAdapter|SceneCinematicRuntimeNoVisualPlayer|playCinematic" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/test/cinematic_builder_workspace_test.dart || true
```

```text
```

Commande :

```text
rg -n "startPlayback|stopPlayback|pausePlayback|resumePlayback|seek|scrub|scrubber|runtimePreview|previewRuntime|playCinematic|PlaybackController|Timer\(|Ticker|AnimationController|isPlaying|currentTimeMs|playbackTimeMs" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/test/cinematic_builder_workspace_test.dart || true
```

```text
```

Commande :

```text
rg -n "Draggable|LongPressDraggable|DragTarget|onHorizontalDrag|onPanUpdate|onScaleUpdate|gesture.*timeline|drag.*cursor|drag.*playhead|resize|reorder|moveUp|moveDown|keyframe|overlap" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart || true
```

```text
```

Commande :

```text
rg -n "cursorTimeMs|playheadTimeMs|currentTimeMs|playbackTimeMs|timelineLayout|laneLayout|transportState|isPlaying" packages/map_core/lib/src/models packages/map_core/lib/src/authoring packages/map_core/lib/src/diagnostics packages/map_editor/lib/src/ui/canvas/cinematics || true
```

```text
```

Commande :

```text
rg -n "Color\(|Colors\.|0xFF|0xff" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart || true
```

```text
```

Commande :

```text
rg -n "selbrume|mael|maël|lysa|port_brisants|bourg_selbrume|phare|brume|marais" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/test/cinematic_builder_workspace_test.dart || true
```

```text
```

## 8. Diff stat et fichiers modifies avant rapport

Commande : `git diff --stat`

```text
 .../cinematics/cinematic_builder_workspace.dart    |  99 +++++++++++++++++
 .../test/cinematic_builder_workspace_test.dart     | 119 +++++++++++++++++++++
 .../scenes/road_map_scene_builder_authoring.md     |  17 ++-
 reports/narrativeStudio/scenes/road_map_scenes.md  |  21 +++-
 4 files changed, 252 insertions(+), 4 deletions(-)
```

Commande : `git diff --name-only`

```text
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

Commande : `git diff --check`

```text
```

Commande : `git status --short --untracked-files=all` avant creation des rapports V1-53

```text
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
 M packages/map_editor/test/cinematic_builder_workspace_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_53_cinematic_timeline_transport_controls_placeholder_v0.png
```

## 9. Fichiers crees par V1-53

- `reports/narrativeStudio/scenes/ns_scenes_v1_53_cinematic_timeline_transport_controls_placeholder_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_53_evidence_pack.md`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_53_cinematic_timeline_transport_controls_placeholder_v0.png`

## 10. Auto-review critique

- Boutons disabled : oui, `onPressed = null`.
- No-op : non retenu.
- Mutation projet au tap : testee, aucune.
- Selection preservee : testee.
- Curseur preserve : teste.
- Playback/timer/seek/scrubber/runtime : absents des recherches code/test.
- Design system : respecte.
- Visual Gate : produite et verifiee.
- Build runner : non lance.
- Git write : aucune commande Git d'ecriture executee.

## 11. Checks finaux apres creation rapports

Commande : `git diff --check`

```text
```

Commande : `git diff --stat`

```text
 .../cinematics/cinematic_builder_workspace.dart    |  99 +++++++++++++++++
 .../test/cinematic_builder_workspace_test.dart     | 119 +++++++++++++++++++++
 .../scenes/road_map_scene_builder_authoring.md     |  17 ++-
 reports/narrativeStudio/scenes/road_map_scenes.md  |  21 +++-
 4 files changed, 252 insertions(+), 4 deletions(-)
```

Note : `git diff --stat` ne liste pas les fichiers non suivis. Les rapports et la capture V1-53 apparaissent dans `git status`.

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
?? reports/narrativeStudio/scenes/ns_scenes_v1_53_cinematic_timeline_transport_controls_placeholder_v0.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_53_evidence_pack.md
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_53_cinematic_timeline_transport_controls_placeholder_v0.png
```
