import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import 'support/runtime_player_test_harness.dart';

void main() {
  test('a second Save is refused while one checkpoint transaction is active',
      () async {
    final harness = RuntimePlayerTestHarness();
    addTearDown(harness.dispose);
    await launchHarnessToPlaying(harness);
    await openHarnessPause(harness);
    harness.adapter.checkpoint = testPlayerCheckpoint();
    final gate = Completer<void>();
    harness.saves.commitGate = gate;

    final first = harness.coordinator.dispatch(
      RuntimePlayerCommand(
        action: RuntimePlayerAction.save,
        snapshotRevision: harness.coordinator.snapshot.revision,
      ),
    );
    await _waitUntil(() => harness.saves.activeCommits == 1);
    final second = harness.coordinator.dispatch(
      RuntimePlayerCommand(
        action: RuntimePlayerAction.save,
        snapshotRevision: harness.coordinator.snapshot.revision,
      ),
    );

    gate.complete();
    final results = await Future.wait(<Future<RuntimePlayerCommandResult>>[
      first,
      second,
    ]);

    expect(results.first.status, RuntimePlayerCommandStatus.accepted);
    expect(results.last.status, RuntimePlayerCommandStatus.unavailable);
    expect(results.last.safeMessage, contains('déjà en cours'));
    expect(harness.saves.commitAttempts, hasLength(1));
    expect(harness.saves.maxConcurrentCommits, 1);
    expect(harness.coordinator.snapshot.phase, RuntimePlayerPhase.paused);
  });

  test('return to title waits for the active Save safe boundary', () async {
    final harness = RuntimePlayerTestHarness();
    addTearDown(harness.dispose);
    await launchHarnessToPlaying(harness);
    await openHarnessPause(harness);
    harness.adapter.checkpoint = testPlayerCheckpoint();
    final gate = Completer<void>();
    harness.saves.commitGate = gate;

    final save = harness.coordinator.dispatch(
      RuntimePlayerCommand(
        action: RuntimePlayerAction.save,
        snapshotRevision: harness.coordinator.snapshot.revision,
      ),
    );
    await _waitUntil(() => harness.saves.activeCommits == 1);
    final returnToTitle = harness.coordinator.dispatch(
      RuntimePlayerCommand(
        action: RuntimePlayerAction.returnToTitle,
        snapshotRevision: harness.coordinator.snapshot.revision,
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(harness.adapter.disposeCalls, 0);
    expect(harness.coordinator.snapshot.phase, RuntimePlayerPhase.saving);

    gate.complete();
    expect(
      (await save).status,
      RuntimePlayerCommandStatus.accepted,
    );
    expect(
      (await returnToTitle).status,
      RuntimePlayerCommandStatus.accepted,
    );

    expect(harness.saves.commitAttempts, hasLength(1));
    expect(harness.adapter.disposeCalls, 1);
    expect(harness.coordinator.snapshot.phase, RuntimePlayerPhase.title);
  });

  test('a confirmed Save enables Continue after returning to title', () async {
    final harness = RuntimePlayerTestHarness();
    addTearDown(harness.dispose);
    await launchHarnessToPlaying(harness);
    await openHarnessPause(harness);
    harness.adapter.checkpoint = testPlayerCheckpoint();

    final save = await harness.coordinator.dispatch(
      RuntimePlayerCommand(
        action: RuntimePlayerAction.save,
        snapshotRevision: harness.coordinator.snapshot.revision,
      ),
    );
    expect(save.status, RuntimePlayerCommandStatus.accepted);
    expect(
      harness.saves.commits.single.trigger,
      GameSessionCheckpointTrigger.manual,
    );
    expect(harness.saves.commits.single.isAutosave, isFalse);
    expect(
      harness.coordinator.snapshot.activeSaveAddress,
      RuntimePlayerSaveAddress(
        gameId: harness.source.identity.gameId,
        profileId: 'player',
        slotId: 'slot_1',
      ),
    );
    expect(
      harness.coordinator.snapshot.saveReceipt?.address.slotId,
      'slot_1',
    );

    final title = await harness.coordinator.dispatch(
      RuntimePlayerCommand(
        action: RuntimePlayerAction.returnToTitle,
        snapshotRevision: harness.coordinator.snapshot.revision,
      ),
    );
    expect(title.status, RuntimePlayerCommandStatus.accepted);
    expect(
      harness.coordinator.snapshot
          .isActionEnabled(RuntimePlayerAction.continueGame),
      isTrue,
    );

    final continueGame = await harness.coordinator.dispatch(
      RuntimePlayerCommand(
        action: RuntimePlayerAction.continueGame,
        snapshotRevision: harness.coordinator.snapshot.revision,
      ),
    );

    expect(continueGame.status, RuntimePlayerCommandStatus.accepted);
    expect(harness.source.requests.last.launchMode,
        GameSessionLaunchMode.continueGame);
    expect(harness.source.requests.last.saveReadHandle, isNotNull);
  });

  test('GameCompleted is committed after an active Save without overlap',
      () async {
    final harness = RuntimePlayerTestHarness();
    addTearDown(harness.dispose);
    await launchHarnessToPlaying(harness);
    await openHarnessPause(harness);
    harness.adapter.checkpoint = testPlayerCheckpoint();
    final gate = Completer<void>();
    harness.saves.commitGate = gate;

    final save = harness.coordinator.dispatch(
      RuntimePlayerCommand(
        action: RuntimePlayerAction.save,
        snapshotRevision: harness.coordinator.snapshot.revision,
      ),
    );
    await _waitUntil(() => harness.saves.activeCommits == 1);

    harness.adapter.emitCompletion(testPlayerCompletion(harness));
    await Future<void>.delayed(Duration.zero);
    expect(harness.saves.activeCommits, 1);
    expect(harness.saves.maxConcurrentCommits, 1);

    gate.complete();
    await save;
    await harness.coordinator.settle();

    expect(
      harness.saves.commits.map((commit) => commit.status),
      <SaveStatus>[SaveStatus.active, SaveStatus.completed],
    );
    expect(harness.saves.maxConcurrentCommits, 1);
    expect(harness.coordinator.snapshot.phase, RuntimePlayerPhase.result);
  });
}

Future<void> _waitUntil(
  bool Function() predicate, {
  int attempts = 50,
}) async {
  for (var attempt = 0; attempt < attempts; attempt++) {
    if (predicate()) return;
    await Future<void>.delayed(Duration.zero);
  }
  fail('Condition was not reached before the test timeout.');
}
