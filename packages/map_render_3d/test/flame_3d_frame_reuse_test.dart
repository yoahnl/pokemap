import 'dart:typed_data';

import 'package:flame/components.dart' show Vector2;
import 'package:flame_3d/camera.dart';
import 'package:flame_3d/core.dart' hide Vector2;
import 'package:flame_3d/model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_render_3d/map_render_3d.dart';

import '../../map_authoring/test/support/glb_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ModelNode node(int index, {int? parent, double x = 0}) => ModelNode(
    name: 'node $index',
    nodeIndex: index,
    parentNodeIndex: parent,
    transform: Matrix4.translationValues(x, 0, 0),
    mesh: null,
    joints: {},
  );

  test('a model at rest is processed once and keeps its dependency order', () {
    final model = Model(
      nodes: {
        2: node(2, parent: 1, x: 4),
        1: node(1, parent: 0, x: 2),
        0: node(0, x: 1),
      },
      animations: [],
    );
    final animation = AnimationState();

    final first = model.processNodes(animation);
    final second = model.processNodes(animation);

    expect(identical(first, second), isTrue);
    expect(first.keys, [0, 1, 2]);
    expect(first[2]!.combinedTransform.getTranslation().x, 7);
  });

  test('a running animation is sampled on every call', () async {
    final model = await ModelByteLoader.load(Uint8List.fromList(animatedGlb()));
    final animation = AnimationState()
      ..startAnimation(model.animations.single)
      ..clock = 0;

    final start = model
        .processNodes(animation)
        .values
        .single
        .combinedTransform
        .clone();
    animation.clock = model.animations.single.lastTime / 2;
    final middle = model.processNodes(animation);

    expect(identical(model.processNodes(animation), middle), isFalse);
    expect(middle.values.single.combinedTransform, isNot(start));
  });

  test('a held frustum ignores camera moves until it is released', () {
    final camera = CameraComponent3D(
      position: Vector3(0, 0, 5),
      target: Vector3.zero(),
    );
    camera.viewport.size = Vector2(200, 100);
    final box = Aabb3.minMax(Vector3(-0.5, -0.5, -0.5), Vector3.all(0.5));

    camera.holdFrustum();
    camera.position.setValues(0, 0, -5);
    camera.target.setValues(0, 0, -10);
    expect(box.frustumCullTest(camera.frustum), CullResult.inside);

    camera.releaseFrustum();
    expect(box.frustumCullTest(camera.frustum), CullResult.outside);
  });

  test(
    'the cull test still separates inside, straddling and outside boxes',
    () {
      final camera = CameraComponent3D(
        position: Vector3(0, 0, 5),
        target: Vector3.zero(),
      );
      camera.viewport.size = Vector2(100, 100);
      final frustum = camera.frustum;

      expect(
        Aabb3.minMax(
          Vector3.all(-0.5),
          Vector3.all(0.5),
        ).frustumCullTest(frustum),
        CullResult.inside,
      );
      expect(
        Aabb3.minMax(
          Vector3(-0.5, -0.5, 4),
          Vector3(0.5, 0.5, 6),
        ).frustumCullTest(frustum),
        CullResult.intersecting,
      );
      expect(
        Aabb3.minMax(
          Vector3(-0.5, -0.5, 6),
          Vector3(0.5, 0.5, 7),
        ).frustumCullTest(frustum),
        CullResult.outside,
      );
    },
  );
}
