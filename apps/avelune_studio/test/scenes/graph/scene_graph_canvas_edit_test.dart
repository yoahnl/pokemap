import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_studio/features/scenes/application/graph/scene_graph_view.dart';
import 'package:avelune_studio/l10n/app_localizations.dart';
import 'package:avelune_studio/presentation/features/scene_focus/graph/scene_graph_camera.dart';
import 'package:avelune_studio/presentation/features/scene_focus/graph/scene_graph_canvas.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../steps/scene_step_fixtures.dart';

final _initial = SceneAsset(
  id: 'scene',
  name: 'Scene',
  graph: graphOf(
    [startNode(), conditionNode('check'), waitNode('wait'), endNode('end')],
    [
      link('start', 'check'),
      link('check', 'wait', port: 'true'),
      link('wait', 'end'),
    ],
  ),
);

final _canvas = GlobalKey<SceneGraphCanvasState>();

class _Host extends StatefulWidget {
  const _Host({super.key, required this.editable});

  final bool editable;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  SceneAsset scene = _initial;
  var edits = 0;

  @override
  Widget build(BuildContext context) => SceneGraphCanvas(
    key: _canvas,
    scene: scene,
    project: null,
    onChanged: widget.editable
        ? (next) {
            setState(() {
              scene = next;
              edits++;
            });
            return true;
          }
        : null,
  );
}

final _host = GlobalKey<_HostState>();

Future<_HostState> _pump(WidgetTester tester, {bool editable = true}) async {
  tester.view.physicalSize = const Size(1400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: studioTheme(),
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: _Host(key: _host, editable: editable),
      ),
    ),
  );
  return _host.currentState!;
}

Finder _key(String key) => find.byKey(ValueKey(key));

Offset _exit(WidgetTester tester, String nodeId, String portId) {
  final scene = _host.currentState!.scene;
  final card = projectSceneGraph(scene).card(nodeId)!;
  final canvas = tester.getTopLeft(_key('scene-graph-canvas'));
  return canvas +
      _canvas.currentState!.camera!.toScreen(
        sceneGraphOutputAnchor(card, portId),
      );
}

Offset _centre(WidgetTester tester, String nodeId) =>
    tester.getCenter(_key('scene-graph-card-$nodeId'));

Offset _void(WidgetTester tester) =>
    tester.getRect(_key('scene-graph-canvas')).bottomRight -
    const Offset(40, 140);

Future<void> _drag(WidgetTester tester, Offset from, Offset to) async {
  final gesture = await tester.startGesture(
    from,
    kind: PointerDeviceKind.mouse,
  );
  await gesture.moveTo(from + (to - from) / 2);
  await tester.pump();
  await gesture.moveTo(to);
  await tester.pump();
  await gesture.up();
  await tester.pumpAndSettle();
}

Future<void> _rightClick(WidgetTester tester, Offset at) async {
  final gesture = await tester.startGesture(
    at,
    kind: PointerDeviceKind.mouse,
    buttons: kSecondaryMouseButton,
  );
  await gesture.up();
  await tester.pumpAndSettle();
}

SceneEdge? _from(SceneAsset scene, String node, String port) => scene
    .graph
    .edges
    .where((edge) => edge.fromNodeId == node && edge.fromPortId == port)
    .firstOrNull;

void main() {
  testWidgets('dragging an exit onto a step links them', (tester) async {
    final host = await _pump(tester);

    await _drag(
      tester,
      _exit(tester, 'check', 'false'),
      _centre(tester, 'end'),
    );

    expect(_from(host.scene, 'check', 'false')?.toNodeId, 'end');
    expect(_key('scene-graph-draft-wire'), findsNothing);
  });

  testWidgets('dropping a link in the void opens the search and adds the '
      'chosen step there, linked and selected', (tester) async {
    final host = await _pump(tester);
    final drop = _void(tester);

    await _drag(tester, _exit(tester, 'check', 'false'), drop);
    expect(_key('scene-graph-step-menu'), findsOneWidget);
    await tester.enterText(_key('scene-graph-step-search'), 'fin');
    await tester.pump();
    expect(_key('scene-graph-step-new-talk'), findsNothing);
    await tester.tap(_key('scene-graph-step-new-end'));
    await tester.pumpAndSettle();

    expect(_key('scene-graph-step-menu'), findsNothing);
    final created = _from(host.scene, 'check', 'false')!.toNodeId;
    final node = host.scene.graph.nodes.singleWhere((n) => n.id == created);
    expect(node.kind, SceneNodeKind.end);
    expect(_canvas.currentState!.selection, {created});
    final placed = host.scene.layout.nodeLayouts.singleWhere(
      (layout) => layout.nodeId == created,
    );
    final canvas = tester.getTopLeft(_key('scene-graph-canvas'));
    final world = _canvas.currentState!.camera!.toWorld(drop - canvas);
    expect((placed.x - world.dx).abs(), lessThanOrEqualTo(8));
    expect((placed.y - world.dy).abs(), lessThanOrEqualTo(8));
  });

  testWidgets('dragging cards moves the selection on the grid and stores '
      'every card place', (tester) async {
    final host = await _pump(tester);
    final before = {
      for (final card in projectSceneGraph(_initial).cards)
        card.id: card.position,
    };

    await tester.tapAt(_centre(tester, 'wait'), kind: PointerDeviceKind.mouse);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.tapAt(_centre(tester, 'end'), kind: PointerDeviceKind.mouse);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
    final scale = _canvas.currentState!.camera!.scale;
    await _drag(
      tester,
      _centre(tester, 'wait'),
      _centre(tester, 'wait') + Offset(80 * scale, 50 * scale),
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
    expect(_canvas.currentState!.selection, {'wait', 'end'});
    expect(host.scene.graph, _initial.graph);
  });

  testWidgets('Delete removes the selection; Start and loops are refused '
      'with a message; Alt+click unlinks an exit', (tester) async {
    final host = await _pump(tester);

    await _drag(
      tester,
      _exit(tester, 'wait', 'completed'),
      _centre(tester, 'check'),
    );
    expect(find.textContaining('boucles'), findsOneWidget);
    expect(host.edits, 0);

    await tester.tapAt(_centre(tester, 'start'), kind: PointerDeviceKind.mouse);
    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await tester.pump();
    expect(find.text('Le début ne peut pas être supprimé.'), findsOneWidget);

    await tester.tapAt(_centre(tester, 'wait'), kind: PointerDeviceKind.mouse);
    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await tester.pump();
    expect(host.scene.graph.nodes.map((n) => n.id), ['start', 'check', 'end']);
    expect(_from(host.scene, 'check', 'true'), isNull);
    expect(_canvas.currentState!.selection, isEmpty);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await tester.tapAt(
      _exit(tester, 'start', 'completed'),
      kind: PointerDeviceKind.mouse,
    );
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    await tester.pump();
    expect(_from(host.scene, 'start', 'completed'), isNull);
  });

  testWidgets('a right click in the void opens the search; Escape closes it', (
    tester,
  ) async {
    await _pump(tester);

    await _rightClick(tester, _void(tester));
    expect(_key('scene-graph-step-menu'), findsOneWidget);
    expect(_key('scene-graph-step-new-end'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(_key('scene-graph-step-menu'), findsNothing);
  });

  testWidgets('a read-only graph ignores links, moves, deletion and the menu', (
    tester,
  ) async {
    final host = await _pump(tester, editable: false);
    final camera = _canvas.currentState!.camera!;

    await _drag(
      tester,
      _exit(tester, 'check', 'false'),
      _centre(tester, 'end'),
    );
    await tester.tapAt(_centre(tester, 'wait'), kind: PointerDeviceKind.mouse);
    await _drag(
      tester,
      _centre(tester, 'wait'),
      _centre(tester, 'wait') + const Offset(60, 60),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await _rightClick(tester, _void(tester));

    expect(host.scene, same(_initial));
    expect(_key('scene-graph-step-menu'), findsNothing);
    expect(_canvas.currentState!.camera, camera);
  });
}
