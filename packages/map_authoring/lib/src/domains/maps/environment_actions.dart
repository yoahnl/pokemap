import 'dart:convert';

import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import 'semantic_map_action_support.dart';

part 'environment_generation_support.dart';

/// Bounded map-space region used by deterministic Environment generation.
final class EnvironmentGenerationRegion {
  const EnvironmentGenerationRegion({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final int x;
  final int y;
  final int width;
  final int height;

  int get right => x + width;
  int get bottom => y + height;

  bool contains(GridPos pos) =>
      pos.x >= x && pos.x < right && pos.y >= y && pos.y < bottom;

  Map<String, Object?> toJson() => {
        'x': x,
        'y': y,
        'width': width,
        'height': height,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EnvironmentGenerationRegion &&
          x == other.x &&
          y == other.y &&
          width == other.width &&
          height == other.height;

  @override
  int get hashCode => Object.hash(x, y, width, height);
}

/// Renderer-neutral generated placement included in an optimistic preview.
final class EnvironmentGeneratedPlacement {
  EnvironmentGeneratedPlacement({
    required this.id,
    required this.layerId,
    required this.elementId,
    required this.pos,
    required this.applyCollision,
  });

  final String id;
  final String layerId;
  final String elementId;
  final GridPos pos;
  final bool applyCollision;

  Map<String, Object?> toJson() => {
        'id': id,
        'layerId': layerId,
        'elementId': elementId,
        'x': pos.x,
        'y': pos.y,
        'applyCollision': applyCollision,
      };
}

/// Immutable Environment preview bound to the exact map revision and area seed.
final class EnvironmentGenerationPreview {
  EnvironmentGenerationPreview._({
    required this.mapId,
    required this.layerId,
    required this.areaId,
    required this.projectRevision,
    required this.seed,
    required this.requestedRegion,
    required this.resolutionRegion,
    required this.haloCells,
    required Iterable<EnvironmentGeneratedPlacement> placements,
  }) : placements = List.unmodifiable(placements) {
    fingerprint = computeNarrativeProjectFingerprint([
      NarrativeProjectFingerprintEntry(
        relativePath: 'environment-generation-preview.json',
        bytes: utf8.encode(jsonEncode(_fingerprintPayload())),
      ),
    ]);
  }

  final String mapId;
  final String layerId;
  final String areaId;
  final String projectRevision;
  final int seed;
  final EnvironmentGenerationRegion requestedRegion;
  final EnvironmentGenerationRegion resolutionRegion;
  final int haloCells;
  final List<EnvironmentGeneratedPlacement> placements;
  late final String fingerprint;

  Map<String, Object?> _fingerprintPayload() => {
        'schema': 'pokemap.environment-generation-preview.v1',
        'mapId': mapId,
        'layerId': layerId,
        'areaId': areaId,
        'projectRevision': projectRevision,
        'seed': seed,
        'requestedRegion': requestedRegion.toJson(),
        'resolutionRegion': resolutionRegion.toJson(),
        'haloCells': haloCells,
        'placements': placements.map((value) => value.toJson()).toList(),
      };

  Map<String, Object?> toJson() => {
        ..._fingerprintPayload(),
        'placementCount': placements.length,
        'fingerprint': fingerprint,
      };
}

/// Canonical Environment mutation and deterministic generation adapter.
final class EnvironmentActions {
  const EnvironmentActions();

  static const int generationHaloCells = 1;
  static const int maxGenerationCells = 4096;

  static final List<AuthoringActionDescriptor> descriptors = List.unmodifiable([
    semanticActionDescriptor(
      'environment.attach_to_tile_layer',
      'Attach an Environment layer to a Tile layer',
    ),
    semanticActionDescriptor(
      'environment.detach_from_tile_layer',
      'Detach an Environment layer from its Tile layer',
    ),
    semanticActionDescriptor(
      'environment.area_create',
      'Create an Environment area with an empty map-sized mask',
    ),
    semanticActionDescriptor(
      'environment.area_update',
      'Update Environment area metadata and generation parameters',
    ),
    semanticActionDescriptor(
      'environment.area_delete',
      'Delete an Environment area and its tracked placements',
    ),
    semanticActionDescriptor(
      'environment.area_set_preset',
      'Assign an Environment preset to an area',
    ),
    semanticActionDescriptor(
      'environment.area_set_seed',
      'Set an Environment area deterministic seed',
    ),
    semanticActionDescriptor(
      'environment.mask_paint',
      'Paint a bounded Environment mask region',
    ),
    semanticActionDescriptor(
      'environment.mask_erase',
      'Erase a bounded Environment mask region',
    ),
    semanticActionDescriptor(
      'environment.mask_clear',
      'Clear an Environment area mask',
    ),
    semanticActionDescriptor(
      'environment.generate_apply',
      'Apply a deterministic full Environment generation preview',
    ),
    semanticActionDescriptor(
      'environment.regenerate_apply',
      'Apply deterministic local Environment regeneration',
    ),
    semanticActionDescriptor(
      'environment.shuffle_apply',
      'Advance the area seed and atomically regenerate it',
    ),
    semanticActionDescriptor(
      'environment.generated_placement_add',
      'Add a manual Environment placement override',
    ),
    semanticActionDescriptor(
      'environment.generated_placement_move',
      'Move one tracked Environment placement override',
    ),
    semanticActionDescriptor(
      'environment.generated_placement_delete',
      'Delete one tracked Environment placement override',
    ),
    semanticActionDescriptor(
      'environment.generated_placements_clear',
      'Clear every tracked placement for an Environment area',
    ),
  ]);

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
    final haloCells = params.minSpacingCells > generationHaloCells
        ? params.minSpacingCells
        : generationHaloCells;
    final resolution = _expandRegion(requested, map.size, haloCells);
    final cellCount = resolution.width * resolution.height;
    if (cellCount > maxGenerationCells) {
      throw semanticFailure(
        'environment.region_too_large',
        'The Environment generation region exceeds the bounded limit.',
        details: {
          'cellCount': cellCount,
          'maxGenerationCells': maxGenerationCells,
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
          elementId: candidate.elementId,
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

  AuthoringMutationDraft build(AuthoringPlanningContext planning) {
    final actionId = planning.request.actionId;
    final allowed = switch (actionId) {
      'environment.attach_to_tile_layer' => const {
          'layerId',
          'targetTileLayerId',
        },
      'environment.detach_from_tile_layer' => const {'layerId'},
      'environment.area_create' => const {
          'layerId',
          'areaId',
          'name',
          'presetId',
          'seed',
        },
      'environment.area_update' => const {
          'layerId',
          'areaId',
          'name',
          'presetId',
          'seed',
          'paramsOverride',
          'clearParamsOverride',
        },
      'environment.area_delete' ||
      'environment.mask_clear' ||
      'environment.generated_placements_clear' =>
        const {
          'layerId',
          'areaId',
        },
      'environment.area_set_preset' => const {
          'layerId',
          'areaId',
          'presetId',
        },
      'environment.area_set_seed' => const {'layerId', 'areaId', 'seed'},
      'environment.mask_paint' || 'environment.mask_erase' => const {
          'layerId',
          'areaId',
          'x',
          'y',
          'width',
          'height',
        },
      'environment.generate_apply' || 'environment.regenerate_apply' => const {
          'layerId',
          'areaId',
          'x',
          'y',
          'width',
          'height',
        },
      'environment.shuffle_apply' => const {
          'layerId',
          'areaId',
          'newSeed',
        },
      'environment.generated_placement_add' => const {
          'layerId',
          'areaId',
          'placementId',
          'elementId',
          'x',
          'y',
        },
      'environment.generated_placement_move' => const {
          'layerId',
          'areaId',
          'placementId',
          'x',
          'y',
        },
      'environment.generated_placement_delete' => const {
          'layerId',
          'areaId',
          'placementId',
        },
      _ => throw semanticFailure(
          'map.action_unsupported',
          'The requested Environment action is unsupported.',
          details: {'actionId': actionId},
        ),
    };
    final context = SemanticMapActionContext.read(
      planning,
      allowedParameters: allowed,
    );
    final parameters = context.parameters;
    final layerId = parameters.string('layerId');
    late MapData updated;
    var changedItems = 1;
    final extraPreview = <String, Object?>{};

    switch (actionId) {
      case 'environment.attach_to_tile_layer':
        updated = _attach(
          context.map,
          layerId: layerId,
          targetTileLayerId: parameters.string('targetTileLayerId'),
        );
      case 'environment.detach_from_tile_layer':
        updated = _attach(
          context.map,
          layerId: layerId,
          targetTileLayerId: null,
        );
      case 'environment.area_create':
        _preset(context.manifest, parameters.string('presetId'));
        updated = _createArea(
          context.map,
          layerId: layerId,
          areaId: parameters.string('areaId'),
          name: parameters.string('name'),
          presetId: parameters.string('presetId'),
          seed: parameters.integer('seed'),
        );
      case 'environment.area_update':
        final clear = parameters.contains('clearParamsOverride') &&
            parameters.boolean('clearParamsOverride');
        if (clear && parameters.contains('paramsOverride')) {
          throw invalidSemanticField(
            'paramsOverride',
            'absent when clearParamsOverride is true',
          );
        }
        final presetId = parameters.optionalString('presetId');
        if (presetId != null) _preset(context.manifest, presetId);
        updated = _replaceArea(
          context.map,
          layerId: layerId,
          areaId: parameters.string('areaId'),
          update: (area) => _copyArea(
            area,
            name: parameters.optionalString('name'),
            presetId: presetId,
            seed: parameters.optionalInteger('seed'),
            paramsOverride: parameters.contains('paramsOverride')
                ? _params(parameters.object('paramsOverride'))
                : area.paramsOverride,
            clearParamsOverride: clear,
          ),
        );
      case 'environment.area_delete':
        updated = _deleteArea(
          context.map,
          layerId: layerId,
          areaId: parameters.string('areaId'),
        );
      case 'environment.area_set_preset':
        final presetId = parameters.string('presetId');
        _preset(context.manifest, presetId);
        updated = _replaceArea(
          context.map,
          layerId: layerId,
          areaId: parameters.string('areaId'),
          update: (area) => _copyArea(area, presetId: presetId),
        );
      case 'environment.area_set_seed':
        updated = _replaceArea(
          context.map,
          layerId: layerId,
          areaId: parameters.string('areaId'),
          update: (area) => _copyArea(
            area,
            seed: parameters.integer('seed'),
          ),
        );
      case 'environment.mask_paint':
      case 'environment.mask_erase':
        final region = _parameterRegion(parameters, context.map.size)!;
        updated = _editMask(
          context.map,
          layerId: layerId,
          areaId: parameters.string('areaId'),
          region: region,
          value: actionId == 'environment.mask_paint',
        );
        changedItems = region.width * region.height;
        extraPreview['editedRegion'] = region.toJson();
        extraPreview['regenerationHaloCells'] = generationHaloCells;
      case 'environment.mask_clear':
        updated = _clearMask(
          context.map,
          layerId: layerId,
          areaId: parameters.string('areaId'),
        );
      case 'environment.generate_apply':
      case 'environment.regenerate_apply':
        final preview = previewGeneration(
          manifest: context.manifest,
          map: context.map,
          layerId: layerId,
          areaId: parameters.string('areaId'),
          projectRevision: context.resource.revision!,
          region: _parameterRegion(parameters, context.map.size),
        );
        updated = applyGeneration(
          manifest: context.manifest,
          map: context.map,
          preview: preview,
          currentRevision: context.resource.revision!,
        );
        changedItems = preview.placements.length;
        extraPreview['generation'] = preview.toJson();
      case 'environment.shuffle_apply':
        final areaId = parameters.string('areaId');
        final target = _target(
          manifest: context.manifest,
          map: context.map,
          layerId: layerId,
          areaId: areaId,
        );
        final nextSeed = parameters.optionalInteger('newSeed') ??
            _nextSeed(target.area.seed);
        final seeded = _replaceArea(
          context.map,
          layerId: layerId,
          areaId: areaId,
          update: (area) => _copyArea(area, seed: nextSeed),
        );
        final preview = previewGeneration(
          manifest: context.manifest,
          map: seeded,
          layerId: layerId,
          areaId: areaId,
          projectRevision: context.resource.revision!,
        );
        updated = applyGeneration(
          manifest: context.manifest,
          map: seeded,
          preview: preview,
          currentRevision: context.resource.revision!,
        );
        changedItems = preview.placements.length;
        extraPreview['generation'] = preview.toJson();
      case 'environment.generated_placement_add':
        updated = _addManualPlacement(
          context.manifest,
          context.map,
          layerId: layerId,
          areaId: parameters.string('areaId'),
          placementId: parameters.string('placementId'),
          elementId: parameters.string('elementId'),
          pos: GridPos(
            x: parameters.integer('x'),
            y: parameters.integer('y'),
          ),
        );
      case 'environment.generated_placement_move':
        updated = _moveManualPlacement(
          context.map,
          layerId: layerId,
          areaId: parameters.string('areaId'),
          placementId: parameters.string('placementId'),
          pos: GridPos(
            x: parameters.integer('x'),
            y: parameters.integer('y'),
          ),
        );
      case 'environment.generated_placement_delete':
        updated = _deletePlacement(
          context.map,
          layerId: layerId,
          areaId: parameters.string('areaId'),
          placementId: parameters.string('placementId'),
        );
      case 'environment.generated_placements_clear':
        final area = _environmentLayer(context.map, layerId)
            .content
            .areaById(parameters.string('areaId'));
        if (area == null) {
          throw semanticFailure(
            'environment.area_missing',
            'The requested Environment area does not exist.',
          );
        }
        changedItems = area.generatedPlacementIds.length;
        updated = _clearPlacements(
          context.map,
          layerId: layerId,
          areaId: area.id,
        );
      default:
        throw StateError('unreachable Environment action');
    }

    return context.draftMap(
      after: updated,
      operation: actionId,
      changedItems: changedItems,
      layerId: layerId,
      preview: extraPreview,
    );
  }
}

EnvironmentGenerationRegion _expandRegion(
  EnvironmentGenerationRegion region,
  GridSize size,
  int haloCells,
) {
  final x = region.x > haloCells ? region.x - haloCells : 0;
  final y = region.y > haloCells ? region.y - haloCells : 0;
  final right = region.right + haloCells < size.width
      ? region.right + haloCells
      : size.width;
  final bottom = region.bottom + haloCells < size.height
      ? region.bottom + haloCells
      : size.height;
  return EnvironmentGenerationRegion(
    x: x,
    y: y,
    width: right - x,
    height: bottom - y,
  );
}

void _requireRegion(EnvironmentGenerationRegion region, GridSize size) {
  if (region.x < 0 ||
      region.y < 0 ||
      region.width <= 0 ||
      region.height <= 0 ||
      region.right > size.width ||
      region.bottom > size.height) {
    throw semanticFailure(
      'environment.region_out_of_bounds',
      'The Environment region must be positive and inside the map.',
      details: region.toJson(),
    );
  }
}

EnvironmentGenerationRegion? _parameterRegion(
  SemanticParameters parameters,
  GridSize size,
) {
  final keys = ['x', 'y', 'width', 'height'];
  final present = keys.where(parameters.contains).length;
  if (present == 0) return null;
  if (present != keys.length) {
    throw invalidSemanticField(
      'region',
      'all of x, y, width and height when any region field is supplied',
    );
  }
  final region = EnvironmentGenerationRegion(
    x: parameters.integer('x'),
    y: parameters.integer('y'),
    width: parameters.integer('width'),
    height: parameters.integer('height'),
  );
  _requireRegion(region, size);
  return region;
}

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

EnvironmentGenerationParams _params(Map<String, Object?> value) {
  const keys = {
    'density',
    'variation',
    'edgeDensity',
    'minSpacingCells',
  };
  final unknown = value.keys.where((key) => !keys.contains(key)).toList();
  if (unknown.isNotEmpty) {
    throw invalidSemanticField('paramsOverride', 'known generation fields');
  }
  double number(String key) {
    final raw = value[key];
    if (raw is! num || !raw.isFinite) {
      throw invalidSemanticField('paramsOverride.$key', 'a finite number');
    }
    return raw.toDouble();
  }

  final spacing = value['minSpacingCells'];
  if (spacing is! int) {
    throw invalidSemanticField(
      'paramsOverride.minSpacingCells',
      'an integer',
    );
  }
  return EnvironmentGenerationParams(
    density: number('density'),
    variation: number('variation'),
    edgeDensity: number('edgeDensity'),
    minSpacingCells: spacing,
  );
}

MapData _editMask(
  MapData map, {
  required String layerId,
  required String areaId,
  required EnvironmentGenerationRegion region,
  required bool value,
}) =>
    _replaceArea(
      map,
      layerId: layerId,
      areaId: areaId,
      update: (area) {
        final cells = List<bool>.from(area.mask.cells);
        for (var y = region.y; y < region.bottom; y++) {
          for (var x = region.x; x < region.right; x++) {
            cells[y * area.mask.width + x] = value;
          }
        }
        return EnvironmentArea(
          id: area.id,
          name: area.name,
          presetId: area.presetId,
          mask: EnvironmentAreaMask(
            width: area.mask.width,
            height: area.mask.height,
            cells: cells,
          ),
          seed: area.seed,
          paramsOverride: area.paramsOverride,
          generatedPlacementIds: area.generatedPlacementIds,
        );
      },
    );

MapData _clearMask(
  MapData map, {
  required String layerId,
  required String areaId,
}) =>
    _replaceArea(
      map,
      layerId: layerId,
      areaId: areaId,
      update: (area) => EnvironmentArea(
        id: area.id,
        name: area.name,
        presetId: area.presetId,
        mask: EnvironmentAreaMask(
          width: area.mask.width,
          height: area.mask.height,
          cells: List<bool>.filled(area.mask.width * area.mask.height, false),
        ),
        seed: area.seed,
        paramsOverride: area.paramsOverride,
        generatedPlacementIds: area.generatedPlacementIds,
      ),
    );

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
