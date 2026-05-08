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

final class AddTileLayerEnvironmentGeneratedPlacementResult {
  const AddTileLayerEnvironmentGeneratedPlacementResult({
    required this.map,
    required this.tileLayerId,
    required this.environmentLayerId,
    required this.areaId,
    required this.addedPlacementId,
  });

  final MapData map;
  final String tileLayerId;
  final String environmentLayerId;
  final String areaId;
  final String addedPlacementId;

  bool get added => addedPlacementId.isNotEmpty;
}

class AddTileLayerEnvironmentGeneratedPlacementAtUseCase {
  AddTileLayerEnvironmentGeneratedPlacementResult execute(
    MapData map, {
    required ProjectManifest manifest,
    required String tileLayerId,
    required String areaId,
    required String elementId,
    required GridPos pos,
  }) {
    final target = _resolveTarget(
      map,
      tileLayerId: tileLayerId,
      areaId: areaId,
    );
    if (target.area.generatedPlacementIds.isEmpty) {
      throw const EditorValidationException(
        'Generate the environment area before adding individual placements',
      );
    }

    final preset = _findEnvironmentPreset(manifest, target.area.presetId);
    if (preset == null) {
      throw EditorValidationException(
        'Environment preset not found: ${target.area.presetId}',
      );
    }
    final eid = elementId.trim();
    if (eid.isEmpty) {
      throw const EditorValidationException('Element id cannot be empty');
    }
    final paletteItem = _paletteItemByElementId(preset, eid);
    if (paletteItem == null) {
      throw EditorValidationException(
        'Element is not in environment preset palette: $eid',
      );
    }
    final element = _projectElementById(manifest, eid);
    if (element == null) {
      throw EditorValidationException('Project element not found: $eid');
    }
    final targetTilesetId = _effectiveTileLayerTilesetId(
      target.tileLayer,
      map,
    );
    final elementTilesetId = _elementPrimaryTilesetId(element);
    if (targetTilesetId.isNotEmpty &&
        elementTilesetId.isNotEmpty &&
        targetTilesetId != elementTilesetId) {
      throw EditorValidationException(
        'Element tileset $elementTilesetId does not match TileLayer tileset $targetTilesetId',
      );
    }

    final footprint = _elementFootprint(element);
    if (!_elementFootprintInBounds(
      pos: pos,
      footprint: footprint,
      mapSize: map.size,
    )) {
      throw const EditorValidationException(
        'Generated placement footprint is outside map bounds',
      );
    }

    final placedId = _uniqueGeneratedEnvironmentPlacementId(
      map,
      area: target.area,
      pos: pos,
      elementId: paletteItem.elementId,
    );
    final placed = MapPlacedElement(
      id: placedId,
      layerId: target.tileLayer.id,
      elementId: paletteItem.elementId,
      pos: pos,
      applyCollision: _applyCollisionFromEnvironmentMode(
        paletteItem.collisionMode,
      ),
    );
    final updated = _addGeneratedPlacement(
      map,
      environmentLayerId: target.environmentLayer.id,
      areaId: target.area.id,
      placed: placed,
    );
    MapValidator.validate(updated, projectDialogueContext: manifest);
    return AddTileLayerEnvironmentGeneratedPlacementResult(
      map: updated,
      tileLayerId: target.tileLayer.id,
      environmentLayerId: target.environmentLayer.id,
      areaId: target.area.id,
      addedPlacementId: placed.id,
    );
  }
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

MapData _addGeneratedPlacement(
  MapData map, {
  required String environmentLayerId,
  required String areaId,
  required MapPlacedElement placed,
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
                        ...area.generatedPlacementIds,
                        placed.id,
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
      ...map.placedElements,
      placed,
    ],
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

EnvironmentPreset? _findEnvironmentPreset(
  ProjectManifest manifest,
  String presetId,
) {
  final normalizedId = presetId.trim();
  for (final preset in manifest.environmentPresets) {
    if (preset.id == normalizedId) return preset;
  }
  return null;
}

EnvironmentPaletteItem? _paletteItemByElementId(
  EnvironmentPreset preset,
  String elementId,
) {
  final normalizedId = elementId.trim();
  for (final item in preset.palette) {
    if (item.elementId == normalizedId) return item;
  }
  return null;
}

ProjectElementEntry? _projectElementById(
  ProjectManifest manifest,
  String elementId,
) {
  final normalizedId = elementId.trim();
  for (final element in manifest.elements) {
    if (element.id == normalizedId) return element;
  }
  return null;
}

GridSize _elementFootprint(ProjectElementEntry element) {
  final source = element.frames.primarySource;
  return GridSize(
    width: source.width <= 0 ? 1 : source.width,
    height: source.height <= 0 ? 1 : source.height,
  );
}

bool _elementFootprintInBounds({
  required GridPos pos,
  required GridSize footprint,
  required GridSize mapSize,
}) {
  return pos.x >= 0 &&
      pos.y >= 0 &&
      pos.x + footprint.width <= mapSize.width &&
      pos.y + footprint.height <= mapSize.height;
}

String _effectiveTileLayerTilesetId(TileLayer layer, MapData map) {
  return (layer.tilesetId ?? map.tilesetId).trim();
}

String _elementPrimaryTilesetId(ProjectElementEntry element) {
  final frameTilesetId = element.frames.primaryFrame.tilesetId.trim();
  if (frameTilesetId.isNotEmpty) return frameTilesetId;
  return element.tilesetId.trim();
}

bool _applyCollisionFromEnvironmentMode(EnvironmentCollisionMode mode) {
  switch (mode) {
    case EnvironmentCollisionMode.forceEnabled:
      return true;
    case EnvironmentCollisionMode.forceDisabled:
      return false;
    case EnvironmentCollisionMode.useElementDefault:
      return true;
  }
}

String _uniqueGeneratedEnvironmentPlacementId(
  MapData map, {
  required EnvironmentArea area,
  required GridPos pos,
  required String elementId,
}) {
  final baseId = generatedEnvironmentPlacementId(
    areaId: area.id,
    pos: pos,
    elementId: elementId,
  );
  final usedIds = {
    ...area.generatedPlacementIds,
    for (final placed in map.placedElements) placed.id,
  };
  if (!usedIds.contains(baseId)) return baseId;
  var suffix = 2;
  while (usedIds.contains('${baseId}_$suffix')) {
    suffix++;
  }
  return '${baseId}_$suffix';
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
