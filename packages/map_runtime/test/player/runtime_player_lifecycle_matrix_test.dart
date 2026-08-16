import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/map_runtime.dart';

import 'support/runtime_player_test_harness.dart';

void main() {
  test('suspending during an active checkpoint resumes without crashing',
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
    expect(harness.coordinator.snapshot.phase, RuntimePlayerPhase.saving);

    final suspended = harness.coordinator.pauseForLifecycle();
    gate.complete();
    await save;
    await suspended;

    await expectLater(harness.coordinator.resumeFromLifecycle(), completes);
    expect(
      harness.coordinator.snapshot.phase,
      isNot(RuntimePlayerPhase.lifecyclePaused),
      reason: 'the player must never stay stuck on the suspended phase',
    );
  });

  test('suspending on a terminal phase never suspends and never throws',
      () async {
    final harness = RuntimePlayerTestHarness();
    addTearDown(harness.dispose);
    await launchHarnessToPlaying(harness);
    harness.saves.commitError = StateError('disk full');
    harness.adapter.emitCompletion(testPlayerCompletion(harness));
    await harness.coordinator.settle();
    expect(harness.coordinator.snapshot.phase, RuntimePlayerPhase.completing);

    await harness.coordinator.pauseForLifecycle();

    expect(
      harness.coordinator.snapshot.phase,
      RuntimePlayerPhase.completing,
      reason: 'only a running or paused session may be lifecycle suspended',
    );
    await expectLater(harness.coordinator.resumeFromLifecycle(), completes);
    expect(harness.coordinator.snapshot.phase, RuntimePlayerPhase.completing);
  });

  test('suspending during credits never suspends and never throws', () async {
    final harness = RuntimePlayerTestHarness();
    addTearDown(harness.dispose);
    await launchHarnessToPlaying(harness);
    harness.adapter.emitCompletion(testPlayerCompletion(harness));
    await harness.coordinator.settle();
    await harness.coordinator.dispatch(
      RuntimePlayerCommand(
        action: RuntimePlayerAction.showCredits,
        snapshotRevision: harness.coordinator.snapshot.revision,
      ),
    );
    expect(harness.coordinator.snapshot.phase, RuntimePlayerPhase.credits);

    await harness.coordinator.pauseForLifecycle();
    await expectLater(harness.coordinator.resumeFromLifecycle(), completes);

    expect(
      harness.coordinator.snapshot.phase,
      isNot(RuntimePlayerPhase.lifecyclePaused),
    );
  });
}

Future<void> _waitUntil(bool Function() predicate) async {
  for (var attempt = 0; attempt < 1000; attempt++) {
    if (predicate()) return;
    await Future<void>.delayed(Duration.zero);
  }
  fail('condition was never reached');
}
