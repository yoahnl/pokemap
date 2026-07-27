import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import 'support/runtime_player_test_harness.dart';

void main() {
  test('playing lifecycle pause and resume are idempotent', () async {
    final harness = RuntimePlayerTestHarness();
    addTearDown(harness.dispose);
    await launchHarnessToPlaying(harness);
    harness.adapter.checkpoint = testPlayerCheckpoint();

    await harness.coordinator.pauseForLifecycle();
    await harness.coordinator.pauseForLifecycle();

    expect(
      harness.coordinator.snapshot.phase,
      RuntimePlayerPhase.lifecyclePaused,
    );
    expect(
      harness.sessions.snapshot.state,
      GameSessionState.lifecyclePaused,
    );
    expect(
      harness.adapter.calls.where((call) => call == 'pause'),
      hasLength(1),
    );
    expect(harness.saves.commits, hasLength(1));
    expect(
      harness.saves.commits.single.trigger,
      GameSessionCheckpointTrigger.lifecyclePause,
    );
    expect(harness.saves.commits.single.isAutosave, isTrue);

    await harness.coordinator.resumeFromLifecycle();
    await harness.coordinator.resumeFromLifecycle();

    expect(harness.coordinator.snapshot.phase, RuntimePlayerPhase.playing);
    expect(harness.sessions.snapshot.state, GameSessionState.running);
    expect(
      harness.adapter.calls.where((call) => call == 'resume'),
      hasLength(1),
    );
  });

  test('lifecycle restores the exact paused detail without resuming gameplay',
      () async {
    final harness = RuntimePlayerTestHarness();
    addTearDown(harness.dispose);
    await launchHarnessToPlaying(harness);
    await openHarnessPause(harness);
    await harness.coordinator.dispatch(
      RuntimePlayerCommand(
        action: RuntimePlayerAction.openBag,
        snapshotRevision: harness.coordinator.snapshot.revision,
      ),
    );

    await harness.coordinator.pauseForLifecycle();
    await harness.coordinator.resumeFromLifecycle();

    expect(harness.coordinator.snapshot.phase, RuntimePlayerPhase.paused);
    expect(
      harness.coordinator.snapshot.pauseSection,
      RuntimePlayerPauseSection.bag,
    );
    expect(harness.sessions.snapshot.state, GameSessionState.paused);
    expect(
      harness.adapter.calls.where((call) => call == 'resume'),
      isEmpty,
      reason: 'Foreground must not unpause a player-opened menu.',
    );
  });

  test('lifecycle autosave follows the explicit session save policy', () async {
    final harness = RuntimePlayerTestHarness(
      savePolicy: const GameSessionSavePolicy(
        autosaveOnLifecyclePause: false,
      ),
    );
    addTearDown(harness.dispose);
    await launchHarnessToPlaying(harness);
    harness.adapter.checkpoint = testPlayerCheckpoint();

    await harness.coordinator.pauseForLifecycle();

    expect(harness.saves.commits, isEmpty);
    expect(
      harness.sessions.snapshot.state,
      GameSessionState.lifecyclePaused,
    );
  });

  test('return to title checkpoints and disposes before publishing title',
      () async {
    final harness = RuntimePlayerTestHarness();
    addTearDown(harness.dispose);
    await launchHarnessToPlaying(harness);
    await openHarnessPause(harness);
    harness.adapter.checkpoint = testPlayerCheckpoint();
    var disposeCallsWhenTitlePublished = -1;
    final subscription = harness.coordinator.snapshots.listen((snapshot) {
      if (snapshot.phase == RuntimePlayerPhase.title) {
        disposeCallsWhenTitlePublished = harness.adapter.disposeCalls;
      }
    });
    addTearDown(subscription.cancel);

    final result = await harness.coordinator.dispatch(
      RuntimePlayerCommand(
        action: RuntimePlayerAction.returnToTitle,
        snapshotRevision: harness.coordinator.snapshot.revision,
      ),
    );
    await harness.coordinator.settle();

    expect(result.status, RuntimePlayerCommandStatus.accepted);
    expect(harness.saves.commits.single.status, SaveStatus.active);
    expect(
      harness.saves.commits.single.trigger,
      GameSessionCheckpointTrigger.sessionExit,
    );
    expect(harness.sessions.snapshot.state, GameSessionState.disposed);
    expect(harness.adapter.disposeCalls, 1);
    expect(disposeCallsWhenTitlePublished, 1);
    expect(harness.coordinator.snapshot.phase, RuntimePlayerPhase.title);
  });

  test('checkpoint failure keeps return to title retryable in pause', () async {
    final harness = RuntimePlayerTestHarness();
    addTearDown(harness.dispose);
    await launchHarnessToPlaying(harness);
    await openHarnessPause(harness);
    harness.adapter.checkpoint = testPlayerCheckpoint();
    harness.saves.commitError = StateError('disk full');

    final failed = await harness.coordinator.dispatch(
      RuntimePlayerCommand(
        action: RuntimePlayerAction.returnToTitle,
        snapshotRevision: harness.coordinator.snapshot.revision,
      ),
    );

    expect(failed.status, RuntimePlayerCommandStatus.failed);
    expect(harness.coordinator.snapshot.phase, RuntimePlayerPhase.paused);
    expect(
      harness.coordinator.snapshot.failure?.code,
      GameSessionFailureCode.storage,
    );
    expect(harness.sessions.snapshot.state, GameSessionState.paused);
    expect(harness.adapter.disposeCalls, 0);

    harness.saves.commitError = null;
    final retried = await harness.coordinator.dispatch(
      RuntimePlayerCommand(
        action: RuntimePlayerAction.returnToTitle,
        snapshotRevision: harness.coordinator.snapshot.revision,
      ),
    );

    expect(retried.status, RuntimePlayerCommandStatus.accepted);
    expect(harness.adapter.disposeCalls, 1);
    expect(harness.coordinator.snapshot.phase, RuntimePlayerPhase.title);
  });

  test('return to host is refused while playing or paused', () async {
    final harness = RuntimePlayerTestHarness();
    addTearDown(harness.dispose);
    await launchHarnessToPlaying(harness);

    final whilePlaying = await harness.coordinator.dispatch(
      RuntimePlayerCommand(
        action: RuntimePlayerAction.returnToHost,
        snapshotRevision: harness.coordinator.snapshot.revision,
      ),
    );
    expect(whilePlaying.status, RuntimePlayerCommandStatus.unavailable);

    await openHarnessPause(harness);
    final whilePaused = await harness.coordinator.dispatch(
      RuntimePlayerCommand(
        action: RuntimePlayerAction.returnToHost,
        snapshotRevision: harness.coordinator.snapshot.revision,
      ),
    );

    expect(whilePaused.status, RuntimePlayerCommandStatus.unavailable);
    expect(harness.exit.calls, 0);
  });

  test('title disposes the coordinator before returning to host once',
      () async {
    final harness = RuntimePlayerTestHarness();
    await harness.coordinator.initialize();

    final result = await harness.coordinator.dispatch(
      RuntimePlayerCommand(
        action: RuntimePlayerAction.returnToHost,
        snapshotRevision: harness.coordinator.snapshot.revision,
      ),
    );

    expect(result.status, RuntimePlayerCommandStatus.accepted);
    expect(harness.coordinator.snapshot.phase, RuntimePlayerPhase.externalExit);
    expect(harness.coordinator.isDisposed, isTrue);
    expect(harness.exit.calls, 1);
    expect(harness.exit.disposedWhenCalled, isTrue);

    await harness.coordinator.dispose();
    await harness.coordinator.dispose();
    expect(harness.exit.calls, 1);
  });

  test('teardown exception releases the session and leaves a safe warning',
      () async {
    final harness = RuntimePlayerTestHarness();
    addTearDown(harness.dispose);
    await launchHarnessToPlaying(harness);
    await openHarnessPause(harness);
    harness.adapter.stopError = StateError('native stop failed');

    final result = await harness.coordinator.dispatch(
      RuntimePlayerCommand(
        action: RuntimePlayerAction.returnToTitle,
        snapshotRevision: harness.coordinator.snapshot.revision,
      ),
    );
    await harness.coordinator.settle();

    expect(result.status, RuntimePlayerCommandStatus.accepted);
    expect(harness.sessions.snapshot.state, GameSessionState.disposed);
    expect(harness.adapter.disposeCalls, 1);
    expect(harness.coordinator.snapshot.phase, RuntimePlayerPhase.title);
    expect(
      harness.coordinator.snapshot.failure?.recoverability,
      GameSessionFailureRecoverability.titleOrHub,
    );
  });
}
