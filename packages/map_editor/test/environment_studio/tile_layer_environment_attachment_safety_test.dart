import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/services/environment_layer_tile_layer_attachment_resolver.dart';
import 'package:map_editor/src/application/use_cases/layer_use_cases.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';

void main() {
  group('validEnvironmentLayerAttachmentsForTileLayer', () {
    test('détecte les EnvironmentLayers attachés valides en ordre de layer',
        () {
      final map = _mapWithAttachedEnvironment(extraAttached: true);

      final attachments = validEnvironmentLayerAttachmentsForTileLayer(
        map,
        ' decor ',
      );

      expect(
        attachments.map((layer) => layer.id),
        ['env_decor', 'env_decor_alt'],
      );
    });

    test('ignore les targets nulles, manquantes, non TileLayer et différentes',
        () {
      final map = MapData(
        id: 'map',
        name: 'Map',
        size: const GridSize(width: 3, height: 3),
        layers: [
          _tileLayer('decor'),
          const ObjectLayer(id: 'objects', name: 'Objects'),
          _environmentLayer(id: 'env_null', targetLayerId: null),
          _environmentLayer(id: 'env_missing', targetLayerId: 'missing'),
          _environmentLayer(id: 'env_object', targetLayerId: 'objects'),
          _tileLayer('other_tile'),
          _environmentLayer(id: 'env_other', targetLayerId: 'other_tile'),
        ],
      );

      final attachments = validEnvironmentLayerAttachmentsForTileLayer(
        map,
        'decor',
      );

      expect(attachments, isEmpty);
    });

    test('retourne vide pour un id vide, manquant ou non TileLayer', () {
      final map = _mapWithAttachedEnvironment();

      expect(
        validEnvironmentLayerAttachmentsForTileLayer(map, '   '),
        isEmpty,
      );
      expect(
        validEnvironmentLayerAttachmentsForTileLayer(map, 'missing'),
        isEmpty,
      );
      expect(
        validEnvironmentLayerAttachmentsForTileLayer(map, 'objects'),
        isEmpty,
      );
    });
  });

  group('DeleteMapLayerUseCase attachment safety', () {
    test('refuse la suppression d’un TileLayer avec EnvironmentLayer attaché',
        () {
      final map = _mapWithAttachedEnvironment();

      expect(
        () => DeleteMapLayerUseCase().execute(map, layerId: 'decor'),
        throwsA(
          isA<EditorValidationException>().having(
            (error) => error.message,
            'message',
            contains('environnement lui est attaché'),
          ),
        ),
      );
      expect(map.layers.map((layer) => layer.id),
          ['decor', 'env_decor', 'objects']);
    });

    test('autorise la suppression d’un TileLayer sans EnvironmentLayer attaché',
        () {
      final map = _mapWithoutAttachedEnvironment();

      final updated = DeleteMapLayerUseCase().execute(
        map,
        layerId: 'decor',
      );

      expect(updated.layers.map((layer) => layer.id), ['objects']);
      expect(updated.placedElements, isEmpty);
    });

    test('autorise la suppression d’un EnvironmentLayer invalide', () {
      final map = _mapWithInvalidEnvironment();

      final updated = DeleteMapLayerUseCase().execute(
        map,
        layerId: 'env_missing',
      );

      expect(updated.layers.map((layer) => layer.id), ['decor']);
    });
  });

  group('EditorNotifier attachment safety', () {
    test('bloque la suppression d’un TileLayer avec environnement attaché', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final map = _mapWithAttachedEnvironment();
      notifier.state = EditorState(
        activeMap: map,
        activeLayerId: 'decor',
      );

      notifier.deleteMapLayer('decor');

      final state = notifier.state;
      expect(state.activeMap, same(map));
      expect(state.activeLayerId, 'decor');
      expect(state.errorMessage, contains('environnement lui est attaché'));
    });

    test('la suppression d’un TileLayer sans environnement reste inchangée',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final map = _mapWithoutAttachedEnvironment();
      notifier.state = EditorState(
        activeMap: map,
        activeLayerId: 'decor',
      );

      notifier.deleteMapLayer('decor');

      final state = notifier.state;
      expect(state.activeMap!.layers.map((layer) => layer.id), ['objects']);
      expect(state.activeMap!.placedElements, isEmpty);
      expect(state.errorMessage, isNull);
    });

    test('la suppression d’un EnvironmentLayer invalide reste possible', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final map = _mapWithInvalidEnvironment();
      notifier.state = EditorState(
        activeMap: map,
        activeLayerId: 'env_missing',
      );

      notifier.deleteMapLayer('env_missing');

      final state = notifier.state;
      expect(state.activeMap!.layers.map((layer) => layer.id), ['decor']);
      expect(state.errorMessage, isNull);
    });
  });
}

MapData _mapWithAttachedEnvironment({bool extraAttached = false}) {
  return MapData(
    id: 'map',
    name: 'Map',
    size: const GridSize(width: 3, height: 3),
    layers: [
      _tileLayer('decor'),
      _environmentLayer(id: 'env_decor', targetLayerId: 'decor'),
      if (extraAttached)
        _environmentLayer(id: 'env_decor_alt', targetLayerId: 'decor'),
      const ObjectLayer(id: 'objects', name: 'Objects'),
    ],
    placedElements: const [
      MapPlacedElement(
        id: 'tree',
        layerId: 'decor',
        elementId: 'tree',
        pos: GridPos(x: 1, y: 1),
      ),
    ],
  );
}

MapData _mapWithoutAttachedEnvironment() {
  return MapData(
    id: 'map',
    name: 'Map',
    size: const GridSize(width: 3, height: 3),
    layers: [
      _tileLayer('decor'),
      const ObjectLayer(id: 'objects', name: 'Objects'),
    ],
    placedElements: const [
      MapPlacedElement(
        id: 'tree',
        layerId: 'decor',
        elementId: 'tree',
        pos: GridPos(x: 1, y: 1),
      ),
    ],
  );
}

MapData _mapWithInvalidEnvironment() {
  return MapData(
    id: 'map',
    name: 'Map',
    size: const GridSize(width: 3, height: 3),
    layers: [
      _tileLayer('decor'),
      _environmentLayer(id: 'env_missing', targetLayerId: 'missing'),
    ],
  );
}

TileLayer _tileLayer(String id) {
  return TileLayer(
    id: id,
    name: id,
    tiles: const [0, 0, 0, 0, 0, 0, 0, 0, 0],
  );
}

EnvironmentLayer _environmentLayer({
  required String id,
  required String? targetLayerId,
}) {
  return MapLayer.environment(
    id: id,
    name: id,
    content: EnvironmentLayerContent(targetTileLayerId: targetLayerId),
  ) as EnvironmentLayer;
}
