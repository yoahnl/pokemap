import 'package:map_core/map_core.dart';

final class EnvironmentGeneratedPlacementAddPreview {
  const EnvironmentGeneratedPlacementAddPreview({
    required this.placed,
    required this.element,
  });

  final MapPlacedElement placed;
  final ProjectElementEntry element;
}

final class EnvironmentGeneratedPlacementDeleteTarget {
  const EnvironmentGeneratedPlacementDeleteTarget({
    required this.placed,
    required this.element,
  });

  final MapPlacedElement placed;
  final ProjectElementEntry? element;
}

EnvironmentGeneratedPlacementAddPreview?
    resolveEnvironmentGeneratedPlacementAddPreview({
  required MapData map,
  required ProjectManifest manifest,
  required String? activeLayerId,
  required String? selectedAreaId,
  required GridPos pos,
}) {
  final envLayer = _activeEnvironmentLayer(map, activeLayerId);
  if (envLayer == null) return null;
  final area = _environmentAreaById(envLayer, selectedAreaId);
  if (area == null) return null;
  final targetLayer = _targetTileLayer(map, envLayer);
  if (targetLayer == null) return null;
  final preset = _environmentPresetById(manifest, area.presetId);
  if (preset == null) return null;

  final targetTilesetId = _effectiveTileLayerTilesetId(targetLayer, map);
  EnvironmentPaletteItem? item;
  ProjectElementEntry? element;
  for (final candidate in preset.palette) {
    final candidateElement = _projectElementById(manifest, candidate.elementId);
    if (candidateElement == null) continue;
    final elementTilesetId = _elementPrimaryTilesetId(candidateElement);
    if (targetTilesetId.isNotEmpty &&
        elementTilesetId.isNotEmpty &&
        targetTilesetId != elementTilesetId) {
      continue;
    }
    item = candidate;
    element = candidateElement;
    break;
  }
  if (item == null || element == null) return null;

  final footprint = _elementFootprint(element);
  if (!_elementFootprintInBounds(
    pos: pos,
    footprint: footprint,
    mapSize: map.size,
  )) {
    return null;
  }

  final placedId = generatedEnvironmentPlacementId(
    areaId: area.id,
    pos: pos,
    elementId: item.elementId,
  );
  if (area.generatedPlacementIds.contains(placedId) ||
      map.placedElements.any((placed) => placed.id == placedId)) {
    return null;
  }

  return EnvironmentGeneratedPlacementAddPreview(
    placed: MapPlacedElement(
      id: placedId,
      layerId: targetLayer.id,
      elementId: item.elementId,
      pos: pos,
      applyCollision: _applyCollisionFromEnvironmentMode(item.collisionMode),
    ),
    element: element,
  );
}

EnvironmentGeneratedPlacementDeleteTarget?
    resolveEnvironmentGeneratedPlacementDeleteTarget({
  required MapData map,
  required ProjectManifest? manifest,
  required String? activeLayerId,
  required String? selectedAreaId,
  required GridPos pos,
}) {
  final envLayer = _activeOrAttachedEnvironmentLayer(map, activeLayerId);
  if (envLayer == null) return null;

  final generatedIds = <String>{};
  final selectedId = selectedAreaId?.trim();
  for (final area in envLayer.content.areas) {
    if (selectedId != null && selectedId.isNotEmpty && area.id != selectedId) {
      continue;
    }
    generatedIds.addAll(area.generatedPlacementIds);
  }
  if (generatedIds.isEmpty) return null;

  final elementById = <String, ProjectElementEntry>{
    if (manifest != null)
      for (final element in manifest.elements) element.id: element,
  };
  for (final instance in map.placedElements.reversed) {
    if (!generatedIds.contains(instance.id)) continue;
    final element = elementById[instance.elementId];
    if (!_placedElementContainsGridPos(
      instance: instance,
      element: element,
      pos: pos,
    )) {
      continue;
    }
    return EnvironmentGeneratedPlacementDeleteTarget(
      placed: instance,
      element: element,
    );
  }

  return null;
}

String generatedEnvironmentPlacementId({
  required String areaId,
  required GridPos pos,
  required String elementId,
}) {
  return 'env_gen_${_sanitizeEnvironmentIdPart(areaId)}_${pos.x}_${pos.y}_${_sanitizeEnvironmentIdPart(elementId)}';
}

EnvironmentLayer? _activeEnvironmentLayer(
  MapData map,
  String? activeLayerId,
) {
  final layerId = activeLayerId?.trim();
  if (layerId == null || layerId.isEmpty) return null;
  for (final layer in map.layers) {
    if (layer.id == layerId && layer is EnvironmentLayer) {
      return layer;
    }
  }
  return null;
}

EnvironmentLayer? _activeOrAttachedEnvironmentLayer(
  MapData map,
  String? activeLayerId,
) {
  final layerId = activeLayerId?.trim();
  if (layerId == null || layerId.isEmpty) return null;
  for (final layer in map.layers) {
    if (layer.id == layerId && layer is EnvironmentLayer) {
      return layer;
    }
  }
  for (final layer in map.layers) {
    if (layer is EnvironmentLayer &&
        layer.content.targetTileLayerId?.trim() == layerId) {
      return layer;
    }
  }
  return null;
}

EnvironmentArea? _environmentAreaById(
  EnvironmentLayer layer,
  String? selectedAreaId,
) {
  final areaId = selectedAreaId?.trim();
  if (areaId == null || areaId.isEmpty) return null;
  for (final area in layer.content.areas) {
    if (area.id == areaId) return area;
  }
  return null;
}

TileLayer? _targetTileLayer(MapData map, EnvironmentLayer layer) {
  final targetLayerId = layer.content.targetTileLayerId?.trim();
  if (targetLayerId == null || targetLayerId.isEmpty) return null;
  for (final layer in map.layers) {
    if (layer.id == targetLayerId && layer is TileLayer) {
      return layer;
    }
  }
  return null;
}

EnvironmentPreset? _environmentPresetById(
  ProjectManifest manifest,
  String presetId,
) {
  final normalizedId = presetId.trim();
  for (final preset in manifest.environmentPresets) {
    if (preset.id == normalizedId) return preset;
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

bool _placedElementContainsGridPos({
  required MapPlacedElement instance,
  required ProjectElementEntry? element,
  required GridPos pos,
}) {
  final source = element?.frames.primarySource;
  final width = source == null || source.width <= 0 ? 1 : source.width;
  final height = source == null || source.height <= 0 ? 1 : source.height;
  return pos.x >= instance.pos.x &&
      pos.y >= instance.pos.y &&
      pos.x < instance.pos.x + width &&
      pos.y < instance.pos.y + height;
}

String _sanitizeEnvironmentIdPart(String value) {
  return value.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
}
