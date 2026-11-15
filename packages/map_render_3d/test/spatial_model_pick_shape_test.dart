import 'package:flame_3d/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_render_3d/src/model_byte_loader.dart';
import 'package:map_render_3d/src/spatial_model_pick_shape.dart';

import 'support/billboard_glb_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a masked billboard keeps only its opaque texels for picking', () async {
    final model = await ModelByteLoader.load(
      billboardGlb(opaque: rightQuarterOpaque),
    );
    final shape = spatialModelPickShape(model)!;
    final forward = Vector3(0, 0, -1);

    expect(shape.rayDistance(Vector3(0, 1, 10), forward), isNull);
    expect(shape.rayDistance(Vector3(-.75, 1, 10), forward), isNull);
    expect(shape.rayDistance(Vector3(.75, 1, 10), forward), closeTo(10, 1e-9));
    expect(shape.rayDistance(Vector3(.75, 1, -10), Vector3(0, 0, 1)), 10);
    expect(shape.rayDistance(Vector3(1.5, 1, 10), forward), isNull);
  });

  test('the visible bounds hug the opaque texels instead of the box', () async {
    final model = await ModelByteLoader.load(
      billboardGlb(opaque: rightQuarterOpaque),
    );
    final bounds = spatialModelPickShape(model)!.bounds;

    expect(bounds.min.x, greaterThanOrEqualTo(.5 - .25));
    expect(bounds.max.x, closeTo(1, .25));
    expect(bounds.min.y, closeTo(0, .25));
    expect(bounds.max.y, closeTo(2, .25));
  });

  test('opaque models keep their box picking and outline', () async {
    final model = await ModelByteLoader.load(
      billboardGlb(opaque: rightQuarterOpaque, alphaMode: 'OPAQUE'),
    );

    expect(spatialModelPickShape(model), isNull);
  });

  test('a fully transparent masked model offers nothing to pick', () async {
    final model = await ModelByteLoader.load(
      billboardGlb(opaque: (_, _) => false),
    );
    final shape = spatialModelPickShape(model)!;

    expect(shape.triangleCount, 0);
    expect(shape.rayDistance(Vector3(.75, 1, 10), Vector3(0, 0, -1)), isNull);
  });

  test('the shape is computed once per loaded asset revision', () async {
    final first = await ModelByteLoader.load(
      billboardGlb(opaque: rightQuarterOpaque),
    );
    final revised = await ModelByteLoader.load(
      billboardGlb(opaque: everyTexelOpaque),
    );

    final shape = spatialModelPickShape(first);
    expect(spatialModelPickShape(first), same(shape));
    final revisedShape = spatialModelPickShape(revised)!;
    expect(revisedShape, isNot(same(shape)));
    expect(revisedShape.bounds.min.x, closeTo(-1, .01));
    expect(
      revisedShape.rayDistance(Vector3(0, 1, 10), Vector3(0, 0, -1)),
      closeTo(10, 1e-9),
    );
    expect(shape!.rayDistance(Vector3(0, 1, 10), Vector3(0, 0, -1)), isNull);
  });
}
