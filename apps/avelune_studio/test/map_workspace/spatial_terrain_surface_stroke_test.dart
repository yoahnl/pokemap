import 'package:avelune_studio/features/map_workspace/application/spatial_terrain_stroke.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

void main() {
  test('relief painting explains continuous terrain conflicts without changing the map', () {
    final map = MapData(
      id: 'map',
      name: 'Terrain',
      version: ProjectVersion.v9,
      size: const GridSize(width: 3, height: 3),
      spatialScene: MapSpatialScene(
        width: 3,
        depth: 3,
        terrainSurfaces: SpatialTerrainSurfaceSet(
          surfaces: [
            SpatialTerrainSurface(
              id: 'hill',
              x: 1,
              z: 1,
              height: 2,
              gradientX: .25,
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
      ),
    );
    final stroke = SpatialTerrainStroke(
      source: map,
      mode: SpatialTerrainMode.relief,
      level: 3,
      erase: false,
      origin: const GridPos(x: 1, y: 1),
    );
    expect(stroke.error, contains('surface de terrain'));
    expect(stroke.preview, same(map));
    expect(() => stroke.commit(), throwsStateError);
  });
}
