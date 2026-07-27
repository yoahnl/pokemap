import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
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
        RuntimePlayerAction.useBagItem,
        RuntimePlayerAction.openPokedex,
        RuntimePlayerAction.openMap,
        RuntimePlayerAction.save,
        RuntimePlayerAction.openOptions,
        RuntimePlayerAction.updatePreferences,
        RuntimePlayerAction.returnToTitle,
      },
    );
    expect(
      RuntimePlayerAction.values.map((action) => action.name),
      isNot(contains(anyOf('shop', 'heal', 'pokemonCenter', 'pc'))),
    );
  });

  test('options persist touch control opacity through the host gateway',
      () async {
    final harness = RuntimePlayerTestHarness();
    addTearDown(harness.dispose);
    await launchHarnessToPlaying(harness);
    await _openMenu(harness);
    await harness.coordinator.dispatch(
      RuntimePlayerCommand(
        action: RuntimePlayerAction.openOptions,
        snapshotRevision: harness.coordinator.snapshot.revision,
      ),
    );
    final updated = harness.preferences.current.copyWith(
      touchControlsOpacity: 0.45,
    );

    final result = await harness.coordinator.dispatch(
      RuntimePlayerCommand(
        action: RuntimePlayerAction.updatePreferences,
        snapshotRevision: harness.coordinator.snapshot.revision,
        payload: updated,
      ),
    );

    expect(result.status, RuntimePlayerCommandStatus.accepted);
    expect(harness.preferences.saves, 1);
    expect(harness.preferences.current.touchControlsOpacity, 0.45);
    expect(
      harness.coordinator.snapshot.preferences?.touchControlsOpacity,
      0.45,
    );
  });

  test('pause surfaces receive live data from the active runtime', () async {
    final harness = RuntimePlayerTestHarness();
    addTearDown(harness.dispose);
    await launchHarnessToPlaying(harness);
    harness.adapter.pauseDetails =
        <RuntimePlayerPauseSection, RuntimePlayerPauseDetailSnapshot>{
      RuntimePlayerPauseSection.party: RuntimePlayerPauseDetailSnapshot(
        section: RuntimePlayerPauseSection.party,
        title: 'Équipe',
        entries: <RuntimePlayerDetailEntrySnapshot>[
          RuntimePlayerDetailEntrySnapshot(
            id: 'party.0',
            title: 'Salamèche',
            subtitle: 'Niv. 16 · PV 38/38',
          ),
        ],
      ),
      RuntimePlayerPauseSection.bag: RuntimePlayerPauseDetailSnapshot(
        section: RuntimePlayerPauseSection.bag,
        title: 'Sac',
        entries: <RuntimePlayerDetailEntrySnapshot>[
          RuntimePlayerDetailEntrySnapshot(
            id: 'bag.medicine.potion',
            title: 'Potion',
            trailingLabel: '×3',
          ),
        ],
      ),
      RuntimePlayerPauseSection.pokedex: RuntimePlayerPauseDetailSnapshot(
        section: RuntimePlayerPauseSection.pokedex,
        title: 'Pokédex',
        entries: <RuntimePlayerDetailEntrySnapshot>[
          RuntimePlayerDetailEntrySnapshot(
            id: 'charmander',
            title: 'Salamèche',
            subtitle: '#004 · Capturé',
          ),
        ],
      ),
    };

    await _openMenu(harness);

    expect(harness.adapter.calls, contains('pause-details'));
    expect(
      harness.coordinator.snapshot
          .pauseDetailFor(RuntimePlayerPauseSection.party)!
          .entries
          .single
          .title,
      'Salamèche',
    );
    expect(
      harness.coordinator.snapshot
          .pauseDetailFor(RuntimePlayerPauseSection.bag)!
          .entries
          .single
          .trailingLabel,
      '×3',
    );
    expect(
      harness.coordinator.snapshot
          .isActionEnabled(RuntimePlayerAction.openPokedex),
      isTrue,
    );

    final openPokedex = await harness.coordinator.dispatch(
      RuntimePlayerCommand(
        action: RuntimePlayerAction.openPokedex,
        snapshotRevision: harness.coordinator.snapshot.revision,
      ),
    );

    expect(openPokedex.status, RuntimePlayerCommandStatus.accepted);
    expect(
      harness.coordinator.snapshot.pauseSection,
      RuntimePlayerPauseSection.pokedex,
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

  test('uses a bag item through the runtime and refreshes pause feedback',
      () async {
    final harness = RuntimePlayerTestHarness();
    addTearDown(harness.dispose);
    await launchHarnessToPlaying(harness);
    harness.adapter.pauseDetails =
        <RuntimePlayerPauseSection, RuntimePlayerPauseDetailSnapshot>{
      RuntimePlayerPauseSection.party: RuntimePlayerPauseDetailSnapshot(
        section: RuntimePlayerPauseSection.party,
        title: 'Équipe',
      ),
      RuntimePlayerPauseSection.bag: RuntimePlayerPauseDetailSnapshot(
        section: RuntimePlayerPauseSection.bag,
        title: 'Sac',
        entries: <RuntimePlayerDetailEntrySnapshot>[
          RuntimePlayerDetailEntrySnapshot(
            id: 'bag.medicine.potion',
            title: 'Potion',
          ),
        ],
      ),
    };
    await _openMenu(harness);
    await harness.coordinator.dispatch(
      RuntimePlayerCommand(
        action: RuntimePlayerAction.openBag,
        snapshotRevision: harness.coordinator.snapshot.revision,
      ),
    );
    final checkpointTime = DateTime.utc(2026, 7, 27, 12);
    harness.adapter.checkpoint = GameSessionCheckpoint(
      saveId: 'bag-checkpoint',
      createdAt: checkpointTime,
      updatedAt: checkpointTime,
      playTimeSeconds: 42,
      state: const GameState(saveId: 'bag-checkpoint').toJson(),
    );

    const command = RuntimePlayerPauseCommand.useBagItem(
      itemTargetId: 'potion',
      partyTargetId: 'party.0',
    );
    final result = await harness.coordinator.dispatch(
      RuntimePlayerCommand(
        action: RuntimePlayerAction.useBagItem,
        snapshotRevision: harness.coordinator.snapshot.revision,
        payload: command,
      ),
    );

    expect(result.status, RuntimePlayerCommandStatus.accepted);
    expect(harness.adapter.pauseCommands, <RuntimePlayerPauseCommand>[command]);
    expect(harness.saves.commits, hasLength(1));
    expect(
      harness.coordinator.snapshot
          .pauseDetailFor(RuntimePlayerPauseSection.bag)
          ?.message,
      'Objet utilisé.',
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
