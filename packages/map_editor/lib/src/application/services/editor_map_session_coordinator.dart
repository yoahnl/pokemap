import 'package:map_core/map_core.dart';

class EditorMapSessionSelection {
  const EditorMapSessionSelection({
    required this.activeLayerId,
    required this.selectedWarpId,
    required this.selectedTriggerId,
    required this.selectedTilesetEditorId,
  });

  final String? activeLayerId;
  final String? selectedWarpId;
  final String? selectedTriggerId;
  final String? selectedTilesetEditorId;
}

class EditorMapSessionCoordinator {
  const EditorMapSessionCoordinator();

  EditorMapSessionSelection resolveSelectionForMap(
    MapData map, {
    String? preferredLayerId,
    String? preferredWarpId,
    String? preferredTriggerId,
    String? currentSelectedTilesetEditorId,
  }) {
    final activeLayerId = resolveActiveLayerId(
      map,
      preferredLayerId: preferredLayerId,
    );
    final selectedWarpId = resolveSelectedWarpId(
      map,
      preferredWarpId: preferredWarpId,
    );
    final selectedTriggerId = resolveSelectedTriggerId(
      map,
      preferredTriggerId: preferredTriggerId,
    );
    final normalizedCurrentTilesetId = currentSelectedTilesetEditorId?.trim();
    final selectedTilesetEditorId = normalizedCurrentTilesetId != null &&
            normalizedCurrentTilesetId.isNotEmpty
        ? normalizedCurrentTilesetId
        : resolveSelectedTilesetIdForMap(
            map,
            preferredLayerId: activeLayerId,
          );
    return EditorMapSessionSelection(
      activeLayerId: activeLayerId,
      selectedWarpId: selectedWarpId,
      selectedTriggerId: selectedTriggerId,
      selectedTilesetEditorId: selectedTilesetEditorId,
    );
  }

  String? resolveActiveLayerId(
    MapData map, {
    String? preferredLayerId,
  }) {
    if (preferredLayerId != null &&
        map.layers.any((layer) => layer.id == preferredLayerId)) {
      return preferredLayerId;
    }
    for (final layer in map.layers) {
      if (layer is TileLayer) {
        return layer.id;
      }
    }
    if (map.layers.isEmpty) return null;
    return map.layers.first.id;
  }

  String? resolveFallbackLayerIdAfterDeletion(
    MapData map, {
    required int removedIndex,
  }) {
    if (map.layers.isEmpty) return null;
    var candidateIndex = removedIndex;
    if (candidateIndex >= map.layers.length) {
      candidateIndex = map.layers.length - 1;
    }
    final candidateLayer = map.layers[candidateIndex];
    if (candidateLayer is TileLayer) {
      return candidateLayer.id;
    }
    return resolveActiveLayerId(map);
  }

  String? resolveSelectedWarpId(
    MapData map, {
    String? preferredWarpId,
  }) {
    if (preferredWarpId == null) return null;
    final normalized = preferredWarpId.trim();
    if (normalized.isEmpty) return null;
    if (map.warps.any((warp) => warp.id == normalized)) {
      return normalized;
    }
    return null;
  }

  String? resolveSelectedTriggerId(
    MapData map, {
    String? preferredTriggerId,
  }) {
    if (preferredTriggerId == null) return null;
    final normalized = preferredTriggerId.trim();
    if (normalized.isEmpty) return null;
    if (map.triggers.any((trigger) => trigger.id == normalized)) {
      return normalized;
    }
    return null;
  }

  String? resolveSelectedTilesetIdForMap(
    MapData? map, {
    String? preferredLayerId,
  }) {
    if (map == null) return null;
    if (preferredLayerId != null) {
      final preferredLayer = _findLayerById(map, preferredLayerId);
      if (preferredLayer is TileLayer) {
        final preferredTilesetId = preferredLayer.tilesetId?.trim();
        if (preferredTilesetId != null && preferredTilesetId.isNotEmpty) {
          return preferredTilesetId;
        }
      }
    }

    for (final layer in map.layers) {
      if (layer is TileLayer) {
        final tilesetId = layer.tilesetId?.trim();
        if (tilesetId != null && tilesetId.isNotEmpty) {
          return tilesetId;
        }
      }
    }

    final legacyTilesetId = map.tilesetId.trim();
    if (legacyTilesetId.isNotEmpty) {
      return legacyTilesetId;
    }
    return null;
  }

  MapLayer? _findLayerById(MapData map, String layerId) {
    for (final layer in map.layers) {
      if (layer.id == layerId) {
        return layer;
      }
    }
    return null;
  }
}
