import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import 'support/runtime_player_test_harness.dart';

void main() {
  test(
      'pause projection failure replaces loading and supports resume and retry',
      () async {
    final harness = RuntimePlayerTestHarness();
    addTearDown(harness.dispose);
    await launchHarnessToPlaying(harness);
    harness.adapter.pauseDetailsLoader =
        () async => throw StateError('invalid catalog');
    final result = await harness.coordinator.dispatch(RuntimePlayerCommand(
      action: RuntimePlayerAction.openMenu,
      snapshotRevision: harness.coordinator.snapshot.revision,
    ));
    expect(result.status, RuntimePlayerCommandStatus.failed);
    expect(
        harness.coordinator.snapshot
            .unavailableReasonFor(RuntimePlayerAction.openPokedex),
        contains('Lecture impossible'));
    expect(
        harness.coordinator.snapshot
            .isActionEnabled(RuntimePlayerAction.resume),
        isTrue);
    await harness.coordinator.dispatch(RuntimePlayerCommand(
      action: RuntimePlayerAction.resume,
      snapshotRevision: harness.coordinator.snapshot.revision,
    ));
    harness.adapter.pauseDetailsLoader = null;
    await _openMenu(harness);
    expect(
        harness.coordinator.snapshot
            .unavailableReasonFor(RuntimePlayerAction.openPokedex),
        isNot(contains('Lecture impossible')));
  });

  test('pause projection failure preserves hidden options and map on retry',
      () async {
    final harness = RuntimePlayerTestHarness();
    addTearDown(harness.dispose);
    await launchHarnessToPlaying(harness);
    final pauseMenuState = const PlayerPauseMenuState.empty()
        .setActionVisibility(ProjectPauseActionId.options, visible: false)
        .setActionVisibility(ProjectPauseActionId.map, visible: false);
    harness.adapter.pauseMenuState = pauseMenuState;

    for (final fail in [true, false]) {
      harness.adapter.pauseDetailsLoader =
          fail ? () async => throw StateError('invalid catalog') : null;
      final result = await harness.coordinator.dispatch(RuntimePlayerCommand(
        action: RuntimePlayerAction.openMenu,
        snapshotRevision: harness.coordinator.snapshot.revision,
      ));
      expect(
          result.status,
          fail
              ? RuntimePlayerCommandStatus.failed
              : RuntimePlayerCommandStatus.accepted);
      expect(harness.coordinator.snapshot.pauseMenuState, same(pauseMenuState));
      expect(
          harness.coordinator.snapshot.actions.map((entry) => entry.action),
          isNot(contains(anyOf(
              RuntimePlayerAction.openOptions, RuntimePlayerAction.openMap))));
      expect(
          harness.coordinator.snapshot
              .isActionEnabled(RuntimePlayerAction.resume),
          isTrue);
      final rejected = await harness.coordinator.dispatch(RuntimePlayerCommand(
        action: RuntimePlayerAction.openOptions,
        snapshotRevision: harness.coordinator.snapshot.revision,
      ));
      expect(rejected.status, RuntimePlayerCommandStatus.unavailable);
      await harness.coordinator.dispatch(RuntimePlayerCommand(
        action: RuntimePlayerAction.resume,
        snapshotRevision: harness.coordinator.snapshot.revision,
      ));
    }
  });

  test('pending pause projections show loading before actual availability',
      () async {
    final harness = RuntimePlayerTestHarness();
    addTearDown(harness.dispose);
    await launchHarnessToPlaying(harness);
    final started = Completer<void>();
    final pending = Completer<
        Map<RuntimePlayerPauseSection, RuntimePlayerPauseDetailSnapshot>>();
    harness.adapter.pauseDetailsLoader = () {
      started.complete();
      return pending.future;
    };
    final command = harness.coordinator.dispatch(RuntimePlayerCommand(
      action: RuntimePlayerAction.openMenu,
      snapshotRevision: harness.coordinator.snapshot.revision,
    ));
    await started.future;
    expect(
        harness.coordinator.snapshot
            .unavailableReasonFor(RuntimePlayerAction.openPokedex),
        contains('Chargement'));
    expect(
        harness.coordinator.snapshot
            .unavailableReasonFor(RuntimePlayerAction.openProfile),
        contains('Chargement'));
    pending.complete({
      RuntimePlayerPauseSection.pokedex: RuntimePlayerPauseDetailSnapshot(
        section: RuntimePlayerPauseSection.pokedex,
        title: 'Pokédex',
      ),
      RuntimePlayerPauseSection.profile: RuntimePlayerPauseDetailSnapshot(
        section: RuntimePlayerPauseSection.profile,
        title: 'Profile',
        profile: RuntimePlayerProfileSnapshot(
            playerName: 'Current', currentMapId: 'route', money: 7),
      ),
    });
    expect((await command).status, RuntimePlayerCommandStatus.accepted);
    expect(
        harness.coordinator.snapshot
            .isActionEnabled(RuntimePlayerAction.openPokedex),
        isTrue);
    expect(
        harness.coordinator.snapshot
            .isActionEnabled(RuntimePlayerAction.openProfile),
        isTrue);
  });

  for (final section in [
    RuntimePlayerPauseSection.bag,
    RuntimePlayerPauseSection.party,
  ]) {
    test('${section.name} refresh failure rejects a queued duplicate mutation',
        () async {
      final harness = RuntimePlayerTestHarness();
      addTearDown(harness.dispose);
      await launchHarnessToPlaying(harness);
      harness.adapter.pauseDetails = {
        section: RuntimePlayerPauseDetailSnapshot(
          section: section,
          title: section.name,
          entries: [
            RuntimePlayerDetailEntrySnapshot(id: 'old', title: 'Old data'),
          ],
        ),
      };
      await _openMenu(harness);
      final isBag = section == RuntimePlayerPauseSection.bag;
      final action = isBag
          ? RuntimePlayerAction.useBagItem
          : RuntimePlayerAction.reorderParty;
      await harness.coordinator.dispatch(RuntimePlayerCommand(
        action:
            isBag ? RuntimePlayerAction.openBag : RuntimePlayerAction.openParty,
        snapshotRevision: harness.coordinator.snapshot.revision,
      ));
      harness.adapter.pauseDetailsLoader =
          () async => throw StateError('projection failed after mutation');
      final command = RuntimePlayerCommand(
        action: action,
        snapshotRevision: harness.coordinator.snapshot.revision,
        payload: isBag
            ? const RuntimePlayerPauseCommand.useBagItem(
                itemTargetId: 'potion',
                partyTargetId: 'pokemon.current',
              )
            : const RuntimePlayerPauseCommand.setPartyLead(
                partyTargetId: 'pokemon.current',
              ),
      );
      final results = await Future.wait([
        harness.coordinator.dispatch(command),
        harness.coordinator.dispatch(command),
      ].map((future) => future.then<Object>((result) => result,
          onError: (Object error) => error)));

      expect(harness.adapter.pauseCommands, hasLength(1));
      expect(results.first, isA<RuntimePlayerCommandResult>());
      expect((results.first as RuntimePlayerCommandResult).status,
          RuntimePlayerCommandStatus.failed);
      expect((results.last as RuntimePlayerCommandResult).status,
          RuntimePlayerCommandStatus.stale);
      expect(harness.coordinator.snapshot.pauseSection, section);
      expect(harness.coordinator.snapshot.pauseDetailFor(section)?.entries,
          isEmpty);
      expect(harness.coordinator.snapshot.pauseDetailFor(section)?.emptyMessage,
          contains('Lecture impossible'));
      expect(harness.coordinator.snapshot.isActionEnabled(action), isFalse);
      expect(
          harness.coordinator.snapshot
              .isActionEnabled(RuntimePlayerAction.resume),
          isTrue);
      final rejected = await harness.coordinator.dispatch(RuntimePlayerCommand(
        action: action,
        snapshotRevision: harness.coordinator.snapshot.revision,
        payload: command.payload,
      ));
      expect(rejected.status, RuntimePlayerCommandStatus.unavailable);
      expect(harness.adapter.pauseCommands, hasLength(1));

      await harness.coordinator.dispatch(RuntimePlayerCommand(
        action: RuntimePlayerAction.resume,
        snapshotRevision: harness.coordinator.snapshot.revision,
      ));
      harness.adapter.pauseDetailsLoader = null;
      await _openMenu(harness);
      expect(harness.coordinator.snapshot.isActionEnabled(action), isTrue);
      expect(
          harness.coordinator.snapshot
              .pauseDetailFor(section)
              ?.entries
              .single
              .id,
          'old');
    });

    for (final refreshFails in [false, true]) {
      test(
          'late ${section.name} refresh ${refreshFails ? 'failure' : 'result'} cannot replace a disposed snapshot',
          () async {
        final harness = RuntimePlayerTestHarness();
        addTearDown(harness.dispose);
        await launchHarnessToPlaying(harness);
        await _openMenu(harness);
        final isBag = section == RuntimePlayerPauseSection.bag;
        await harness.coordinator.dispatch(RuntimePlayerCommand(
          action: isBag
              ? RuntimePlayerAction.openBag
              : RuntimePlayerAction.openParty,
          snapshotRevision: harness.coordinator.snapshot.revision,
        ));
        final started = Completer<void>();
        final pending = Completer<
            Map<RuntimePlayerPauseSection, RuntimePlayerPauseDetailSnapshot>>();
        harness.adapter.pauseDetailsLoader = () {
          started.complete();
          return pending.future;
        };
        final command = harness.coordinator.dispatch(RuntimePlayerCommand(
          action: isBag
              ? RuntimePlayerAction.useBagItem
              : RuntimePlayerAction.reorderParty,
          snapshotRevision: harness.coordinator.snapshot.revision,
          payload: isBag
              ? const RuntimePlayerPauseCommand.useBagItem(
                  itemTargetId: 'potion',
                  partyTargetId: 'pokemon.current',
                )
              : const RuntimePlayerPauseCommand.setPartyLead(
                  partyTargetId: 'pokemon.current',
                ),
        ));
        await started.future;
        await harness.coordinator.dispose();
        final disposedSnapshot = harness.coordinator.snapshot;
        if (refreshFails) {
          pending.completeError(StateError('late projection failure'));
        } else {
          pending.complete({
            RuntimePlayerPauseSection.profile: RuntimePlayerPauseDetailSnapshot(
              section: RuntimePlayerPauseSection.profile,
              title: 'Profile',
              profile: RuntimePlayerProfileSnapshot(
                playerName: 'Expired',
                currentMapId: 'old-map',
                money: 9,
              ),
            ),
          });
        }
        final result = await command;
        expect(result.status, RuntimePlayerCommandStatus.cancelled);
        expect(harness.coordinator.snapshot, same(disposedSnapshot));
        expect(harness.coordinator.snapshot.playerProfile, isNull);
        expect(harness.adapter.pauseCommands, hasLength(1));
      });
    }
  }

  test('late pause data cannot replace a disposed player snapshot', () async {
    final harness = RuntimePlayerTestHarness();
    addTearDown(harness.dispose);
    await launchHarnessToPlaying(harness);
    final started = Completer<void>();
    final pending = Completer<
        Map<RuntimePlayerPauseSection, RuntimePlayerPauseDetailSnapshot>>();
    harness.adapter.pauseDetailsLoader = () {
      started.complete();
      return pending.future;
    };
    final command = harness.coordinator.dispatch(RuntimePlayerCommand(
      action: RuntimePlayerAction.openMenu,
      snapshotRevision: harness.coordinator.snapshot.revision,
    ));
    await started.future;
    await harness.coordinator.dispose();
    final disposedSnapshot = harness.coordinator.snapshot;
    pending.complete({
      RuntimePlayerPauseSection.profile: RuntimePlayerPauseDetailSnapshot(
        section: RuntimePlayerPauseSection.profile,
        title: 'Profile',
        profile: RuntimePlayerProfileSnapshot(
          playerName: 'Expired',
          currentMapId: 'old-map',
          money: 9,
        ),
      ),
    });
    final result = await command;
    expect(result.status, RuntimePlayerCommandStatus.cancelled);
    expect(harness.coordinator.snapshot, same(disposedSnapshot));
    expect(harness.coordinator.snapshot.playerProfile, isNull);
  });

  test('returning to title clears the previous session profile', () async {
    final harness = RuntimePlayerTestHarness();
    addTearDown(harness.dispose);
    await launchHarnessToPlaying(harness);
    harness.adapter.pauseDetails = {
      RuntimePlayerPauseSection.profile: RuntimePlayerPauseDetailSnapshot(
        section: RuntimePlayerPauseSection.profile,
        title: 'Profile',
        profile: RuntimePlayerProfileSnapshot(
          playerName: 'Previous',
          currentMapId: 'route',
          money: 9,
        ),
      ),
    };
    await _openMenu(harness);
    expect(harness.coordinator.snapshot.playerProfile, isNotNull);
    await harness.coordinator.dispatch(RuntimePlayerCommand(
      action: RuntimePlayerAction.returnToTitle,
      snapshotRevision: harness.coordinator.snapshot.revision,
    ));
    expect(harness.coordinator.snapshot.phase, RuntimePlayerPhase.title);
    expect(harness.coordinator.snapshot.playerProfile, isNull);
    expect(harness.coordinator.snapshot.pauseDetails, isEmpty);
  });

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
        RuntimePlayerAction.reorderParty,
        RuntimePlayerAction.openBag,
        RuntimePlayerAction.useBagItem,
        RuntimePlayerAction.openPokedex,
        RuntimePlayerAction.openQuests,
        RuntimePlayerAction.openMap,
        RuntimePlayerAction.openProfile,
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

  for (final stage in ['persistence', 'refresh', 'refresh failure']) {
    test('late preferences $stage cannot replace a disposed snapshot',
        () async {
      final harness = RuntimePlayerTestHarness();
      addTearDown(harness.dispose);
      await launchHarnessToPlaying(harness);
      await _openMenu(harness);
      await harness.coordinator.dispatch(RuntimePlayerCommand(
        action: RuntimePlayerAction.openOptions,
        snapshotRevision: harness.coordinator.snapshot.revision,
      ));
      final started = Completer<void>();
      final projection = Completer<
          Map<RuntimePlayerPauseSection, RuntimePlayerPauseDetailSnapshot>>();
      if (stage == 'persistence') {
        harness.preferences.saveGate = Completer<void>();
      } else {
        harness.adapter.pauseDetailsLoader = () {
          started.complete();
          return projection.future;
        };
      }
      final requested = harness.preferences.current.copyWith(locale: 'en');
      final command = harness.coordinator.dispatch(RuntimePlayerCommand(
        action: RuntimePlayerAction.updatePreferences,
        snapshotRevision: harness.coordinator.snapshot.revision,
        payload: requested,
      ));
      if (stage == 'persistence') {
        await Future<void>.delayed(Duration.zero);
        expect(harness.preferences.saves, 1);
      } else {
        await started.future;
      }
      final appliedCount = harness.adapter.appliedPreferences.length;
      await harness.coordinator.dispose();
      final disposedSnapshot = harness.coordinator.snapshot;
      if (stage == 'persistence') {
        harness.preferences.saveGate!.complete();
      } else if (stage == 'refresh failure') {
        projection.completeError(StateError('late locale projection failure'));
      } else {
        projection.complete({});
      }
      final result = await command;
      expect(harness.coordinator.snapshot, same(disposedSnapshot));
      expect(result.status, RuntimePlayerCommandStatus.cancelled);
      expect(harness.adapter.appliedPreferences, hasLength(appliedCount));
    });
  }

  for (final queuedAction in [
    'open bag',
    'preferences',
    'back',
    'service back'
  ]) {
    test('queued $queuedAction is cancelled after coordinator disposal',
        () async {
      final harness = RuntimePlayerTestHarness();
      addTearDown(harness.dispose);
      await launchHarnessToPlaying(harness);
      await _openMenu(harness);
      await harness.coordinator.dispatch(RuntimePlayerCommand(
        action: RuntimePlayerAction.openOptions,
        snapshotRevision: harness.coordinator.snapshot.revision,
      ));
      if (queuedAction == 'service back') {
        harness.adapter.publishWorldService(RuntimeWorldServiceSnapshot(
          revision: 4,
          request: const OpenShopService(
            interactionId: 'merchant',
            shopId: 'station-shop',
          ),
          stage: RuntimeWorldServiceStage.active,
          actions: const [
            RuntimeWorldServiceActionAvailability.enabled(
              RuntimeWorldServiceAction.close,
            ),
          ],
        ));
        await harness.coordinator.settle();
      }
      final gate = Completer<void>();
      harness.preferences.saveGate = gate;
      final revision = harness.coordinator.snapshot.revision;
      final requested = harness.preferences.current.copyWith(locale: 'en');
      final pendingPreferences =
          harness.coordinator.dispatch(RuntimePlayerCommand(
        action: RuntimePlayerAction.updatePreferences,
        snapshotRevision: revision,
        payload: requested,
      ));
      await Future<void>.delayed(Duration.zero);
      expect(harness.preferences.saves, 1);
      final pendingCommand = queuedAction.endsWith('back')
          ? harness.coordinator.requestBack(snapshotRevision: revision)
          : harness.coordinator.dispatch(RuntimePlayerCommand(
              action: queuedAction == 'preferences'
                  ? RuntimePlayerAction.updatePreferences
                  : RuntimePlayerAction.openBag,
              snapshotRevision: revision,
              payload: queuedAction == 'preferences' ? requested : null,
            ));
      final appliedCount = harness.adapter.appliedPreferences.length;
      await harness.coordinator.dispose();
      final disposedSnapshot = harness.coordinator.snapshot;
      gate.complete();
      expect((await pendingPreferences).status,
          RuntimePlayerCommandStatus.cancelled);
      expect(
          (await pendingCommand).status, RuntimePlayerCommandStatus.cancelled);
      expect(harness.coordinator.snapshot, same(disposedSnapshot));
      expect(harness.preferences.saves, 1);
      expect(harness.adapter.appliedPreferences, hasLength(appliedCount));
      expect(harness.adapter.worldServiceCommands, isEmpty);
    });
  }

  test('successful locale refresh restores pause mutations after a read error',
      () async {
    final harness = RuntimePlayerTestHarness();
    addTearDown(harness.dispose);
    await launchHarnessToPlaying(harness);
    harness.adapter.pauseDetailsLoader =
        () async => throw StateError('invalid catalog');
    await harness.coordinator.dispatch(RuntimePlayerCommand(
      action: RuntimePlayerAction.openMenu,
      snapshotRevision: harness.coordinator.snapshot.revision,
    ));
    expect(
        harness.coordinator.snapshot
            .isActionEnabled(RuntimePlayerAction.useBagItem),
        isFalse);
    await harness.coordinator.dispatch(RuntimePlayerCommand(
      action: RuntimePlayerAction.openOptions,
      snapshotRevision: harness.coordinator.snapshot.revision,
    ));
    harness.adapter.pauseDetailsLoader = null;
    final result = await harness.coordinator.dispatch(RuntimePlayerCommand(
      action: RuntimePlayerAction.updatePreferences,
      snapshotRevision: harness.coordinator.snapshot.revision,
      payload: harness.preferences.current.copyWith(locale: 'en'),
    ));
    expect(result.status, RuntimePlayerCommandStatus.accepted);
    expect(
        harness.coordinator.snapshot
            .isActionEnabled(RuntimePlayerAction.useBagItem),
        isTrue);
    expect(
        harness.coordinator.snapshot
            .isActionEnabled(RuntimePlayerAction.reorderParty),
        isTrue);
  });

  test('profile navigation shares root data and preserves command guards',
      () async {
    final harness = RuntimePlayerTestHarness();
    addTearDown(harness.dispose);
    await launchHarnessToPlaying(harness);
    final profile = RuntimePlayerProfileSnapshot(
      playerName: 'Live player',
      currentMapId: 'route',
      money: 45,
      playtimeSeconds: 105,
    );
    harness.adapter.pauseDetails = {
      RuntimePlayerPauseSection.profile: RuntimePlayerPauseDetailSnapshot(
        section: RuntimePlayerPauseSection.profile,
        title: 'Profil',
        profile: profile,
      ),
    };
    await _openMenu(harness);
    final rootRevision = harness.coordinator.snapshot.revision;
    expect(harness.coordinator.snapshot.playerProfile, same(profile));
    expect(
        harness.coordinator.snapshot.isActionEnabled(
          RuntimePlayerAction.openProfile,
        ),
        isTrue);
    expect(
        harness.coordinator.snapshot.isActionEnabled(
          RuntimePlayerAction.openQuests,
        ),
        isFalse);
    final rejected = await harness.coordinator.dispatch(RuntimePlayerCommand(
      action: RuntimePlayerAction.openQuests,
      snapshotRevision: rootRevision,
    ));
    expect(rejected.status, RuntimePlayerCommandStatus.unavailable);
    expect(rejected.safeMessage, isNotEmpty);
    expect(harness.coordinator.snapshot.revision, rootRevision);

    final opened = await harness.coordinator.dispatch(RuntimePlayerCommand(
      action: RuntimePlayerAction.openProfile,
      snapshotRevision: rootRevision,
    ));
    expect(opened.status, RuntimePlayerCommandStatus.accepted);
    expect(harness.coordinator.snapshot.pauseSection,
        RuntimePlayerPauseSection.profile);
    final stale = await harness.coordinator.dispatch(RuntimePlayerCommand(
      action: RuntimePlayerAction.openParty,
      snapshotRevision: rootRevision,
    ));
    expect(stale.status, RuntimePlayerCommandStatus.stale);
    await harness.coordinator.requestBack(
      snapshotRevision: harness.coordinator.snapshot.revision,
    );
    expect(harness.coordinator.snapshot.pauseSection,
        RuntimePlayerPauseSection.root);
    expect(harness.coordinator.snapshot.playerProfile, same(profile));
    expect(harness.adapter.pauseCommands, isEmpty);
    await harness.coordinator.requestBack(
      snapshotRevision: harness.coordinator.snapshot.revision,
    );
    expect(harness.coordinator.snapshot.phase, RuntimePlayerPhase.playing);
    expect(harness.coordinator.snapshot.playerProfile, isNull);
  });

  test('profile without a typed projection remains unavailable', () async {
    final harness = RuntimePlayerTestHarness();
    addTearDown(harness.dispose);
    await launchHarnessToPlaying(harness);
    harness.adapter.pauseDetails = {
      RuntimePlayerPauseSection.profile: RuntimePlayerPauseDetailSnapshot(
        section: RuntimePlayerPauseSection.profile,
        title: 'Profile',
      ),
    };
    await _openMenu(harness);
    final result = await harness.coordinator.dispatch(RuntimePlayerCommand(
      action: RuntimePlayerAction.openProfile,
      snapshotRevision: harness.coordinator.snapshot.revision,
    ));
    expect(result.status, RuntimePlayerCommandStatus.unavailable);
    expect(result.safeMessage, isNotEmpty);
    expect(harness.coordinator.snapshot.pauseSection,
        RuntimePlayerPauseSection.root);
  });

  test(
      'narrative override hides profile while retaining root summary and resume',
      () async {
    final harness = RuntimePlayerTestHarness();
    addTearDown(harness.dispose);
    await launchHarnessToPlaying(harness);
    final profile = RuntimePlayerProfileSnapshot(
      playerName: 'Current',
      currentMapId: 'route',
      money: 1,
    );
    harness.adapter.pauseDetails = {
      RuntimePlayerPauseSection.profile: RuntimePlayerPauseDetailSnapshot(
        section: RuntimePlayerPauseSection.profile,
        title: 'Profil',
        profile: profile,
      ),
    };
    harness.adapter.pauseMenuState = const PlayerPauseMenuState.empty()
        .setActionVisibility(ProjectPauseActionId.profile, visible: false)
        .setActionVisibility(ProjectPauseActionId.quests, visible: false);
    await _openMenu(harness);
    expect(harness.coordinator.snapshot.playerProfile, same(profile));
    expect(
        harness.coordinator.snapshot.actions.map((entry) => entry.action),
        isNot(contains(anyOf(
            RuntimePlayerAction.openProfile, RuntimePlayerAction.openQuests))));
    expect(
        harness.coordinator.snapshot
            .isActionEnabled(RuntimePlayerAction.resume),
        isTrue);
    final result = await harness.coordinator.dispatch(RuntimePlayerCommand(
      action: RuntimePlayerAction.openProfile,
      snapshotRevision: harness.coordinator.snapshot.revision,
    ));
    expect(result.status, RuntimePlayerCommandStatus.unavailable);
    expect(harness.adapter.pauseCommands, isEmpty);
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

  test('a narrative visibility override removes and guards the pause action',
      () async {
    final harness = RuntimePlayerTestHarness();
    addTearDown(harness.dispose);
    await launchHarnessToPlaying(harness);
    harness.adapter.pauseMenuState =
        const PlayerPauseMenuState.empty().setActionVisibility(
      ProjectPauseActionId.pokedex,
      visible: false,
    );
    harness.adapter.pauseDetails =
        <RuntimePlayerPauseSection, RuntimePlayerPauseDetailSnapshot>{
      RuntimePlayerPauseSection.pokedex: RuntimePlayerPauseDetailSnapshot(
        section: RuntimePlayerPauseSection.pokedex,
        title: 'Pokédex',
      ),
    };

    await _openMenu(harness);
    final revision = harness.coordinator.snapshot.revision;

    expect(
      harness.coordinator.snapshot.actions.map((entry) => entry.action),
      isNot(contains(RuntimePlayerAction.openPokedex)),
    );
    expect(
      harness.coordinator.snapshot.pauseMenuState,
      harness.adapter.pauseMenuState,
    );
    final direct = await harness.coordinator.dispatch(
      RuntimePlayerCommand(
        action: RuntimePlayerAction.openPokedex,
        snapshotRevision: revision,
      ),
    );
    expect(direct.status, RuntimePlayerCommandStatus.unavailable);
    expect(harness.coordinator.snapshot.revision, revision);
  });

  test('a save override can reveal an entry hidden by the project default',
      () async {
    final harness = RuntimePlayerTestHarness(
      defaultVisiblePauseActions: ProjectPauseActionId.values
          .where((actionId) => actionId != ProjectPauseActionId.pokedex)
          .toSet(),
    );
    addTearDown(harness.dispose);
    await launchHarnessToPlaying(harness);
    harness.adapter.pauseMenuState =
        const PlayerPauseMenuState.empty().setActionVisibility(
      ProjectPauseActionId.pokedex,
      visible: true,
    );

    await _openMenu(harness);

    expect(
      harness.coordinator.snapshot.actions.map((entry) => entry.action),
      contains(RuntimePlayerAction.openPokedex),
    );
    expect(
      harness.coordinator.snapshot.actions.map((entry) => entry.action),
      contains(RuntimePlayerAction.resume),
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

  test('reorders the party from the pause party section', () async {
    // BETA-PTY-002, le canal UI. La commande arrive du routeur d'actions
    // joueur — le même quel que soit le périphérique (clavier, manette,
    // tactile), c'est le contrat device-agnostic des actions runtime.
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
            id: 'pokemon.pkm_lead',
            title: 'Lead',
          ),
          RuntimePlayerDetailEntrySnapshot(
            id: 'pokemon.pkm_second',
            title: 'Second',
          ),
        ],
      ),
    };
    await _openMenu(harness);
    await harness.coordinator.dispatch(
      RuntimePlayerCommand(
        action: RuntimePlayerAction.openParty,
        snapshotRevision: harness.coordinator.snapshot.revision,
      ),
    );

    const command = RuntimePlayerPauseCommand.reorderPartyMember(
      partyTargetId: 'pokemon.pkm_lead',
      secondPartyTargetId: 'pokemon.pkm_second',
    );
    final result = await harness.coordinator.dispatch(
      RuntimePlayerCommand(
        action: RuntimePlayerAction.reorderParty,
        snapshotRevision: harness.coordinator.snapshot.revision,
        payload: command,
      ),
    );

    expect(result.status, RuntimePlayerCommandStatus.accepted);
    expect(harness.adapter.pauseCommands, <RuntimePlayerPauseCommand>[command]);
    expect(
      harness.coordinator.snapshot.pauseSection,
      RuntimePlayerPauseSection.party,
      reason: 'the player stays on the party section after the reorder',
    );
    expect(
      harness.coordinator.snapshot
          .pauseDetailFor(RuntimePlayerPauseSection.party)
          ?.message,
      harness.adapter.pauseCommandResult.safeMessage,
      reason: 'the party detail carries the outcome message',
    );
  });

  test('refuses a reorder outside the party section', () async {
    // Même garde que le sac : la commande n'a de sens que sur sa section. Un
    // payload rejoué depuis un autre écran est refusé sans dispatch.
    final harness = RuntimePlayerTestHarness();
    addTearDown(harness.dispose);
    await launchHarnessToPlaying(harness);
    await _openMenu(harness);

    final result = await harness.coordinator.dispatch(
      RuntimePlayerCommand(
        action: RuntimePlayerAction.reorderParty,
        snapshotRevision: harness.coordinator.snapshot.revision,
        payload: const RuntimePlayerPauseCommand.setPartyLead(
          partyTargetId: 'pokemon.pkm_lead',
        ),
      ),
    );

    expect(result.status, RuntimePlayerCommandStatus.unavailable);
    expect(harness.adapter.pauseCommands, isEmpty);
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
