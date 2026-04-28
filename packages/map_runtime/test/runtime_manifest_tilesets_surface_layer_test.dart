import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/runtime_manifest_tilesets.dart';

void main() {
  group('runtime manifest tileset collection with SurfaceLayer', () {
    test('ignores SurfaceLayer placements in runtime V0 without throwing', () {
      const map = MapData(
        id: 'route-1',
        name: 'Route 1',
        tilesetId: 'base-world',
        size: GridSize(width: 4, height: 4),
        layers: [
          MapLayer.surface(
            id: 'surfaces',
            name: 'Surfaces',
            placements: [
              SurfaceCellPlacement(x: 1, y: 1, surfacePresetId: 'water'),
            ],
          ),
        ],
      );

      // Surface runtime rendering is intentionally deferred. Lot 83 only
      // guarantees that loaders tolerate the layer and do not collect catalog
      // assets before the Surface runtime resolver exists.
      expect(collectTilesetIdsReferencedOnMap(map), {'base-world'});
    });
  });
}
