import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/scene_runtime/cinematic_runtime_playback_controller.dart';
import 'package:map_runtime/src/spatial/spatial_cinematic_runtime_playback_sink.dart';

void main() {
  test('spatial playback refuses actor-relative stage points without any writes', () async {
    final host = _Host();
    final base = _asset();
    final context = base.stageContext!;
    final asset = CinematicAsset.fromJson({...base.toJson(), 'stageContext': {...context.toJson(),
      'stagePoints': [for (final point in context.stagePoints) {...point.toJson(), 'relativeToActorId': 'hero'}],
    }});
    final initial = Map.of(host.poses);
    expect((await host.controller.play(asset)).success, isFalse);
    expect(host.writes, 0);
    expect(host.poses, initial);
    expect(host.locked, isFalse);
  });

  test(
    'parallel actors can clear one another path at the same timestamp',
    () async {
      final host = _Host();
      final completion = host.controller.play(_asset());
      host.controller.update(const Duration(milliseconds: 500));
      expect(host.poses['hero']!.x, 2);
      expect(host.poses['guide']!.x, 4);
      host.controller.update(const Duration(milliseconds: 500));
      expect(host.controller.currentSteps.map((step) => step.id), ['camera']);
      host.controller.update(const Duration(milliseconds: 500));
      expect((await completion).success, isTrue);
      expect(host.committed, hasLength(2));
      expect(host.locked, isFalse);
    },
  );

  test(
    'parallel jump lands in the position another actor has just cleared',
    () async {
      final host = _Host(jump: true);
      final completion = host.controller.play(_asset(jump: true));
      host.controller.update(const Duration(milliseconds: 500));
      expect(host.poses['guide']!.liftCells, .5);
      host.controller.update(const Duration(milliseconds: 1000));
      expect((await completion).success, isTrue);
      expect(host.poses['guide']!.x, 1);
      expect(host.poses['guide']!.z, 2);
      expect(host.poses['guide']!.liftCells, 0);
    },
  );

  test('crossing actor routes are refused before any visual writes', () async {
    final host = _Host();
    final initial = Map.of(host.poses);
    final result = await host.controller.play(_asset(swap: true));
    expect(result.success, isFalse);
    expect(host.writes, 0);
    expect(host.poses, initial);
    expect(host.committed, isEmpty);
  });

  test(
    'spatial seek rebuilds preparation and cancellation restores both actors',
    () async {
      final host = _Host();
      final initial = Map.of(host.poses);
      final completion = host.controller.play(_asset());
      host.controller.update(const Duration(milliseconds: 500));
      expect(
        (await host.controller.seek(const Duration(milliseconds: 750))).success,
        isTrue,
      );
      expect(host.poses['hero']!.x, 2.5);
      expect(host.poses['guide']!.x, 4.5);
      expect(host.committed, isEmpty);
      host.controller.cancel();
      expect((await completion).success, isFalse);
      expect(host.poses, initial);
      expect(host.locked, isFalse);
    },
  );

  test(
    'large and small ticks produce the same collective final poses',
    () async {
      final large = _Host(), small = _Host();
      final first = large.controller.play(_asset()),
          second = small.controller.play(_asset());
      large.controller.update(const Duration(milliseconds: 1500));
      for (var i = 0; i < 15; i++) {
        small.controller.update(const Duration(milliseconds: 100));
      }
      expect((await first).success, isTrue);
      expect((await second).success, isTrue);
      expect(large.poses, small.poses);
    },
  );
}

final class _Host {
  _Host({bool jump = false}) {
    poses['hero'] = const SpatialCinematicActorPose(
      x: 1,
      z: 2,
      facing: EntityFacing.east,
    );
    poses['guide'] = SpatialCinematicActorPose(
      x: jump ? 1 : 3,
      z: jump ? 4 : 2,
      facing: EntityFacing.east,
    );
    final map = MapData(
      id: 'room',
      name: 'Room',
      size: const GridSize(width: 8, height: 8),
      spatialScene: MapSpatialScene(width: 8, depth: 8),
    );
    controller = CinematicRuntimePlaybackController(
      sink: SpatialCinematicRuntimePlaybackSink(
        project: const ProjectManifest(name: 'Group', maps: [], tilesets: []),
        activeMap: () => map,
        readActor: (binding) => poses[binding.actorId],
        writeActor: (binding, pose) {
          writes++;
          poses[binding.actorId] = pose;
        },
        readCamera: () => camera,
        writeCamera: (pose) => camera = pose,
        setInputLocked: (value) => locked = value,
        onCompletedPoses: (values) => committed.addAll(values),
        canTraverse: (actor, x, z, nx, nz, candidates) => candidates.entries
            .where((entry) => entry.key.actorId != actor.actorId)
            .every(
              (entry) =>
                  math.sqrt(
                    math.pow(nx - entry.value.x, 2) +
                        math.pow(nz - entry.value.z, 2),
                  ) >=
                  .5,
            ),
      ),
    );
  }
  late final CinematicRuntimePlaybackController controller;
  final poses = <String, SpatialCinematicActorPose>{};
  final committed = <CinematicActorBinding, SpatialCinematicActorPose>{};
  SpatialCinematicCameraPose? camera;
  var locked = false;
  var writes = 0;
}

CinematicAsset _asset({bool jump = false, bool swap = false}) => CinematicAsset(
  id: 'group',
  title: 'Group',
  mapId: 'room',
  requiredActors: [
    for (final id in ['hero', 'guide']) CinematicActorRef(actorId: id),
  ],
  movementTargets: [
    for (final id in ['a', 'b'])
      CinematicMovementTargetRef(targetId: id, label: id),
  ],
  stageContext: CinematicStageContext(
    actorBindings: [
      CinematicActorBinding(
        actorId: 'hero',
        kind: CinematicActorBindingKind.player,
      ),
      CinematicActorBinding(
        actorId: 'guide',
        kind: CinematicActorBindingKind.mapEntity,
        mapEntityId: 'guide',
      ),
    ],
    stagePoints: [
      CinematicStagePoint(id: 'a', label: 'A', x: 3, y: 2),
      CinematicStagePoint(id: 'b', label: 'B', x: jump || swap ? 1 : 5, y: 2),
    ],
    movementTargetBindings: [
      for (final id in ['a', 'b'])
        CinematicMovementTargetBinding(
          targetId: id,
          kind: CinematicMovementTargetBindingKind.stagePoint,
          sourceId: id,
        ),
    ],
  ),
  timeline: CinematicTimeline(
    steps: [
      for (final id in ['hero', 'guide'])
        CinematicTimelineStep.fromJson({
          'id': id,
          'kind': jump && id == 'guide' ? 'actorJump' : 'actorMove',
          'actorId': id,
          'targetId': id == 'hero' ? 'a' : 'b',
          'durationMs': 1000,
          'parallelGroupId': 'together',
          'metadata': jump && id == 'guide'
              ? {'actor.jumpHeightCells': '0.5'}
              : {'actor.movementMode': 'walk', 'actor.pathMode': 'direct'},
        }),
      CinematicTimelineStep.fromJson({
        'id': 'camera',
        'kind': 'camera',
        'durationMs': 1500,
        'parallelGroupId': 'together',
        'metadata': {'camera.mode': 'hold'},
      }),
    ],
  ),
);
