import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import '../player/support/runtime_player_test_harness.dart';

void main() {
  for (final paused in [false, true]) {
    test(
        'atomic companion data is readable while ${paused ? 'paused' : 'running'}',
        () async {
      final harness = RuntimePlayerTestHarness();
      addTearDown(harness.dispose);
      await launchHarnessToPlaying(harness);
      if (paused) await openHarnessPause(harness);
      final menuState = const PlayerPauseMenuState.empty()
          .setActionVisibility(ProjectPauseActionId.bag, visible: false);
      final profile = RuntimePlayerPauseDetailSnapshot(
        section: RuntimePlayerPauseSection.profile,
        title: 'Current profile',
        profile: RuntimePlayerProfileSnapshot(
          playerName: 'Current trainer',
          currentMapId: 'route-7',
          money: 1234,
        ),
      );
      harness.adapter.pauseMenuState = menuState;
      harness.adapter.pauseDetails = {
        RuntimePlayerPauseSection.profile: profile,
      };
      final canonical = harness.sessions.snapshot;
      harness.adapter.calls.clear();

      final data = await harness.sessions.readCompanionMenuData();

      expect(data, isNotNull);
      expect(data!.pauseMenuState, same(menuState));
      expect(
          data.pauseDetails[RuntimePlayerPauseSection.profile], same(profile));
      expect(harness.sessions.snapshot, same(canonical));
      expect(harness.adapter.calls, ['companion-menu']);
      expect(
        harness.sessions.handleInput(
          const RuntimeInputEvent.press(RuntimeInputControl.right),
        ),
        !paused,
      );
    });
  }

  test('companion data is absent without an active session', () async {
    final harness = RuntimePlayerTestHarness();
    addTearDown(harness.dispose);

    expect(await harness.sessions.readCompanionMenuData(), isNull);
    await launchHarnessToPlaying(harness);
    final adapter = harness.adapter;
    await harness.sessions.terminate();
    final calls = List<String>.of(adapter.calls);

    expect(await harness.sessions.readCompanionMenuData(), isNull);
    expect(adapter.calls, calls);
  });

  test('terminating a session rejects its pending companion data', () async {
    final harness = RuntimePlayerTestHarness();
    addTearDown(harness.dispose);
    await launchHarnessToPlaying(harness);
    final started = Completer<void>();
    final pending = Completer<RuntimePlayerCompanionMenuData>();
    harness.adapter.companionMenuLoader = () {
      started.complete();
      return pending.future;
    };
    final reading = harness.sessions.readCompanionMenuData();
    await started.future;
    await harness.sessions.terminate();
    final canonical = harness.sessions.snapshot;

    pending.complete(RuntimePlayerCompanionMenuData(
      pauseMenuState: const PlayerPauseMenuState.empty(),
      pauseDetails: const {},
    ));

    expect(await reading, isNull);
    expect(harness.sessions.snapshot, same(canonical));
  });

  test('a disposed session controller does not access companion data',
      () async {
    final harness = RuntimePlayerTestHarness();
    addTearDown(harness.dispose);
    await launchHarnessToPlaying(harness);
    final adapter = harness.adapter;
    await harness.coordinator.dispose();
    final calls = List<String>.of(adapter.calls);

    expect(await harness.sessions.readCompanionMenuData(), isNull);
    expect(adapter.calls, calls);
  });
}
