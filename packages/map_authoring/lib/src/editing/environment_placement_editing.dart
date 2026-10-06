part of 'environment_editing.dart';

MapData _addManualPlacement(
  ProjectManifest manifest,
  MapData map, {
  required String layerId,
  required String areaId,
  required String placementId,
  required String elementId,
  required GridPos pos,
}) {
  final target = _target(
    manifest: manifest,
    map: map,
    layerId: layerId,
    areaId: areaId,
  );
  if (map.placedElements.any((value) => value.id == placementId)) {
    throw semanticFailure(
      'environment.placement_id_conflict',
      'A map placement already uses this ID.',
      details: {'placementId': placementId},
    );
  }
  final paletteItem = target.preset.palette
      .where((candidate) => candidate.elementId == elementId)
      .firstOrNull;
  if (paletteItem == null) {
    throw semanticFailure(
      'environment.element_not_in_palette',
      'The manual placement element is not in the area preset palette.',
      details: {'elementId': elementId, 'presetId': target.preset.id},
    );
  }
  final element = target.elements[elementId]!;
  if (!_footprintInBounds(pos: pos, element: element, size: map.size)) {
    throw semanticFailure(
      'environment.placement_out_of_bounds',
      'The manual Environment placement is outside map bounds.',
      details: {'x': pos.x, 'y': pos.y},
    );
  }
  final placed = MapPlacedElement(
    id: placementId,
    layerId: target.tileLayer.id,
    elementId: elementId,
    pos: pos,
    applyCollision:
        paletteItem.collisionMode != EnvironmentCollisionMode.forceDisabled,
    properties: const {
      'pokemapPlacementOrigin': 'environment',
      'pokemapEnvironmentManualOverride': 'true',
    },
  );
  return _replaceArea(
    map,
    layerId: layerId,
    areaId: areaId,
    update: (area) => _copyArea(
      area,
      generatedPlacementIds: [...area.generatedPlacementIds, placementId],
    ),
  ).copyWith(placedElements: [...map.placedElements, placed]);
}

MapData _moveManualPlacement(
  MapData map, {
  required String layerId,
  required String areaId,
  required String placementId,
  required GridPos pos,
}) {
  if (pos.x < 0 ||
      pos.y < 0 ||
      pos.x >= map.size.width ||
      pos.y >= map.size.height) {
    throw semanticFailure(
      'environment.placement_out_of_bounds',
      'The manual Environment placement is outside map bounds.',
      details: {'x': pos.x, 'y': pos.y},
    );
  }
  final layer = _environmentLayer(map, layerId);
  final area = layer.content.areaById(areaId);
  if (area == null || !area.generatedPlacementIds.contains(placementId)) {
    throw semanticFailure(
      'environment.placement_missing',
      'The tracked Environment placement does not exist.',
      details: {'placementId': placementId},
    );
  }
  if (!map.placedElements.any((value) => value.id == placementId)) {
    throw semanticFailure(
      'environment.placement_missing',
      'The tracked Environment placement is missing from the map.',
      details: {'placementId': placementId},
    );
  }
  return map.copyWith(
    placedElements: [
      for (final placement in map.placedElements)
        if (placement.id == placementId)
          placement.copyWith(
            pos: pos,
            properties: {
              ...placement.properties,
              'pokemapEnvironmentManualOverride': 'true',
            },
          )
        else
          placement,
    ],
  );
}

MapData _deletePlacement(
  MapData map, {
  required String layerId,
  required String areaId,
  required String placementId,
}) {
  final layer = _environmentLayer(map, layerId);
  final area = layer.content.areaById(areaId);
  if (area == null || !area.generatedPlacementIds.contains(placementId)) {
    throw semanticFailure(
      'environment.placement_missing',
      'The tracked Environment placement does not exist.',
      details: {'placementId': placementId},
    );
  }
  return _replaceArea(
    map,
    layerId: layerId,
    areaId: areaId,
    update: (value) => _copyArea(
      value,
      generatedPlacementIds: [
        for (final id in value.generatedPlacementIds)
          if (id != placementId) id,
      ],
    ),
  ).copyWith(
    placedElements: [
      for (final placement in map.placedElements)
        if (placement.id != placementId) placement,
    ],
  );
}

MapData _clearPlacements(
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
    );
  }
  final ids = area.generatedPlacementIds.toSet();
  return _replaceArea(
    map,
    layerId: layerId,
    areaId: areaId,
    update: (value) => _copyArea(value, generatedPlacementIds: const []),
  ).copyWith(
    placedElements: [
      for (final placement in map.placedElements)
        if (!ids.contains(placement.id)) placement,
    ],
  );
}
