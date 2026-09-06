import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/map_runtime.dart';

import 'support/runtime_player_test_harness.dart';

void main() {
  test('host defaults remain distinct from saved preferences across snapshots',
      () async {
    final harness = RuntimePlayerTestHarness();
    addTearDown(harness.dispose);
    const defaults = PlayerPreferencesSnapshot(
      locale: 'en',
      accessibility: GameSessionAccessibilityOptions(),
      audioMix: RuntimeAudioMix(musicVolume: 0.8, effectsVolume: 0.8),
    );
    harness.preferences.defaultPreferences = defaults;
    harness.preferences.current = defaults.copyWith(
      locale: 'fr',
      audioMix: const RuntimeAudioMix(masterVolume: 0.3),
    );
    await launchHarnessToPlaying(harness);
    expect(harness.coordinator.snapshot.defaultPreferences, same(defaults));
    expect(harness.coordinator.snapshot.preferences!.locale, 'fr');
    await openHarnessPause(harness);
    await harness.coordinator.dispatch(RuntimePlayerCommand(
      action: RuntimePlayerAction.openOptions,
      snapshotRevision: harness.coordinator.snapshot.revision,
    ));
    await harness.coordinator.dispatch(RuntimePlayerCommand(
      action: RuntimePlayerAction.updatePreferences,
      snapshotRevision: harness.coordinator.snapshot.revision,
      payload: defaults.copyWith(dialogueTextSpeed: RuntimeDialogueTextSpeed.fast),
    ));
    expect(harness.coordinator.snapshot.defaultPreferences, same(defaults));
    expect(harness.coordinator.snapshot.preferences!.dialogueTextSpeed,
        RuntimeDialogueTextSpeed.fast);
  });

  test('launch and saved preferences reach the active runtime', () async {
    final harness = RuntimePlayerTestHarness();
    addTearDown(harness.dispose);
    await launchHarnessToPlaying(harness);
    expect(harness.adapter.appliedPreferences, hasLength(1));
    await openHarnessPause(harness);
    await harness.coordinator.dispatch(RuntimePlayerCommand(
      action: RuntimePlayerAction.openOptions,
      snapshotRevision: harness.coordinator.snapshot.revision,
    ));
    final preferences = harness.coordinator.snapshot.preferences!.copyWith(
      locale: 'en',
      dialogueTextSpeed: RuntimeDialogueTextSpeed.fast,
      menuEffects: RuntimePlayerMenuEffects.opaque,
    );
    harness.adapter.pauseDetailsLoader = () async => {
      RuntimePlayerPauseSection.map: RuntimePlayerPauseDetailSnapshot(
        section: RuntimePlayerPauseSection.map,
        title: harness.adapter.appliedPreferences.last.locale,
      ),
    };
    final result = await harness.coordinator.dispatch(RuntimePlayerCommand(
      action: RuntimePlayerAction.updatePreferences,
      snapshotRevision: harness.coordinator.snapshot.revision,
      payload: preferences,
    ));
    expect(result.status, RuntimePlayerCommandStatus.accepted);
    expect(harness.adapter.appliedPreferences.last, same(preferences));
    expect(harness.coordinator.snapshot.preferences, same(preferences));
    expect(harness.coordinator.snapshot.pauseDetailFor(RuntimePlayerPauseSection.map)!.title, 'en');
  });

  test('failed preference persistence keeps the confirmed runtime values',
      () async {
    final harness = RuntimePlayerTestHarness();
    addTearDown(harness.dispose);
    await launchHarnessToPlaying(harness);
    await openHarnessPause(harness);
    await harness.coordinator.dispatch(RuntimePlayerCommand(
      action: RuntimePlayerAction.openOptions,
      snapshotRevision: harness.coordinator.snapshot.revision,
    ));
    final confirmed = harness.coordinator.snapshot.preferences!;
    harness.preferences.saveError = StateError('disk unavailable');
    final result = await harness.coordinator.dispatch(RuntimePlayerCommand(
      action: RuntimePlayerAction.updatePreferences,
      snapshotRevision: harness.coordinator.snapshot.revision,
      payload: confirmed.copyWith(dialogueTextSpeed: RuntimeDialogueTextSpeed.fast),
    ));
    expect(result.status, RuntimePlayerCommandStatus.failed);
    expect(harness.coordinator.snapshot.preferences, same(confirmed));
    expect(harness.adapter.appliedPreferences, hasLength(1));
  });
}
