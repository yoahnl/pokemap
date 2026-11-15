import 'package:avelune_studio/features/scenes/application/graph/scene_graph_checks.dart';
import 'package:avelune_studio/features/scenes/application/graph/scene_graph_edits.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../steps/scene_step_fixtures.dart';

SceneAsset _unplaced(List<SceneNode> nodes, List<SceneEdge> edges) =>
    SceneAsset(id: 'scene', name: 'Scene', graph: graphOf(nodes, edges));

void main() {
  test('a sound scene has no problem, even without stored positions', () {
    final checks = checkSceneGraph(
      _unplaced(
        [startNode(), waitNode('wait'), endNode('end')],
        [link('start', 'wait'), link('wait', 'end')],
      ),
    );

    expect(checks.problems, isEmpty);
    expect(checks.blocking, isFalse);
  });

  test('an unlinked required exit and an isolated step are warnings on '
      'their step; no reachable end blocks', () {
    final checks = checkSceneGraph(
      _unplaced(
        [
          startNode(),
          conditionNode('check'),
          waitNode('alone'),
          endNode('end'),
        ],
        [link('start', 'check'), link('alone', 'end')],
      ),
    );

    expect(
      checks.ofNode('check').map((p) => (p.code, p.level)),
      contains((
        SceneDiagnosticCode.requiredOutputPortMissing,
        SceneGraphProblemLevel.warning,
      )),
    );
    expect(
      checks.ofNode('alone').map((p) => p.code),
      contains(SceneDiagnosticCode.unreachableNode),
    );
    expect(checks.levelOfNode('alone'), SceneGraphProblemLevel.warning);
    expect(checks.blocking, isTrue);
    expect(checks.problems.every((p) => p.message.isNotEmpty), isTrue);
  });

  test('editing a step keeps its links and refuses a kind change', () {
    final scene = _unplaced(
      [startNode(), conditionNode('check'), endNode('end')],
      [
        link('start', 'check'),
        link('check', 'end', port: 'true'),
        link('check', 'end', port: 'false'),
      ],
    );
    final renamed = SceneNode(
      id: 'check',
      kind: SceneNodeKind.condition,
      title: 'Lundi ?',
      payload: weekdayCondition(),
    );

    final edited =
        (editSceneGraphStep(scene, renamed) as SceneGraphEdited).scene;

    expect(edited.graph.nodes[1], renamed);
    expect(edited.graph.edges, scene.graph.edges);
    expect(
      (editSceneGraphStep(
        scene,
        waitNode('check'),
      ) as SceneGraphEditRefused).reason,
      SceneGraphEditRefusal.invalid,
    );
  });
}
