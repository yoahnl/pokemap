import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import 'support/runtime_player_test_harness.dart';

void main() {
  test('companion menu reads exploration without pausing or publishing',
      () async {
    final harness = RuntimePlayerTestHarness();
    addTearDown(harness.dispose);
    await launchHarnessToPlaying(harness);
    final canonical = harness.coordinator.snapshot;
    final session = harness.sessions.snapshot;
    final publications = <RuntimePlayerSnapshot>[];
    final subscription = harness.coordinator.snapshots.listen(publications.add);
    addTearDown(subscription.cancel);
    harness.adapter.calls.clear();

    final projection = await harness.coordinator.readCompanionMenu();
    await harness.coordinator.settle();

    expect(projection, isNotNull);
    expect(projection!.phase, RuntimePlayerPhase.paused);
    expect(projection.pauseSection, RuntimePlayerPauseSection.root);
    expect(projection.revision, canonical.revision);
    expect(projection.gameTitle, canonical.gameTitle);
    expect(harness.coordinator.snapshot, same(canonical));
    expect(harness.sessions.snapshot, same(session));
    expect(harness.sessions.snapshot.state, GameSessionState.running);
    expect(publications, isEmpty);
    expect(harness.adapters, hasLength(1));
    expect(harness.adapter.calls, ['companion-menu']);
    expect(
      harness.sessions.handleInput(
        const RuntimeInputEvent.press(RuntimeInputControl.right),
      ),
      isTrue,
    );
  });

  test('companion menu uses canonical details and action visibility', () async {
    final harness = RuntimePlayerTestHarness();
    addTearDown(harness.dispose);
    await launchHarnessToPlaying(harness);
    final menuState = const PlayerPauseMenuState.empty()
        .setActionVisibility(ProjectPauseActionId.options, visible: false)
        .setActionVisibility(ProjectPauseActionId.map, visible: false);
    final profile = RuntimePlayerProfileSnapshot(
      playerName: 'Current trainer',
      currentMapId: 'route-7',
      money: 1234,
    );
    final bag = RuntimePlayerPauseDetailSnapshot(
      section: RuntimePlayerPauseSection.bag,
      title: 'Sac',
      bagMoney: 1234,
      entries: [
        RuntimePlayerDetailEntrySnapshot(id: 'potion', title: 'Potion × 3'),
      ],
    );
    harness.adapter.pauseMenuState = menuState;
    harness.adapter.pauseDetails = {
      RuntimePlayerPauseSection.profile: RuntimePlayerPauseDetailSnapshot(
        section: RuntimePlayerPauseSection.profile,
        title: 'Profil',
        profile: profile,
      ),
      RuntimePlayerPauseSection.bag: bag,
      RuntimePlayerPauseSection.pokedex: RuntimePlayerPauseDetailSnapshot(
        section: RuntimePlayerPauseSection.pokedex,
        title: 'Pokédex',
      ),
    };
    final canonical = harness.coordinator.snapshot;

    final projection = await harness.coordinator.readCompanionMenu();

    expect(projection, isNotNull);
    expect(projection!.pauseMenuState, same(menuState));
    expect(projection.playerProfile, same(profile));
    expect(projection.pauseDetailFor(RuntimePlayerPauseSection.bag), same(bag));
    expect(projection.activeSaveAddress, same(canonical.activeSaveAddress));
    expect(projection.preferences, same(canonical.preferences));
    expect(projection.defaultPreferences, same(canonical.defaultPreferences));
    expect(
      projection.actions.map((availability) => availability.action).toSet(),
      {
        RuntimePlayerAction.resume,
        RuntimePlayerAction.openParty,
        RuntimePlayerAction.reorderParty,
        RuntimePlayerAction.openBag,
        RuntimePlayerAction.useBagItem,
        RuntimePlayerAction.openPokedex,
        RuntimePlayerAction.openQuests,
        RuntimePlayerAction.openProfile,
        RuntimePlayerAction.save,
        RuntimePlayerAction.returnToTitle,
      },
    );
    expect(projection.isActionEnabled(RuntimePlayerAction.openProfile), isTrue);
    expect(projection.isActionEnabled(RuntimePlayerAction.openPokedex), isTrue);
    expect(projection.isActionEnabled(RuntimePlayerAction.openQuests), isFalse);
    expect(
      projection.unavailableReasonFor(RuntimePlayerAction.openQuests),
      isNotEmpty,
    );
    expect(harness.coordinator.snapshot, same(canonical));
    expect(canonical.pauseDetails, isEmpty);
  });

  test('companion menu preserves the current canonical pause section',
      () async {
    final harness = RuntimePlayerTestHarness();
    addTearDown(harness.dispose);
    await launchHarnessToPlaying(harness);
    await openHarnessPause(harness);
    await harness.coordinator.dispatch(RuntimePlayerCommand(
      action: RuntimePlayerAction.openBag,
      snapshotRevision: harness.coordinator.snapshot.revision,
    ));
    final canonical = harness.coordinator.snapshot;
    final session = harness.sessions.snapshot;
    harness.adapter.calls.clear();

    final projection = await harness.coordinator.readCompanionMenu();

    expect(projection, same(canonical));
    expect(projection!.pauseSection, RuntimePlayerPauseSection.bag);
    expect(harness.coordinator.snapshot, same(canonical));
    expect(canonical.pauseSection, RuntimePlayerPauseSection.bag);
    expect(harness.sessions.snapshot, same(session));
    expect(harness.adapter.calls, isEmpty);
  });

  test('companion menu is absent before launch and after disposal', () async {
    final harness = RuntimePlayerTestHarness();
    addTearDown(harness.dispose);

    expect(await harness.coordinator.readCompanionMenu(), isNull);
    await harness.coordinator.initialize();
    expect(await harness.coordinator.readCompanionMenu(), isNull);
    expect(harness.adapters, isEmpty);
    await launchHarnessToPlaying(harness);
    final adapter = harness.adapter;
    await harness.coordinator.dispose();
    final calls = List<String>.of(adapter.calls);

    expect(await harness.coordinator.readCompanionMenu(), isNull);
    expect(adapter.calls, calls);
  });

  test('a revision change rejects an in-flight companion projection', () async {
    final harness = RuntimePlayerTestHarness();
    addTearDown(harness.dispose);
    await launchHarnessToPlaying(harness);
    final started = Completer<void>();
    final pending = Completer<RuntimePlayerCompanionMenuData>();
    harness.adapter.companionMenuLoader = () {
      started.complete();
      return pending.future;
    };
    final originalRevision = harness.coordinator.snapshot.revision;
    final reading = harness.coordinator.readCompanionMenu();
    await started.future;
    final paused = await harness.coordinator.dispatch(RuntimePlayerCommand(
      action: RuntimePlayerAction.openMenu,
      snapshotRevision: originalRevision,
    ));
    expect(paused.status, RuntimePlayerCommandStatus.accepted);
    final canonical = harness.coordinator.snapshot;
    expect(canonical.revision, greaterThan(originalRevision));

    pending.complete(_expiredMenuData());

    expect(await reading, isNull);
    expect(harness.coordinator.snapshot, same(canonical));
    expect(canonical.playerProfile, isNull);
  });

  test('a replacement session rejects the old companion projection', () async {
    final harness = RuntimePlayerTestHarness();
    addTearDown(harness.dispose);
    await launchHarnessToPlaying(harness);
    final originalAdapter = harness.adapter;
    final originalSessionId = harness.sessions.snapshot.descriptor!.sessionId;
    final started = Completer<void>();
    final pending = Completer<RuntimePlayerCompanionMenuData>();
    originalAdapter.companionMenuLoader = () {
      started.complete();
      return pending.future;
    };
    final reading = harness.coordinator.readCompanionMenu();
    await started.future;
    await openHarnessPause(harness);
    final returned = await harness.coordinator.dispatch(RuntimePlayerCommand(
      action: RuntimePlayerAction.returnToTitle,
      snapshotRevision: harness.coordinator.snapshot.revision,
    ));
    expect(returned.status, RuntimePlayerCommandStatus.accepted);
    final launched = await harness.coordinator.dispatch(RuntimePlayerCommand(
      action: RuntimePlayerAction.newGame,
      snapshotRevision: harness.coordinator.snapshot.revision,
      payload: const RuntimePlayerLoadSlot(
        profileId: 'player',
        slotId: 'slot_2',
      ),
    ));
    expect(launched.status, RuntimePlayerCommandStatus.accepted);
    harness.adapters.last.emitRunning();
    await harness.coordinator.settle();
    final canonical = harness.coordinator.snapshot;
    expect(canonical.phase, RuntimePlayerPhase.playing);
    expect(harness.sessions.snapshot.descriptor!.sessionId,
        isNot(originalSessionId));

    pending.complete(_expiredMenuData());

    expect(await reading, isNull);
    expect(harness.coordinator.snapshot, same(canonical));
    expect(canonical.playerProfile, isNull);
  });

  test('disposal rejects an in-flight companion projection', () async {
    final harness = RuntimePlayerTestHarness();
    addTearDown(harness.dispose);
    await launchHarnessToPlaying(harness);
    final started = Completer<void>();
    final pending = Completer<RuntimePlayerCompanionMenuData>();
    harness.adapter.companionMenuLoader = () {
      started.complete();
      return pending.future;
    };
    final reading = harness.coordinator.readCompanionMenu();
    await started.future;
    await harness.coordinator.dispose();
    final canonical = harness.coordinator.snapshot;

    pending.complete(_expiredMenuData());

    expect(await reading, isNull);
    expect(harness.coordinator.snapshot, same(canonical));
    expect(canonical.playerProfile, isNull);
  });

  test('a closed runtime error after disposal is rejected as stale', () async {
    final harness = RuntimePlayerTestHarness();
    addTearDown(harness.dispose);
    await launchHarnessToPlaying(harness);
    final started = Completer<void>();
    final pending = Completer<RuntimePlayerCompanionMenuData>();
    harness.adapter.companionMenuLoader = () {
      started.complete();
      return pending.future;
    };
    final reading = harness.coordinator.readCompanionMenu();
    await started.future;
    await harness.coordinator.dispose();
    final canonical = harness.coordinator.snapshot;
    final outcome = expectLater(reading, completion(isNull));

    pending.completeError(StateError('closed'));

    await outcome;
    expect(harness.coordinator.snapshot, same(canonical));
  });

  test('an active runtime read failure remains visible to the caller',
      () async {
    final harness = RuntimePlayerTestHarness();
    addTearDown(harness.dispose);
    await launchHarnessToPlaying(harness);
    final failure = StateError('invalid catalog');
    harness.adapter.companionMenuLoader = () async => throw failure;
    final canonical = harness.coordinator.snapshot;

    await expectLater(
      harness.coordinator.readCompanionMenu(),
      throwsA(same(failure)),
    );

    expect(harness.coordinator.snapshot, same(canonical));
    expect(harness.sessions.snapshot.state, GameSessionState.running);
  });
}

RuntimePlayerCompanionMenuData _expiredMenuData() =>
    RuntimePlayerCompanionMenuData(
      pauseMenuState: const PlayerPauseMenuState.empty(),
      pauseDetails: {
        RuntimePlayerPauseSection.profile: RuntimePlayerPauseDetailSnapshot(
          section: RuntimePlayerPauseSection.profile,
          title: 'Expired profile',
          profile: RuntimePlayerProfileSnapshot(
            playerName: 'Expired trainer',
            currentMapId: 'old-route',
            money: 9,
          ),
        ),
      },
    );
