part of 'environment_editing.dart';

EnvironmentLayer _environmentLayer(MapData map, String layerId) {
  final layer =
      map.layers.where((candidate) => candidate.id == layerId).firstOrNull;
  if (layer is! EnvironmentLayer) {
    throw semanticFailure(
      'environment.layer_missing',
      'The requested layer is missing or is not an Environment layer.',
      details: {'layerId': layerId},
    );
  }
  return layer;
}

void _requireEditableMask(MapData map, String layerId, String areaId) {
  final area = _environmentLayer(map, layerId).content.areaById(areaId);
  if (area == null) {
    throw semanticFailure('environment.area_missing',
        'The requested Environment area does not exist.',
        details: {'layerId': layerId, 'areaId': areaId});
  }
  if (area.mask.width != map.size.width ||
      area.mask.height != map.size.height) {
    throw semanticFailure('environment.mask_size_invalid',
        'The Environment mask size does not match the map.',
        details: {'layerId': layerId, 'areaId': areaId});
  }
}

EnvironmentPreset _preset(ProjectManifest manifest, String presetId) {
  final preset = manifest.environmentPresets
      .where((candidate) => candidate.id == presetId)
      .firstOrNull;
  if (preset == null) {
    throw semanticFailure(
      'environment.preset_missing',
      'The requested Environment preset does not exist.',
      details: {'presetId': presetId},
    );
  }
  return preset;
}

MapData _attach(
  MapData map, {
  required String layerId,
  required String? targetTileLayerId,
}) {
  if (targetTileLayerId != null) {
    final target = map.layers
        .where((candidate) => candidate.id == targetTileLayerId)
        .firstOrNull;
    if (target is! TileLayer) {
      throw semanticFailure(
        'environment.target_layer_invalid',
        'The Environment target must be an existing Tile layer.',
        details: {'targetTileLayerId': targetTileLayerId},
      );
    }
  }
  return _replaceEnvironmentLayer(
    map,
    layerId,
    (layer) => layer.copyWith(
      content: EnvironmentLayerContent(
        targetTileLayerId: targetTileLayerId,
        areas: layer.content.areas,
      ),
    ),
  );
}

MapData _createArea(
  MapData map, {
  required String layerId,
  required String areaId,
  required String name,
  required String presetId,
  required int seed,
}) =>
    _replaceEnvironmentLayer(
      map,
      layerId,
      (layer) {
        if (layer.content.areaById(areaId) != null) {
          throw semanticFailure(
            'environment.area_exists',
            'An Environment area already uses this ID.',
            details: {'areaId': areaId},
          );
        }
        return layer.copyWith(
          content: EnvironmentLayerContent(
            targetTileLayerId: layer.content.targetTileLayerId,
            areas: [
              ...layer.content.areas,
              EnvironmentArea(
                id: areaId,
                name: name,
                presetId: presetId,
                mask: EnvironmentAreaMask(
                  width: map.size.width,
                  height: map.size.height,
                  cells: List<bool>.filled(
                    map.size.width * map.size.height,
                    false,
                  ),
                ),
                seed: seed,
              ),
            ],
          ),
        );
      },
    );

MapData _deleteArea(
  MapData map, {
  required String layerId,
  required String areaId,
}) {
  final layer = _environmentLayer(map, layerId);
  final area = layer.content.areaById(areaId);
  if (area == null) {
    throw semanticFailure(
      'environment.area_missing',
      'The requested Environment area does not exist.',
      details: {'areaId': areaId},
    );
  }
  final tracked = area.generatedPlacementIds.toSet();
  final withoutPlacements = map.copyWith(
    placedElements: [
      for (final placement in map.placedElements)
        if (!tracked.contains(placement.id)) placement,
    ],
  );
  return _replaceEnvironmentLayer(
    withoutPlacements,
    layerId,
    (current) => current.copyWith(
      content: EnvironmentLayerContent(
        targetTileLayerId: current.content.targetTileLayerId,
        areas: [
          for (final candidate in current.content.areas)
            if (candidate.id != areaId) candidate,
        ],
      ),
    ),
  );
}

MapData _replaceArea(
  MapData map, {
  required String layerId,
  required String areaId,
  required EnvironmentArea Function(EnvironmentArea area) update,
}) =>
    _replaceEnvironmentLayer(
      map,
      layerId,
      (layer) {
        final existing = layer.content.areaById(areaId);
        if (existing == null) {
          throw semanticFailure(
            'environment.area_missing',
            'The requested Environment area does not exist.',
            details: {'areaId': areaId},
          );
        }
        return layer.copyWith(
          content: EnvironmentLayerContent(
            targetTileLayerId: layer.content.targetTileLayerId,
            areas: [
              for (final area in layer.content.areas)
                if (area.id == areaId) update(area) else area,
            ],
          ),
        );
      },
    );

EnvironmentArea _copyArea(
  EnvironmentArea area, {
  String? name,
  String? presetId,
  int? seed,
  EnvironmentGenerationParams? paramsOverride,
  bool clearParamsOverride = false,
  List<String>? generatedPlacementIds,
}) =>
    EnvironmentArea(
      id: area.id,
      name: name ?? area.name,
      presetId: presetId ?? area.presetId,
      mask: area.mask,
      seed: seed ?? area.seed,
      paramsOverride:
          clearParamsOverride ? null : paramsOverride ?? area.paramsOverride,
      generatedPlacementIds:
          generatedPlacementIds ?? area.generatedPlacementIds,
    );

MapData _replaceEnvironmentLayer(
  MapData map,
  String layerId,
  EnvironmentLayer Function(EnvironmentLayer layer) update,
) {
  final existing = _environmentLayer(map, layerId);
  return map.copyWith(
    layers: [
      for (final layer in map.layers)
        if (identical(layer, existing)) update(existing) else layer,
    ],
  );
}

void _requireStableText(String value, String field) {
  if (value.isEmpty || value.trim() != value) {
    throw semanticFailure(
      'environment.request_invalid',
      '$field must be a nonblank trimmed string.',
      details: {'field': field},
    );
  }
}
