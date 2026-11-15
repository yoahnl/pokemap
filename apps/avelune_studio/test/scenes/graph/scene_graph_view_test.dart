import 'package:avelune_studio/features/scenes/application/graph/scene_graph_layout.dart';
import 'package:avelune_studio/features/scenes/application/graph/scene_graph_metrics.dart';
import 'package:avelune_studio/features/scenes/application/graph/scene_graph_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../steps/scene_step_fixtures.dart';

SceneAsset _unplaced(List<SceneNode> nodes, List<SceneEdge> edges) =>
    SceneAsset(id: 'scene', name: 'Scene', graph: graphOf(nodes, edges));

SceneEdge _battleLink(String from, String to, String port) => SceneEdge(
  id: '$from.$port',
  fromNodeId: from,
  fromPortId: port,
  toNodeId: to,
  kind: port == 'victory'
      ? SceneEdgeKind.battleVictory
      : SceneEdgeKind.battleDefeat,
);

SceneEdge _choice(String from, String to, String outcome) => SceneEdge(
  id: '$from.$outcome',
  fromNodeId: from,
  fromPortId: outcome,
  toNodeId: to,
  kind: SceneEdgeKind.dialogueOutcome,
);

List<String> _ports(SceneGraphView view, String nodeId) => [
  for (final port in view.card(nodeId)!.outputs) port.id,
];

void main() {
  test('every node shows the exits the engine declares, linked or not', () {
    final view = projectSceneGraph(
      _unplaced(
        [
          startNode(),
          dialogueNode('ask', ['yes', 'no']),
          conditionNode('check'),
          battleNode('fight'),
          endNode('end'),
        ],
        [
          link('start', 'ask'),
          _choice('ask', 'fight', 'yes'),
          _choice('ask', 'check', 'no'),
          _battleLink('fight', 'end', 'victory'),
          link('check', 'end', port: 'true'),
        ],
      ),
    );

    expect(_ports(view, 'start'), ['completed']);
    expect(_ports(view, 'ask'), ['completed', 'yes', 'no']);
    expect(_ports(view, 'check'), ['true', 'false']);
    expect(_ports(view, 'fight'), ['victory', 'defeat']);
    expect(_ports(view, 'end'), isEmpty);
    final fight = view.card('fight')!.outputs;
    expect(fight.firstWhere((p) => p.id == 'victory').connected, isTrue);
    expect(fight.firstWhere((p) => p.id == 'defeat').connected, isFalse);
    expect(view.card('start')!.acceptsInput, isFalse);
    expect(view.card('end')!.acceptsInput, isTrue);
    expect(view.card('ask')!.family, SceneGraphFamily.dialogue);
    expect(view.card('fight')!.family, SceneGraphFamily.battle);
    expect(view.wires.map((wire) => wire.id), hasLength(5));
    expect(view.wires.every((wire) => wire.declared && !wire.loop), isTrue);
  });

  test(
    'a link from an exit the engine does not declare stays visible and flagged',
    () {
      final view = projectSceneGraph(
        _unplaced(
          [startNode(), conditionNode('check'), endNode('end')],
          [link('start', 'check'), link('check', 'end', port: 'maybe')],
        ),
      );

      final port = view.card('check')!.outputs.last;
      expect(port.id, 'maybe');
      expect(port.declared, isFalse);
      expect(
        view.wires.singleWhere((w) => w.id == 'check.maybe').declared,
        isFalse,
      );
    },
  );

  test('scenes without stored positions are laid out left to right', () {
    final view = projectSceneGraph(
      _unplaced(
        [endNode('lost'), battleNode('fight'), endNode('won'), startNode()],
        [
          link('start', 'fight'),
          _battleLink('fight', 'won', 'victory'),
          _battleLink('fight', 'lost', 'defeat'),
        ],
      ),
    );

    final start = view.card('start')!.position;
    final fight = view.card('fight')!.position;
    final won = view.card('won')!.position;
    final lost = view.card('lost')!.position;
    expect(start.x, 0);
    expect(fight.x, greaterThan(start.x));
    expect(
      won.x,
      fight.x + SceneGraphMetrics.cardWidth + SceneGraphMetrics.columnGap,
    );
    expect(lost.x, won.x);
    expect(won.y, lessThan(lost.y), reason: 'victory is the first exit');
    expect(lost.y - won.y, greaterThanOrEqualTo(view.card('won')!.height));
    expect(view.needsLayoutSave, isTrue);
  });

  test(
    'stored positions are kept and only missing cards are placed below them',
    () {
      final scene = SceneAsset(
        id: 'scene',
        name: 'Scene',
        graph: graphOf(
          [startNode(), factNode('remember'), endNode('end')],
          [link('start', 'remember'), link('remember', 'end')],
        ),
        layout: SceneGraphLayout(
          nodeLayouts: [
            SceneNodeLayout(nodeId: 'start', x: 40, y: 500),
            SceneNodeLayout(nodeId: 'remember', x: 300, y: 520),
          ],
        ),
      );

      final view = projectSceneGraph(scene);

      expect(view.card('start')!.position, const SceneGraphPoint(40, 500));
      expect(view.card('remember')!.position, const SceneGraphPoint(300, 520));
      final end = view.card('end')!;
      expect(end.storedPosition, isFalse);
      expect(end.position.y, greaterThan(520 + view.card('remember')!.height));
      expect(view.card('start')!.storedPosition, isTrue);
    },
  );

  test(
    'a loop is reported on the wire that goes back and layout still ends',
    () {
      final view = projectSceneGraph(
        _unplaced(
          [startNode(), waitNode('a'), waitNode('b'), endNode('end')],
          [
            link('start', 'a'),
            link('a', 'b'),
            SceneEdge(
              id: 'back',
              fromNodeId: 'b',
              fromPortId: 'completed',
              toNodeId: 'a',
              kind: SceneEdgeKind.actionCompleted,
            ),
          ],
        ),
      );

      expect(view.hasLoop, isTrue);
      expect(view.wires.where((w) => w.loop).map((w) => w.id), ['back']);
      expect(
        view.card('b')!.position.x,
        greaterThan(view.card('a')!.position.x),
      );
      expect(view.unreachableNodeIds, {'end'});
    },
  );

  test('two paths into the same step put it after the longest one', () {
    final view = projectSceneGraph(
      _unplaced(
        [startNode(), conditionNode('check'), waitNode('wait'), endNode('end')],
        [
          link('start', 'check'),
          link('check', 'wait', port: 'true'),
          link('wait', 'end'),
          link('check', 'end', port: 'false'),
        ],
      ),
    );

    expect(
      view.card('end')!.position.x,
      greaterThan(view.card('wait')!.position.x),
    );
    final columns = <double, List<SceneGraphCard>>{};
    for (final card in view.cards) {
      columns.putIfAbsent(card.position.x, () => []).add(card);
    }
    for (final column in columns.values) {
      column.sort((a, b) => a.position.y.compareTo(b.position.y));
      for (var i = 1; i < column.length; i++) {
        expect(
          column[i].position.y,
          greaterThanOrEqualTo(column[i - 1].position.y + column[i - 1].height),
        );
      }
    }
  });
}
