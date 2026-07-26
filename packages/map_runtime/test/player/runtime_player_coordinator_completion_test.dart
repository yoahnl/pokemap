import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import 'support/runtime_player_test_harness.dart';

void main() {
  test('Save publishes saving and returns to the same pause section', () async {
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
    harness.adapter.checkpoint = testPlayerCheckpoint();
    final phases = <RuntimePlayerPhase>[];
    final subscription = harness.coordinator.snapshots.listen(
      (snapshot) => phases.add(snapshot.phase),
    );
    addTearDown(subscription.cancel);

    final result = await harness.coordinator.dispatch(
      RuntimePlayerCommand(
        action: RuntimePlayerAction.save,
        snapshotRevision: harness.coordinator.snapshot.revision,
      ),
    );

    expect(result.status, RuntimePlayerCommandStatus.accepted);
    expect(phases, contains(RuntimePlayerPhase.saving));
    expect(harness.saves.commits.single.status, SaveStatus.active);
    expect(harness.coordinator.snapshot.phase, RuntimePlayerPhase.paused);
    expect(
      harness.coordinator.snapshot.pauseSection,
      RuntimePlayerPauseSection.bag,
    );
  });

  test('Save failure preserves the paused session and can be retried',
      () async {
    final harness = RuntimePlayerTestHarness();
    addTearDown(harness.dispose);
    await launchHarnessToPlaying(harness);
    await openHarnessPause(harness);
    harness.adapter.checkpoint = testPlayerCheckpoint();
    harness.saves.commitError = StateError('disk full');

    final failed = await harness.coordinator.dispatch(
      RuntimePlayerCommand(
        action: RuntimePlayerAction.save,
        snapshotRevision: harness.coordinator.snapshot.revision,
      ),
    );

    expect(failed.status, RuntimePlayerCommandStatus.failed);
    expect(harness.sessions.snapshot.state, GameSessionState.paused);
    expect(harness.coordinator.snapshot.phase, RuntimePlayerPhase.paused);
    expect(harness.coordinator.snapshot.failure?.code,
        GameSessionFailureCode.storage);
    expect(
      harness.coordinator.snapshot.isActionEnabled(RuntimePlayerAction.save),
      isTrue,
    );

    harness.saves.commitError = null;
    final retried = await harness.coordinator.dispatch(
      RuntimePlayerCommand(
        action: RuntimePlayerAction.save,
        snapshotRevision: harness.coordinator.snapshot.revision,
      ),
    );

    expect(retried.status, RuntimePlayerCommandStatus.accepted);
    expect(harness.saves.commits, hasLength(1));
    expect(harness.coordinator.snapshot.failure, isNull);
  });

  test('GameCompleted locks gameplay and commits before publishing result',
      () async {
    final harness = RuntimePlayerTestHarness();
    addTearDown(harness.dispose);
    await launchHarnessToPlaying(harness);
    final completion = testPlayerCompletion(harness);

    harness.adapter.emitCompletion(completion);
    await harness.coordinator.settle();

    expect(harness.adapter.gameplayLocked, isTrue);
    expect(harness.saves.commits.single.status, SaveStatus.completed);
    expect(harness.coordinator.snapshot.phase, RuntimePlayerPhase.result);
    expect(harness.coordinator.snapshot.result?.title, 'Victoire');
    expect(harness.coordinator.snapshot.credits?.endingLabel, 'Fin principale');
  });

  test('completion save failure stays retryable before exposing result',
      () async {
    final harness = RuntimePlayerTestHarness();
    addTearDown(harness.dispose);
    await launchHarnessToPlaying(harness);
    harness.saves.commitError = StateError('disk full');

    harness.adapter.emitCompletion(testPlayerCompletion(harness));
    await harness.coordinator.settle();

    expect(harness.coordinator.snapshot.phase, RuntimePlayerPhase.completing);
    expect(harness.adapter.completionAcknowledgements, <bool>[false]);
    expect(
      harness.coordinator.snapshot.isActionEnabled(RuntimePlayerAction.retry),
      isTrue,
    );

    harness.saves.commitError = null;
    final result = await harness.coordinator.dispatch(
      RuntimePlayerCommand(
        action: RuntimePlayerAction.retry,
        snapshotRevision: harness.coordinator.snapshot.revision,
      ),
    );
    await harness.coordinator.settle();

    expect(result.status, RuntimePlayerCommandStatus.accepted);
    expect(harness.adapter.completionAcknowledgements, <bool>[false, true]);
    expect(harness.coordinator.snapshot.phase, RuntimePlayerPhase.result);
  });

  test('result opens credits and tears down before returning to title',
      () async {
    final harness = RuntimePlayerTestHarness();
    addTearDown(harness.dispose);
    await launchHarnessToPlaying(harness);
    harness.adapter.emitCompletion(testPlayerCompletion(harness));
    await harness.coordinator.settle();
    var disposeCallsWhenTitlePublished = -1;
    final subscription = harness.coordinator.snapshots.listen((snapshot) {
      if (snapshot.phase == RuntimePlayerPhase.title) {
        disposeCallsWhenTitlePublished = harness.adapter.disposeCalls;
      }
    });
    addTearDown(subscription.cancel);

    final credits = await harness.coordinator.dispatch(
      RuntimePlayerCommand(
        action: RuntimePlayerAction.showCredits,
        snapshotRevision: harness.coordinator.snapshot.revision,
      ),
    );
    expect(credits.status, RuntimePlayerCommandStatus.accepted);
    expect(harness.coordinator.snapshot.phase, RuntimePlayerPhase.credits);

    final finished = await harness.coordinator.dispatch(
      RuntimePlayerCommand(
        action: RuntimePlayerAction.finishCredits,
        snapshotRevision: harness.coordinator.snapshot.revision,
      ),
    );
    await harness.coordinator.settle();

    expect(finished.status, RuntimePlayerCommandStatus.accepted);
    expect(harness.coordinator.snapshot.phase, RuntimePlayerPhase.title);
    expect(harness.sessions.snapshot.state, GameSessionState.disposed);
    expect(disposeCallsWhenTitlePublished, 1);
    expect(
      harness.adapter.calls,
      containsAllInOrder(<String>['stop:title', 'dispose']),
    );
  });

  test('Hub completion exits to the host after credits', () async {
    final harness = RuntimePlayerTestHarness();
    addTearDown(harness.dispose);
    await launchHarnessToPlaying(harness);
    harness.adapter.emitCompletion(
      testPlayerCompletion(
        harness,
        destination: GameCompletionDestination.hub,
      ),
    );
    await harness.coordinator.settle();

    expect(
      harness.coordinator.snapshot
          .isActionEnabled(RuntimePlayerAction.returnToHost),
      isTrue,
    );
    expect(
      harness.coordinator.snapshot
          .isActionEnabled(RuntimePlayerAction.returnToTitle),
      isFalse,
    );

    await harness.coordinator.dispatch(
      RuntimePlayerCommand(
        action: RuntimePlayerAction.showCredits,
        snapshotRevision: harness.coordinator.snapshot.revision,
      ),
    );
    final finished = await harness.coordinator.dispatch(
      RuntimePlayerCommand(
        action: RuntimePlayerAction.finishCredits,
        snapshotRevision: harness.coordinator.snapshot.revision,
      ),
    );
    await harness.coordinator.settle();

    expect(finished.status, RuntimePlayerCommandStatus.accepted);
    expect(harness.coordinator.snapshot.phase, RuntimePlayerPhase.externalExit);
    expect(harness.exit.calls, 1);
    expect(harness.sessions.snapshot.state, GameSessionState.disposed);
  });
}
