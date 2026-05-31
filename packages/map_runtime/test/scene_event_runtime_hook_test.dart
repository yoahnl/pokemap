import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  group('SceneEventRuntimeHook', () {
    test('ignores event pages without sceneTarget', () async {
      final fixture = _fixture(withSceneTarget: false);
      final calls = <String>[];

      final result = await SceneEventRuntimeHook(
        callbacks: _callbacks(calls: calls),
      ).runForEventPage(
        project: fixture.project,
        map: fixture.map,
        event: fixture.event,
        page: fixture.event.pages.single,
      );

      expect(result.status, SceneEventRuntimeHookStatus.notHandled);
      expect(result.handled, isFalse);
      expect(calls, isEmpty);
    });

    test('fails clearly when sceneTarget references a missing scene', () async {
      final fixture = _fixture();

      final result = await SceneEventRuntimeHook(
        callbacks: _callbacks(calls: <String>[]),
      ).runForEventPage(
        project: fixture.project.copyWith(scenes: const []),
        map: fixture.map,
        event: fixture.event,
        page: fixture.event.pages.single,
      );

      expect(result.status, SceneEventRuntimeHookStatus.failed);
      expect(
        result.errorCode,
        SceneEventRuntimeHookErrorCode.sceneTargetMissingScene,
      );
      expect(result.sceneId, 'scene_test_runtime');
      expect(result.executionResult, isNull);
    });

    test('fails before execution when scene diagnostics contain errors',
        () async {
      final fixture = _fixture(scene: _sceneWithoutEnd());
      final calls = <String>[];

      final result = await SceneEventRuntimeHook(
        callbacks: _callbacks(calls: calls),
      ).runForEventPage(
        project: fixture.project,
        map: fixture.map,
        event: fixture.event,
        page: fixture.event.pages.single,
      );

      expect(result.status, SceneEventRuntimeHookStatus.failed);
      expect(
        result.errorCode,
        SceneEventRuntimeHookErrorCode.sceneTargetDiagnosticsFailed,
      );
      expect(result.executionResult, isNull);
      expect(calls, isEmpty);
    });

    test('fails before execution when runtime plan cannot be built', () async {
      final fixture = _fixture(scene: _sceneWithUnsupportedAction());
      final calls = <String>[];

      final result = await SceneEventRuntimeHook(
        callbacks: _callbacks(calls: calls),
      ).runForEventPage(
        project: fixture.project,
        map: fixture.map,
        event: fixture.event,
        page: fixture.event.pages.single,
      );

      expect(result.status, SceneEventRuntimeHookStatus.failed);
      expect(
        result.errorCode,
        SceneEventRuntimeHookErrorCode.sceneTargetRuntimePlanFailed,
      );
      expect(result.executionResult, isNull);
      expect(calls, isEmpty);
    });

    test('executes a targeted Scene V1 through dialogue and battle victory',
        () async {
      final fixture = _fixture();
      final calls = <String>[];

      final result = await SceneEventRuntimeHook(
        callbacks: _callbacks(calls: calls, battleResult: 'victory'),
      ).runForEventPage(
        project: fixture.project,
        map: fixture.map,
        event: fixture.event,
        page: fixture.event.pages.single,
      );

      expect(result.status, SceneEventRuntimeHookStatus.completed);
      expect(result.handled, isTrue);
      expect(result.success, isTrue);
      expect(result.sceneId, 'scene_test_runtime');
      expect(result.executionResult?.status,
          SceneRuntimeExecutionStatus.completed);
      expect(result.executionResult?.finalNodeId, 'node_end_victory');
      expect(calls, [
        'dialogue:dialogue_test_intro',
        'battle:trainer_test_guard',
      ]);
    });

    test('executes a targeted Scene V1 through battle defeat branch', () async {
      final fixture = _fixture();

      final result = await SceneEventRuntimeHook(
        callbacks: _callbacks(calls: <String>[], battleResult: 'defeat'),
      ).runForEventPage(
        project: fixture.project,
        map: fixture.map,
        event: fixture.event,
        page: fixture.event.pages.single,
      );

      expect(result.status, SceneEventRuntimeHookStatus.completed);
      expect(result.executionResult?.finalNodeId, 'node_end_defeat');
      expect(
        result.executionResult?.trace.map((entry) => entry.nodeId),
        [
          'node_start',
          'node_dialogue',
          'node_battle',
          'node_end_defeat',
        ],
      );
    });

    test('does not require or promote ScenarioAsset to execute Scene V1',
        () async {
      final fixture = _fixture();

      expect(fixture.project.scenarios, isEmpty);

      final result = await SceneEventRuntimeHook(
        callbacks: _callbacks(calls: <String>[]),
      ).runForEventPage(
        project: fixture.project,
        map: fixture.map,
        event: fixture.event,
        page: fixture.event.pages.single,
      );

      expect(result.status, SceneEventRuntimeHookStatus.completed);
      expect(fixture.project.scenarios, isEmpty);
    });

    test('does not mutate project, map or game state', () async {
      final fixture = _fixture();
      final projectBefore = fixture.project.toJson();
      final mapBefore = fixture.map.toJson();
      const gameState = GameState(saveId: 'save_test_runtime');
      final gameStateBefore = gameState.toJson();

      await SceneEventRuntimeHook(
        callbacks: _callbacks(calls: <String>[]),
      ).runForEventPage(
        project: fixture.project,
        map: fixture.map,
        event: fixture.event,
        page: fixture.event.pages.single,
      );

      expect(fixture.project.toJson(), projectBefore);
      expect(fixture.map.toJson(), mapBefore);
      expect(gameState.toJson(), gameStateBefore);
    });

    test('reports callback execution failure without mutating state', () async {
      final fixture = _fixture();

      final result = await SceneEventRuntimeHook(
        callbacks: _callbacks(
          calls: <String>[],
          startBattle: (_) => throw StateError('battle seam unavailable'),
        ),
      ).runForEventPage(
        project: fixture.project,
        map: fixture.map,
        event: fixture.event,
        page: fixture.event.pages.single,
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
    });

    test('keeps Scene V1 hook files independent from battle package imports',
        () {
      const hookFiles = [
        'lib/src/application/scene_runtime/scene_event_runtime_hook.dart',
        'lib/src/application/scene_runtime/scene_runtime_host_callbacks.dart',
        'lib/src/application/scene_runtime/scene_runtime_hook_result.dart',
      ];

      for (final path in hookFiles) {
        expect(File(path).readAsStringSync(), isNot(contains('map_battle')));
      }
    });
  });
}

SceneRuntimeHostCallbacks _callbacks({
  required List<String> calls,
  String battleResult = 'victory',
  SceneRuntimeIntentCallback? evaluateCondition,
  SceneRuntimeIntentCallback? showDialogue,
  SceneRuntimeIntentCallback? startBattle,
  SceneRuntimeIntentCallback? playCinematic,
}) {
  return SceneRuntimeHostCallbacks(
    evaluateCondition: evaluateCondition ??
        (intent) {
          calls.add('condition:${intent.conditionSource?.sourceId}');
          return 'true';
        },
    showDialogue: showDialogue ??
        (intent) {
          calls.add('dialogue:${intent.dialogueId}');
          return 'completed';
        },
    startBattle: startBattle ??
        (intent) {
          calls.add('battle:${intent.trainerId}');
          return battleResult;
        },
    playCinematic: playCinematic ??
        (intent) {
          calls.add('cinematic:${intent.cinematicId}');
          return 'completed';
        },
  );
}

_RuntimeSceneFixture _fixture({
  bool withSceneTarget = true,
  SceneAsset? scene,
}) {
  final resolvedScene = scene ?? _scene();
  final project = ProjectManifest(
    name: 'Scene runtime hook test project',
    maps: const [
      ProjectMapEntry(
        id: 'map_test_runtime',
        name: 'Runtime Test Map',
        relativePath: 'maps/map_test_runtime.json',
      ),
    ],
    tilesets: const [],
    dialogues: const [
      ProjectDialogueEntry(
        id: 'dialogue_test_intro',
        name: 'Test Intro Dialogue',
        relativePath: 'dialogues/dialogue_test_intro.yarn',
      ),
    ],
    trainers: const [
      ProjectTrainerEntry(
        id: 'trainer_test_guard',
        name: 'Test Guard',
        trainerClass: 'Tester',
        team: [
          ProjectTrainerPokemonEntry(speciesId: 'pichu', level: 5),
        ],
      ),
    ],
    scenes: [resolvedScene],
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
  );
  final event = MapEventDefinition(
    id: 'event_test_scene',
    title: 'Test Scene Event',
    position: const EventPosition(layerId: 'l_base', x: 2, y: 2),
    pages: [
      MapEventPage(
        pageNumber: 0,
        message: 'Legacy message must stay bypassed when sceneTarget exists.',
        sceneTarget: withSceneTarget
            ? const MapEventSceneTarget(sceneId: 'scene_test_runtime')
            : null,
      ),
    ],
  );
  final map = MapData(
    id: 'map_test_runtime',
    name: 'Runtime Test Map',
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
  return _RuntimeSceneFixture(project: project, map: map, event: event);
}

SceneAsset _scene() {
  return SceneAsset(
    id: 'scene_test_runtime',
    name: 'Runtime Hook Test Scene',
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
        SceneNodeLayout(nodeId: 'node_battle', x: 560, y: 0),
        SceneNodeLayout(nodeId: 'node_end_victory', x: 840, y: -90),
        SceneNodeLayout(nodeId: 'node_end_defeat', x: 840, y: 90),
      ],
    ),
  );
}

SceneAsset _sceneWithoutEnd() {
  return SceneAsset(
    id: 'scene_test_runtime',
    name: 'Runtime Hook Test Scene',
    graph: SceneGraph(
      startNodeId: 'node_start',
      nodes: [
        SceneNode(id: 'node_start', kind: SceneNodeKind.start),
      ],
    ),
  );
}

SceneAsset _sceneWithUnsupportedAction() {
  return SceneAsset(
    id: 'scene_test_runtime',
    name: 'Runtime Hook Unsupported Action Scene',
    graph: SceneGraph(
      startNodeId: 'node_start',
      nodes: [
        SceneNode(id: 'node_start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'node_action',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload(actionKind: 'runtime_test_action'),
        ),
        SceneNode(id: 'node_end', kind: SceneNodeKind.end),
      ],
      edges: [
        SceneEdge(
          id: 'edge_start_action',
          fromNodeId: 'node_start',
          fromPortId: 'completed',
          toNodeId: 'node_action',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'edge_action_end',
          fromNodeId: 'node_action',
          fromPortId: 'completed',
          toNodeId: 'node_end',
          kind: SceneEdgeKind.actionCompleted,
        ),
      ],
    ),
  );
}

final class _RuntimeSceneFixture {
  const _RuntimeSceneFixture({
    required this.project,
    required this.map,
    required this.event,
  });

  final ProjectManifest project;
  final MapData map;
  final MapEventDefinition event;
}
