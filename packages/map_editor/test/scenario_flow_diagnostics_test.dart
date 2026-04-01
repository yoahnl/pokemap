import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/scenario/scenario_flow_diagnostics.dart';

void main() {
  group('scenario_flow_diagnostics', () {
    test('reports unreachable and incomplete nodes', () {
      const scenario = ScenarioAsset(
        id: 'main',
        name: 'Main',
        entryNodeId: 'start',
        nodes: <ScenarioNode>[
          ScenarioNode(id: 'start', type: ScenarioNodeType.start),
          ScenarioNode(id: 'dialogue', type: ScenarioNodeType.dialogue),
          ScenarioNode(id: 'end', type: ScenarioNodeType.end),
          ScenarioNode(id: 'action', type: ScenarioNodeType.action),
        ],
        edges: <ScenarioEdge>[
          ScenarioEdge(
              id: 'start_to_dialogue',
              fromNodeId: 'start',
              toNodeId: 'dialogue'),
        ],
      );

      final report = analyzeScenarioFlow(scenario);
      expect(report.summary.unreachableNodes, greaterThanOrEqualTo(1));
      expect(report.summary.incompleteNodes, greaterThanOrEqualTo(1));
      expect(
        report.issues.any((issue) => issue.code == 'node_incomplete'),
        isTrue,
      );
      expect(
        report.issues.any((issue) => issue.code == 'unreachable_node'),
        isTrue,
      );
    });

    test('flags condition node with too few branches', () {
      const scenario = ScenarioAsset(
        id: 'branching',
        name: 'Branching',
        entryNodeId: 'start',
        nodes: <ScenarioNode>[
          ScenarioNode(id: 'start', type: ScenarioNodeType.start),
          ScenarioNode(
            id: 'condition',
            type: ScenarioNodeType.condition,
            payload: ScenarioNodePayload(
              condition: ScriptCondition(
                type: ScriptConditionType.flagIsSet,
                params: <String, String>{
                  ScriptConditionParams.flagName: 'story.ready'
                },
              ),
            ),
          ),
          ScenarioNode(id: 'end', type: ScenarioNodeType.end),
        ],
        edges: <ScenarioEdge>[
          ScenarioEdge(
              id: 's_to_c', fromNodeId: 'start', toNodeId: 'condition'),
          ScenarioEdge(id: 'c_to_e', fromNodeId: 'condition', toNodeId: 'end'),
        ],
      );

      final report = analyzeScenarioFlow(scenario);
      expect(
        report.issues
            .any((issue) => issue.code == 'condition_missing_branches'),
        isTrue,
      );
    });

    test('runtime summary distinguishes capability from connection', () {
      const scenario = ScenarioAsset(
        id: 'runtime',
        name: 'Runtime',
        entryNodeId: 'start',
        nodes: <ScenarioNode>[
          ScenarioNode(id: 'start', type: ScenarioNodeType.start),
          ScenarioNode(
            id: 'action',
            type: ScenarioNodeType.action,
            payload: ScenarioNodePayload(actionKind: 'openDialogue'),
            binding: ScenarioNodeBinding(dialogueId: 'dialogue_intro'),
          ),
          ScenarioNode(id: 'end', type: ScenarioNodeType.end),
        ],
        edges: <ScenarioEdge>[
          ScenarioEdge(id: 's_to_a', fromNodeId: 'start', toNodeId: 'action'),
          ScenarioEdge(id: 'a_to_e', fromNodeId: 'action', toNodeId: 'end'),
        ],
      );

      final report = analyzeScenarioFlow(
        scenario,
        graphRuntimeConnected: false,
      );
      expect(report.summary.runtimeConnectedNodes, 0);
      expect(report.summary.runtimeCapableNodes, greaterThanOrEqualTo(1));
      expect(report.summary.authoringBridgeNodes, greaterThanOrEqualTo(1));
    });
  });
}
