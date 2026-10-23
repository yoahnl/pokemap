import 'dart:async';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  test('player map placement keeps current pose facing and camera before waiting', () async {
    final host = _FakeHost();
    host.actors['hero']!.setFacing(EntityFacing.west);
    host.cameraPosition = Vector2(7, 9);
    final base = _visualAsset(steps: [CinematicTimelineStep(id: 'pause', kind: CinematicTimelineStepKind.wait, durationMs: 100)]);
    final asset = CinematicAsset.fromJson({...base.toJson(), 'stageContext': {...base.stageContext!.toJson(),
      'initialPlacements': [{'actorId': 'hero', 'kind': 'fromMapEntity'}],
    }});
    final controller = CinematicRuntimePlaybackController(sink: FlameCinematicRuntimePlaybackSink(host: host));
    addTearDown(() { controller.cancel(); });
    final completion = controller.play(asset);
    expect(host.actors['hero']!.focusPoint, Vector2(20, 20));
    expect(host.actors['hero']!.facing, EntityFacing.west);
    expect(host.cameraPosition, Vector2(7, 9));
    controller.update(const Duration(milliseconds: 50));
    expect(host.actors['hero']!.facing, EntityFacing.west);
    expect(host.cameraPosition, Vector2(7, 9));
    controller.cancel();
    expect((await completion).success, isFalse);
    expect(host.actors['hero']!.focusPoint, Vector2(20, 20));
    expect(host.actors['hero']!.facing, EntityFacing.west);
    expect(host.cameraPosition, Vector2(7, 9));
    expect(host.inputLocked, isFalse);
  });

  test('relative jump lands from the current actor origin on each replay', () async {
    final host = _FakeHost();
    final base = _visualAsset(steps: [_actorMoveStep()]);
    final asset = CinematicAsset.fromJson({...base.toJson(),
      'actorCompletionPolicy': 'keepFinal',
      'timeline': {'steps': [{'id': 'jump-relative', 'kind': 'actorJump', 'actorId': 'hero',
        'targetId': 'lighthouse', 'durationMs': 500, 'metadata': {'actor.jumpHeightCells': '1'}}]},
      'stageContext': {...base.stageContext!.toJson(), 'stagePoints': [
        {'id': 'lighthouse_point', 'label': 'Offset', 'x': -1.0, 'y': 0.0, 'relativeToActorId': 'hero'},
      ]},
    });
    final controller = CinematicRuntimePlaybackController(sink: FlameCinematicRuntimePlaybackSink(host: host));
    for (final origin in [Vector2(20, 20), Vector2(40, 30)]) {
      host.actors['hero']!.setFocusPoint(origin);
      final result = controller.play(asset);
      controller.update(const Duration(milliseconds: 500));
      expect((await result).success, isTrue);
      expect(host.actors['hero']!.focusPoint, origin + Vector2(-1, 0));
    }
  });

  test('relative origin with an authored teleport refuses before input capture', () async {
    final host = _FakeHost();
    final base = _visualAsset(steps: [_actorMoveStep()]);
    final asset = CinematicAsset.fromJson({...base.toJson(),
      'stageContext': {...base.stageContext!.toJson(), 'stagePoints': [
        {'id': 'lighthouse_point', 'label': 'Offset', 'x': 2.0, 'y': 0.0, 'relativeToActorId': 'hero'},
        {'id': 'start', 'label': 'Start', 'x': 100.0, 'y': 100.0},
      ], 'initialPlacements': [{'actorId': 'hero', 'kind': 'stagePoint', 'stagePointId': 'start'}]},
    });
    final controller = CinematicRuntimePlaybackController(sink: FlameCinematicRuntimePlaybackSink(host: host));
    expect((await controller.play(asset)).success, isFalse);
    expect(host.events, isEmpty);
    expect(host.actors['hero']!.focusPoint, Vector2(20, 20));
  });

  test(
    'actor-relative targets and waypoints replay from each playback origin',
    () async {
      final host = _FakeHost()
        ..stageOffset = Vector2(100, 200)
        ..stageCell = Vector2(24, 40);
      final base = _visualAsset(steps: [_actorMoveStep()]);
      final asset = CinematicAsset.fromJson({
        ...base.toJson(),
        'actorCompletionPolicy': 'keepFinal',
        'timeline': {
          'steps': [
            {
              ..._actorMoveStep().toJson(),
              'metadata': {
                ..._actorMoveStep().metadata,
                cinematicTimelineActorPathModeMetadataKey: 'manual',
              },
            },
          ],
        },
        'stageContext': {
          ...base.stageContext!.toJson(),
          'stagePoints': [
            {
              'id': 'lighthouse_point',
              'label': 'Offset',
              'x': 2.0,
              'y': -1.0,
              'relativeToActorId': 'hero',
            },
            {
              'id': 'corner',
              'label': 'Corner',
              'x': 1.0,
              'y': 0.0,
              'relativeToActorId': 'hero',
            },
          ],
          'manualPaths': [
            {
              'id': 'path',
              'label': 'Path',
              'ownerActorMoveStepId': 'move',
              'waypointStagePointIds': ['corner'],
            },
          ],
        },
      });
      final controller = CinematicRuntimePlaybackController(
        sink: FlameCinematicRuntimePlaybackSink(host: host),
      );
      for (final origin in [Vector2(20, 20), Vector2(40, 30)]) {
        host.actors['hero']!.setFocusPoint(origin);
        final completion = controller.play(
          CinematicAsset.fromJson(asset.toJson()),
        );
        expect(host.actors['hero']!.focusPoint, origin);
        controller.update(const Duration(milliseconds: 100));
        expect((await completion).success, isTrue);
        expect(host.actors['hero']!.focusPoint, origin + Vector2(48, -40));
      }
      host.actors['hero']!.setFocusPoint(Vector2(50, 50));
      final cancelled = controller.play(asset);
      controller.update(const Duration(milliseconds: 50));
      controller.cancel();
      expect((await cancelled).success, isFalse);
      expect(host.actors['hero']!.focusPoint, Vector2(50, 50));
      expect(host.inputLocked, isFalse);
    },
  );

  test(
    'relative target refuses a missing origin before capture or input lock',
    () async {
      final host = _FakeHost();
      final base = _visualAsset(steps: [_actorMoveStep()]);
      final asset = CinematicAsset.fromJson({
        ...base.toJson(),
        'stageContext': {
          ...base.stageContext!.toJson(),
          'stagePoints': [
            {
              'id': 'lighthouse_point',
              'label': 'Offset',
              'x': 2.0,
              'y': 0.0,
              'relativeToActorId': 'missing',
            },
          ],
        },
      });
      final controller = CinematicRuntimePlaybackController(
        sink: FlameCinematicRuntimePlaybackSink(host: host),
      );
      expect((await controller.play(asset)).success, isFalse);
      expect(host.events, isEmpty);
      expect(host.actors['hero']!.focusPoint, Vector2(20, 20));
    },
  );

  test('resolved media channel conflict rejects before capturing or locking', () async {
    final host = _FakeHost();
    final media = _BlockingMediaPort();
    final controller = CinematicRuntimePlaybackController(sink: FlameCinematicRuntimePlaybackSink(
        host: host, mediaPlaybackPort: media, mediaAssets: _parallelMediaAssets(shared: true)));
    final result = await controller.play(_parallelMediaAsset());
    expect(result.success, isFalse);
    expect(media.captures, 0);
    expect(media.commands, isEmpty);
    expect(host.inputLocked, isFalse);
  });

  for (final sameKind in [false, true]) {
    test('distinct media channels start concurrently sameKind=$sameKind', () async {
      final host = _FakeHost();
      final media = _BlockingMediaPort()..blockAudio = true;
      final controller = CinematicRuntimePlaybackController(sink: FlameCinematicRuntimePlaybackSink(
          host: host, mediaPlaybackPort: media,
          mediaAssets: _parallelMediaAssets(shared: false, sameKind: sameKind)));
      final completion = controller.play(_parallelMediaAsset(sameKind: sameKind));
      await Future<void>.delayed(Duration.zero);
      expect(media.commands.map((command) => command.assetId), ['a', 'b']);
      expect(controller.pause(), isFalse);
      expect((await controller.seek(Duration.zero)).status,
          CinematicRuntimeSeekStatus.unsupportedTimeline);
      media.audioGate.complete();
      await Future<void>.delayed(Duration.zero);
      controller.update(const Duration(seconds: 1));
      expect((await completion).success, isTrue);
      expect(media.restores, 1);
      expect(host.inputLocked, isFalse);
    });
  }

  test('FX cancellation stays ordered before a subsequent spawn on its channel', () async {
    final media = _BlockingMediaPort()..blockFxCancel = true;
    final host = _FakeHost();
    final controller = CinematicRuntimePlaybackController(sink: FlameCinematicRuntimePlaybackSink(
      host: host, mediaPlaybackPort: media,
      mediaAssets: [CinematicMediaAsset(id: 'fx', label: 'FX',
          kind: CinematicMediaAssetKind.cinematicFx, relativePath: 'fx/test.json', channel: 'weather')],
    ));
    final asset = _visualAsset(steps: [
      for (final id in ['first', 'second']) CinematicTimelineStep(id: id,
          kind: CinematicTimelineStepKind.fx, assetRef: 'fx', durationMs: 100),
    ]);
    final completion = controller.play(asset);
    await Future<void>.delayed(Duration.zero);
    controller.update(const Duration(milliseconds: 100));
    await Future<void>.delayed(Duration.zero);
    expect(media.commands.where((command) =>
        command.kind == CinematicMediaPlaybackCommandKind.spawnFx), hasLength(1));
    media.fxCancelGate.complete();
    await Future<void>.delayed(Duration.zero);
    expect(media.commands.where((command) =>
        command.kind == CinematicMediaPlaybackCommandKind.spawnFx), hasLength(2));
    controller.update(const Duration(milliseconds: 100));
    expect((await completion).success, isTrue);
  });

  test('parallel dialogue waits for player confirmation after its duration', () async {
    final host = _FakeHost();
    final base = _visualAsset();
    final move = _actorMoveStep();
    final asset = CinematicAsset.fromJson({...base.toJson(), 'timeline': {'steps': [
      {...move.toJson(), 'durationMs': 1000, 'parallelGroupId': 'pair'},
      {'id': 'dialogue', 'kind': 'dialogueLine', 'durationMs': 1000,
        'dialogueText': 'Continue', 'parallelGroupId': 'pair'},
    ]}});
    final sink = FlameCinematicRuntimePlaybackSink(host: host);
    final controller = CinematicRuntimePlaybackController(sink: sink);
    final completion = controller.play(asset);
    controller.update(const Duration(seconds: 1));
    expect(controller.isPlaying, isTrue);
    expect(host.dialogueLine, 'Continue');
    expect(sink.signalDialogueLineComplete(), isTrue);
    controller.update(Duration.zero);
    expect((await completion).success, isTrue);
    expect(host.inputLocked, isFalse);
  });

  test('two actors and camera advance together from a common group snapshot', () async {
    final host = _FakeHost();
    final base = _visualAsset();
    final actorMove = _actorMoveStep();
    final camera = base.timeline.steps.firstWhere((step) => step.kind == CinematicTimelineStepKind.camera);
    final asset = CinematicAsset.fromJson({...base.toJson(),
      'timeline': {'steps': [
        {...actorMove.toJson(), 'durationMs': 1000, 'parallelGroupId': 'together'},
        {...actorMove.toJson(), 'id': 'npc-move', 'actorId': 'lysa',
          'durationMs': 1000, 'parallelGroupId': 'together'},
        {...camera.toJson(), 'durationMs': 1500, 'parallelGroupId': 'together'},
      ]},
    });
    final controller = CinematicRuntimePlaybackController(
        sink: FlameCinematicRuntimePlaybackSink(host: host));
    final completion = controller.play(asset);
    controller.update(const Duration(milliseconds: 500));
    expect(host.actors['hero']!.focusPoint, Vector2(60, 30));
    expect(host.actors['npc']!.focusPoint, Vector2(70, 30));
    expect(host.cameraPosition.x, closeTo(10 + 10 / 3, .000001));
    expect(host.cameraPosition.y, closeTo(10 + 10 / 3, .000001));
    controller.update(const Duration(milliseconds: 1000));
    expect((await completion).success, isTrue);
    expect(host.actors['hero']!.focusPoint, Vector2(20, 20));
    expect(host.actors['npc']!.focusPoint, Vector2(40, 20));
    expect(host.cameraPosition, Vector2(10, 10));
  });

  for (final keepFacing in [false, true]) {
    test('jump has a separate lift and exact landing preserve=$keepFacing', () async {
      final host = _FakeHost();
      final base = _visualAsset(steps: [_actorMoveStep()]);
      final asset = CinematicAsset.fromJson({...base.toJson(),
        'actorCompletionPolicy': 'keepFinal', 'timeline': {'steps': [
          {'id': 'jump', 'kind': 'actorJump', 'actorId': 'hero',
            'targetId': base.timeline.steps.single.targetId, 'durationMs': 1000,
            'metadata': {'actor.jumpHeightCells': '0.5',
              'actor.facingMode': keepFacing ? 'preserve' : 'followMovement'}},
        ]},
      });
      final controller = CinematicRuntimePlaybackController(
          sink: FlameCinematicRuntimePlaybackSink(host: host));
      final completion = controller.play(asset);
      controller.update(const Duration(milliseconds: 500));
      expect(host.actors['hero']!.focusPoint, Vector2(60, 30));
      expect(host.actors['hero']!.jumpLift, .5);
      expect(host.actors['hero']!.facing, keepFacing ? EntityFacing.north : EntityFacing.east);
      controller.update(const Duration(milliseconds: 500));
      expect((await completion).success, isTrue);
      expect(host.actors['hero']!.focusPoint, Vector2(100, 40));
      expect(host.actors['hero']!.jumpLift, 0);
    });
  }

  test('occupied landing after takeoff fails and restores the initial pose', () async {
    final host = _FakeHost();
    final base = _visualAsset(steps: [_actorMoveStep()]);
    final asset = CinematicAsset.fromJson({...base.toJson(),
      'timeline': {'steps': [
        {'id': 'jump', 'kind': 'actorJump', 'actorId': 'hero',
          'targetId': base.timeline.steps.single.targetId, 'durationMs': 1000,
          'metadata': {'actor.jumpHeightCells': '0.5'}},
      ]},
    });
    final controller = CinematicRuntimePlaybackController(
        sink: FlameCinematicRuntimePlaybackSink(host: host));
    final completion = controller.play(asset);
    controller.update(const Duration(milliseconds: 500));
    expect(host.lastValidatedPoses, hasLength(2));
    host.rejectPoses = true;
    controller.update(const Duration(milliseconds: 500));
    expect((await completion).success, isFalse);
    expect(host.actors['hero']!.focusPoint, Vector2(20, 20));
    expect(host.actors['hero']!.jumpLift, 0);
    expect(host.inputLocked, isFalse);
  });

  test('cleanup failure prevents final pose publication', () async {
    final host = _FakeHost();
    final base = _visualAsset(steps: [_actorMoveStep()]);
    final controller = CinematicRuntimePlaybackController(
        sink: FlameCinematicRuntimePlaybackSink(host: host));
    final completion = controller.play(CinematicAsset.fromJson({
      ...base.toJson(), 'actorCompletionPolicy': 'keepFinal',
    }));
    host.throwWhenClearingDialogue = true;
    controller.update(const Duration(milliseconds: 100));
    expect((await completion).success, isFalse);
    expect(host.poseCommitCount, 0);
    expect(host.actors['hero']!.focusPoint, Vector2(20, 20));
  });

  test('failed final pose publication restores actors and releases ownership', () async {
    final host = _FakeHost()..throwWhenCommittingPoses = true;
    final base = _visualAsset(steps: [_actorMoveStep()]);
    final asset = CinematicAsset.fromJson({
      ...base.toJson(), 'actorCompletionPolicy': 'keepFinal',
    });
    final controller = CinematicRuntimePlaybackController(
        sink: FlameCinematicRuntimePlaybackSink(host: host));
    final completion = controller.play(asset);
    controller.update(const Duration(milliseconds: 100));
    expect((await completion).success, isFalse);
    expect(host.actors['hero']!.focusPoint, Vector2(20, 20));
    expect(host.actors['hero']!.facing, EntityFacing.north);
    expect(host.inputLocked, isFalse);
    expect(controller.isPlaying, isFalse);
  });

  test('old snapshots cannot restore actors in a replacement activation', () async {
    final host = _FakeHost();
    final controller = CinematicRuntimePlaybackController(
        sink: FlameCinematicRuntimePlaybackSink(host: host));
    final completion = controller.play(_visualAsset(steps: [_actorMoveStep()]));
    controller.update(const Duration(milliseconds: 50));
    host.activation = Object();
    host.actors['hero']!.setFocusPoint(Vector2(7, 8));
    controller.cancel();
    await completion;
    expect(host.actors['hero']!.focusPoint, Vector2(7, 8));
    expect(host.poseCommitCount, 0);
  });

  test('keepFinal retains actor position and facing after successful playback',
      () async {
    final host = _FakeHost();
    final base = _visualAsset(steps: [_actorMoveStep()]);
    final asset = CinematicAsset.fromJson({
      ...base.toJson(),
      'actorCompletionPolicy': 'keepFinal',
    });
    final controller = CinematicRuntimePlaybackController(
        sink: FlameCinematicRuntimePlaybackSink(host: host));
    final completion = controller.play(asset);
    controller.update(const Duration(milliseconds: 100));
    expect((await completion).success, isTrue);
    expect(host.actors['hero']!.focusPoint, Vector2(100, 40));
    expect(host.actors['hero']!.facing, EntityFacing.east);
    expect(host.inputLocked, isFalse);
  });

  for (final target in [
    (facing: EntityFacing.north, x: 20.0, y: 40.0),
    (facing: EntityFacing.south, x: 20.0, y: 0.0),
    (facing: EntityFacing.east, x: 0.0, y: 20.0),
    (facing: EntityFacing.west, x: 40.0, y: 20.0),
  ]) {
    test('preserves ${target.facing.name} while moving backwards', () async {
      final host = _FakeHost();
      host.actors['hero']!.setFacing(target.facing);
      final base = _visualAsset(steps: [_actorMoveStep()]);
      final asset = CinematicAsset.fromJson({
        ...base.toJson(),
        'stageContext': {
          ...base.stageContext!.toJson(),
          'stagePoints': [
            {
              'id': 'lighthouse_point',
              'label': 'End',
              'x': target.x,
              'y': target.y,
            },
          ],
        },
        'timeline': {
          'steps': [
            {
              ...base.timeline.steps.single.toJson(),
              'metadata': {
                ...base.timeline.steps.single.metadata,
                'actor.facingMode': 'preserve',
              },
            },
            {'id': 'hold', 'kind': 'wait', 'durationMs': 10},
          ],
        },
      });
      final controller = CinematicRuntimePlaybackController(
        sink: FlameCinematicRuntimePlaybackSink(host: host),
      );
      final completion = controller.play(asset);
      controller.update(const Duration(milliseconds: 50));
      expect(host.actors['hero']!.facing, target.facing);
      expect(host.actors['hero']!.motion, CharacterAnimationState.walk);
      controller.update(const Duration(milliseconds: 50));
      expect(host.actors['hero']!.focusPoint, Vector2(target.x, target.y));
      expect(host.actors['hero']!.facing, target.facing);
      controller.cancel();
      await completion;
      expect(host.actors['hero']!.focusPoint, Vector2(20, 20));
      expect(host.actors['hero']!.facing, target.facing);
    });
  }

  test(
      'authored initial placement is temporary and cancellation restores actor',
      () async {
    final host = _FakeHost();
    final base = _visualAsset(steps: [_actorMoveStep()]);
    final context = base.stageContext!;
    final asset = CinematicAsset.fromJson({
      ...base.toJson(),
      'stageContext': {
        ...context.toJson(),
        'stagePoints': [
          ...context.stagePoints.map((p) => p.toJson()),
          {'id': 'start', 'label': 'Start', 'x': 8, 'y': 9}
        ],
        'initialPlacements': [
          {'actorId': 'hero', 'kind': 'stagePoint', 'stagePointId': 'start'}
        ],
      }
    });
    final before = asset.toJson();
    final controller = CinematicRuntimePlaybackController(
        sink: FlameCinematicRuntimePlaybackSink(host: host));
    final completion = controller.play(asset);
    expect(host.actors['hero']!.focusPoint, Vector2(8, 9));
    controller.cancel();
    await completion;
    expect(host.actors['hero']!.focusPoint, Vector2(20, 20));
    expect(host.actors['hero']!.facing, EntityFacing.north);
    expect(asset.toJson(), before);
  });
  test('move plays walking animation then returns to idle', () async {
    final host = _FakeHost();
    final controller = CinematicRuntimePlaybackController(
        sink: FlameCinematicRuntimePlaybackSink(host: host));
    final completion = controller.play(_visualAsset(steps: [
      _actorMoveStep(),
      CinematicTimelineStep(
          id: 'hold', kind: CinematicTimelineStepKind.wait, durationMs: 10)
    ]));
    controller.update(const Duration(milliseconds: 50));
    expect(host.actors['hero']!.motion, CharacterAnimationState.walk);
    expect(host.actors['hero']!.facing, EntityFacing.east);
    controller.update(const Duration(milliseconds: 50));
    expect(host.actors['hero']!.motion, CharacterAnimationState.idle);
    controller.cancel();
    await completion;
    expect(host.actors['hero']!.motion, CharacterAnimationState.idle);
  });
  test('each cinematic move starts a fresh animation phase', () async {
    final host = _FakeHost();
    final first = _actorMoveStep();
    final second =
        CinematicTimelineStep.fromJson({...first.toJson(), 'id': 'second'});
    final controller = CinematicRuntimePlaybackController(
        sink: FlameCinematicRuntimePlaybackSink(host: host));
    final completion = controller.play(_visualAsset(steps: [first, second]));
    expect(host.actors['hero']!.restoreCount, 1);
    controller.update(const Duration(milliseconds: 100));
    expect(host.actors['hero']!.restoreCount, 2);
    controller.cancel();
    await completion;
  });
  test('manual route uses distance rather than equal time per segment',
      () async {
    final host = _FakeHost();
    final base = _visualAsset(steps: [_actorMoveStep()]);
    final step = base.timeline.steps.single;
    final asset = CinematicAsset.fromJson({
      ...base.toJson(),
      'stageContext': {
        ...base.stageContext!.toJson(),
        'stagePoints': [
          {'id': 'lighthouse_point', 'label': 'End', 'x': 30, 'y': 20},
          {'id': 'near', 'label': 'Near', 'x': 21, 'y': 20}
        ],
        'manualPaths': [
          {
            'id': 'route',
            'label': 'Route',
            'ownerActorMoveStepId': step.id,
            'waypointStagePointIds': ['near']
          }
        ],
      },
      'timeline': {
        'steps': [
          {
            ...step.toJson(),
            'metadata': {...step.metadata, 'actor.pathMode': 'manual'}
          }
        ]
      },
    });
    final controller = CinematicRuntimePlaybackController(
        sink: FlameCinematicRuntimePlaybackSink(host: host));
    final completion = controller.play(asset);
    controller.update(const Duration(milliseconds: 50));
    expect(host.actors['hero']!.focusPoint, Vector2(25, 20));
    controller.cancel();
    await completion;
  });

  group('FlameCinematicRuntimePlaybackSink', () {
    test('preflight rejects an unavailable actor without runtime mutation', () {
      final host = _FakeHost()..actors.remove('npc');
      final sink = FlameCinematicRuntimePlaybackSink(host: host);

      final result = sink.preflight(_visualAsset());

      expect(result.isReady, isFalse);
      expect(
        result.errorCode,
        SceneCinematicRuntimeAwaitableErrorCode.invalidActorReference,
      );
      expect(host.inputLocked, isFalse);
      expect(host.events, isEmpty);
    });

    test('preflight rejects an incomplete map actor binding without throwing',
        () {
      final host = _FakeHost();
      final sink = FlameCinematicRuntimePlaybackSink(host: host);
      final asset = _visualAsset(
        stageContext: CinematicStageContext(
          actorBindings: <CinematicActorBinding>[
            CinematicActorBinding(
              actorId: 'lysa',
              kind: CinematicActorBindingKind.mapEntity,
            ),
          ],
        ),
      );

      final result = sink.preflight(asset);

      expect(result.isReady, isFalse);
      expect(
        result.errorCode,
        SceneCinematicRuntimeAwaitableErrorCode.invalidActorReference,
      );
      expect(host.inputLocked, isFalse);
      expect(host.events, isEmpty);
    });

    test('renders the eight V1 beats and restores the runtime atomically',
        () async {
      final host = _FakeHost();
      final sink = FlameCinematicRuntimePlaybackSink(host: host);
      final controller = CinematicRuntimePlaybackController(sink: sink);

      final completion = controller.play(_visualAsset());

      expect(host.inputLocked, isTrue);
      controller.update(const Duration(milliseconds: 10));
      expect(controller.currentStep?.kind, CinematicTimelineStepKind.camera);

      controller.update(const Duration(milliseconds: 50));
      expect(host.cameraPosition, Vector2(15, 15));
      expect(host.cameraVisibleGameSize, Vector2(80, 64));

      controller.update(const Duration(milliseconds: 50));
      expect(controller.currentStep?.kind, CinematicTimelineStepKind.actorMove);
      controller.update(const Duration(milliseconds: 50));
      expect(host.actors['hero']!.focusPoint, Vector2(60, 30));

      controller.update(const Duration(milliseconds: 50));
      expect(
          controller.currentStep?.kind, CinematicTimelineStepKind.actorEmote);
      expect(host.emoteId, 'heart');
      expect(host.actors['npc']!.facing, EntityFacing.east);

      controller.update(const Duration(milliseconds: 100));
      expect(
        controller.currentStep?.kind,
        CinematicTimelineStepKind.dialogueLine,
      );
      expect(host.dialogueLine, 'Le phare nous attend.');
      expect(sink.isAwaitingDialogueLineAdvance, isTrue);

      expect(sink.signalDialogueLineComplete(), isTrue);
      controller.update(Duration.zero);
      expect(controller.currentStep?.kind, CinematicTimelineStepKind.fade);
      controller.update(const Duration(milliseconds: 50));
      expect(host.fadeOpacity, closeTo(0.5, 0.001));

      controller.update(const Duration(milliseconds: 50));
      expect(controller.currentStep?.kind, CinematicTimelineStepKind.shake);
      controller.update(const Duration(milliseconds: 50));
      expect(host.cameraPosition, isNot(Vector2(20, 20)));

      controller.update(const Duration(milliseconds: 50));
      final result = await completion;

      expect(result.success, isTrue);
      expect(host.inputLocked, isFalse);
      expect(host.cameraPosition, Vector2(10, 10));
      expect(host.cameraVisibleGameSize, Vector2(100, 80));
      expect(host.actors['hero']!.focusPoint, Vector2(20, 20));
      expect(host.actors['npc']!.facing, EntityFacing.south);
      expect(host.dialogueLine, isNull);
      expect(host.fadeOpacity, isNull);
      expect(host.emoteId, isNull);
    });

    test('cancellation restores camera actors overlays and input once',
        () async {
      final host = _FakeHost();
      final sink = FlameCinematicRuntimePlaybackSink(host: host);
      final controller = CinematicRuntimePlaybackController(sink: sink);
      final asset = _visualAsset(
        steps: <CinematicTimelineStep>[
          _actorMoveStep(),
        ],
      );

      final completion = controller.play(asset);
      controller.update(const Duration(milliseconds: 50));
      expect(host.actors['hero']!.focusPoint, Vector2(60, 30));

      expect(controller.cancel(), isTrue);
      expect(controller.cancel(), isFalse);
      final result = await completion;

      expect(
        result.errorCode,
        SceneCinematicRuntimeAwaitableErrorCode.cancelled,
      );
      expect(host.inputLocked, isFalse);
      expect(host.actors['hero']!.focusPoint, Vector2(20, 20));
      expect(host.inputUnlockCount, 1);
    });

    test('restoration keeps unlocking input when overlay cleanup throws',
        () async {
      final host = _FakeHost()..throwWhenClearingDialogue = true;
      final sink = FlameCinematicRuntimePlaybackSink(host: host);
      final controller = CinematicRuntimePlaybackController(sink: sink);
      final completion = controller.play(
        _visualAsset(
          steps: <CinematicTimelineStep>[
            CinematicTimelineStep(
              id: 'line',
              kind: CinematicTimelineStepKind.dialogueLine,
              dialogueText: 'Toujours restaurer.',
            ),
          ],
        ),
      );

      expect(controller.cancel(), isTrue);
      final result = await completion;

      expect(
        result.errorCode,
        SceneCinematicRuntimeAwaitableErrorCode.sinkFailure,
      );
      expect(host.inputLocked, isFalse);
      expect(host.inputUnlockCount, 1);
      expect(host.cameraPosition, Vector2(10, 10));
      expect(host.actors['hero']!.focusPoint, Vector2(20, 20));
    });

    test('awaits custom character animation and restores Base', () async {
      final host = _FakeHost();
      final sink = FlameCinematicRuntimePlaybackSink(
        host: host,
        project: _characterAnimationProject(),
      );
      final controller = CinematicRuntimePlaybackController(sink: sink);
      final command = CharacterCustomAnimationRuntimeCommand(
        actorId: 'hero',
        definitionId: 'wave',
      );
      final asset = _visualAsset(
        steps: <CinematicTimelineStep>[
          buildCinematicCharacterCustomAnimationStep(
            id: 'wave-step',
            command: command,
          ),
        ],
      );

      final completion = controller.play(asset);
      expect(host.actors['hero']!.playedDefinitions, <String>['wave']);

      controller.update(const Duration(milliseconds: 299));
      expect(controller.isPlaying, isTrue);
      controller.update(const Duration(milliseconds: 1));

      expect((await completion).success, isTrue);
      expect(host.actors['hero']!.restoreCount, 1);
      expect(host.actors['hero']!.facing, EntityFacing.north);
      expect(host.emoteId, isNull);
    });
  });
}

final class _FakeHost implements FlameCinematicRuntimeHost, FlameCinematicPoseRuntimeHost {
  Object activation = Object();
  bool throwWhenCommittingPoses = false;
  bool rejectPoses = false;
  Map<CinematicActorBinding, FlameCinematicActorPose> lastValidatedPoses = const {};
  int poseCommitCount = 0;
  @override
  Object get cinematicActivationToken => activation;

  @override
  void validateCinematicActorPoses(Map<CinematicActorBinding, FlameCinematicActorPose> poses) {
    lastValidatedPoses = poses;
    if (rejectPoses) throw StateError('Landing occupied.');
  }

  @override
  void commitCinematicActorPoses(Map<CinematicActorBinding, FlameCinematicActorPose> poses) {
    if (throwWhenCommittingPoses) throw StateError('Pose publication failed.');
    poseCommitCount++;
  }
  bool ready = true;
  bool inputLocked = false;
  int inputUnlockCount = 0;
  bool throwWhenClearingDialogue = false;
  String? dialogueLine;
  String? emoteId;
  double? fadeOpacity;
  final List<String> events = <String>[];
  final Map<String, _FakeActor> actors = <String, _FakeActor>{
    'hero': _FakeActor(Vector2(20, 20), EntityFacing.north),
    'npc': _FakeActor(Vector2(40, 20), EntityFacing.south),
  };

  @override
  String get activeMapId => 'map_port';

  @override
  bool get isReady => ready;

  @override
  Vector2 cameraPosition = Vector2(10, 10);

  @override
  Vector2? cameraVisibleGameSize = Vector2(100, 80);

  @override
  Vector2 get sceneCenter => Vector2(50, 40);

  @override
  FlameCinematicRuntimeActorHandle? get playerActor => actors['hero'];

  @override
  FlameCinematicRuntimeActorHandle? mapEntityActor(String entityId) {
    return actors[entityId];
  }

  @override
  Vector2? mapEntityFocusPoint(String entityId) {
    return actors[entityId]?.focusPoint.clone();
  }

  Vector2 stageOffset = Vector2.zero();
  Vector2 stageCell = Vector2(1, 1);

  @override
  Vector2 stagePointFocusPoint(CinematicStagePoint point) {
    return Vector2(point.x * stageCell.x + stageOffset.x,
      point.y * stageCell.y + stageOffset.y);
  }

  @override
  void setCinematicInputLocked(bool locked) {
    inputLocked = locked;
    events.add('input:$locked');
    if (!locked) inputUnlockCount++;
  }

  @override
  void showCinematicActorEmote(
    FlameCinematicRuntimeActorHandle? actor,
    String? emoteId,
  ) {
    this.emoteId = emoteId;
    events.add('emote:${emoteId ?? '-'}');
  }

  @override
  void showCinematicDialogueLine(String? text) {
    if (text == null && throwWhenClearingDialogue) {
      throw StateError('dialogue cleanup failed');
    }
    dialogueLine = text;
    events.add('dialogue:${text ?? '-'}');
  }

  @override
  Future<void> playCinematicDialogueAsset(String dialogueId) async {
    events.add('dialogueAsset:$dialogueId');
  }

  @override
  void cancelCinematicDialogueAsset() {
    events.add('dialogueAsset:cancel');
  }

  @override
  void setCinematicFadeOpacity(double? opacity) {
    fadeOpacity = opacity;
    events.add('fade:${opacity ?? '-'}');
  }
}

final class _BlockingMediaPort implements CinematicMediaPlaybackPort {
  final commands = <CinematicMediaPlaybackCommand>[];
  final audioGate = Completer<void>();
  final fxCancelGate = Completer<void>();
  bool blockAudio = false, blockFxCancel = false;
  int captures = 0, restores = 0;

  @override
  Future<CinematicMediaPlaybackCheckpoint> captureCheckpoint() async {
    captures++;
    return CinematicMediaPlaybackCheckpoint();
  }

  @override
  Future<void> execute(CinematicMediaPlaybackCommand command) async {
    commands.add(command);
    if (blockAudio && command.kind == CinematicMediaPlaybackCommandKind.play) await audioGate.future;
    if (blockFxCancel && command.kind == CinematicMediaPlaybackCommandKind.cancelFx) await fxCancelGate.future;
  }

  @override
  Future<void> restore(CinematicMediaPlaybackCheckpoint checkpoint) async { restores++; }
}

CinematicAsset _parallelMediaAsset({bool sameKind = false}) => _visualAsset(steps: [
  CinematicTimelineStep(id: 'a', kind: CinematicTimelineStepKind.sound,
      assetRef: 'a', durationMs: 1000, parallelGroupId: 'media'),
  CinematicTimelineStep(id: 'b', kind: sameKind ? CinematicTimelineStepKind.sound
      : CinematicTimelineStepKind.music, assetRef: 'b', durationMs: 1000, parallelGroupId: 'media'),
]);

List<CinematicMediaAsset> _parallelMediaAssets({required bool shared, bool sameKind = false}) => [
  CinematicMediaAsset(id: 'a', label: 'A', kind: CinematicMediaAssetKind.sound,
      relativePath: 'audio/a.ogg', channel: shared ? 'shared' : 'a'),
  CinematicMediaAsset(id: 'b', label: 'B', kind: sameKind ? CinematicMediaAssetKind.sound
      : CinematicMediaAssetKind.music, relativePath: 'audio/b.ogg', channel: shared ? 'shared' : 'b'),
];

final class _FakeActor
    implements
        FlameCinematicCharacterAnimationActorHandle,
        FlameCinematicMotionActorHandle, FlameCinematicJumpActorHandle {
  _FakeActor(this.focusPoint, this.facing);
  double jumpLift = 0;

  @override
  void setJumpLift(double lift) => jumpLift = lift;

  @override
  Vector2 focusPoint;

  /// Un sprite de personnage de 32x48, la forme du projet.
  @override
  Vector2 visualSize = Vector2(32, 48);

  @override
  EntityFacing facing;
  final List<String> playedDefinitions = <String>[];
  int restoreCount = 0;

  @override
  String get actorId => 'fake';

  CharacterAnimationState motion = CharacterAnimationState.idle;

  @override
  void setMotion(EntityFacing facing, CharacterAnimationState state) {
    this.facing = facing;
    motion = state;
  }

  @override
  ProjectCharacterEntry get character => _characterAnimationCharacter();

  @override
  bool canPlayCustomAnimation(CharacterCustomAnimationClip clip) => true;

  @override
  void playCustomAnimation(CharacterCustomAnimationClip clip) {
    playedDefinitions.add(clip.definitionId);
    if (clip.direction != null) facing = clip.direction!;
  }

  @override
  void restoreBase(EntityFacing facing) {
    restoreCount += 1;
    this.facing = facing;
  }

  @override
  void setFacing(EntityFacing facing) {
    this.facing = facing;
    motion = CharacterAnimationState.idle;
  }

  @override
  void setFocusPoint(Vector2 focusPoint) {
    this.focusPoint = focusPoint.clone();
  }
}

ProjectManifest _characterAnimationProject() {
  return ProjectManifest(
    name: 'Cinematic custom animation',
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
    characterStudioCatalog: const ProjectCharacterStudioCatalog(
      customAnimationDefinitions: <CharacterCustomAnimationDefinition>[
        CharacterCustomAnimationDefinition(
          id: 'wave',
          displayName: 'Wave',
          mode: CharacterCustomAnimationMode.single,
        ),
      ],
    ),
  );
}

ProjectCharacterEntry _characterAnimationCharacter() {
  return const ProjectCharacterEntry(
    id: 'hero-character',
    name: 'Hero',
    tilesetId: 'hero',
    customAnimations: <CharacterCustomAnimationClip>[
      CharacterCustomAnimationClip(
        definitionId: 'wave',
        sourceAssetId: 'wave-source',
        frames: <CharacterAnimationFrame>[
          CharacterAnimationFrame(
            source: TilesetSourceRect(x: 0, y: 0, width: 24, height: 32),
            durationMs: 100,
          ),
          CharacterAnimationFrame(
            source: TilesetSourceRect(x: 24, y: 0, width: 24, height: 32),
            durationMs: 200,
          ),
        ],
      ),
    ],
  );
}

CinematicAsset _visualAsset({
  List<CinematicTimelineStep>? steps,
  CinematicStageContext? stageContext,
}) {
  return CinematicAsset(
    id: 'cinematic_port',
    actorCompletionPolicy: CinematicActorCompletionPolicy.restoreInitial,
    title: 'Port cinematic',
    mapId: 'map_port',
    requiredActors: <CinematicActorRef>[
      CinematicActorRef(actorId: 'hero'),
      CinematicActorRef(actorId: 'lysa'),
    ],
    movementTargets: <CinematicMovementTargetRef>[
      CinematicMovementTargetRef(targetId: 'lighthouse', label: 'Phare'),
    ],
    stageContext: stageContext ??
        CinematicStageContext(
          actorBindings: <CinematicActorBinding>[
            CinematicActorBinding(
              actorId: 'hero',
              kind: CinematicActorBindingKind.player,
            ),
            CinematicActorBinding(
              actorId: 'lysa',
              kind: CinematicActorBindingKind.mapEntity,
              mapEntityId: 'npc',
            ),
          ],
          movementTargetBindings: <CinematicMovementTargetBinding>[
            CinematicMovementTargetBinding(
              targetId: 'lighthouse',
              kind: CinematicMovementTargetBindingKind.stagePoint,
              sourceId: 'lighthouse_point',
            ),
          ],
          stagePoints: <CinematicStagePoint>[
            CinematicStagePoint(
              id: 'lighthouse_point',
              label: 'Phare',
              x: 100,
              y: 40,
            ),
          ],
        ),
    timeline: CinematicTimeline(
      steps: steps ??
          <CinematicTimelineStep>[
            CinematicTimelineStep(
              id: 'wait',
              kind: CinematicTimelineStepKind.wait,
              durationMs: 10,
            ),
            CinematicTimelineStep(
              id: 'camera',
              kind: CinematicTimelineStepKind.camera,
              durationMs: 100,
              metadata: const <String, String>{
                cinematicTimelineCameraModeMetadataKey: 'focus',
                cinematicTimelineCameraTargetKindMetadataKey: 'actor',
                cinematicTimelineCameraTargetActorIdMetadataKey: 'hero',
                cinematicTimelineCameraZoomPresetMetadataKey: 'close',
              },
            ),
            _actorMoveStep(),
            CinematicTimelineStep(
              id: 'face',
              kind: CinematicTimelineStepKind.actorFace,
              actorId: 'lysa',
              metadata: const <String, String>{
                cinematicTimelineActorDirectionMetadataKey: 'right',
              },
            ),
            CinematicTimelineStep(
              id: 'emote',
              kind: CinematicTimelineStepKind.actorEmote,
              durationMs: 100,
              actorId: 'lysa',
              metadata: const <String, String>{
                cinematicTimelineActorEmoteEmoteIdMetadataKey: 'heart',
              },
            ),
            CinematicTimelineStep(
              id: 'line',
              kind: CinematicTimelineStepKind.dialogueLine,
              dialogueText: 'Le phare nous attend.',
            ),
            CinematicTimelineStep(
              id: 'fade',
              kind: CinematicTimelineStepKind.fade,
              durationMs: 100,
              metadata: const <String, String>{
                cinematicTimelineFadeModeMetadataKey: 'fadeOut',
              },
            ),
            CinematicTimelineStep(
              id: 'shake',
              kind: CinematicTimelineStepKind.shake,
              durationMs: 100,
            ),
          ],
    ),
  );
}

CinematicTimelineStep _actorMoveStep() {
  return CinematicTimelineStep(
    id: 'move',
    kind: CinematicTimelineStepKind.actorMove,
    durationMs: 100,
    actorId: 'hero',
    targetId: 'lighthouse',
    metadata: const <String, String>{
      cinematicTimelineActorMovementModeMetadataKey: 'walk',
      cinematicTimelineActorPathModeMetadataKey: 'direct',
    },
  );
}
