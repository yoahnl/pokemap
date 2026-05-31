import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Scene authoring operations', () {
    test('creates a minimal scene draft in ProjectManifest.scenes', () {
      final project = _project();

      final result = createSceneDraftInProject(
        project,
        name: ' Rencontre rival ',
        description: ' Premier brouillon ',
      );

      expect(project.scenes, isEmpty);
      expect(result.updatedProject.scenes, hasLength(1));
      expect(result.createdScene.id, 'scene_rencontre_rival');
      expect(result.createdScene.name, 'Rencontre rival');
      expect(result.createdScene.description, 'Premier brouillon');
      expect(result.createdScene.tags, isEmpty);
      expect(result.createdScene.declaredOutcomes, isEmpty);
      expect(result.createdScene.graph.startNodeId, 'node_start');
      expect(result.createdScene.graph.nodes.map((node) => node.id), [
        'node_start',
        'node_end',
      ]);
      expect(result.createdScene.graph.edges.single.id, 'edge_start_end');
      expect(result.createdScene.graph.edges.single.fromPortId, 'completed');
      expect(
        result.createdScene.graph.edges.single.kind,
        SceneEdgeKind.defaultFlow,
      );
      expect(
          result.createdScene.layout.nodeLayouts.map((node) => node.nodeId), [
        'node_start',
        'node_end',
      ]);
    });

    test('generates suffixed ids on collision', () {
      final project = _project(
        scenes: [
          _scene('scene_rencontre_rival'),
          _scene('scene_rencontre_rival_2'),
        ],
      );

      final result = createSceneDraftInProject(
        project,
        name: 'Rencontre rival',
      );

      expect(result.createdScene.id, 'scene_rencontre_rival_3');
      expect(result.updatedProject.scenes, hasLength(3));
    });

    test('rejects an empty scene name', () {
      expect(
        () => createSceneDraftInProject(_project(), name: '   '),
        throwsArgumentError,
      );
    });

    test('does not touch scenarios or storylines', () {
      final scenario = ScenarioAsset(
        id: 'scenario_existing',
        name: 'Existing scenario',
        scope: ScenarioScope.localEventFlow,
        entryNodeId: 'scenario_node_start',
        nodes: [
          ScenarioNode(
            id: 'scenario_node_start',
            type: ScenarioNodeType.start,
            title: 'Start',
          ),
        ],
      );
      final storyline = StorylineAsset(
        id: 'storyline_existing',
        title: 'Existing storyline',
        type: StorylineType.main,
      );
      final project = _project(
        scenarios: [scenario],
        storylines: [storyline],
      );

      final result = createSceneDraftInProject(project, name: 'Scene');

      expect(result.updatedProject.scenarios, project.scenarios);
      expect(result.updatedProject.storylines, project.storylines);
      expect(result.updatedProject.scenes, hasLength(1));
    });

    test('adds a condition node draft without mutating the original scene', () {
      final scene = _scene(
        'scene_authoring',
        metadata: const {'owner': 'test'},
        declaredOutcomes: [SceneOutcome(id: 'done', label: 'Done')],
      );

      final result = addSceneNodeDraft(
        scene,
        kind: SceneNodeKind.condition,
        afterNodeId: 'node_start',
      );

      expect(scene.graph.nodes.map((node) => node.id), [
        'node_start',
        'node_end',
      ]);
      expect(result.createdNode.id, 'node_condition');
      expect(result.createdNode.title, 'Condition');
      expect(result.createdNode.kind, SceneNodeKind.condition);
      expect(result.createdNode.payload, isA<SceneConditionPayload>());
      expect(result.updatedScene.id, scene.id);
      expect(result.updatedScene.metadata, scene.metadata);
      expect(result.updatedScene.declaredOutcomes, scene.declaredOutcomes);
      expect(result.updatedScene.graph.edges, scene.graph.edges);
      expect(result.updatedScene.graph.nodes.map((node) => node.id), [
        'node_start',
        'node_end',
        'node_condition',
      ]);
      final layout = result.updatedScene.layout.nodeLayouts
          .firstWhere((layout) => layout.nodeId == 'node_condition');
      expect(layout.x, 324);
      expect(layout.y, 80);
    });

    test('adds merge and end node drafts with stable suffixed ids', () {
      var scene = _scene('scene_authoring');

      final merge = addSceneNodeDraft(scene, kind: SceneNodeKind.merge);
      scene = merge.updatedScene;
      final secondMerge = addSceneNodeDraft(scene, kind: SceneNodeKind.merge);
      scene = secondMerge.updatedScene;
      final end = addSceneNodeDraft(scene, kind: SceneNodeKind.end);

      expect(merge.createdNode.id, 'node_merge');
      expect(merge.createdNode.payload, isA<SceneMergePayload>());
      expect(secondMerge.createdNode.id, 'node_merge_2');
      expect(end.createdNode.id, 'node_end_2');
      expect(end.createdNode.title, 'Fin');
      expect(end.createdNode.payload, isA<SceneEndPayload>());
      expect(end.updatedScene.graph.edges, scene.graph.edges);
      expect(
        end.updatedScene.layout.nodeLayouts
            .map((layout) => layout.nodeId)
            .contains('node_end_2'),
        isTrue,
      );
    });

    test('rejects unsupported node kinds in V0 without fake refs', () {
      final scene = _scene('scene_authoring');

      for (final kind in [
        SceneNodeKind.start,
        SceneNodeKind.yarnDialogue,
        SceneNodeKind.action,
        SceneNodeKind.battle,
        SceneNodeKind.cinematic,
        SceneNodeKind.branchByOutcome,
      ]) {
        expect(
          () => addSceneNodeDraft(scene, kind: kind),
          throwsA(isA<ArgumentError>()),
          reason: '${kind.name} must not be authorable in V0',
        );
      }
    });

    test('adds linked asset payload nodes without fake refs', () {
      var scene = _scene('scene_authoring');

      final dialogue = addSceneLinkedAssetNodeDraft(
        scene,
        payload: SceneYarnDialoguePayload(
          dialogueId: 'test_dialogue',
          yarnNodeName: 'Start',
        ),
        title: 'Test Dialogue',
      );
      scene = dialogue.updatedScene;
      final battle = addSceneLinkedAssetNodeDraft(
        scene,
        payload: SceneBattlePayload(
          battleKind: 'trainer',
          trainerId: 'test_trainer',
          declaredOutcomes: const ['victory', 'defeat'],
        ),
        title: 'Trainer Battle',
      );

      expect(dialogue.createdNode.id, 'node_yarn_dialogue');
      expect(dialogue.createdNode.kind, SceneNodeKind.yarnDialogue);
      expect(dialogue.createdNode.payload, isA<SceneYarnDialoguePayload>());
      expect(
        (dialogue.createdNode.payload as SceneYarnDialoguePayload)
            .expectedOutcomes,
        isEmpty,
      );
      expect(battle.createdNode.id, 'node_battle');
      expect(battle.createdNode.kind, SceneNodeKind.battle);
      expect(
        (battle.createdNode.payload as SceneBattlePayload).declaredOutcomes,
        ['victory', 'defeat'],
      );
      expect(battle.updatedScene.graph.edges, scene.graph.edges);
      expect(
        battle.updatedScene.layout.nodeLayouts.map((layout) => layout.nodeId),
        containsAll(['node_yarn_dialogue', 'node_battle']),
      );
      expect(_scene('scene_authoring').graph.nodes.map((node) => node.id), [
        'node_start',
        'node_end',
      ]);
    });

    test('rejects linked asset node drafts outside V1-22 scope', () {
      final scene = _scene('scene_authoring');

      for (final payload in [
        SceneActionPayload(actionKind: 'test_action'),
        SceneBranchByOutcomePayload(),
        SceneConditionPayload(),
        SceneEndPayload(),
        SceneMergePayload(),
        SceneStartPayload(),
      ]) {
        expect(
          () => addSceneLinkedAssetNodeDraft(scene, payload: payload),
          throwsA(isA<ArgumentError>()),
          reason:
              '${payload.kind.name} must not be added by payload pickers V0',
        );
      }
    });

    test('updates a Yarn dialogue payload without mutating scene structure',
        () {
      final existingEdge = SceneEdge(
        id: 'edge_node_yarn_completed_node_end',
        fromNodeId: 'node_yarn',
        fromPortId: 'completed',
        toNodeId: 'node_end',
        kind: SceneEdgeKind.defaultFlow,
      );
      final scene = _edgeAuthoringSceneWithYarnSource(
        edges: [existingEdge],
      );

      final result = updateSceneYarnDialoguePayload(
        scene,
        nodeId: 'node_yarn',
        dialogueId: ' dialogue_updated ',
        yarnNodeName: ' UpdatedStart ',
      );

      final payload = result.updatedPayload;
      expect(payload.dialogueId, 'dialogue_updated');
      expect(payload.yarnNodeName, 'UpdatedStart');
      expect(payload.expectedOutcomes, ['accept']);
      expect(result.updatedNode.id, 'node_yarn');
      expect(result.updatedNode.kind, SceneNodeKind.yarnDialogue);
      expect(result.updatedScene.graph.edges, scene.graph.edges);
      expect(result.updatedScene.layout, scene.layout);
      expect(result.updatedScene.declaredOutcomes, scene.declaredOutcomes);
      expect(result.updatedScene.metadata, scene.metadata);
      expect(
        (scene.graph.nodes.firstWhere((node) => node.id == 'node_yarn').payload
                as SceneYarnDialoguePayload)
            .dialogueId,
        'dialogue_test',
      );
    });

    test('rejects invalid Yarn dialogue payload updates', () {
      final scene = _edgeAuthoringSceneWithYarnSource();

      expect(
        () => updateSceneYarnDialoguePayload(
          scene,
          nodeId: 'node_missing',
          dialogueId: 'dialogue_updated',
        ),
        throwsArgumentError,
      );
      expect(
        () => updateSceneYarnDialoguePayload(
          scene,
          nodeId: 'node_start',
          dialogueId: 'dialogue_updated',
        ),
        throwsArgumentError,
      );
      expect(
        () => updateSceneYarnDialoguePayload(
          scene,
          nodeId: 'node_yarn',
          dialogueId: '   ',
        ),
        throwsArgumentError,
      );
    });

    test('updates a trainer battle payload without mutating scene structure',
        () {
      final victoryEdge = SceneEdge(
        id: 'edge_node_battle_victory_node_end',
        fromNodeId: 'node_battle',
        fromPortId: 'victory',
        toNodeId: 'node_end',
        kind: SceneEdgeKind.battleVictory,
      );
      final defeatEdge = SceneEdge(
        id: 'edge_node_battle_defeat_node_end_2',
        fromNodeId: 'node_battle',
        fromPortId: 'defeat',
        toNodeId: 'node_end_2',
        kind: SceneEdgeKind.battleDefeat,
      );
      final scene = _edgeAuthoringSceneWithBattleSource(
        edges: [victoryEdge, defeatEdge],
      );

      final result = updateSceneBattlePayload(
        scene,
        nodeId: 'node_battle',
        trainerId: ' trainer_updated ',
      );

      final payload = result.updatedPayload;
      expect(payload.battleKind, 'trainer');
      expect(payload.trainerId, 'trainer_updated');
      expect(payload.declaredOutcomes, ['victory', 'defeat']);
      expect(result.updatedNode.id, 'node_battle');
      expect(result.updatedNode.kind, SceneNodeKind.battle);
      expect(result.updatedScene.graph.edges, scene.graph.edges);
      expect(result.updatedScene.layout, scene.layout);
      expect(result.updatedScene.declaredOutcomes, scene.declaredOutcomes);
      expect(result.updatedScene.metadata, scene.metadata);
      expect(
        (scene.graph.nodes
                .firstWhere((node) => node.id == 'node_battle')
                .payload as SceneBattlePayload)
            .trainerId,
        'trainer_test',
      );
    });

    test('rejects invalid trainer battle payload updates', () {
      final scene = _edgeAuthoringSceneWithBattleSource();

      expect(
        () => updateSceneBattlePayload(
          scene,
          nodeId: 'node_missing',
          trainerId: 'trainer_updated',
        ),
        throwsArgumentError,
      );
      expect(
        () => updateSceneBattlePayload(
          scene,
          nodeId: 'node_start',
          trainerId: 'trainer_updated',
        ),
        throwsArgumentError,
      );
      expect(
        () => updateSceneBattlePayload(
          scene,
          nodeId: 'node_battle',
          trainerId: '   ',
        ),
        throwsArgumentError,
      );
    });

    test('exposes authorable output ports for V0 node kinds', () {
      expect(
        authorableSceneOutputPortsForNode(
          SceneNode(id: 'node_start', kind: SceneNodeKind.start),
        ).map((port) => (port.id, port.edgeKind)),
        [('completed', SceneEdgeKind.defaultFlow)],
      );
      expect(
        authorableSceneOutputPortsForNode(
          SceneNode(id: 'node_condition', kind: SceneNodeKind.condition),
        ).map((port) => (port.id, port.edgeKind)),
        [
          ('true', SceneEdgeKind.conditionTrue),
          ('false', SceneEdgeKind.conditionFalse),
        ],
      );
      expect(
        authorableSceneOutputPortsForNode(
          SceneNode(id: 'node_merge', kind: SceneNodeKind.merge),
        ).map((port) => (port.id, port.edgeKind)),
        [('completed', SceneEdgeKind.defaultFlow)],
      );
      expect(
        authorableSceneOutputPortsForNode(
          SceneNode(id: 'node_end', kind: SceneNodeKind.end),
        ),
        isEmpty,
      );
      expect(
        authorableSceneOutputPortsForNode(
          SceneNode(
            id: 'node_dialogue',
            kind: SceneNodeKind.yarnDialogue,
            payload: SceneYarnDialoguePayload(dialogueId: 'dialogue_test'),
          ),
        ).map((port) => (port.id, port.edgeKind)),
        [('completed', SceneEdgeKind.defaultFlow)],
      );
      expect(
        authorableSceneOutputPortsForNode(
          SceneNode(
            id: 'node_battle',
            kind: SceneNodeKind.battle,
            payload: SceneBattlePayload(
              battleKind: 'trainer',
              trainerId: 'trainer_test',
              declaredOutcomes: const ['victory', 'defeat'],
            ),
          ),
        ).map((port) => (port.id, port.edgeKind)),
        [
          ('victory', SceneEdgeKind.battleVictory),
          ('defeat', SceneEdgeKind.battleDefeat),
        ],
      );
    });

    test('adds a start completed edge with derived default kind', () {
      final scene = _edgeAuthoringScene();

      final result = addSceneEdgeDraft(
        scene,
        fromNodeId: 'node_start',
        fromPortId: 'completed',
        toNodeId: 'node_condition',
      );

      expect(scene.graph.edges, isEmpty);
      expect(result.createdEdge.id, 'edge_node_start_completed_node_condition');
      expect(result.createdEdge.fromNodeId, 'node_start');
      expect(result.createdEdge.fromPortId, 'completed');
      expect(result.createdEdge.toNodeId, 'node_condition');
      expect(result.createdEdge.kind, SceneEdgeKind.defaultFlow);
      expect(result.createdEdge.label, 'completed');
      expect(result.updatedScene.graph.edges, [result.createdEdge]);
    });

    test('adds condition true and false edges with derived kinds', () {
      var scene = _edgeAuthoringScene();

      final trueEdge = addSceneEdgeDraft(
        scene,
        fromNodeId: 'node_condition',
        fromPortId: 'true',
        toNodeId: 'node_end',
      );
      scene = trueEdge.updatedScene;
      final falseEdge = addSceneEdgeDraft(
        scene,
        fromNodeId: 'node_condition',
        fromPortId: 'false',
        toNodeId: 'node_merge',
        label: ' alternate ',
      );

      expect(trueEdge.createdEdge.kind, SceneEdgeKind.conditionTrue);
      expect(trueEdge.createdEdge.label, 'true');
      expect(falseEdge.createdEdge.kind, SceneEdgeKind.conditionFalse);
      expect(falseEdge.createdEdge.label, 'alternate');
      expect(falseEdge.updatedScene.graph.edges, [
        trueEdge.createdEdge,
        falseEdge.createdEdge,
      ]);
    });

    test('adds a merge completed edge with derived default kind', () {
      final scene = _edgeAuthoringScene();

      final result = addSceneEdgeDraft(
        scene,
        fromNodeId: 'node_merge',
        fromPortId: 'completed',
        toNodeId: 'node_end',
      );

      expect(result.createdEdge.id, 'edge_node_merge_completed_node_end');
      expect(result.createdEdge.kind, SceneEdgeKind.defaultFlow);
      expect(result.createdEdge.label, 'completed');
    });

    test('adds dialogue completed edge with derived default kind', () {
      final scene = _edgeAuthoringSceneWithYarnSource();

      final result = addSceneEdgeDraft(
        scene,
        fromNodeId: 'node_yarn',
        fromPortId: 'completed',
        toNodeId: 'node_end',
      );

      expect(result.createdEdge.id, 'edge_node_yarn_completed_node_end');
      expect(result.createdEdge.kind, SceneEdgeKind.defaultFlow);
      expect(result.createdEdge.label, 'completed');
    });

    test('adds battle victory and defeat edges with derived kinds', () {
      var scene = _edgeAuthoringSceneWithBattleSource();

      final victoryEdge = addSceneEdgeDraft(
        scene,
        fromNodeId: 'node_battle',
        fromPortId: 'victory',
        toNodeId: 'node_end',
      );
      scene = victoryEdge.updatedScene;
      final defeatEdge = addSceneEdgeDraft(
        scene,
        fromNodeId: 'node_battle',
        fromPortId: 'defeat',
        toNodeId: 'node_end_2',
      );

      expect(victoryEdge.createdEdge.kind, SceneEdgeKind.battleVictory);
      expect(victoryEdge.createdEdge.label, 'victory');
      expect(defeatEdge.createdEdge.kind, SceneEdgeKind.battleDefeat);
      expect(defeatEdge.createdEdge.label, 'defeat');
      expect(defeatEdge.updatedScene.graph.edges, [
        victoryEdge.createdEdge,
        defeatEdge.createdEdge,
      ]);
    });

    test('generates suffixed edge ids on collision', () {
      final scene = _edgeAuthoringScene(
        edges: [
          SceneEdge(
            id: 'edge_node_start_completed_node_condition',
            fromNodeId: 'node_condition',
            fromPortId: 'true',
            toNodeId: 'node_end',
            kind: SceneEdgeKind.conditionTrue,
          ),
        ],
      );

      final result = addSceneEdgeDraft(
        scene,
        fromNodeId: 'node_start',
        fromPortId: 'completed',
        toNodeId: 'node_condition',
      );

      expect(
        result.createdEdge.id,
        'edge_node_start_completed_node_condition_2',
      );
    });

    test('preserves scene data and layout while adding an edge', () {
      final existingEdge = SceneEdge(
        id: 'edge_node_condition_true_node_end',
        fromNodeId: 'node_condition',
        fromPortId: 'true',
        toNodeId: 'node_end',
        kind: SceneEdgeKind.conditionTrue,
      );
      final scene = _edgeAuthoringScene(
        metadata: const {'owner': 'test'},
        declaredOutcomes: [SceneOutcome(id: 'done', label: 'Done')],
        edges: [existingEdge],
        edgeLayouts: [
          SceneEdgeLayout(
            edgeId: existingEdge.id,
            controlPoints: [SceneLayoutPoint(x: 20, y: 30)],
          ),
        ],
      );

      final result = addSceneEdgeDraft(
        scene,
        fromNodeId: 'node_start',
        fromPortId: 'completed',
        toNodeId: 'node_condition',
      );

      expect(result.updatedScene.id, scene.id);
      expect(result.updatedScene.name, scene.name);
      expect(result.updatedScene.description, scene.description);
      expect(result.updatedScene.storylineId, scene.storylineId);
      expect(result.updatedScene.chapterId, scene.chapterId);
      expect(result.updatedScene.tags, scene.tags);
      expect(result.updatedScene.metadata, scene.metadata);
      expect(result.updatedScene.declaredOutcomes, scene.declaredOutcomes);
      expect(result.updatedScene.layout, scene.layout);
      expect(result.updatedScene.graph.nodes, scene.graph.nodes);
      expect(result.updatedScene.graph.edges.first, existingEdge);
      expect(scene.graph.edges, [existingEdge]);
    });

    test('removes an edge draft without mutating scene data', () {
      final removedEdge = SceneEdge(
        id: 'edge_node_start_completed_node_condition',
        fromNodeId: 'node_start',
        fromPortId: 'completed',
        toNodeId: 'node_condition',
        kind: SceneEdgeKind.defaultFlow,
      );
      final keptEdge = SceneEdge(
        id: 'edge_node_condition_true_node_end',
        fromNodeId: 'node_condition',
        fromPortId: 'true',
        toNodeId: 'node_end',
        kind: SceneEdgeKind.conditionTrue,
      );
      final scene = _edgeAuthoringScene(
        metadata: const {'owner': 'test'},
        declaredOutcomes: [SceneOutcome(id: 'done', label: 'Done')],
        edges: [removedEdge, keptEdge],
        edgeLayouts: [
          SceneEdgeLayout(
            edgeId: removedEdge.id,
            controlPoints: [SceneLayoutPoint(x: 8, y: 12)],
          ),
          SceneEdgeLayout(
            edgeId: keptEdge.id,
            controlPoints: [SceneLayoutPoint(x: 20, y: 30)],
          ),
        ],
      );

      final result = removeSceneEdgeDraft(scene, removedEdge.id);

      expect(result.removedEdge, removedEdge);
      expect(result.updatedScene.id, scene.id);
      expect(result.updatedScene.name, scene.name);
      expect(result.updatedScene.description, scene.description);
      expect(result.updatedScene.storylineId, scene.storylineId);
      expect(result.updatedScene.chapterId, scene.chapterId);
      expect(result.updatedScene.tags, scene.tags);
      expect(result.updatedScene.metadata, scene.metadata);
      expect(result.updatedScene.declaredOutcomes, scene.declaredOutcomes);
      expect(result.updatedScene.graph.nodes, scene.graph.nodes);
      expect(result.updatedScene.graph.edges, [keptEdge]);
      expect(scene.graph.edges, [removedEdge, keptEdge]);
      expect(
        result.updatedScene.layout.nodeLayouts,
        scene.layout.nodeLayouts,
      );
      expect(
        result.updatedScene.layout.edgeLayouts.map((layout) => layout.edgeId),
        [keptEdge.id],
      );
    });

    test('rejects removing an unknown edge draft', () {
      final scene = _edgeAuthoringScene(
        edges: [
          SceneEdge(
            id: 'edge_node_start_completed_node_condition',
            fromNodeId: 'node_start',
            fromPortId: 'completed',
            toNodeId: 'node_condition',
            kind: SceneEdgeKind.defaultFlow,
          ),
        ],
      );

      expect(
        () => removeSceneEdgeDraft(scene, 'edge_missing'),
        throwsArgumentError,
      );
      expect(scene.graph.edges, hasLength(1));
    });

    test('removes a V0 node draft and its connected edges without mutation',
        () {
      final incomingEdge = SceneEdge(
        id: 'edge_node_start_completed_node_condition',
        fromNodeId: 'node_start',
        fromPortId: 'completed',
        toNodeId: 'node_condition',
        kind: SceneEdgeKind.defaultFlow,
      );
      final outgoingEdge = SceneEdge(
        id: 'edge_node_condition_true_node_end',
        fromNodeId: 'node_condition',
        fromPortId: 'true',
        toNodeId: 'node_end',
        kind: SceneEdgeKind.conditionTrue,
      );
      final keptEdge = SceneEdge(
        id: 'edge_node_merge_completed_node_end',
        fromNodeId: 'node_merge',
        fromPortId: 'completed',
        toNodeId: 'node_end',
        kind: SceneEdgeKind.defaultFlow,
      );
      final scene = _edgeAuthoringScene(
        metadata: const {'owner': 'test'},
        declaredOutcomes: [SceneOutcome(id: 'done', label: 'Done')],
        edges: [incomingEdge, outgoingEdge, keptEdge],
        edgeLayouts: [
          SceneEdgeLayout(
            edgeId: incomingEdge.id,
            controlPoints: [SceneLayoutPoint(x: 8, y: 12)],
          ),
          SceneEdgeLayout(
            edgeId: outgoingEdge.id,
            controlPoints: [SceneLayoutPoint(x: 16, y: 24)],
          ),
          SceneEdgeLayout(
            edgeId: keptEdge.id,
            controlPoints: [SceneLayoutPoint(x: 20, y: 30)],
          ),
        ],
      );

      final result = removeSceneNodeDraft(scene, 'node_condition');

      expect(result.removedNode.id, 'node_condition');
      expect(result.removedEdges, [incomingEdge, outgoingEdge]);
      expect(result.updatedScene.id, scene.id);
      expect(result.updatedScene.name, scene.name);
      expect(result.updatedScene.description, scene.description);
      expect(result.updatedScene.storylineId, scene.storylineId);
      expect(result.updatedScene.chapterId, scene.chapterId);
      expect(result.updatedScene.tags, scene.tags);
      expect(result.updatedScene.metadata, scene.metadata);
      expect(result.updatedScene.declaredOutcomes, scene.declaredOutcomes);
      expect(
        result.updatedScene.graph.nodes.map((node) => node.id),
        ['node_start', 'node_merge', 'node_end'],
      );
      expect(result.updatedScene.graph.edges, [keptEdge]);
      expect(
        result.updatedScene.layout.nodeLayouts.map((layout) => layout.nodeId),
        ['node_start', 'node_merge', 'node_end'],
      );
      expect(
        result.updatedScene.layout.edgeLayouts.map((layout) => layout.edgeId),
        [keptEdge.id],
      );
      expect(scene.graph.nodes.map((node) => node.id), [
        'node_start',
        'node_condition',
        'node_merge',
        'node_end',
      ]);
      expect(scene.graph.edges, [incomingEdge, outgoingEdge, keptEdge]);
    });

    test('rejects removing start and non V0 node drafts', () {
      final scene = _edgeAuthoringSceneWithYarnSource();

      expect(
        () => removeSceneNodeDraft(scene, 'node_start'),
        throwsArgumentError,
      );
      expect(
        () => removeSceneNodeDraft(scene, 'node_yarn'),
        throwsArgumentError,
      );
      expect(
        () => removeSceneNodeDraft(scene, 'node_missing'),
        throwsArgumentError,
      );
      expect(scene.graph.nodes.map((node) => node.id), [
        'node_start',
        'node_yarn',
        'node_end',
      ]);
    });

    test('rejects invalid edge drafts in V0', () {
      final scene = _edgeAuthoringScene(
        edges: [
          SceneEdge(
            id: 'edge_node_start_completed_node_condition',
            fromNodeId: 'node_start',
            fromPortId: 'completed',
            toNodeId: 'node_condition',
            kind: SceneEdgeKind.defaultFlow,
          ),
        ],
      );

      expect(
        () => addSceneEdgeDraft(
          scene,
          fromNodeId: 'node_unknown',
          fromPortId: 'completed',
          toNodeId: 'node_end',
        ),
        throwsArgumentError,
      );
      expect(
        () => addSceneEdgeDraft(
          scene,
          fromNodeId: 'node_start',
          fromPortId: 'completed',
          toNodeId: 'node_unknown',
        ),
        throwsArgumentError,
      );
      expect(
        () => addSceneEdgeDraft(
          scene,
          fromNodeId: 'node_start',
          fromPortId: 'missing',
          toNodeId: 'node_end',
        ),
        throwsArgumentError,
      );
      expect(
        () => addSceneEdgeDraft(
          scene,
          fromNodeId: 'node_end',
          fromPortId: 'completed',
          toNodeId: 'node_merge',
        ),
        throwsArgumentError,
      );
      expect(
        () => addSceneEdgeDraft(
          scene,
          fromNodeId: 'node_condition',
          fromPortId: 'true',
          toNodeId: 'node_condition',
        ),
        throwsArgumentError,
      );
      expect(
        () => addSceneEdgeDraft(
          scene,
          fromNodeId: 'node_start',
          fromPortId: 'completed',
          toNodeId: 'node_end',
        ),
        throwsArgumentError,
      );
      expect(
        () => addSceneEdgeDraft(
          _edgeAuthoringSceneWithYarnSource(),
          fromNodeId: 'node_yarn',
          fromPortId: 'accept',
          toNodeId: 'node_end',
        ),
        throwsArgumentError,
      );
      expect(
        () => addSceneEdgeDraft(
          _edgeAuthoringSceneWithBattleSource(),
          fromNodeId: 'node_battle',
          fromPortId: 'completed',
          toNodeId: 'node_end',
        ),
        throwsArgumentError,
      );
    });

    test('rejects duplicate dialogue and battle source ports', () {
      final dialogueScene = _edgeAuthoringSceneWithYarnSource(
        edges: [
          SceneEdge(
            id: 'edge_node_yarn_completed_node_end',
            fromNodeId: 'node_yarn',
            fromPortId: 'completed',
            toNodeId: 'node_end',
            kind: SceneEdgeKind.defaultFlow,
          ),
        ],
      );
      final battleScene = _edgeAuthoringSceneWithBattleSource(
        edges: [
          SceneEdge(
            id: 'edge_node_battle_victory_node_end',
            fromNodeId: 'node_battle',
            fromPortId: 'victory',
            toNodeId: 'node_end',
            kind: SceneEdgeKind.battleVictory,
          ),
          SceneEdge(
            id: 'edge_node_battle_defeat_node_end_2',
            fromNodeId: 'node_battle',
            fromPortId: 'defeat',
            toNodeId: 'node_end_2',
            kind: SceneEdgeKind.battleDefeat,
          ),
        ],
      );

      expect(
        () => addSceneEdgeDraft(
          dialogueScene,
          fromNodeId: 'node_yarn',
          fromPortId: 'completed',
          toNodeId: 'node_start',
        ),
        throwsArgumentError,
      );
      expect(
        () => addSceneEdgeDraft(
          battleScene,
          fromNodeId: 'node_battle',
          fromPortId: 'victory',
          toNodeId: 'node_start',
        ),
        throwsArgumentError,
      );
      expect(
        () => addSceneEdgeDraft(
          battleScene,
          fromNodeId: 'node_battle',
          fromPortId: 'defeat',
          toNodeId: 'node_start',
        ),
        throwsArgumentError,
      );
    });

    test('updates an existing node layout without mutating graph logic', () {
      final scene = _edgeAuthoringScene(
        metadata: const {'owner': 'test'},
        declaredOutcomes: [SceneOutcome(id: 'done', label: 'Done')],
        edges: [
          SceneEdge(
            id: 'edge_node_start_completed_node_condition',
            fromNodeId: 'node_start',
            fromPortId: 'completed',
            toNodeId: 'node_condition',
            kind: SceneEdgeKind.defaultFlow,
          ),
        ],
      );

      final result = updateSceneNodeLayout(
        scene,
        nodeId: 'node_condition',
        x: 512.5,
        y: 196.25,
      );

      expect(
          scene.layout.nodeLayouts
              .firstWhere((layout) => layout.nodeId == 'node_condition')
              .x,
          324);
      expect(
          result.updatedLayout,
          SceneNodeLayout(
            nodeId: 'node_condition',
            x: 512.5,
            y: 196.25,
          ));
      expect(result.updatedScene.graph.nodes, scene.graph.nodes);
      expect(result.updatedScene.graph.edges, scene.graph.edges);
      expect(result.updatedScene.declaredOutcomes, scene.declaredOutcomes);
      expect(result.updatedScene.metadata, scene.metadata);
      expect(result.updatedScene.tags, scene.tags);
      expect(result.updatedScene.description, scene.description);
      expect(result.updatedScene.storylineId, scene.storylineId);
      expect(result.updatedScene.chapterId, scene.chapterId);
    });

    test('creates a missing node layout and rejects unknown nodes', () {
      final scene = SceneAsset(
        id: 'scene_missing_layout',
        name: 'Missing layout scene',
        graph: SceneGraph(
          startNodeId: 'node_start',
          nodes: [
            SceneNode(id: 'node_start', kind: SceneNodeKind.start),
            SceneNode(id: 'node_end', kind: SceneNodeKind.end),
          ],
          edges: [
            SceneEdge(
              id: 'edge_start_end',
              fromNodeId: 'node_start',
              fromPortId: 'completed',
              toNodeId: 'node_end',
              kind: SceneEdgeKind.defaultFlow,
            ),
          ],
        ),
        layout: SceneGraphLayout(
          nodeLayouts: [
            SceneNodeLayout(nodeId: 'node_start', x: 24, y: 80),
          ],
        ),
      );

      final result = updateSceneNodeLayout(
        scene,
        nodeId: 'node_end',
        x: 420.75,
        y: -16.5,
      );

      expect(scene.layout.nodeLayouts.map((layout) => layout.nodeId),
          ['node_start']);
      expect(
          result.updatedScene.layout.nodeLayouts.map((layout) => layout.nodeId),
          ['node_start', 'node_end']);
      expect(result.updatedLayout.x, 420.75);
      expect(result.updatedLayout.y, -16.5);
      expect(result.updatedScene.graph.nodes, scene.graph.nodes);
      expect(result.updatedScene.graph.edges, scene.graph.edges);
      expect(
        () => updateSceneNodeLayout(
          scene,
          nodeId: 'node_unknown',
          x: 1,
          y: 2,
        ),
        throwsArgumentError,
      );
    });

    test('updates a condition node with a fact-like story flag source', () {
      final scene = _edgeAuthoringScene(
        metadata: const {'owner': 'test'},
        declaredOutcomes: [SceneOutcome(id: 'done', label: 'Done')],
        edges: [
          SceneEdge(
            id: 'edge_node_start_completed_node_condition',
            fromNodeId: 'node_start',
            fromPortId: 'completed',
            toNodeId: 'node_condition',
            kind: SceneEdgeKind.defaultFlow,
          ),
        ],
      );
      final source = SceneConditionSource(
        sourceKind: SceneConditionSourceKind.factLikeStoryFlag,
        sourceId: 'story_flag.harbor_fog_seen',
        operator: SceneConditionOperator.isTrue,
        label: 'Le joueur a vu la brume',
        debugTechnicalLabel: 'story_flag.harbor_fog_seen',
      );

      final result = updateSceneConditionSource(
        scene,
        nodeId: 'node_condition',
        source: source,
      );

      final payload = result.updatedPayload;
      expect(payload.conditionSource, source);
      expect(payload.conditionLabel, 'Le joueur a vu la brume');
      expect(payload.conditionRef, 'story_flag.harbor_fog_seen');
      expect(payload.conditionDraft, isNull);
      expect(result.updatedNode.id, 'node_condition');
      expect(result.updatedScene.graph.edges, scene.graph.edges);
      expect(result.updatedScene.layout, scene.layout);
      expect(result.updatedScene.declaredOutcomes, scene.declaredOutcomes);
      expect(result.updatedScene.metadata, scene.metadata);
      expect(
          scene.graph.nodes
              .firstWhere((node) => node.id == 'node_condition')
              .payload,
          isA<SceneConditionPayload>());
    });

    test('updates a condition node with a story step completion source', () {
      final scene = _edgeAuthoringScene();

      final result = updateSceneConditionSource(
        scene,
        nodeId: 'node_condition',
        source: SceneConditionSource(
          sourceKind: SceneConditionSourceKind.storyStepCompletion,
          sourceId: 'step_intro_completed',
          operator: SceneConditionOperator.equals,
          value: SceneConditionValues.completed,
          label: 'Introduction terminée',
          debugTechnicalLabel: 'step_intro_completed',
        ),
      );

      final source = result.updatedPayload.conditionSource!;
      expect(source.sourceKind, SceneConditionSourceKind.storyStepCompletion);
      expect(source.sourceId, 'step_intro_completed');
      expect(source.operator, SceneConditionOperator.equals);
      expect(source.value, SceneConditionValues.completed);
      expect(result.updatedScene.graph.nodes, isNot(scene.graph.nodes));
      expect(
          scene.graph.nodes
              .firstWhere((node) => node.id == 'node_condition')
              .payload,
          equals(SceneConditionPayload()));
    });

    test('rejects invalid condition source updates', () {
      final scene = _edgeAuthoringScene();

      expect(
        () => updateSceneConditionSource(
          scene,
          nodeId: 'node_start',
          source: SceneConditionSource(
            sourceKind: SceneConditionSourceKind.factLikeStoryFlag,
            sourceId: 'flag_seen',
            operator: SceneConditionOperator.isTrue,
          ),
        ),
        throwsArgumentError,
      );
      expect(
        () => updateSceneConditionSource(
          scene,
          nodeId: 'node_condition',
          source: SceneConditionSource(
            sourceKind: SceneConditionSourceKind.inventoryItem,
            sourceId: 'item_potion',
            operator: SceneConditionOperator.isTrue,
          ),
        ),
        throwsArgumentError,
      );
      expect(
        () => updateSceneConditionSource(
          scene,
          nodeId: 'node_condition',
          source: SceneConditionSource(
            sourceKind: SceneConditionSourceKind.storyStepCompletion,
            sourceId: 'step_intro_completed',
            operator: SceneConditionOperator.isTrue,
          ),
        ),
        throwsArgumentError,
      );
      expect(
        () => updateSceneConditionSource(
          scene,
          nodeId: 'node_condition',
          source: SceneConditionSource(
            sourceKind: SceneConditionSourceKind.consumedEvent,
            sourceId: 'event_intro',
            operator: SceneConditionOperator.equals,
            value: 'consumed',
          ),
        ),
        throwsArgumentError,
      );
    });
  });
}

ProjectManifest _project({
  List<SceneAsset> scenes = const [],
  List<ScenarioAsset> scenarios = const [],
  List<StorylineAsset> storylines = const [],
}) {
  return ProjectManifest(
    name: 'Scene authoring test',
    maps: const [],
    tilesets: const [],
    scenes: scenes,
    scenarios: scenarios,
    storylines: storylines,
  );
}

SceneAsset _scene(
  String id, {
  Map<String, String> metadata = const {},
  List<SceneOutcome> declaredOutcomes = const [],
}) {
  return SceneAsset(
    id: id,
    name: id,
    tags: const ['test'],
    graph: SceneGraph(
      startNodeId: 'node_start',
      nodes: [
        SceneNode(id: 'node_start', kind: SceneNodeKind.start),
        SceneNode(id: 'node_end', kind: SceneNodeKind.end),
      ],
      edges: [
        SceneEdge(
          id: 'edge_start_end',
          fromNodeId: 'node_start',
          fromPortId: 'completed',
          toNodeId: 'node_end',
          kind: SceneEdgeKind.defaultFlow,
        ),
      ],
    ),
    layout: SceneGraphLayout(
      nodeLayouts: [
        SceneNodeLayout(nodeId: 'node_start', x: 24, y: 80),
        SceneNodeLayout(nodeId: 'node_end', x: 320, y: 80),
      ],
    ),
    declaredOutcomes: declaredOutcomes,
    metadata: metadata,
  );
}

SceneAsset _edgeAuthoringScene({
  Map<String, String> metadata = const {},
  List<SceneOutcome> declaredOutcomes = const [],
  List<SceneEdge> edges = const [],
  List<SceneEdgeLayout> edgeLayouts = const [],
}) {
  return SceneAsset(
    id: 'scene_edge_authoring',
    name: 'Edge Authoring Scene',
    description: 'Scene for edge authoring tests.',
    storylineId: 'storyline_test',
    chapterId: 'chapter_test',
    tags: const ['test'],
    graph: SceneGraph(
      startNodeId: 'node_start',
      nodes: [
        SceneNode(id: 'node_start', kind: SceneNodeKind.start),
        SceneNode(id: 'node_condition', kind: SceneNodeKind.condition),
        SceneNode(id: 'node_merge', kind: SceneNodeKind.merge),
        SceneNode(id: 'node_end', kind: SceneNodeKind.end),
      ],
      edges: edges,
    ),
    layout: SceneGraphLayout(
      nodeLayouts: [
        SceneNodeLayout(nodeId: 'node_start', x: 24, y: 80),
        SceneNodeLayout(nodeId: 'node_condition', x: 324, y: 80),
        SceneNodeLayout(nodeId: 'node_merge', x: 624, y: 80),
        SceneNodeLayout(nodeId: 'node_end', x: 924, y: 80),
      ],
      edgeLayouts: edgeLayouts,
    ),
    declaredOutcomes: declaredOutcomes,
    metadata: metadata,
  );
}

SceneAsset _edgeAuthoringSceneWithYarnSource({
  List<SceneEdge> edges = const [],
}) {
  return SceneAsset(
    id: 'scene_edge_authoring_yarn',
    name: 'Edge Authoring Yarn Source',
    graph: SceneGraph(
      startNodeId: 'node_start',
      nodes: [
        SceneNode(id: 'node_start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'node_yarn',
          kind: SceneNodeKind.yarnDialogue,
          payload: SceneYarnDialoguePayload(
            dialogueId: 'dialogue_test',
            expectedOutcomes: const ['accept'],
          ),
        ),
        SceneNode(id: 'node_end', kind: SceneNodeKind.end),
      ],
      edges: edges,
    ),
    layout: SceneGraphLayout(
      nodeLayouts: [
        SceneNodeLayout(nodeId: 'node_start', x: 24, y: 80),
        SceneNodeLayout(nodeId: 'node_yarn', x: 324, y: 80),
        SceneNodeLayout(nodeId: 'node_end', x: 624, y: 80),
      ],
    ),
  );
}

SceneAsset _edgeAuthoringSceneWithBattleSource({
  List<SceneEdge> edges = const [],
}) {
  return SceneAsset(
    id: 'scene_edge_authoring_battle',
    name: 'Edge Authoring Battle Source',
    graph: SceneGraph(
      startNodeId: 'node_start',
      nodes: [
        SceneNode(id: 'node_start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'node_battle',
          kind: SceneNodeKind.battle,
          payload: SceneBattlePayload(
            battleKind: 'trainer',
            trainerId: 'trainer_test',
            declaredOutcomes: const ['victory', 'defeat'],
          ),
        ),
        SceneNode(id: 'node_end', kind: SceneNodeKind.end),
        SceneNode(id: 'node_end_2', kind: SceneNodeKind.end),
      ],
      edges: edges,
    ),
    layout: SceneGraphLayout(
      nodeLayouts: [
        SceneNodeLayout(nodeId: 'node_start', x: 24, y: 80),
        SceneNodeLayout(nodeId: 'node_battle', x: 324, y: 80),
        SceneNodeLayout(nodeId: 'node_end', x: 624, y: 40),
        SceneNodeLayout(nodeId: 'node_end_2', x: 624, y: 160),
      ],
    ),
  );
}
