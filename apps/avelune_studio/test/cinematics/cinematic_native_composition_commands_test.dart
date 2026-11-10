import 'dart:async';
import 'dart:convert';

import 'package:avelune_studio/features/cinematics/application/cinematic_workspace_controller.dart';
import 'package:avelune_studio/features/cinematics/application/cinematic_map_model.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/data/local_narrative_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../../../../packages/map_core/test/fixtures/cinematic_facing_fixture.dart';
import '../support/cinematic_adapter_fixture.dart';

void main() {
  test('parallel native commands group, seek, undo, publish and reject incompatible motion', () async {
    final fixture = await CinematicAdapterFixture.create();
    await _writeMap(
      fixture,
      MapData(
        id: 'room',
        name: 'Room',
        size: const GridSize(width: 16, height: 16),
      ),
    );
    await fixture.writeManifest(facingProject(_parallelAsset()));
    final maps = MapWorkspaceController(fixture.session, fixture.maps);
    await maps.initialize();
    final narrative = NarrativeWorkspaceController(
      maps,
      LocalNarrativeAdapter(session: fixture.session, mapAdapter: fixture.maps),
      () {},
      (_, _) async {},
    );
    final controller = CinematicWorkspaceController(
      narrative,
      fixture.adapter(),
      changed: () {},
    );
    addTearDown(() async {
      controller.dispose();
      narrative.dispose();
      maps.dispose();
      await fixture.dispose();
    });
    await controller.open('facing-scene');
    expect(
      controller.edit(
        (asset) => joinCinematicParallelSteps(asset, 'otherMove'),
      ),
      isTrue,
      reason: controller.error,
    );
    expect(
      controller.edit((asset) => joinCinematicParallelSteps(asset, 'camera')),
      isTrue,
      reason: controller.error,
    );
    final grouped = controller.active!.asset;
    expect(
      grouped.timeline.steps
          .skip(1)
          .map((step) => step.parallelGroupId)
          .toSet(),
      hasLength(1),
    );
    expect(
      buildCinematicTimelineTimeLayoutReadModel(grouped).totalDurationMs,
      1500,
    );
    controller.undo();
    expect(
      controller.active!.asset.timeline.steps.last.parallelGroupId,
      isNull,
    );
    controller.redo();
    expect(controller.active!.asset, grouped);
    expect(await controller.save(), isTrue, reason: controller.error);
    expect((await fixture.adapter().load('facing-scene')).asset, grouped);
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
    expect(
      controller.edit(
        (asset) => dissolveCinematicParallelSteps(asset, 'camera'),
      ),
      isTrue,
    );
    expect(
      controller.active!.asset.timeline.steps.every(
        (step) => step.parallelGroupId == null,
      ),
      isTrue,
    );
    expect(await controller.save(), isTrue, reason: controller.error);
    expect(
      (await fixture.adapter().load('facing-scene')).asset,
      controller.active!.asset,
    );
    controller.edit(
      (asset) => updateCinematicTimelineActorMoveStep(
        controller.project.copyWith(cinematics: [asset]),
        cinematicId: asset.id,
        stepId: 'otherMove',
        durationMs: 900,
      ).cinematic,
    );
    final before = controller.active!.asset;
    expect(
      controller.edit(
        (asset) => joinCinematicParallelSteps(asset, 'otherMove'),
      ),
      isFalse,
    );
    expect(controller.active!.asset, before);
  });

  test(
    'relative points preserve routes and replay from the new actor origin',
    () async {
      final map = MapData(
        id: 'room',
        name: 'Room',
        size: const GridSize(width: 16, height: 16),
        entities: const [
          MapEntity(
            id: 'guide',
            kind: MapEntityKind.npc,
            pos: GridPos(x: 8, y: 8),
            npc: MapEntityNpcData(),
          ),
        ],
      );
      final base = facingCinematic(manual: true);
      final initial = CinematicAsset.fromJson({
        ...base.toJson(),
        'stageContext': {
          ...base.stageContext!.toJson(),
          'actorBindings': [
            {'actorId': 'actor', 'kind': 'mapEntity', 'mapEntityId': 'guide'},
          ],
          'initialPlacements': [
            {'actorId': 'actor', 'kind': 'fromMapEntity'},
          ],
        },
      });
      final fixture = await CinematicAdapterFixture.create();
      await _writeMap(fixture, map);
      await fixture.writeManifest(facingProject(initial));
      final maps = MapWorkspaceController(fixture.session, fixture.maps);
      await maps.initialize();
      final narrative = NarrativeWorkspaceController(
        maps,
        LocalNarrativeAdapter(
          session: fixture.session,
          mapAdapter: fixture.maps,
        ),
        () {},
        (_, _) async {},
      );
      final controller = CinematicWorkspaceController(
        narrative,
        fixture.adapter(),
        changed: () {},
      );
      addTearDown(() async {
        controller.dispose();
        narrative.dispose();
        maps.dispose();
        await fixture.dispose();
      });
      await controller.open('facing-scene');
      final model = CinematicMapModel(initial, controller.project, map);
      final original = initial.stageContext!.stagePoints.last;
      expect(() => model.rebasePoint(original, 'missing'), throwsStateError);
      expect(() => model.pointAt(original, -1, 4), throwsStateError);
      final relative = model.rebasePoint(original, 'actor');
      expect(relative.x, 3.5);
      expect(relative.relativeToActorId, 'actor');
      controller.setStagePoint(relative);
      final pending = Completer<bool>();
      final move = controller.moveStagePointTo(
        relative.id,
        11.5,
        8.5,
        model: model,
        confirmShared: (_) => pending.future,
      );
      if (!pending.isCompleted) pending.complete(true);
      await move;
      controller.setStagePoint(
        CinematicStagePoint(
          id: relative.id,
          label: relative.label,
          x: 3,
          y: relative.y,
          relativeToActorId: 'actor',
        ),
      );
      expect(await controller.save(), isTrue, reason: controller.error);
      final reopened = (await fixture.adapter().load('facing-scene')).asset;
      expect(
        reopened.stageContext!.stagePoints.last.relativeToActorId,
        'actor',
      );
      expect(reopened.stageContext!.manualPaths.single.waypointStagePointIds, [
        'corner',
      ]);
      final moved = map.copyWith(
        entities: [
          map.entities.single.copyWith(pos: const GridPos(x: 4, y: 5)),
        ],
      );
      final movedModel = CinematicMapModel(reopened, controller.project, moved);
      final plan = buildCinematicPreviewPlaybackPlan(
        cinematic: reopened,
        actorDisplayPreviewModel: movedModel.actors,
        stageBounds: movedModel.bounds,
        availableMapIds: ['room'],
      );
      final pose = plan.frameAt(plan.totalDurationMs).actorPoseById('actor')!;
      expect(pose.x, movedModel.actorOrigins['actor']!.x + 3);
      expect(pose.y, 5);
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

Future<void> _writeMap(CinematicAdapterFixture fixture, MapData map) async {
  final file = fixture.file('maps/room.json');
  await file.parent.create(recursive: true);
  await file.writeAsString(jsonEncode(map.toJson()));
}
