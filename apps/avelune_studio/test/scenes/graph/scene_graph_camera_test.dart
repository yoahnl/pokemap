import 'dart:ui';

import 'package:avelune_studio/presentation/features/scene_focus/graph/scene_graph_camera.dart';
import 'package:avelune_studio/features/scenes/application/graph/scene_graph_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../steps/scene_step_fixtures.dart';

void main() {
  test('zooming keeps the world point under the pointer in place', () {
    const camera = SceneGraphCamera(pan: Offset(40, -30), scale: 0.8);
    const pointer = Offset(300, 200);
    final before = camera.toWorld(pointer);

    final zoomed = camera.zoomAt(pointer, 1.5);

    expect(zoomed.scale, closeTo(1.2, 1e-9));
    expect(zoomed.toWorld(pointer).dx, closeTo(before.dx, 1e-9));
    expect(zoomed.toWorld(pointer).dy, closeTo(before.dy, 1e-9));
    expect(zoomed.toScreen(zoomed.toWorld(pointer)), pointer);
  });

  test('zoom stays between the minimum and maximum scale', () {
    const camera = SceneGraphCamera();

    expect(camera.zoomAt(Offset.zero, 100).scale, SceneGraphCamera.maxScale);
    expect(camera.zoomAt(Offset.zero, 0.001).scale, SceneGraphCamera.minScale);
  });

  test('fit centres the scene and never enlarges a small one', () {
    const viewport = Size(1000, 600);
    const small = Rect.fromLTWH(500, 500, 200, 100);
    final fitted = SceneGraphCamera.fit(small, viewport);
    expect(fitted.scale, 1);
    expect(fitted.toScreen(small.center), viewport.center(Offset.zero));

    const large = Rect.fromLTWH(-200, 0, 3000, 400);
    final shrunk = SceneGraphCamera.fit(large, viewport);
    expect(shrunk.scale, lessThan(1));
    final screen = Rect.fromPoints(
      shrunk.toScreen(large.topLeft),
      shrunk.toScreen(large.bottomRight),
    );
    expect(
      screen.left,
      greaterThanOrEqualTo(SceneGraphCamera.fitMargin - 1e-6),
    );
    expect(
      screen.right,
      lessThanOrEqualTo(viewport.width - SceneGraphCamera.fitMargin + 1e-6),
    );
  });

  test('an empty scene or viewport keeps the default view', () {
    expect(
      SceneGraphCamera.fit(Rect.zero, const Size(800, 600)),
      const SceneGraphCamera(),
    );
    expect(
      SceneGraphCamera.fit(const Rect.fromLTWH(0, 0, 10, 10), Size.zero),
      const SceneGraphCamera(),
    );
  });

  test('a long scene opens readable from its start, Show all still fits', () {
    const viewport = Size(1000, 600);
    const chain = Rect.fromLTWH(0, 0, 9000, 300);
    const start = Offset(110, 150);

    final opening = SceneGraphCamera.opening(chain, viewport, start);

    expect(opening.scale, SceneGraphCamera.readableScale);
    expect(opening.toScreen(chain.topLeft).dx, SceneGraphCamera.fitMargin);
    expect(opening.toScreen(start).dy, viewport.height / 2);
    expect(
      SceneGraphCamera.fit(chain, viewport).scale,
      lessThan(SceneGraphCamera.readableScale),
    );
    const small = Rect.fromLTWH(0, 0, 400, 200);
    expect(
      SceneGraphCamera.opening(small, viewport, start),
      SceneGraphCamera.fit(small, viewport),
    );
  });

  test('a press between two close exits picks the nearest one', () {
    final view = projectSceneGraph(
      SceneAsset(
        id: 'scene',
        name: 'Scene',
        graph: graphOf(
          [startNode(), conditionNode('check'), endNode('end')],
          [link('start', 'check'), link('check', 'end', port: 'true')],
        ),
      ),
    );
    final card = view.card('check')!;
    final yes = sceneGraphOutputAnchor(card, 'true');
    final no = sceneGraphOutputAnchor(card, 'false');
    final nearNo = Offset.lerp(yes, no, 0.7)!;

    expect(sceneGraphExitAt(view, nearNo, 100), (
      nodeId: 'check',
      portId: 'false',
    ));
    expect(
      sceneGraphExitAt(view, yes + const Offset(0, -1), 100)?.portId,
      'true',
    );
    expect(sceneGraphExitAt(view, nearNo, 1), isNull);
  });
}
