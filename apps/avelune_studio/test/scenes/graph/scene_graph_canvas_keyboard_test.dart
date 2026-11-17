import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import 'scene_graph_canvas_harness.dart';

void main() {
  for (final modifier in [
    LogicalKeyboardKey.metaLeft,
    LogicalKeyboardKey.controlLeft,
  ]) {
    testWidgets('${modifier.keyLabel} selects all from the keyboard', (
      tester,
    ) async {
      final host = await pumpGraph(tester);
      await tester.pump();
      await tester.sendKeyDownEvent(modifier);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
      await tester.sendKeyUpEvent(modifier);
      await tester.pump();
      expect(graphCanvas.currentState!.selection, {
        'start',
        'check',
        'wait',
        'end',
      });
      expect(host.edits, 0);
    });
  }

  testWidgets('⌘C then ⌘V pastes under the mouse, ⌘D duplicates beside, '
      '⌘X cuts', (tester) async {
    final host = await pumpGraph(tester);
    Future<void> command(LogicalKeyboardKey key) async {
      await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
      await tester.sendKeyEvent(key);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
      await tester.pumpAndSettle();
    }

    await tester.tapAt(
      graphCentre(tester, 'wait'),
      kind: PointerDeviceKind.mouse,
    );
    await command(LogicalKeyboardKey.keyC);
    await tester.tapAt(graphVoid(tester), kind: PointerDeviceKind.mouse);
    await tester.pump();
    await command(LogicalKeyboardKey.keyV);

    final pasted = graphCanvas.currentState!.selection.single;
    expect(pasted, isNot('wait'));
    final node = host.scene.graph.nodes.singleWhere((n) => n.id == pasted);
    expect(node.payload, graphInitial.graph.nodes[2].payload);
    final canvas = tester.getTopLeft(graphKey('scene-graph-canvas'));
    final world = graphCanvas.currentState!.camera!.toWorld(
      graphVoid(tester) - canvas,
    );
    final place = host.scene.layout.nodeLayouts.singleWhere(
      (l) => l.nodeId == pasted,
    );
    expect((place.x - world.dx).abs(), lessThanOrEqualTo(8));

    final before = host.scene.layout.nodeLayouts.singleWhere(
      (l) => l.nodeId == 'wait',
    );
    await tester.tapAt(
      graphCentre(tester, 'wait'),
      kind: PointerDeviceKind.mouse,
    );
    await command(LogicalKeyboardKey.keyD);
    final twin = graphCanvas.currentState!.selection.single;
    final twinPlace = host.scene.layout.nodeLayouts.singleWhere(
      (l) => l.nodeId == twin,
    );
    expect((twinPlace.x, twinPlace.y), (before.x + 32, before.y + 32));

    await command(LogicalKeyboardKey.keyX);
    expect(host.scene.graph.nodes.map((n) => n.id), isNot(contains(twin)));
    expect(host.scene.graph.nodes, hasLength(5));
  });

  testWidgets('a read-only graph still copies but never pastes', (
    tester,
  ) async {
    final host = await pumpGraph(tester, editable: false);

    await tester.tapAt(
      graphCentre(tester, 'wait'),
      kind: PointerDeviceKind.mouse,
    );
    await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyV);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyD);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    await tester.pump();

    expect(host.scene, same(graphInitial));
  });

  testWidgets('shortcuts work as soon as the graph opens, before any click', (
    tester,
  ) async {
    final host = await pumpGraph(tester);
    await tester.pump();

    graphCanvas.currentState!.show('wait');
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyD);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    await tester.pump();

    expect(
      host.scene.graph.nodes,
      hasLength(graphInitial.graph.nodes.length + 1),
    );
  });

  testWidgets('a paste near the bottom stays above the help bar', (
    tester,
  ) async {
    await pumpGraph(tester);
    final canvas = tester.getRect(graphKey('scene-graph-canvas'));

    await tester.tapAt(
      graphCentre(tester, 'wait'),
      kind: PointerDeviceKind.mouse,
    );
    await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    await tester.tapAt(
      Offset(canvas.center.dx, canvas.bottom - 100),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyV);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    await tester.pumpAndSettle();

    final pasted = graphCanvas.currentState!.selection.single;
    final card = tester.getRect(graphKey('scene-graph-card-$pasted'));
    expect(card.bottom, lessThanOrEqualTo(canvas.bottom - 96 + 16));
  });

  testWidgets('while editing is being prepared the help bar says so', (
    tester,
  ) async {
    await pumpGraph(tester, editable: false, preparing: true);

    expect(find.textContaining('Préparation de l’édition…'), findsOneWidget);
    expect(find.textContaining('Glisser une sortie'), findsNothing);
  });

  testWidgets('an advanced action is named by the engine catalog, not its id', (
    tester,
  ) async {
    await pumpGraph(tester);

    expect(
      find.descendant(
        of: graphKey('scene-graph-card-wait'),
        matching: find.text('wait'),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: graphKey('scene-graph-card-wait'),
        matching: find.text(
          NarrativeCommandCatalog.canonical().byId('wait')!.label,
        ),
      ),
      findsOneWidget,
    );
  });
}
