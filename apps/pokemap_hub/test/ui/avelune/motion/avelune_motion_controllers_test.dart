import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pokemap_hub/presentation/design_system/foundation/avelune_motion_tokens.dart';
import 'package:pokemap_hub/presentation/features/home/state/avelune_exchange_controller.dart';
import 'package:pokemap_hub/presentation/design_system/motion/avelune_feedback.dart';
import 'package:pokemap_hub/presentation/features/home/state/avelune_insertion_controller.dart';
import 'package:pokemap_hub/presentation/design_system/motion/avelune_interaction_state.dart';

void main() {
  group('Avelune interaction transitions', () {
    test('allows only physically coherent state changes', () {
      const allowed = <(AveluneInteractionState, AveluneInteractionState)>[
        (AveluneInteractionState.idle, AveluneInteractionState.exchanging),
        (AveluneInteractionState.idle, AveluneInteractionState.aligning),
        (AveluneInteractionState.idle, AveluneInteractionState.openingDetails),
        (AveluneInteractionState.exchanging, AveluneInteractionState.idle),
        (AveluneInteractionState.aligning, AveluneInteractionState.descending),
        (AveluneInteractionState.descending, AveluneInteractionState.latched),
        (AveluneInteractionState.latched, AveluneInteractionState.launching),
        (AveluneInteractionState.launching, AveluneInteractionState.idle),
        (AveluneInteractionState.recovering, AveluneInteractionState.idle),
        (AveluneInteractionState.error, AveluneInteractionState.recovering),
      ];
      const impossible = <(AveluneInteractionState, AveluneInteractionState)>[
        (AveluneInteractionState.idle, AveluneInteractionState.latched),
        (
          AveluneInteractionState.exchanging,
          AveluneInteractionState.descending
        ),
        (AveluneInteractionState.descending, AveluneInteractionState.launching),
        (
          AveluneInteractionState.openingDetails,
          AveluneInteractionState.latched
        ),
      ];

      for (final (from, to) in allowed) {
        expect(
          AveluneInteractionTransitions.canTransition(from, to),
          isTrue,
          reason: '$from -> $to',
        );
      }
      for (final (from, to) in impossible) {
        expect(
          AveluneInteractionTransitions.canTransition(from, to),
          isFalse,
          reason: '$from -> $to',
        );
        expect(
          () => AveluneInteractionTransitions.ensureAllowed(from, to),
          throwsStateError,
        );
      }
    });
  });

  group('AveluneExchangeController', () {
    test('commits one exchange at the occluded midpoint', () async {
      final delay = _ControlledDelay();
      final feedback = _RecordingFeedback();
      final commits = <String>[];
      final controller = AveluneExchangeController(
        initialGameId: 'selbrume',
        motion: AveluneMotionTokens.standard,
        feedback: feedback,
        delay: delay.call,
      );

      final future = controller.select('train', onCommitted: commits.add);
      expect(controller.state, AveluneInteractionState.exchanging);
      expect(controller.currentGameId, 'selbrume');
      expect(controller.sourceGameId, 'selbrume');
      expect(controller.targetGameId, 'train');
      expect(controller.stage, AveluneExchangeStage.departing);
      expect(feedback.cues, isEmpty);
      expect(
        delay.durations,
        <Duration>[const Duration(milliseconds: 220)],
      );

      delay.completeNext();
      await _flushMicrotasks();
      expect(controller.currentGameId, 'train');
      expect(controller.stage, AveluneExchangeStage.settling);
      expect(controller.state, AveluneInteractionState.exchanging);
      expect(commits, <String>['train']);
      expect(feedback.cues, <AveluneFeedbackCue>[AveluneFeedbackCue.selection]);
      expect(delay.durations, <Duration>[
        const Duration(milliseconds: 220),
        const Duration(milliseconds: 220),
      ]);

      delay.completeNext();
      await future;
      expect(controller.state, AveluneInteractionState.idle);
      expect(controller.stage, AveluneExchangeStage.idle);
      expect(controller.sourceGameId, isNull);
      expect(controller.targetGameId, isNull);
      expect(feedback.cues, <AveluneFeedbackCue>[AveluneFeedbackCue.selection]);
    });

    test('keeps only the latest selection queued during exchange', () async {
      final delay = _ControlledDelay();
      final commits = <String>[];
      final controller = AveluneExchangeController(
        initialGameId: 'selbrume',
        motion: AveluneMotionTokens.standard,
        feedback: _RecordingFeedback(),
        delay: delay.call,
      );

      final exchange = controller.select('train', onCommitted: commits.add);
      unawaited(controller.select('demo', onCommitted: commits.add));
      unawaited(controller.select('aurora', onCommitted: commits.add));
      expect(controller.queuedGameId, 'aurora');

      delay.completeNext();
      await _flushMicrotasks();
      expect(commits, <String>['aurora']);
      expect(controller.currentGameId, 'aurora');
      expect(controller.stage, AveluneExchangeStage.settling);
      expect(delay.pendingCount, 1);

      delay.completeNext();
      await exchange;
      expect(commits, <String>['aurora']);
      expect(controller.currentGameId, 'aurora');
      expect(controller.state, AveluneInteractionState.idle);
    });

    test('keeps state coherent through 20 sequential exchanges', () async {
      final commits = <String>[];
      final feedback = _RecordingFeedback();
      final controller = AveluneExchangeController(
        initialGameId: 'game-0',
        motion: AveluneMotionTokens.standard,
        feedback: feedback,
        delay: (_) async {},
      );

      for (var index = 1; index <= 20; index++) {
        await controller.select('game-$index', onCommitted: commits.add);
        expect(controller.currentGameId, 'game-$index');
        expect(controller.state, AveluneInteractionState.idle);
      }

      expect(commits, <String>[
        for (var index = 1; index <= 20; index++) 'game-$index',
      ]);
      expect(
        feedback.cues.where((cue) => cue == AveluneFeedbackCue.selection),
        hasLength(20),
      );
    });

    test('does not commit after dispose', () async {
      final delay = _ControlledDelay();
      final commits = <String>[];
      final controller = AveluneExchangeController(
        initialGameId: 'selbrume',
        motion: AveluneMotionTokens.standard,
        feedback: _RecordingFeedback(),
        delay: delay.call,
      );

      final exchange = controller.select('train', onCommitted: commits.add);
      controller.dispose();
      delay.completeNext();
      await exchange;
      expect(commits, isEmpty);
    });

    test('ignores selection while insertion owns the physical scene', () async {
      final insertionDelay = _ControlledDelay();
      final insertion = AveluneInsertionController(
        motion: AveluneMotionTokens.standard,
        feedback: _RecordingFeedback(),
        delay: insertionDelay.call,
      );
      final insertionFuture = insertion.insert(onLaunch: () {});
      final exchangeDelay = _ControlledDelay();
      final commits = <String>[];
      final exchange = AveluneExchangeController(
        initialGameId: 'selbrume',
        motion: AveluneMotionTokens.standard,
        feedback: _RecordingFeedback(),
        delay: exchangeDelay.call,
        isSelectionBlocked: () => insertion.isInserting,
      );

      await exchange.select('train', onCommitted: commits.add);
      expect(exchange.state, AveluneInteractionState.idle);
      expect(exchangeDelay.durations, isEmpty);
      expect(commits, isEmpty);

      insertion.cancel();
      insertionDelay.completeNext();
      expect(await insertionFuture, isFalse);
      final exchangeFuture = exchange.select('train', onCommitted: commits.add);
      exchangeDelay.completeNext();
      await _flushMicrotasks();
      exchangeDelay.completeNext();
      await exchangeFuture;
      expect(commits, <String>['train']);
    });
  });

  group('AveluneInsertionController', () {
    test('runs align descend latch and launch in order', () async {
      final delay = _ControlledDelay();
      final feedback = _RecordingFeedback();
      var launches = 0;
      final controller = AveluneInsertionController(
        motion: AveluneMotionTokens.standard,
        feedback: feedback,
        delay: delay.call,
      );

      final insertion = controller.insert(onLaunch: () => launches++);
      expect(controller.state, AveluneInteractionState.aligning);
      expect(feedback.cues, <AveluneFeedbackCue>[AveluneFeedbackCue.align]);

      delay.completeNext();
      await _flushMicrotasks();
      expect(controller.state, AveluneInteractionState.descending);

      delay.completeNext();
      await _flushMicrotasks();
      expect(controller.state, AveluneInteractionState.latched);
      expect(feedback.cues.last, AveluneFeedbackCue.latch);

      delay.completeNext();
      await _flushMicrotasks();
      expect(controller.state, AveluneInteractionState.launching);
      expect(launches, 0);
      expect(feedback.cues.last, AveluneFeedbackCue.latch);

      delay.completeNext();
      expect(await insertion, isTrue);
      expect(launches, 1);
      expect(controller.state, AveluneInteractionState.idle);
      expect(
        delay.durations,
        <Duration>[
          AveluneMotionTokens.standard.insertionAlign,
          AveluneMotionTokens.standard.insertionDescend,
          AveluneMotionTokens.standard.insertionLatch,
          AveluneMotionTokens.standard.insertionLaunchDelay,
        ],
      );
      expect(
        feedback.cues,
        <AveluneFeedbackCue>[
          AveluneFeedbackCue.align,
          AveluneFeedbackCue.latch,
        ],
      );
    });

    test('coalesces repeated insertion taps into one launch', () async {
      final delay = _ControlledDelay(autoComplete: true);
      var launches = 0;
      final controller = AveluneInsertionController(
        motion: AveluneMotionTokens.standard,
        feedback: _RecordingFeedback(),
        delay: delay.call,
      );

      final first = controller.insert(onLaunch: () => launches++);
      final second = controller.insert(onLaunch: () => launches++);
      expect(identical(first, second), isTrue);
      expect(await first, isTrue);
      expect(launches, 1);
    });

    test('never calls launch after dispose or cancellation', () async {
      final delay = _ControlledDelay();
      var launches = 0;
      final controller = AveluneInsertionController(
        motion: AveluneMotionTokens.standard,
        feedback: _RecordingFeedback(),
        delay: delay.call,
      );

      final insertion = controller.insert(onLaunch: () => launches++);
      controller.cancel();
      expect(controller.state, AveluneInteractionState.idle);
      delay.completeNext();
      expect(await insertion, isFalse);
      expect(launches, 0);

      final disposedDelay = _ControlledDelay();
      final disposed = AveluneInsertionController(
        motion: AveluneMotionTokens.standard,
        feedback: _RecordingFeedback(),
        delay: disposedDelay.call,
      );
      final disposedInsertion = disposed.insert(onLaunch: () => launches++);
      disposed.dispose();
      disposedDelay.completeNext();
      expect(await disposedInsertion, isFalse);
      expect(launches, 0);
    });

    test('moves to error once when launch fails', () async {
      final feedback = _RecordingFeedback();
      final controller = AveluneInsertionController(
        motion: AveluneMotionTokens.reduced,
        feedback: feedback,
        delay: (_) async {},
      );

      await expectLater(
        controller.insert(onLaunch: () => throw StateError('invalid save')),
        throwsStateError,
      );
      expect(controller.state, AveluneInteractionState.error);
      expect(controller.lastError, isA<StateError>());
      expect(
        feedback.cues.where((cue) => cue == AveluneFeedbackCue.error),
        hasLength(1),
      );
      controller.recover();
      expect(controller.state, AveluneInteractionState.idle);
      expect(await controller.insert(onLaunch: () {}), isTrue);
    });

    test('reduced motion uses only reduced phase durations', () async {
      final durations = <Duration>[];
      final controller = AveluneInsertionController(
        motion: AveluneMotionTokens.reduced,
        feedback: _RecordingFeedback(),
        delay: (duration) async => durations.add(duration),
      );

      expect(await controller.insert(onLaunch: () {}), isTrue);
      expect(
        durations,
        <Duration>[
          Duration.zero,
          const Duration(milliseconds: 120),
          Duration.zero,
          Duration.zero,
        ],
      );
      expect(
        durations.fold<int>(0, (total, value) => total + value.inMilliseconds),
        120,
      );
    });
  });
}

Future<void> _flushMicrotasks() => Future<void>.delayed(Duration.zero);

class _RecordingFeedback implements AveluneFeedback {
  final List<AveluneFeedbackCue> cues = <AveluneFeedbackCue>[];

  @override
  void emit(AveluneFeedbackCue cue) => cues.add(cue);
}

class _ControlledDelay {
  _ControlledDelay({this.autoComplete = false});

  final bool autoComplete;
  final List<Duration> durations = <Duration>[];
  final List<Completer<void>> _pending = <Completer<void>>[];

  int get pendingCount => _pending.where((item) => !item.isCompleted).length;

  Future<void> call(Duration duration) {
    durations.add(duration);
    if (autoComplete) return Future<void>.value();
    final completer = Completer<void>();
    _pending.add(completer);
    return completer.future;
  }

  void completeNext() {
    _pending.firstWhere((item) => !item.isCompleted).complete();
  }
}
