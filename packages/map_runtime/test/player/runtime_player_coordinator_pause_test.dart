import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/map_runtime.dart';

import 'support/runtime_player_test_harness.dart';

void main() {
  test('openMenu pauses the session before publishing the pause root',
      () async {
    final harness = RuntimePlayerTestHarness();
    addTearDown(harness.dispose);
    await launchHarnessToPlaying(harness);

    final result = await harness.coordinator.dispatch(
      RuntimePlayerCommand(
        action: RuntimePlayerAction.openMenu,
        snapshotRevision: harness.coordinator.snapshot.revision,
      ),
    );

    expect(result.status, RuntimePlayerCommandStatus.accepted);
    expect(harness.adapter.calls, contains('pause'));
    expect(harness.sessions.snapshot.state, GameSessionState.paused);
    expect(
      harness.sessions.handleInput(
        const RuntimeInputEvent.press(RuntimeInputControl.right),
      ),
      isFalse,
    );
    expect(harness.coordinator.snapshot.phase, RuntimePlayerPhase.paused);
    expect(
      harness.coordinator.snapshot.pauseSection,
      RuntimePlayerPauseSection.root,
    );
  });

  test('pause root exposes the approved actions and no contextual service',
      () async {
    final harness = RuntimePlayerTestHarness();
    addTearDown(harness.dispose);
    await launchHarnessToPlaying(harness);
    await _openMenu(harness);

    final actions = {
      for (final state in harness.coordinator.snapshot.actions) state.action,
    };

    expect(
      actions,
      <RuntimePlayerAction>{
        RuntimePlayerAction.resume,
        RuntimePlayerAction.openParty,
        RuntimePlayerAction.openBag,
        RuntimePlayerAction.openPokedex,
        RuntimePlayerAction.openMap,
        RuntimePlayerAction.save,
        RuntimePlayerAction.openOptions,
        RuntimePlayerAction.returnToTitle,
      },
    );
    expect(
      RuntimePlayerAction.values.map((action) => action.name),
      isNot(contains(anyOf('shop', 'heal', 'pokemonCenter', 'pc'))),
    );
  });

  test('navigates to a detail section and returns to the pause root', () async {
    final harness = RuntimePlayerTestHarness();
    addTearDown(harness.dispose);
    await launchHarnessToPlaying(harness);
    await _openMenu(harness);

    final openParty = await harness.coordinator.dispatch(
      RuntimePlayerCommand(
        action: RuntimePlayerAction.openParty,
        snapshotRevision: harness.coordinator.snapshot.revision,
      ),
    );

    expect(openParty.status, RuntimePlayerCommandStatus.accepted);
    expect(
      harness.coordinator.snapshot.pauseSection,
      RuntimePlayerPauseSection.party,
    );
    expect(
      harness.coordinator.snapshot.logicalSelectionId,
      'pause.party',
    );

    final back = await harness.coordinator.dispatch(
      RuntimePlayerCommand(
        action: RuntimePlayerAction.returnToPauseRoot,
        snapshotRevision: harness.coordinator.snapshot.revision,
      ),
    );

    expect(back.status, RuntimePlayerCommandStatus.accepted);
    expect(
      harness.coordinator.snapshot.pauseSection,
      RuntimePlayerPauseSection.root,
    );
    expect(
      harness.coordinator.snapshot.logicalSelectionId,
      'pause.party',
    );
  });

  test('refuses an unavailable section without changing pause state', () async {
    final harness = RuntimePlayerTestHarness();
    addTearDown(harness.dispose);
    await launchHarnessToPlaying(harness);
    await _openMenu(harness);
    final revision = harness.coordinator.snapshot.revision;

    final result = await harness.coordinator.dispatch(
      RuntimePlayerCommand(
        action: RuntimePlayerAction.openPokedex,
        snapshotRevision: revision,
      ),
    );

    expect(result.status, RuntimePlayerCommandStatus.unavailable);
    expect(result.safeMessage, isNotEmpty);
    expect(harness.coordinator.snapshot.revision, revision);
    expect(
      harness.coordinator.snapshot.pauseSection,
      RuntimePlayerPauseSection.root,
    );
  });

  test('resume closes every pause section and restores gameplay', () async {
    final harness = RuntimePlayerTestHarness();
    addTearDown(harness.dispose);
    await launchHarnessToPlaying(harness);
    await _openMenu(harness);
    await harness.coordinator.dispatch(
      RuntimePlayerCommand(
        action: RuntimePlayerAction.openBag,
        snapshotRevision: harness.coordinator.snapshot.revision,
      ),
    );

    final result = await harness.coordinator.dispatch(
      RuntimePlayerCommand(
        action: RuntimePlayerAction.resume,
        snapshotRevision: harness.coordinator.snapshot.revision,
      ),
    );

    expect(result.status, RuntimePlayerCommandStatus.accepted);
    expect(harness.sessions.snapshot.state, GameSessionState.running);
    expect(
        harness.adapter.calls,
        containsAllInOrder(<String>[
          'pause',
          'resume',
        ]));
    expect(harness.coordinator.snapshot.phase, RuntimePlayerPhase.playing);
    expect(harness.coordinator.snapshot.pauseSection, isNull);
    expect(
      harness.sessions.handleInput(
        const RuntimeInputEvent.press(RuntimeInputControl.right),
      ),
      isTrue,
    );
  });

  test('stale detail commands cannot move the active pause section', () async {
    final harness = RuntimePlayerTestHarness();
    addTearDown(harness.dispose);
    await launchHarnessToPlaying(harness);
    await _openMenu(harness);
    final staleRevision = harness.coordinator.snapshot.revision;
    await harness.coordinator.dispatch(
      RuntimePlayerCommand(
        action: RuntimePlayerAction.openParty,
        snapshotRevision: staleRevision,
      ),
    );

    final stale = await harness.coordinator.dispatch(
      RuntimePlayerCommand(
        action: RuntimePlayerAction.openBag,
        snapshotRevision: staleRevision,
      ),
    );

    expect(stale.status, RuntimePlayerCommandStatus.stale);
    expect(
      harness.coordinator.snapshot.pauseSection,
      RuntimePlayerPauseSection.party,
    );
  });
}

Future<void> _openMenu(RuntimePlayerTestHarness harness) async {
  final result = await harness.coordinator.dispatch(
    RuntimePlayerCommand(
      action: RuntimePlayerAction.openMenu,
      snapshotRevision: harness.coordinator.snapshot.revision,
    ),
  );
  if (result.status != RuntimePlayerCommandStatus.accepted) {
    throw StateError('The test pause menu did not open.');
  }
}
