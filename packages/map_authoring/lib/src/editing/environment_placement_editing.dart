part of 'environment_editing.dart';

MapData _addManualPlacement(
  ProjectManifest manifest,
  MapData map, {
  required String layerId,
  required String areaId,
  required String placementId,
  String? elementId,
  String? modelId,
  required GridPos pos,
}) {
  if ((elementId == null) == (modelId == null)) {
    throw invalidSemanticField(
        'visualResource', 'exactly one of elementId or modelId');
  }
  final target = _target(
    manifest: manifest,
    map: map,
    layerId: layerId,
    areaId: areaId,
  );
  if (map.placedElements.any((value) => value.id == placementId) ||
      (map.spatialScene?.instances.any((value) => value.id == placementId) ??
          false)) {
    throw semanticFailure(
      'environment.placement_id_conflict',
      'A map placement already uses this ID.',
      details: {'placementId': placementId},
    );
  }
  final paletteItem = target.preset.palette
      .where((candidate) =>
          candidate.elementId == elementId && candidate.modelId == modelId)
      .firstOrNull;
  if (paletteItem == null) {
    throw semanticFailure(
      'environment.element_not_in_palette',
      'The manual placement element is not in the area preset palette.',
      details: {'elementId': elementId, 'presetId': target.preset.id},
    );
  }
  if (modelId != null) {
    final position =
        _spatialPosition(map, pos, offset: paletteItem.cellOffsetWorld);
    final updated = _replaceArea(map,
        layerId: layerId,
        areaId: areaId,
        update: (area) => _copyArea(area,
            generatedPlacementIds: [...area.generatedPlacementIds, placementId],
            manualPlacementIds: [...area.manualPlacementIds, placementId]));
    return updated.copyWith(
        spatialScene: map.spatialScene!.copyWith(instances: [
      ...map.spatialScene!.instances,
      SpatialModelInstance(
          id: placementId,
          modelId: modelId,
          position: position,
          blocksMovement: switch (paletteItem.collisionMode) {
            EnvironmentCollisionMode.useElementDefault =>
              target.models[modelId]!.blocksMovementByDefault,
            EnvironmentCollisionMode.forceEnabled => true,
            EnvironmentCollisionMode.forceDisabled => false,
          }),
    ]));
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
    layerId: target.tileLayer!.id,
    elementId: elementId!,
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
  _requireTrackedOwnership(map, layer, area);
  if (layer.content.targetsSpatialTerrain) {
    final instance = map.spatialScene?.instances
        .where((value) => value.id == placementId)
        .firstOrNull;
    if (instance == null) {
      throw semanticFailure('environment.placement_missing',
          'The tracked spatial Environment instance is missing.');
    }
    var updated = _replaceArea(map,
        layerId: layerId,
        areaId: areaId,
        update: (area) => _copyArea(area,
            manualPlacementIds:
                {...area.manualPlacementIds, placementId}.toList()));
    final old = _spatialTrackedAnchor(layer, area, instance);
    if (!area.manualPlacementIds.contains(instance.id) ||
        old.x != pos.x ||
        old.y != pos.y) {
      updated = _editMaskCells(updated,
          layerId: layerId,
          areaId: areaId,
          cells: [(x: old.x, y: old.y)],
          value: false);
    }
    return updated.copyWith(
        spatialScene: map.spatialScene!.copyWith(instances: [
      for (final value in map.spatialScene!.instances)
        if (value.id == placementId)
          value.copyWith(position: _spatialPosition(map, pos))
        else
          value,
    ]));
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
  _requireTrackedOwnership(map, layer, area);
  var source = map;
  if (layer.content.targetsSpatialTerrain) {
    final instance = map.spatialScene?.instances
        .where((value) => value.id == placementId)
        .firstOrNull;
    if (instance != null) {
      final anchor = _spatialTrackedAnchor(layer, area, instance);
      source = _editMaskCells(map,
          layerId: layerId,
          areaId: areaId,
          cells: [(x: anchor.x, y: anchor.y)],
          value: false);
    }
  }
  final updated = _replaceArea(
    source,
    layerId: layerId,
    areaId: areaId,
    update: (value) => _copyArea(
      value,
      generatedPlacementIds: [
        for (final id in value.generatedPlacementIds)
          if (id != placementId) id,
      ],
      manualPlacementIds: [
        for (final id in value.manualPlacementIds)
          if (id != placementId) id
      ],
    ),
  );
  return _removeTrackedPlacements(updated, layer, {placementId});
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
  final updated = _replaceArea(
    map,
    layerId: layerId,
    areaId: areaId,
    update: (value) => _copyArea(value,
        generatedPlacementIds: const [], manualPlacementIds: const []),
  );
  return _removeTrackedPlacements(updated, layer, ids);
}
