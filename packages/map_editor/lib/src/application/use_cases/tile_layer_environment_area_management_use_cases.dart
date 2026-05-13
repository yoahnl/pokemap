import 'package:map_core/map_core.dart';

import '../errors/application_errors.dart';

final class RenameTileLayerEnvironmentAreaResult {
  const RenameTileLayerEnvironmentAreaResult({
    required this.map,
    required this.tileLayerId,
    required this.environmentLayerId,
    required this.areaId,
    required this.name,
  });

  final MapData map;
  final String tileLayerId;
  final String environmentLayerId;
  final String areaId;
  final String name;
}

final class DeleteTileLayerEnvironmentAreaResult {
  const DeleteTileLayerEnvironmentAreaResult({
    required this.map,
    required this.tileLayerId,
    required this.environmentLayerId,
    required this.deletedAreaId,
    required this.removedPlacementIds,
    required this.clearedReferenceCount,
  });

  final MapData map;
  final String tileLayerId;
  final String environmentLayerId;
  final String deletedAreaId;
  final List<String> removedPlacementIds;
  final int clearedReferenceCount;

  int get removedPlacementCount => removedPlacementIds.length;
}

class RenameTileLayerEnvironmentAreaUseCase {
  RenameTileLayerEnvironmentAreaResult execute(
    MapData map, {
    required String tileLayerId,
    required String areaId,
    required String name,
  }) {
    final nextName = name.trim();
    if (nextName.isEmpty) {
      throw const EditorValidationException(
        'Environment area name cannot be empty',
      );
    }
    final target = _resolveTarget(
      map,
      tileLayerId: tileLayerId,
      areaId: areaId,
    );
    final updatedArea = EnvironmentArea(
      id: target.area.id,
      name: nextName,
      presetId: target.area.presetId,
      mask: target.area.mask,
      seed: target.area.seed,
      paramsOverride: target.area.paramsOverride,
      generatedPlacementIds: target.area.generatedPlacementIds,
    );
    final updated = _replaceEnvironmentLayerAreas(
      map,
      environmentLayer: target.environmentLayer,
      areas: [
        for (final area in target.environmentLayer.content.areas)
          if (area.id == target.area.id) updatedArea else area,
      ],
      placedElements: map.placedElements,
    );
    return RenameTileLayerEnvironmentAreaResult(
      map: updated,
      tileLayerId: target.tileLayer.id,
      environmentLayerId: target.environmentLayer.id,
      areaId: target.area.id,
      name: nextName,
    );
  }
}

class DeleteTileLayerEnvironmentAreaUseCase {
  DeleteTileLayerEnvironmentAreaResult execute(
    MapData map, {
    required String tileLayerId,
    required String areaId,
  }) {
    final target = _resolveTarget(
      map,
      tileLayerId: tileLayerId,
      areaId: areaId,
    );
    final generatedPlacementIds = target.area.generatedPlacementIds.toSet();
    final removedPlacementIds = [
      for (final placed in map.placedElements)
        if (generatedPlacementIds.contains(placed.id)) placed.id,
    ];
    final updated = _replaceEnvironmentLayerAreas(
      map,
      environmentLayer: target.environmentLayer,
      areas: [
        for (final area in target.environmentLayer.content.areas)
          if (area.id != target.area.id) area,
      ],
      placedElements: [
        for (final placed in map.placedElements)
          if (!generatedPlacementIds.contains(placed.id)) placed,
      ],
    );
    return DeleteTileLayerEnvironmentAreaResult(
      map: updated,
      tileLayerId: target.tileLayer.id,
      environmentLayerId: target.environmentLayer.id,
      deletedAreaId: target.area.id,
      removedPlacementIds: removedPlacementIds,
      clearedReferenceCount: target.area.generatedPlacementIds.length,
    );
  }
}

_TileLayerEnvironmentAreaManagementTarget _resolveTarget(
  MapData map, {
  required String tileLayerId,
  required String areaId,
}) {
  final tid = tileLayerId.trim();
  if (tid.isEmpty) {
    throw const EditorValidationException('Tile layer id cannot be empty');
  }
  final aid = areaId.trim();
  if (aid.isEmpty) {
    throw const EditorValidationException(
      'Environment area id cannot be empty',
    );
  }

  final layer = _findLayerById(map, tid);
  if (layer == null) {
    throw EditorValidationException('Tile layer not found: $tid');
  }
  if (layer is! TileLayer) {
    throw EditorValidationException('Layer is not a TileLayer: $tid');
  }

  final environmentLayer = _firstEnvironmentLayerTargeting(map, tid);
  if (environmentLayer == null) {
    throw const EditorValidationException(
      'Activez d’abord l’environnement sur ce layer.',
    );
  }

  final area = environmentLayer.content.areaById(aid);
  if (area == null) {
    throw EditorValidationException('Environment area not found: $aid');
  }

  return _TileLayerEnvironmentAreaManagementTarget(
    tileLayer: layer,
    environmentLayer: environmentLayer,
    area: area,
  );
}

MapData _replaceEnvironmentLayerAreas(
  MapData map, {
  required EnvironmentLayer environmentLayer,
  required List<EnvironmentArea> areas,
  required List<MapPlacedElement> placedElements,
}) {
  final updated = map.copyWith(
    layers: [
      for (final layer in map.layers)
        if (layer is EnvironmentLayer && layer.id == environmentLayer.id)
          MapLayer.environment(
            id: layer.id,
            name: layer.name,
            isVisible: layer.isVisible,
            opacity: layer.opacity,
            content: EnvironmentLayerContent(
              targetTileLayerId: layer.content.targetTileLayerId,
              areas: areas,
            ),
            properties: layer.properties,
          )
        else
          layer,
    ],
    placedElements: placedElements,
  );
  try {
    MapValidator.validate(updated);
    return updated;
  } on ValidationException catch (e) {
    throw EditorValidationException(e.message);
  }
}

MapLayer? _findLayerById(MapData map, String layerId) {
  for (final layer in map.layers) {
    if (layer.id == layerId) {
      return layer;
    }
  }
  return null;
}

EnvironmentLayer? _firstEnvironmentLayerTargeting(
  MapData map,
  String tileLayerId,
) {
  for (final layer in map.layers) {
    if (layer is EnvironmentLayer &&
        layer.content.targetTileLayerId?.trim() == tileLayerId) {
      return layer;
    }
  }
  return null;
}

final class _TileLayerEnvironmentAreaManagementTarget {
  const _TileLayerEnvironmentAreaManagementTarget({
    required this.tileLayer,
    required this.environmentLayer,
    required this.area,
  });

  final TileLayer tileLayer;
  final EnvironmentLayer environmentLayer;
  final EnvironmentArea area;
}
