import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('SceneAsset JSON roundtrip', () {
    test('round-trips a complete V0 authoring shape', () {
      final scene = _completeScene();

      final json =
          jsonDecode(jsonEncode(scene.toJson())) as Map<String, dynamic>;
      final decoded = SceneAsset.fromJson(json);

      expect(decoded, equals(scene));
      expect(json['graph'], isA<Map<String, dynamic>>());
      expect(json['layout'], isA<Map<String, dynamic>>());
      expect(json['declaredOutcomes'], isA<List<dynamic>>());
      expect(json['metadata'], isA<Map<String, dynamic>>());
    });

    test('serializes enums as stable strings', () {
      final json = _completeScene().toJson();
      final graph = json['graph'] as Map<String, dynamic>;
      final nodes = graph['nodes'] as List<dynamic>;
      final edges = graph['edges'] as List<dynamic>;

      final start = nodes.first as Map<String, dynamic>;
      final firstEdge = edges.first as Map<String, dynamic>;

      expect(start['kind'], 'start');
      expect(firstEdge['kind'], 'default');
      expect(start['kind'], isNot(isA<int>()));
      expect(firstEdge['kind'], isNot(isA<int>()));
    });

    test('round-trips all minimal payload kinds', () {
      final payloads = <SceneNodePayload>[
        SceneStartPayload(notes: 'Entry point'),
        SceneEndPayload(sceneOutcomeId: 'scene_done'),
        SceneYarnDialoguePayload(
          dialogueId: 'dialogue_intro',
          yarnNodeName: 'Start',
          expectedOutcomes: const ['reassure', 'panic'],
          speakerHints: const ['npc_mayor'],
        ),
        SceneConditionPayload(
          conditionLabel: 'Has seen the lighthouse',
          conditionRef: 'condition_seen_lighthouse',
        ),
        SceneActionPayload(
          actionKind: 'setFlag',
          parameters: {'flagId': 'saw_lighthouse'},
        ),
        SceneActionPayload.consequence(
          SceneConsequence.setFact(
            factId: 'fact_test_gate_unlocked',
            value: true,
            label: 'Unlock test gate',
          ),
        ),
        SceneBattlePayload(
          battleKind: 'trainer',
          trainerId: 'trainer_rival',
          declaredOutcomes: const ['victory', 'defeat'],
        ),
        SceneCinematicPayload(cinematicId: 'cinematic_fog_lifts'),
        SceneBranchByOutcomePayload(
          sourceNodeId: 'node_dialogue',
          sourceOutcomeSetRef: 'dialogue_intro',
          fallbackPolicy: 'blocked',
        ),
        SceneMergePayload(label: 'Return to main flow'),
      ];

      for (final payload in payloads) {
        final decoded = SceneNodePayload.fromJson(payload.toJson());

        expect(decoded, equals(payload));
      }
    });

    test('round-trips layout nodes and edge control points', () {
      final layout = SceneGraphLayout(
        nodeLayouts: [
          SceneNodeLayout(nodeId: 'node_start', x: 0, y: 0),
        ],
        edgeLayouts: [
          SceneEdgeLayout(
            edgeId: 'edge_start_dialogue',
            controlPoints: [
              SceneLayoutPoint(x: 120, y: 32),
              SceneLayoutPoint(x: 240, y: 32),
            ],
          ),
        ],
      );

      expect(SceneGraphLayout.fromJson(layout.toJson()), equals(layout));
    });

    test('round-trips structured condition source payload', () {
      final payload = SceneConditionPayload(
        conditionSource: SceneConditionSource(
          sourceKind: SceneConditionSourceKind.storyStepCompletion,
          sourceId: 'step_intro_completed',
          field: 'completion',
          operator: SceneConditionOperator.equals,
          value: SceneConditionValues.completed,
          label: 'Introduction terminée',
          debugTechnicalLabel: 'step_intro_completed',
        ),
      );

      final json = payload.toJson();
      final conditionSource = json['conditionSource'] as Map<String, dynamic>;
      final decoded = SceneNodePayload.fromJson(json);

      expect(conditionSource['sourceKind'], 'storyStepCompletion');
      expect(conditionSource['sourceId'], 'step_intro_completed');
      expect(conditionSource['field'], 'completion');
      expect(conditionSource['operator'], 'equals');
      expect(conditionSource['value'], 'completed');
      expect(conditionSource['label'], 'Introduction terminée');
      expect(conditionSource['debugTechnicalLabel'], 'step_intro_completed');
      expect(decoded, equals(payload));
    });

    test('round-trips Fact Registry condition source payload', () {
      final payload = SceneConditionPayload(
        conditionLabel: 'Brume vue au port',
        conditionRef: 'fact_harbor_fog_seen',
        conditionSource: SceneConditionSource(
          sourceKind: SceneConditionSourceKind.fact,
          sourceId: 'fact_harbor_fog_seen',
          operator: SceneConditionOperator.isTrue,
          label: 'Brume vue au port',
          debugTechnicalLabel: 'story_flag.harbor_fog_seen',
        ),
      );

      final json = payload.toJson();
      final conditionSource = json['conditionSource'] as Map<String, dynamic>;
      final decoded = SceneNodePayload.fromJson(json);

      expect(conditionSource['sourceKind'], 'fact');
      expect(conditionSource['sourceId'], 'fact_harbor_fog_seen');
      expect(decoded, equals(payload));
    });
  });

  group('SceneAsset JSON defaults and invalid shapes', () {
    test('decodes stable defaults from minimal JSON', () {
      final decoded = SceneAsset.fromJson({
        'id': 'scene',
        'name': 'Scene',
        'graph': _minimalGraphJson(),
      });

      expect(decoded.description, isNull);
      expect(decoded.tags, isEmpty);
      expect(decoded.layout, equals(SceneGraphLayout()));
      expect(decoded.declaredOutcomes, isEmpty);
      expect(decoded.metadata, isEmpty);
    });

    test('rejects unknown enum and invalid payload shapes', () {
      expect(
        () => SceneNode.fromJson({
          'id': 'node',
          'kind': 'dialogue',
        }),
        _throws,
      );
      expect(
        () => SceneEdge.fromJson({
          'id': 'edge',
          'fromNodeId': 'from',
          'fromPortId': 'completed',
          'toNodeId': 'to',
          'kind': 'unknown',
        }),
        _throws,
      );
      expect(
        () => SceneNodePayload.fromJson({
          'kind': 'yarnDialogue',
        }),
        _throws,
      );
      expect(
        () => SceneNodePayload.fromJson({
          'kind': 'action',
          'actionKind': 'setFlag',
          'parameters': {'flag': 1},
        }),
        _throws,
      );
    });
  });
}

final Matcher _throws = throwsA(
  anyOf(isA<FormatException>(), isA<ValidationException>()),
);

SceneAsset _completeScene() {
  return SceneAsset(
    id: 'scene_intro',
    name: 'Intro scene',
    description: 'Scene graph with every V0 node kind.',
    storylineId: 'story_main',
    chapterId: 'chapter_1',
    tags: const ['demo', 'draft'],
    graph: SceneGraph(
      startNodeId: 'node_start',
      nodes: [
        SceneNode(
          id: 'node_start',
          kind: SceneNodeKind.start,
          title: 'Start',
          payload: SceneStartPayload(notes: 'Entry'),
        ),
        SceneNode(
          id: 'node_dialogue',
          kind: SceneNodeKind.yarnDialogue,
          title: 'Talk',
          payload: SceneYarnDialoguePayload(
            dialogueId: 'dialogue_intro',
            yarnNodeName: 'Start',
            expectedOutcomes: const ['reassure', 'panic'],
          ),
        ),
        SceneNode(
          id: 'node_branch',
          kind: SceneNodeKind.branchByOutcome,
          title: 'Branch',
          payload: SceneBranchByOutcomePayload(sourceNodeId: 'node_dialogue'),
        ),
        SceneNode(
          id: 'node_condition',
          kind: SceneNodeKind.condition,
          title: 'Check',
          payload: SceneConditionPayload(conditionRef: 'condition_has_badge'),
        ),
        SceneNode(
          id: 'node_action',
          kind: SceneNodeKind.action,
          title: 'Set flag',
          payload: SceneActionPayload(actionKind: 'setFlag'),
        ),
        SceneNode(
          id: 'node_battle',
          kind: SceneNodeKind.battle,
          title: 'Battle',
          payload: SceneBattlePayload(
            battleKind: 'trainer',
            trainerId: 'trainer_rival',
            declaredOutcomes: ['victory', 'defeat'],
          ),
        ),
        SceneNode(
          id: 'node_cinematic',
          kind: SceneNodeKind.cinematic,
          title: 'Cinematic',
          payload: SceneCinematicPayload(cinematicId: 'cinematic_intro'),
        ),
        SceneNode(
          id: 'node_merge',
          kind: SceneNodeKind.merge,
          title: 'Merge',
          payload: SceneMergePayload(label: 'Continue'),
        ),
        SceneNode(
          id: 'node_end',
          kind: SceneNodeKind.end,
          title: 'End',
          payload: SceneEndPayload(sceneOutcomeId: 'scene_done'),
        ),
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
          id: 'edge_dialogue_branch',
          fromNodeId: 'node_dialogue',
          fromPortId: 'outcome:reassure',
          toNodeId: 'node_branch',
          kind: SceneEdgeKind.dialogueOutcome,
          label: 'Reassure',
        ),
        SceneEdge(
          id: 'edge_condition_true',
          fromNodeId: 'node_condition',
          fromPortId: 'true',
          toNodeId: 'node_action',
          kind: SceneEdgeKind.conditionTrue,
        ),
      ],
    ),
    layout: SceneGraphLayout(
      nodeLayouts: [
        SceneNodeLayout(nodeId: 'node_start', x: 0, y: 0),
        SceneNodeLayout(nodeId: 'node_dialogue', x: 240, y: 0),
      ],
    ),
    declaredOutcomes: [
      SceneOutcome(
        id: 'scene_done',
        label: 'Scene completed',
        description: 'The scene reached a clean end.',
      ),
    ],
    metadata: const {'source': 'unit_test'},
  );
}

Map<String, dynamic> _minimalGraphJson() {
  return {
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
}
