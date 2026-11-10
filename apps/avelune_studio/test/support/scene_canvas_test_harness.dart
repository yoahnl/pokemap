import 'scene_graph_project_fixture.dart';

import 'package:avelune_studio/presentation/features/scenes/scene_graph_canvas.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

class SceneCanvasTestHarness {
  SceneAsset scene = sceneCanvasFixture();
  final view = SceneGraphViewport();
  late StateSetter refresh;
  final history = <SceneAsset>[];
  String? selected, edge;
  int commits = 0;
  final additions = <(SceneBlockDragData, Offset, String?, String?)>[];
  void commit(SceneAsset next) {
    history.add(scene);
    commits++;
    refresh(() => scene = next);
  }

  void undo() {
    refresh(() => scene = history.removeLast());
  }

  Future<void> mount(
    WidgetTester tester, {
    Widget Function(Widget)? wrap,
  }) async {
    tester.view.reset();
    tester.view.physicalSize = const Size(1100, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(view.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              refresh = setState;
              final canvas = SceneGraphCanvas(
                scene: scene,
                viewport: view,
                fitOnFirstLayout: false,
                selectedNodeId: selected,
                selectedEdgeId: edge,
                onSelectNode: (id) => refresh(() => selected = id),
                onSelectEdge: (id) => refresh(() => edge = id),
                onClearSelection: () => refresh(() {
                  selected = null;
                  edge = null;
                }),
                onMoveNode: (id, p) => commit(
                  updateSceneNodeLayout(
                    scene,
                    nodeId: id,
                    x: p.dx,
                    y: p.dy,
                  ).updatedScene,
                ),
                onConnect: (from, port, to) => commit(
                  addSceneEdgeDraft(
                    scene,
                    fromNodeId: from,
                    fromPortId: port,
                    toNodeId: to,
                  ).updatedScene,
                ),
                availableBlocks: const [
                  SceneBlockDragData(
                    kind: SceneNodeKind.condition,
                    label: 'Condition',
                  ),
                ],
                onAdd: (block, position, {fromNodeId, fromPortId}) =>
                    additions.add((block, position, fromNodeId, fromPortId)),
                onDelete: () {
                  if (edge != null) {
                    commit(removeSceneEdgeDraft(scene, edge!).updatedScene);
                  }
                },
                onUndo: undo,
              );
              return wrap?.call(canvas) ?? canvas;
            },
          ),
        ),
      ),
    );
    await tester.pump();
  }
}
