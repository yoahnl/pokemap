part of 'environment_editing.dart';

typedef _EnvironmentTarget = ({
  EnvironmentLayer layer,
  TileLayer? tileLayer,
  EnvironmentArea area,
  EnvironmentPreset preset,
  Map<String, ProjectElementEntry> elements,
  Map<String, ProjectModel3dEntry> models,
});

_EnvironmentTarget _target({
  required ProjectManifest manifest,
  required MapData map,
  required String layerId,
  required String areaId,
}) {
  final layer = _environmentLayer(map, layerId);
  final area = layer.content.areaById(areaId);
  if (area == null) {
    throw semanticFailure(
      'environment.area_missing',
      'The requested Environment area does not exist.',
      details: {'layerId': layerId, 'areaId': areaId},
    );
  }
  final targetId = layer.content.targetTileLayerId;
  final spatial = layer.content.targetsSpatialTerrain;
  if (targetId == null && !spatial) {
    throw semanticFailure(
      'environment.target_layer_missing',
      'The Environment layer is not attached to a Tile layer.',
      details: {'layerId': layerId},
    );
  }
  final targetLayer =
      map.layers.where((candidate) => candidate.id == targetId).firstOrNull;
  if (!spatial && targetLayer is! TileLayer) {
    throw semanticFailure(
      'environment.target_layer_invalid',
      'The Environment target is missing or is not a Tile layer.',
      details: {'targetTileLayerId': targetId},
    );
  }
  if (area.mask.width != map.size.width ||
      area.mask.height != map.size.height) {
    throw semanticFailure(
      'environment.mask_size_invalid',
      'The Environment mask size does not match the map.',
      details: {
        'maskWidth': area.mask.width,
        'maskHeight': area.mask.height,
        'mapWidth': map.size.width,
        'mapHeight': map.size.height,
      },
    );
  }
  final preset = _preset(manifest, area.presetId);
  _validatePresetForMap(manifest, map, preset);
  if (preset.isSpatial != spatial) {
    throw semanticFailure('environment.target_kind_mismatch',
        'The preset and Environment target must use the same visual dimension.');
  }
  _requireTrackedOwnership(map, layer, area);
  final elements = <String, ProjectElementEntry>{
    for (final element in manifest.elements) element.id: element,
  };
  final models = {for (final model in manifest.models3d) model.id: model};
  for (final item in preset.palette) {
    if (item.isSpatial
        ? !models.containsKey(item.modelId)
        : !elements.containsKey(item.elementId)) {
      throw semanticFailure(
        item.isSpatial
            ? 'environment.palette_model_missing'
            : 'environment.palette_element_missing',
        'The Environment preset references a missing project element.',
        details: {
          'presetId': preset.id,
          'elementId': item.elementId,
        },
      );
    }
  }
  return (
    layer: layer,
    tileLayer: targetLayer is TileLayer ? targetLayer : null,
    area: area,
    preset: preset,
    elements: elements,
    models: models,
  );
}

List<EnvironmentGeneratedPlacement> _generate({
  required MapData map,
  required _EnvironmentTarget target,
  required EnvironmentGenerationRegion resolutionRegion,
}) {
  final params = target.area.paramsOverride ?? target.preset.defaultParams;
  final accepted = <GridPos>[];
  final placements = <EnvironmentGeneratedPlacement>[];
  for (var y = resolutionRegion.y; y < resolutionRegion.bottom; y++) {
    for (var x = resolutionRegion.x; x < resolutionRegion.right; x++) {
      if (!target.area.mask.isActiveAt(x, y)) continue;
      final edge = _isMaskEdge(target.area.mask, x, y);
      final baseProbability = edge ? params.edgeDensity : params.density;
      final variation = _random01(
        seed: target.area.seed,
        areaId: target.area.id,
        presetId: target.preset.id,
        x: x,
        y: y,
        usage: 'variation',
      );
      final probability =
          (baseProbability + (variation - 0.5) * params.variation)
              .clamp(0.0, 1.0);
      final roll = _random01(
        seed: target.area.seed,
        areaId: target.area.id,
        presetId: target.preset.id,
        x: x,
        y: y,
        usage: 'placement',
      );
      if (roll > probability ||
          (!target.preset.isSpatial &&
              _tooClose(
                GridPos(x: x, y: y),
                accepted,
                params.minSpacingCells,
              ))) {
        continue;
      }
      final item = _pickPalette(
        target.preset.palette,
        _randomUint32(
          seed: target.area.seed,
          areaId: target.area.id,
          presetId: target.preset.id,
          x: x,
          y: y,
          usage: 'palette',
        ),
      );
      final pos = GridPos(x: x, y: y);
      if (item.isSpatial) {
        final position =
            _spatialPosition(map, pos, offset: item.cellOffsetWorld);
        if (!_spatialSpacingAllows(map, target, pos, params)) {
          continue;
        }
        accepted.add(pos);
        placements.add(EnvironmentGeneratedPlacement(
          id: environmentSpatialPlacementId(
              layerId: target.layer.id,
              areaId: target.area.id,
              anchor: pos,
              modelId: item.modelId!),
          layerId: target.layer.id,
          modelId: item.modelId,
          position: position,
          pos: pos,
          applyCollision:
              item.collisionMode != EnvironmentCollisionMode.forceDisabled,
        ));
        continue;
      }
      final element = target.elements[item.elementId]!;
      if (!_footprintInBounds(
            pos: GridPos(x: x, y: y),
            element: element,
            size: map.size,
          ) ||
          !_footprintInMask(
            pos: GridPos(x: x, y: y),
            element: element,
            mask: target.area.mask,
          )) {
        continue;
      }
      accepted.add(pos);
      placements.add(
        EnvironmentGeneratedPlacement(
          id: 'env_gen_${_safeId(target.area.id)}_${x}_${y}_${_safeId(item.elementId!)}',
          layerId: target.tileLayer!.id,
          elementId: item.elementId,
          pos: pos,
          applyCollision:
              item.collisionMode != EnvironmentCollisionMode.forceDisabled,
        ),
      );
    }
  }
  return placements;
}

EnvironmentPaletteItem _pickPalette(
  List<EnvironmentPaletteItem> palette,
  int roll,
) {
  final total = palette.fold<int>(0, (sum, item) => sum + item.weight);
  var remaining = roll % total;
  for (final item in palette) {
    if (remaining < item.weight) return item;
    remaining -= item.weight;
  }
  return palette.last;
}

bool _tooClose(GridPos candidate, List<GridPos> accepted, int spacing) {
  if (spacing <= 0) return false;
  return accepted.any(
    (value) =>
        (candidate.x - value.x).abs() <= spacing &&
        (candidate.y - value.y).abs() <= spacing,
  );
}

bool _isMaskEdge(EnvironmentAreaMask mask, int x, int y) =>
    !mask.isActiveAt(x - 1, y) ||
    !mask.isActiveAt(x + 1, y) ||
    !mask.isActiveAt(x, y - 1) ||
    !mask.isActiveAt(x, y + 1);

bool _footprintInBounds({
  required GridPos pos,
  required ProjectElementEntry element,
  required GridSize size,
}) {
  final source = element.frames.primarySource;
  final width = source.width <= 0 ? 1 : source.width;
  final height = source.height <= 0 ? 1 : source.height;
  return pos.x >= 0 &&
      pos.y >= 0 &&
      pos.x + width <= size.width &&
      pos.y + height <= size.height;
}

bool _footprintInMask({
  required GridPos pos,
  required ProjectElementEntry element,
  required EnvironmentAreaMask mask,
}) {
  final source = element.frames.primarySource;
  final width = source.width <= 0 ? 1 : source.width;
  final height = source.height <= 0 ? 1 : source.height;
  for (var dy = 0; dy < height; dy++) {
    for (var dx = 0; dx < width; dx++) {
      if (!mask.isActiveAt(pos.x + dx, pos.y + dy)) return false;
    }
  }
  return true;
}

double _random01({
  required int seed,
  required String areaId,
  required String presetId,
  required int x,
  required int y,
  required String usage,
}) =>
    _randomUint32(
      seed: seed,
      areaId: areaId,
      presetId: presetId,
      x: x,
      y: y,
      usage: usage,
    ) /
    4294967296.0;

int _randomUint32({
  required int seed,
  required String areaId,
  required String presetId,
  required int x,
  required int y,
  required String usage,
}) {
  var hash = 0x811c9dc5;
  for (final unit in '$seed|$areaId|$presetId|$x|$y|$usage'.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  var value = (hash ^ seed) & 0xffffffff;
  if (value == 0) value = 0x9e3779b9;
  value ^= (value << 13) & 0xffffffff;
  value ^= value >> 17;
  value ^= (value << 5) & 0xffffffff;
  return value & 0xffffffff;
}

int _nextSeed(int seed) {
  var value = seed & 0xffffffff;
  if (value == 0) value = 0x9e3779b9;
  value ^= (value << 13) & 0xffffffff;
  value ^= value >> 17;
  value ^= (value << 5) & 0xffffffff;
  return value & 0x7fffffff;
}

String _safeId(String value) => value.replaceAll(RegExp('[^a-zA-Z0-9_-]'), '_');

void _validatePresetForMap(
    ProjectManifest manifest, MapData map, EnvironmentPreset preset) {
  if (preset.isSpatial != (map.spatialScene != null)) {
    throw semanticFailure('environment.dimension_mismatch',
        'The Environment preset must match the map dimension.');
  }
  final catalog = manifest.resourceLibraryCatalog;
  for (final item in preset.palette) {
    final exists = item.isSpatial
        ? manifest.models3d.any((model) => model.id == item.modelId)
        : manifest.elements.any((element) => element.id == item.elementId);
    if (!exists) {
      throw semanticFailure(
          item.isSpatial
              ? 'environment.palette_model_missing'
              : 'environment.palette_element_missing',
          'The Environment palette references an unknown visual resource.',
          details: {'presetId': preset.id, 'resourceId': item.resourceId});
    }
  }
  for (final reference in [
    ('environmentPreset', preset.id),
    for (final item in preset.palette)
      (item.isSpatial ? 'model3d' : 'element', item.resourceId),
  ]) {
    if (!catalog.availableForMap(reference.$1, reference.$2, map.id)) {
      throw semanticFailure('resource_library.scope_conflict',
          'This Environment resource is reserved for another map.', details: {
        'resourceKind': reference.$1,
        'resourceId': reference.$2,
        'mapId': map.id
      });
    }
  }
}

String _generationInputFingerprint(
        ProjectManifest manifest, MapData map, _EnvironmentTarget target) =>
    computeNarrativeProjectFingerprint([
      NarrativeProjectFingerprintEntry(
          relativePath: 'environment-input.json',
          bytes: utf8.encode(jsonEncode({
            'map': target.preset.isSpatial
                ? {
                    'mapId': map.id,
                    'mapVersion': map.version.name,
                    'mapSize': map.size.toJson(),
                    'width': map.spatialScene!.width,
                    'depth': map.spatialScene!.depth,
                    'heightLevels': map.spatialScene!.heightLevels,
                    'levelHeight': map.spatialScene!.levelHeight,
                    'ramps': map.spatialScene!.navigation.ramps
                        .map((ramp) => ramp.toJson())
                        .toList(),
                    'layerId': target.layer.id,
                    'area': encodeEnvironmentArea(target.area)
                      ..remove('generatedPlacementIds'),
                    'manualInstances': [
                      for (final id
                          in target.area.manualPlacementIds.toList()..sort())
                        map.spatialScene!.instances
                            .singleWhere((instance) => instance.id == id)
                            .toJson(),
                    ],
                  }
                : map.toJson(),
            'preset': encodeEnvironmentPreset(target.preset),
            'visuals': [
              for (final item in target.preset.palette)
                item.isSpatial
                    ? target.models[item.modelId]!.toJson()
                    : target.elements[item.elementId]!.toJson()
            ],
            if (!target.preset.isSpatial)
              'resourceLibraryCatalog':
                  manifest.resourceLibraryCatalog.toJson(),
          }))),
    ]);

Model3dVector3 _spatialPosition(MapData map, GridPos pos,
    {Model3dVector3? offset}) {
  final scene = map.spatialScene!;
  final x = pos.x + .5 + (offset?.x ?? 0);
  final z = pos.y + .5 + (offset?.z ?? 0);
  if (x < 0 || z < 0 || x >= map.size.width || z >= map.size.height) {
    throw semanticFailure('environment.placement_out_of_bounds',
        'The spatial Environment anchor is outside the map.',
        details: {'cellX': pos.x, 'cellZ': pos.y, 'worldX': x, 'worldZ': z});
  }
  return Model3dVector3(
      x: x, y: scene.worldHeightAt(x, z) + (offset?.y ?? 0), z: z);
}

GridPos _spatialTrackedAnchor(EnvironmentLayer layer, EnvironmentArea area,
    SpatialModelInstance instance) {
  if (area.manualPlacementIds.contains(instance.id)) {
    return GridPos(
        x: instance.position.x.floor(), y: instance.position.z.floor());
  }
  try {
    return environmentSpatialPlacementAnchor(
        placementId: instance.id,
        layerId: layer.id,
        areaId: area.id,
        modelId: instance.modelId);
  } on ValidationException catch (error) {
    throw semanticFailure(
        error.code ?? 'environment.placement_anchor_invalid', error.message,
        details: {'placementId': instance.id});
  }
}

bool _spatialSpacingAllows(MapData map, _EnvironmentTarget target, GridPos pos,
    EnvironmentGenerationParams params) {
  final spacing = params.minSpacingCells;
  if (spacing == 0) return true;
  int rank(int x, int y) => _randomUint32(
      seed: target.area.seed,
      areaId: target.area.id,
      presetId: target.preset.id,
      x: x,
      y: y,
      usage: 'spacing');
  final currentRank = rank(pos.x, pos.y);
  for (var y = (pos.y - spacing).clamp(0, map.size.height - 1);
      y <= (pos.y + spacing).clamp(0, map.size.height - 1);
      y++) {
    for (var x = (pos.x - spacing).clamp(0, map.size.width - 1);
        x <= (pos.x + spacing).clamp(0, map.size.width - 1);
        x++) {
      if ((x == pos.x && y == pos.y) || !target.area.mask.isActiveAt(x, y)) {
        continue;
      }
      final otherRank = rank(x, y);
      if (otherRank > currentRank ||
          (otherRank == currentRank &&
              y * map.size.width + x > pos.y * map.size.width + pos.x)) {
        continue;
      }
      final base = _isMaskEdge(target.area.mask, x, y)
          ? params.edgeDensity
          : params.density;
      final variation = _random01(
          seed: target.area.seed,
          areaId: target.area.id,
          presetId: target.preset.id,
          x: x,
          y: y,
          usage: 'variation');
      final probability =
          (base + (variation - .5) * params.variation).clamp(0.0, 1.0);
      if (_random01(
              seed: target.area.seed,
              areaId: target.area.id,
              presetId: target.preset.id,
              x: x,
              y: y,
              usage: 'placement') >
          probability) {
        continue;
      }
      final item = _pickPalette(
          target.preset.palette,
          _randomUint32(
              seed: target.area.seed,
              areaId: target.area.id,
              presetId: target.preset.id,
              x: x,
              y: y,
              usage: 'palette'));
      _spatialPosition(map, GridPos(x: x, y: y), offset: item.cellOffsetWorld);
      return false;
    }
  }
  return true;
}

void _requireTrackedOwnership(
    MapData map, EnvironmentLayer layer, EnvironmentArea area) {
  final owned = area.generatedPlacementIds.toSet();
  if (layer.content.targetsSpatialTerrain) {
    final existing = {
      for (final instance
          in map.spatialScene?.instances ?? const <SpatialModelInstance>[])
        instance.id
    };
    if (!existing.containsAll(owned)) {
      throw semanticFailure('environment.placement_missing',
          'A spatial Environment owns an instance that is missing from the map.');
    }
    for (final instance in map.spatialScene!.instances
        .where((value) => owned.contains(value.id))) {
      final anchor = _spatialTrackedAnchor(layer, area, instance);
      if (anchor.x < 0 ||
          anchor.y < 0 ||
          anchor.x >= map.size.width ||
          anchor.y >= map.size.height) {
        throw semanticFailure('environment.placement_anchor_invalid',
            'The Environment ownership anchor is outside the map.',
            details: {'placementId': instance.id});
      }
    }
  }
  for (final other in map.layers.whereType<EnvironmentLayer>()) {
    for (final otherArea in other.content.areas) {
      if (other.id == layer.id && otherArea.id == area.id) continue;
      if (otherArea.generatedPlacementIds.any(owned.contains)) {
        throw semanticFailure('environment.placement_owner_conflict',
            'An Environment placement cannot belong to two areas.');
      }
    }
  }
}

MapData _removeTrackedPlacements(
    MapData map, EnvironmentLayer layer, Set<String> ids) {
  for (final area in layer.content.areas) {
    if (area.generatedPlacementIds.any(ids.contains)) {
      _requireTrackedOwnership(map, layer, area);
    }
  }
  if (layer.content.targetsSpatialTerrain) {
    final scene = map.spatialScene;
    if (scene == null) {
      throw semanticFailure('environment.spatial_scene_missing',
          'A spatial Environment needs a native spatial terrain.');
    }
    return map.copyWith(
        spatialScene: scene.copyWith(instances: [
      for (final instance in scene.instances)
        if (!ids.contains(instance.id)) instance,
    ]));
  }
  return map.copyWith(placedElements: [
    for (final placement in map.placedElements)
      if (!ids.contains(placement.id)) placement,
  ]);
}
