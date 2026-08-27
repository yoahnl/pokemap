import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
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
    expect(snapshot.isActionEnabled(RuntimePlayerAction.openOptions), isTrue);
    expect(snapshot.isActionEnabled(RuntimePlayerAction.showCredits), isTrue);
    expect(snapshot.hasDiscoveredSave, isFalse);
    expect(
      snapshot.unavailableReasonFor(RuntimePlayerAction.continueGame),
      isNotEmpty,
    );
    expect(harness.preferences.loads, 1);
  });

  test('opens persisted options from title and returns without a session',
      () async {
    final harness = RuntimePlayerTestHarness();
    addTearDown(harness.dispose);
    await harness.coordinator.initialize();

    final opened = await harness.coordinator.dispatch(
      RuntimePlayerCommand(
        action: RuntimePlayerAction.openOptions,
        snapshotRevision: harness.coordinator.snapshot.revision,
      ),
    );

    expect(opened.status, RuntimePlayerCommandStatus.accepted);
    expect(harness.coordinator.snapshot.phase, RuntimePlayerPhase.title);
    expect(
      harness.coordinator.snapshot.pauseSection,
      RuntimePlayerPauseSection.options,
    );
    expect(
      harness.coordinator.snapshot
          .isActionEnabled(RuntimePlayerAction.updatePreferences),
      isTrue,
    );

    final updated = harness.preferences.current.copyWith(
      touchControlsOpacity: 0.6,
    );
    final saved = await harness.coordinator.dispatch(
      RuntimePlayerCommand(
        action: RuntimePlayerAction.updatePreferences,
        snapshotRevision: harness.coordinator.snapshot.revision,
        payload: updated,
      ),
    );
    expect(saved.status, RuntimePlayerCommandStatus.accepted);
    expect(harness.preferences.current.touchControlsOpacity, 0.6);

    final returned = await harness.coordinator.dispatch(
      RuntimePlayerCommand(
        action: RuntimePlayerAction.returnToTitle,
        snapshotRevision: harness.coordinator.snapshot.revision,
      ),
    );
    expect(returned.status, RuntimePlayerCommandStatus.accepted);
    expect(harness.coordinator.snapshot.phase, RuntimePlayerPhase.title);
    expect(harness.coordinator.snapshot.pauseSection, isNull);
    expect(harness.adapters, isEmpty);
  });

  test('opens title credits before completion and returns to title', () async {
    final harness = RuntimePlayerTestHarness();
    addTearDown(harness.dispose);
    await harness.coordinator.initialize();

    final opened = await harness.coordinator.dispatch(
      RuntimePlayerCommand(
        action: RuntimePlayerAction.showCredits,
        snapshotRevision: harness.coordinator.snapshot.revision,
      ),
    );

    expect(opened.status, RuntimePlayerCommandStatus.accepted);
    expect(harness.coordinator.snapshot.phase, RuntimePlayerPhase.credits);
    expect(harness.coordinator.snapshot.credits, isNull);
    expect(
      harness.coordinator.snapshot
          .isActionEnabled(RuntimePlayerAction.finishCredits),
      isTrue,
    );

    final returned = await harness.coordinator.dispatch(
      RuntimePlayerCommand(
        action: RuntimePlayerAction.finishCredits,
        snapshotRevision: harness.coordinator.snapshot.revision,
      ),
    );
    expect(returned.status, RuntimePlayerCommandStatus.accepted);
    expect(harness.coordinator.snapshot.phase, RuntimePlayerPhase.title);
    expect(harness.adapters, isEmpty);
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
    expect(harness.coordinator.snapshot.hasDiscoveredSave, isTrue);
    expect(harness.coordinator.snapshot.continueSave, same(save));
  });

  test('keeps Options and Credits available for a completed save', () async {
    final seed = RuntimePlayerTestHarness();
    final completedSave = PlayerSaveSummary(
      address: SaveSlotAddress(
        gameId: seed.source.identity.gameId,
        profileId: 'player',
        slotId: 'slot_1',
      ),
      updatedAt: DateTime.utc(2026, 7, 27),
      playTimeSeconds: 3600,
      status: SaveStatus.completed,
      canContinue: false,
    );
    await seed.dispose();
    final harness = RuntimePlayerTestHarness(latestSave: completedSave);
    addTearDown(harness.dispose);

    await harness.coordinator.initialize();

    expect(
      harness.coordinator.snapshot
          .isActionEnabled(RuntimePlayerAction.continueGame),
      isFalse,
    );
    expect(
      harness.coordinator.snapshot
          .isActionEnabled(RuntimePlayerAction.openOptions),
      isTrue,
    );
    expect(
      harness.coordinator.snapshot
          .isActionEnabled(RuntimePlayerAction.showCredits),
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

  test('launches with starter options deferred to an authored pre-session',
      () async {
    final harness = RuntimePlayerTestHarness(
      scenes: <SceneAsset>[
        SceneAsset(
          id: 'scene-pre-session',
          name: 'Deferred starter pre-session',
          executionProfile: SceneExecutionProfile.preSession,
          graph: SceneGraph(
            startNodeId: 'start',
            nodes: <SceneNode>[
              SceneNode(id: 'start', kind: SceneNodeKind.start),
              SceneNode(id: 'end', kind: SceneNodeKind.end),
            ],
            edges: <SceneEdge>[
              SceneEdge(
                id: 'start-end',
                fromNodeId: 'start',
                fromPortId: 'completed',
                toNodeId: 'end',
                kind: SceneEdgeKind.defaultFlow,
              ),
            ],
          ),
        ),
      ],
      newGameConfig: ProjectNewGameConfig(
        enabled: true,
        startMapId: 'start_map',
        preSessionSceneId: 'scene-pre-session',
        starterOptions: <ProjectStarterOption>[
          ProjectStarterOption(
            id: 'starter-leaf',
            label: 'Leaf',
            pokemon: PlayerPokemon(
              speciesId: 'leafmon',
              natureId: 'hardy',
              abilityId: 'overgrow',
            ),
          ),
          ProjectStarterOption(
            id: 'starter-fire',
            label: 'Fire',
            pokemon: PlayerPokemon(
              speciesId: 'firemon',
              natureId: 'hardy',
              abilityId: 'blaze',
            ),
          ),
        ],
      ),
    );
    addTearDown(harness.dispose);
    await harness.coordinator.initialize();

    final draft = NewGameDraft.start(
      draftId: 'deferred-starter-draft',
      projectRevision: harness.newGameFlow.preparation.projectRevision,
      slotId: 'slot_1',
      config: harness.newGameFlow.project.newGame,
    );
    final commit = commitNewGameDraft(
      journal: NewGameSeedCommitJournal.empty(),
      operationId: 'deferred-starter-commit',
      currentProjectRevision: harness.newGameFlow.preparation.projectRevision,
      expectedDraftRevision: draft.revision,
      draft: draft,
    );
    expect(
      commit.status,
      NewGameSeedCommitStatus.committed,
      reason: commit.issues.map((issue) => issue.toJson()).join(', '),
    );

    expect(
      harness.coordinator.snapshot.isActionEnabled(RuntimePlayerAction.newGame),
      isTrue,
      reason: harness.coordinator.snapshot
          .unavailableReasonFor(RuntimePlayerAction.newGame),
    );

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

    expect(
      result.status,
      RuntimePlayerCommandStatus.accepted,
      reason: result.safeMessage ??
          harness.coordinator.snapshot.failure?.safeMessage,
    );
    expect(
      harness.source.requests.single.initialGameState!.party.members,
      isEmpty,
    );
  });

  test('uses the runtime default slot when New Game has no payload', () async {
    final harness = RuntimePlayerTestHarness(
      defaultSaveSlot: const RuntimePlayerLoadSlot(
        profileId: 'default-player',
        slotId: 'main',
      ),
    );
    addTearDown(harness.dispose);
    await harness.coordinator.initialize();

    final result = await harness.coordinator.dispatch(
      RuntimePlayerCommand(
        action: RuntimePlayerAction.newGame,
        snapshotRevision: harness.coordinator.snapshot.revision,
      ),
    );

    expect(result.status, RuntimePlayerCommandStatus.accepted);
    expect(harness.source.requests.single.profileId, 'default-player');
    expect(harness.source.requests.single.slotId, 'main');
  });

  test('an explicit New Game slot overrides the runtime default', () async {
    final harness = RuntimePlayerTestHarness(
      defaultSaveSlot: const RuntimePlayerLoadSlot(
        profileId: 'default-player',
        slotId: 'main',
      ),
    );
    addTearDown(harness.dispose);
    await harness.coordinator.initialize();

    final result = await harness.coordinator.dispatch(
      RuntimePlayerCommand(
        action: RuntimePlayerAction.newGame,
        snapshotRevision: harness.coordinator.snapshot.revision,
        payload: const RuntimePlayerLoadSlot(
          profileId: 'selected-player',
          slotId: 'slot_2',
        ),
      ),
    );

    expect(result.status, RuntimePlayerCommandStatus.accepted);
    expect(harness.source.requests.single.profileId, 'selected-player');
    expect(harness.source.requests.single.slotId, 'slot_2');
  });

  test('projects guided identity into the committed new game state', () async {
    final harness = RuntimePlayerTestHarness();
    addTearDown(harness.dispose);
    await harness.coordinator.initialize();

    final result = await harness.coordinator.dispatch(
      RuntimePlayerCommand(
        action: RuntimePlayerAction.newGame,
        snapshotRevision: harness.coordinator.snapshot.revision,
        payload: RuntimePlayerNewGameSetup(
          slot: const RuntimePlayerLoadSlot(
            profileId: 'player',
            slotId: 'slot_1',
          ),
          identity: GameSessionPlayerIdentity(
            name: 'Camille',
            pronounSet: PlayerPronounSet.feminine,
          ),
        ),
      ),
    );

    expect(result.status, RuntimePlayerCommandStatus.accepted);
    final state = harness.source.requests.single.initialGameState!;
    expect(state.trainerProfile.name, 'Camille');
    expect(state.trainerProfile.avatarCharacterId, isNull);
    expect(state.trainerProfile.pronounSet, PlayerPronounSet.feminine);
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

  test('uses the runtime default slot when Load has no payload', () async {
    final seed = RuntimePlayerTestHarness();
    final save = compatiblePlayerSave(seed.source.identity);
    await seed.dispose();
    final harness = RuntimePlayerTestHarness(
      latestSave: save,
      defaultSaveSlot: const RuntimePlayerLoadSlot(
        profileId: 'player',
        slotId: 'slot_1',
      ),
    );
    addTearDown(harness.dispose);
    await harness.coordinator.initialize();

    final result = await harness.coordinator.dispatch(
      RuntimePlayerCommand(
        action: RuntimePlayerAction.load,
        snapshotRevision: harness.coordinator.snapshot.revision,
      ),
    );

    expect(result.status, RuntimePlayerCommandStatus.accepted);
    expect(
        harness.source.requests.single.launchMode, GameSessionLaunchMode.load);
    expect(harness.source.requests.single.saveReadHandle, 'save:player:slot_1');
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
