import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/ui/panels/layers_panel_presentation.dart';

void main() {
  group('TileLayer environment layer grouping presentation', () {
    test('TileLayer sans EnvironmentLayer reste une row normale', () {
      const map = MapData(
        id: 'map',
        name: 'Map',
        size: GridSize(width: 3, height: 3),
        layers: [
          TileLayer(
            id: 'decor',
            name: 'Décor',
            tiles: [0, 0, 0, 0, 0, 0, 0, 0, 0],
          ),
        ],
      );

      final rows = buildLayerPanelPresentationRows(map);

      expect(rows.map((row) => row.layer.id), const ['decor']);
      expect(rows.single.environmentAttachmentLabel, isNull);
      expect(rows.single.isTechnicalEnvironmentSelection, isFalse);
    });

    test('EnvironmentLayer attaché valide est groupé sur le TileLayer cible',
        () {
      final map = _mapWithAttachedEnvironment();

      final rows = buildLayerPanelPresentationRows(map);

      expect(rows.map((row) => row.layer.id), const ['decor', 'objects']);
      expect(rows.first.environmentAttachmentLabel, 'Environnement actif');
      expect(rows.first.attachedEnvironmentLayerIds, const ['env_decor']);
      expect(rows.first.environmentWarningLabel, isNull);
    });

    test('EnvironmentLayer target manquant reste visible avec warning', () {
      final map = _mapWithEnvironmentTarget('missing');

      final rows = buildLayerPanelPresentationRows(map);

      expect(
        rows.map((row) => row.layer.id),
        const ['decor', 'objects', 'env_decor'],
      );
      expect(rows.last.layer, isA<EnvironmentLayer>());
      expect(rows.last.environmentWarningLabel, 'Cible invalide');
    });

    test('EnvironmentLayer target non TileLayer reste visible avec warning',
        () {
      final map = _mapWithEnvironmentTarget('objects');

      final rows = buildLayerPanelPresentationRows(map);

      expect(rows.map((row) => row.layer.id),
          const ['decor', 'objects', 'env_decor']);
      expect(rows.last.layer, isA<EnvironmentLayer>());
      expect(rows.last.environmentWarningLabel, 'Cible invalide');
    });

    test('plusieurs EnvironmentLayers attachés au même TileLayer sont comptés',
        () {
      final map = _mapWithAttachedEnvironment(extraAttached: true);

      final rows = buildLayerPanelPresentationRows(map);

      expect(rows.map((row) => row.layer.id), const ['decor', 'objects']);
      expect(
          rows.first.environmentAttachmentLabel, '2 environnements attachés');
      expect(
        rows.first.attachedEnvironmentLayerIds,
        const ['env_decor', 'env_decor_alt'],
      );
    });

    test('EnvironmentLayer attaché actif reste compréhensible via le TileLayer',
        () {
      final map = _mapWithAttachedEnvironment();

      final rows = buildLayerPanelPresentationRows(
        map,
        activeLayerId: 'env_decor',
      );

      expect(rows.map((row) => row.layer.id), const ['decor', 'objects']);
      expect(rows.first.isActive, isTrue);
      expect(rows.first.isTechnicalEnvironmentSelection, isTrue);
      expect(
        rows.first.technicalEnvironmentSelectionLabel,
        'Environnement technique sélectionné',
      );
    });

    test('ordre des autres layers préservé', () {
      final map = MapData(
        id: 'map',
        name: 'Map',
        size: const GridSize(width: 3, height: 3),
        layers: [
          const CollisionLayer(
            id: 'collision',
            name: 'Collision',
            collisions: [
              false,
              false,
              false,
              false,
              false,
              false,
              false,
              false,
              false
            ],
          ),
          const TileLayer(
            id: 'decor',
            name: 'Décor',
            tiles: [0, 0, 0, 0, 0, 0, 0, 0, 0],
          ),
          _environmentLayer('env_decor', 'decor'),
          const ObjectLayer(id: 'objects', name: 'Objects'),
        ],
      );

      final rows = buildLayerPanelPresentationRows(map);

      expect(
        rows.map((row) => row.layer.id),
        const ['collision', 'decor', 'objects'],
      );
    });
  });
}

MapData _mapWithAttachedEnvironment({bool extraAttached = false}) {
  return MapData(
    id: 'map',
    name: 'Map',
    size: const GridSize(width: 3, height: 3),
    layers: [
      const TileLayer(
        id: 'decor',
        name: 'Décor',
        tiles: [0, 0, 0, 0, 0, 0, 0, 0, 0],
      ),
      _environmentLayer('env_decor', 'decor'),
      if (extraAttached) _environmentLayer('env_decor_alt', 'decor'),
      const ObjectLayer(id: 'objects', name: 'Objects'),
    ],
  );
}

MapData _mapWithEnvironmentTarget(String targetLayerId) {
  return MapData(
    id: 'map',
    name: 'Map',
    size: const GridSize(width: 3, height: 3),
    layers: [
      const TileLayer(
        id: 'decor',
        name: 'Décor',
        tiles: [0, 0, 0, 0, 0, 0, 0, 0, 0],
      ),
      const ObjectLayer(id: 'objects', name: 'Objects'),
      _environmentLayer('env_decor', targetLayerId),
    ],
  );
}

EnvironmentLayer _environmentLayer(String id, String targetLayerId) {
  return MapLayer.environment(
    id: id,
    name: 'Environment — $targetLayerId',
    content: EnvironmentLayerContent(targetTileLayerId: targetLayerId),
  ) as EnvironmentLayer;
}
