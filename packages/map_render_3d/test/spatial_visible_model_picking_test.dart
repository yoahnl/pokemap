import 'dart:typed_data';

import 'package:flame_3d/core.dart';
import 'package:flame_3d/graphics.dart';
import 'package:flutter/widgets.dart' hide Matrix4;
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/src/adaptive_camera.dart';
import 'package:map_render_3d/src/spatial_scene_view.dart';

import 'support/billboard_glb_fixture.dart';

ProjectModel3dEntry _entry(String id, Model3dVector3 min, Model3dVector3 max) =>
    ProjectModel3dEntry(
      id: id,
      name: id,
      sourceAssetId: id,
      relativePath: 'assets/models3d/$id.glb',
      inspection: Model3dInspection(
        bounds: Model3dBounds(min: min, max: max),
        meshCount: 1,
        triangleCount: 2,
      ),
    );

final _scene = MapSpatialScene(
  width: 8,
  depth: 8,
  instances: [
    SpatialModelInstance(
      id: 'tree',
      modelId: 'tree',
      position: Model3dVector3(x: 4, y: 0, z: 4.5),
    ),
    SpatialModelInstance(
      id: 'behind',
      modelId: 'wall',
      position: Model3dVector3(x: 4, y: 0, z: 3.5),
    ),
  ],
);

final _models = [
  _entry(
    'tree',
    Model3dVector3(x: -1, y: 0, z: 0),
    Model3dVector3(x: 1, y: 2, z: 0),
  ),
  _entry(
    'wall',
    Model3dVector3(x: -1, y: 0, z: 0),
    Model3dVector3(x: 1, y: 2, z: 0),
  ),
];

Future<Uint8List> _load(String id) async => id == 'tree'
    ? billboardGlb(opaque: rightQuarterOpaque)
    : billboardGlb(opaque: everyTexelOpaque, alphaMode: 'OPAQUE');

SpatialSceneView _view(SpatialSceneController controller, {String? selected}) =>
    SpatialSceneView(
      scene: _scene,
      models: _models,
      loadModel: _load,
      controller: controller,
      selectedContent: selected == null
          ? null
          : SpatialSceneContentHit(
              kind: SpatialSceneContentKind.model,
              id: selected,
              cell: (4, 4),
            ),
      onCell: (_, _) {},
      background: const Color(0xff000000),
      ground: const Color(0xff000000),
      edge: const Color(0xff000000),
      errorBuilder: (_, _) => const SizedBox(),
    );

Offset _screen(SpatialSceneGame game, Vector3 world) {
  final clip = game.camera.viewProjectionMatrix.transform(
    Vector4(world.x, world.y, world.z, 1),
  );
  return Offset(
    (clip.x / clip.w + 1) * game.size.x / 2,
    (1 - clip.y / clip.w) * game.size.y / 2,
  );
}

Future<SpatialSceneGame> _loadedGame(SpatialSceneController controller) async {
  final game = SpatialSceneGame(
    _view(controller),
    onPreviewStatus: (_) {},
    onSurfaceChanged: () {},
  )..onGameResize(Vector2(200, 200));
  game.sceneReady = true;
  await game.refresh();
  addTearDown(game.onRemove);
  (game.camera as AdaptiveCamera3D).frame(
    Vector3(4, 1, 4),
    pitch: 0,
    yaw: 0,
    distance: 10,
    viewportAspectRatio: 1,
  );
  return game;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'a click through transparent foliage selects the model behind',
    () async {
      _UnusedBackend();
      final controller = SpatialSceneController();
      addTearDown(controller.dispose);
      final game = await _loadedGame(controller);
      expect(game.modelComponents.keys, containsAll(['tree', 'behind']));

      expect(game.pickContent(const Offset(100, 100))?.id, 'behind');
      expect(
        game.pickContent(_screen(game, Vector3(4.75, 1, 4.5)))?.id,
        'tree',
      );
      expect(
        game.pickContent(_screen(game, Vector3(3.25, 1, 4.5)))?.id,
        'behind',
      );
    },
  );

  test('the selection outline follows the visible foliage', () async {
    _UnusedBackend();
    final controller = SpatialSceneController();
    addTearDown(controller.dispose);
    final game = await _loadedGame(controller);
    final tree = game.modelComponents['tree']!.component;
    final before = game.configuration;
    final selected = _view(controller, selected: 'tree');
    game.renderedConfiguration = selected;
    game.syncContentSelection(before, selected);

    final edges = game.modelSelections['tree']!;
    final xs = edges.map((edge) => edge.position.x);
    final minimum = xs.reduce((a, b) => a < b ? a : b);
    expect(minimum, greaterThan(tree.visibleBounds.min.x + .5));
    expect(minimum, greaterThanOrEqualTo(.5 - .25 - .1));
    final behindSelected = _view(controller, selected: 'behind');
    game.renderedConfiguration = behindSelected;
    game.syncContentSelection(selected, behindSelected);
    final wall = game.modelSelections['behind']!.map((edge) => edge.position.x);
    expect(wall.reduce((a, b) => a < b ? a : b), lessThan(-1));
  });
}

final class _UnusedBackend extends GpuBackend {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError(invocation.memberName.toString());
}
