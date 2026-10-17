import 'package:flame_3d/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/src/spatial_picking.dart';

void main() {
  test(
    'oblique picking reaches continuous ground above the underlying grid',
    () {
      final scene = MapSpatialScene(
        width: 4,
        depth: 4,
        navigation: SpatialNavigationProfile(spawn: SpatialSpawn(x: .5, z: .5)),
        terrainSurfaces: SpatialTerrainSurfaceSet(
          surfaces: [
            SpatialTerrainSurface(
              id: 'hill',
              x: 0,
              z: 0,
              height: 2,
              footprints: [
                BorderGroundFootprint(
                  points: [
                    BorderGroundPoint(x: 0, z: 0),
                    BorderGroundPoint(x: 1, z: 0),
                    BorderGroundPoint(x: 1, z: 1),
                    BorderGroundPoint(x: 0, z: 1),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
      final hit = pickSpatialSurface(
        scene,
        Vector3(.5, 4, 2.5),
        Vector3(0, -1, -1).normalized(),
      );
      expect(hit, isNotNull);
      expect(hit!.cell, (0, 0));
      expect(hit.position.x, closeTo(.5, 1e-6));
      expect(hit.position.y, closeTo(2, 1e-6));
      expect(hit.position.z, closeTo(.5, 1e-6));
    },
  );
}
