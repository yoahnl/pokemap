import 'package:map_core/map_core.dart';

import '../errors/application_errors.dart';

class AddMapLayerResult {
  final MapData map;
  final MapLayer layer;

  AddMapLayerResult(this.map, this.layer);
}

class AddMapLayerUseCase {
  AddMapLayerResult execute(
    MapData map, {
    required MapLayerKind kind,
    required String name,
    String? tileTilesetId,
    int? insertIndex,
  }) {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      throw const EditorValidationException('Layer name cannot be empty');
    }

    final layerId = _generateUniqueLayerId(
      map,
      kind: kind,
      name: normalizedName,
    );

    final updated = addMapLayer(
      map,
      kind: kind,
      id: layerId,
      name: normalizedName,
      tileTilesetId: tileTilesetId,
      insertIndex: insertIndex,
    );
    MapValidator.validate(updated);

    final created = updated.layers.firstWhere((layer) => layer.id == layerId);
    return AddMapLayerResult(updated, created);
  }

  AddMapLayerResult executeSurface(
    MapData map, {
    String name = 'Surfaces',
    int? insertIndex,
  }) {
    final normalizedName = name.trim().isEmpty ? 'Surfaces' : name.trim();
    final layerId = _generateUniqueSurfaceLayerId(map);
    final layerName = _resolveSurfaceLayerName(map, normalizedName);
    final layer = MapLayer.surface(
      id: layerId,
      name: layerName,
    );

    var targetIndex = insertIndex ?? map.layers.length;
    if (targetIndex < 0) targetIndex = 0;
    if (targetIndex > map.layers.length) targetIndex = map.layers.length;

    final updatedLayers = List<MapLayer>.from(map.layers, growable: true)
      ..insert(targetIndex, layer);
    final updated = map.copyWith(layers: updatedLayers);
    MapValidator.validate(updated);
    return AddMapLayerResult(updated, layer);
  }

  String _generateUniqueLayerId(
    MapData map, {
    required MapLayerKind kind,
    required String name,
  }) {
    final existing = map.layers.map((layer) => layer.id).toSet();
    final kindPrefix = switch (kind) {
      MapLayerKind.tile => 'l_tile',
      MapLayerKind.collision => 'l_collision',
      MapLayerKind.terrain => 'l_terrain',
      MapLayerKind.path => 'l_path',
      MapLayerKind.object => 'l_object',
      MapLayerKind.environment => 'l_environment',
    };
    final slug = _slugifyLayerName(name);
    final base = slug.isEmpty ? kindPrefix : '${kindPrefix}_$slug';
    var candidate = base;
    var suffix = 1;
    while (existing.contains(candidate)) {
      candidate = '${base}_$suffix';
      suffix++;
    }
    return candidate;
  }

  String _generateUniqueSurfaceLayerId(MapData map) {
    final existing = map.layers.map((layer) => layer.id).toSet();
    const base = 'surface-main';
    if (!existing.contains(base)) {
      return base;
    }
    var suffix = 2;
    while (existing.contains('surface-$suffix')) {
      suffix++;
    }
    return 'surface-$suffix';
  }

  String _resolveSurfaceLayerName(MapData map, String requestedName) {
    if (requestedName != 'Surfaces') {
      return requestedName;
    }
    final existing = map.layers.map((layer) => layer.name).toSet();
    const base = 'Surfaces';
    if (!existing.contains(base)) {
      return base;
    }
    var suffix = 2;
    while (existing.contains('$base $suffix')) {
      suffix++;
    }
    return '$base $suffix';
  }

  String _slugifyLayerName(String value) {
    final lowered = value.toLowerCase().trim();
    final replaced = lowered.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    final normalized = replaced.replaceAll(RegExp(r'^_+|_+$'), '');
    return normalized;
  }
}

class RenameMapLayerUseCase {
  MapData execute(
    MapData map, {
    required String layerId,
    required String name,
  }) {
    final updated = renameMapLayer(
      map,
      layerId: layerId,
      name: name,
    );
    MapValidator.validate(updated);
    return updated;
  }
}

class DeleteMapLayerUseCase {
  MapData execute(
    MapData map, {
    required String layerId,
  }) {
    final updated = removeMapLayer(map, layerId: layerId);
    MapValidator.validate(updated);
    return updated;
  }
}

class DeleteAllMapLayersUseCase {
  MapData execute(MapData map) {
    final updated = removeAllMapLayers(map);
    MapValidator.validate(updated);
    return updated;
  }
}

class MoveMapLayerUseCase {
  MapData execute(
    MapData map, {
    required String layerId,
    required int direction,
  }) {
    final updated = moveMapLayer(
      map,
      layerId: layerId,
      direction: direction,
    );
    MapValidator.validate(updated);
    return updated;
  }
}

class ReorderMapLayersUseCase {
  MapData execute(
    MapData map, {
    required int oldIndex,
    required int newIndex,
  }) {
    final updated = reorderMapLayers(
      map,
      oldIndex: oldIndex,
      newIndex: newIndex,
    );
    MapValidator.validate(updated);
    return updated;
  }
}

class SetMapLayerVisibilityUseCase {
  MapData execute(
    MapData map, {
    required String layerId,
    required bool isVisible,
  }) {
    final updated = setMapLayerVisibility(
      map,
      layerId: layerId,
      isVisible: isVisible,
    );
    MapValidator.validate(updated);
    return updated;
  }
}

class SetMapLayerOpacityUseCase {
  MapData execute(
    MapData map, {
    required String layerId,
    required double opacity,
  }) {
    final updated = setMapLayerOpacity(
      map,
      layerId: layerId,
      opacity: opacity,
    );
    MapValidator.validate(updated);
    return updated;
  }
}

/// Lot Environment-20 : cible tuile pour un [EnvironmentLayer] (mutation map pure).
class SetEnvironmentLayerTargetTileLayerUseCase {
  MapData execute(
    MapData map, {
    required String environmentLayerId,
    required String? targetTileLayerId,
  }) {
    final envId = environmentLayerId.trim();
    if (envId.isEmpty) {
      throw const EditorValidationException(
          'Environment layer id cannot be empty');
    }

    MapLayer? envLayer;
    for (final layer in map.layers) {
      if (layer.id == envId) {
        envLayer = layer;
        break;
      }
    }
    if (envLayer == null) {
      throw EditorValidationException('Environment layer not found: $envId');
    }
    if (envLayer is! EnvironmentLayer) {
      throw EditorValidationException(
          'Layer is not an environment layer: $envId');
    }

    if (targetTileLayerId == null) {
      final nextContent = EnvironmentLayerContent(
        targetTileLayerId: null,
        areas: envLayer.content.areas,
      );
      try {
        final updated = setEnvironmentLayerContent(
          map,
          layerId: envId,
          content: nextContent,
        );
        MapValidator.validate(updated);
        return updated;
      } on ValidationException catch (e) {
        throw EditorValidationException(e.message);
      }
    }

    final tid = targetTileLayerId.trim();
    if (tid.isEmpty) {
      throw const EditorValidationException(
          'Target tile layer id cannot be empty');
    }
    if (tid == envId) {
      throw const EditorValidationException(
        'Environment layer cannot target itself as targetTileLayerId',
      );
    }

    MapLayer? targetLayer;
    for (final layer in map.layers) {
      if (layer.id == tid) {
        targetLayer = layer;
        break;
      }
    }
    if (targetLayer == null) {
      throw EditorValidationException('Target tile layer not found: $tid');
    }
    if (targetLayer is! TileLayer) {
      throw EditorValidationException(
        'targetTileLayerId must reference a TileLayer, got ${targetLayer.runtimeType}',
      );
    }

    final nextContent = EnvironmentLayerContent(
      targetTileLayerId: tid,
      areas: envLayer.content.areas,
    );
    try {
      final updated = setEnvironmentLayerContent(
        map,
        layerId: envId,
        content: nextContent,
      );
      MapValidator.validate(updated);
      return updated;
    } on ValidationException catch (e) {
      throw EditorValidationException(e.message);
    }
  }
}

/// Masque booléen vide aligné sur [MapData.size] (toutes les cellules inactives).
EnvironmentAreaMask emptyEnvironmentAreaMaskForMap(MapData map) {
  final w = map.size.width;
  final h = map.size.height;
  return EnvironmentAreaMask(
    width: w,
    height: h,
    cells: List<bool>.filled(w * h, false, growable: false),
  );
}

String _slugifyEnvAreaToken(String value) {
  final lowered = value.toLowerCase().trim();
  final replaced = lowered.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  return replaced.replaceAll(RegExp(r'^_+|_+$'), '');
}

String _uniqueEnvironmentAreaId({
  required String presetId,
  required Iterable<String> existingAreaIds,
}) {
  final slug = _slugifyEnvAreaToken(presetId);
  final baseToken = slug.isEmpty ? 'area' : slug;
  final base = 'env_area_$baseToken';
  final existing = existingAreaIds.toSet();
  if (!existing.contains(base)) {
    return base;
  }
  var n = 2;
  while (true) {
    final candidate = '${base}_$n';
    if (!existing.contains(candidate)) {
      return candidate;
    }
    n++;
  }
}

/// Lot Environment-21 : résultat de [AddEnvironmentAreaUseCase].
final class AddEnvironmentAreaResult {
  const AddEnvironmentAreaResult({
    required this.map,
    required this.area,
  });

  final MapData map;
  final EnvironmentArea area;
}

/// Lot Environment-21 : ajoute une [EnvironmentArea] (mask vide, map size).
class AddEnvironmentAreaUseCase {
  AddEnvironmentAreaResult execute(
    MapData map, {
    required ProjectManifest manifest,
    required String environmentLayerId,
    required String presetId,
  }) {
    final envId = environmentLayerId.trim();
    if (envId.isEmpty) {
      throw const EditorValidationException(
        'Environment layer id cannot be empty',
      );
    }
    final pid = presetId.trim();
    if (pid.isEmpty) {
      throw const EditorValidationException('Preset id cannot be empty');
    }

    EnvironmentPreset? preset;
    for (final p in manifest.environmentPresets) {
      if (p.id == pid) {
        preset = p;
        break;
      }
    }
    if (preset == null) {
      throw EditorValidationException('Environment preset not found: $pid');
    }

    MapLayer? envLayer;
    for (final layer in map.layers) {
      if (layer.id == envId) {
        envLayer = layer;
        break;
      }
    }
    if (envLayer == null) {
      throw EditorValidationException('Environment layer not found: $envId');
    }
    if (envLayer is! EnvironmentLayer) {
      throw EditorValidationException(
        'Layer is not an environment layer: $envId',
      );
    }

    final existingIds = envLayer.content.areas.map((a) => a.id).toList();
    final newId = _uniqueEnvironmentAreaId(
      presetId: pid,
      existingAreaIds: existingIds,
    );
    final mask = emptyEnvironmentAreaMaskForMap(map);
    final area = EnvironmentArea(
      id: newId,
      name: preset.name,
      presetId: pid,
      mask: mask,
      seed: 0,
    );

    final nextAreas = <EnvironmentArea>[...envLayer.content.areas, area];
    final nextContent = EnvironmentLayerContent(
      targetTileLayerId: envLayer.content.targetTileLayerId,
      areas: nextAreas,
    );
    try {
      final updated = setEnvironmentLayerContent(
        map,
        layerId: envId,
        content: nextContent,
      );
      MapValidator.validate(updated);
      return AddEnvironmentAreaResult(map: updated, area: area);
    } on ValidationException catch (e) {
      throw EditorValidationException(e.message);
    }
  }
}

/// Lot Environment-21 : change uniquement le [EnvironmentArea.presetId].
class SetEnvironmentAreaPresetUseCase {
  MapData execute(
    MapData map, {
    required ProjectManifest manifest,
    required String environmentLayerId,
    required String areaId,
    required String presetId,
  }) {
    final envId = environmentLayerId.trim();
    if (envId.isEmpty) {
      throw const EditorValidationException(
        'Environment layer id cannot be empty',
      );
    }
    final aid = areaId.trim();
    if (aid.isEmpty) {
      throw const EditorValidationException('Area id cannot be empty');
    }
    final pid = presetId.trim();
    if (pid.isEmpty) {
      throw const EditorValidationException('Preset id cannot be empty');
    }

    EnvironmentPreset? preset;
    for (final p in manifest.environmentPresets) {
      if (p.id == pid) {
        preset = p;
        break;
      }
    }
    if (preset == null) {
      throw EditorValidationException('Environment preset not found: $pid');
    }

    MapLayer? envLayer;
    for (final layer in map.layers) {
      if (layer.id == envId) {
        envLayer = layer;
        break;
      }
    }
    if (envLayer == null) {
      throw EditorValidationException('Environment layer not found: $envId');
    }
    if (envLayer is! EnvironmentLayer) {
      throw EditorValidationException(
        'Layer is not an environment layer: $envId',
      );
    }

    EnvironmentArea? found;
    for (final a in envLayer.content.areas) {
      if (a.id == aid) {
        found = a;
        break;
      }
    }
    if (found == null) {
      throw EditorValidationException('Environment area not found: $aid');
    }

    final updatedArea = EnvironmentArea(
      id: found.id,
      name: found.name,
      presetId: pid,
      mask: found.mask,
      seed: found.seed,
      paramsOverride: found.paramsOverride,
      generatedPlacementIds: found.generatedPlacementIds,
    );

    final nextAreas = envLayer.content.areas
        .map((a) => a.id == aid ? updatedArea : a)
        .toList(growable: false);
    final nextContent = EnvironmentLayerContent(
      targetTileLayerId: envLayer.content.targetTileLayerId,
      areas: nextAreas,
    );
    try {
      final updated = setEnvironmentLayerContent(
        map,
        layerId: envId,
        content: nextContent,
      );
      MapValidator.validate(updated);
      return updated;
    } on ValidationException catch (e) {
      throw EditorValidationException(e.message);
    }
  }
}

/// Lot Environment-21 : retire une [EnvironmentArea] du layer.
class RemoveEnvironmentAreaUseCase {
  MapData execute(
    MapData map, {
    required String environmentLayerId,
    required String areaId,
  }) {
    final envId = environmentLayerId.trim();
    if (envId.isEmpty) {
      throw const EditorValidationException(
        'Environment layer id cannot be empty',
      );
    }
    final aid = areaId.trim();
    if (aid.isEmpty) {
      throw const EditorValidationException('Area id cannot be empty');
    }

    MapLayer? envLayer;
    for (final layer in map.layers) {
      if (layer.id == envId) {
        envLayer = layer;
        break;
      }
    }
    if (envLayer == null) {
      throw EditorValidationException('Environment layer not found: $envId');
    }
    if (envLayer is! EnvironmentLayer) {
      throw EditorValidationException(
        'Layer is not an environment layer: $envId',
      );
    }

    final had = envLayer.content.areas.any((a) => a.id == aid);
    if (!had) {
      throw EditorValidationException('Environment area not found: $aid');
    }

    final nextAreas = envLayer.content.areas
        .where((a) => a.id != aid)
        .toList(growable: false);
    final nextContent = EnvironmentLayerContent(
      targetTileLayerId: envLayer.content.targetTileLayerId,
      areas: nextAreas,
    );
    try {
      final updated = setEnvironmentLayerContent(
        map,
        layerId: envId,
        content: nextContent,
      );
      MapValidator.validate(updated);
      return updated;
    } on ValidationException catch (e) {
      throw EditorValidationException(e.message);
    }
  }
}
