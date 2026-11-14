import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

const _size = GridSize(width: 2, height: 2);

void main() {
  group('3D ground paint over surfaces drawn above it', () {
    test(
      'erases paths and water at painted cells only, whatever their order',
      () {
        final map = _map(
          spatial: true,
          layers: [
            _surface('road', SmartTileUsage.path, [1, 1, 0, 0]),
            _surface('grass', SmartTileUsage.terrain, [0, 0, 0, 0]),
            _surface('water', SmartTileUsage.path, [1, 0, 1, 0]),
          ],
        );

        final painted = _paint(map, 'grass', const [GridPos(x: 0, y: 0)]);

        expect(_cells(painted, 'grass'), [1, 0, 0, 0]);
        expect(_cells(painted, 'road'), [0, 1, 0, 0]);
        expect(_cells(painted, 'water'), [0, 0, 1, 0]);
      },
    );

    test('keeps lower grounds and erase gestures unchanged', () {
      final map = _map(
        spatial: true,
        layers: [
          _surface('base', SmartTileUsage.terrain, [1, 1, 1, 1]),
          _surface('grass', SmartTileUsage.terrain, [0, 0, 0, 0]),
          _surface('road', SmartTileUsage.path, [1, 1, 1, 1]),
        ],
      );

      final painted = _paint(map, 'grass', const [GridPos(x: 1, y: 1)]);
      expect(_cells(painted, 'base'), [1, 1, 1, 1]);
      expect(_cells(painted, 'road'), [1, 1, 1, 0]);

      final erased = applySmartTileMapMaterialGesture(
        painted,
        layer: _layer(painted, 'grass'),
        catalog: ProjectSmartTileCatalog(),
        cells: const [GridPos(x: 0, y: 0)],
        materialId: null,
      );
      expect(_cells(erased, 'road'), [1, 1, 1, 0]);
    });

    test('2D maps keep their paths', () {
      final map = _map(
        spatial: false,
        layers: [
          _surface('grass', SmartTileUsage.terrain, [0, 0, 0, 0]),
          _surface('road', SmartTileUsage.path, [1, 1, 1, 1]),
        ],
      );

      final painted = _paint(map, 'grass', const [GridPos(x: 0, y: 0)]);

      expect(_cells(painted, 'grass'), [1, 0, 0, 0]);
      expect(_cells(painted, 'road'), [1, 1, 1, 1]);
    });
  });
}

SmartTileLayer _surface(String id, SmartTileUsage usage, List<int> cells) =>
    SmartTileLayer(
      id: id,
      name: id,
      presetId: id,
      usage: usage,
      materialPalette: ['', id],
      field: SmartTileField.cell(semanticCells: cells),
    );

MapData _map({required bool spatial, required List<MapLayer> layers}) =>
    MapData(
      id: 'map',
      name: 'Map',
      size: _size,
      version: spatial ? ProjectVersion.v9 : ProjectVersion.v8,
      properties: const {'tileLayerOrder': 'bottom_to_top'},
      spatialScene: spatial ? MapSpatialScene(width: 2, depth: 2) : null,
      layers: layers,
    );

SmartTileLayer _layer(MapData map, String id) => map.layers
    .whereType<SmartTileLayer>()
    .firstWhere((layer) => layer.id == id);

MapData _paint(MapData map, String id, List<GridPos> cells) =>
    applySmartTileMapMaterialGesture(
      map,
      layer: _layer(map, id),
      catalog: ProjectSmartTileCatalog(),
      cells: cells,
      materialId: id,
    );

List<int> _cells(MapData map, String id) =>
    smartTileSemanticCells(_layer(map, id));
