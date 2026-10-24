import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/application/narrative_scene_runtime_execution.dart';

import 'player/support/runtime_player_test_harness.dart';

void main() {
  final writer = SceneConsequenceRuntimeWriter(
    project: const ProjectManifest(name: 'Completion', maps: [], tilesets: []),
  );
  final state = GameState(
    saveId: 'victory-save',
    currentMapId: 'victory-hall',
    trainerProfile: const TrainerProfile(name: 'Alice'),
    party: const PlayerParty(
      members: [
        PlayerPokemon(
          individualId: 'pokemon-victor',
          speciesId: 'pikachu',
          level: 50,
          natureId: 'hardy',
          abilityId: 'static',
          knownMoveIds: ['thunderbolt'],
        ),
      ],
    ),
  );
  SceneConsequence completion({bool recordParty = true}) =>
      SceneConsequence.finishGame(
        endingId: 'ending-victory',
        outcome: SceneGameCompletionOutcome.victory,
        result: SceneFinishGameResult(
          title: SceneLocalizedText(fallback: 'Victoire'),
          summary: SceneLocalizedText(fallback: 'Bravo !'),
        ),
        postGamePolicy: ScenePostGamePolicy.returnToTitle,
        recordParty: recordParty,
      );

  test('records party and terminal marker in one replay-safe state write', () {
    final applied = writer.applyOne(
      state,
      completion(),
      completionRecordedAtEpochMs: 1792814400000,
    );
    expect(applied.success, isTrue);
    expect(applied.gameCompletion, isNotNull);
    expect(
      applied.gameState.completionPartyJournal.records.single.party,
      state.party,
    );
    expect(
      applied.gameState.metadata[sceneGameCompletionEndingMetadataKey],
      'ending-victory',
    );
    final replayed = writer.applyOne(applied.gameState, completion());
    expect(replayed.success, isTrue);
    expect(replayed.gameState, same(applied.gameState));
    expect(replayed.gameCompletion, isNull);
  });

  test(
    'cannot commit an archive without a frozen timestamp or actual party',
    () {
      for (final candidate in [
        state,
        state.copyWith(party: const PlayerParty()),
      ]) {
        final rejected = writer.applyOne(candidate, completion());
        expect(rejected.success, isFalse);
        expect(rejected.gameState, same(candidate));
        expect(rejected.gameCompletion, isNull);
      }
      final rejected = writer.applyOne(
        state.copyWith(party: const PlayerParty()),
        completion(),
        completionRecordedAtEpochMs: 1792814400000,
      );
      expect(rejected.success, isFalse);
      expect(rejected.gameState.metadata, isEmpty);
    },
  );

  test('a completed ending cannot retroactively archive the current party', () {
    final ended = writer.applyOne(state, completion(recordParty: false));
    final replayed = writer.applyOne(
      ended.gameState,
      completion(),
      completionRecordedAtEpochMs: 1792814400000,
    );
    expect(replayed.success, isTrue);
    expect(replayed.gameState.completionPartyJournal.records, isEmpty);
  });

  test(
    'the real scene executor freezes the victory before later callbacks',
    () async {
      final scene = SceneAsset(
        id: 'scene-completion',
        name: 'Completion',
        graph: SceneGraph(
          startNodeId: 'start',
          nodes: [
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(
              id: 'finish',
              kind: SceneNodeKind.action,
              payload: SceneActionPayload.consequence(completion()),
            ),
            SceneNode(
              id: 'after-completion',
              kind: SceneNodeKind.yarnDialogue,
              payload: SceneYarnDialoguePayload(
                dialogueId: 'observe',
                yarnNodeName: 'Start',
              ),
            ),
            SceneNode(id: 'end', kind: SceneNodeKind.end),
          ],
          edges: [
            SceneEdge(
              id: 'begin',
              fromNodeId: 'start',
              fromPortId: 'completed',
              toNodeId: 'finish',
              kind: SceneEdgeKind.defaultFlow,
            ),
            SceneEdge(
              id: 'complete',
              fromNodeId: 'finish',
              fromPortId: 'completed',
              toNodeId: 'after-completion',
              kind: SceneEdgeKind.actionCompleted,
            ),
            SceneEdge(
              id: 'dialogue-end',
              fromNodeId: 'after-completion',
              fromPortId: 'completed',
              toNodeId: 'end',
              kind: SceneEdgeKind.defaultFlow,
            ),
          ],
        ),
      );
      var clockReads = 0;
      var hostState = state;
      final result = await executeNarrativeEventScene(
        request: NarrativeSceneExecutionRequest(
          eventId: 'event',
          sceneId: scene.id,
          executionId: 'execution',
          gameState: state,
        ),
        project: ProjectManifest(
          name: 'Completion',
          maps: const [],
          tilesets: const [],
          scenes: [scene],
          dialogues: const [
            ProjectDialogueEntry(
              id: 'observe',
              name: 'Observe',
              relativePath: 'dialogues/observe.yarn',
            ),
          ],
        ),
        mapsById: const {},
        currentGameState: () => hostState,
        completionClock: () {
          clockReads++;
          return DateTime.fromMillisecondsSinceEpoch(
            1792814400000 + clockReads,
          );
        },
        callbacks: SceneRuntimeHostCallbacks(
          evaluateCondition: (_) => throw StateError('Unexpected condition'),
          showDialogue: (_) {
            hostState = state.copyWith(
              currentMapId: 'after-dialogue',
              party: const PlayerParty(),
              trainerProfile: const TrainerProfile(name: 'Later'),
            );
            return 'completed';
          },
          startBattle: (_) => throw StateError('Unexpected battle'),
          playCinematic: (_) => throw StateError('Unexpected cinematic'),
        ),
      );
      expect(hostState.party.members, isEmpty);
      expect(clockReads, 1);
      expect(
        result,
        isA<NarrativeSceneExecutionCompleted>(),
        reason: result is NarrativeSceneExecutionFailed
            ? result.failure.toString()
            : null,
      );
      final completed = result as NarrativeSceneExecutionCompleted;
      final archived =
          completed.updatedGameState.completionPartyJournal.records.single;
      expect(archived.party, state.party);
      expect(archived.mapId, state.currentMapId);
      expect(archived.trainerName, state.trainerProfile.name);
      expect(completed.updatedGameState.currentMapId, 'after-dialogue');
      expect(completed.updatedGameState.party.members, isEmpty);
      expect(clockReads, 1);
      expect(
        completed
            .updatedGameState
            .completionPartyJournal
            .records
            .single
            .completedAtEpochMs,
        1792814400001,
      );
      expect(completed.gameCompletion, isNotNull);
    },
  );

  test(
    'Player retries a failed archive checkpoint before showing results',
    () async {
      final harness = RuntimePlayerTestHarness();
      addTearDown(harness.dispose);
      await launchHarnessToPlaying(harness);
      final base = testPlayerCompletion(harness);
      final recorded = writer.applyOne(
        state.copyWith(saveId: base.finalCheckpoint.saveId),
        completion(),
        completionRecordedAtEpochMs: base.completedAt.millisecondsSinceEpoch,
      );
      expect(recorded.success, isTrue);
      final event = GameCompletionEvent(
        sessionId: base.sessionId,
        gameId: base.gameId,
        endingId: 'ending-victory',
        outcome: base.outcome,
        completedAt: base.completedAt,
        playTimeSeconds: base.playTimeSeconds,
        result: base.result,
        credits: base.credits,
        destination: base.destination,
        allowPostGameContinue: base.allowPostGameContinue,
        finalCheckpoint: GameSessionCheckpoint(
          saveId: base.finalCheckpoint.saveId,
          createdAt: base.finalCheckpoint.createdAt,
          updatedAt: base.completedAt,
          playTimeSeconds: base.playTimeSeconds,
          state: strictGameStateSaveJson(recorded.gameState),
        ),
      );
      harness.saves.commitError = StateError('disk full');
      harness.adapter.emitCompletion(event);
      await harness.coordinator.settle();
      expect(harness.coordinator.snapshot.phase, RuntimePlayerPhase.completing);
      expect(harness.coordinator.snapshot.result, isNull);
      expect(harness.saves.commits, isEmpty);
      harness.saves.commitError = null;
      final retried = await harness.coordinator.dispatch(
        RuntimePlayerCommand(
          action: RuntimePlayerAction.retry,
          snapshotRevision: harness.coordinator.snapshot.revision,
        ),
      );
      await harness.coordinator.settle();
      expect(retried.status, RuntimePlayerCommandStatus.accepted);
      expect(harness.coordinator.snapshot.phase, RuntimePlayerPhase.result);
      final committed = harness.saves.commits.single;
      expect(committed.status, SaveStatus.completed);
      final restored = gameStateFromStrictSaveJson(
        Map<String, dynamic>.from(committed.checkpoint.state),
      );
      expect(
        restored.completionPartyJournal,
        recorded.gameState.completionPartyJournal,
      );
      expect(harness.adapter.completionAcknowledgements, [false, true]);
    },
  );
}
