import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/map_runtime.dart';

import 'support/runtime_player_test_harness.dart';

void main() {
  test('initializes a title without save and explains unavailable actions',
      () async {
    final harness = RuntimePlayerTestHarness();
    addTearDown(harness.dispose);

    expect(harness.coordinator.snapshot.phase, RuntimePlayerPhase.boot);

    await harness.coordinator.initialize();

    final snapshot = harness.coordinator.snapshot;
    expect(snapshot.phase, RuntimePlayerPhase.title);
    expect(snapshot.isActionEnabled(RuntimePlayerAction.newGame), isTrue);
    expect(snapshot.isActionEnabled(RuntimePlayerAction.continueGame), isFalse);
    expect(snapshot.isActionEnabled(RuntimePlayerAction.load), isFalse);
    expect(
      snapshot.unavailableReasonFor(RuntimePlayerAction.continueGame),
      isNotEmpty,
    );
    expect(harness.preferences.loads, 1);
  });

  test('initializes Continue and Load from a compatible scoped save', () async {
    final seed = RuntimePlayerTestHarness();
    final save = compatiblePlayerSave(seed.source.identity);
    await seed.dispose();
    final harness = RuntimePlayerTestHarness(latestSave: save);
    addTearDown(harness.dispose);

    await harness.coordinator.initialize();

    expect(
      harness.coordinator.snapshot
          .isActionEnabled(RuntimePlayerAction.continueGame),
      isTrue,
    );
    expect(
      harness.coordinator.snapshot.isActionEnabled(RuntimePlayerAction.load),
      isTrue,
    );
  });

  test('loads title preferences and save summary concurrently once', () async {
    final seed = RuntimePlayerTestHarness();
    final save = compatiblePlayerSave(seed.source.identity);
    await seed.dispose();
    final harness = RuntimePlayerTestHarness(latestSave: save);
    addTearDown(harness.dispose);
    final preferencesGate = Completer<void>();
    final saveGate = Completer<void>();
    harness.preferences.loadGate = preferencesGate;
    harness.saves.latestSummaryGate = saveGate;

    final initialization = harness.coordinator.initialize();
    try {
      await Future<void>.delayed(Duration.zero);
      expect(harness.preferences.loads, 1);
      expect(harness.saves.latestSummaryReads, 1);
    } finally {
      preferencesGate.complete();
      saveGate.complete();
    }
    await initialization;

    expect(harness.coordinator.latestSave, same(save));
    expect(harness.saves.latestSummaryReads, 1);
  });

  test('launches a new game and follows session progress into playing',
      () async {
    final harness = RuntimePlayerTestHarness();
    addTearDown(harness.dispose);
    await harness.coordinator.initialize();

    final command = RuntimePlayerCommand(
      action: RuntimePlayerAction.newGame,
      snapshotRevision: harness.coordinator.snapshot.revision,
      payload: const RuntimePlayerLoadSlot(
        profileId: 'player',
        slotId: 'slot_1',
      ),
    );
    final result = await harness.coordinator.dispatch(command);

    expect(result.status, RuntimePlayerCommandStatus.accepted);
    expect(
      harness.coordinator.snapshot.phase,
      RuntimePlayerPhase.preparingSession,
    );
    expect(harness.source.requests.single.launchMode,
        GameSessionLaunchMode.newGame);
    expect(harness.source.requests.single.saveReadHandle, isNull);

    harness.adapter.emit(
      const GameSessionLoading(
        'runtime-player-session-1',
        GameSessionLoadingProgress(
          stage: 'project',
          current: 1,
          total: 3,
        ),
      ),
    );
    await harness.coordinator.settle();
    expect(
        harness.coordinator.snapshot.phase, RuntimePlayerPhase.loadingSession);
    expect(harness.coordinator.snapshot.loadingProgress?.stage, 'project');

    harness.adapter.emitRunning();
    await harness.coordinator.settle();
    expect(harness.coordinator.snapshot.phase, RuntimePlayerPhase.playing);
  });

  test('Continue resolves an opaque save handle before launch', () async {
    final seed = RuntimePlayerTestHarness();
    final save = compatiblePlayerSave(seed.source.identity);
    await seed.dispose();
    final harness = RuntimePlayerTestHarness(latestSave: save);
    addTearDown(harness.dispose);
    await harness.coordinator.initialize();

    final result = await harness.coordinator.dispatch(
      RuntimePlayerCommand(
        action: RuntimePlayerAction.continueGame,
        snapshotRevision: harness.coordinator.snapshot.revision,
      ),
    );

    expect(result.status, RuntimePlayerCommandStatus.accepted);
    expect(
      harness.source.requests.single.saveReadHandle,
      'save:player:slot_1',
    );
    expect(
      harness.source.requests.single.launchMode,
      GameSessionLaunchMode.continueGame,
    );
  });

  test('Load requires an explicit slot and keeps a distinct launch mode',
      () async {
    final seed = RuntimePlayerTestHarness();
    final save = compatiblePlayerSave(seed.source.identity);
    await seed.dispose();
    final harness = RuntimePlayerTestHarness(latestSave: save);
    addTearDown(harness.dispose);
    await harness.coordinator.initialize();

    final result = await harness.coordinator.dispatch(
      RuntimePlayerCommand(
        action: RuntimePlayerAction.load,
        snapshotRevision: harness.coordinator.snapshot.revision,
        payload: const RuntimePlayerLoadSlot(
          profileId: 'player',
          slotId: 'slot_1',
        ),
      ),
    );

    expect(result.status, RuntimePlayerCommandStatus.accepted);
    expect(
      harness.source.requests.single.launchMode,
      GameSessionLaunchMode.load,
    );
    expect(
      harness.source.requests.single.saveReadHandle,
      'save:player:slot_1',
    );
  });

  test('rejects stale and duplicate title commands without a second session',
      () async {
    final gate = Completer<void>();
    final harness = RuntimePlayerTestHarness(descriptorGate: gate.future);
    addTearDown(harness.dispose);
    await harness.coordinator.initialize();
    final revision = harness.coordinator.snapshot.revision;
    final command = RuntimePlayerCommand(
      action: RuntimePlayerAction.newGame,
      snapshotRevision: revision,
      payload: const RuntimePlayerLoadSlot(
        profileId: 'player',
        slotId: 'slot_1',
      ),
    );

    final first = harness.coordinator.dispatch(command);
    await Future<void>.delayed(Duration.zero);
    final second = harness.coordinator.dispatch(command);
    gate.complete();

    expect((await first).status, RuntimePlayerCommandStatus.accepted);
    expect((await second).status, RuntimePlayerCommandStatus.stale);
    expect(harness.source.requests, hasLength(1));
    expect(harness.adapters, hasLength(1));
  });

  test('cancels a launch before the session descriptor is created', () async {
    final gate = Completer<void>();
    final harness = RuntimePlayerTestHarness(descriptorGate: gate.future);
    addTearDown(harness.dispose);
    await harness.coordinator.initialize();

    final launch = harness.coordinator.dispatch(
      RuntimePlayerCommand(
        action: RuntimePlayerAction.newGame,
        snapshotRevision: harness.coordinator.snapshot.revision,
        payload: const RuntimePlayerLoadSlot(
          profileId: 'player',
          slotId: 'slot_1',
        ),
      ),
    );
    await Future<void>.delayed(Duration.zero);

    final cancel = await harness.coordinator.dispatch(
      RuntimePlayerCommand(
        action: RuntimePlayerAction.cancel,
        snapshotRevision: harness.coordinator.snapshot.revision,
      ),
    );
    gate.complete();

    expect(cancel.status, RuntimePlayerCommandStatus.accepted);
    expect((await launch).status, RuntimePlayerCommandStatus.cancelled);
    expect(harness.coordinator.snapshot.phase, RuntimePlayerPhase.title);
    expect(harness.adapters, isEmpty);
  });

  test('converts launch errors into a recoverable player failure', () async {
    final harness = RuntimePlayerTestHarness(
      descriptorError: StateError('package unavailable'),
    );
    addTearDown(harness.dispose);
    await harness.coordinator.initialize();

    final result = await harness.coordinator.dispatch(
      RuntimePlayerCommand(
        action: RuntimePlayerAction.newGame,
        snapshotRevision: harness.coordinator.snapshot.revision,
        payload: const RuntimePlayerLoadSlot(
          profileId: 'player',
          slotId: 'slot_1',
        ),
      ),
    );

    expect(result.status, RuntimePlayerCommandStatus.failed);
    expect(harness.coordinator.snapshot.phase, RuntimePlayerPhase.error);
    expect(harness.coordinator.snapshot.failure?.safeMessage, isNotEmpty);
    expect(
      harness.coordinator.snapshot.isActionEnabled(RuntimePlayerAction.retry),
      isTrue,
    );
  });

  test('projects contextual world services without replacing the player phase',
      () async {
    final harness = RuntimePlayerTestHarness();
    addTearDown(harness.dispose);
    await launchHarnessToPlaying(harness);
    final service = RuntimeWorldServiceSnapshot(
      revision: 8,
      request: const OpenShopService(
        interactionId: 'npc.merchant',
        shopId: 'mart',
      ),
      stage: RuntimeWorldServiceStage.active,
    );

    harness.adapter.publishWorldService(service);
    await harness.coordinator.settle();

    expect(harness.coordinator.snapshot.phase, RuntimePlayerPhase.playing);
    expect(harness.coordinator.snapshot.worldService, same(service));
    final result = await harness.coordinator.dispatchWorldService(
      const RuntimeWorldServiceCommand(
        action: RuntimeWorldServiceAction.close,
        snapshotRevision: 8,
      ),
    );
    expect(result.status, RuntimeWorldServiceCommandStatus.accepted);
    expect(harness.adapter.worldServiceCommands.single.action,
        RuntimeWorldServiceAction.close);

    harness.adapter.publishWorldService(null);
    await harness.coordinator.settle();
    expect(harness.coordinator.snapshot.worldService, isNull);
    expect(harness.coordinator.snapshot.phase, RuntimePlayerPhase.playing);
  });

  test('retry recovers a title initialization failure without deadlocking',
      () async {
    final harness = RuntimePlayerTestHarness();
    addTearDown(harness.dispose);
    harness.preferences.loadError = StateError('preferences unavailable');

    await harness.coordinator.initialize();
    expect(harness.coordinator.snapshot.phase, RuntimePlayerPhase.error);
    harness.preferences.loadError = null;

    final result = await harness.coordinator
        .dispatch(
          RuntimePlayerCommand(
            action: RuntimePlayerAction.retry,
            snapshotRevision: harness.coordinator.snapshot.revision,
          ),
        )
        .timeout(const Duration(seconds: 1));

    expect(result.status, RuntimePlayerCommandStatus.accepted);
    expect(harness.coordinator.snapshot.phase, RuntimePlayerPhase.title);
  });
}
