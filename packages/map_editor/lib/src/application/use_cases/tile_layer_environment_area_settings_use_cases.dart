import 'package:map_core/map_core.dart';

import '../errors/application_errors.dart';

class SetTileLayerEnvironmentAreaParamsOverrideUseCase {
  MapData execute(
    MapData map, {
    required String tileLayerId,
    required String areaId,
    required EnvironmentGenerationParams paramsOverride,
  }) {
    final target = _resolveTarget(
      map,
      tileLayerId: tileLayerId,
      areaId: areaId,
    );
    return _replaceTargetArea(
      map,
      environmentLayer: target.environmentLayer,
      areaId: target.area.id,
      updatedArea: EnvironmentArea(
        id: target.area.id,
        name: target.area.name,
        presetId: target.area.presetId,
        mask: target.area.mask,
        seed: target.area.seed,
        paramsOverride: paramsOverride,
        generatedPlacementIds: target.area.generatedPlacementIds,
      ),
    );
  }
}

class ResetTileLayerEnvironmentAreaParamsOverrideUseCase {
  MapData execute(
    MapData map, {
    required String tileLayerId,
    required String areaId,
  }) {
    final target = _resolveTarget(
      map,
      tileLayerId: tileLayerId,
      areaId: areaId,
    );
    return _replaceTargetArea(
      map,
      environmentLayer: target.environmentLayer,
      areaId: target.area.id,
      updatedArea: EnvironmentArea(
        id: target.area.id,
        name: target.area.name,
        presetId: target.area.presetId,
        mask: target.area.mask,
        seed: target.area.seed,
        generatedPlacementIds: target.area.generatedPlacementIds,
      ),
    );
  }
}

class SetTileLayerEnvironmentAreaSeedForTileLayerUseCase {
  MapData execute(
    MapData map, {
    required String tileLayerId,
    required String areaId,
    required int seed,
  }) {
    if (seed < 0) {
      throw const EditorValidationException(
          'EnvironmentArea seed must be >= 0');
    }
    final target = _resolveTarget(
      map,
      tileLayerId: tileLayerId,
      areaId: areaId,
    );
    return _replaceTargetArea(
      map,
      environmentLayer: target.environmentLayer,
      areaId: target.area.id,
      updatedArea: EnvironmentArea(
        id: target.area.id,
        name: target.area.name,
        presetId: target.area.presetId,
        mask: target.area.mask,
        seed: seed,
        paramsOverride: target.area.paramsOverride,
        generatedPlacementIds: target.area.generatedPlacementIds,
      ),
    );
  }
}

_TileLayerEnvironmentAreaTarget _resolveTarget(
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
        'Environment area id cannot be empty');
  }

  final tileLayer = _findLayerById(map, tid);
  if (tileLayer == null) {
    throw EditorValidationException('Tile layer not found: $tid');
  }
  if (tileLayer is! TileLayer) {
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

  return _TileLayerEnvironmentAreaTarget(
    environmentLayer: environmentLayer,
    area: area,
  );
}

MapData _replaceTargetArea(
  MapData map, {
  required EnvironmentLayer environmentLayer,
  required String areaId,
  required EnvironmentArea updatedArea,
}) {
  final nextAreas = [
    for (final area in environmentLayer.content.areas)
      if (area.id == areaId) updatedArea else area,
  ];
  final nextContent = EnvironmentLayerContent(
    targetTileLayerId: environmentLayer.content.targetTileLayerId,
    areas: nextAreas,
  );

  try {
    final updated = setEnvironmentLayerContent(
      map,
      layerId: environmentLayer.id,
      content: nextContent,
    );
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

final class _TileLayerEnvironmentAreaTarget {
  const _TileLayerEnvironmentAreaTarget({
    required this.environmentLayer,
    required this.area,
  });

  final EnvironmentLayer environmentLayer;
  final EnvironmentArea area;
}
