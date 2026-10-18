import 'dart:convert';

import 'package:avelune_studio/presentation/features/cinematics/cinematic_timeline_editor.dart';

import 'package:avelune_studio/features/cinematics/application/cinematic_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/data/local_narrative_adapter.dart';
import 'package:avelune_studio/presentation/features/cinematics/cinematic_inspector.dart';
import 'package:avelune_studio/presentation/features/cinematics/cinematic_view_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../../../../packages/map_core/test/fixtures/cinematic_facing_fixture.dart';
import '../support/cinematic_adapter_fixture.dart';

void main() {
  testWidgets(
    'parallel audio channels occupy separate visual rows at their Core time',
    (tester) async {
      final asset = _parallelAsset().copyWith(
        timeline: CinematicTimeline(
          steps: [
            CinematicTimelineStep(
              id: 'sound',
              assetRef: 'sound-a',
              kind: CinematicTimelineStepKind.sound,
              durationMs: 500,
              parallelGroupId: 'audio',
            ),
            CinematicTimelineStep(
              id: 'music',
              assetRef: 'sound-b',
              kind: CinematicTimelineStepKind.sound,
              durationMs: 900,
              parallelGroupId: 'audio',
            ),
          ],
        ),
      );
      final view = CinematicViewState();
      final transport = CinematicPreviewTransport();
      addTearDown(() {
        view.dispose();
        transport.dispose();
      });
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1000,
              height: 600,
              child: CinematicTimelineEditor(
                asset: asset,
                view: view,
                transport: transport,
                changed: () {},
                onSelect: (_) {},
                onMove: (_) {},
                onDuration: (_, _) {},
                onPlay: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      final sound = tester.getTopLeft(
        find.byKey(const ValueKey('cinematic-clip-sound')),
      );
      final music = tester.getTopLeft(
        find.byKey(const ValueKey('cinematic-clip-music')),
      );
      expect(sound.dx, music.dx);
      expect(sound.dy, isNot(music.dy));
      expect(
        buildCinematicTimelineTimeLayoutReadModel(asset).totalDurationMs,
        900,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'parallel inspector groups two actors and camera, seeks, persists and refuses mismatched motion',
    (tester) async {
      final fixture = (await tester.runAsync(() async {
        final f = await CinematicAdapterFixture.create();
        final map = f.file('maps/room.json');
        await map.parent.create(recursive: true);
        await map.writeAsString(
          jsonEncode(
            MapData(
              id: 'room',
              name: 'Room',
              size: const GridSize(width: 16, height: 16),
            ).toJson(),
          ),
        );
        await f.writeManifest(facingProject(_parallelAsset()));
        return f;
      }))!;
      late MapWorkspaceController maps;
      late NarrativeWorkspaceController narrative;
      late CinematicWorkspaceController controller;
      await tester.runAsync(() async {
        maps = MapWorkspaceController(fixture.session, fixture.maps);
        await maps.initialize();
        narrative = NarrativeWorkspaceController(
          maps,
          LocalNarrativeAdapter(
            session: fixture.session,
            mapAdapter: fixture.maps,
          ),
          () {},
          (_, _) async {},
        );
        controller = CinematicWorkspaceController(
          narrative,
          fixture.adapter(),
          changed: () {},
        );
        await controller.open('facing-scene');
      });
      final view = CinematicViewState()..selection.add('otherMove');
      addTearDown(() async {
        view.dispose();
        controller.dispose();
        narrative.dispose();
        maps.dispose();
        await fixture.dispose();
      });
      Future<void> mount() => tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 900,
              child: CinematicInspector(
                controller: controller,
                view: view,
                changed: () {},
                model: null,
                onDialogue: (_) {},
                onLocate: (_) async => null,
                onAdd: (_) {},
              ),
            ),
          ),
        ),
      );
      await mount();
      Future<void> join() async {
        final button = find.byKey(
          ValueKey('cinematic-parallel-join-${view.stepId}'),
        );
        expect(button, findsOneWidget);
        await tester.ensureVisible(button);
        await tester.tap(button);
        await tester.pumpAndSettle();
        await mount();
      }

      await join();
      var asset = controller.active!.asset;
      expect(asset.timeline.steps[1].parallelGroupId, isNotNull);
      expect(
        asset.timeline.steps[1].parallelGroupId,
        asset.timeline.steps[2].parallelGroupId,
      );
      view.selection
        ..clear()
        ..add('camera');
      await mount();
      await join();
      asset = controller.active!.asset;
      expect(
        asset.timeline.steps.skip(1).map((s) => s.parallelGroupId).toSet(),
        hasLength(1),
      );
      expect(
        buildCinematicTimelineTimeLayoutReadModel(asset).totalDurationMs,
        1500,
      );
      expect(find.text('Ensemble'), findsWidgets);
      controller.undo();
      expect(
        controller.active!.asset.timeline.steps.last.parallelGroupId,
        isNull,
      );
      controller.redo();
      expect(
        controller.active!.asset.timeline.steps.last.parallelGroupId,
        isNotNull,
      );
      expect(
        await tester.runAsync(controller.save),
        isTrue,
        reason: controller.error,
      );
      expect(
        (await tester.runAsync(() => fixture.adapter().load('facing-scene')))!
            .asset,
        controller.active!.asset,
      );
      controller.preparePreview();
      controller.transport.seek(500);
      expect(controller.transport.frame!.activeStepIds.toSet(), {
        'move',
        'otherMove',
        'camera',
      });
      expect(
        controller.transport.frame!.actorPoseById('actor')!.x,
        greaterThan(8),
      );
      expect(
        controller.transport.frame!.actorPoseById('other')!.y,
        greaterThan(4),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1000,
              height: 600,
              child: CinematicTimelineEditor(
                asset: asset,
                view: view,
                transport: controller.transport,
                changed: () {},
                onSelect: (_) {},
                onMove: (_) {},
                onDuration: (_, _) {},
                onPlay: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      final move = tester.getTopLeft(
        find.byKey(const ValueKey('cinematic-clip-move')),
      );
      final other = tester.getTopLeft(
        find.byKey(const ValueKey('cinematic-clip-otherMove')),
      );
      final camera = tester.getTopLeft(
        find.byKey(const ValueKey('cinematic-clip-camera')),
      );
      expect(move.dx, closeTo(other.dx, .001));
      expect(move.dx, closeTo(camera.dx, .001));
      expect(move.dy, isNot(other.dy));
      await mount();
      final dissolve = find.byKey(
        const ValueKey('cinematic-parallel-dissolve-camera'),
      );
      await tester.ensureVisible(dissolve);
      await tester.tap(dissolve);
      await tester.pumpAndSettle();
      expect(
        controller.active!.asset.timeline.steps.every(
          (s) => s.parallelGroupId == null,
        ),
        isTrue,
      );
      expect(
        await tester.runAsync(controller.save),
        isTrue,
        reason: controller.error,
      );
      expect(
        (await tester.runAsync(() => fixture.adapter().load('facing-scene')))!
            .asset
            .timeline
            .steps
            .every((s) => s.parallelGroupId == null),
        isTrue,
      );
      controller.edit(
        (a) => updateCinematicTimelineActorMoveStep(
          controller.project.copyWith(cinematics: [a]),
          cinematicId: a.id,
          stepId: 'otherMove',
          durationMs: 900,
        ).cinematic,
      );
      final before = controller.active!.asset;
      view.selection
        ..clear()
        ..add('otherMove');
      await mount();
      await join();
      expect(controller.active!.asset, before);
      expect(view.error, contains('durées identiques'));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}

CinematicAsset _parallelAsset() {
  final json = jsonDecode(
    jsonEncode(facingCinematic().toJson()),
  ) as Map<String, dynamic>;
  (json['requiredActors'] as List).add({'actorId': 'other', 'label': 'Other'});
  (json['movementTargets'] as List).add({
    'targetId': 'otherTarget',
    'label': 'Other arrival',
  });
  final context = json['stageContext'] as Map;
  (context['actorBindings'] as List).add({
    'actorId': 'other',
    'kind': 'mapEntity',
    'mapEntityId': 'npc-other',
  });
  (context['initialPlacements'] as List).add({
    'actorId': 'other',
    'kind': 'stagePoint',
    'stagePointId': 'otherStart',
  });
  (context['stagePoints'] as List).addAll(<Map<String, dynamic>>[
    {'id': 'otherStart', 'label': 'Other start', 'x': 4, 'y': 4},
    {'id': 'otherEnd', 'label': 'Other end', 'x': 4, 'y': 12},
  ]);
  (context['movementTargetBindings'] as List).add({
    'targetId': 'otherTarget',
    'kind': 'stagePoint',
    'sourceId': 'otherEnd',
  });
  final steps = (json['timeline'] as Map)['steps'] as List;
  steps.add({
    ...steps.last as Map,
    'id': 'otherMove',
    'actorId': 'other',
    'targetId': 'otherTarget',
  });
  steps.add({
    'id': 'camera',
    'kind': 'camera',
    'durationMs': 1500,
    'metadata': {
      'camera.mode': 'focus',
      'camera.targetKind': 'actor',
      'camera.targetActorId': 'actor',
      'camera.zoomPreset': 'medium',
    },
  });
  return CinematicAsset.fromJson(json);
}
