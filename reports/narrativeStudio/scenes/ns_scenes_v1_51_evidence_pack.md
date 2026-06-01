# NS-SCENES-V1-51 — Evidence Pack

## 1. Gate 0

Commande : `pwd`  
Resultat :

```text
/Users/karim/Project/pokemonProject
```

Commande : `git branch --show-current`  
Resultat :

```text
main
```

Commande : `git status --short --untracked-files=all` avant edits V1-51  
Resultat :

```text
 M packages/map_core/lib/src/read_models/cinematic_timeline_lane_read_model.dart
 M packages/map_core/test/cinematic_authoring_operations_test.dart
 M packages/map_core/test/cinematic_timeline_lane_read_model_test.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
 M packages/map_editor/test/cinematic_builder_workspace_test.dart
 M packages/map_editor/test/cinematics_library_workspace_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_50_cinematic_actor_movement_inspector_polish_target_labels_v0.md
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_50_cinematic_actor_movement_inspector_polish_target_labels_v0.png
```

Commande : `git diff --stat` avant edits V1-51  
Resultat :

```text
 .../cinematic_timeline_lane_read_model.dart        |  23 +-
 .../test/cinematic_authoring_operations_test.dart  |  61 ++-
 .../cinematic_timeline_lane_read_model_test.dart   |   1 +
 .../cinematics/cinematic_builder_workspace.dart    | 431 +++++++++++++++++++--
 .../cinematics/cinematics_library_workspace.dart   |  18 +
 .../src/ui/canvas/narrative_workspace_canvas.dart  |  54 +++
 .../test/cinematic_builder_workspace_test.dart     | 225 ++++++++++-
 .../test/cinematics_library_workspace_test.dart    |  28 ++
 .../scenes/road_map_scene_builder_authoring.md     |  17 +-
 reports/narrativeStudio/scenes/road_map_scenes.md  |  23 +-
 10 files changed, 843 insertions(+), 38 deletions(-)
```

Commande : `git diff --name-only` avant edits V1-51  
Resultat :

```text
packages/map_core/lib/src/read_models/cinematic_timeline_lane_read_model.dart
packages/map_core/test/cinematic_authoring_operations_test.dart
packages/map_core/test/cinematic_timeline_lane_read_model_test.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
packages/map_editor/test/cinematics_library_workspace_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

Commande : `git log --oneline -n 15` avant edits V1-51  
Resultat :

```text
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
b39d596f feat(narrative): add cinematic runtime adapter v0 (NS-SCENES-V1-40)
```

## 2. TDD RED

RED core execute avant implementation :

```text
cd packages/map_core
dart test test/cinematic_timeline_time_layout_read_model_test.dart
```

Resultat observe : echec attendu, symboles absents pour `buildCinematicTimelineTimeLayoutReadModel`, `CinematicTimelineVisualDurationSource` et `cinematicTimelineFallbackVisualDurationMs`.

RED editor execute avant implementation :

```text
cd packages/map_editor
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
```

Resultat observe : echec attendu, le sous-titre `Projection temporelle derivee du deroule lineaire` et le bar layout n'existaient pas encore.

## 2.1 Ajustement proportionnel demande par l'utilisateur

Apres la premiere cloture V1-51, l'utilisateur a explicitement demande de reduire la taille de l'`Apercu sandbox` et d'augmenter la taille de la timeline pour se rapprocher de l'image de reference fournie.

TDD RED cible execute avant ajustement de hauteur :

```text
cd packages/map_editor
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'balances sandbox preview and timeline proportions on reference'
```

Resultat observe : echec attendu, `timelineRect.height` valait `300.0` alors que le test demandait `>= 360`.

Ajustement implemente :

- timeline fixe portee de 300 px a 390 px ;
- preview sandbox conservee en `Expanded`, donc reduite par la timeline agrandie ;
- header du Builder rendu responsive sous 1300 px pour supprimer l'overflow detecte par la suite complete ;
- capture V1-51 regeneree.

## 3. Nouveau fichier core

Fichier : `packages/map_core/lib/src/read_models/cinematic_timeline_time_layout_read_model.dart`

```dart
import 'package:meta/meta.dart' show immutable;

import '../models/cinematic_asset.dart';
import 'cinematic_timeline_lane_read_model.dart';

const cinematicTimelineFallbackVisualDurationMs = 300;

enum CinematicTimelineVisualDurationSource {
  explicit,
  fallback,
}

@immutable
final class CinematicTimelineTimeLayoutReadModel {
  CinematicTimelineTimeLayoutReadModel({
    required List<CinematicTimelineTimeLane> lanes,
    required List<CinematicTimelineTimeBlock> blocks,
    required List<CinematicTimelineTimeTick> ticks,
    required this.totalDurationMs,
    required this.stepCount,
  })  : lanes = List<CinematicTimelineTimeLane>.unmodifiable(lanes),
        blocks = List<CinematicTimelineTimeBlock>.unmodifiable(blocks),
        ticks = List<CinematicTimelineTimeTick>.unmodifiable(ticks);

  final List<CinematicTimelineTimeLane> lanes;
  final List<CinematicTimelineTimeBlock> blocks;
  final List<CinematicTimelineTimeTick> ticks;
  final int totalDurationMs;
  final int stepCount;

  int get laneCount => lanes.length;
  bool get isEmpty => stepCount == 0;

  CinematicTimelineTimeLane? laneById(String laneId) {
    for (final lane in lanes) {
      if (lane.laneId == laneId) {
        return lane;
      }
    }
    return null;
  }
}

@immutable
final class CinematicTimelineTimeLane {
  CinematicTimelineTimeLane({
    required this.laneId,
    required this.laneKind,
    required this.label,
    required this.sortOrder,
    this.actorId,
    this.actorLabel,
    required List<CinematicTimelineTimeBlock> blocks,
  }) : blocks = List<CinematicTimelineTimeBlock>.unmodifiable(blocks);

  final String laneId;
  final CinematicTimelineLaneKind laneKind;
  final String label;
  final int sortOrder;
  final String? actorId;
  final String? actorLabel;
  final List<CinematicTimelineTimeBlock> blocks;

  bool get isEmpty => blocks.isEmpty;
}

@immutable
final class CinematicTimelineTimeBlock {
  CinematicTimelineTimeBlock({
    required this.stepId,
    required this.stepIndex,
    required this.laneId,
    required this.kind,
    required this.label,
    required this.startMs,
    required this.endMs,
    this.durationMs,
    required this.visualDurationMs,
    required this.durationSource,
    this.actorId,
    this.actorLabel,
    this.targetId,
    this.targetLabel,
    required this.isAuthoringOwned,
    required List<String> badges,
  }) : badges = List<String>.unmodifiable(badges);

  final String stepId;
  final int stepIndex;
  final String laneId;
  final CinematicTimelineStepKind kind;
  final String label;
  final int startMs;
  final int endMs;
  final int? durationMs;
  final int visualDurationMs;
  final CinematicTimelineVisualDurationSource durationSource;
  final String? actorId;
  final String? actorLabel;
  final String? targetId;
  final String? targetLabel;
  final bool isAuthoringOwned;
  final List<String> badges;
}

@immutable
final class CinematicTimelineTimeTick {
  const CinematicTimelineTimeTick({
    required this.timeMs,
    required this.label,
    required this.isMajor,
  });

  final int timeMs;
  final String label;
  final bool isMajor;
}

CinematicTimelineTimeLayoutReadModel buildCinematicTimelineTimeLayoutReadModel(
  CinematicAsset cinematic,
) {
  final laneReadModel = buildCinematicTimelineLaneReadModel(cinematic);
  final timings = <String, _StepTiming>{};

  var currentMs = 0;
  for (final entry in cinematic.timeline.steps.asMap().entries) {
    final step = entry.value;
    final visualDurationMs = _visualDurationMs(step.durationMs);
    final durationSource = _durationSource(step.durationMs);
    final startMs = currentMs;
    final endMs = startMs + visualDurationMs;
    timings[step.id] = _StepTiming(
      startMs: startMs,
      endMs: endMs,
      visualDurationMs: visualDurationMs,
      durationSource: durationSource,
    );
    currentMs = endMs;
  }

  final timeLanes = [
    for (final lane in laneReadModel.lanes)
      CinematicTimelineTimeLane(
        laneId: lane.laneId,
        laneKind: lane.laneKind,
        label: lane.label,
        sortOrder: lane.sortOrder,
        actorId: lane.actorId,
        actorLabel: lane.actorLabel,
        blocks: [
          for (final step in lane.steps)
            if (timings[step.stepId] case final timing?)
              CinematicTimelineTimeBlock(
                stepId: step.stepId,
                stepIndex: step.stepIndex,
                laneId: lane.laneId,
                kind: step.kind,
                label: step.label,
                startMs: timing.startMs,
                endMs: timing.endMs,
                durationMs: step.durationMs,
                visualDurationMs: timing.visualDurationMs,
                durationSource: timing.durationSource,
                actorId: step.actorId,
                actorLabel: step.actorLabel,
                targetId: step.targetId,
                targetLabel: step.targetLabel,
                isAuthoringOwned: step.isAuthoringOwned,
                badges: step.badges,
              ),
        ],
      ),
  ];

  final blocks = [
    for (final lane in timeLanes) ...lane.blocks,
  ]..sort((a, b) => a.stepIndex.compareTo(b.stepIndex));

  return CinematicTimelineTimeLayoutReadModel(
    lanes: timeLanes,
    blocks: blocks,
    ticks: _ticksForTotalDuration(currentMs),
    totalDurationMs: currentMs,
    stepCount: cinematic.timeline.steps.length,
  );
}

int _visualDurationMs(int? durationMs) {
  if (durationMs != null && durationMs > 0) {
    return durationMs;
  }
  return cinematicTimelineFallbackVisualDurationMs;
}

CinematicTimelineVisualDurationSource _durationSource(int? durationMs) {
  if (durationMs != null && durationMs > 0) {
    return CinematicTimelineVisualDurationSource.explicit;
  }
  return CinematicTimelineVisualDurationSource.fallback;
}

List<CinematicTimelineTimeTick> _ticksForTotalDuration(int totalDurationMs) {
  if (totalDurationMs <= 0) {
    return const [
      CinematicTimelineTimeTick(timeMs: 0, label: '0 ms', isMajor: true),
    ];
  }

  final intervalMs = _tickIntervalMs(totalDurationMs);
  final times = <int>[];
  for (var timeMs = 0; timeMs <= totalDurationMs; timeMs += intervalMs) {
    times.add(timeMs);
  }
  if (times.last != totalDurationMs) {
    times.add(totalDurationMs);
  }

  return [
    for (final timeMs in times)
      CinematicTimelineTimeTick(
        timeMs: timeMs,
        label: _formatTickLabel(timeMs),
        isMajor: true,
      ),
  ];
}

int _tickIntervalMs(int totalDurationMs) {
  if (totalDurationMs <= 3000) {
    return 500;
  }
  if (totalDurationMs <= 10000) {
    return 1000;
  }
  if (totalDurationMs <= 30000) {
    return 5000;
  }
  return 10000;
}

String _formatTickLabel(int timeMs) {
  if (timeMs < 1000) {
    return '$timeMs ms';
  }
  if (timeMs % 1000 == 0) {
    return '${timeMs ~/ 1000} s';
  }
  final decimals = timeMs % 100 == 0 ? 1 : 2;
  var seconds = (timeMs / 1000).toStringAsFixed(decimals);
  while (seconds.endsWith('0')) {
    seconds = seconds.substring(0, seconds.length - 1);
  }
  if (seconds.endsWith('.')) {
    seconds = seconds.substring(0, seconds.length - 1);
  }
  return '$seconds s';
}

final class _StepTiming {
  const _StepTiming({
    required this.startMs,
    required this.endMs,
    required this.visualDurationMs,
    required this.durationSource,
  });

  final int startMs;
  final int endMs;
  final int visualDurationMs;
  final CinematicTimelineVisualDurationSource durationSource;
}
```

## 4. Export public

Hunk `packages/map_core/lib/map_core.dart` :

```diff
 export 'src/read_models/cinematics_library_read_model.dart';
 export 'src/read_models/cinematic_timeline_lane_read_model.dart';
+export 'src/read_models/cinematic_timeline_time_layout_read_model.dart';
 export 'src/read_models/storyline_scene_links_read_model.dart';
```

## 5. Nouveau test core

Fichier : `packages/map_core/test/cinematic_timeline_time_layout_read_model_test.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('buildCinematicTimelineTimeLayoutReadModel', () {
    test('derives block timing from linear order with fallback durations', () {
      final cinematic = _cinematic();
      final before = cinematic.toJson();

      final readModel = buildCinematicTimelineTimeLayoutReadModel(cinematic);
      final secondReadModel =
          buildCinematicTimelineTimeLayoutReadModel(cinematic);

      expect(cinematic.toJson(), before);
      expect(readModel.stepCount, 5);
      expect(readModel.laneCount, 8);
      expect(readModel.totalDurationMs, 2900);
      expect(
        readModel.ticks.map((tick) => tick.label),
        ['0 ms', '500 ms', '1 s', '1.5 s', '2 s', '2.5 s', '2.9 s'],
      );
      expect(
        secondReadModel.blocks.map((block) => block.stepId),
        readModel.blocks.map((block) => block.stepId),
      );

      expect(
        readModel.blocks.map((block) => (
              block.stepId,
              block.stepIndex,
              block.startMs,
              block.endMs,
              block.visualDurationMs,
              block.durationSource,
              block.laneId,
            )),
        [
          (
            'step_camera',
            0,
            0,
            500,
            500,
            CinematicTimelineVisualDurationSource.explicit,
            'camera',
          ),
          (
            'step_face',
            1,
            500,
            800,
            cinematicTimelineFallbackVisualDurationMs,
            CinematicTimelineVisualDurationSource.fallback,
            'actor:actor_professor',
          ),
          (
            'step_wait',
            2,
            800,
            1100,
            cinematicTimelineFallbackVisualDurationMs,
            CinematicTimelineVisualDurationSource.fallback,
            'time-global',
          ),
          (
            'step_move',
            3,
            1100,
            2600,
            1500,
            CinematicTimelineVisualDurationSource.explicit,
            'actor:actor_professor',
          ),
          (
            'step_marker',
            4,
            2600,
            2900,
            cinematicTimelineFallbackVisualDurationMs,
            CinematicTimelineVisualDurationSource.fallback,
            'time-global',
          ),
        ],
      );

      final actorLane = readModel.laneById('actor:actor_professor')!;
      expect(actorLane.actorId, 'actor_professor');
      expect(actorLane.actorLabel, 'Professor');
      expect(actorLane.blocks.map((block) => block.stepId), [
        'step_face',
        'step_move',
      ]);
      expect(actorLane.blocks.last.label, 'Professor → Centre scène');
      expect(actorLane.blocks.last.targetId, 'target_center');
      expect(actorLane.blocks.last.targetLabel, 'Centre scène');
      expect(actorLane.blocks.last.badges, contains('Cible: Centre scène'));
    });

    test('handles empty timelines deterministically', () {
      final cinematic = CinematicAsset(
        id: 'cinematic_empty',
        title: 'Empty cinematic',
        timeline: CinematicTimeline(),
      );

      final readModel = buildCinematicTimelineTimeLayoutReadModel(cinematic);
      final secondReadModel =
          buildCinematicTimelineTimeLayoutReadModel(cinematic);

      expect(readModel.stepCount, 0);
      expect(readModel.totalDurationMs, 0);
      expect(readModel.blocks, isEmpty);
      expect(readModel.laneCount, 7);
      expect(readModel.ticks.map((tick) => tick.label), ['0 ms']);
      expect(secondReadModel.ticks.map((tick) => tick.label), ['0 ms']);
    });

    test('uses coarse ticks for long timelines', () {
      final readModel = buildCinematicTimelineTimeLayoutReadModel(
        CinematicAsset(
          id: 'cinematic_long',
          title: 'Long cinematic',
          timeline: CinematicTimeline(
            steps: [
              CinematicTimelineStep(
                id: 'step_wait_long',
                kind: CinematicTimelineStepKind.wait,
                label: 'Long wait',
                durationMs: 32000,
              ),
            ],
          ),
        ),
      );

      expect(readModel.totalDurationMs, 32000);
      expect(
        readModel.ticks.map((tick) => tick.label),
        ['0 ms', '10 s', '20 s', '30 s', '32 s'],
      );
      expect(readModel.ticks.where((tick) => tick.isMajor), hasLength(5));
    });

    test('keeps unknown actor blocks on derived actor lanes', () {
      final readModel = buildCinematicTimelineTimeLayoutReadModel(
        CinematicAsset(
          id: 'cinematic_unknown_actor',
          title: 'Unknown actor cinematic',
          movementTargets: [
            CinematicMovementTargetRef(
              targetId: 'target_center',
              label: 'Centre scène',
            ),
          ],
          timeline: CinematicTimeline(
            steps: [
              CinematicTimelineStep(
                id: 'step_move_unknown',
                kind: CinematicTimelineStepKind.actorMove,
                label: 'Unknown move',
                actorId: 'actor_missing',
                targetId: 'target_center',
                durationMs: 900,
              ),
            ],
          ),
        ),
      );

      final unknownLane = readModel.laneById('actor:actor_missing')!;

      expect(unknownLane.label, 'Acteur inconnu: actor_missing');
      expect(unknownLane.blocks.single.stepId, 'step_move_unknown');
      expect(unknownLane.blocks.single.actorLabel, 'actor_missing');
      expect(unknownLane.blocks.single.targetLabel, 'Centre scène');
      expect(unknownLane.blocks.single.startMs, 0);
      expect(unknownLane.blocks.single.endMs, 900);
    });
  });
}

CinematicAsset _cinematic() {
  return CinematicAsset(
    id: 'cinematic_time_layout',
    title: 'Time layout cinematic',
    requiredActors: [
      CinematicActorRef(actorId: 'actor_professor', label: 'Professor'),
    ],
    movementTargets: [
      CinematicMovementTargetRef(
        targetId: 'target_center',
        label: 'Centre scène',
      ),
    ],
    timeline: CinematicTimeline(
      steps: [
        CinematicTimelineStep(
          id: 'step_camera',
          kind: CinematicTimelineStepKind.camera,
          label: 'Camera reveal',
          durationMs: 500,
        ),
        CinematicTimelineStep(
          id: 'step_face',
          kind: CinematicTimelineStepKind.actorFace,
          label: 'Professor turns',
          actorId: 'actor_professor',
          metadata: const {
            cinematicTimelineDraftMetadataKindKey:
                cinematicTimelineBasicBlockMetadataKindValue,
            cinematicTimelineDraftMetadataSourceKey:
                cinematicTimelineDraftMetadataSourceValue,
            cinematicTimelineAuthoringBlockMetadataKey:
                cinematicTimelineActorFaceBlockMetadataValue,
            cinematicTimelineActorDirectionMetadataKey: 'right',
          },
        ),
        CinematicTimelineStep(
          id: 'step_wait',
          kind: CinematicTimelineStepKind.wait,
          label: 'Beat',
          durationMs: 0,
        ),
        CinematicTimelineStep(
          id: 'step_move',
          kind: CinematicTimelineStepKind.actorMove,
          label: 'Move Professor',
          actorId: 'actor_professor',
          targetId: 'target_center',
          durationMs: 1500,
          metadata: const {
            cinematicTimelineDraftMetadataKindKey:
                cinematicTimelineBasicBlockMetadataKindValue,
            cinematicTimelineDraftMetadataSourceKey:
                cinematicTimelineDraftMetadataSourceValue,
            cinematicTimelineAuthoringBlockMetadataKey:
                cinematicTimelineActorMoveBlockMetadataValue,
            cinematicTimelineActorMovementModeMetadataKey: 'walk',
            cinematicTimelineActorPathModeMetadataKey: 'direct',
          },
        ),
        CinematicTimelineStep(
          id: 'step_marker',
          kind: CinematicTimelineStepKind.marker,
          label: 'Marker',
          durationMs: -10,
        ),
      ],
    ),
  );
}
```

## 6. Hunk UI principal

Hunks V1-51 dans `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart` :

```diff
+import 'dart:math' as math;
...
+const _timelineLaneHeaderWidth = 154.0;
+const _timelineAxisHeight = 28.0;
+const _timelineLaneRowHeight = 30.0;
+const _timelineBarMinWidth = 96.0;
+const _timelineFallbackPixelsPerMs =
+    _timelineBarMinWidth / cinematicTimelineFallbackVisualDurationMs;
...
+    final timeLayout = buildCinematicTimelineTimeLayoutReadModel(asset);
+    final stepsById = {
+      for (final step in steps) step.id: step,
+    };
...
+                    'Projection temporelle dérivée du déroulé linéaire',
...
+                _TimelineSummaryBadge('${timeLayout.stepCount} step(s)'),
+                _TimelineSummaryBadge(_timelineTotalLabel(
+                  timeLayout.totalDurationMs,
+                )),
+                _TimelineSummaryBadge('${timeLayout.laneCount} piste(s)'),
+                const _TimelineSummaryBadge('Ordre linéaire conservé'),
+                const _TimelineSummaryBadge('Layout temporel dérivé'),
+                if (timeLayout.blocks.any(
+                  (block) =>
+                      block.durationSource ==
+                      CinematicTimelineVisualDurationSource.fallback,
+                ))
+                  const _TimelineSummaryBadge('Fallback visuel'),
...
+              _TimelineTimeGrid(
+                asset: asset,
+                timeLayout: timeLayout,
+                stepsById: stepsById,
+                selectedStepId: selectedStepId,
+                onStepSelected: onStepSelected,
+              ),
```

La UI ajoute les widgets `_TimelineTimeGrid`, `_TimelineLaneHeaderCell`, `_TimelineLaneLabelCell`, `_TimelineAxis`, `_TimelineTrackRow`, `_TimelineStepCard`, `_TimelineBarMetaStrip` et helpers de labels/durees.

## 7. Hunk test editor V1-51

Hunks principaux dans `packages/map_editor/test/cinematic_builder_workspace_test.dart` :

```diff
+const _defaultBuilderSurfaceSize = Size(1280, 860);
+const _referenceTimelineSurfaceSize = Size(1663, 926);
...
+  testWidgets('renders a derived time axis with proportional bars',
+      (tester) async {
+    _setLargeSurface(tester);
+    final project = _project(cinematics: [_timeLayoutCinematic()]);
+    final before = project.toJson();
+    await _pumpBuilder(
+      tester,
+      _entry(project, 'cinematic_time_layout'),
+      asset: _asset(project, 'cinematic_time_layout'),
+    );
+    expect(find.text('Timeline par pistes'), findsOneWidget);
+    expect(find.text('Projection temporelle dérivée du déroulé linéaire'),
+        findsOneWidget);
+    expect(find.text('Layout temporel dérivé'), findsOneWidget);
+    expect(find.text('0 ms'), findsOneWidget);
+    expect(find.text('500 ms'), findsWidgets);
+    expect(find.text('1 s'), findsOneWidget);
+    expect(find.text('1.5 s'), findsOneWidget);
+    final cameraRect = tester.getRect(
+      find.byKey(const ValueKey('cinematic-builder-time-block-step_camera')),
+    );
+    final faceRect = tester.getRect(
+      find.byKey(const ValueKey('cinematic-builder-time-block-step_face')),
+    );
+    final waitRect = tester.getRect(
+      find.byKey(const ValueKey('cinematic-builder-time-block-step_wait')),
+    );
+    final moveRect = tester.getRect(
+      find.byKey(const ValueKey('cinematic-builder-time-block-step_move')),
+    );
+    expect(faceRect.left, greaterThan(cameraRect.left));
+    expect(waitRect.left, greaterThan(faceRect.left));
+    expect(moveRect.left, greaterThan(waitRect.left));
+    expect(moveRect.width, greaterThan(cameraRect.width));
+    expect(cameraRect.width, greaterThan(faceRect.width));
+    await tester.tapAt(Offset(cameraRect.left + 16, cameraRect.top + 16));
+    await tester.pumpAndSettle();
+    final selectedCameraBar = tester.widget<PokeMapCard>(
+      find.byKey(const ValueKey('cinematic-builder-step-card-step_camera')),
+    );
+    expect(selectedCameraBar.selected, isTrue);
+    expect(find.text('Fallback visuel'), findsWidgets);
+    expect(find.text('drag'), findsNothing);
+    expect(find.text('resize'), findsNothing);
+    expect(project.toJson(), before);
+  });
...
+  testWidgets('captures V1-51 timeline time axis bar layout when requested',
+      (tester) async {
+    if (!const bool.fromEnvironment(
+      'NS_SCENES_V1_51_CAPTURE_CINEMATIC_TIMELINE_BAR_LAYOUT',
+    )) {
+      return;
+    }
+    _setLargeSurface(tester, _referenceTimelineSurfaceSize);
+    await _loadScreenshotFonts();
+    await _pumpBuilderHarness(
+      tester,
+      _project(cinematics: [_timeLayoutCinematic()]),
+      'cinematic_time_layout',
+      surfaceSize: _referenceTimelineSurfaceSize,
+    );
+    final cameraRect = tester.getRect(
+      find.byKey(const ValueKey('cinematic-builder-time-block-step_camera')),
+    );
+    await tester.tapAt(Offset(cameraRect.left + 16, cameraRect.top + 16));
+    await tester.pumpAndSettle();
+    final screenshotFile = File(
+      '../../reports/narrativeStudio/scenes/screenshots/'
+      'ns_scenes_v1_51_cinematic_timeline_time_axis_bar_layout_v0.png',
+    );
+    screenshotFile.parent.createSync(recursive: true);
+    await expectLater(
+      find.byKey(const ValueKey('cinematic-builder-workspace')),
+      matchesGoldenFile(screenshotFile.absolute.path),
+    );
+    expect(screenshotFile.existsSync(), isTrue);
+  });
```

## 8. Tests et analyse

Commande : `cd packages/map_core && dart test test/cinematic_timeline_time_layout_read_model_test.dart`

```text
00:00 +0: loading test/cinematic_timeline_time_layout_read_model_test.dart
00:00 +0: buildCinematicTimelineTimeLayoutReadModel derives block timing from linear order with fallback durations
00:00 +1: buildCinematicTimelineTimeLayoutReadModel derives block timing from linear order with fallback durations
00:00 +1: buildCinematicTimelineTimeLayoutReadModel handles empty timelines deterministically
00:00 +2: buildCinematicTimelineTimeLayoutReadModel handles empty timelines deterministically
00:00 +2: buildCinematicTimelineTimeLayoutReadModel uses coarse ticks for long timelines
00:00 +3: buildCinematicTimelineTimeLayoutReadModel uses coarse ticks for long timelines
00:00 +3: buildCinematicTimelineTimeLayoutReadModel keeps unknown actor blocks on derived actor lanes
00:00 +4: buildCinematicTimelineTimeLayoutReadModel keeps unknown actor blocks on derived actor lanes
00:00 +4: All tests passed!
```

Commande : `cd packages/map_core && dart test test/cinematic_timeline_lane_read_model_test.dart`

```text
00:00 +0: loading test/cinematic_timeline_lane_read_model_test.dart
00:00 +0: buildCinematicTimelineLaneReadModel groups timeline steps into deterministic lanes without mutation
00:00 +1: buildCinematicTimelineLaneReadModel groups timeline steps into deterministic lanes without mutation
00:00 +1: buildCinematicTimelineLaneReadModel exposes actorMove target and movement badges on actor lane
00:00 +2: buildCinematicTimelineLaneReadModel exposes actorMove target and movement badges on actor lane
00:00 +2: All tests passed!
```

Commande : `cd packages/map_core && dart test test/cinematics_library_read_model_test.dart`

```text
00:00 +0: loading test/cinematics_library_read_model_test.dart
00:00 +0: buildCinematicsLibraryReadModel lists canonical CinematicAsset and scenario bridges separately
00:00 +1: buildCinematicsLibraryReadModel lists canonical CinematicAsset and scenario bridges separately
00:00 +1: buildCinematicsLibraryReadModel attaches diagnostics and reports empty timeline metrics
00:00 +2: buildCinematicsLibraryReadModel attaches diagnostics and reports empty timeline metrics
00:00 +2: buildCinematicsLibraryReadModel reports canonical, bridge, and unknown Scene references
00:00 +3: buildCinematicsLibraryReadModel reports canonical, bridge, and unknown Scene references
00:00 +3: buildCinematicsLibraryReadModel does not mutate ProjectManifest or import Flutter/runtime packages
00:00 +4: buildCinematicsLibraryReadModel does not mutate ProjectManifest or import Flutter/runtime packages
00:00 +4: All tests passed!
```

Commande : `cd packages/map_core && dart analyze`

```text
Analyzing map_core...
No issues found!
```

Commande : `cd packages/map_editor && flutter test --reporter=compact test/cinematics_library_workspace_test.dart`

```text
00:04 +10: All tests passed!
```

Commande : `cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart`

```text
00:04 +26: All tests passed!
```

Commande cible post-ajustement proportions : `cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'balances sandbox preview and timeline proportions on reference'`

```text
00:01 +1: All tests passed!
```

Commande cible post-correction header responsive : `cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'shows populated read-only cinematic builder shell'`

```text
00:01 +1: All tests passed!
```

Commande : `cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart test/cinematic_builder_workspace_test.dart test/cinematics_library_workspace_test.dart`

```text
Analyzing 3 items...
No issues found! (ran in 1.1s)
```

Commande Visual Gate :

```text
cd packages/map_editor
flutter test --update-goldens --dart-define=NS_SCENES_V1_51_CAPTURE_CINEMATIC_TIMELINE_BAR_LAYOUT=true --reporter=compact test/cinematic_builder_workspace_test.dart
```

Resultat :

```text
00:05 +26: All tests passed!
```

## 9. Visual Gate

Commandes :

```text
ls -l reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_51_cinematic_timeline_time_axis_bar_layout_v0.png
```

```text
-rw-r--r--  1 karim  staff  235780 Jun  2 01:26 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_51_cinematic_timeline_time_axis_bar_layout_v0.png
```

```text
file reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_51_cinematic_timeline_time_axis_bar_layout_v0.png
```

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_51_cinematic_timeline_time_axis_bar_layout_v0.png: PNG image data, 1663 x 926, 8-bit/color RGBA, non-interlaced
```

```text
shasum reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_51_cinematic_timeline_time_axis_bar_layout_v0.png
```

```text
c7abc4442a6ce9ae5a2bdfab7f43d5ae7f3f2ef2  reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_51_cinematic_timeline_time_axis_bar_layout_v0.png
```

```text
shasum -a 256 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_51_cinematic_timeline_time_axis_bar_layout_v0.png
```

```text
f2a4e6446eba9a19080afe5ae5cff1de20ac708059818bf9f1575af7e41c2380  reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_51_cinematic_timeline_time_axis_bar_layout_v0.png
```

## 10. Checks anti-scope

Commande : `git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle examples`  
Resultat : sortie vide.

Commande anti-runtime :

```text
rg -n "PlayableMapGame|SceneRuntimeExecutor|SceneEventRuntimeHook|SceneCinematicRuntimeAwaitableAdapter|SceneCinematicRuntimeNoVisualPlayer|playCinematic" packages/map_core/lib/map_core.dart packages/map_core/lib/src/read_models/cinematic_timeline_time_layout_read_model.dart packages/map_core/test/cinematic_timeline_time_layout_read_model_test.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/test/cinematic_builder_workspace_test.dart
```

Resultat : sortie vide.

Commande anti-couleurs :

```text
rg -n "Color\(|Colors\.|0xFF|0xff" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/test/cinematic_builder_workspace_test.dart
```

Resultat : sortie vide.

Commande anti-Selbrume :

```text
rg -n "selbrume|mael|maël|lysa|port_brisants|bourg_selbrume|phare|brume|marais" packages/map_core/lib/map_core.dart packages/map_core/lib/src/read_models/cinematic_timeline_time_layout_read_model.dart packages/map_core/test/cinematic_timeline_time_layout_read_model_test.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/test/cinematic_builder_workspace_test.dart
```

Resultat : sortie vide.

Commande anti-timeline editor complet :

```text
rg -n "drag|drop|TimelineEditor|scrubber|keyframe|reorder|moveUp|moveDown|resize|overlap|draggable|gesture.*horizontal|pan.*block|copyWith\(.*startMs|copyWith\(.*endMs|copyWith\(.*GameState|PlayableMapGame" packages/map_core/lib/map_core.dart packages/map_core/lib/src/read_models/cinematic_timeline_time_layout_read_model.dart packages/map_core/test/cinematic_timeline_time_layout_read_model_test.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/test/cinematic_builder_workspace_test.dart
```

Resultat :

```text
packages/map_editor/test/cinematic_builder_workspace_test.dart:144:    expect(find.text('drag'), findsNothing);
packages/map_editor/test/cinematic_builder_workspace_test.dart:145:    expect(find.text('resize'), findsNothing);
packages/map_editor/test/cinematic_builder_workspace_test.dart:423:    await tester.drag(
packages/map_editor/test/cinematic_builder_workspace_test.dart:1152:    await tester.drag(
packages/map_core/lib/map_core.dart:40:export 'src/operations/map_resize.dart';
```

Interpretation : les deux premieres lignes sont les assertions V1-51 d'absence de `drag`/`resize`; les deux `tester.drag` sont des tests de scroll historiques du fichier ; `map_resize.dart` est un export core preexistant, pas une timeline resize.

Commande anti-playback :

```text
rg -n "playhead|transport|seek|scrub|pause|resume|stopPlayback|startPlayback|previewRuntime|runtimePreview" packages/map_core/lib/map_core.dart packages/map_core/lib/src/read_models/cinematic_timeline_time_layout_read_model.dart packages/map_core/test/cinematic_timeline_time_layout_read_model_test.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/test/cinematic_builder_workspace_test.dart
```

Resultat : sortie vide.

Commande anti-pathfinding stricte :

```text
rg -n "pathfinding|findPath|AStar|astar|Vector2|MapEntity|MapEventDefinition|gridX|gridY|coordinates|positionTarget|targetPosition|velocity|speed" packages/map_core/lib/map_core.dart packages/map_core/lib/src/read_models/cinematic_timeline_time_layout_read_model.dart packages/map_core/test/cinematic_timeline_time_layout_read_model_test.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/test/cinematic_builder_workspace_test.dart
```

Resultat : sortie vide.

Commande `startMs/endMs` :

```text
rg -n "startMs|endMs" packages/map_core/lib/src/read_models/cinematic_timeline_time_layout_read_model.dart packages/map_core/test/cinematic_timeline_time_layout_read_model_test.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/test/cinematic_builder_workspace_test.dart
```

Resultat :

```text
packages/map_core/lib/src/read_models/cinematic_timeline_time_layout_read_model.dart:75:    required this.startMs,
packages/map_core/lib/src/read_models/cinematic_timeline_time_layout_read_model.dart:76:    required this.endMs,
packages/map_core/lib/src/read_models/cinematic_timeline_time_layout_read_model.dart:93:  final int startMs;
packages/map_core/lib/src/read_models/cinematic_timeline_time_layout_read_model.dart:94:  final int endMs;
packages/map_core/lib/src/read_models/cinematic_timeline_time_layout_read_model.dart:130:    final startMs = currentMs;
packages/map_core/lib/src/read_models/cinematic_timeline_time_layout_read_model.dart:131:    final endMs = startMs + visualDurationMs;
packages/map_core/lib/src/read_models/cinematic_timeline_time_layout_read_model.dart:133:      startMs: startMs,
packages/map_core/lib/src/read_models/cinematic_timeline_time_layout_read_model.dart:134:      endMs: endMs,
packages/map_core/lib/src/read_models/cinematic_timeline_time_layout_read_model.dart:138:    currentMs = endMs;
packages/map_core/lib/src/read_models/cinematic_timeline_time_layout_read_model.dart:159:                startMs: timing.startMs,
packages/map_core/lib/src/read_models/cinematic_timeline_time_layout_read_model.dart:160:                endMs: timing.endMs,
packages/map_core/lib/src/read_models/cinematic_timeline_time_layout_read_model.dart:261:    required this.startMs,
packages/map_core/lib/src/read_models/cinematic_timeline_time_layout_read_model.dart:262:    required this.endMs,
packages/map_core/lib/src/read_models/cinematic_timeline_time_layout_read_model.dart:267:  final int startMs;
packages/map_core/lib/src/read_models/cinematic_timeline_time_layout_read_model.dart:268:  final int endMs;
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:1733:                    left: block.startMs * pixelsPerMs,
packages/map_core/test/cinematic_timeline_time_layout_read_model_test.dart:31:              block.startMs,
packages/map_core/test/cinematic_timeline_time_layout_read_model_test.dart:32:              block.endMs,
packages/map_core/test/cinematic_timeline_time_layout_read_model_test.dart:176:      expect(unknownLane.blocks.single.startMs, 0);
packages/map_core/test/cinematic_timeline_time_layout_read_model_test.dart:177:      expect(unknownLane.blocks.single.endMs, 900);
```

Interpretation : uniquement read model derive, test, et mapping UI ; aucun modele JSON ni operation de persistance.

Commande anti-persistence :

```text
rg -n "copyWith\(.*startMs|copyWith\(.*endMs|durationMs.*copyWith|CinematicTimelineStep\(.*startMs|CinematicTimelineStep\(.*endMs" packages/map_core/lib/src/read_models/cinematic_timeline_time_layout_read_model.dart packages/map_core/test/cinematic_timeline_time_layout_read_model_test.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/test/cinematic_builder_workspace_test.dart
```

Resultat : sortie vide.

## 11. Auto-review obligatoire

1. Est-ce que V1-51 a modifie `map_runtime` ? Non.
2. Est-ce que V1-51 a modifie `map_gameplay` / `map_battle` / `examples` ? Non.
3. Est-ce que V1-51 a modifie le modele JSON ? Non.
4. Est-ce que V1-51 a lance build_runner ? Non.
5. Est-ce que V1-51 a ajoute `startMs/endMs` persistés ? Non, seulement read model derive.
6. Est-ce que V1-51 a ajoute une lane persistee ? Non.
7. Est-ce que V1-51 a ajoute du drag/drop ? Non.
8. Est-ce que V1-51 a ajoute du resize ? Non.
9. Est-ce que V1-51 a ajoute du reordonnancement ? Non.
10. Est-ce que V1-51 a ajoute un playhead interactif ? Non.
11. Est-ce que V1-51 a ajoute une preview runtime ? Non.
12. Est-ce que V1-51 a ajoute du pathfinding ? Non.
13. Est-ce que les durees fallback sont derivees seulement ? Oui.
14. Est-ce que l'ordre lineaire reste source de verite ? Oui.
15. Est-ce que Wait/Fade/Camera restent fonctionnels ? Oui, couvert par `cinematic_builder_workspace_test.dart`.
16. Est-ce que ActorFace reste fonctionnel ? Oui.
17. Est-ce que ActorMove reste fonctionnel ? Oui.
18. Est-ce que les labels cible V1-50 restent fonctionnels ? Oui.
19. Est-ce que les steps non-owned restent proteges ? Oui, non modifie et tests builder relances.
20. Est-ce que le design system est respecte ? Oui, pas de couleur hardcodee dans les fichiers UI modifies.
21. Est-ce que la Visual Gate prouve le bar layout et l'ajustement demande par l'utilisateur ? Oui, screenshot 1663x926 avec preview sandbox reduit, timeline agrandie, axe, ticks, barres, selection et inspecteur.
22. Est-ce que l'Evidence Pack est complet sans placeholders ? Oui, les commandes et chemins reels sont listes.
23. Quel est le prochain lot exact recommande ? `NS-SCENES-V1-52 — Cinematic Timeline Selection Cursor / Playhead Placeholder V0`.

## 12. Statut final Git

Commande : `git diff --check`  
Resultat : sortie vide.

Commande : `git diff --stat`  
Resultat :

```text
 packages/map_core/lib/map_core.dart                |    1 +
 .../cinematic_timeline_lane_read_model.dart        |   23 +-
 .../test/cinematic_authoring_operations_test.dart  |   61 +-
 .../cinematic_timeline_lane_read_model_test.dart   |    1 +
 .../cinematics/cinematic_builder_workspace.dart    | 1490 +++++++++++++++-----
 .../cinematics/cinematics_library_workspace.dart   |   18 +
 .../src/ui/canvas/narrative_workspace_canvas.dart  |   54 +
 .../test/cinematic_builder_workspace_test.dart     |  467 +++++-
 .../test/cinematics_library_workspace_test.dart    |   28 +
 .../scenes/road_map_scene_builder_authoring.md     |   32 +-
 reports/narrativeStudio/scenes/road_map_scenes.md  |   36 +-
 11 files changed, 1844 insertions(+), 367 deletions(-)
```

Note : `git diff --stat` ne liste pas les fichiers non suivis V1-51. Ils apparaissent dans le statut final ci-dessous.

Commande : `git diff --name-only`  
Resultat :

```text
packages/map_core/lib/map_core.dart
packages/map_core/lib/src/read_models/cinematic_timeline_lane_read_model.dart
packages/map_core/test/cinematic_authoring_operations_test.dart
packages/map_core/test/cinematic_timeline_lane_read_model_test.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
packages/map_editor/test/cinematics_library_workspace_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

Commande : `git status --short --untracked-files=all`  
Resultat :

```text
 M packages/map_core/lib/map_core.dart
 M packages/map_core/lib/src/read_models/cinematic_timeline_lane_read_model.dart
 M packages/map_core/test/cinematic_authoring_operations_test.dart
 M packages/map_core/test/cinematic_timeline_lane_read_model_test.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
 M packages/map_editor/test/cinematic_builder_workspace_test.dart
 M packages/map_editor/test/cinematics_library_workspace_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? packages/map_core/lib/src/read_models/cinematic_timeline_time_layout_read_model.dart
?? packages/map_core/test/cinematic_timeline_time_layout_read_model_test.dart
?? reports/narrativeStudio/scenes/ns_scenes_v1_50_cinematic_actor_movement_inspector_polish_target_labels_v0.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_51_cinematic_timeline_time_axis_bar_layout_v0.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_51_evidence_pack.md
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_50_cinematic_actor_movement_inspector_polish_target_labels_v0.png
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_51_cinematic_timeline_time_axis_bar_layout_v0.png
```
