import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../../dev/hgss_lighting_comparison.dart';

void main() {
  final house = SpatialModelInstance(
    id: 'house',
    modelId: 'house-model',
    position: Model3dVector3.zero,
  );
  final door = SpatialModelInstance(
    id: 'door',
    modelId: 'door-model',
    position: Model3dVector3.zero,
  );
  final turbine = SpatialModelInstance(
    id: 'turbine',
    modelId: 'turbine-model',
    position: Model3dVector3.zero,
  );
  final source = MapSpatialScene(
    width: 4,
    depth: 4,
    heightLevels: List.filled(16, 1),
    instances: [house, door, turbine],
  );

  test(
    'comparison hides only requested instances without mutating its source',
    () {
      final prepared = prepareComparisonScene(source, {'turbine'});
      expect(prepared.instances, [house, door]);
      expect(source.instances, [house, door, turbine]);
      expect(prepared.camera, same(source.camera));
      expect(prepared.navigation, same(source.navigation));
      expect(prepared.heightLevels, source.heightLevels);
      expect(prepared.terrainSurfaces, same(source.terrainSurfaces));
    },
  );

  test(
    'an unknown removal fails instead of producing a misleading comparison',
    () {
      expect(
        () => prepareComparisonScene(source, {'unknown'}),
        throwsStateError,
      );
    },
  );

  test('an unfiltered comparison preserves the original scene identity', () {
    expect(prepareComparisonScene(source, {}), same(source));
  });

  test(
    'the renderer map carries the same filtered scene as its scene argument',
    () {
      final map = MapData(
        id: 'comparison',
        name: 'Comparison',
        version: ProjectVersion.v9,
        size: const GridSize(width: 4, height: 4),
        spatialScene: source,
      );
      final prepared = prepareComparisonMap(map, {'turbine'});
      expect(prepared.spatialScene!.instances, [house, door]);
      expect(map.spatialScene!.instances, [house, door, turbine]);
      expect(prepared.spatialScene!.camera, same(source.camera));
      expect(prepared.entities, map.entities);
      expect(prepared.layers, map.layers);
    },
  );
}
