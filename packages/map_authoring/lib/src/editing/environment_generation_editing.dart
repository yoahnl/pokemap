part of 'environment_editing.dart';

mixin _EnvironmentGenerationEditing {
  EnvironmentGenerationPreview previewGeneration({
    required ProjectManifest manifest,
    required MapData map,
    required String layerId,
    required String areaId,
    required String projectRevision,
    EnvironmentGenerationRegion? region,
  }) {
    _requireStableText(projectRevision, 'projectRevision');
    final target = _target(
      manifest: manifest,
      map: map,
      layerId: layerId,
      areaId: areaId,
    );
    final requested = region ??
        EnvironmentGenerationRegion(
          x: 0,
          y: 0,
          width: map.size.width,
          height: map.size.height,
        );
    _requireRegion(requested, map.size);
    final params = target.area.paramsOverride ?? target.preset.defaultParams;
    final haloCells =
        params.minSpacingCells > EnvironmentEditing.generationHaloCells
            ? params.minSpacingCells
            : EnvironmentEditing.generationHaloCells;
    final resolution = _expandRegion(requested, map.size, haloCells);
    final cellCount = resolution.width * resolution.height;
    if (cellCount > EnvironmentEditing.maxGenerationCells) {
      throw semanticFailure(
        'environment.region_too_large',
        'The Environment generation region exceeds the bounded limit.',
        details: {
          'cellCount': cellCount,
          'maxGenerationCells': EnvironmentEditing.maxGenerationCells,
        },
        remediation: const ['Regenerate the area in smaller regions.'],
      );
    }

    final placements = _generate(
      map: map,
      target: target,
      resolutionRegion: resolution,
    );
    return EnvironmentGenerationPreview._(
      mapId: map.id,
      layerId: target.layer.id,
      areaId: target.area.id,
      projectRevision: projectRevision,
      inputFingerprint: _generationInputFingerprint(manifest, map, target),
      seed: target.area.seed,
      requestedRegion: requested,
      resolutionRegion: resolution,
      haloCells: haloCells,
      placements: placements,
    );
  }

  MapData applyGeneration({
    required ProjectManifest manifest,
    required MapData map,
    required EnvironmentGenerationPreview preview,
    required String currentRevision,
  }) {
    if (preview.mapId != map.id || preview.projectRevision != currentRevision) {
      throw semanticFailure(
        'environment.preview_stale',
        'The Environment preview is not bound to the current map revision.',
        details: {
          'previewMapId': preview.mapId,
          'currentMapId': map.id,
          'previewRevision': preview.projectRevision,
          'currentRevision': currentRevision,
        },
        remediation: const ['Regenerate the preview from the current map.'],
      );
    }
    final target = _target(
      manifest: manifest,
      map: map,
      layerId: preview.layerId,
      areaId: preview.areaId,
    );
    if (target.area.seed != preview.seed) {
      throw semanticFailure(
        'environment.preview_seed_stale',
        'The Environment area seed changed after preview generation.',
        details: {
          'previewSeed': preview.seed,
          'currentSeed': target.area.seed,
        },
      );
    }
    final canonicalPreview = previewGeneration(
      manifest: manifest,
      map: map,
      layerId: preview.layerId,
      areaId: preview.areaId,
      projectRevision: currentRevision,
      region: preview.requestedRegion,
    );
    if (canonicalPreview.fingerprint != preview.fingerprint) {
      throw semanticFailure(
        'environment.preview_invalid',
        'The Environment preview does not match canonical generation.',
        remediation: const ['Regenerate the preview from the current map.'],
      );
    }

    if (target.preset.isSpatial) {
      return _applySpatialGeneration(manifest, map, target, preview);
    }

    final placedById = <String, MapPlacedElement>{
      for (final placement in map.placedElements) placement.id: placement,
    };
    final removedIds = <String>{};
    for (final id in target.area.generatedPlacementIds) {
      final placement = placedById[id];
      if (placement != null &&
          preview.resolutionRegion.contains(placement.pos)) {
        removedIds.add(id);
      }
    }
    final retained = <MapPlacedElement>[
      for (final placement in map.placedElements)
        if (!removedIds.contains(placement.id)) placement,
    ];
    final occupiedIds = <String>{for (final value in retained) value.id};
    final generated = <MapPlacedElement>[];
    for (final candidate in preview.placements) {
      if (!occupiedIds.add(candidate.id)) {
        throw semanticFailure(
          'environment.placement_id_conflict',
          'A generated Environment placement ID is already in use.',
          details: {'placementId': candidate.id},
        );
      }
      generated.add(
        MapPlacedElement(
          id: candidate.id,
          layerId: candidate.layerId,
          elementId: candidate.elementId!,
          pos: candidate.pos,
          applyCollision: candidate.applyCollision,
          properties: const {
            'pokemapPlacementOrigin': 'environment',
          },
        ),
      );
    }

    final preservedAreaIds = <String>[
      for (final id in target.area.generatedPlacementIds)
        if (!removedIds.contains(id)) id,
    ];
    final replacementIds = generated.map((value) => value.id).toList();
    final updated = _replaceArea(
      map,
      layerId: target.layer.id,
      areaId: target.area.id,
      update: (area) => _copyArea(
        area,
        generatedPlacementIds: [...preservedAreaIds, ...replacementIds],
      ),
    ).copyWith(placedElements: [...retained, ...generated]);
    MapValidator.validate(updated, projectDialogueContext: manifest);
    return updated;
  }
}

MapData _applySpatialGeneration(ProjectManifest manifest, MapData map,
    _EnvironmentTarget target, EnvironmentGenerationPreview preview) {
  final scene = map.spatialScene!;
  final tracked = target.area.generatedPlacementIds.toSet();
  final removed = <String>{
    for (final instance in scene.instances)
      if (tracked.contains(instance.id) &&
          !target.area.manualPlacementIds.contains(instance.id) &&
          preview.resolutionRegion.contains(
              _spatialTrackedAnchor(target.layer, target.area, instance)))
        instance.id,
  };
  final retained = [
    for (final instance in scene.instances)
      if (!removed.contains(instance.id)) instance
  ];
  final occupied = {
    for (final instance in retained) instance.id,
    for (final value in map.placedElements) value.id
  };
  final generated = <SpatialModelInstance>[];
  for (final candidate in preview.placements) {
    if (target.area.manualPlacementIds.contains(candidate.id) ||
        retained.any((instance) =>
            target.area.manualPlacementIds.contains(instance.id) &&
            instance.position.x.floor() == candidate.position!.x.floor() &&
            instance.position.z.floor() == candidate.position!.z.floor())) {
      continue;
    }
    if (!occupied.add(candidate.id)) {
      throw semanticFailure('environment.placement_id_conflict',
          'A generated Environment instance ID is already in use.',
          details: {'placementId': candidate.id});
    }
    generated.add(SpatialModelInstance(
        id: candidate.id,
        modelId: candidate.modelId!,
        position: candidate.position!,
        blocksMovement: candidate.applyCollision));
  }
  final updated = _replaceArea(map,
      layerId: target.layer.id,
      areaId: target.area.id,
      update: (area) => _copyArea(area, generatedPlacementIds: [
            for (final id in area.generatedPlacementIds)
              if (!removed.contains(id)) id,
            for (final instance in generated) instance.id,
          ])).copyWith(
      spatialScene: scene.copyWith(instances: [...retained, ...generated]));
  MapValidator.validate(updated, projectDialogueContext: manifest);
  return updated;
}
