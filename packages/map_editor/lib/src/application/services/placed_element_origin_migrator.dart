import 'package:map_core/map_core.dart';

import 'placed_element_instance_indexer.dart';

enum PlacedElementOriginMigrationReason {
  environmentReference,
  exactTilePattern,
  unmatchedAuthored,
}

final class PlacedElementOriginMigrationEntry {
  const PlacedElementOriginMigrationEntry({
    required this.placementIndex,
    required this.placementId,
    required this.layerId,
    required this.elementId,
    required this.pos,
    required this.previousOrigin,
    required this.proposedOrigin,
    required this.reason,
  });

  final int placementIndex;
  final String placementId;
  final String layerId;
  final String elementId;
  final GridPos pos;
  final String? previousOrigin;
  final String proposedOrigin;
  final PlacedElementOriginMigrationReason reason;

  bool get changesOrigin => previousOrigin != proposedOrigin;
}

final class PlacedElementOriginMigrationPreview {
  PlacedElementOriginMigrationPreview({
    required this.sourceMap,
    required List<PlacedElementOriginMigrationEntry> entries,
  }) : entries = List<PlacedElementOriginMigrationEntry>.unmodifiable(entries);

  final MapData sourceMap;
  final List<PlacedElementOriginMigrationEntry> entries;

  String get mapId => sourceMap.id;

  int get changedCount => entries.where((entry) => entry.changesOrigin).length;

  int countFor(String origin) =>
      entries.where((entry) => entry.proposedOrigin == origin).length;

  PlacedElementOriginMigrationEntry? classificationFor(String placementId) {
    for (final entry in entries) {
      if (entry.placementId == placementId) {
        return entry;
      }
    }
    return null;
  }
}

/// Explicit, one-shot classifier for legacy placement ownership markers.
///
/// This service is intentionally never invoked from map loading. Callers must
/// first present [preview] to the user and may only then pass that exact preview
/// to [apply].
final class PlacedElementOriginMigrator {
  const PlacedElementOriginMigrator({
    PlacedElementInstanceIndexer indexer = const PlacedElementInstanceIndexer(),
  }) : _indexer = indexer;

  final PlacedElementInstanceIndexer _indexer;

  PlacedElementOriginMigrationPreview preview({
    required MapData map,
    required ProjectManifest project,
  }) {
    final environmentIds = _environmentGeneratedPlacementIds(map);
    final indexed = _indexer.syncAllTileLayers(
      map: map.copyWith(placedElements: const <MapPlacedElement>[]),
      project: project,
    );
    final exactTilePatterns = indexed.placedElements
        .where(
          (entry) =>
              entry.properties[pokemapPlacementOriginProperty] ==
              pokemapPlacementOriginTileIndex,
        )
        .map(_patternKey)
        .toSet();

    final entries = <PlacedElementOriginMigrationEntry>[];
    for (var index = 0; index < map.placedElements.length; index += 1) {
      final placement = map.placedElements[index];
      late final String proposedOrigin;
      late final PlacedElementOriginMigrationReason reason;
      if (environmentIds.contains(placement.id)) {
        proposedOrigin = pokemapPlacementOriginEnvironment;
        reason = PlacedElementOriginMigrationReason.environmentReference;
      } else if (exactTilePatterns.contains(_patternKey(placement))) {
        proposedOrigin = pokemapPlacementOriginTileIndex;
        reason = PlacedElementOriginMigrationReason.exactTilePattern;
      } else {
        proposedOrigin = pokemapPlacementOriginAuthored;
        reason = PlacedElementOriginMigrationReason.unmatchedAuthored;
      }
      entries.add(
        PlacedElementOriginMigrationEntry(
          placementIndex: index,
          placementId: placement.id,
          layerId: placement.layerId,
          elementId: placement.elementId,
          pos: placement.pos,
          previousOrigin: placement.properties[pokemapPlacementOriginProperty],
          proposedOrigin: proposedOrigin,
          reason: reason,
        ),
      );
    }

    return PlacedElementOriginMigrationPreview(
      sourceMap: map,
      entries: entries,
    );
  }

  MapData apply({
    required MapData map,
    required PlacedElementOriginMigrationPreview preview,
  }) {
    if (map != preview.sourceMap) {
      throw StateError(
        'Placement origin migration preview is stale for map ${map.id}.',
      );
    }
    if (preview.entries.length != map.placedElements.length) {
      throw StateError(
        'Placement origin migration preview does not match map ${map.id}.',
      );
    }
    if (preview.changedCount == 0) {
      return map;
    }

    final migrated = <MapPlacedElement>[];
    for (var index = 0; index < map.placedElements.length; index += 1) {
      final placement = map.placedElements[index];
      final entry = preview.entries[index];
      if (entry.placementIndex != index ||
          entry.placementId != placement.id ||
          entry.layerId != placement.layerId ||
          entry.elementId != placement.elementId ||
          entry.pos != placement.pos ||
          entry.previousOrigin !=
              placement.properties[pokemapPlacementOriginProperty]) {
        throw StateError(
          'Placement origin migration preview is stale at index $index.',
        );
      }
      migrated.add(
        placement.copyWith(
          properties: <String, String>{
            ...placement.properties,
            pokemapPlacementOriginProperty: entry.proposedOrigin,
          },
        ),
      );
    }
    return map.copyWith(placedElements: migrated);
  }

  Set<String> _environmentGeneratedPlacementIds(MapData map) {
    final ids = <String>{};
    for (final layer in map.layers.whereType<EnvironmentLayer>()) {
      for (final area in layer.content.areas) {
        for (final id in area.generatedPlacementIds) {
          final trimmed = id.trim();
          if (trimmed.isNotEmpty) {
            ids.add(trimmed);
          }
        }
      }
    }
    return ids;
  }

  ({String layerId, String elementId, int x, int y}) _patternKey(
    MapPlacedElement placement,
  ) =>
      (
        layerId: placement.layerId,
        elementId: placement.elementId,
        x: placement.pos.x,
        y: placement.pos.y,
      );
}
