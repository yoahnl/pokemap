import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  group('Scene runtime golden slice smoke', () {
    test(
      'event sceneTarget waits for dialogue then commits victory consequences',
      () async {
        final fixture = _goldenSmokeFixture();
        const originalGameState = GameState(
          saveId: 'save_test_runtime',
          progression: PlayerProgression(completedStepIds: ['step_before']),
        );
        final dialogueCompleter =
            Completer<SceneDialogueRuntimeAwaitableResult>();
        final runtimeCalls = <String>[];
        var hookCompleted = false;

        expect(fixture.event.pages.single.sceneTarget?.sceneId,
            'scene_test_runtime');
        expect(fixture.project.scenarios, isEmpty);
        expect(fixture.project.worldRules, isEmpty);

        final hookFuture = SceneEventRuntimeHook(
          callbacks: _adapterCallbacks(
            runtimeCalls: runtimeCalls,
            dialogueLauncher: _SmokeDialogueLauncher((request) {
              runtimeCalls.add('dialogue:${request.dialogueId}');
              return dialogueCompleter.future;
            }),
            battleLauncher: _SmokeBattleLauncher((request) {
              runtimeCalls.add('battle:${request.trainerId}:victory');
              return const SceneBattleRuntimeOutcomeResult.completed(
                port: SceneBattleRuntimeOutcomePort.victory,
              );
            }),
          ),
        )
            .runForEventPage(
          project: fixture.project,
          map: fixture.map,
          event: fixture.event,
          page: fixture.event.pages.single,
          gameState: originalGameState,
        )
            .then((result) {
          hookCompleted = true;
          return result;
        });

        await Future<void>.delayed(Duration.zero);

        expect(hookCompleted, isFalse);
        expect(runtimeCalls, ['dialogue:dialogue_test_intro']);
        expect(originalGameState.storyFlags.activeFlags, isEmpty);
        expect(originalGameState.consumedEventIds, isEmpty);

        dialogueCompleter.complete(
          const SceneDialogueRuntimeAwaitableResult.completed(),
        );

        final result = await hookFuture;

        expect(result.status, SceneEventRuntimeHookStatus.completed);
        expect(result.sceneId, 'scene_test_runtime');
        expect(result.executionResult?.status,
            SceneRuntimeExecutionStatus.completed);
        expect(result.executionResult?.finalNodeId, 'node_end_victory');
        expect(result.executionResult?.trace.map((entry) => entry.nodeId), [
          'node_start',
          'node_dialogue',
          'node_battle',
          'node_action_victory_fact',
          'node_action_victory_consumed',
          'node_end_victory',
        ]);
        expect(runtimeCalls, [
          'dialogue:dialogue_test_intro',
          'battle:trainer_test_guard:victory',
        ]);
        expect(
          result.updatedGameState?.storyFlags.activeFlags,
          contains('fact_test_scene_victory'),
        );
        expect(
          result.updatedGameState?.storyFlags.activeFlags,
          isNot(contains('fact_test_scene_defeat')),
        );
        expect(
          result.updatedGameState?.consumedEventIds,
          contains('event_test_scene'),
        );
        expect(
          result.updatedGameState?.progression.completedStepIds,
          ['step_before'],
        );
        expect(
          result.consequenceWriteResult?.appliedConsequences,
          hasLength(2),
        );
        expect(originalGameState.storyFlags.activeFlags, isEmpty);
        expect(originalGameState.consumedEventIds, isEmpty);
        expect(originalGameState.progression.completedStepIds, ['step_before']);
      },
    );

    test(
      'event sceneTarget follows defeat branch and commits defeat consequence',
      () async {
        final fixture = _goldenSmokeFixture();
        const originalGameState = GameState(saveId: 'save_test_runtime');
        final runtimeCalls = <String>[];

        final result = await SceneEventRuntimeHook(
          callbacks: _adapterCallbacks(
            runtimeCalls: runtimeCalls,
            dialogueLauncher: _SmokeDialogueLauncher((request) {
              runtimeCalls.add('dialogue:${request.dialogueId}');
              return const SceneDialogueRuntimeAwaitableResult.completed();
            }),
            battleLauncher: _SmokeBattleLauncher((request) {
              runtimeCalls.add('battle:${request.trainerId}:defeat');
              return const SceneBattleRuntimeOutcomeResult.completed(
                port: SceneBattleRuntimeOutcomePort.defeat,
              );
            }),
          ),
        ).runForEventPage(
          project: fixture.project,
          map: fixture.map,
          event: fixture.event,
          page: fixture.event.pages.single,
          gameState: originalGameState,
        );

        expect(result.status, SceneEventRuntimeHookStatus.completed);
        expect(result.executionResult?.finalNodeId, 'node_end_defeat');
        expect(result.executionResult?.trace.map((entry) => entry.nodeId), [
          'node_start',
          'node_dialogue',
          'node_battle',
          'node_action_defeat_fact',
          'node_end_defeat',
        ]);
        expect(runtimeCalls, [
          'dialogue:dialogue_test_intro',
          'battle:trainer_test_guard:defeat',
        ]);
        expect(
          result.updatedGameState?.storyFlags.activeFlags,
          contains('fact_test_scene_defeat'),
        );
        expect(
          result.updatedGameState?.storyFlags.activeFlags,
          isNot(contains('fact_test_scene_victory')),
        );
        expect(result.updatedGameState?.consumedEventIds, isEmpty);
        expect(
          result.consequenceWriteResult?.appliedConsequences,
          hasLength(1),
        );
        expect(originalGameState.storyFlags.activeFlags, isEmpty);
      },
    );

    test(
      'event sceneTarget failure discards staged consequences',
      () async {
        final fixture = _failureAfterStagedConsequenceFixture();
        const originalGameState = GameState(saveId: 'save_test_runtime');
        final runtimeCalls = <String>[];

        final result = await SceneEventRuntimeHook(
          callbacks: _adapterCallbacks(
            runtimeCalls: runtimeCalls,
            dialogueLauncher: _SmokeDialogueLauncher((request) {
              runtimeCalls.add('dialogue:${request.dialogueId}');
              return const SceneDialogueRuntimeAwaitableResult.completed();
            }),
            battleLauncher: _SmokeBattleLauncher((request) {
              runtimeCalls.add('battle:${request.trainerId}:failed');
              return const SceneBattleRuntimeOutcomeResult.failed(
                errorCode: SceneBattleRuntimeOutcomeErrorCode.launcherFailed,
                message: 'Controlled battle failure.',
              );
            }),
          ),
        ).runForEventPage(
          project: fixture.project,
          map: fixture.map,
          event: fixture.event,
          page: fixture.event.pages.single,
          gameState: originalGameState,
        );

        expect(result.status, SceneEventRuntimeHookStatus.failed);
        expect(
          result.errorCode,
          SceneEventRuntimeHookErrorCode.sceneExecutionFailed,
        );
        expect(
          result.executionResult?.errorCode,
          SceneRuntimeExecutionErrorCode.callbackFailed,
        );
        expect(result.updatedGameState, isNull);
        expect(result.consequenceWriteResult, isNull);
        expect(runtimeCalls, [
          'dialogue:dialogue_test_intro',
          'battle:trainer_test_guard:failed',
        ]);
        expect(originalGameState.storyFlags.activeFlags, isEmpty);
        expect(originalGameState.consumedEventIds, isEmpty);
      },
    );
  });
}

SceneRuntimeHostCallbacks _adapterCallbacks({
  required List<String> runtimeCalls,
  required SceneDialogueRuntimeLauncher dialogueLauncher,
  required SceneBattleRuntimeLauncher battleLauncher,
}) {
  return SceneRuntimeHostCallbacks(
    evaluateCondition: (_) => throw StateError('Condition callback unused.'),
    showDialogue: (intent) async {
      final result = await SceneDialogueRuntimeAwaitableAdapter(
        runtimeSourceId: 'scene:golden-smoke',
        createdAtEpochMs: () => 1000,
        launcher: dialogueLauncher,
      ).showDialogue(intent);
      final scenePortId = result.scenePortId;
      if (!result.success || scenePortId == null) {
        throw StateError(result.message ?? 'Dialogue smoke failed.');
      }
      return scenePortId;
    },
    startBattle: (intent) async {
      final result = await SceneBattleRuntimeOutcomeAdapter(
        runtimeSourceId: 'scene:golden-smoke',
        defaultNpcEntityId: 'event_test_scene',
        createdAtEpochMs: () => 2000,
        launcher: battleLauncher,
      ).startBattle(intent);
      final scenePortId = result.scenePortId;
      if (!result.success || scenePortId == null) {
        throw StateError(result.message ?? 'Battle smoke failed.');
      }
      return scenePortId;
    },
    playCinematic: (_) => throw StateError('Cinematic callback unused.'),
  );
}

_GoldenSmokeFixture _goldenSmokeFixture() {
  return _fixture(scene: _goldenSmokeScene());
}

_GoldenSmokeFixture _failureAfterStagedConsequenceFixture() {
  return _fixture(scene: _failureAfterStagedConsequenceScene());
}

_GoldenSmokeFixture _fixture({required SceneAsset scene}) {
  const event = MapEventDefinition(
    id: 'event_test_scene',
    title: 'Runtime smoke event',
    position: EventPosition(layerId: 'l_base', x: 2, y: 2),
    pages: [
      MapEventPage(
        pageNumber: 0,
        sceneTarget: MapEventSceneTarget(sceneId: 'scene_test_runtime'),
      ),
    ],
  );
  final map = MapData(
    id: 'map_test_runtime',
    name: 'Runtime smoke map',
    size: const GridSize(width: 8, height: 8),
    layers: [
      MapLayer.tile(
        id: 'l_base',
        name: 'Base',
        tiles: List<int>.filled(64, 0),
      ),
    ],
    events: [event],
  );
  final project = ProjectManifest(
    name: 'Runtime smoke project',
    maps: const [
      ProjectMapEntry(
        id: 'map_test_runtime',
        name: 'Runtime smoke map',
        relativePath: 'maps/map_test_runtime.json',
      ),
    ],
    tilesets: const [],
    dialogues: const [
      ProjectDialogueEntry(
        id: 'dialogue_test_intro',
        name: 'Runtime smoke dialogue',
        relativePath: 'dialogues/dialogue_test_intro.yarn',
      ),
    ],
    trainers: const [
      ProjectTrainerEntry(
        id: 'trainer_test_guard',
        name: 'Runtime smoke trainer',
        trainerClass: 'Tester',
        team: [
          ProjectTrainerPokemonEntry(speciesId: 'pichu', level: 5),
        ],
      ),
    ],
    facts: [
      NarrativeFactDefinition(
        id: 'fact_test_scene_victory',
        label: 'Runtime smoke victory',
      ),
      NarrativeFactDefinition(
        id: 'fact_test_scene_defeat',
        label: 'Runtime smoke defeat',
      ),
      NarrativeFactDefinition(
        id: 'fact_test_event_consumed',
        label: 'Runtime smoke event consumed',
      ),
    ],
    scenes: [scene],
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
  );
  return _GoldenSmokeFixture(project: project, map: map, event: event);
}

SceneAsset _goldenSmokeScene() {
  return SceneAsset(
    id: 'scene_test_runtime',
    name: 'Runtime smoke scene',
    graph: SceneGraph(
      startNodeId: 'node_start',
      nodes: [
        SceneNode(id: 'node_start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'node_dialogue',
          kind: SceneNodeKind.yarnDialogue,
          payload: SceneYarnDialoguePayload(dialogueId: 'dialogue_test_intro'),
        ),
        SceneNode(
          id: 'node_battle',
          kind: SceneNodeKind.battle,
          payload: SceneBattlePayload(
            battleKind: 'trainer',
            trainerId: 'trainer_test_guard',
            declaredOutcomes: const ['victory', 'defeat'],
          ),
        ),
        SceneNode(
          id: 'node_action_victory_fact',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(
            SceneConsequence.setFact(
              factId: 'fact_test_scene_victory',
              value: true,
            ),
          ),
        ),
        SceneNode(
          id: 'node_action_victory_consumed',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(
            SceneConsequence.markEventConsumed(
              mapId: 'map_test_runtime',
              eventId: 'event_test_scene',
            ),
          ),
        ),
        SceneNode(
          id: 'node_action_defeat_fact',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(
            SceneConsequence.setFact(
              factId: 'fact_test_scene_defeat',
              value: true,
            ),
          ),
        ),
        SceneNode(id: 'node_end_victory', kind: SceneNodeKind.end),
        SceneNode(id: 'node_end_defeat', kind: SceneNodeKind.end),
      ],
      edges: [
        SceneEdge(
          id: 'edge_start_dialogue',
          fromNodeId: 'node_start',
          fromPortId: 'completed',
          toNodeId: 'node_dialogue',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'edge_dialogue_battle',
          fromNodeId: 'node_dialogue',
          fromPortId: 'completed',
          toNodeId: 'node_battle',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'edge_battle_victory',
          fromNodeId: 'node_battle',
          fromPortId: 'victory',
          toNodeId: 'node_action_victory_fact',
          kind: SceneEdgeKind.battleVictory,
        ),
        SceneEdge(
          id: 'edge_action_victory_fact_consumed',
          fromNodeId: 'node_action_victory_fact',
          fromPortId: 'completed',
          toNodeId: 'node_action_victory_consumed',
          kind: SceneEdgeKind.actionCompleted,
        ),
        SceneEdge(
          id: 'edge_action_victory_consumed_end',
          fromNodeId: 'node_action_victory_consumed',
          fromPortId: 'completed',
          toNodeId: 'node_end_victory',
          kind: SceneEdgeKind.actionCompleted,
        ),
        SceneEdge(
          id: 'edge_battle_defeat',
          fromNodeId: 'node_battle',
          fromPortId: 'defeat',
          toNodeId: 'node_action_defeat_fact',
          kind: SceneEdgeKind.battleDefeat,
        ),
        SceneEdge(
          id: 'edge_action_defeat_fact_end',
          fromNodeId: 'node_action_defeat_fact',
          fromPortId: 'completed',
          toNodeId: 'node_end_defeat',
          kind: SceneEdgeKind.actionCompleted,
        ),
      ],
    ),
    layout: SceneGraphLayout(
      nodeLayouts: [
        SceneNodeLayout(nodeId: 'node_start', x: 0, y: 0),
        SceneNodeLayout(nodeId: 'node_dialogue', x: 280, y: 0),
        SceneNodeLayout(nodeId: 'node_battle', x: 560, y: 0),
        SceneNodeLayout(nodeId: 'node_action_victory_fact', x: 840, y: -100),
        SceneNodeLayout(
          nodeId: 'node_action_victory_consumed',
          x: 1120,
          y: -100,
        ),
        SceneNodeLayout(nodeId: 'node_action_defeat_fact', x: 840, y: 120),
        SceneNodeLayout(nodeId: 'node_end_victory', x: 1400, y: -100),
        SceneNodeLayout(nodeId: 'node_end_defeat', x: 1120, y: 120),
      ],
    ),
  );
}

SceneAsset _failureAfterStagedConsequenceScene() {
  return SceneAsset(
    id: 'scene_test_runtime',
    name: 'Runtime smoke staged failure scene',
    graph: SceneGraph(
      startNodeId: 'node_start',
      nodes: [
        SceneNode(id: 'node_start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'node_dialogue',
          kind: SceneNodeKind.yarnDialogue,
          payload: SceneYarnDialoguePayload(dialogueId: 'dialogue_test_intro'),
        ),
        SceneNode(
          id: 'node_action_victory_fact',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(
            SceneConsequence.setFact(
              factId: 'fact_test_scene_victory',
              value: true,
            ),
          ),
        ),
        SceneNode(
          id: 'node_battle',
          kind: SceneNodeKind.battle,
          payload: SceneBattlePayload(
            battleKind: 'trainer',
            trainerId: 'trainer_test_guard',
            declaredOutcomes: const ['victory', 'defeat'],
          ),
        ),
        SceneNode(id: 'node_end_victory', kind: SceneNodeKind.end),
        SceneNode(id: 'node_end_defeat', kind: SceneNodeKind.end),
      ],
      edges: [
        SceneEdge(
          id: 'edge_start_dialogue',
          fromNodeId: 'node_start',
          fromPortId: 'completed',
          toNodeId: 'node_dialogue',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'edge_dialogue_action_victory_fact',
          fromNodeId: 'node_dialogue',
          fromPortId: 'completed',
          toNodeId: 'node_action_victory_fact',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'edge_action_victory_fact_battle',
          fromNodeId: 'node_action_victory_fact',
          fromPortId: 'completed',
          toNodeId: 'node_battle',
          kind: SceneEdgeKind.actionCompleted,
        ),
        SceneEdge(
          id: 'edge_battle_victory',
          fromNodeId: 'node_battle',
          fromPortId: 'victory',
          toNodeId: 'node_end_victory',
          kind: SceneEdgeKind.battleVictory,
        ),
        SceneEdge(
          id: 'edge_battle_defeat',
          fromNodeId: 'node_battle',
          fromPortId: 'defeat',
          toNodeId: 'node_end_defeat',
          kind: SceneEdgeKind.battleDefeat,
        ),
      ],
    ),
    layout: SceneGraphLayout(
      nodeLayouts: [
        SceneNodeLayout(nodeId: 'node_start', x: 0, y: 0),
        SceneNodeLayout(nodeId: 'node_dialogue', x: 280, y: 0),
        SceneNodeLayout(nodeId: 'node_action_victory_fact', x: 560, y: 0),
        SceneNodeLayout(nodeId: 'node_battle', x: 840, y: 0),
        SceneNodeLayout(nodeId: 'node_end_victory', x: 1120, y: -80),
        SceneNodeLayout(nodeId: 'node_end_defeat', x: 1120, y: 80),
      ],
    ),
  );
}

final class _GoldenSmokeFixture {
  const _GoldenSmokeFixture({
    required this.project,
    required this.map,
    required this.event,
  });

  final ProjectManifest project;
  final MapData map;
  final MapEventDefinition event;
}

final class _SmokeDialogueLauncher implements SceneDialogueRuntimeLauncher {
  const _SmokeDialogueLauncher(this._handler);

  final FutureOr<SceneDialogueRuntimeAwaitableResult> Function(
    SceneDialogueRuntimeDialogueRequest request,
  ) _handler;

  @override
  Future<SceneDialogueRuntimeAwaitableResult> showDialogue(
    SceneDialogueRuntimeDialogueRequest request,
  ) async {
    return _handler(request);
  }
}

final class _SmokeBattleLauncher implements SceneBattleRuntimeLauncher {
  const _SmokeBattleLauncher(this._handler);

  final FutureOr<SceneBattleRuntimeOutcomeResult> Function(
    SceneBattleRuntimeBattleRequest request,
  ) _handler;

  @override
  Future<SceneBattleRuntimeOutcomeResult> startTrainerBattle(
    SceneBattleRuntimeBattleRequest request,
  ) async {
    return _handler(request);
  }
}
