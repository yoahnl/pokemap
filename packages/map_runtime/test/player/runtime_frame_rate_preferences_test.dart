import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/map_runtime.dart';

import 'support/runtime_player_test_harness.dart';

void main() {
  setUp(() => AveluneFrameRate.setLimit(60));
  tearDown(() => AveluneFrameRate.setLimit(60));

  test('loaded preferences apply the frame limit before entering the game',
      () async {
    final harness = RuntimePlayerTestHarness();
    addTearDown(harness.dispose);
    harness.preferences.current = harness.preferences.current.copyWith(
      targetFramesPerSecond: 45,
    );

    await harness.coordinator.initialize();

    expect(harness.coordinator.snapshot.phase, RuntimePlayerPhase.title);
    expect(AveluneFrameRate.limit, 45);
  });

  test('confirmed frame limit changes reach the active rendering clock',
      () async {
    final harness = RuntimePlayerTestHarness();
    addTearDown(harness.dispose);
    await launchHarnessToPlaying(harness);
    await openHarnessPause(harness);

    final result = await harness.coordinator.dispatch(RuntimePlayerCommand(
      action: RuntimePlayerAction.updatePreferences,
      snapshotRevision: harness.coordinator.snapshot.revision,
      payload: harness.coordinator.preferences!.copyWith(
        targetFramesPerSecond: 30,
      ),
    ));

    expect(result.status, RuntimePlayerCommandStatus.accepted);
    expect(AveluneFrameRate.limit, 30);
    expect(harness.preferences.current.targetFramesPerSecond, 30);
    expect(harness.coordinator.snapshot.preferences!.targetFramesPerSecond, 30);
    expect(harness.adapter.appliedPreferences, hasLength(1));
  });

  test('failed persistence retains the confirmed frame limit', () async {
    final harness = RuntimePlayerTestHarness();
    addTearDown(harness.dispose);
    await launchHarnessToPlaying(harness);
    await openHarnessPause(harness);
    harness.preferences.saveError = StateError('unavailable storage');

    final result = await harness.coordinator.dispatch(RuntimePlayerCommand(
      action: RuntimePlayerAction.updatePreferences,
      snapshotRevision: harness.coordinator.snapshot.revision,
      payload: harness.coordinator.preferences!.copyWith(
        targetFramesPerSecond: 120,
      ),
    ));

    expect(result.status, RuntimePlayerCommandStatus.failed);
    expect(AveluneFrameRate.limit, 60);
    expect(harness.coordinator.preferences!.targetFramesPerSecond, 60);
  });

  test('shared frame limit changes refresh options without saving other values',
      () async {
    final harness = RuntimePlayerTestHarness();
    addTearDown(harness.dispose);
    await launchHarnessToPlaying(harness);
    final before = harness.coordinator.preferences!;
    final sessionId = harness.sessions.snapshot.descriptor!.sessionId;

    AveluneFrameRate.setLimit(90);

    expect(harness.coordinator.preferences!.targetFramesPerSecond, 90);
    expect(harness.coordinator.snapshot.preferences!.targetFramesPerSecond, 90);
    expect(harness.coordinator.preferences!.audioMix, same(before.audioMix));
    expect(harness.sessions.snapshot.descriptor!.sessionId, sessionId);
    expect(harness.preferences.loads, 1);
    expect(harness.preferences.saves, 0);
    expect(harness.adapter.appliedPreferences, hasLength(1));
  });

  test('disposed players no longer observe shared frame limits', () async {
    final harness = RuntimePlayerTestHarness();
    await harness.coordinator.initialize();
    await harness.dispose();
    final revision = harness.coordinator.snapshot.revision;

    AveluneFrameRate.setLimit(120);

    expect(harness.coordinator.snapshot.revision, revision);
  });

  test('a pending audio save retains a newer shared frame limit', () async {
    final harness = RuntimePlayerTestHarness();
    addTearDown(harness.dispose);
    await launchHarnessToPlaying(harness);
    await openHarnessPause(harness);
    final gate = Completer<void>();
    harness.preferences.saveGate = gate;
    final saving = harness.coordinator.dispatch(RuntimePlayerCommand(
      action: RuntimePlayerAction.updatePreferences,
      snapshotRevision: harness.coordinator.snapshot.revision,
      payload: harness.coordinator.preferences!.copyWith(
        audioMix: const RuntimeAudioMix(masterVolume: .4),
      ),
    ));
    await Future<void>.delayed(Duration.zero);

    AveluneFrameRate.setLimit(30);
    gate.complete();
    final result = await saving;

    expect(result.status, RuntimePlayerCommandStatus.accepted);
    expect(AveluneFrameRate.limit, 30);
    expect(harness.coordinator.preferences!.targetFramesPerSecond, 30);
    expect(harness.coordinator.preferences!.audioMix.masterVolume, .4);
  });

  test('a disposed pending title cannot change shared rendering preferences',
      () async {
    final harness = RuntimePlayerTestHarness();
    final gate = Completer<void>();
    harness.preferences.loadGate = gate;
    harness.preferences.current = harness.preferences.current.copyWith(
      targetFramesPerSecond: 45,
    );
    final loading = harness.coordinator.initialize();
    await Future<void>.delayed(Duration.zero);
    await harness.dispose();

    AveluneFrameRate.setLimit(120);
    gate.complete();
    await loading;

    expect(AveluneFrameRate.limit, 120);
  });

  test('a delayed title load retains a newer shared frame limit', () async {
    final harness = RuntimePlayerTestHarness();
    addTearDown(harness.dispose);
    final gate = Completer<void>();
    harness.preferences.loadGate = gate;
    harness.preferences.current = harness.preferences.current.copyWith(
      targetFramesPerSecond: 45,
    );
    final loading = harness.coordinator.initialize();
    await Future<void>.delayed(Duration.zero);

    AveluneFrameRate.setLimit(90);
    gate.complete();
    await loading;

    expect(AveluneFrameRate.limit, 90);
    expect(harness.coordinator.preferences!.targetFramesPerSecond, 90);
  });
}
