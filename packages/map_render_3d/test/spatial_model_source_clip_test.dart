import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/src/spatial_model_source_clip.dart';

void main() {
  final definition = ProjectModel3dEntry(
    id: 'floor',
    name: 'Floor',
    sourceAssetId: 'floor-source',
    relativePath: 'assets/models3d/floor.glb',
    scale: 2,
    pivot: Model3dVector3(x: 10, y: .125, z: 20),
    inspection: Model3dInspection(
      bounds: Model3dBounds(
        min: Model3dVector3(x: -20, y: -.125, z: -20),
        max: Model3dVector3(x: 20, y: 0, z: 20),
      ),
      meshCount: 1,
      triangleCount: 2,
    ),
  );

  test('clip cells convert through both scales and model pivot', () {
    for (final angle in [0.0, 90.0, 180.0, 270.0]) {
      final instance = SpatialModelInstance(
        id: 'patch',
        modelId: 'floor',
        position: Model3dVector3(x: 500, y: -.1240234375, z: 200),
        rotationDegrees: angle,
        scale: .25,
        blocksMovement: false,
        clip: SpatialModelClip(left: -1.5, top: -2.5, right: 1.5, bottom: 2.5),
      );
      final clip = spatialModelSourceClip(instance, definition)!;
      expect((clip.left, clip.top, clip.right, clip.bottom), (7, 15, 13, 25));
      expect(instance.position.y, -.1240234375);
      final elsewhere = instance.copyWith(
        position: Model3dVector3(x: -100, y: 4, z: 100),
      );
      final same = spatialModelSourceClip(elsewhere, definition)!;
      expect(
        (same.left, same.top, same.right, same.bottom),
        (clip.left, clip.top, clip.right, clip.bottom),
      );
    }
  });

  test('unclipped models keep their existing source geometry', () {
    expect(
      spatialModelSourceClip(
        SpatialModelInstance(
          id: 'whole',
          modelId: 'floor',
          position: Model3dVector3.zero,
        ),
        definition,
      ),
      isNull,
    );
  });

  test('scale underflow is rejected before cutting geometry', () {
    final instance = SpatialModelInstance(
      id: 'tiny',
      modelId: 'floor',
      position: Model3dVector3.zero,
      scale: 1e-250,
      blocksMovement: false,
      clip: SpatialModelClip(left: 0, top: 0, right: 1, bottom: 1),
    );
    expect(
      () =>
          spatialModelSourceClip(instance, definition.copyWith(scale: 1e-250)),
      throwsFormatException,
    );
  });
}
