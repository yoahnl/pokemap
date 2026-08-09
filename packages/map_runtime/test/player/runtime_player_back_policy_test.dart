import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/map_runtime.dart';

import 'support/runtime_player_test_harness.dart';

void main() {
  test('Back returns title options to the runtime title', () async {
    final harness = RuntimePlayerTestHarness();
    addTearDown(harness.dispose);
    await harness.coordinator.initialize();
    await harness.coordinator.dispatch(
      RuntimePlayerCommand(
        action: RuntimePlayerAction.openOptions,
        snapshotRevision: harness.coordinator.snapshot.revision,
      ),
    );

    final result = await harness.coordinator.requestBack(
      snapshotRevision: harness.coordinator.snapshot.revision,
    );

    expect(result.status, RuntimePlayerCommandStatus.accepted);
    expect(harness.coordinator.snapshot.phase, RuntimePlayerPhase.title);
    expect(harness.coordinator.snapshot.pauseSection, isNull);
    expect(harness.exit.calls, 0);
  });

  test('Back returns the runtime title to its host', () async {
    final harness = RuntimePlayerTestHarness();
    await harness.coordinator.initialize();

    final result = await harness.coordinator.requestBack(
      snapshotRevision: harness.coordinator.snapshot.revision,
    );

    expect(result.status, RuntimePlayerCommandStatus.accepted);
    expect(harness.exit.calls, 1);
    expect(harness.exit.disposedWhenCalled, isTrue);
  });

  test('Back opens, descends and closes the runtime pause menu', () async {
    final harness = RuntimePlayerTestHarness();
    addTearDown(harness.dispose);
    await launchHarnessToPlaying(harness);

    final opened = await harness.coordinator.requestBack(
      snapshotRevision: harness.coordinator.snapshot.revision,
    );
    expect(opened.status, RuntimePlayerCommandStatus.accepted);
    expect(harness.coordinator.snapshot.phase, RuntimePlayerPhase.paused);
    expect(
      harness.coordinator.snapshot.pauseSection,
      RuntimePlayerPauseSection.root,
    );

    await harness.coordinator.dispatch(
      RuntimePlayerCommand(
        action: RuntimePlayerAction.openOptions,
        snapshotRevision: harness.coordinator.snapshot.revision,
      ),
    );
    final returned = await harness.coordinator.requestBack(
      snapshotRevision: harness.coordinator.snapshot.revision,
    );
    expect(returned.status, RuntimePlayerCommandStatus.accepted);
    expect(
      harness.coordinator.snapshot.pauseSection,
      RuntimePlayerPauseSection.root,
    );

    final resumed = await harness.coordinator.requestBack(
      snapshotRevision: harness.coordinator.snapshot.revision,
    );
    expect(resumed.status, RuntimePlayerCommandStatus.accepted);
    expect(harness.coordinator.snapshot.phase, RuntimePlayerPhase.playing);
  });

  test('Back closes a runtime world service before changing player phase',
      () async {
    final harness = RuntimePlayerTestHarness();
    addTearDown(harness.dispose);
    await launchHarnessToPlaying(harness);
    harness.adapter.publishWorldService(
      RuntimeWorldServiceSnapshot(
        revision: 4,
        request: const OpenShopService(
          interactionId: 'merchant',
          shopId: 'station-shop',
        ),
        stage: RuntimeWorldServiceStage.active,
        actions: const <RuntimeWorldServiceActionAvailability>[
          RuntimeWorldServiceActionAvailability.enabled(
            RuntimeWorldServiceAction.close,
          ),
        ],
      ),
    );
    await harness.coordinator.settle();

    final result = await harness.coordinator.requestBack(
      snapshotRevision: harness.coordinator.snapshot.revision,
    );

    expect(result.status, RuntimePlayerCommandStatus.accepted);
    expect(harness.adapter.worldServiceCommands.single.action,
        RuntimeWorldServiceAction.close);
    expect(harness.coordinator.snapshot.phase, RuntimePlayerPhase.playing);
  });

  test('Back rejects a stale player snapshot', () async {
    final harness = RuntimePlayerTestHarness();
    addTearDown(harness.dispose);
    await harness.coordinator.initialize();

    final result = await harness.coordinator.requestBack(snapshotRevision: 0);

    expect(result.status, RuntimePlayerCommandStatus.stale);
    expect(harness.exit.calls, 0);
  });

  test('Back cancels an in-flight descriptor without waiting behind it',
      () async {
    final gate = Completer<void>();
    final harness = RuntimePlayerTestHarness(
      descriptorGate: gate.future,
      defaultSaveSlot: const RuntimePlayerLoadSlot(
        profileId: 'player',
        slotId: 'slot_1',
      ),
    );
    addTearDown(harness.dispose);
    await harness.coordinator.initialize();
    final launch = harness.coordinator.dispatch(
      RuntimePlayerCommand(
        action: RuntimePlayerAction.newGame,
        snapshotRevision: harness.coordinator.snapshot.revision,
      ),
    );
    await Future<void>.delayed(Duration.zero);

    final back = harness.coordinator.requestBack(
      snapshotRevision: harness.coordinator.snapshot.revision,
    );
    await Future<void>.delayed(Duration.zero);
    final phaseBeforeDescriptorCompletes = harness.coordinator.snapshot.phase;
    gate.complete();

    expect((await back).status, RuntimePlayerCommandStatus.accepted);
    expect((await launch).status, RuntimePlayerCommandStatus.cancelled);
    expect(phaseBeforeDescriptorCompletes, RuntimePlayerPhase.title);
    expect(harness.adapters, isEmpty);
  });
}
