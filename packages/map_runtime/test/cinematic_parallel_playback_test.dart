import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/scene_runtime/cinematic_runtime_playback_controller.dart';

void main() {
  test(
    'stop during seek restoration cancels once without reviving playback',
    () async {
      final sink = _AsyncSink()..gate = Completer<void>();
      final controller = CinematicRuntimePlaybackController(sink: sink);
      final completion = controller.play(_asset());
      final seeking = controller.seek(const Duration(milliseconds: 500));
      expect(controller.cancel(), isTrue);
      expect(controller.cancel(), isFalse);
      expect(controller.isPlaying, isTrue);
      sink.gate!.complete();
      expect((await seeking).status, CinematicRuntimeSeekStatus.cancelled);
      expect((await completion).success, isFalse);
      expect(controller.isPlaying, isFalse);
      expect(sink.restoreCalls, 1);
    },
  );

  test(
    'failed seek restoration releases ownership without restoring twice',
    () async {
      final sink = _AsyncSink()..failRestore = true;
      final controller = CinematicRuntimePlaybackController(sink: sink);
      final completion = controller.play(_asset());
      expect(
        (await controller.seek(const Duration(milliseconds: 500))).status,
        CinematicRuntimeSeekStatus.failed,
      );
      expect((await completion).success, isFalse);
      expect(controller.isPlaying, isFalse);
      expect(sink.restoreCalls, 1);
    },
  );

  test('zero duration does not bypass an external completion', () async {
    final sink = _Sink();
    final controller = CinematicRuntimePlaybackController(sink: sink);
    final asset = _asset().copyWith(
      timeline: CinematicTimeline(
        steps: [
          CinematicTimelineStep(
            id: 'external',
            kind: CinematicTimelineStepKind.sound,
            assetRef: 'sound.test',
            durationMs: 0,
          ),
        ],
      ),
    );
    final completion = controller.play(asset);
    expect(controller.isPlaying, isTrue);
    controller.update(Duration.zero);
    expect(controller.isPlaying, isTrue);
    sink.externallyCompleted.add('external');
    controller.update(Duration.zero);
    expect((await completion).success, isTrue);
  });

  test(
    'pause and seek resample without completing or publishing the cinematic',
    () async {
      final sink = _Sink();
      final controller = CinematicRuntimePlaybackController(sink: sink);
      var completed = false;
      final completion = controller.play(_asset()).then((result) {
        completed = true;
        return result;
      });
      controller.update(const Duration(milliseconds: 250));
      expect(controller.pause(), isTrue);
      controller.update(const Duration(seconds: 2));
      expect(sink.elapsed['hero'], const Duration(milliseconds: 250));
      expect(
        (await controller.seek(const Duration(milliseconds: 750))).success,
        isTrue,
      );
      expect(controller.isPaused, isTrue);
      expect(sink.elapsed['hero'], const Duration(milliseconds: 750));
      expect(sink.elapsed['guide'], const Duration(milliseconds: 750));
      expect(completed, isFalse);
      expect(
        (await controller.seek(const Duration(milliseconds: 1500))).success,
        isTrue,
      );
      expect(controller.isPlaying, isTrue);
      expect(completed, isFalse);
      expect(
        sink.terminations,
        everyElement(CinematicRuntimeTermination.cancelled),
      );
      expect(
        (await controller.seek(const Duration(milliseconds: 1501))).status,
        CinematicRuntimeSeekStatus.invalidPosition,
      );
      controller.cancel();
      expect((await completion).success, isFalse);
    },
  );

  test('an external completion holds the barrier while other members keep advancing', () async {
    final sink = _Sink();
    final controller = CinematicRuntimePlaybackController(sink: sink);
    final base = _asset();
    final asset = base.copyWith(
      timeline: CinematicTimeline(
        steps: [
          ...base.timeline.steps,
          CinematicTimelineStep.fromJson({
            'id': 'external',
            'kind': 'wait',
            'durationMs': 500,
            'parallelGroupId': 'opening',
          }),
          CinematicTimelineStep(
            id: 'tail',
            kind: CinematicTimelineStepKind.wait,
            durationMs: 100,
          ),
        ],
      ),
    );
    final completion = controller.play(asset);
    controller.update(const Duration(seconds: 2));
    expect(sink.elapsed['camera'], const Duration(milliseconds: 1500));
    expect(sink.active.keys, ['external']);
    expect(sink.elapsed.containsKey('tail'), isFalse);
    sink.externallyCompleted.add('external');
    controller.update(const Duration(seconds: 4));
    expect(sink.active.keys, ['tail']);
    expect(sink.elapsed['tail'], isNull);
    controller.update(const Duration(milliseconds: 100));
    expect((await completion).success, isTrue);
  });

  test(
    'two actors and camera begin together and join at the longest duration',
    () async {
      final sink = _Sink();
      final controller = CinematicRuntimePlaybackController(sink: sink);
      final completion = controller.play(_asset());
      expect(sink.active.keys, unorderedEquals(['hero', 'guide', 'camera']));
      controller.update(const Duration(milliseconds: 500));
      expect(sink.elapsed['hero'], const Duration(milliseconds: 500));
      expect(sink.elapsed['guide'], const Duration(milliseconds: 500));
      expect(sink.elapsed['camera'], const Duration(milliseconds: 500));
      controller.update(const Duration(milliseconds: 500));
      expect(sink.active.keys, ['camera']);
      controller.update(const Duration(milliseconds: 500));
      expect((await completion).success, isTrue);
      expect(sink.terminations, [CinematicRuntimeTermination.completed]);
    },
  );
}

CinematicAsset _asset() => CinematicAsset(
  id: 'parallel',
  title: 'Parallel',
  mapId: 'room',
  requiredActors: [
    CinematicActorRef(actorId: 'hero'),
    CinematicActorRef(actorId: 'guide'),
  ],
  movementTargets: [
    CinematicMovementTargetRef(targetId: 'a', label: 'A'),
    CinematicMovementTargetRef(targetId: 'b', label: 'B'),
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
      CinematicStagePoint(id: 'b', label: 'B', x: 5, y: 3),
    ],
    movementTargetBindings: [
      CinematicMovementTargetBinding(
        targetId: 'a',
        kind: CinematicMovementTargetBindingKind.stagePoint,
        sourceId: 'a',
      ),
      CinematicMovementTargetBinding(
        targetId: 'b',
        kind: CinematicMovementTargetBindingKind.stagePoint,
        sourceId: 'b',
      ),
    ],
  ),
  timeline: CinematicTimeline(
    steps: [
      for (final actor in ['hero', 'guide'])
        CinematicTimelineStep.fromJson({
          'id': actor,
          'kind': 'actorMove',
          'actorId': actor,
          'targetId': actor == 'hero' ? 'a' : 'b',
          'durationMs': 1000,
          'parallelGroupId': 'opening',
          'metadata': {
            'actor.movementMode': 'walk',
            'actor.pathMode': 'direct',
          },
        }),
      CinematicTimelineStep.fromJson({
        'id': 'camera',
        'kind': 'camera',
        'durationMs': 1500,
        'parallelGroupId': 'opening',
        'metadata': {'camera.mode': 'hold'},
      }),
    ],
  ),
);

final class _Sink
    implements
        CinematicRuntimePlaybackSink,
        CinematicRuntimeStepCompletionPolicy {
  final active = <String, bool>{};
  final elapsed = <String, Duration>{};
  final terminations = <CinematicRuntimeTermination>[];
  final externallyCompleted = <String>{};

  @override
  bool requiresSinkCompletion(CinematicRuntimeStepContext context) =>
      context.step.id == 'external';

  @override
  CinematicRuntimeSinkPreflightResult preflight(CinematicAsset asset) =>
      const CinematicRuntimeSinkPreflightResult.ready();

  @override
  void beginStep(CinematicRuntimeStepContext context) =>
      active[context.step.id] = true;

  @override
  void updateStep(CinematicRuntimeStepContext context) =>
      elapsed[context.step.id] = context.elapsed;

  @override
  bool isStepVisuallyComplete(CinematicRuntimeStepContext context) =>
      externallyCompleted.contains(context.step.id);

  @override
  void endStep(CinematicRuntimeStepContext context) =>
      active.remove(context.step.id);

  @override
  void restore(CinematicRuntimeTermination termination) {
    active.clear();
    terminations.add(termination);
  }
}

final class _AsyncSink extends _Sink
    implements CinematicRuntimeAsyncRestorationSink {
  Completer<void>? gate;
  bool failRestore = false;
  int restoreCalls = 0;

  @override
  Future<void> restoreAsync(CinematicRuntimeTermination termination) async {
    restoreCalls++;
    await gate?.future;
    if (failRestore) throw StateError('Restoration failed.');
    restore(termination);
  }
}
