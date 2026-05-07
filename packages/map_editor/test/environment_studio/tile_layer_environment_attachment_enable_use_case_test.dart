import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/use_cases/tile_layer_environment_attachment_use_cases.dart';

void main() {
  group('EnableTileLayerEnvironmentAttachmentUseCase', () {
    test('crée un EnvironmentLayer attaché à un TileLayer sans environnement',
        () {
      final result = _useCase.execute(_map(), tileLayerId: 'tiles');

      expect(result.created, isTrue);
      expect(result.alreadyAttached, isFalse);
      expect(result.tileLayerId, 'tiles');
      expect(result.environmentLayerId, startsWith('l_environment_ground'));

      final envLayer = result.map.layers[1] as EnvironmentLayer;
      expect(envLayer.id, result.environmentLayerId);
      expect(envLayer.name, 'Environnement - Ground');
      expect(envLayer.content.targetTileLayerId, 'tiles');
      expect(envLayer.content.areas, isEmpty);
    });

    test('insère le nouvel EnvironmentLayer juste après le TileLayer ciblé',
        () {
      final result = _useCase.execute(
        _map(
          layers: const [
            TileLayer(id: 'base', name: 'Base', tiles: [0, 0, 0, 0]),
            TileLayer(id: 'tiles', name: 'Ground', tiles: [0, 0, 0, 0]),
            ObjectLayer(id: 'objects', name: 'Objects'),
          ],
        ),
        tileLayerId: 'tiles',
      );

      expect(
        result.map.layers.map((layer) => layer.id),
        ['base', 'tiles', result.environmentLayerId, 'objects'],
      );
    });

    test('ne recrée rien si un EnvironmentLayer cible déjà le TileLayer', () {
      final map = _map(
        layers: [
          const TileLayer(id: 'tiles', name: 'Ground', tiles: [0, 0, 0, 0]),
          MapLayer.environment(
            id: 'env_existing',
            name: 'Environment',
            content: EnvironmentLayerContent(
              targetTileLayerId: 'tiles',
            ),
          ),
        ],
      );

      final result = _useCase.execute(map, tileLayerId: 'tiles');

      expect(result.created, isFalse);
      expect(result.alreadyAttached, isTrue);
      expect(result.map, same(map));
      expect(result.environmentLayerId, 'env_existing');
      expect(result.map.layers.length, 2);
    });

    test('refuse un layer introuvable', () {
      expect(
        () => _useCase.execute(_map(), tileLayerId: 'missing'),
        throwsA(isA<EditorValidationException>()),
      );
    });

    test('refuse un layer non TileLayer', () {
      expect(
        () => _useCase.execute(
          _map(
            layers: const [
              ObjectLayer(id: 'objects', name: 'Objects'),
            ],
          ),
          tileLayerId: 'objects',
        ),
        throwsA(isA<EditorValidationException>()),
      );
    });

    test('préserve les autres layers et les placedElements', () {
      const placed = MapPlacedElement(
        id: 'placed',
        layerId: 'tiles',
        elementId: 'tree',
        pos: GridPos(x: 1, y: 1),
      );
      final map = _map(
        layers: const [
          TileLayer(id: 'tiles', name: 'Ground', tiles: [0, 0, 0, 0]),
          ObjectLayer(id: 'objects', name: 'Objects'),
        ],
        placedElements: [placed],
      );

      final result = _useCase.execute(map, tileLayerId: 'tiles');

      expect(result.map.layers.first, map.layers.first);
      expect(result.map.layers.last, map.layers.last);
      expect(result.map.placedElements, [placed]);
      expect(
        result.map.layers.whereType<EnvironmentLayer>().single.content.areas,
        isEmpty,
      );
      expect(result.map.placedElements.length, 1);
    });

    test('génère un id unique si un layer environnement porte déjà le base id',
        () {
      final result = _useCase.execute(
        _map(
          layers: [
            const TileLayer(id: 'tiles', name: 'Ground', tiles: [0, 0, 0, 0]),
            const EnvironmentLayer(
              id: 'l_environment_ground',
              name: 'Legacy',
            ),
          ],
        ),
        tileLayerId: 'tiles',
      );

      expect(result.environmentLayerId, 'l_environment_ground_2');
    });
  });
}

final _useCase = EnableTileLayerEnvironmentAttachmentUseCase();

MapData _map({
  List<MapLayer>? layers,
  List<MapPlacedElement> placedElements = const [],
}) {
  return MapData(
    id: 'map',
    name: 'Map',
    size: const GridSize(width: 2, height: 2),
    layers: layers ??
        const [
          TileLayer(id: 'tiles', name: 'Ground', tiles: [0, 0, 0, 0]),
          ObjectLayer(id: 'objects', name: 'Objects'),
        ],
    placedElements: placedElements,
  );
}
