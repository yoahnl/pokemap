import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flame_3d/core.dart';
import 'package:flame_3d/graphics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/src/spatial_scene_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(_UnusedBackend.new);

  for (final projection in SpatialCameraProjection.values) {
    for (final locked in [false, true]) {
      test(
        '$projection playback keeps actor scale and focus across rotation ($locked)',
        () {
          final controller = SpatialSceneController()
            ..setView(SpatialEditorView.game)
            ..visualProfile = SpatialVisualPatch({
              SpatialVisualParameter.lockVerticalFraming: locked,
            });
          addTearDown(controller.dispose);
          var magnification = 1.0;
          final game = SpatialSceneGame(
            SpatialSceneView(
              scene: MapSpatialScene(
                width: 20,
                depth: 20,
                camera: SpatialCameraProfile(
                  projection: projection,
                  distance: 42,
                  fieldOfViewDegrees: 35,
                  orthographicHeight: 12,
                ),
              ),
              models: const [],
              loadModel: (_) async => Uint8List(0),
              controller: controller,
              onCell: (_, _) {},
              background: const Color(0xff000000),
              ground: const Color(0xff000000),
              edge: const Color(0xff000000),
              errorBuilder: (_, _) => const SizedBox.shrink(),
              adaptivePlaybackFraming: true,
              cameraMagnification: () => magnification,
              cameraPose: () => (x: 10, y: 0, z: 10, zoom: 1),
            ),
            onPreviewStatus: (_) {},
            onSurfaceChanged: () {},
          );
          addTearDown(game.onRemove);

          double scale(double width, double height) {
            game.onGameResize(Vector2(width, height));
            game.syncCamera();
            final framing = math.sqrt(width / height / 1.5) * magnification;
            if (projection == SpatialCameraProjection.perspective) {
              expect(
                math.tan(game.camera.fovY * math.pi / 360),
                closeTo(math.tan(35 * math.pi / 360) / framing, 1e-6),
              );
            } else {
              expect(game.camera.fovY, closeTo(12 / framing, 1e-6));
            }
            return height /
                (projection == SpatialCameraProjection.perspective
                    ? math.tan(game.camera.fovY * math.pi / 360) *
                          (game.camera.position - game.camera.target).length
                    : game.camera.fovY);
          }

          final landscape = scale(844, 390);
          final position = game.camera.position.clone();
          final target = game.camera.target.clone();
          final portrait = scale(390, 844);
          expect(portrait, closeTo(landscape, landscape * 1e-6));
          expect(game.camera.position, position);
          expect((position - target).length, closeTo(42, 1e-5));
          expect(game.camera.target, target);
          expect(scale(844, 390), closeTo(landscape, landscape * 1e-6));
          magnification = 1.25;
          expect(scale(390, 844), closeTo(portrait * 1.25, portrait * 1e-6));
          expect(game.camera.position, position);
        },
      );
    }
  }
}

final class _UnusedBackend extends GpuBackend {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
