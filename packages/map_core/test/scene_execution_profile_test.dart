import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Scene execution profiles', () {
    test('keeps legacy scenes world-compatible and round-trips preSession', () {
      final world = SceneAsset.fromJson({
        'id': 'scene_world',
        'name': 'World scene',
        'graph': _graphJson(),
      });
      final preSession = SceneAsset.fromJson({
        'id': 'scene_pre_session',
        'name': 'Pre-session',
        'executionProfile': 'preSession',
        'graph': _graphJson(),
      });

      expect(world.executionProfile, SceneExecutionProfile.world);
      expect(world.toJson(), isNot(contains('executionProfile')));
      expect(preSession.executionProfile, SceneExecutionProfile.preSession);
      expect(preSession.toJson()['executionProfile'], 'preSession');
      expect(SceneAsset.fromJson(preSession.toJson()), preSession);
    });

    test('rejects an unknown execution profile at decode time', () {
      expect(
        () => SceneAsset.fromJson({
          'id': 'scene_future',
          'name': 'Future scene',
          'executionProfile': 'futureProfile',
          'graph': _graphJson(),
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('publishes the exact preSession V1 capability matrix', () {
      expect(
        sceneExecutionCapabilityMatrix.allowedCapabilities(
          SceneExecutionProfile.preSession,
        ),
        equals({
          SceneExecutionCapabilityIds.flowStart,
          SceneExecutionCapabilityIds.flowEnd,
          SceneExecutionCapabilityIds.draftLocalCondition,
          SceneExecutionCapabilityIds.flowBranch,
          SceneExecutionCapabilityIds.flowMerge,
          SceneExecutionCapabilityIds.presentationCinematic,
          SceneExecutionCapabilityIds.inputMessage,
          SceneExecutionCapabilityIds.inputChoice,
          SceneExecutionCapabilityIds.inputText,
          SceneExecutionCapabilityIds.inputConfirmation,
          SceneExecutionCapabilityIds.inputSelection,
          SceneExecutionCapabilityIds.draftAssign,
        }),
      );

      final forbidden = sceneExecutionCapabilityMatrix.evaluate(
        profile: SceneExecutionProfile.preSession,
        capabilityId: SceneExecutionCapabilityIds.worldBattle,
      );
      final unknown = sceneExecutionCapabilityMatrix.evaluate(
        profile: SceneExecutionProfile.preSession,
        capabilityId: 'future.capability',
      );

      expect(forbidden.isAllowed, isFalse);
      expect(
        forbidden.issueCode,
        SceneExecutionCapabilityIssueCode.forbiddenForProfile,
      );
      expect(
        forbidden.issueCode?.wireName,
        'scene.capability.forbiddenForProfile',
      );
      expect(unknown.isAllowed, isFalse);
      expect(
        unknown.issueCode,
        SceneExecutionCapabilityIssueCode.unknownCapability,
      );
      expect(unknown.issueCode?.wireName, 'scene.capability.unknown');
    });

    test('blocks world-only nodes with one shared diagnostic code', () async {
      final scene = _scene(
        profile: SceneExecutionProfile.preSession,
        middle: SceneNode(
          id: 'node_battle',
          kind: SceneNodeKind.battle,
          payload: SceneBattlePayload(
            battleKind: 'trainer',
            trainerId: 'trainer_rival',
          ),
        ),
        middlePort: 'victory',
        middleEdgeKind: SceneEdgeKind.battleVictory,
      );

      final diagnostic = diagnoseScene(
        scene,
      ).byCode(SceneDiagnosticCode.capabilityForbiddenForProfile).single;
      final build = buildSceneRuntimePlan(scene);
      final runtime =
          await SceneRuntimeExecutor(callbacks: _callbacks()).execute(
        _runtimePlan(
          profile: SceneExecutionProfile.preSession,
          middleIntent: SceneRuntimePlanIntent.startBattle(
            battleKind: 'trainer',
            trainerId: 'trainer_rival',
          ),
          middleKind: SceneNodeKind.battle,
          middlePort: 'victory',
          middleEdgeKind: SceneEdgeKind.battleVictory,
        ),
      );

      expect(
        diagnostic.capabilityIssueCode,
        SceneExecutionCapabilityIssueCode.forbiddenForProfile,
      );
      expect(build.plan, isNull);
      expect(
        build.diagnostics.single.capabilityIssueCode,
        diagnostic.capabilityIssueCode,
      );
      expect(
        runtime.errorCode,
        SceneRuntimeExecutionErrorCode.capabilityViolation,
      );
      expect(runtime.capabilityIssueCode, diagnostic.capabilityIssueCode);
    });

    test('builds and executes a dedicated Presentation intent', () async {
      final scene = _scene(
        profile: SceneExecutionProfile.preSession,
        middle: SceneNode(
          id: 'node_presentation',
          kind: SceneNodeKind.presentationCinematic,
          payload: ScenePresentationCinematicPayload(
            presentationCinematicId: 'presentation_intro',
          ),
        ),
        middlePort: 'completed',
        middleEdgeKind: SceneEdgeKind.presentationCompleted,
      );
      final presentationNode = scene.graph.nodes[1];
      expect(
        SceneNode.fromJson(presentationNode.toJson()),
        presentationNode,
      );
      final build = buildSceneRuntimePlan(scene);
      var presentationCalls = 0;

      final result = await SceneRuntimeExecutor(
        callbacks: _callbacks(
          playPresentationCinematic: (intent) {
            presentationCalls++;
            expect(intent.presentationCinematicId, 'presentation_intro');
            return 'completed';
          },
        ),
      ).execute(build.plan!);

      expect(build.diagnostics, isEmpty);
      expect(
        build.plan!.nodes[1].intent.kind,
        SceneRuntimePlanIntentKind.playPresentationCinematic,
      );
      expect(result.status, SceneRuntimeExecutionStatus.completed);
      expect(presentationCalls, 1);
    });

    test('preserves the world Cinematic intent and callback', () async {
      final scene = _scene(
        middle: SceneNode(
          id: 'node_cinematic',
          kind: SceneNodeKind.cinematic,
          payload: SceneCinematicPayload(cinematicId: 'cinematic_world'),
        ),
        middlePort: 'completed',
        middleEdgeKind: SceneEdgeKind.cinematicCompleted,
      );
      final build = buildSceneRuntimePlan(scene);
      var worldCalls = 0;

      final result = await SceneRuntimeExecutor(
        callbacks: _callbacks(
          playCinematic: (intent) {
            worldCalls++;
            expect(intent.cinematicId, 'cinematic_world');
            return 'completed';
          },
        ),
      ).execute(build.plan!);

      expect(result.status, SceneRuntimeExecutionStatus.completed);
      expect(worldCalls, 1);
    });

    test('authoring mutations preserve the execution profile', () {
      final source = SceneAsset.fromJson({
        'id': 'scene_pre_session',
        'name': 'Pre-session',
        'executionProfile': 'preSession',
        'graph': _graphJson(),
      });

      final result = addSceneLinkedAssetNodeDraft(
        source,
        payload: ScenePresentationCinematicPayload(
          presentationCinematicId: 'presentation_intro',
        ),
      );

      expect(
        result.updatedScene.executionProfile,
        SceneExecutionProfile.preSession,
      );

      final world = SceneAsset.fromJson({
        'id': 'scene_world',
        'name': 'World',
        'graph': _graphJson(),
      });
      expect(
        () => addSceneLinkedAssetNodeDraft(
          world,
          payload: ScenePresentationCinematicPayload(
            presentationCinematicId: 'presentation_intro',
          ),
        ),
        throwsArgumentError,
      );
      expect(
        () => addSceneLinkedAssetNodeDraft(
          source,
          payload: SceneCinematicPayload(cinematicId: 'cinematic_world'),
        ),
        throwsArgumentError,
      );
    });

    test('runtime rejects unknown declared capabilities fail-closed', () async {
      final plan = _runtimePlan(
        middleIntent: SceneRuntimePlanIntent.merge(),
        middleKind: SceneNodeKind.merge,
        middlePort: 'completed',
        middleEdgeKind: SceneEdgeKind.defaultFlow,
        middleCapabilityId: 'future.capability',
      );

      final result = await SceneRuntimeExecutor(
        callbacks: _callbacks(),
      ).execute(plan);

      expect(
        result.errorCode,
        SceneRuntimeExecutionErrorCode.capabilityViolation,
      );
      expect(
        result.capabilityIssueCode,
        SceneExecutionCapabilityIssueCode.unknownCapability,
      );
      expect(result.trace, isEmpty);
    });
  });
}

SceneAsset _scene({
  SceneExecutionProfile profile = SceneExecutionProfile.world,
  required SceneNode middle,
  required String middlePort,
  required SceneEdgeKind middleEdgeKind,
}) {
  return SceneAsset(
    id: 'scene_test',
    name: 'Scene test',
    executionProfile: profile,
    graph: SceneGraph(
      startNodeId: 'node_start',
      nodes: [
        SceneNode(id: 'node_start', kind: SceneNodeKind.start),
        middle,
        SceneNode(id: 'node_end', kind: SceneNodeKind.end),
      ],
      edges: [
        SceneEdge(
          id: 'edge_start_middle',
          fromNodeId: 'node_start',
          fromPortId: 'completed',
          toNodeId: middle.id,
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'edge_middle_end',
          fromNodeId: middle.id,
          fromPortId: middlePort,
          toNodeId: 'node_end',
          kind: middleEdgeKind,
        ),
      ],
    ),
    layout: SceneGraphLayout(
      nodeLayouts: [
        SceneNodeLayout(nodeId: 'node_start', x: 0, y: 0),
        SceneNodeLayout(nodeId: middle.id, x: 100, y: 0),
        SceneNodeLayout(nodeId: 'node_end', x: 200, y: 0),
      ],
    ),
  );
}

SceneRuntimePlan _runtimePlan({
  SceneExecutionProfile profile = SceneExecutionProfile.world,
  required SceneRuntimePlanIntent middleIntent,
  required SceneNodeKind middleKind,
  required String middlePort,
  required SceneEdgeKind middleEdgeKind,
  String? middleCapabilityId,
}) {
  return SceneRuntimePlan(
    sceneId: 'scene_runtime_test',
    executionProfile: profile,
    startNodeId: 'node_start',
    nodes: [
      SceneRuntimePlanNode(
        id: 'node_start',
        kind: SceneNodeKind.start,
        intent: SceneRuntimePlanIntent.start(),
      ),
      SceneRuntimePlanNode(
        id: 'node_middle',
        kind: middleKind,
        intent: middleIntent,
        capabilityId: middleCapabilityId,
      ),
      SceneRuntimePlanNode(
        id: 'node_end',
        kind: SceneNodeKind.end,
        intent: SceneRuntimePlanIntent.end(),
      ),
    ],
    edges: [
      const SceneRuntimePlanEdge(
        id: 'edge_start_middle',
        fromNodeId: 'node_start',
        fromPortId: 'completed',
        toNodeId: 'node_middle',
        kind: SceneEdgeKind.defaultFlow,
      ),
      SceneRuntimePlanEdge(
        id: 'edge_middle_end',
        fromNodeId: 'node_middle',
        fromPortId: middlePort,
        toNodeId: 'node_end',
        kind: middleEdgeKind,
      ),
    ],
    declaredOutcomes: const [],
  );
}

SceneRuntimeExecutionCallbacks _callbacks({
  SceneRuntimeIntentCallback? playCinematic,
  SceneRuntimeIntentCallback? playPresentationCinematic,
}) {
  return SceneRuntimeExecutionCallbacks(
    evaluateCondition: (_) => 'false',
    showDialogue: (_) => 'completed',
    startBattle: (_) => 'victory',
    playCinematic: playCinematic ?? (_) => 'completed',
    playPresentationCinematic: playPresentationCinematic,
    applyConsequence: (_) => 'completed',
  );
}

Map<String, dynamic> _graphJson() => {
      'startNodeId': 'node_start',
      'nodes': [
        {'id': 'node_start', 'kind': 'start'},
        {'id': 'node_end', 'kind': 'end'},
      ],
      'edges': [
        {
          'id': 'edge_start_end',
          'fromNodeId': 'node_start',
          'fromPortId': 'completed',
          'toNodeId': 'node_end',
          'kind': 'default',
        },
      ],
    };
