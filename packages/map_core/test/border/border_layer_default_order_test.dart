import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  for (final frontFirst in [true, false]) {
    test('new Border layer paints above existing ground ($frontFirst)', () {
      final ground = TileLayer(id: 'ground', name: 'Sol', cells: [0]);
      final source = MapData(
        id: 'garden',
        name: 'Jardin',
        size: const GridSize(width: 1, height: 1),
        visualStack: frontFirst ? MapVisualStackConfig.canonicalV1 : null,
        properties: frontFirst
            ? const {}
            : const {'tileLayerOrder': 'bottom_to_top'},
        layers: [ground],
      );
      final updated = addBorderLayer(source, id: 'border', name: 'Bordures');
      final plan = buildMapVisualCompositionPlan(updated).plan!;
      final painted = plan.steps
          .where((step) => step.layer != null)
          .map((step) => step.layer!.id)
          .toList();
      expect(painted.indexOf('border'), greaterThan(painted.indexOf('ground')));
      expect(updated.layers.whereType<TileLayer>().single, same(ground));
      expect(source.layers, [ground]);
      expect(MapData.fromJson(updated.toJson()).layers, updated.layers);
      final generic = addMapLayer(
        source,
        kind: MapLayerKind.border,
        id: 'border',
        name: 'Bordures',
      );
      expect(generic, updated);
    });
  }

  test('explicit insertion and existing authored order remain unchanged', () {
    final source = MapData(
      id: 'garden',
      name: 'Jardin',
      size: const GridSize(width: 1, height: 1),
      visualStack: MapVisualStackConfig.canonicalV1,
      layers: [
        const MapLayer.border(id: 'old-border', name: 'Existing'),
        TileLayer(id: 'ground', name: 'Sol', cells: [0]),
      ],
    );
    final updated = addBorderLayer(
      source,
      id: 'new-border',
      name: 'Behind ground',
      insertIndex: 2,
    );
    expect(updated.layers.take(2), orderedEquals(source.layers));
    expect(updated.layers.last.id, 'new-border');
  });
}
