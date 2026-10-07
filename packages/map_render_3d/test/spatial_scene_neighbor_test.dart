import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/map_render_3d.dart';

import '../../map_gameplay/lib/src/gameplay_connection.dart';

void main() {
  const source = GridSize(width: 11, height: 9);
  const target = GridSize(width: 7, height: 13);
  for (final direction in MapConnectionDirection.values) {
    for (final offset in [-3, 0, 3]) {
      test(
        '${direction.name} offset $offset agrees with 2D border crossing',
        () {
          final placement = spatialConnectionOffset(
            source,
            target,
            direction,
            offset,
          );
          final returnPlacement = spatialConnectionOffset(
            target,
            source,
            direction.opposite,
            -offset,
          );
          expect(placement + returnPlacement, Offset.zero);
          var crossings = 0;
          for (var y = 0; y < source.height; y++) {
            for (var x = 0; x < source.width; x++) {
              final position = GridPos(x: x, y: y);
              final destination = resolveConnectedMapTargetPos(
                sourcePos: position,
                sourceSize: source,
                targetSize: target,
                direction: direction,
                offset: offset,
              );
              if (destination == null) continue;
              crossings++;
              final step = switch (direction) {
                MapConnectionDirection.east => const Offset(1, 0),
                MapConnectionDirection.west => const Offset(-1, 0),
                MapConnectionDirection.north => const Offset(0, -1),
                MapConnectionDirection.south => const Offset(0, 1),
              };
              expect(
                placement +
                    Offset(destination.x.toDouble(), destination.y.toDouble()),
                Offset(x.toDouble(), y.toDouble()) + step,
              );
            }
          }
          expect(crossings, greaterThan(0));
        },
      );
    }
  }

  test('editor defaults keep a single scene at the local origin', () {
    final controller = SpatialSceneController();
    addTearDown(controller.dispose);
    final view = SpatialSceneView(
      scene: MapSpatialScene(width: 2, depth: 2),
      models: const [],
      loadModel: (_) async => Uint8List(0),
      controller: controller,
      onCell: (_, _) {},
      background: const Color(0xff000000),
      ground: const Color(0xff224422),
      edge: const Color(0xff111111),
      errorBuilder: (_, _) => const SizedBox(),
    );
    expect(view.neighbors, isEmpty);
    expect(view.sceneOffset, Offset.zero);
  });

  test('neighbor retains its map, relative origin and asset loader', () async {
    final map = MapData(
      id: 'east',
      name: 'East',
      size: target,
      spatialScene: MapSpatialScene(width: target.width, depth: target.height),
    );
    final requested = <String>[];
    final neighbor = SpatialSceneNeighbor(
      map: map,
      offset: const Offset(11, -3),
      loadGroundImage: (id) async {
        requested.add(id);
        return Uint8List.fromList([1, 2]);
      },
    );
    expect(neighbor.map, same(map));
    expect(neighbor.offset, const Offset(11, -3));
    expect(await neighbor.loadGroundImage('grass'), [1, 2]);
    expect(requested, ['grass']);
  });
}
