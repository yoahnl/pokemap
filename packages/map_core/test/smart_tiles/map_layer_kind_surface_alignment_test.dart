import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('surface usage is represented by the canonical Smart Tile layer', () {
    expect(MapLayerKind.smartTile.name, 'smartTile');
    expect(
      const MapLayer.smartTile(
        id: 'surface',
        name: 'Forest surface',
        presetId: 'forest',
        usage: SmartTileUsage.forestSurface,
        materialPalette: <String>['', 'forest'],
        field: SmartTileField.cell(semanticCells: <int>[1]),
      ),
      isA<SmartTileLayer>(),
    );
  });
}
