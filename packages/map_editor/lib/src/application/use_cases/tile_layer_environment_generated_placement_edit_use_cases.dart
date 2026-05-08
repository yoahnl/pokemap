import 'package:map_core/map_core.dart';

import '../errors/application_errors.dart';
import '../services/environment_generated_placement_hover_resolver.dart';

final class DeleteTileLayerEnvironmentGeneratedPlacementResult {
  const DeleteTileLayerEnvironmentGeneratedPlacementResult({
    required this.map,
    required this.tileLayerId,
    required this.environmentLayerId,
    required this.areaId,
    required this.removedPlacementId,
  });

  final MapData map;
  final String tileLayerId;
  final String environmentLayerId;
  final String areaId;
  final String? removedPlacementId;

  bool get removed => removedPlacementId != null;
}

class DeleteTileLayerEnvironmentGeneratedPlacementAtUseCase {
  DeleteTileLayerEnvironmentGeneratedPlacementResult execute(
    MapData map, {
    required ProjectManifest? manifest,
    required String tileLayerId,
    required String areaId,
    required GridPos pos,
  }) {
    final target = _resolveTarget(
      map,
      tileLayerId: tileLayerId,
      areaId: areaId,
    );
    final deleteTarget = resolveEnvironmentGeneratedPlacementDeleteTarget(
      map: map,
      manifest: manifest,
      activeLayerId: target.environmentLayer.id,
      selectedAreaId: target.area.id,
      pos: pos,
    );
    if (deleteTarget == null) {
      return DeleteTileLayerEnvironmentGeneratedPlacementResult(
        map: map,
        tileLayerId: target.tileLayer.id,
        environmentLayerId: target.environmentLayer.id,
        areaId: target.area.id,
        removedPlacementId: null,
      );
    }

    final updated = _deleteGeneratedPlacement(
      map,
      environmentLayerId: target.environmentLayer.id,
      areaId: target.area.id,
      placedElementId: deleteTarget.placed.id,
    );
    MapValidator.validate(updated, projectDialogueContext: manifest);
    return DeleteTileLayerEnvironmentGeneratedPlacementResult(
      map: updated,
      tileLayerId: target.tileLayer.id,
      environmentLayerId: target.environmentLayer.id,
      areaId: target.area.id,
      removedPlacementId: deleteTarget.placed.id,
    );
  }
}

_TileLayerEnvironmentGeneratedPlacementEditTarget _resolveTarget(
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

  return _TileLayerEnvironmentGeneratedPlacementEditTarget(
    tileLayer: layer,
    environmentLayer: environmentLayer,
    area: area,
  );
}

MapData _deleteGeneratedPlacement(
  MapData map, {
  required String environmentLayerId,
  required String areaId,
  required String placedElementId,
}) {
  return map.copyWith(
    layers: [
      for (final layer in map.layers)
        if (layer is EnvironmentLayer && layer.id == environmentLayerId)
          MapLayer.environment(
            id: layer.id,
            name: layer.name,
            isVisible: layer.isVisible,
            opacity: layer.opacity,
            content: EnvironmentLayerContent(
              targetTileLayerId: layer.content.targetTileLayerId,
              areas: [
                for (final area in layer.content.areas)
                  if (area.id == areaId)
                    EnvironmentArea(
                      id: area.id,
                      name: area.name,
                      presetId: area.presetId,
                      mask: area.mask,
                      seed: area.seed,
                      paramsOverride: area.paramsOverride,
                      generatedPlacementIds: [
                        for (final id in area.generatedPlacementIds)
                          if (id != placedElementId) id,
                      ],
                    )
                  else
                    area,
              ],
            ),
            properties: layer.properties,
          )
        else
          layer,
    ],
    placedElements: [
      for (final placed in map.placedElements)
        if (placed.id != placedElementId) placed,
    ],
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

final class _TileLayerEnvironmentGeneratedPlacementEditTarget {
  const _TileLayerEnvironmentGeneratedPlacementEditTarget({
    required this.tileLayer,
    required this.environmentLayer,
    required this.area,
  });

  final TileLayer tileLayer;
  final EnvironmentLayer environmentLayer;
  final EnvironmentArea area;
}
