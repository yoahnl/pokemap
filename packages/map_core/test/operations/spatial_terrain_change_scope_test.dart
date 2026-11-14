import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'relief_height_step_characterization_test.dart' show reliefMap;

MapData withFeatures(MapData map, List<(String, List<GridPos>)> strokes) =>
    map.copyWith(
      layers: [
        MapLayer.border(
          id: 'border',
          name: 'Cliffs',
          content: BorderLayerContent(
            features: [
              for (final (id, points) in strokes)
                BorderFeature(
                  id: id,
                  name: id,
                  blueprintId: 'fence',
                  seed: BorderSignedInt64.fromInt(0),
                  overrides: const [],
                  keepOutRegions: const [],
                  geometry: BorderStrokeGeometry(
                    alignment: BorderStrokeAlignment.gridEdges,
                    strokes: [
                      BorderStroke(id: id, points: points, closed: false),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );

void main() {
  test('changed surface bounds use world coordinates', () {
    final before = reliefMap([], width: 24, depth: 16).spatialScene!;
    final moved = SpatialTerrainSurface(
      id: 'plateau',
      x: 14,
      z: 6,
      height: 2,
      footprints: [
        BorderGroundFootprint(
          points: [
            BorderGroundPoint(x: 0, z: 0),
            BorderGroundPoint(x: 4, z: 0),
            BorderGroundPoint(x: 4, z: 3),
            BorderGroundPoint(x: 0, z: 3),
          ],
        ),
      ],
    );
    final after = before.copyWith(
      terrainSurfaces: SpatialTerrainSurfaceSet(
        surfaces: [...before.terrainSurfaces.surfaces, moved],
      ),
    );
    expect(spatialTerrainChangeBounds(before, after), (
      left: 14.0,
      top: 6.0,
      right: 18.0,
      bottom: 9.0,
    ));
    expect(spatialTerrainChangeBounds(after, after), isNull);
  });

  test('grid level changes are bounded by their cells', () {
    final before = MapSpatialScene(width: 8, depth: 8);
    final after = before.copyWith(
      heightLevels: [for (var i = 0; i < 64; i++) i == 8 * 5 + 3 ? 2 : 0],
    );
    expect(spatialTerrainChangeBounds(before, after), (
      left: 3.0,
      top: 5.0,
      right: 4.0,
      bottom: 6.0,
    ));
  });

  test('only borders traced near the change are selected', () {
    final map = withFeatures(reliefMap([], width: 30, depth: 16), [
      ('near', [for (var x = 12; x <= 16; x++) GridPos(x: x, y: 5)]),
      ('far', [for (var x = 1; x <= 4; x++) GridPos(x: x, y: 2)]),
      ('crossing', [for (var x = 0; x <= 29; x++) GridPos(x: x, y: 11)]),
    ]);
    expect(
      spatialBorderFeaturesNear(
        [map],
        (left: 14, top: 6, right: 18, bottom: 9),
      ),
      {('border', 'near'), ('border', 'crossing')},
    );
  });
}
