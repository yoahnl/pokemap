import 'dart:typed_data';

import 'package:flame_3d/core.dart';
import 'package:flame_3d/graphics.dart';
import 'package:flutter/widgets.dart' hide Matrix4;
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/src/adaptive_camera.dart';
import 'package:map_render_3d/src/spatial_picking.dart';
import 'package:map_render_3d/src/spatial_scene_view.dart';

ProjectModel3dEntry _model(String id, Model3dVector3 min, Model3dVector3 max) =>
    ProjectModel3dEntry(
      id: id,
      name: id,
      sourceAssetId: id,
      relativePath: 'assets/models3d/$id.glb',
      inspection: Model3dInspection(
        bounds: Model3dBounds(min: min, max: max),
        meshCount: 1,
        triangleCount: 12,
      ),
    );

SpatialSceneGame _game(
  MapSpatialScene scene,
  List<ProjectModel3dEntry> models,
) {
  final controller = SpatialSceneController();
  addTearDown(controller.dispose);
  final game = SpatialSceneGame(
    SpatialSceneView(
      scene: scene,
      models: models,
      loadModel: (_) async => Uint8List(0),
      controller: controller,
      onCell: (_, _) {},
      background: const Color(0xff000000),
      ground: const Color(0xff000000),
      edge: const Color(0xff000000),
      errorBuilder: (_, _) => const SizedBox(),
    ),
    onPreviewStatus: (_) {},
    onSurfaceChanged: () {},
  )..onGameResize(Vector2(200, 200));
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

  test('ray box entry measures the first face the pointer ray crosses', () {
    final min = Vector3(-1, 0, -1), max = Vector3(1, 2, 1);
    expect(
      spatialRayBoxEntry(Vector3(0, 1, 10), Vector3(0, 0, -1), min, max),
      closeTo(9, 1e-9),
    );
    expect(
      spatialRayBoxEntry(Vector3(3, 1, 10), Vector3(0, 0, -1), min, max),
      isNull,
    );
    expect(
      spatialRayBoxEntry(Vector3(0, 1, 0), Vector3(0, 0, -1), min, max),
      0,
    );
    expect(
      spatialRayBoxEntry(Vector3(0, 1, -5), Vector3(0, 0, -1), min, max),
      isNull,
    );
  });

  test('a press only becomes a content drag past the drag slop', () {
    final threshold = SpatialDragThreshold(const Offset(10, 10));
    expect(threshold.passed(const Offset(12, 12)), isFalse);
    expect(
      threshold.passed(const Offset(10 + spatialContentDragSlop, 10)),
      isTrue,
    );
    expect(threshold.passed(const Offset(10, 10)), isTrue);
  });

  test('the picker keeps the model whose face is in front of the pointer', () {
    _UnusedBackend();
    final scene = MapSpatialScene(
      width: 8,
      depth: 8,
      instances: [
        SpatialModelInstance(
          id: 'tree',
          modelId: 'cube',
          position: Model3dVector3(x: 4, y: 0, z: 3.5),
        ),
        SpatialModelInstance(
          id: 'cliff',
          modelId: 'slab',
          position: Model3dVector3(x: 4, y: 0, z: 5),
        ),
      ],
    );
    final game = _game(scene, [
      _model(
        'cube',
        Model3dVector3(x: -.5, y: 0, z: -.5),
        Model3dVector3(x: .5, y: 2, z: .5),
      ),
      _model(
        'slab',
        Model3dVector3(x: -.5, y: 0, z: -6),
        Model3dVector3(x: .5, y: 2, z: .5),
      ),
    ]);
    expect(game.pickContent(const Offset(100, 100))?.id, 'cliff');
  });

  test('raised terrain in front of a model hides it from the picker', () {
    _UnusedBackend();
    final scene = MapSpatialScene(
      width: 8,
      depth: 8,
      heightLevels: [
        for (var z = 0; z < 8; z++)
          for (var x = 0; x < 8; x++) z == 5 ? 3 : 0,
      ],
      instances: [
        SpatialModelInstance(
          id: 'tree',
          modelId: 'cube',
          position: Model3dVector3(x: 4, y: 0, z: 3.5),
        ),
      ],
    );
    final game = _game(scene, [
      _model(
        'cube',
        Model3dVector3(x: -.5, y: 0, z: -.5),
        Model3dVector3(x: .5, y: 2, z: .5),
      ),
    ]);
    expect(game.pickContent(const Offset(100, 100)), isNull);
  });
}

final class _UnusedBackend extends GpuBackend {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError(invocation.memberName.toString());
}
