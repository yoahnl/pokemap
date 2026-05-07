import 'package:map_core/map_core.dart';

import '../errors/application_errors.dart';
import 'environment_generator_clear_use_cases.dart';

final class ClearTileLayerEnvironmentAreaGeneratedPlacementsResult {
  const ClearTileLayerEnvironmentAreaGeneratedPlacementsResult({
    required this.map,
    required this.tileLayerId,
    required this.environmentLayerId,
    required this.areaId,
    required this.removedPlacementIds,
    required this.clearedReferenceCount,
  });

  final MapData map;
  final String tileLayerId;
  final String environmentLayerId;
  final String areaId;
  final List<String> removedPlacementIds;
  final int clearedReferenceCount;

  int get removedPlacementCount => removedPlacementIds.length;
}

class ClearTileLayerEnvironmentAreaGeneratedPlacementsUseCase {
  ClearTileLayerEnvironmentAreaGeneratedPlacementsResult execute(
    MapData map, {
    required String tileLayerId,
    required String areaId,
  }) {
    final target = _resolveTarget(
      map,
      tileLayerId: tileLayerId,
      areaId: areaId,
    );
    final referenceCount = target.area.generatedPlacementIds.length;
    if (referenceCount == 0) {
      return ClearTileLayerEnvironmentAreaGeneratedPlacementsResult(
        map: map,
        tileLayerId: target.tileLayer.id,
        environmentLayerId: target.environmentLayer.id,
        areaId: target.area.id,
        removedPlacementIds: const [],
        clearedReferenceCount: 0,
      );
    }

    final clear = ClearEnvironmentGeneratedPlacementsUseCase().execute(
      map,
      environmentLayerId: target.environmentLayer.id,
      areaId: target.area.id,
    );
    if (clear.hasErrors) {
      throw EditorValidationException(_firstClearError(clear));
    }

    return ClearTileLayerEnvironmentAreaGeneratedPlacementsResult(
      map: clear.map,
      tileLayerId: target.tileLayer.id,
      environmentLayerId: target.environmentLayer.id,
      areaId: target.area.id,
      removedPlacementIds: [
        for (final placement in clear.clearedPlacements)
          placement.placedElementId,
      ],
      clearedReferenceCount: referenceCount,
    );
  }
}

_TileLayerEnvironmentClearTarget _resolveTarget(
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

  return _TileLayerEnvironmentClearTarget(
    tileLayer: layer,
    environmentLayer: environmentLayer,
    area: area,
  );
}

MapLayer? _findLayerById(MapData map, String layerId) {
  for (final layer in map.layers) {
    if (layer.id == layerId) return layer;
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

String _firstClearError(EnvironmentClearResult result) {
  final issue = result.issues.firstWhere(
    (issue) => issue.severity == EnvironmentClearIssueSeverity.error,
    orElse: () => result.issues.first,
  );
  return issue.message;
}

final class _TileLayerEnvironmentClearTarget {
  const _TileLayerEnvironmentClearTarget({
    required this.tileLayer,
    required this.environmentLayer,
    required this.area,
  });

  final TileLayer tileLayer;
  final EnvironmentLayer environmentLayer;
  final EnvironmentArea area;
}
