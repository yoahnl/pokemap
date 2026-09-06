import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import 'support/runtime_player_test_harness.dart';

void main() {
  test('prepares and projects a new game before creating its descriptor',
      () async {
    final harness = RuntimePlayerTestHarness();
    addTearDown(harness.dispose);
    await harness.coordinator.initialize();
    final configBefore = harness.newGameFlow.project.newGame.toJson();

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

    expect(result.status, RuntimePlayerCommandStatus.accepted);
    expect(harness.newGameFlow.prepareCalls, 1);
    expect(harness.source.requests, hasLength(1));
    final state = harness.source.requests.single.initialGameState;
    expect(state, isNotNull);
    expect(state!.saveId, 'a1d9f8ee-9bec-5c3d-85ce-9f5c4c8a2556');
    expect(state.currentMapId, 'start_map');
    expect(state.scriptVariables.values['player_name']?.value, 'Player');
    expect(harness.newGameFlow.project.newGame.toJson(), configBefore);
  });

  test('asks for overwrite confirmation before preload and preserves the save',
      () async {
    final seed = RuntimePlayerTestHarness();
    final existing = compatiblePlayerSave(seed.source.identity);
    await seed.dispose();
    final harness = RuntimePlayerTestHarness(latestSave: existing);
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
    await _waitForInteraction(harness.coordinator);

    final snapshot = harness.coordinator.snapshot;
    expect(snapshot.phase, RuntimePlayerPhase.preSession);
    expect(snapshot.preSessionRequest?.kind,
        SceneInteractionRequestKind.confirmation);
    expect(harness.newGameFlow.prepareCalls, 0);
    final request = snapshot.preSessionRequest!;
    final resolution = await harness.coordinator.dispatch(
      RuntimePlayerCommand(
        action: RuntimePlayerAction.resolvePreSessionInteraction,
        snapshotRevision: snapshot.revision,
        payload: SceneInteractionResult.confirmed(
          requestId: request.requestId,
          revision: request.revision,
          value: false,
        ),
      ),
    );

    expect(resolution.status, RuntimePlayerCommandStatus.accepted);
    expect((await launch).status, RuntimePlayerCommandStatus.cancelled);
    expect(harness.coordinator.snapshot.phase, RuntimePlayerPhase.title);
    expect(harness.source.requests, isEmpty);
    expect(harness.saves.commits, isEmpty);
    expect(await harness.saves.readSummary(existing.address), same(existing));
  });

  test('explains an unusable save instead of offering an ordinary overwrite',
      () async {
    final seed = RuntimePlayerTestHarness();
    final existing = unusablePlayerSave(seed.source.identity);
    await seed.dispose();
    final harness = RuntimePlayerTestHarness(latestSave: existing);
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
    await _waitForInteraction(harness.coordinator);

    final request = harness.coordinator.snapshot.preSessionRequest!;
    expect(request.kind, SceneInteractionRequestKind.confirmation);
    expect(
      request.prompt.localizationKey,
      isNot('player.new_game.confirm_overwrite'),
      reason: 'an unusable save must not reuse the ordinary overwrite prompt',
    );
    expect(
      request.prompt.arguments['reason'],
      playerSaveUnavailableReasonText(existing.unavailableReason!),
      reason: 'the player must be told why the save cannot be continued',
    );
    expect(
      request.prompt.arguments['reasonCode'],
      existing.unavailableReason!.name,
      reason: 'the machine-readable cause travels beside the wording, so a '
          'localization resolver can pick its own phrase',
    );

    final resolution = await harness.coordinator.dispatch(
      RuntimePlayerCommand(
        action: RuntimePlayerAction.resolvePreSessionInteraction,
        snapshotRevision: harness.coordinator.snapshot.revision,
        payload: SceneInteractionResult.confirmed(
          requestId: request.requestId,
          revision: request.revision,
          value: false,
        ),
      ),
    );

    expect(resolution.status, RuntimePlayerCommandStatus.accepted);
    expect((await launch).status, RuntimePlayerCommandStatus.cancelled);
    expect(harness.saves.commits, isEmpty);
    expect(await harness.saves.readSummary(existing.address), same(existing));
  });

  test('the overwrite prompt is written in a single language', () async {
    // La capture qui a lancé ce correctif : « Cette sauvegarde ne peut pas être
    // poursuivie : This ending does not allow post-game continuation. La
    // remplacer effacera définitivement sa progression. » Un gabarit d'un côté,
    // une phrase produite ailleurs de l'autre, et deux langues dans un même
    // paragraphe. Le test interpole comme la surface joueur et regarde la
    // phrase entière, pas ses morceaux.
    final seed = RuntimePlayerTestHarness();
    final existing = unusablePlayerSave(
      seed.source.identity,
      reason: PlayerSaveUnavailableReason.postGameContinuationRefused,
    );
    await seed.dispose();
    final harness = RuntimePlayerTestHarness(latestSave: existing);
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
    await _waitForInteraction(harness.coordinator);

    final prompt = harness.coordinator.snapshot.preSessionRequest!.prompt;
    var rendered = prompt.fallbackText!;
    for (final entry in prompt.arguments.entries) {
      rendered = rendered.replaceAll('{${entry.key}}', entry.value);
    }

    expect(
      rendered,
      'Cette sauvegarde ne peut pas être poursuivie : Cette fin n’autorise pas '
      'de reprise après la fin du jeu. La remplacer effacera définitivement sa '
      'progression.',
    );
    expect(
      rendered,
      isNot(contains('{')),
      reason: 'a placeholder the player can read is the other half of this bug',
    );

    await harness.coordinator.dispatch(
      RuntimePlayerCommand(
        action: RuntimePlayerAction.resolvePreSessionInteraction,
        snapshotRevision: harness.coordinator.snapshot.revision,
        payload: SceneInteractionResult.confirmed(
          requestId: harness.coordinator.snapshot.preSessionRequest!.requestId,
          revision: harness.coordinator.snapshot.preSessionRequest!.revision,
          value: false,
        ),
      ),
    );
    await launch;
  });

  test('an unusable save explains itself when Continue is refused', () async {
    final seed = RuntimePlayerTestHarness();
    final existing = unusablePlayerSave(
      seed.source.identity,
      reason: PlayerSaveUnavailableReason.incompatibleVersion,
    );
    await seed.dispose();
    final harness = RuntimePlayerTestHarness(latestSave: existing);
    addTearDown(harness.dispose);
    await harness.coordinator.initialize();

    final result = await harness.coordinator.dispatch(
      RuntimePlayerCommand(
        action: RuntimePlayerAction.continueGame,
        snapshotRevision: harness.coordinator.snapshot.revision,
        payload: const RuntimePlayerLoadSlot(
          profileId: 'player',
          slotId: 'slot_1',
        ),
      ),
    );

    expect(result.status, RuntimePlayerCommandStatus.unavailable);
    expect(
      result.safeMessage,
      playerSaveUnavailableReasonText(existing.unavailableReason!),
      reason: 'the player must learn why the save cannot be continued',
    );
    expect(harness.source.requests, isEmpty);
  });

  test('a refused Continue publishes recovery actions and can delete the save',
      () async {
    final seed = RuntimePlayerTestHarness();
    final existing = unusablePlayerSave(seed.source.identity);
    await seed.dispose();
    final harness = RuntimePlayerTestHarness(latestSave: existing);
    addTearDown(harness.dispose);
    await harness.coordinator.initialize();

    await harness.coordinator.dispatch(
      RuntimePlayerCommand(
        action: RuntimePlayerAction.continueGame,
        snapshotRevision: harness.coordinator.snapshot.revision,
        payload: const RuntimePlayerLoadSlot(
          profileId: 'player',
          slotId: 'slot_1',
        ),
      ),
    );

    final recovery = harness.coordinator.snapshot.saveRecovery;
    expect(recovery, isNotNull);
    expect(
      recovery!.recommendedActions,
      contains(SaveRecoveryAction.deleteSave),
    );

    final deleted = await harness.coordinator.dispatch(
      RuntimePlayerCommand(
        action: RuntimePlayerAction.deleteUnusableSave,
        snapshotRevision: harness.coordinator.snapshot.revision,
      ),
    );

    expect(deleted.status, RuntimePlayerCommandStatus.accepted);
    expect(harness.saves.deletedAddresses, <SaveSlotAddress>[existing.address]);
    expect(harness.coordinator.snapshot.saveRecovery, isNull);
    expect(await harness.saves.readSummary(existing.address), isNull);
  });

  test('confirmed overwrite keeps the old save until a checkpoint commits',
      () async {
    final seed = RuntimePlayerTestHarness();
    final existing = compatiblePlayerSave(seed.source.identity);
    await seed.dispose();
    final harness = RuntimePlayerTestHarness(latestSave: existing);
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
    await _waitForInteraction(harness.coordinator);
    final snapshot = harness.coordinator.snapshot;
    final request = snapshot.preSessionRequest!;

    final resolution = await harness.coordinator.dispatch(
      RuntimePlayerCommand(
        action: RuntimePlayerAction.resolvePreSessionInteraction,
        snapshotRevision: snapshot.revision,
        payload: SceneInteractionResult.confirmed(
          requestId: request.requestId,
          revision: request.revision,
          value: true,
        ),
      ),
    );

    expect(resolution.status, RuntimePlayerCommandStatus.accepted);
    expect((await launch).status, RuntimePlayerCommandStatus.accepted);
    expect(harness.newGameFlow.prepareCalls, 1);
    expect(harness.source.requests, hasLength(1));
    expect(harness.saves.commits, isEmpty);
    expect(await harness.saves.readSummary(existing.address), same(existing));
  });

  test('runs a text-only preSession interaction before one exact session',
      () async {
    final harness = RuntimePlayerTestHarness(
      preSessionRunner: _MessagePreSessionRunner(),
    );
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
    await _waitForInteraction(harness.coordinator);
    final snapshot = harness.coordinator.snapshot;
    final request = snapshot.preSessionRequest!;

    final resolution = await harness.coordinator.dispatch(
      RuntimePlayerCommand(
        action: RuntimePlayerAction.resolvePreSessionInteraction,
        snapshotRevision: snapshot.revision,
        payload: SceneInteractionResult.acknowledged(
          requestId: request.requestId,
          revision: request.revision,
        ),
      ),
    );
    final staleReplay = await harness.coordinator.dispatch(
      RuntimePlayerCommand(
        action: RuntimePlayerAction.resolvePreSessionInteraction,
        snapshotRevision: snapshot.revision,
        payload: SceneInteractionResult.acknowledged(
          requestId: request.requestId,
          revision: request.revision,
        ),
      ),
    );

    expect(resolution.status, RuntimePlayerCommandStatus.accepted);
    expect(staleReplay.status, isNot(RuntimePlayerCommandStatus.accepted));
    expect((await launch).status, RuntimePlayerCommandStatus.accepted);
    expect(harness.source.requests, hasLength(1));
    expect(harness.adapters, hasLength(1));
  });

  test('clears a resolved preSession request while its runner continues',
      () async {
    final release = Completer<void>();
    final harness = RuntimePlayerTestHarness(
      preSessionRunner: _HoldingMessagePreSessionRunner(release.future),
    );
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
    await _waitForInteraction(harness.coordinator);
    final snapshot = harness.coordinator.snapshot;
    final request = snapshot.preSessionRequest!;

    final resolution = await harness.coordinator.dispatch(
      RuntimePlayerCommand(
        action: RuntimePlayerAction.resolvePreSessionInteraction,
        snapshotRevision: snapshot.revision,
        payload: SceneInteractionResult.acknowledged(
          requestId: request.requestId,
          revision: request.revision,
        ),
      ),
    );

    expect(resolution.status, RuntimePlayerCommandStatus.accepted);
    expect(harness.coordinator.snapshot.phase, RuntimePlayerPhase.preSession);
    expect(harness.coordinator.snapshot.preSessionRequest, isNull);
    expect(
      harness.coordinator.snapshot
          .isActionEnabled(RuntimePlayerAction.resolvePreSessionInteraction),
      isFalse,
    );

    release.complete();
    expect((await launch).status, RuntimePlayerCommandStatus.accepted);
  });

  test('cancel and a late preload completion cannot create a session',
      () async {
    final gate = Completer<void>();
    final harness = RuntimePlayerTestHarness(
      newGamePreparationGate: gate.future,
    );
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
    await _waitForPhase(harness.coordinator, RuntimePlayerPhase.preSession);
    final cancelled = await harness.coordinator.dispatch(
      RuntimePlayerCommand(
        action: RuntimePlayerAction.cancel,
        snapshotRevision: harness.coordinator.snapshot.revision,
      ),
    );
    gate.complete();

    expect(cancelled.status, RuntimePlayerCommandStatus.accepted);
    expect((await launch).status, RuntimePlayerCommandStatus.cancelled);
    expect(harness.newGameFlow.clearCalls, greaterThanOrEqualTo(1));
    expect(harness.source.requests, isEmpty);
    expect(harness.saves.commits, isEmpty);
  });

  test('project drift fails closed and retry uses a fresh preparation',
      () async {
    final harness = RuntimePlayerTestHarness();
    addTearDown(harness.dispose);
    await harness.coordinator.initialize();
    harness.newGameFlow.currentProjectRevision = 'sha256:changed';

    final failed = await harness.coordinator.dispatch(
      RuntimePlayerCommand(
        action: RuntimePlayerAction.newGame,
        snapshotRevision: harness.coordinator.snapshot.revision,
        payload: const RuntimePlayerLoadSlot(
          profileId: 'player',
          slotId: 'slot_1',
        ),
      ),
    );

    expect(failed.status, RuntimePlayerCommandStatus.failed);
    expect(harness.coordinator.snapshot.phase, RuntimePlayerPhase.error);
    expect(harness.source.requests, isEmpty);
    harness.newGameFlow.currentProjectRevision =
        harness.newGameFlow.preparation.projectRevision;

    final retried = await harness.coordinator.dispatch(
      RuntimePlayerCommand(
        action: RuntimePlayerAction.retry,
        snapshotRevision: harness.coordinator.snapshot.revision,
      ),
    );

    expect(retried.status, RuntimePlayerCommandStatus.accepted);
    expect(harness.newGameFlow.prepareCalls, 2);
    expect(harness.source.requests, hasLength(1));
  });
}

final class _MessagePreSessionRunner implements RuntimeNewGamePreSessionRunner {
  @override
  Future<NewGameDraft> run({
    required String runId,
    required NewGameDraft draft,
    required SceneStructuredInteractionPort interactions,
  }) async {
    final result = await interactions.request(
      SceneInteractionRequest.message(
        requestId: '$runId:intro',
        revision: 0,
        prompt: SceneInteractionPrompt(
          localizationKey: 'test.pre_session.intro',
          fallbackText: 'Bienvenue.',
        ),
      ),
    );
    if (result is SceneCancelledInteractionResult) {
      throw StateError('cancelled');
    }
    return draft;
  }
}

final class _HoldingMessagePreSessionRunner
    implements RuntimeNewGamePreSessionRunner {
  _HoldingMessagePreSessionRunner(this.release);

  final Future<void> release;

  @override
  Future<NewGameDraft> run({
    required String runId,
    required NewGameDraft draft,
    required SceneStructuredInteractionPort interactions,
  }) async {
    final result = await interactions.request(
      SceneInteractionRequest.message(
        requestId: '$runId:intro',
        revision: 0,
        prompt: SceneInteractionPrompt(
          localizationKey: 'test.pre_session.intro',
          fallbackText: 'Bienvenue.',
        ),
      ),
    );
    if (result is SceneCancelledInteractionResult) {
      throw StateError('cancelled');
    }
    await release;
    return draft;
  }
}

Future<void> _waitForInteraction(RuntimePlayerCoordinator coordinator) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    if (coordinator.snapshot.preSessionRequest != null) return;
    await Future<void>.delayed(Duration.zero);
  }
  fail('No preSession interaction was published.');
}

Future<void> _waitForPhase(
  RuntimePlayerCoordinator coordinator,
  RuntimePlayerPhase phase,
) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    if (coordinator.snapshot.phase == phase) return;
    await Future<void>.delayed(Duration.zero);
  }
  fail('Player never reached ${phase.name}.');
}
