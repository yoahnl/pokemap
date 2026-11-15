import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_studio/features/scenes/application/graph/scene_graph_view.dart';
import 'package:avelune_studio/l10n/app_localizations.dart';
import 'package:avelune_studio/presentation/features/scene_focus/graph/scene_graph_camera.dart';
import 'package:avelune_studio/presentation/features/scene_focus/graph/scene_graph_canvas.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../steps/scene_step_fixtures.dart';

final graphInitial = SceneAsset(
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

final graphCanvas = GlobalKey<SceneGraphCanvasState>();

class GraphHost extends StatefulWidget {
  const GraphHost({super.key, required this.editable});

  final bool editable;

  @override
  State<GraphHost> createState() => GraphHostState();
}

class GraphHostState extends State<GraphHost> {
  SceneAsset scene = graphInitial;
  var edits = 0;

  @override
  Widget build(BuildContext context) => SceneGraphCanvas(
    key: graphCanvas,
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

final graphHost = GlobalKey<GraphHostState>();

Future<GraphHostState> pumpGraph(
  WidgetTester tester, {
  bool editable = true,
}) async {
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
        body: GraphHost(key: graphHost, editable: editable),
      ),
    ),
  );
  return graphHost.currentState!;
}

Finder graphKey(String key) => find.byKey(ValueKey(key));

Offset graphExit(WidgetTester tester, String nodeId, String portId) {
  final scene = graphHost.currentState!.scene;
  final card = projectSceneGraph(scene).card(nodeId)!;
  final canvas = tester.getTopLeft(graphKey('scene-graph-canvas'));
  return canvas +
      graphCanvas.currentState!.camera!.toScreen(
        sceneGraphOutputAnchor(card, portId),
      );
}

Offset graphCentre(WidgetTester tester, String nodeId) =>
    tester.getCenter(graphKey('scene-graph-card-$nodeId'));

Offset graphVoid(WidgetTester tester) =>
    tester.getRect(graphKey('scene-graph-canvas')).bottomRight -
    const Offset(40, 140);

Future<void> dragGraph(WidgetTester tester, Offset from, Offset to) async {
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

Future<void> rightClickGraph(WidgetTester tester, Offset at) async {
  final gesture = await tester.startGesture(
    at,
    kind: PointerDeviceKind.mouse,
    buttons: kSecondaryMouseButton,
  );
  await gesture.up();
  await tester.pumpAndSettle();
}

SceneEdge? edgeFrom(SceneAsset scene, String node, String port) => scene
    .graph
    .edges
    .where((edge) => edge.fromNodeId == node && edge.fromPortId == port)
    .firstOrNull;
