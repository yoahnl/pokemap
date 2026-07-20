import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  group('CinematicRuntimePlaybackController', () {
    test('implements the existing awaitable cinematic player port', () async {
      final sink = _RecordingSink();
      final controller = CinematicRuntimePlaybackController(sink: sink);
      final asset = _asset(
        steps: <CinematicTimelineStep>[
          _step(CinematicTimelineStepKind.wait, durationMs: 10),
        ],
      );

      final completion = controller.playCinematic(
        SceneCinematicRuntimeRequest(
          requestId: 'request',
          createdAtEpochMs: 0,
          cinematicId: asset.id,
          asset: asset,
        ),
      );
      controller.update(const Duration(milliseconds: 10));

      expect(
        (await completion).status,
        SceneCinematicRuntimeAwaitableStatus.completed,
      );
      expect(controller, isA<SceneCinematicRuntimePlayer>());
    });

    test('executes the eight V1 step kinds strictly in authored order',
        () async {
      final sink = _RecordingSink()..recordUpdates = false;
      final controller = CinematicRuntimePlaybackController(sink: sink);
      final asset = _asset(
        steps: <CinematicTimelineStep>[
          for (final kind in const <CinematicTimelineStepKind>[
            CinematicTimelineStepKind.wait,
            CinematicTimelineStepKind.camera,
            CinematicTimelineStepKind.actorMove,
            CinematicTimelineStepKind.actorFace,
            CinematicTimelineStepKind.actorEmote,
            CinematicTimelineStepKind.dialogueLine,
            CinematicTimelineStepKind.fade,
            CinematicTimelineStepKind.shake,
          ])
            _step(kind, durationMs: 10),
        ],
      );

      final completion = controller.play(asset);
      controller.update(const Duration(milliseconds: 80));
      final result = await completion;

      expect(result.status, SceneCinematicRuntimeAwaitableStatus.completed);
      expect(
        sink.events,
        <String>[
          for (final kind in const <CinematicTimelineStepKind>[
            CinematicTimelineStepKind.wait,
            CinematicTimelineStepKind.camera,
            CinematicTimelineStepKind.actorMove,
            CinematicTimelineStepKind.actorFace,
            CinematicTimelineStepKind.actorEmote,
            CinematicTimelineStepKind.dialogueLine,
            CinematicTimelineStepKind.fade,
            CinematicTimelineStepKind.shake,
          ]) ...<String>['begin:${kind.name}', 'end:${kind.name}'],
          'restore:completed',
        ],
      );
    });

    test('does not advance before visual completion or duration elapses',
        () async {
      final sink = _RecordingSink();
      final controller = CinematicRuntimePlaybackController(sink: sink);
      final completion = controller.play(
        _asset(
          steps: <CinematicTimelineStep>[
            _step(CinematicTimelineStepKind.camera),
            _step(CinematicTimelineStepKind.wait, durationMs: 10),
          ],
        ),
      );

      controller.update(const Duration(seconds: 5));
      expect(controller.currentStep?.kind, CinematicTimelineStepKind.camera);
      expect(sink.events, <String>['begin:camera', 'update:camera']);
      expect(controller.isPlaying, isTrue);

      sink.visuallyCompletedKinds.add(CinematicTimelineStepKind.camera);
      controller.update(Duration.zero);
      expect(controller.currentStep?.kind, CinematicTimelineStepKind.wait);
      expect(
        sink.events,
        containsAllInOrder(<String>['end:camera', 'begin:wait']),
      );

      controller.update(const Duration(milliseconds: 10));
      expect(
        (await completion).status,
        SceneCinematicRuntimeAwaitableStatus.completed,
      );
    });

    test('preflight rejects a missing actor before any mutation', () async {
      final sink = _RecordingSink();
      final controller = CinematicRuntimePlaybackController(sink: sink);

      final result = await controller.play(
        _asset(
          steps: <CinematicTimelineStep>[
            CinematicTimelineStep(
              id: 'face_missing',
              kind: CinematicTimelineStepKind.actorFace,
              actorId: 'missing',
            ),
          ],
        ),
      );

      expect(
        result.errorCode,
        SceneCinematicRuntimeAwaitableErrorCode.invalidActorReference,
      );
      expect(sink.preflightCalls, 0);
      expect(sink.events, isEmpty);
    });

    test('preflight rejects cinematicOnly bindings before sink mutation',
        () async {
      final sink = _RecordingSink();
      final controller = CinematicRuntimePlaybackController(sink: sink);

      final result = await controller.play(
        _asset(
          bindingKind: CinematicActorBindingKind.cinematicOnly,
          steps: <CinematicTimelineStep>[
            _step(CinematicTimelineStepKind.actorEmote, durationMs: 10),
          ],
        ),
      );

      expect(
        result.errorCode,
        SceneCinematicRuntimeAwaitableErrorCode.unsupportedActorBinding,
      );
      expect(sink.preflightCalls, 0);
      expect(sink.events, isEmpty);
    });

    test('editorial markers are never emitted to the runtime sink', () async {
      final sink = _RecordingSink();
      final controller = CinematicRuntimePlaybackController(sink: sink);

      final completion = controller.play(
        _asset(
          steps: <CinematicTimelineStep>[
            _step(CinematicTimelineStepKind.wait, durationMs: 10),
            _step(CinematicTimelineStepKind.marker),
          ],
        ),
      );
      controller.update(const Duration(milliseconds: 10));
      final result = await completion;

      expect(result.success, isTrue);
      expect(sink.preflightCalls, 1);
      expect(sink.events, isNot(contains(contains('marker'))));
    });

    test('preflight rejects unsupported movement targets before sink mutation',
        () async {
      final sink = _RecordingSink();
      final controller = CinematicRuntimePlaybackController(sink: sink);
      final valid = _asset(
        steps: <CinematicTimelineStep>[
          _step(CinematicTimelineStepKind.actorMove, durationMs: 10),
        ],
      );
      final invalid = CinematicAsset(
        id: valid.id,
        title: valid.title,
        requiredActors: valid.requiredActors,
        movementTargets: valid.movementTargets,
        stageContext: CinematicStageContext(
          actorBindings: valid.stageContext!.actorBindings,
          movementTargetBindings: <CinematicMovementTargetBinding>[
            CinematicMovementTargetBinding(
              targetId: 'target',
              kind: CinematicMovementTargetBindingKind.abstractPoint,
            ),
          ],
        ),
        timeline: valid.timeline,
      );

      final result = await controller.play(invalid);

      expect(
        result.errorCode,
        SceneCinematicRuntimeAwaitableErrorCode.invalidTargetReference,
      );
      expect(sink.preflightCalls, 0);
      expect(sink.events, isEmpty);
    });

    test('sink preflight rejection stays mutation free and typed', () async {
      final sink = _RecordingSink()
        ..preflightResult = const CinematicRuntimeSinkPreflightResult.rejected(
          errorCode:
              SceneCinematicRuntimeAwaitableErrorCode.invalidActorReference,
          message: 'Actor is not mounted on the active map.',
        );
      final controller = CinematicRuntimePlaybackController(sink: sink);

      final result = await controller.play(
        _asset(
          steps: <CinematicTimelineStep>[
            _step(CinematicTimelineStepKind.wait, durationMs: 10),
          ],
        ),
      );

      expect(
        result.errorCode,
        SceneCinematicRuntimeAwaitableErrorCode.invalidActorReference,
      );
      expect(sink.preflightCalls, 1);
      expect(sink.events, isEmpty);
    });

    test('cancellation completes once and restores atomically', () async {
      final sink = _RecordingSink();
      final controller = CinematicRuntimePlaybackController(sink: sink);
      final completion = controller.play(
        _asset(
          steps: <CinematicTimelineStep>[
            _step(CinematicTimelineStepKind.camera),
          ],
        ),
      );

      expect(controller.cancel(message: 'test cancellation'), isTrue);
      expect(controller.cancel(message: 'duplicate cancellation'), isFalse);
      final result = await completion;

      expect(
        result.errorCode,
        SceneCinematicRuntimeAwaitableErrorCode.cancelled,
      );
      expect(sink.restoreCalls, 1);
      expect(sink.events.last, 'restore:cancelled');
      expect(controller.isPlaying, isFalse);
    });

    test('sink errors restore once and return a typed failure', () async {
      final sink = _RecordingSink()..throwOnUpdate = true;
      final controller = CinematicRuntimePlaybackController(sink: sink);
      final completion = controller.play(
        _asset(
          steps: <CinematicTimelineStep>[
            _step(CinematicTimelineStepKind.camera),
          ],
        ),
      );

      controller.update(const Duration(milliseconds: 1));
      final result = await completion;

      expect(
        result.errorCode,
        SceneCinematicRuntimeAwaitableErrorCode.sinkFailure,
      );
      expect(sink.restoreCalls, 1);
      expect(controller.isPlaying, isFalse);
    });
  });
}

final class _RecordingSink implements CinematicRuntimePlaybackSink {
  int preflightCalls = 0;
  int restoreCalls = 0;
  bool throwOnUpdate = false;
  bool recordUpdates = true;
  final Set<CinematicTimelineStepKind> visuallyCompletedKinds =
      <CinematicTimelineStepKind>{};
  CinematicRuntimeSinkPreflightResult preflightResult =
      const CinematicRuntimeSinkPreflightResult.ready();
  final List<String> events = <String>[];

  @override
  CinematicRuntimeSinkPreflightResult preflight(CinematicAsset asset) {
    preflightCalls++;
    return preflightResult;
  }

  @override
  void beginStep(CinematicRuntimeStepContext context) {
    events.add('begin:${context.step.kind.name}');
  }

  @override
  void updateStep(CinematicRuntimeStepContext context) {
    if (throwOnUpdate) throw StateError('sink update failed');
    if (recordUpdates) events.add('update:${context.step.kind.name}');
  }

  @override
  bool isStepVisuallyComplete(CinematicRuntimeStepContext context) {
    return visuallyCompletedKinds.contains(context.step.kind);
  }

  @override
  void endStep(CinematicRuntimeStepContext context) {
    events.add('end:${context.step.kind.name}');
  }

  @override
  void restore(CinematicRuntimeTermination termination) {
    restoreCalls++;
    events.add('restore:${termination.name}');
  }
}

CinematicAsset _asset({
  required List<CinematicTimelineStep> steps,
  CinematicActorBindingKind bindingKind = CinematicActorBindingKind.mapEntity,
}) {
  return CinematicAsset(
    id: 'cinematic_test',
    title: 'Test cinematic',
    requiredActors: <CinematicActorRef>[
      CinematicActorRef(actorId: 'actor'),
    ],
    movementTargets: <CinematicMovementTargetRef>[
      CinematicMovementTargetRef(targetId: 'target', label: 'Target'),
    ],
    stageContext: CinematicStageContext(
      actorBindings: <CinematicActorBinding>[
        CinematicActorBinding(
          actorId: 'actor',
          kind: bindingKind,
          mapEntityId:
              bindingKind == CinematicActorBindingKind.mapEntity ? 'npc' : null,
        ),
      ],
      movementTargetBindings: <CinematicMovementTargetBinding>[
        CinematicMovementTargetBinding(
          targetId: 'target',
          kind: CinematicMovementTargetBindingKind.stagePoint,
          sourceId: 'point',
        ),
      ],
      stagePoints: <CinematicStagePoint>[
        CinematicStagePoint(
          id: 'point',
          label: 'Point',
          x: 1,
          y: 1,
        ),
      ],
    ),
    timeline: CinematicTimeline(steps: steps),
  );
}

CinematicTimelineStep _step(
  CinematicTimelineStepKind kind, {
  int? durationMs,
}) {
  return CinematicTimelineStep(
    id: 'step_${kind.name}',
    kind: kind,
    durationMs: durationMs,
    actorId: switch (kind) {
      CinematicTimelineStepKind.actorMove ||
      CinematicTimelineStepKind.actorFace ||
      CinematicTimelineStepKind.actorEmote =>
        'actor',
      _ => null,
    },
    targetId: kind == CinematicTimelineStepKind.actorMove ? 'target' : null,
    dialogueText:
        kind == CinematicTimelineStepKind.dialogueLine ? 'Hello' : null,
  );
}
