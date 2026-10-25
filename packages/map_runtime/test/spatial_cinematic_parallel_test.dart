import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/scene_runtime/cinematic_runtime_playback_controller.dart';
import 'package:map_runtime/src/spatial/spatial_cinematic_runtime_playback_sink.dart';

void main() {
  test('spatial playback refuses absent relative origins without any writes', () async {
    final host = _Host();
    final base = _asset();
    final context = base.stageContext!;
    final asset = CinematicAsset.fromJson({...base.toJson(), 'stageContext': {...context.toJson(),
      'stagePoints': [for (final point in context.stagePoints) {...point.toJson(), 'relativeToActorId': 'missing'}],
    }});
    final initial = Map.of(host.poses);
    expect((await host.controller.play(asset)).success, isFalse);
    expect(host.writes, 0);
    expect(host.poses, initial);
    expect(host.locked, isFalse);
  });

  for (final cancelled in [false, true]) {
    test('relative zero-distance walking preserves fractional poses and ${cancelled ? 'cancels' : 'completes'}', () async {
      final host = _Host();
      host.poses['hero'] = const SpatialCinematicActorPose(x: 1.3125, z: 2.0625, facing: EntityFacing.east);
      final initial = Map.of(host.poses);
      final completion = host.controller.play(_relativeAsset());
      expect(host.controller.isPlaying, isTrue);
      host.controller.update(const Duration(milliseconds: 250));
      expect(host.poses['hero']!.x, 1.3125);
      expect(host.poses['hero']!.z, 2.0625);
      expect(host.poses['hero']!.motion, CharacterAnimationState.walk);
      expect(host.poses['hero']!.animationSeconds, .25);
      expect(host.poses['hero']!.liftCells, 0);
      if (cancelled) {
        host.controller.cancel();
        expect((await completion).success, isFalse);
        expect(host.poses, initial);
        expect(host.committed, isEmpty);
      } else {
        host.controller.update(const Duration(days: 1));
        expect((await completion).success, isTrue);
        expect(host.committed.keys.map((binding) => binding.actorId), contains('hero'));
        expect(host.poses['hero']!.motion, CharacterAnimationState.idle);
      }
      expect(host.locked, isFalse);
    });
  }

  test('relative route offsets use the initial snapshot across later groups', () async {
    final host = _Host();
    host.poses['hero'] = const SpatialCinematicActorPose(x: 1.3125, z: 2.0625, facing: EntityFacing.east);
    final asset = _relativeAsset(offsets: [.5, 1]);
    final completion = host.controller.play(asset);
    host.controller.update(const Duration(seconds: 1));
    expect(host.poses['hero']!.x, 1.8125);
    host.controller.update(const Duration(seconds: 1));
    expect((await completion).success, isTrue);
    expect(host.poses['hero']!.x, 2.3125);
    expect(host.poses['hero']!.z, 2.0625);
  });

  for (final failure in ['repositioned origin', 'outside map', 'wall']) {
    test('relative routes reject $failure before changing actors', () async {
      final host = _Host(wall: failure == 'wall');
      var asset = _relativeAsset(offsets: [failure == 'outside map' ? 10 : 1]);
      if (failure == 'repositioned origin') {
        asset = asset.copyWith(stageContext: CinematicStageContext.fromJson({...asset.stageContext!.toJson(), 'initialPlacements': [
          {'actorId': 'hero', 'kind': 'stagePoint', 'stagePointId': 'fixed'},
        ], 'stagePoints': [...asset.stageContext!.stagePoints.map((point) => point.toJson()),
          {'id': 'fixed', 'label': 'Fixed', 'x': 1, 'y': 2},
        ]}));
      }
      expect((await host.controller.play(asset)).success, isFalse);
      expect(host.writes, 0);
      expect(host.committed, isEmpty);
      expect(host.locked, isFalse);
    });
  }

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

  test('explicit mobile actor crossing permits a simultaneous swap', () async {
    final host = _Host();
    final asset = CinematicAsset.fromJson({..._asset(swap: true).toJson(), 'allowMobileActorCrossing': true});
    final completion = host.controller.play(asset);
    host.controller.update(const Duration(milliseconds: 1500));
    expect((await completion).success, isTrue);
    expect(host.committed, hasLength(2));
    expect(host.locked, isFalse);
  });

  for (final blockedBy in ['wall', 'stationary actor', 'overlapping final poses']) {
    test('mobile crossing preserves $blockedBy rejection', () async {
      final host = _Host(wall: blockedBy == 'wall', stationaryActor: blockedBy == 'stationary actor');
      var asset = _asset(swap: true).copyWith(allowMobileActorCrossing: true);
      if (blockedBy == 'overlapping final poses') {
        asset = asset.copyWith(stageContext: CinematicStageContext.fromJson({...asset.stageContext!.toJson(), 'stagePoints': [
          {'id': 'a', 'label': 'A', 'x': 3, 'y': 2},
          {'id': 'b', 'label': 'B', 'x': 3, 'y': 2},
        ]}));
      }
      final result = await host.controller.play(asset);
      expect(result.success, isFalse);
      expect(host.writes, 0);
      expect(host.committed, isEmpty);
      expect(host.locked, isFalse);
    });
  }

  test('crossing opt-in never exempts a stationary member of the same group', () async {
    final host = _Host();
    final base = _asset(swap: true);
    final asset = base.copyWith(allowMobileActorCrossing: true, timeline: CinematicTimeline(steps: [
      for (final step in base.timeline.steps)
        if (step.actorId == 'guide')
          CinematicTimelineStep.fromJson({...step.toJson(), 'kind': 'actorFace', 'targetId': null, 'metadata': {'actor.direction': 'left'}})
        else step,
    ]));
    expect((await host.controller.play(asset)).success, isFalse);
    expect(host.writes, 0);
    expect(host.committed, isEmpty);
  });

  test('cancelling a permitted crossing restores both actors before commit', () async {
    final host = _Host();
    final initial = Map.of(host.poses);
    final completion = host.controller.play(_asset(swap: true).copyWith(allowMobileActorCrossing: true));
    host.controller.update(const Duration(milliseconds: 500));
    expect(host.poses['hero']!.x, host.poses['guide']!.x);
    host.controller.cancel();
    expect((await completion).success, isFalse);
    expect(host.poses, initial);
    expect(host.committed, isEmpty);
    expect(host.locked, isFalse);
  });

  for (final kind in [CinematicTimelineStepKind.actorMove, CinematicTimelineStepKind.actorJump]) {
    test('zero-distance ${kind.name} remains a blocker with crossing enabled', () async {
      final host = _Host();
      final base = _asset();
      final asset = base.copyWith(allowMobileActorCrossing: true,
        stageContext: CinematicStageContext.fromJson({...base.stageContext!.toJson(), 'stagePoints': [
          {'id': 'a', 'label': 'A', 'x': 5, 'y': 2},
          {'id': 'b', 'label': 'B', 'x': 3, 'y': 2},
        ]}),
        timeline: CinematicTimeline(steps: [for (final step in base.timeline.steps)
          if (step.actorId == 'guide' && kind == CinematicTimelineStepKind.actorJump)
            CinematicTimelineStep.fromJson({...step.toJson(), 'kind': 'actorJump', 'metadata': {'actor.jumpHeightCells': '1'}})
          else step,
        ]));
      final completion = host.controller.play(asset);
      host.controller.update(const Duration(milliseconds: 1500));
      expect((await completion).success, isFalse);
      expect(host.writes, 0);
      expect(host.committed, isEmpty);
      expect(host.locked, isFalse);
    });
  }

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

CinematicAsset _relativeAsset({List<double> offsets = const [0]}) {
  final base = _asset();
  return CinematicAsset.fromJson({...base.toJson(), 'movementTargets': [
    for (var i = 0; i < offsets.length; i++) {'targetId': 'relative-$i', 'label': 'Relative $i'},
  ], 'stageContext': {...base.stageContext!.toJson(), 'initialPlacements': [
    {'actorId': 'hero', 'kind': 'fromMapEntity'},
  ], 'stagePoints': [
    for (var i = 0; i < offsets.length; i++) {'id': 'relative-$i', 'label': 'Relative $i', 'x': offsets[i], 'y': 0, 'relativeToActorId': 'hero'},
  ], 'movementTargetBindings': [
    for (var i = 0; i < offsets.length; i++) {'targetId': 'relative-$i', 'kind': 'stagePoint', 'sourceId': 'relative-$i'},
  ]}, 'timeline': {'steps': [
    for (var i = 0; i < offsets.length; i++) {'id': 'relative-$i', 'kind': 'actorMove', 'actorId': 'hero', 'targetId': 'relative-$i', 'durationMs': 1000, 'metadata': {
      'actor.movementMode': 'walk', 'actor.pathMode': 'direct', 'actor.facingMode': 'preserve',
    }},
  ]}});
}

final class _Host {
  _Host({bool jump = false, bool wall = false, bool stationaryActor = false}) {
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
        canTraverse: (actor, x, z, nx, nz, candidates, crossingActors) =>
            (!wall || nx < 1.75 || nx > 2.25) &&
            (!stationaryActor || (nx - 2).abs() >= .5 || (nz - 2).abs() >= .5) && candidates.entries
            .where((entry) => entry.key.actorId != actor.actorId && !crossingActors.contains(entry.key))
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
