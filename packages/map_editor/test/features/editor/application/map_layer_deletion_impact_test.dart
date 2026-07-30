import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/application/map_layer_deletion_impact.dart';

void main() {
  group('MapLayerDeletionImpactProjector', () {
    test('fails explicitly when the requested layer does not exist', () {
      expect(
        () => const MapLayerDeletionImpactProjector().project(
          map: _baseMap(),
          layerId: 'missing',
        ),
        throwsArgumentError,
      );
    });

    test('counts removed placements and sorted MapEvent ids', () {
      final impact = const MapLayerDeletionImpactProjector().project(
        map: _baseMap(
          placedElements: const [
            MapPlacedElement(
              id: 'manual_b',
              layerId: 'decor',
              elementId: 'tree',
              pos: GridPos(x: 0, y: 0),
            ),
            MapPlacedElement(
              id: 'manual_a',
              layerId: 'decor',
              elementId: 'rock',
              pos: GridPos(x: 1, y: 0),
            ),
            MapPlacedElement(
              id: 'kept',
              layerId: 'objects',
              elementId: 'lamp',
              pos: GridPos(x: 2, y: 0),
            ),
          ],
          events: const [
            MapEventDefinition(
              id: 'event_z',
              pages: [MapEventPage(pageNumber: 0)],
              position: EventPosition(layerId: 'decor', x: 0, y: 0),
            ),
            MapEventDefinition(
              id: 'event_a',
              pages: [MapEventPage(pageNumber: 0)],
              position: EventPosition(layerId: 'decor', x: 1, y: 0),
            ),
          ],
        ),
        layerId: 'decor',
      );

      expect(impact.layerId, 'decor');
      expect(impact.placedElementCount, 2);
      expect(impact.affectedMapEventIds, const ['event_a', 'event_z']);
      expect(
        impact.blockingReasons,
        contains(
          'Impossible de supprimer ce layer : 2 événements de map y sont attachés.',
        ),
      );
      expect(
        () => impact.affectedMapEventIds.add('event_x'),
        throwsUnsupportedError,
      );
      expect(
        () => impact.blockingReasons.clear(),
        throwsUnsupportedError,
      );
    });

    test('counts valid Environment attachments with the canonical reason', () {
      final map = _baseMap(
        layers: [
          _tile('decor'),
          _environment(
            id: 'forest',
            targetLayerId: 'decor',
            generatedIds: const ['generated_tree', 'generated_tree'],
          ),
          _environment(id: 'orphan', targetLayerId: 'missing'),
          const ObjectLayer(id: 'objects', name: 'Objects'),
        ],
        placedElements: const [
          MapPlacedElement(
            id: 'generated_tree',
            layerId: 'decor',
            elementId: 'tree',
            pos: GridPos(x: 0, y: 0),
          ),
        ],
      );

      final impact = const MapLayerDeletionImpactProjector().project(
        map: map,
        layerId: 'decor',
      );

      expect(impact.environmentAttachmentCount, 1);
      expect(impact.environmentGeneratedCount, 1);
      expect(
        impact.blockingReasons,
        contains(
          'Impossible de supprimer ce layer : un environnement lui est attaché.',
        ),
      );
    });

    test('blocks generated members orphaned by deleting their Environment', () {
      final map = _baseMap(
        layers: [
          _tile('decor'),
          _environment(
            id: 'forest',
            targetLayerId: 'decor',
            generatedIds: const ['generated_tree', 'missing_generated'],
          ),
          const ObjectLayer(id: 'objects', name: 'Objects'),
        ],
        placedElements: const [
          MapPlacedElement(
            id: 'generated_tree',
            layerId: 'decor',
            elementId: 'tree',
            pos: GridPos(x: 0, y: 0),
          ),
        ],
      );

      final impact = const MapLayerDeletionImpactProjector().project(
        map: map,
        layerId: 'forest',
      );

      expect(impact.environmentGeneratedCount, 1);
      expect(
        impact.blockingReasons,
        contains(
          'Impossible de supprimer ce layer : 1 élément généré deviendrait orphelin.',
        ),
      );
    });

    test('deduplicates surviving Environment references to removed placements',
        () {
      final map = _baseMap(
        layers: [
          _tile('decor'),
          _environment(
            id: 'forest_a',
            targetLayerId: 'decor',
            generatedIds: const ['generated_tree'],
          ),
          _environment(
            id: 'forest_b',
            targetLayerId: 'decor',
            generatedIds: const ['generated_tree'],
          ),
          const ObjectLayer(id: 'objects', name: 'Objects'),
        ],
        placedElements: const [
          MapPlacedElement(
            id: 'generated_tree',
            layerId: 'decor',
            elementId: 'tree',
            pos: GridPos(x: 0, y: 0),
          ),
        ],
      );

      final impact = const MapLayerDeletionImpactProjector().project(
        map: map,
        layerId: 'decor',
      );

      expect(impact.environmentGeneratedCount, 1);
      expect(
        impact.blockingReasons,
        contains(
          'Impossible de supprimer ce layer : 1 élément généré deviendrait orphelin.',
        ),
      );
    });

    test('keeps an orphan Environment without generated members deletable', () {
      final impact = const MapLayerDeletionImpactProjector().project(
        map: _baseMap(
          layers: [
            _tile('decor'),
            _environment(id: 'orphan', targetLayerId: 'missing'),
          ],
        ),
        layerId: 'orphan',
      );

      expect(impact.placedElementCount, 0);
      expect(impact.environmentGeneratedCount, 0);
      expect(impact.environmentAttachmentCount, 0);
      expect(impact.affectedMapEventIds, isEmpty);
      expect(impact.blockingReasons, isEmpty);
    });
  });
}

MapData _baseMap({
  List<MapLayer>? layers,
  List<MapPlacedElement> placedElements = const [],
  List<MapEventDefinition> events = const [],
}) {
  return MapData(
    id: 'map',
    name: 'Map',
    size: const GridSize(width: 3, height: 3),
    layers: layers ??
        [
          _tile('decor'),
          const ObjectLayer(id: 'objects', name: 'Objects'),
        ],
    placedElements: placedElements,
    events: events,
  );
}

TileLayer _tile(String id) {
  return TileLayer(
    id: id,
    name: id,
    tiles: List<int>.filled(9, 0),
  );
}

EnvironmentLayer _environment({
  required String id,
  required String targetLayerId,
  List<String> generatedIds = const [],
}) {
  final uniqueGeneratedIds = generatedIds.toSet().toList(growable: false);
  return MapLayer.environment(
    id: id,
    name: id,
    content: EnvironmentLayerContent(
      targetTileLayerId: targetLayerId,
      areas: [
        EnvironmentArea(
          id: '${id}_area',
          name: 'Area',
          presetId: 'forest',
          mask: EnvironmentAreaMask(
            width: 3,
            height: 3,
            cells: List<bool>.filled(9, true),
          ),
          seed: 1,
          generatedPlacementIds: uniqueGeneratedIds,
        ),
      ],
    ),
  ) as EnvironmentLayer;
}
