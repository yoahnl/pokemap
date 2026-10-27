import 'dart:collection';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flame_3d/core.dart';
import 'package:flame_3d/graphics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/src/spatial_scene_height_cache.dart';
import 'package:map_render_3d/src/spatial_scene_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final size in [256, 65536]) {
    test('300 frames do not rescan $size immutable height cells', () {
      final levels = _CountingLevels(List.generate(size, (i) => i % 6));
      final cache = SpatialSceneHeightCache();
      expect(cache.maximumHeight(levels, 2), 10);
      expect(levels.reads, size);
      levels.reads = 0;
      for (var frame = 0; frame < 300; frame++) {
        expect(cache.maximumHeight(levels, 2), 10);
      }
      expect(levels.reads, 0);
    });
  }

  test('new immutable levels invalidate while level scaling stays dynamic', () {
    final cache = SpatialSceneHeightCache();
    final first = _CountingLevels([0, 2, 5, 1]);
    final next = _CountingLevels([0, 8, 3, 1]);
    expect(cache.maximumHeight(first, 2), 10);
    first.reads = 0;
    expect(cache.maximumHeight(first, 3), 15);
    expect(first.reads, 0);
    expect(cache.maximumHeight(next, 3), 24);
    expect(next.reads, 4);
    next.reads = 0;
    expect(cache.maximumHeight(next, 3), 24);
    expect(next.reads, 0);
  });

  test('an empty source cannot replace the last valid revision', () {
    final cache = SpatialSceneHeightCache();
    final levels = _CountingLevels([0, 3]);
    expect(cache.maximumHeight(levels, 1), 3);
    expect(() => cache.maximumHeight(const [], 1), throwsStateError);
    levels.reads = 0;
    expect(cache.maximumHeight(levels, 2), 6);
    expect(levels.reads, 0);
  });

  test(
    'camera framing follows the displayed scene through a pending refresh',
    () {
      _UnusedBackend();
      final controller = SpatialSceneController();
      addTearDown(controller.dispose);
      SpatialSceneView view(MapSpatialScene scene) => SpatialSceneView(
        scene: scene,
        models: const [],
        loadModel: (_) async => Uint8List(0),
        controller: controller,
        onCell: (_, _) {},
        background: const Color(0xff000000),
        ground: const Color(0xff000000),
        edge: const Color(0xff000000),
        errorBuilder: (_, _) => const SizedBox.shrink(),
      );
      final before = view(
        MapSpatialScene(
          width: 2,
          depth: 2,
          heightLevels: [0, 2, 5, 1],
          levelHeight: 2,
        ),
      );
      final after = view(
        MapSpatialScene(
          width: 2,
          depth: 2,
          heightLevels: [0, 8, 3, 1],
          levelHeight: 3,
        ),
      );
      final game = SpatialSceneGame(
        before,
        onPreviewStatus: (_) {},
        onSurfaceChanged: () {},
      );
      addTearDown(game.onRemove);
      game.onGameResize(Vector2(400, 300));
      game.syncCamera();
      final position = game.camera.position.clone();
      final target = game.camera.target.clone();
      final distance = (position - target).length;
      expect(
        distance,
        closeTo(
          10 / (2 * math.tan(math.pi / 9)) * 1.35 * controller.zoom,
          1e-5,
        ),
      );
      for (var frame = 0; frame < 300; frame++) {
        game.syncActors(0);
      }
      expect(game.camera.position, position);
      expect(game.camera.target, target);
      game
        ..renderedConfiguration = before
        ..configuration = after
        ..refreshing = true;
      game.syncCamera();
      expect(game.camera.position, position);
      game
        ..renderedConfiguration = after
        ..refreshing = false;
      game.syncCamera();
      expect(
        (game.camera.position - game.camera.target).length,
        closeTo(distance * 2.4, 1e-5),
      );
      controller
        ..zoom *= .5
        ..pan = const Offset(3, 4);
      game.syncCamera();
      expect(
        (game.camera.position - game.camera.target).length,
        closeTo(distance * 1.2, 1e-5),
      );
      expect(game.camera.target.x, target.x + 3);
      expect(game.camera.target.z, target.z + 4);
    },
  );
}

final class _CountingLevels extends ListBase<int> {
  _CountingLevels(List<int> values) : values = List.unmodifiable(values);

  final List<int> values;
  int reads = 0;

  @override
  int get length => values.length;

  @override
  set length(int value) => throw UnsupportedError('Immutable heights');

  @override
  int operator [](int index) {
    reads++;
    return values[index];
  }

  @override
  void operator []=(int index, int value) =>
      throw UnsupportedError('Immutable heights');
}

final class _UnusedBackend extends GpuBackend {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError(invocation.memberName.toString());
}
