import 'dart:async';

import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameSessionController', () {
    test('loads, pauses, tears down, then permits a fresh session', () async {
      final adapters = <_FakeSessionAdapter>[];
      final controller = GameSessionController(
        adapterFactory: (descriptor) {
          final adapter = _FakeSessionAdapter(descriptor.sessionId);
          adapters.add(adapter);
          return adapter;
        },
        commitCheckpoint: (_) async {},
      );

      final first = _descriptor(sessionId: 'session-a');
      await controller.prepare(first);
      expect(controller.snapshot.state, GameSessionState.prepared);
      expect(controller.snapshot.descriptor, isA<GameSessionPublicContext>());
      expect(
        controller.snapshot.descriptor.toString(),
        isNot(contains(first.sessionToken)),
      );

      await controller.start();
      adapters.single.emit(GameSessionReady(first.sessionId));
      adapters.single.emit(
        GameSessionLoading(
          first.sessionId,
          const GameSessionLoadingProgress(
            stage: 'project',
            current: 1,
            total: 2,
          ),
        ),
      );
      adapters.single.emit(GameSessionRunning(first.sessionId));
      await controller.settle();
      expect(controller.snapshot.state, GameSessionState.running);
      expect(controller.snapshot.loadingProgress?.stage, 'project');

      await controller.pause();
      expect(controller.snapshot.state, GameSessionState.paused);
      await controller.resume();
      expect(controller.snapshot.state, GameSessionState.running);

      await controller.returnToTitle(checkpoint: false);
      expect(controller.snapshot.state, GameSessionState.disposed);
      expect(controller.snapshot.exitReason, GameSessionExitReason.title);
      expect(
          adapters.single.calls,
          containsAllInOrder(<String>[
            'prepare',
            'start',
            'pause',
            'resume',
            'stop:title',
            'dispose',
          ]));

      final second = _descriptor(sessionId: 'session-b');
      await controller.prepare(second);
      expect(adapters, hasLength(2));
      expect(controller.snapshot.descriptor?.sessionId, 'session-b');

      await controller.terminate();
      await controller.dispose();
    });

    test('adapter construction failure leaves the controller reusable',
        () async {
      var attempts = 0;
      late _FakeSessionAdapter adapter;
      final controller = GameSessionController(
        adapterFactory: (descriptor) {
          attempts++;
          if (attempts == 1) throw StateError('adapter unavailable');
          return adapter = _FakeSessionAdapter(descriptor.sessionId);
        },
        commitCheckpoint: (_) async {},
      );

      await expectLater(
        controller.prepare(_descriptor(sessionId: 'failed-session')),
        throwsStateError,
      );
      expect(controller.snapshot.state, GameSessionState.disposed);
      expect(controller.snapshot.exitReason, GameSessionExitReason.failed);

      await controller.prepare(_descriptor(sessionId: 'retry-session'));
      expect(controller.snapshot.state, GameSessionState.prepared);
      expect(adapter.calls, <String>['prepare']);

      await controller.terminate();
      await controller.dispose();
    });

    test('publishes loading progress while runtime start is still pending',
        () async {
      final startGate = Completer<void>();
      late _FakeSessionAdapter adapter;
      final controller = GameSessionController(
        adapterFactory: (descriptor) => adapter = _FakeSessionAdapter(
          descriptor.sessionId,
          startWait: startGate.future,
        ),
        commitCheckpoint: (_) async {},
      );
      final descriptor = _descriptor();
      await controller.prepare(descriptor);

      final start = controller.start();
      await Future<void>.delayed(Duration.zero);
      adapter.emit(GameSessionReady(descriptor.sessionId));
      adapter.emit(
        GameSessionLoading(
          descriptor.sessionId,
          const GameSessionLoadingProgress(
            stage: 'project',
            current: 1,
            total: 4,
          ),
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(controller.snapshot.state, GameSessionState.loading);
      expect(controller.snapshot.loadingProgress?.stage, 'project');

      startGate.complete();
      await start;
      adapter.emit(GameSessionRunning(descriptor.sessionId));
      await controller.settle();
      await controller.terminate();
      await controller.dispose();
    });

    test('rejects a second launch and ignores stale session events', () async {
      late _FakeSessionAdapter adapter;
      final controller = GameSessionController(
        adapterFactory: (descriptor) =>
            adapter = _FakeSessionAdapter(descriptor.sessionId),
        commitCheckpoint: (_) async {},
      );
      await controller.prepare(_descriptor(sessionId: 'session-a'));

      await expectLater(
        controller.prepare(_descriptor(sessionId: 'session-b')),
        throwsA(
          isA<GameSessionException>().having(
            (error) => error.code,
            'code',
            GameSessionErrorCode.sessionAlreadyActive,
          ),
        ),
      );

      adapter.emit(const GameSessionRunning('stale-session'));
      await controller.settle();
      expect(controller.snapshot.state, GameSessionState.prepared);
      expect(
        controller.snapshot.lastDiagnostic?.code,
        'session.event.stale',
      );

      await controller.terminate();
      await controller.dispose();
    });

    test('lifecycle pause restores the exact previous state', () async {
      late _FakeSessionAdapter adapter;
      final controller = GameSessionController(
        adapterFactory: (descriptor) =>
            adapter = _FakeSessionAdapter(descriptor.sessionId),
        commitCheckpoint: (_) async {},
      );
      final descriptor = _descriptor();
      await controller.prepare(descriptor);
      await controller.start();
      adapter.emit(GameSessionRunning(descriptor.sessionId));
      await controller.settle();

      await controller.pause();
      await controller.pauseForLifecycle();
      expect(controller.snapshot.state, GameSessionState.lifecyclePaused);
      expect(controller.snapshot.lifecycleResumeState, GameSessionState.paused);

      await controller.resumeFromLifecycle();
      expect(controller.snapshot.state, GameSessionState.paused);
      expect(
        adapter.calls.where((call) => call == 'resume'),
        isEmpty,
        reason: 'A player-paused session must not resume its game clock.',
      );

      await controller.returnToHub(checkpoint: false);
      await controller.dispose();
    });

    test('commits completion before publishing completed and retries safely',
        () async {
      late _FakeSessionAdapter adapter;
      var attempts = 0;
      final committed = <GameSessionCheckpointCommit>[];
      final controller = GameSessionController(
        adapterFactory: (descriptor) =>
            adapter = _FakeSessionAdapter(descriptor.sessionId),
        commitCheckpoint: (request) async {
          attempts++;
          if (attempts == 1) throw StateError('disk full');
          committed.add(request);
        },
      );
      final descriptor = _descriptor();
      await controller.prepare(descriptor);
      await controller.start();
      adapter.emit(GameSessionRunning(descriptor.sessionId));
      await controller.settle();

      final completion = _completion(descriptor);
      adapter.emit(GameSessionCompleted(completion));
      await controller.settle();

      expect(controller.snapshot.state, GameSessionState.completing);
      expect(controller.snapshot.completionCommitFailed, isTrue);
      expect(controller.committedCompletion, isNull);
      expect(adapter.gameplayLocked, isTrue);

      await controller.retryCompletion();
      expect(controller.snapshot.state, GameSessionState.completed);
      expect(controller.committedCompletion, completion);
      expect(committed.single.status, SaveStatus.completed);
      expect(adapter.completionAcknowledgements, <bool>[false, true]);

      adapter.emit(GameSessionCompleted(completion));
      await controller.settle();
      expect(attempts, 2, reason: 'Duplicate completion must be idempotent.');

      await controller.returnToHub(checkpoint: false);
      await controller.dispose();
    });

    test('completion from another game fails the session contract', () async {
      late _FakeSessionAdapter adapter;
      final controller = GameSessionController(
        adapterFactory: (descriptor) =>
            adapter = _FakeSessionAdapter(descriptor.sessionId),
        commitCheckpoint: (_) async {},
      );
      final descriptor = _descriptor();
      await controller.prepare(descriptor);
      await controller.start();
      adapter.emit(GameSessionRunning(descriptor.sessionId));
      await controller.settle();

      adapter.emit(
        GameSessionCompleted(
          _completion(descriptor, gameId: 'org.example.other-game'),
        ),
      );
      await controller.settle();

      expect(controller.snapshot.state, GameSessionState.failed);
      expect(
        controller.snapshot.failure?.code,
        GameSessionFailureCode.contractViolation,
      );
      expect(adapter.gameplayLocked, isTrue);

      await controller.returnToHub(checkpoint: false);
      await controller.dispose();
    });

    test('start failure moves the session to a recoverable failure', () async {
      late _FakeSessionAdapter adapter;
      final controller = GameSessionController(
        adapterFactory: (descriptor) => adapter = _FakeSessionAdapter(
          descriptor.sessionId,
          startError: StateError('runtime boot failed'),
        ),
        commitCheckpoint: (_) async {},
      );

      await controller.prepare(_descriptor());

      await expectLater(
        controller.start(),
        throwsA(
          isA<GameSessionException>().having(
            (error) => error.code,
            'code',
            GameSessionErrorCode.runtime,
          ),
        ),
      );
      expect(controller.snapshot.state, GameSessionState.failed);
      expect(
        controller.snapshot.failure?.recoverability,
        GameSessionFailureRecoverability.retry,
      );

      await controller.returnToHub(checkpoint: false);
      await controller.dispose();
      expect(
        adapter.calls,
        containsAllInOrder(<String>['stop:hub', 'dispose']),
      );
    });
  });
}

GameSessionDescriptor _descriptor({String sessionId = 'session-a'}) {
  return GameSessionDescriptor(
    sessionId: sessionId,
    sessionToken: 'secret-token-$sessionId',
    identity: GameIdentity(
      gameId: 'org.example.adventure',
      gameVersion: '1.2.0',
      projectFormat: ProjectFormat.v2,
      saveFormat: 1,
      compatibilityId: 'story-v1',
    ),
    profileId: 'player-1',
    slotId: 'slot-1',
    launchMode: GameSessionLaunchMode.newGame,
    installedVersionHandle: 'install-handle-$sessionId',
    runtimeApiVersion: '1.0.0',
    grantedCapabilities: const <String>{'battle.v1'},
    locale: 'fr-FR',
    accessibility: const GameSessionAccessibilityOptions(),
  );
}

GameCompletionEvent _completion(
  GameSessionDescriptor descriptor, {
  String? gameId,
}) {
  final completedAt = DateTime.utc(2026, 7, 25, 2);
  return GameCompletionEvent(
    sessionId: descriptor.sessionId,
    gameId: gameId ?? descriptor.identity.gameId,
    endingId: 'ending-main',
    outcome: GameCompletionOutcome.victory,
    completedAt: completedAt,
    playTimeSeconds: 3600,
    result: const GameResultSnapshot(
      title: 'Victoire',
      summary: 'La région est sauvée.',
    ),
    credits: const GameCreditsSnapshot(
      title: 'Example Adventure',
      author: 'Example Studio',
      contributors: <String>['Player'],
      licenses: <String>['Assets: CC-BY-4.0'],
      endingLabel: 'Fin principale',
    ),
    destination: GameCompletionDestination.playerChoice,
    allowPostGameContinue: false,
    finalCheckpoint: GameSessionCheckpoint(
      saveId: 'save-1',
      createdAt: DateTime.utc(2026, 7, 24),
      updatedAt: completedAt,
      playTimeSeconds: 3600,
      state: const <String, Object?>{
        'saveId': 'save-1',
        'currentMapId': 'ending',
      },
    ),
  );
}

final class _FakeSessionAdapter implements GameSessionAdapter {
  _FakeSessionAdapter(this.sessionId, {this.startError, this.startWait});

  final String sessionId;
  final Object? startError;
  final Future<void>? startWait;
  final calls = <String>[];
  final completionAcknowledgements = <bool>[];
  final _events = StreamController<GameSessionAdapterEvent>.broadcast();
  bool gameplayLocked = false;

  @override
  Stream<GameSessionAdapterEvent> get events => _events.stream;

  void emit(GameSessionAdapterEvent event) => _events.add(event);

  @override
  Future<void> prepare(GameSessionDescriptor descriptor) async {
    calls.add('prepare');
  }

  @override
  Future<void> start() async {
    calls.add('start');
    if (startError case final error?) throw error;
    await startWait;
  }

  @override
  Future<void> pause() async {
    calls.add('pause');
  }

  @override
  Future<void> resume() async {
    calls.add('resume');
  }

  @override
  Future<GameSessionCheckpoint?> captureCheckpoint() async {
    calls.add('checkpoint');
    return null;
  }

  @override
  Future<void> lockGameplayForCompletion() async {
    calls.add('lock-completion');
    gameplayLocked = true;
  }

  @override
  Future<void> acknowledgeCompletion({required bool accepted}) async {
    calls.add('completion:$accepted');
    completionAcknowledgements.add(accepted);
  }

  @override
  Future<void> stop(GameSessionExitReason reason) async {
    calls.add('stop:${reason.name}');
  }

  @override
  Future<void> dispose() async {
    calls.add('dispose');
    await _events.close();
  }

  @override
  bool handleInput(RuntimeInputEvent event) {
    calls.add('input:${event.control.name}:${event.phase.name}');
    return true;
  }
}
