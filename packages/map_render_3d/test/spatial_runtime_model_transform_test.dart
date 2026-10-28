import 'package:flame_3d/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/src/spatial_runtime_model_transform.dart';

void main() {
  test('a runtime translation preserves authored offsets and resets without drift', () {
    final anchor = Model3dVector3(x: 2.2, y: 1, z: 3.7);
    final position = Vector3(12.4, 1.2, 23.9);
    final transform = SpatialRuntimeModelTransform(position: position, anchor: anchor);
    final instance = SpatialModelInstance(id: 'rock', modelId: 'rock', position: anchor);
    for (var i = 0; i < 100; i++) {
      final pose = SpatialModelRuntimeState(modelId: 'rock', animationIndex: null,
          normalizedTime: 0, blocksMovement: true, translationX: i / 100, translationZ: -.3);
      transform.apply(position, instance, pose);
    }
    expect(position.x, closeTo(13.39, .000001));
    expect(position.z, closeTo(23.6, .000001));
    expect(transform.apply(position, instance, null), isTrue);
    expect(position.x, closeTo(12.4, .000001));
    expect(position.z, closeTo(23.9, .000001));
    expect(transform.apply(position, instance, null), isFalse);
    position.x += 2;
    expect(transform.apply(position, instance, null), isFalse);
    expect(position.x, closeTo(14.4, .000001));
  });

  test('source replacement rebases the live translation without another model', () {
    final anchor = Model3dVector3(x: 2, y: 1, z: 3);
    final instance = SpatialModelInstance(id: 'rock', modelId: 'rock', position: anchor);
    final position = Vector3(12, 1, 23);
    final transform = SpatialRuntimeModelTransform(position: position, anchor: anchor);
    final pose = SpatialModelRuntimeState(modelId: 'rock', animationIndex: null,
        normalizedTime: 0, blocksMovement: true, translationX: 1);
    transform.apply(position, instance, pose);
    position.setValues(12.1, 1.5, 23.1);
    transform.rebase(position: position);
    transform.apply(position, instance, pose);
    expect(position.x, closeTo(13.1, .000001));
    expect(position.y, 1.5);
    expect(position.z, closeTo(23.1, .000001));
  });
}
