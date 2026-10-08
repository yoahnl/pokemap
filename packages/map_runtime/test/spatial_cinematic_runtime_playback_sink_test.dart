import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/src/spatial_terrain_navigation.dart';
import 'package:map_runtime/src/application/scene_runtime/cinematic_runtime_playback_controller.dart';
import 'package:map_runtime/src/application/scene_runtime/scene_cinematic_runtime_awaitable_result.dart';
import 'package:map_runtime/src/spatial/spatial_cinematic_runtime_playback_sink.dart';

void main() {
  test(
      'manual route follows distance in map units and commits its terminal pose',
      () async {
    final host = _Host();
    final controller = host.controller();
    final completion = controller.play(_asset(manual: true));
    expect(host.locked, isTrue);
    controller.update(const Duration(milliseconds: 500));
    expect(host.pose.x, 3);
    expect(host.pose.z, 2);
    expect(host.pose.motion, CharacterAnimationState.walk);
    expect(host.pose.facing, EntityFacing.east);
    controller.update(const Duration(milliseconds: 500));
    expect((await completion).success, isTrue);
    expect(host.pose.x, 4);
    expect(host.pose.z, 3);
    expect(host.pose.motion, CharacterAnimationState.idle);
    expect(host.pose.facing, EntityFacing.south);
    expect(host.committed.single.x, 4);
    expect(host.locked, isFalse);
    expect(host.camera, isNull);
  });

  test('preflight rejects a thin obstacle between valid endpoints', () async {
    final host = _Host()..blocked = (ax, az, bx, bz) => bx >= 2.5 && bx < 2.6;
    final completion = host.controller().play(_asset());
    expect((await completion).success, isFalse);
    expect(host.writes, 0);
    expect(host.locked, isFalse);
    expect(host.committed, isEmpty);
  });

  test('an active manual route without waypoints fails before mutation',
      () async {
    final host = _Host();
    final base = _asset(manual: true);
    final asset = CinematicAsset.fromJson({
      ...base.toJson(),
      'stageContext': {
        ...base.stageContext!.toJson(),
        'manualPaths': [
          {
            ...base.stageContext!.manualPaths.single.toJson(),
            'waypointStagePointIds': [],
          },
        ],
      },
    });
    final controller = host.controller();
    final completion = controller.play(asset);
    controller.update(const Duration(seconds: 1));
    final result = await completion;
    expect(result.success, isFalse);
    expect(result.message, contains('waypoint'));
    expect(host.writes, 0);
    expect(host.lockChanges, isEmpty);
  });

  test('preflight rejects a cliff crossing through the terrain predicate',
      () async {
    final host = _Host();
    host.map = host.map.copyWith(
        spatialScene: MapSpatialScene(width: 8, depth: 8, heightLevels: [
      for (var z = 0; z < 8; z++)
        for (var x = 0; x < 8; x++) x >= 3 ? 1 : 0,
    ]));
    final result = await host.controller().play(_asset());
    expect(result.success, isFalse);
    expect(host.writes, 0);
  });

  test('an authored ramp is traversable and camera focus uses terrain height',
      () async {
    final host = _Host();
    host.map = host.map.copyWith(
        spatialScene: MapSpatialScene(
            width: 8,
            depth: 8,
            heightLevels: [
              for (var z = 0; z < 8; z++)
                for (var x = 0; x < 8; x++) x >= 3 ? 1 : 0,
            ],
            navigation: SpatialNavigationProfile(ramps: [
              SpatialRamp(
                  id: 'approach',
                  x: 2,
                  z: 1,
                  width: 1,
                  depth: 3,
                  lowLevel: 0,
                  highLevel: 1,
                  direction: SpatialRampDirection.east),
            ])));
    final controller = host.controller();
    final completion = controller.play(_asset(withCamera: true));
    controller.update(const Duration(seconds: 1));
    expect(host.camera!.y, 1);
    controller.update(const Duration(seconds: 1));
    expect((await completion).success, isTrue);
    expect(host.pose.x, 4);
    expect(host.pose.z, 3);
    expect(host.camera, isNull);
  });

  test('missing actors fail before camera or input mutation', () async {
    final host = _Host()..actorPresent = false;
    final result = await host.controller().play(_asset());
    expect(result.errorCode,
        SceneCinematicRuntimeAwaitableErrorCode.invalidActorReference);
    expect(host.writes, 0);
    expect(host.lockChanges, isEmpty);
  });

  for (final kind in CinematicTimelineStepKind.values.where((kind) => !const {
        CinematicTimelineStepKind.wait,
        CinematicTimelineStepKind.camera,
        CinematicTimelineStepKind.actorMove,
        CinematicTimelineStepKind.actorFace,
        CinematicTimelineStepKind.marker,
      }.contains(kind))) {
    test('rejects ${kind.name} before changing any actor', () async {
      final host = _Host();
      final base = _asset();
      final unsupported = CinematicTimelineStep(
          id: 'unsupported',
          kind: kind,
          actorId: 'guide',
          assetRef: 'missing',
          dialogueText: 'No',
          durationMs: 100);
      final asset = base.copyWith(
          timeline: CinematicTimeline(steps: [
        ...base.timeline.steps,
        unsupported,
      ]));
      expect((await host.controller().play(asset)).success, isFalse);
      expect(host.writes, 0);
      expect(host.lockChanges, isEmpty);
    });
  }

  test('cancellation restores camera actor motion and input once', () async {
    final host = _Host();
    final original = host.pose;
    final camera = SpatialCinematicCameraPose(x: 1, y: 0, z: 1, zoom: 1.5);
    host.camera = camera;
    final controller = host.controller();
    final completion = controller.play(_asset(withCamera: true));
    controller.update(const Duration(milliseconds: 500));
    expect(host.camera!.x, 2.5);
    controller.update(const Duration(milliseconds: 750));
    expect(host.pose.x, greaterThan(1));
    expect(controller.cancel(), isTrue);
    expect(controller.cancel(), isFalse);
    expect((await completion).errorCode,
        SceneCinematicRuntimeAwaitableErrorCode.cancelled);
    expect(host.pose, original);
    expect(host.camera, camera);
    expect(host.lockChanges, [true, false]);
    expect(host.committed, isEmpty);
  });

  test('no update preserves a paused scene without wall clock progress',
      () async {
    final host = _Host();
    final controller = host.controller();
    var completed = false;
    final completion = controller.play(_asset())..then((_) => completed = true);
    controller.update(const Duration(milliseconds: 250));
    final paused = host.pose;
    await Future<void>.value();
    expect(host.pose, paused);
    expect(completed, isFalse);
    controller.update(const Duration(milliseconds: 750));
    expect((await completion).success, isTrue);
  });

  test('map replacement fails without writing stale actor poses into new map',
      () async {
    final host = _Host();
    final controller = host.controller();
    final completion = controller.play(_asset());
    controller.update(const Duration(milliseconds: 250));
    host.map = host.map.copyWith(id: 'replacement');
    final writes = host.writes;
    controller.update(const Duration(milliseconds: 250));
    expect((await completion).errorCode,
        SceneCinematicRuntimeAwaitableErrorCode.sinkFailure);
    expect(host.writes, writes);
    expect(host.locked, isFalse);
    expect(host.committed, isEmpty);
  });

  test('a blocker arriving during playback restores the initial actor',
      () async {
    final host = _Host();
    final initial = host.pose;
    final controller = host.controller();
    final completion = controller.play(_asset());
    controller.update(const Duration(milliseconds: 250));
    host.blocked = (ax, az, bx, bz) => bx >= 2.5;
    controller.update(const Duration(milliseconds: 750));
    expect((await completion).success, isFalse);
    expect(host.pose, initial);
    expect(host.locked, isFalse);
    expect(host.committed, isEmpty);
  });

  test('failed final pose commit restores actors and still releases input',
      () async {
    final host = _Host()..failCommit = true;
    final initial = host.pose;
    final controller = host.controller();
    final completion = controller.play(_asset());
    controller.update(const Duration(seconds: 1));
    expect((await completion).success, isFalse);
    expect(host.pose, initial);
    expect(host.locked, isFalse);
  });

  test('a large update visits the manual corner instead of cutting diagonally',
      () async {
    final host = _Host()..blocked = (ax, az, bx, bz) => ax != bx && az != bz;
    final controller = host.controller();
    final completion = controller.play(_asset(manual: true));
    controller.update(const Duration(milliseconds: 500));
    controller.update(const Duration(milliseconds: 500));
    expect((await completion).success, isTrue);
    expect(host.pose.x, 4);
    expect(host.pose.z, 3);
  });

  test('map provider disposal still restores camera and releases owned input',
      () async {
    final host = _Host();
    final controller = host.controller();
    final completion = controller.play(_asset());
    host.mapUnavailable = true;
    controller.update(const Duration(milliseconds: 500));
    expect((await completion).success, isFalse);
    expect(host.locked, isFalse);
    expect(host.camera, isNull);
  });

  test('fromMapEntity initial placement uses the bound runtime actor pose',
      () async {
    final host = _Host();
    final base = _asset();
    final asset = CinematicAsset.fromJson({
      ...base.toJson(),
      'stageContext': {
        ...base.stageContext!.toJson(),
        'initialPlacements': [
          {'actorId': 'guide', 'kind': 'fromMapEntity'},
        ],
      },
    });
    final controller = host.controller();
    final completion = controller.play(asset);
    expect(host.locked, isTrue);
    controller.update(const Duration(seconds: 1));
    expect((await completion).success, isTrue);
  });

  test('wait holds a face command and run advances directional animation phase',
      () async {
    final host = _Host();
    final base = _asset();
    final move = base.timeline.steps.single;
    final asset = base.copyWith(
        timeline: CinematicTimeline(steps: [
      CinematicTimelineStep(
          id: 'face',
          kind: CinematicTimelineStepKind.actorFace,
          actorId: 'guide',
          metadata: const {'actor.direction': 'left'}),
      CinematicTimelineStep(
          id: 'wait', kind: CinematicTimelineStepKind.wait, durationMs: 100),
      CinematicTimelineStep.fromJson({
        ...move.toJson(),
        'metadata': {...move.metadata, 'actor.movementMode': 'run'},
      }),
    ]));
    final controller = host.controller();
    final completion = controller.play(asset);
    expect(host.pose.facing, EntityFacing.west);
    expect(host.pose.x, 1);
    controller.update(const Duration(milliseconds: 50));
    expect(host.pose.x, 1);
    controller.update(const Duration(milliseconds: 100));
    expect(host.pose.motion, CharacterAnimationState.run);
    expect(host.pose.animationSeconds, closeTo(.05, .00001));
    controller.cancel();
    await completion;
  });

  test('preflight simulates an actor clearing another actor route', () async {
    final host = _MultiActorHost();
    final controller = host.controller();
    final completion = controller.play(host.asset());
    expect(host.locked, isTrue);
    controller.update(const Duration(seconds: 2));
    expect((await completion).success, isTrue);
    expect(host.poses['blocker']!.z, 4);
    expect(host.poses['guide']!.x, 4);
    expect(host.poses['guide']!.z, 2);
  });

  test('preflight simulates initial placements before validating later routes',
      () async {
    final host = _MultiActorHost();
    final controller = host.controller();
    final completion = controller.play(host.asset(initialPlacement: true));
    expect(host.locked, isTrue);
    controller.update(const Duration(seconds: 1));
    expect((await completion).success, isTrue);
    expect(host.poses['blocker']!.z, 4);
    expect(host.poses['guide']!.x, 4);
  });

  test('a hero terminal outside the movement precision fails before mutation',
      () async {
    for (final initialPlacement in [false, true]) {
      final host = _Host();
      final controller = host.controller();
      final completion = controller.play(_precisionAsset(
          kind: CinematicActorBindingKind.player,
          x: 3.2,
          initialPlacement: initialPlacement));
      controller.update(const Duration(seconds: 1));
      final result = await completion;
      expect(result.success, isFalse);
      expect(result.message, contains('1/16'));
      expect(host.writes, 0);
      expect(host.lockChanges, isEmpty);
      expect(host.committed, isEmpty);
    }
  });

  test(
      'hero terminals use movement precision while NPCs and waypoints stay exact',
      () async {
    for (final scenario in [
      (kind: CinematicActorBindingKind.player, x: 3.1875, initial: false),
      (kind: CinematicActorBindingKind.player, x: 3.1875, initial: true),
      (kind: CinematicActorBindingKind.player, x: 3.187500005, initial: false),
      (kind: CinematicActorBindingKind.mapEntity, x: 3.2, initial: false),
    ]) {
      final host = _Host();
      final controller = host.controller();
      final completion = controller.play(_precisionAsset(
          kind: scenario.kind,
          x: scenario.x,
          initialPlacement: scenario.initial));
      expect(host.locked, isTrue);
      if (!scenario.initial) {
        controller.update(const Duration(milliseconds: 200));
        expect(host.pose.x * 16,
            isNot(closeTo((host.pose.x * 16).roundToDouble(), 1e-7)));
      }
      controller.update(const Duration(seconds: 1));
      expect((await completion).success, isTrue);
      expect(host.committed.single.x,
          scenario.kind == CinematicActorBindingKind.player ? 3.1875 : 3.2);
      expect(host.committed.single.z, 3);
      expect(host.locked, isFalse);
    }
  });
}

final class _Host {
  final project = const ProjectManifest(
      name: 'Spatial',
      maps: [],
      tilesets: [],
      settings:
          ProjectSettings(tileWidth: 32, tileHeight: 48, displayScale: 2));
  MapData map = MapData(
      id: 'village',
      name: 'Village',
      size: const GridSize(width: 8, height: 8),
      spatialScene: MapSpatialScene(width: 8, depth: 8),
      layers: const []);
  var pose = SpatialCinematicActorPose(x: 1, z: 2, facing: EntityFacing.north);
  SpatialCinematicCameraPose? camera;
  bool actorPresent = true,
      locked = false,
      failCommit = false,
      mapUnavailable = false;
  int writes = 0;
  final lockChanges = <bool>[];
  final committed = <SpatialCinematicActorPose>[];
  bool Function(double, double, double, double)? blocked;

  CinematicRuntimePlaybackController controller() =>
      CinematicRuntimePlaybackController(
          sink: SpatialCinematicRuntimePlaybackSink(
        project: project,
        activeMap: () =>
            mapUnavailable ? throw StateError('Map disposed') : map,
        readActor: (_) => actorPresent ? pose : null,
        writeActor: (_, next) {
          writes++;
          pose = next;
        },
        readCamera: () => camera,
        writeCamera: (next) => camera = next,
        canTraverse: (actor, ax, az, bx, bz, poses) =>
            canTraverseSpatialTerrainStep(map.spatialScene!, ax, az, bx, bz) &&
            !(blocked?.call(ax, az, bx, bz) ?? false),
        setInputLocked: (next) {
          locked = next;
          lockChanges.add(next);
        },
        onCompletedPoses: (poses) {
          if (failCommit) throw StateError('Commit rejected');
          committed.addAll(poses.values);
        },
      ));
}

final class _MultiActorHost {
  final map = MapData(
      id: 'village',
      name: 'Village',
      size: const GridSize(width: 8, height: 8),
      spatialScene: MapSpatialScene(width: 8, depth: 8));
  final poses = <String, SpatialCinematicActorPose>{
    'guide': SpatialCinematicActorPose(x: 1, z: 2, facing: EntityFacing.north),
    'blocker':
        SpatialCinematicActorPose(x: 2.5, z: 2, facing: EntityFacing.south),
  };
  final bindings = <CinematicActorBinding>[
    CinematicActorBinding(
        actorId: 'guide',
        kind: CinematicActorBindingKind.mapEntity,
        mapEntityId: 'guide'),
    CinematicActorBinding(
        actorId: 'blocker',
        kind: CinematicActorBindingKind.mapEntity,
        mapEntityId: 'blocker'),
  ];
  bool locked = false;

  CinematicRuntimePlaybackController controller() =>
      CinematicRuntimePlaybackController(
          sink: SpatialCinematicRuntimePlaybackSink(
        project: _Host().project,
        activeMap: () => map,
        readActor: (binding) => poses[binding.actorId],
        writeActor: (binding, pose) => poses[binding.actorId] = pose,
        readCamera: () => null,
        writeCamera: (pose) {},
        setInputLocked: (value) => locked = value,
        onCompletedPoses: (poses) {},
        canTraverse: (actor, ax, az, bx, bz, simulated) {
          final candidates = simulated.isEmpty
              ? {
                  for (final binding in bindings)
                    binding: poses[binding.actorId]!
                }
              : simulated;
          return candidates.entries.every((entry) =>
              entry.key.actorId == actor.actorId ||
              (entry.value.x - bx).abs() >= .75 ||
              (entry.value.z - bz).abs() >= .5);
        },
      ));

  CinematicAsset asset({bool initialPlacement = false}) => CinematicAsset(
      id: 'two-actors',
      title: 'Two actors',
      mapId: 'village',
      requiredActors: [
        for (final binding in bindings)
          CinematicActorRef(actorId: binding.actorId)
      ],
      movementTargets: [
        for (final id in ['out', 'end'])
          CinematicMovementTargetRef(targetId: id, label: id)
      ],
      stageContext: CinematicStageContext(
          actorBindings: bindings,
          movementTargetBindings: [
            for (final id in ['out', 'end'])
              CinematicMovementTargetBinding(
                  targetId: id,
                  kind: CinematicMovementTargetBindingKind.stagePoint,
                  sourceId: id)
          ],
          stagePoints: [
            CinematicStagePoint(id: 'out', label: 'Out', x: 2.5, y: 4),
            CinematicStagePoint(id: 'end', label: 'End', x: 4, y: 2)
          ],
          initialPlacements: [
            if (initialPlacement)
              CinematicActorInitialPlacement(
                  actorId: 'blocker',
                  kind: CinematicActorInitialPlacementKind.stagePoint,
                  stagePointId: 'out')
          ]),
      timeline: CinematicTimeline(steps: [
        if (!initialPlacement) _move('clear', 'blocker', 'out'),
        _move('cross', 'guide', 'end'),
      ]));

  CinematicTimelineStep _move(String id, String actor, String target) =>
      CinematicTimelineStep(
          id: id,
          kind: CinematicTimelineStepKind.actorMove,
          actorId: actor,
          targetId: target,
          durationMs: 1000,
          metadata: const {
            'actor.movementMode': 'walk',
            'actor.pathMode': 'direct'
          });
}

CinematicAsset _asset({bool manual = false, bool withCamera = false}) =>
    CinematicAsset(
        id: 'promenade',
        title: 'Promenade',
        mapId: 'village',
        requiredActors: [CinematicActorRef(actorId: 'guide')],
        movementTargets: [
          CinematicMovementTargetRef(targetId: 'end', label: 'End')
        ],
        stageContext: CinematicStageContext(
          actorBindings: [
            CinematicActorBinding(
                actorId: 'guide',
                kind: CinematicActorBindingKind.mapEntity,
                mapEntityId: 'npc-guide'),
          ],
          movementTargetBindings: [
            CinematicMovementTargetBinding(
                targetId: 'end',
                kind: CinematicMovementTargetBindingKind.stagePoint,
                sourceId: 'end'),
          ],
          stagePoints: [
            CinematicStagePoint(id: 'end', label: 'End', x: 4, y: 3),
            if (manual)
              CinematicStagePoint(id: 'turn', label: 'Turn', x: 4, y: 2),
          ],
          manualPaths: [
            if (manual)
              CinematicManualPath(
                  id: 'path',
                  label: 'Path',
                  ownerActorMoveStepId: 'walk',
                  waypointStagePointIds: ['turn']),
          ],
        ),
        timeline: CinematicTimeline(steps: [
          if (withCamera)
            CinematicTimelineStep(
                id: 'camera',
                kind: CinematicTimelineStepKind.camera,
                durationMs: 1000,
                metadata: const {
                  'camera.mode': 'focus',
                  'camera.targetKind': 'stagePoint',
                  'camera.targetStagePointId': 'end',
                  'camera.zoomPreset': 'close',
                }),
          CinematicTimelineStep(
              id: 'walk',
              kind: CinematicTimelineStepKind.actorMove,
              actorId: 'guide',
              targetId: 'end',
              durationMs: 1000,
              metadata: {
                'actor.movementMode': 'walk',
                'actor.pathMode': manual ? 'manual' : 'direct',
              }),
        ]));

CinematicAsset _precisionAsset({
  required CinematicActorBindingKind kind,
  required double x,
  required bool initialPlacement,
}) {
  final base = _asset(manual: true);
  return base.copyWith(
      stageContext: CinematicStageContext(
          actorBindings: [
            CinematicActorBinding(
                actorId: 'guide',
                kind: kind,
                mapEntityId: kind == CinematicActorBindingKind.mapEntity
                    ? 'npc-guide'
                    : null),
          ],
          movementTargetBindings: base.stageContext!.movementTargetBindings,
          stagePoints: [
            CinematicStagePoint(id: 'end', label: 'End', x: x, y: 3),
            CinematicStagePoint(id: 'turn', label: 'Turn', x: 3.2, y: 2),
          ],
          manualPaths:
              initialPlacement ? const [] : base.stageContext!.manualPaths,
          initialPlacements: [
            if (initialPlacement)
              CinematicActorInitialPlacement(
                  actorId: 'guide',
                  kind: CinematicActorInitialPlacementKind.stagePoint,
                  stagePointId: 'end'),
          ]),
      timeline: initialPlacement
          ? CinematicTimeline(steps: [
              CinematicTimelineStep(
                  id: 'wait',
                  kind: CinematicTimelineStepKind.wait,
                  durationMs: 1000),
            ])
          : base.timeline);
}
