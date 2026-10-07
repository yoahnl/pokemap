import 'package:flutter_test/flutter_test.dart';
import 'package:map_render_3d/src/spatial_picking.dart';
import 'package:flame_3d/core.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/src/spatial_selection.dart';

void main() {
  test('grabbing above a low camera uses a forward drag plane', () {
    final origin = Vector3(5, 1, -2);
    final direction = Vector3(0, .2, 1);
    final height = spatialContentDragHeight(origin, direction, (5, 8));
    expect(height, closeTo(3, .00001));
    final pointer = pickSpatialPlaneCell(origin, direction, height!);
    expect(pointer, (5, 8));
    final drag = SpatialContentDrag(anchor: (5, 8), pointerOrigin: pointer!);
    expect(drag.cellAt(pointer), (5, 8));
    final moved = pickSpatialPlaneCell(Vector3(6, 1, -2), direction, height);
    expect(drag.cellAt(moved!), (6, 8));
  });
  test('selection frame encloses a flat asset with twelve visible edges', () {
    final minimum = Vector3(-2, 0, -1);
    final maximum = Vector3(2, 0, 1);
    final edges = spatialSelectionEdges(minimum, maximum, .04).toList();
    expect(edges, hasLength(12));
    expect(edges.map((edge) => '${edge.$1}:${edge.$2}').toSet(), hasLength(12));
    final points = edges.expand((edge) => [edge.$1, edge.$2]).toList();
    for (var axis = 0; axis < 3; axis++) {
      final coordinates = points.map((point) => point[axis]).toList()..sort();
      expect(coordinates.first, closeTo(minimum[axis] - .04, .00001));
      expect(coordinates.last, closeTo(maximum[axis] + .04, .00001));
    }
    expect(minimum, Vector3(-2, 0, -1));
    expect(maximum, Vector3(2, 0, 1));
  });
  test(
    'low-angle roof drag tracks an unbounded plane without an anchor jump',
    () {
      final scene = MapSpatialScene(width: 10, depth: 10);
      final origin = Vector3(5, 4, -2);
      final direction = Vector3(0, -.2, 1);
      expect(pickSpatialCell(scene, origin, direction), isNull);
      final pointer = pickSpatialPlaneCell(origin, direction, 0);
      expect(pointer, (5, 18));
      final drag = SpatialContentDrag(anchor: (5, 8), pointerOrigin: pointer!);
      expect(drag.cellAt(pointer), (5, 8));
      expect(drag.cellAt((5, 19)), (5, 9));
      expect(pickSpatialPlaneCell(origin, direction, 2), (5, 8));
    },
  );

  test(
    'drag plane rejects parallel rays and intersections behind the camera',
    () {
      expect(
        pickSpatialPlaneCell(Vector3(0, 4, 0), Vector3(1, 0, 0), 0),
        isNull,
      );
      expect(
        pickSpatialPlaneCell(Vector3(0, 4, 0), Vector3(0, 1, 0), 0),
        isNull,
      );
    },
  );
  test(
    'grabbing a sprite head preserves its anchor for a tiny ground delta',
    () {
      const drag = SpatialContentDrag(anchor: (8, 9), pointerOrigin: (8, 5));
      expect(drag.cellAt((8, 5)), (8, 9));
      expect(drag.cellAt((8, 6)), (8, 10));
    },
  );
  test(
    'grabbing a roof preserves the model position for a tiny ground delta',
    () {
      const drag = SpatialContentDrag(anchor: (3, 11), pointerOrigin: (1, 6));
      expect(drag.cellAt((1, 6)), (3, 11));
      expect(drag.cellAt((2, 6)), (4, 11));
      expect(drag.cellAt((1, 5)), (3, 10));
    },
  );
}
