import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/scenes/application/graph/scene_graph_view.dart';

import 'scene_graph_canvas_harness.dart';

void main() {
  testWidgets('dragging an exit onto a step links them', (tester) async {
    final host = await pumpGraph(tester);

    await dragGraph(
      tester,
      graphExit(tester, 'check', 'false'),
      graphCentre(tester, 'end'),
    );

    expect(edgeFrom(host.scene, 'check', 'false')?.toNodeId, 'end');
    expect(graphKey('scene-graph-draft-wire'), findsNothing);
  });

  testWidgets('dropping a link in the void opens the search and adds the '
      'chosen step there, linked and selected', (tester) async {
    final host = await pumpGraph(tester);
    final drop = graphVoid(tester);

    await dragGraph(tester, graphExit(tester, 'check', 'false'), drop);
    expect(graphKey('scene-graph-step-menu'), findsOneWidget);
    await tester.enterText(graphKey('scene-graph-step-search'), 'fin');
    await tester.pump();
    expect(graphKey('scene-graph-step-new-talk'), findsNothing);
    await tester.tap(graphKey('scene-graph-step-new-end'));
    await tester.pumpAndSettle();

    expect(graphKey('scene-graph-step-menu'), findsNothing);
    final created = edgeFrom(host.scene, 'check', 'false')!.toNodeId;
    final node = host.scene.graph.nodes.singleWhere((n) => n.id == created);
    expect(node.kind, SceneNodeKind.end);
    expect(graphCanvas.currentState!.selection, {created});
    final placed = host.scene.layout.nodeLayouts.singleWhere(
      (layout) => layout.nodeId == created,
    );
    final canvas = tester.getTopLeft(graphKey('scene-graph-canvas'));
    final world = graphCanvas.currentState!.camera!.toWorld(drop - canvas);
    expect((placed.x - world.dx).abs(), lessThanOrEqualTo(8));
    expect((placed.y - world.dy).abs(), lessThanOrEqualTo(8));
  });

  testWidgets('dragging cards moves the selection on the grid and stores '
      'every card place', (tester) async {
    final host = await pumpGraph(tester);
    final before = {
      for (final card in projectSceneGraph(graphInitial).cards)
        card.id: card.position,
    };

    await tester.tapAt(
      graphCentre(tester, 'wait'),
      kind: PointerDeviceKind.mouse,
    );
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.tapAt(
      graphCentre(tester, 'end'),
      kind: PointerDeviceKind.mouse,
    );
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
    final scale = graphCanvas.currentState!.camera!.scale;
    await dragGraph(
      tester,
      graphCentre(tester, 'wait'),
      graphCentre(tester, 'wait') + Offset(80 * scale, 50 * scale),
    );

    expect(host.edits, 1);
    final stored = {
      for (final layout in host.scene.layout.nodeLayouts)
        layout.nodeId: (layout.x, layout.y),
    };
    expect(stored.keys.toSet(), {'start', 'check', 'wait', 'end'});
    for (final id in ['wait', 'end']) {
      final (x, y) = stored[id]!;
      expect(x % 16, 0, reason: id);
      expect(y % 16, 0, reason: id);
      expect((x - before[id]!.x - 80).abs(), lessThanOrEqualTo(8), reason: id);
      expect((y - before[id]!.y - 50).abs(), lessThanOrEqualTo(8), reason: id);
    }
    expect(stored['start'], (before['start']!.x, before['start']!.y));
    expect(graphCanvas.currentState!.selection, {'wait', 'end'});
    expect(host.scene.graph, graphInitial.graph);
  });

  testWidgets('Delete removes the selection; Start and loops are refused '
      'with a message; Alt+click unlinks an exit', (tester) async {
    final host = await pumpGraph(tester);

    await dragGraph(
      tester,
      graphExit(tester, 'wait', 'completed'),
      graphCentre(tester, 'check'),
    );
    expect(find.textContaining('boucles'), findsOneWidget);
    expect(host.edits, 0);

    await tester.tapAt(
      graphCentre(tester, 'start'),
      kind: PointerDeviceKind.mouse,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await tester.pump();
    expect(find.text('Le début ne peut pas être supprimé.'), findsOneWidget);

    await tester.tapAt(
      graphCentre(tester, 'wait'),
      kind: PointerDeviceKind.mouse,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await tester.pump();
    expect(host.scene.graph.nodes.map((n) => n.id), ['start', 'check', 'end']);
    expect(edgeFrom(host.scene, 'check', 'true'), isNull);
    expect(graphCanvas.currentState!.selection, isEmpty);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await tester.tapAt(
      graphExit(tester, 'start', 'completed'),
      kind: PointerDeviceKind.mouse,
    );
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    await tester.pump();
    expect(edgeFrom(host.scene, 'start', 'completed'), isNull);
  });

  testWidgets('a right click in the void opens the search; Escape closes it', (
    tester,
  ) async {
    await pumpGraph(tester);

    await rightClickGraph(tester, graphVoid(tester));
    expect(graphKey('scene-graph-step-menu'), findsOneWidget);
    expect(graphKey('scene-graph-step-new-end'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(graphKey('scene-graph-step-menu'), findsNothing);
  });

  testWidgets('a read-only graph ignores links, moves, deletion and the menu', (
    tester,
  ) async {
    final host = await pumpGraph(tester, editable: false);
    final camera = graphCanvas.currentState!.camera!;

    await dragGraph(
      tester,
      graphExit(tester, 'check', 'false'),
      graphCentre(tester, 'end'),
    );
    await tester.tapAt(
      graphCentre(tester, 'wait'),
      kind: PointerDeviceKind.mouse,
    );
    await dragGraph(
      tester,
      graphCentre(tester, 'wait'),
      graphCentre(tester, 'wait') + const Offset(60, 60),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await rightClickGraph(tester, graphVoid(tester));

    expect(host.scene, same(graphInitial));
    expect(graphKey('scene-graph-step-menu'), findsNothing);
    expect(graphCanvas.currentState!.camera, camera);
  });
}
