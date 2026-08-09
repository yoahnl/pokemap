import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Smart Tile layer animation activation', () {
    test('legacy Smart Tile layers remain continuously animated', () {
      final layer =
          MapLayer.fromJson({
                'runtimeType': 'smart_tile',
                'id': 'grass',
                'name': 'Tall grass',
                'presetId': 'tall_grass',
                'usage': 'path',
                'field': {
                  'kind': 'cell',
                  'semanticCells': [1],
                },
              })
              as SmartTileLayer;

      expect(layer.animationActivation, SmartTileAnimationActivation.always);
    });

    test('cell-entry activation survives JSON round trips', () {
      final layer = SmartTileLayer(
        id: 'grass',
        name: 'Tall grass',
        presetId: 'tall_grass',
        usage: SmartTileUsage.path,
        field: const SmartTileField.cell(semanticCells: [1]),
        animationActivation: SmartTileAnimationActivation.onEnter,
      );

      final decoded = MapLayer.fromJson(layer.toJson()) as SmartTileLayer;

      expect(decoded.animationActivation, SmartTileAnimationActivation.onEnter);
      expect(decoded.toJson()['animationActivation'], 'on_enter');
    });
  });
}
