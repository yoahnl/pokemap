import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('candidateWeights vaut une table vide par défaut', () {
    const layer = MapLayer.smartTile(
      id: 'riviere',
      name: 'Rivière',
      presetId: 'eau',
      usage: SmartTileUsage.path,
      field: SmartTileField.cell(semanticCells: <int>[0, 0, 0, 0]),
    );
    expect((layer as SmartTileLayer).candidateWeights, isEmpty);
  });

  test('un calque écrit sans le champ se relit', () {
    final json = <String, dynamic>{
      'runtimeType': 'smart_tile',
      'id': 'riviere',
      'name': 'Rivière',
      'presetId': 'eau',
      'usage': 'path',
      'field': const SmartTileField.cell(
        semanticCells: <int>[0, 0, 0, 0],
      ).toJson(),
    };
    final layer = MapLayer.fromJson(json) as SmartTileLayer;
    expect(layer.candidateWeights, isEmpty);
  });

  test('aller-retour de sérialisation', () {
    final layer = const MapLayer.smartTile(
      id: 'riviere',
      name: 'Rivière',
      presetId: 'eau',
      usage: SmartTileUsage.path,
      field: SmartTileField.cell(semanticCells: <int>[0, 0, 0, 0]),
      candidateWeights: <String, int>{'cand-5': 0, 'cand-0': 900},
    ) as SmartTileLayer;
    final round = MapLayer.fromJson(layer.toJson()) as SmartTileLayer;
    expect(round.candidateWeights, layer.candidateWeights);
  });

  test('une table vide n\'écrit pas de clé', () {
    const layer = MapLayer.smartTile(
      id: 'riviere',
      name: 'Rivière',
      presetId: 'eau',
      usage: SmartTileUsage.path,
      field: SmartTileField.cell(semanticCells: <int>[0, 0, 0, 0]),
    );
    expect(layer.toJson().containsKey('candidateWeights'), isFalse);
  });
}
