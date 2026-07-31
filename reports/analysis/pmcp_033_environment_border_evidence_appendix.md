# PMCP-033 — Complete created-file appendix

This appendix reproduces the complete implementation and test files created by PMCP-033.

## `packages/map_authoring/lib/src/domains/maps/environment_actions.dart`

```dart
import 'dart:convert';

import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import 'semantic_map_action_support.dart';

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

typedef _EnvironmentTarget = ({
  EnvironmentLayer layer,
  TileLayer tileLayer,
  EnvironmentArea area,
  EnvironmentPreset preset,
  Map<String, ProjectElementEntry> elements,
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
  if (targetId == null) {
    throw semanticFailure(
      'environment.target_layer_missing',
      'The Environment layer is not attached to a Tile layer.',
      details: {'layerId': layerId},
    );
  }
  final targetLayer =
      map.layers.where((candidate) => candidate.id == targetId).firstOrNull;
  if (targetLayer is! TileLayer) {
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
  final elements = <String, ProjectElementEntry>{
    for (final element in manifest.elements) element.id: element,
  };
  for (final item in preset.palette) {
    if (!elements.containsKey(item.elementId)) {
      throw semanticFailure(
        'environment.palette_element_missing',
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
    tileLayer: targetLayer,
    area: area,
    preset: preset,
    elements: elements,
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
          _tooClose(
            GridPos(x: x, y: y),
            accepted,
            params.minSpacingCells,
          )) {
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
      final element = target.elements[item.elementId]!;
      if (!_footprintInBounds(
        pos: GridPos(x: x, y: y),
        element: element,
        size: map.size,
      )) {
        continue;
      }
      final elementTileset = element.frames.primaryFrame.tilesetId.isNotEmpty
          ? element.frames.primaryFrame.tilesetId
          : element.tilesetId;
      final targetTileset = target.tileLayer.tilesetId ?? map.tilesetId;
      if (elementTileset.isNotEmpty &&
          targetTileset.isNotEmpty &&
          elementTileset != targetTileset) {
        throw semanticFailure(
          'environment.tileset_mismatch',
          'An Environment palette element does not match the target Tile layer.',
          details: {
            'elementId': element.id,
            'elementTilesetId': elementTileset,
            'targetTilesetId': targetTileset,
          },
        );
      }
      final pos = GridPos(x: x, y: y);
      accepted.add(pos);
      placements.add(
        EnvironmentGeneratedPlacement(
          id: 'env_gen_${_safeId(target.area.id)}_${x}_${y}_${_safeId(item.elementId)}',
          layerId: target.tileLayer.id,
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
```

## `packages/map_authoring/lib/src/domains/maps/border_actions.dart`

```dart
import 'dart:convert';

import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import 'semantic_map_action_support.dart';

/// Canonical Border resolution preview bound to map revision and feature seed.
final class BorderPreviewArtifact {
  BorderPreviewArtifact({
    required this.mapId,
    required this.layerId,
    required this.featureId,
    required this.projectRevision,
    required this.seed,
    required this.blueprintId,
    required this.blueprintRevision,
    required this.resolverVersion,
    required this.result,
  }) {
    fingerprint = computeNarrativeProjectFingerprint([
      NarrativeProjectFingerprintEntry(
        relativePath: 'border-preview.json',
        bytes: utf8.encode(jsonEncode(_payload())),
      ),
    ]);
  }

  final String mapId;
  final String layerId;
  final String featureId;
  final String projectRevision;
  final String seed;
  final String blueprintId;
  final int blueprintRevision;
  final int resolverVersion;
  final BorderResolutionResult result;
  late final String fingerprint;

  Map<String, Object?> _payload() => {
        'schema': 'pokemap.border-preview.v1',
        'mapId': mapId,
        'layerId': layerId,
        'featureId': featureId,
        'projectRevision': projectRevision,
        'seed': seed,
        'blueprintId': blueprintId,
        'blueprintRevision': blueprintRevision,
        'resolverVersion': resolverVersion,
        'status': result.status.name,
        'diagnosticCount': result.diagnostics.length,
        'errorCount': result.diagnosticReport.errorCount,
        'warningCount': result.diagnosticReport.warningCount,
        'placementCount': result.materialization?.placements.length ?? 0,
        'groundCellCount': result.materialization?.ground.length ?? 0,
        'inputFingerprint':
            result.materialization?.receipt.inputFingerprint ?? '',
        'outputFingerprint':
            result.materialization?.receipt.outputFingerprint ?? '',
      };

  Map<String, Object?> toJson() => {
        ..._payload(),
        'fingerprint': fingerprint,
      };
}

/// Pure adapter over the canonical Border operations owned by `map_core`.
final class BorderActions {
  const BorderActions();

  static final List<AuthoringActionDescriptor> descriptors = List.unmodifiable([
    _descriptor('border_layer.stroke_add', 'Add a Border feature stroke'),
    _descriptor('border_layer.stroke_update', 'Update a Border feature stroke'),
    _descriptor('border_layer.stroke_delete', 'Delete a Border feature stroke'),
    _descriptor('border_layer.region_fill', 'Fill a Border region mask'),
    _descriptor('border_layer.region_clear', 'Clear a Border region mask'),
    _descriptor('border_layer.feature_create', 'Create a Border feature'),
    _descriptor('border_layer.feature_update', 'Update a Border feature'),
    _descriptor('border_layer.feature_move', 'Move Border feature geometry'),
    _descriptor('border_layer.feature_reorder', 'Reorder a Border feature'),
    _descriptor('border_layer.feature_delete', 'Delete a Border feature'),
    _descriptor(
      'border_layer.feature_set_blueprint',
      'Relink a Border feature to a published blueprint',
    ),
    _descriptor(
      'border_layer.feature_set_variation',
      'Set a deterministic Border slot variation',
    ),
    _descriptor('border_layer.feature_lock', 'Lock a resolved Border slot'),
    _descriptor('border_layer.feature_unlock', 'Unlock a Border slot'),
    _descriptor(
      'border_layer.feature_set_keep_out',
      'Replace Border feature keep-out regions',
    ),
    _descriptor(
      'border_layer.relink_apply',
      'Apply a revision-checked Border blueprint relink',
    ),
    _descriptor(
      'border_layer.materialize_apply',
      'Resolve and persist Border materialization',
    ),
    _descriptor(
      'border_layer.resize_apply',
      'Resize a map and every Border layer atomically',
    ),
  ]);

  BorderBlueprintRevision requirePublishedBlueprint(
    ProjectManifest manifest,
    String blueprintId,
  ) {
    final record = manifest.borderCatalog.recordById(blueprintId);
    if (record == null) {
      throw semanticFailure(
        'border.blueprint_missing',
        'The requested Border blueprint does not exist.',
        details: {'blueprintId': blueprintId},
      );
    }
    final published = record.latestPublished;
    if (published == null) {
      throw semanticFailure(
        'border.blueprint_not_published',
        'A Border feature can only use a published blueprint revision.',
        details: {'blueprintId': blueprintId},
        remediation: const [
          'Resolve publication readiness diagnostics and publish the blueprint.',
        ],
      );
    }
    return published;
  }

  BorderStrokeGeometry editStroke(
    BorderStrokeGeometry base, {
    required BorderStrokeEditingMode mode,
    required List<GridPos> sampledPoints,
  }) {
    if (sampledPoints.isEmpty) {
      throw semanticFailure(
        'border.stroke_points_empty',
        'A Border stroke edit needs at least one sampled point.',
      );
    }
    var draft = BorderStrokeEditingDraft.begin(
      baseGeometry: base,
      mode: mode,
      pointerDown: sampledPoints.first,
    );
    for (final point in sampledPoints.skip(1)) {
      draft = draft.sample(point);
    }
    final geometry = draft.previewGeometry;
    if (geometry == null) {
      throw semanticFailure(
        'border.stroke_too_short',
        'A drawn Border stroke must cover at least two cells.',
      );
    }
    return geometry;
  }

  BorderPreviewArtifact preview({
    required ProjectManifest manifest,
    required MapData map,
    required String layerId,
    required String featureId,
    required String projectRevision,
    required GridSize tileSizePx,
    required int resolverVersion,
  }) {
    _stableText(projectRevision, 'projectRevision');
    final feature = _feature(_borderLayer(map, layerId), featureId);
    final revision = requirePublishedBlueprint(manifest, feature.blueprintId);
    final request = BorderResolutionRequest(
      mapSize: map.size,
      tileSizePx: tileSizePx,
      blueprintId: feature.blueprintId,
      blueprintRevision: revision,
      feature: feature,
      visualSnapshots: manifest.borderCatalog.visualSnapshots,
      resolverVersion: resolverVersion,
    );
    final result = resolveBorderFeature(request);
    return BorderPreviewArtifact(
      mapId: map.id,
      layerId: layerId,
      featureId: featureId,
      projectRevision: projectRevision,
      seed: feature.seed.toString(),
      blueprintId: feature.blueprintId,
      blueprintRevision: revision.revision,
      resolverVersion: resolverVersion,
      result: result,
    );
  }

  BorderDiagnosticsReport diagnostics({
    required ProjectManifest manifest,
    required MapData map,
    required String layerId,
    required String featureId,
    required String projectRevision,
    required GridSize tileSizePx,
    required int resolverVersion,
  }) =>
      preview(
        manifest: manifest,
        map: map,
        layerId: layerId,
        featureId: featureId,
        projectRevision: projectRevision,
        tileSizePx: tileSizePx,
        resolverVersion: resolverVersion,
      ).result.diagnosticReport;

  BorderFeatureRelinkPreview planRelink({
    required ProjectManifest manifest,
    required MapData map,
    required String layerId,
    required String featureId,
    required String targetBlueprintId,
    required GridSize tileSizePx,
    required int resolverVersion,
  }) =>
      prepareBorderFeatureRelink(
        map: map,
        layerId: layerId,
        featureId: featureId,
        targetBlueprintId: targetBlueprintId,
        targetBlueprintRevision:
            requirePublishedBlueprint(manifest, targetBlueprintId),
        visualSnapshots: manifest.borderCatalog.visualSnapshots,
        tileSizePx: tileSizePx,
        resolverVersion: resolverVersion,
      );

  MapResizeWithBorderDiagnosticsResult planResize({
    required MapData map,
    required int width,
    required int height,
    required GridSize tileSizePx,
  }) =>
      resizeMapDataWithBorderDiagnostics(
        map,
        width: width,
        height: height,
        tileSizePx: tileSizePx,
      );

  BorderPublicationReadinessResult publicationReadiness({
    required String blueprintId,
    required BorderBlueprintPublishedDefinition definition,
    required int resolverVersion,
    required ProjectManifest project,
    required List<BorderVisualSnapshot> visualSnapshots,
    required Map<String, BorderVisualSnapshotIntegrity> snapshotIntegrity,
    required BorderPublicationGalleryReport canonicalGalleryReport,
  }) =>
      assessBorderPublicationReadiness(
        blueprintId: blueprintId,
        definition: definition,
        resolverVersion: resolverVersion,
        project: project,
        visualSnapshots: visualSnapshots,
        snapshotIntegrity: snapshotIntegrity,
        canonicalGalleryReport: canonicalGalleryReport,
      );

  AuthoringMutationDraft build(AuthoringPlanningContext planning) {
    final actionId = planning.request.actionId;
    final allowed = switch (actionId) {
      'border_layer.stroke_add' || 'border_layer.stroke_update' => const {
          'layerId',
          'featureId',
          'strokeId',
          'points',
          'closed',
        },
      'border_layer.stroke_delete' => const {
          'layerId',
          'featureId',
          'strokeId',
        },
      'border_layer.region_fill' || 'border_layer.region_clear' => const {
          'layerId',
          'featureId',
          'x',
          'y',
          'width',
          'height',
        },
      'border_layer.feature_create' => const {
          'layerId',
          'featureId',
          'name',
          'blueprintId',
          'seed',
          'geometry',
        },
      'border_layer.feature_update' => const {
          'layerId',
          'featureId',
          'name',
          'seed',
          'lineSide',
          'paramsOverride',
          'clearParamsOverride',
        },
      'border_layer.feature_move' => const {
          'layerId',
          'featureId',
          'dx',
          'dy',
        },
      'border_layer.feature_reorder' => const {
          'layerId',
          'featureId',
          'newIndex',
        },
      'border_layer.feature_delete' => const {'layerId', 'featureId'},
      'border_layer.feature_set_blueprint' ||
      'border_layer.relink_apply' =>
        const {
          'layerId',
          'featureId',
          'targetBlueprintId',
          'tileWidthPx',
          'tileHeightPx',
          'resolverVersion',
          'confirmFamilyReset',
        },
      'border_layer.feature_set_variation' => const {
          'layerId',
          'featureId',
          'slotKey',
          'variationSalt',
        },
      'border_layer.feature_lock' || 'border_layer.feature_unlock' => const {
          'layerId',
          'featureId',
          'slotKey',
        },
      'border_layer.feature_set_keep_out' => const {
          'layerId',
          'featureId',
          'regions',
        },
      'border_layer.materialize_apply' => const {
          'layerId',
          'featureId',
          'tileWidthPx',
          'tileHeightPx',
          'resolverVersion',
        },
      'border_layer.resize_apply' => const {
          'layerId',
          'width',
          'height',
          'tileWidthPx',
          'tileHeightPx',
        },
      _ => throw semanticFailure(
          'map.action_unsupported',
          'The requested Border action is unsupported.',
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
      case 'border_layer.stroke_add':
      case 'border_layer.stroke_update':
        final featureId = parameters.string('featureId');
        final layer = _borderLayer(context.map, layerId);
        final feature = _feature(layer, featureId);
        final geometry = feature.geometry;
        if (geometry is! BorderStrokeGeometry) {
          throw semanticFailure(
            'border.geometry_kind_mismatch',
            'Stroke actions require linear Border geometry.',
          );
        }
        final stroke = BorderStroke(
          id: parameters.string('strokeId'),
          points: _points(parameters.list('points')),
          closed: parameters.contains('closed') && parameters.boolean('closed'),
        );
        final index = geometry.strokes
            .indexWhere((candidate) => candidate.id == stroke.id);
        if (actionId == 'border_layer.stroke_add' && index >= 0) {
          throw semanticFailure(
            'border.stroke_exists',
            'A Border stroke already uses this ID.',
          );
        }
        if (actionId == 'border_layer.stroke_update' && index < 0) {
          throw semanticFailure(
            'border.stroke_missing',
            'The requested Border stroke does not exist.',
          );
        }
        final strokes = List<BorderStroke>.from(geometry.strokes);
        if (index < 0) {
          strokes.add(stroke);
        } else {
          strokes[index] = stroke;
        }
        updated = updateBorderFeatureGeometry(
          context.map,
          layerId: layerId,
          featureId: featureId,
          geometry: BorderStrokeGeometry(
            strokes: strokes,
            alignment: geometry.alignment,
          ),
        );
      case 'border_layer.stroke_delete':
        final featureId = parameters.string('featureId');
        final feature = _feature(_borderLayer(context.map, layerId), featureId);
        final geometry = feature.geometry;
        if (geometry is! BorderStrokeGeometry) {
          throw semanticFailure(
            'border.geometry_kind_mismatch',
            'Stroke actions require linear Border geometry.',
          );
        }
        final strokeId = parameters.string('strokeId');
        if (!geometry.strokes.any((value) => value.id == strokeId)) {
          throw semanticFailure(
            'border.stroke_missing',
            'The requested Border stroke does not exist.',
          );
        }
        updated = updateBorderFeatureGeometry(
          context.map,
          layerId: layerId,
          featureId: featureId,
          geometry: BorderStrokeGeometry(
            strokes: [
              for (final stroke in geometry.strokes)
                if (stroke.id != strokeId) stroke,
            ],
            alignment: geometry.alignment,
          ),
        );
      case 'border_layer.region_fill':
      case 'border_layer.region_clear':
        final featureId = parameters.string('featureId');
        final feature = _feature(_borderLayer(context.map, layerId), featureId);
        final geometry = feature.geometry;
        if (geometry is! BorderRegionGeometry) {
          throw semanticFailure(
            'border.geometry_kind_mismatch',
            'Region actions require region Border geometry.',
          );
        }
        final region = _regionParameters(parameters, context.map.size);
        final cells = List<bool>.from(geometry.cells);
        for (var y = region.y; y < region.bottom; y++) {
          for (var x = region.x; x < region.right; x++) {
            cells[y * geometry.width + x] =
                actionId == 'border_layer.region_fill';
          }
        }
        updated = updateBorderFeatureGeometry(
          context.map,
          layerId: layerId,
          featureId: featureId,
          geometry: BorderRegionGeometry(
            width: geometry.width,
            height: geometry.height,
            cells: cells,
          ),
        );
        changedItems = region.width * region.height;
      case 'border_layer.feature_create':
        final blueprintId = parameters.string('blueprintId');
        final featureId = parameters.string('featureId');
        if (_borderLayer(context.map, layerId).content.featureById(featureId) !=
            null) {
          throw semanticFailure(
            'border.feature_exists',
            'A Border feature already uses this ID.',
            details: {'featureId': featureId},
          );
        }
        final revision = requirePublishedBlueprint(
          context.manifest,
          blueprintId,
        );
        final geometry = _geometry(parameters.object('geometry'));
        if (borderGeometryFamily(geometry) !=
            borderTemplateGeometryFamily(revision.definition.template)) {
          throw semanticFailure(
            'border.geometry_kind_mismatch',
            'The Border geometry is incompatible with the blueprint template.',
          );
        }
        updated = upsertBorderFeature(
          context.map,
          layerId: layerId,
          feature: BorderFeature(
            id: featureId,
            name: parameters.string('name'),
            blueprintId: blueprintId,
            seed: _seed(parameters.value('seed')),
            geometry: geometry,
            overrides: const [],
            keepOutRegions: const [],
          ),
          template: revision.definition.template,
        );
      case 'border_layer.feature_update':
        final featureId = parameters.string('featureId');
        final feature = _feature(_borderLayer(context.map, layerId), featureId);
        final clear = parameters.contains('clearParamsOverride') &&
            parameters.boolean('clearParamsOverride');
        final params = parameters.contains('paramsOverride')
            ? _generationParams(parameters.object('paramsOverride'))
            : feature.paramsOverride;
        final lineSide = parameters.optionalString('lineSide');
        updated = upsertBorderFeature(
          context.map,
          layerId: layerId,
          feature: _copyFeature(
            feature,
            name: parameters.optionalString('name'),
            seed: parameters.contains('seed')
                ? _seed(parameters.value('seed'))
                : null,
            lineSide: lineSide == null ? null : _lineSide(lineSide),
            paramsOverride: clear ? null : params,
            replaceParams: clear || parameters.contains('paramsOverride'),
          ),
        );
      case 'border_layer.feature_move':
        final featureId = parameters.string('featureId');
        final feature = _feature(_borderLayer(context.map, layerId), featureId);
        updated = updateBorderFeatureGeometry(
          context.map,
          layerId: layerId,
          featureId: featureId,
          geometry: _translateGeometry(
            feature.geometry,
            dx: parameters.integer('dx'),
            dy: parameters.integer('dy'),
            mapSize: context.map.size,
          ),
        );
      case 'border_layer.feature_reorder':
        updated = reorderBorderFeature(
          context.map,
          layerId: layerId,
          featureId: parameters.string('featureId'),
          newIndex: parameters.integer('newIndex'),
        );
      case 'border_layer.feature_delete':
        updated = removeBorderFeature(
          context.map,
          layerId: layerId,
          featureId: parameters.string('featureId'),
        );
      case 'border_layer.feature_set_blueprint':
      case 'border_layer.relink_apply':
        final relink = planRelink(
          manifest: context.manifest,
          map: context.map,
          layerId: layerId,
          featureId: parameters.string('featureId'),
          targetBlueprintId: parameters.string('targetBlueprintId'),
          tileSizePx: _tileSize(parameters),
          resolverVersion: parameters.integer('resolverVersion'),
        );
        if (relink.kind == BorderRelinkKind.requiresFamilyReset) {
          if (!parameters.contains('confirmFamilyReset') ||
              !parameters.boolean('confirmFamilyReset')) {
            throw semanticFailure(
              'border.relink_confirmation_required',
              'Changing Border geometry family requires explicit confirmation.',
              details: {
                'losses': relink.losses.map((value) => value.name).toList(),
              },
            );
          }
          updated = applyBorderFeatureFamilyReset(
            context.map,
            preview: relink,
          );
        } else {
          if (relink.proposedResult?.canApply != true) {
            throw semanticFailure(
              'border.relink_resolution_failed',
              'The target Border blueprint cannot resolve this feature.',
              details: {
                'diagnosticCount':
                    relink.proposedResult?.diagnostics.length ?? 0,
              },
            );
          }
          updated = applyBorderFeatureRelinkPreview(
            context.map,
            preview: relink,
          );
        }
        extraPreview['relinkKind'] = relink.kind.name;
        extraPreview['losses'] =
            relink.losses.map((value) => value.name).toList();
      case 'border_layer.feature_set_variation':
        final featureId = parameters.string('featureId');
        final feature = _feature(_borderLayer(context.map, layerId), featureId);
        final slotKey = parameters.string('slotKey');
        final salt = _seed(parameters.value('variationSalt'));
        final overrides = List<BorderSlotOverride>.from(feature.overrides);
        final index = overrides.indexWhere((value) => value.slotKey == slotKey);
        final current = index < 0 ? null : overrides[index];
        final replacement = BorderSlotOverride(
          slotKey: slotKey,
          variationSalt: salt,
          suppressed: current?.suppressed ?? false,
          locked: current?.locked ?? false,
          lockedPlacement: current?.lockedPlacement,
          replacementPrimitiveId: current?.replacementPrimitiveId,
          offsetDeltaPx: current?.offsetDeltaPx,
          transformOverride: current?.transformOverride,
        );
        if (index < 0) {
          overrides.add(replacement);
        } else {
          overrides[index] = replacement;
        }
        updated = updateBorderFeatureOverrides(
          context.map,
          layerId: layerId,
          featureId: featureId,
          overrides: overrides,
        );
      case 'border_layer.feature_lock':
        updated = _setSlotLock(
          context.map,
          layerId: layerId,
          featureId: parameters.string('featureId'),
          slotKey: parameters.string('slotKey'),
          locked: true,
        );
      case 'border_layer.feature_unlock':
        updated = _setSlotLock(
          context.map,
          layerId: layerId,
          featureId: parameters.string('featureId'),
          slotKey: parameters.string('slotKey'),
          locked: false,
        );
      case 'border_layer.feature_set_keep_out':
        updated = updateBorderFeatureKeepOutRegions(
          context.map,
          layerId: layerId,
          featureId: parameters.string('featureId'),
          keepOutRegions: _keepOutRegions(parameters.list('regions')),
        );
      case 'border_layer.materialize_apply':
        final featureId = parameters.string('featureId');
        final artifact = preview(
          manifest: context.manifest,
          map: context.map,
          layerId: layerId,
          featureId: featureId,
          projectRevision: context.resource.revision!,
          tileSizePx: _tileSize(parameters),
          resolverVersion: parameters.integer('resolverVersion'),
        );
        if (!artifact.result.canApply) {
          throw semanticFailure(
            'border.materialization_failed',
            'Border resolution diagnostics prevent materialization.',
            details: {
              'diagnosticCount': artifact.result.diagnostics.length,
              'errorCount': artifact.result.diagnosticReport.errorCount,
            },
          );
        }
        final feature = _feature(_borderLayer(context.map, layerId), featureId);
        final revision = requirePublishedBlueprint(
          context.manifest,
          feature.blueprintId,
        );
        final request = BorderResolutionRequest(
          mapSize: context.map.size,
          tileSizePx: _tileSize(parameters),
          blueprintId: feature.blueprintId,
          blueprintRevision: revision,
          feature: feature,
          visualSnapshots: context.manifest.borderCatalog.visualSnapshots,
          resolverVersion: parameters.integer('resolverVersion'),
        );
        updated = applyBorderFeaturePreview(
          context.map,
          expectedMapId: context.map.id,
          layerId: layerId,
          featureId: featureId,
          expectedBaseFeatureFingerprint:
              computeBorderFeatureEditFingerprint(feature),
          proposedRequest: request,
          proposedResult: artifact.result,
        );
        extraPreview['borderPreview'] = artifact.toJson();
        changedItems = artifact.result.materialization!.placements.length +
            artifact.result.materialization!.ground.length;
      case 'border_layer.resize_apply':
        final result = planResize(
          map: context.map,
          width: parameters.integer('width'),
          height: parameters.integer('height'),
          tileSizePx: _tileSize(parameters),
        );
        if (!result.canApply || result.map == null) {
          throw semanticFailure(
            'border.resize_failed',
            'Border diagnostics prevent the requested map resize.',
            details: {
              'diagnosticCount': result.diagnosticReport.diagnosticCount,
              'errorCount': result.diagnosticReport.errorCount,
            },
          );
        }
        updated = result.map!;
        changedItems = updated.size.width * updated.size.height;
        extraPreview['diagnosticCount'] =
            result.diagnosticReport.diagnosticCount;
      default:
        throw StateError('unreachable Border action');
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

AuthoringActionDescriptor _descriptor(String id, String summary) =>
    semanticActionDescriptor(id, summary);

BorderLayer _borderLayer(MapData map, String layerId) {
  final layer =
      map.layers.where((candidate) => candidate.id == layerId).firstOrNull;
  if (layer is! BorderLayer) {
    throw semanticFailure(
      'border.layer_missing',
      'The requested layer is missing or is not a Border layer.',
      details: {'layerId': layerId},
    );
  }
  return layer;
}

BorderFeature _feature(BorderLayer layer, String featureId) {
  final feature = layer.content.featureById(featureId);
  if (feature == null) {
    throw semanticFailure(
      'border.feature_missing',
      'The requested Border feature does not exist.',
      details: {'layerId': layer.id, 'featureId': featureId},
    );
  }
  return feature;
}

BorderFeature _copyFeature(
  BorderFeature feature, {
  String? name,
  BorderSignedInt64? seed,
  BorderFeatureGeometry? geometry,
  BorderLineSide? lineSide,
  BorderGenerationParams? paramsOverride,
  bool replaceParams = false,
  List<BorderSlotOverride>? overrides,
  List<BorderKeepOutRegion>? keepOutRegions,
  BorderMaterialization? materialization,
  bool clearMaterialization = true,
}) =>
    BorderFeature(
      id: feature.id,
      name: name ?? feature.name,
      blueprintId: feature.blueprintId,
      seed: seed ?? feature.seed,
      geometry: geometry ?? feature.geometry,
      lineSide: lineSide ?? feature.lineSide,
      paramsOverride: replaceParams ? paramsOverride : feature.paramsOverride,
      overrides: overrides ?? feature.overrides,
      keepOutRegions: keepOutRegions ?? feature.keepOutRegions,
      materialization: clearMaterialization
          ? null
          : materialization ?? feature.materialization,
    );

BorderSignedInt64 _seed(Object? value) {
  try {
    return switch (value) {
      int value => BorderSignedInt64.fromInt(value),
      String value => BorderSignedInt64.parse(value),
      _ => throw const FormatException(),
    };
  } on Object {
    throw semanticFailure(
      'border.seed_invalid',
      'A Border seed must be an integer or canonical signed 64-bit string.',
    );
  }
}

BorderLineSide _lineSide(String value) => switch (value) {
      'primary' => BorderLineSide.primary,
      'inverted' => BorderLineSide.inverted,
      _ => throw invalidSemanticField(
          'lineSide',
          '"primary" or "inverted"',
        ),
    };

GridSize _tileSize(SemanticParameters parameters) {
  final size = GridSize(
    width: parameters.integer('tileWidthPx'),
    height: parameters.integer('tileHeightPx'),
  );
  if (size.width <= 0 || size.height <= 0) {
    throw semanticFailure(
      'border.tile_size_invalid',
      'Border tile pixel dimensions must be positive.',
    );
  }
  return size;
}

List<GridPos> _points(List<Object?> values) {
  final points = <GridPos>[];
  for (var index = 0; index < values.length; index++) {
    final value = values[index];
    if (value is! Map || value.keys.any((key) => key is! String)) {
      throw invalidSemanticField('points[$index]', 'an {x, y} object');
    }
    final point = Map<String, Object?>.from(value);
    if (point.keys.any((key) => key != 'x' && key != 'y') ||
        point['x'] is! int ||
        point['y'] is! int) {
      throw invalidSemanticField('points[$index]', 'integer x and y fields');
    }
    points.add(GridPos(x: point['x']! as int, y: point['y']! as int));
  }
  return points;
}

BorderFeatureGeometry _geometry(Map<String, Object?> value) {
  final kind = value['kind'];
  switch (kind) {
    case 'region':
      final width = value['width'];
      final height = value['height'];
      final cells = value['cells'];
      if (width is! int || height is! int || cells is! List) {
        throw invalidSemanticField(
          'geometry',
          'region width, height and boolean cells',
        );
      }
      if (cells.any((cell) => cell is! bool)) {
        throw invalidSemanticField('geometry.cells', 'booleans');
      }
      return BorderRegionGeometry(
        width: width,
        height: height,
        cells: cells.cast<bool>(),
      );
    case 'stroke':
      final rawStrokes = value['strokes'];
      if (rawStrokes is! List) {
        throw invalidSemanticField('geometry.strokes', 'a list');
      }
      final alignment = switch (value['alignment']) {
        null || 'cellCenters' => BorderStrokeAlignment.cellCenters,
        'gridEdges' => BorderStrokeAlignment.gridEdges,
        _ => throw invalidSemanticField(
            'geometry.alignment',
            '"cellCenters" or "gridEdges"',
          ),
      };
      return BorderStrokeGeometry(
        alignment: alignment,
        strokes: [
          for (var index = 0; index < rawStrokes.length; index++)
            _stroke(rawStrokes[index], index),
        ],
      );
    default:
      throw invalidSemanticField('geometry.kind', '"region" or "stroke"');
  }
}

BorderStroke _stroke(Object? raw, int index) {
  if (raw is! Map || raw.keys.any((key) => key is! String)) {
    throw invalidSemanticField('geometry.strokes[$index]', 'an object');
  }
  final value = Map<String, Object?>.from(raw);
  final id = value['id'];
  final points = value['points'];
  final closed = value['closed'] ?? false;
  if (id is! String || points is! List || closed is! bool) {
    throw invalidSemanticField(
      'geometry.strokes[$index]',
      'id, points and optional closed fields',
    );
  }
  return BorderStroke(
    id: id,
    points: _points(List<Object?>.from(points)),
    closed: closed,
  );
}

BorderGenerationParams _generationParams(Map<String, Object?> value) {
  const allowed = {
    'irregularityPermille',
    'detailDensityPermille',
    'variationPermille',
    'maxOverlapPx',
    'gapTolerancePx',
    'depthRows',
    'allowAutoRotation',
  };
  if (value.keys.any((key) => !allowed.contains(key))) {
    throw invalidSemanticField(
      'paramsOverride',
      'only canonical Border generation fields',
    );
  }
  int field(String key) {
    final raw = value[key];
    if (raw is! int) {
      throw invalidSemanticField('paramsOverride.$key', 'an integer');
    }
    return raw;
  }

  final rotation = value['allowAutoRotation'];
  if (rotation != null && rotation is! bool) {
    throw invalidSemanticField(
      'paramsOverride.allowAutoRotation',
      'a boolean',
    );
  }
  return BorderGenerationParams(
    irregularityPermille: field('irregularityPermille'),
    detailDensityPermille: field('detailDensityPermille'),
    variationPermille: field('variationPermille'),
    maxOverlapPx: field('maxOverlapPx'),
    gapTolerancePx: field('gapTolerancePx'),
    depthRows: field('depthRows'),
    allowAutoRotation: rotation as bool? ?? true,
  );
}

_BorderEditRegion _regionParameters(
  SemanticParameters parameters,
  GridSize size,
) {
  final region = _BorderEditRegion(
    x: parameters.integer('x'),
    y: parameters.integer('y'),
    width: parameters.integer('width'),
    height: parameters.integer('height'),
  );
  if (region.x < 0 ||
      region.y < 0 ||
      region.width <= 0 ||
      region.height <= 0 ||
      region.right > size.width ||
      region.bottom > size.height) {
    throw semanticFailure(
      'border.region_out_of_bounds',
      'The Border edit region is outside map bounds.',
    );
  }
  return region;
}

final class _BorderEditRegion {
  const _BorderEditRegion({
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
}

BorderFeatureGeometry _translateGeometry(
  BorderFeatureGeometry geometry, {
  required int dx,
  required int dy,
  required GridSize mapSize,
}) {
  switch (geometry) {
    case BorderStrokeGeometry geometry:
      final strokes = <BorderStroke>[];
      for (final stroke in geometry.strokes) {
        final points = [
          for (final point in stroke.points)
            GridPos(x: point.x + dx, y: point.y + dy),
        ];
        if (points.any(
          (point) =>
              point.x < 0 ||
              point.y < 0 ||
              point.x >= mapSize.width ||
              point.y >= mapSize.height,
        )) {
          throw semanticFailure(
            'border.feature_out_of_bounds',
            'Moving the Border feature would leave map bounds.',
          );
        }
        strokes.add(
          BorderStroke(id: stroke.id, points: points, closed: stroke.closed),
        );
      }
      return BorderStrokeGeometry(
        strokes: strokes,
        alignment: geometry.alignment,
      );
    case BorderRegionGeometry geometry:
      final cells = List<bool>.filled(geometry.width * geometry.height, false);
      for (var y = 0; y < geometry.height; y++) {
        for (var x = 0; x < geometry.width; x++) {
          if (!geometry.cells[y * geometry.width + x]) continue;
          final targetX = x + dx;
          final targetY = y + dy;
          if (targetX < 0 ||
              targetY < 0 ||
              targetX >= geometry.width ||
              targetY >= geometry.height) {
            throw semanticFailure(
              'border.feature_out_of_bounds',
              'Moving the Border feature would leave map bounds.',
            );
          }
          cells[targetY * geometry.width + targetX] = true;
        }
      }
      return BorderRegionGeometry(
        width: geometry.width,
        height: geometry.height,
        cells: cells,
      );
  }
}

List<BorderKeepOutRegion> _keepOutRegions(List<Object?> values) => [
      for (var index = 0; index < values.length; index++)
        _keepOutRegion(values[index], index),
    ];

BorderKeepOutRegion _keepOutRegion(Object? raw, int index) {
  if (raw is! Map || raw.keys.any((key) => key is! String)) {
    throw invalidSemanticField('regions[$index]', 'an object');
  }
  final value = Map<String, Object?>.from(raw);
  final id = value['id'];
  final region = value['region'];
  if (id is! String || region is! Map) {
    throw invalidSemanticField('regions[$index]', 'id and region fields');
  }
  final geometry = _geometry({
    'kind': 'region',
    ...Map<String, Object?>.from(region),
  });
  return BorderKeepOutRegion(
    id: id,
    region: geometry as BorderRegionGeometry,
  );
}

MapData _setSlotLock(
  MapData map, {
  required String layerId,
  required String featureId,
  required String slotKey,
  required bool locked,
}) {
  final feature = _feature(_borderLayer(map, layerId), featureId);
  final overrides = List<BorderSlotOverride>.from(feature.overrides);
  final overrideIndex =
      overrides.indexWhere((value) => value.slotKey == slotKey);
  final current = overrideIndex < 0 ? null : overrides[overrideIndex];
  if (locked) {
    final placement = feature.materialization?.placements
        .where((value) => value.slotKey == slotKey)
        .firstOrNull;
    if (placement == null) {
      throw semanticFailure(
        'border.slot_not_resolved',
        'A Border slot must be materialized before it can be locked.',
        details: {'slotKey': slotKey},
      );
    }
    final replacement = BorderSlotOverride(
      slotKey: slotKey,
      variationSalt: current?.variationSalt ?? BorderSignedInt64.zero,
      suppressed: false,
      locked: true,
      lockedPlacement: placement,
      replacementPrimitiveId: current?.replacementPrimitiveId,
      offsetDeltaPx: current?.offsetDeltaPx,
      transformOverride: current?.transformOverride,
    );
    if (overrideIndex < 0) {
      overrides.add(replacement);
    } else {
      overrides[overrideIndex] = replacement;
    }
  } else {
    if (current == null || !current.locked) {
      throw semanticFailure(
        'border.slot_not_locked',
        'The requested Border slot is not locked.',
        details: {'slotKey': slotKey},
      );
    }
    final hasOtherOverride = current.variationSalt != BorderSignedInt64.zero ||
        current.replacementPrimitiveId != null ||
        current.offsetDeltaPx != null ||
        current.transformOverride != null;
    if (!hasOtherOverride) {
      overrides.removeAt(overrideIndex);
    } else {
      overrides[overrideIndex] = BorderSlotOverride(
        slotKey: slotKey,
        variationSalt: current.variationSalt,
        suppressed: false,
        locked: false,
        replacementPrimitiveId: current.replacementPrimitiveId,
        offsetDeltaPx: current.offsetDeltaPx,
        transformOverride: current.transformOverride,
      );
    }
  }
  return updateBorderFeatureOverrides(
    map,
    layerId: layerId,
    featureId: featureId,
    overrides: overrides,
  );
}

void _stableText(String value, String field) {
  if (value.isEmpty || value.trim() != value) {
    throw semanticFailure(
      'border.request_invalid',
      '$field must be a nonblank trimmed string.',
    );
  }
}
```

## `packages/map_authoring/test/domains/maps/environment_actions_test.dart`

```dart
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('EnvironmentActions', () {
    test('generation preview is deterministic and revision/seed bound', () {
      final fixture = _fixture();
      const actions = EnvironmentActions();

      final first = actions.previewGeneration(
        manifest: fixture.manifest,
        map: fixture.map,
        layerId: 'env',
        areaId: 'forest-area',
        projectRevision: 'map-revision-1',
      );
      final second = actions.previewGeneration(
        manifest: fixture.manifest,
        map: fixture.map,
        layerId: 'env',
        areaId: 'forest-area',
        projectRevision: 'map-revision-1',
      );

      expect(second.fingerprint, first.fingerprint);
      expect(first.projectRevision, 'map-revision-1');
      expect(first.seed, 37);
      expect(first.placements, isNotEmpty);
      expect(
        actions
            .previewGeneration(
              manifest: fixture.manifest,
              map: fixture.map,
              layerId: 'env',
              areaId: 'forest-area',
              projectRevision: 'map-revision-2',
            )
            .fingerprint,
        isNot(first.fingerprint),
      );
    });

    test('local regeneration changes only its documented one-cell halo', () {
      final fixture = _fixture();
      const actions = EnvironmentActions();
      final fullPreview = actions.previewGeneration(
        manifest: fixture.manifest,
        map: fixture.map,
        layerId: 'env',
        areaId: 'forest-area',
        projectRevision: 'map-revision-1',
      );
      final generated = actions.applyGeneration(
        manifest: fixture.manifest,
        map: fixture.map,
        preview: fullPreview,
        currentRevision: 'map-revision-1',
      );
      final outside = generated.placedElements.singleWhere(
        (placement) => placement.pos == const GridPos(x: 5, y: 3),
      );
      final marked = generated.copyWith(
        placedElements: [
          for (final placement in generated.placedElements)
            if (placement.id == outside.id)
              placement.copyWith(properties: const {'outside': 'preserve'})
            else
              placement,
        ],
      );

      final localPreview = actions.previewGeneration(
        manifest: fixture.manifest,
        map: marked,
        layerId: 'env',
        areaId: 'forest-area',
        projectRevision: 'map-revision-2',
        region: const EnvironmentGenerationRegion(
          x: 2,
          y: 1,
          width: 1,
          height: 1,
        ),
      );
      final regenerated = actions.applyGeneration(
        manifest: fixture.manifest,
        map: marked,
        preview: localPreview,
        currentRevision: 'map-revision-2',
      );

      expect(localPreview.haloCells, 1);
      expect(
        localPreview.resolutionRegion,
        const EnvironmentGenerationRegion(x: 1, y: 0, width: 3, height: 3),
      );
      expect(
        regenerated.placedElements
            .singleWhere((placement) => placement.id == outside.id)
            .properties,
        const {'outside': 'preserve'},
      );
    });

    test('canonical dispatcher exposes area, mask, generation and overrides',
        () {
      final ids = MapMutationDispatcher.canonical()
          .descriptors
          .map((descriptor) => descriptor.id)
          .toSet();

      expect(
        ids,
        containsAll(<String>{
          'environment.area_create',
          'environment.area_update',
          'environment.area_delete',
          'environment.mask_paint',
          'environment.mask_erase',
          'environment.generate_apply',
          'environment.regenerate_apply',
          'environment.generated_placement_add',
          'environment.generated_placement_move',
          'environment.generated_placement_delete',
        }),
      );
    });
  });
}

({ProjectManifest manifest, MapData map}) _fixture() {
  final preset = EnvironmentPreset(
    id: 'forest',
    name: 'Forest',
    templateId: 'forest',
    palette: [
      EnvironmentPaletteItem(elementId: 'tree', weight: 1),
    ],
    defaultParams: EnvironmentGenerationParams(
      density: 1,
      variation: 0,
      edgeDensity: 1,
      minSpacingCells: 0,
    ),
    sortOrder: 0,
  );
  final manifest = ProjectManifest(
    name: 'Environment test',
    maps: const [],
    tilesets: const [],
    elements: const [
      ProjectElementEntry(
        id: 'tree',
        name: 'Tree',
        tilesetId: 'nature',
        categoryId: 'decor',
        frames: [
          TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
        ],
      ),
    ],
    environmentPresets: [preset],
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
  );
  final area = EnvironmentArea(
    id: 'forest-area',
    name: 'Forest area',
    presetId: 'forest',
    mask: EnvironmentAreaMask(
      width: 6,
      height: 4,
      cells: List<bool>.filled(24, true),
    ),
    seed: 37,
  );
  final map = MapData(
    id: 'map',
    name: 'Map',
    tilesetId: 'nature',
    size: const GridSize(width: 6, height: 4),
    layers: [
      MapLayer.environment(
        id: 'env',
        name: 'Environment',
        content: EnvironmentLayerContent(
          targetTileLayerId: 'ground',
          areas: [area],
        ),
      ),
      MapLayer.tile(
        id: 'ground',
        name: 'Ground',
        tilesetId: 'nature',
        tiles: List<int>.filled(24, 0),
      ),
    ],
  );
  return (manifest: manifest, map: map);
}
```

## `packages/map_authoring/test/domains/maps/border_actions_test.dart`

```dart
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('BorderActions', () {
    test('refuses a blueprint without a published revision', () {
      final manifest = ProjectManifest(
        name: 'Border test',
        maps: const [],
        tilesets: const [],
        surfaceCatalog: const ProjectSurfaceCatalog.empty(),
        borderCatalog: ProjectBorderCatalog(
          records: [_draftOnlyRecord()],
        ),
      );

      expect(
        () => const BorderActions().requirePublishedBlueprint(
          manifest,
          'draft-border',
        ),
        throwsA(
          isA<MapAuthoringException>().having(
            (error) => error.code,
            'code',
            'border.blueprint_not_published',
          ),
        ),
      );
    });

    test('stroke draw adapts canonical core editing and preserves base stroke',
        () {
      final base = BorderStrokeGeometry(
        strokes: [
          BorderStroke(
            id: 'existing',
            points: const [GridPos(x: 0, y: 0), GridPos(x: 1, y: 0)],
            closed: false,
          ),
        ],
      );

      final edited = const BorderActions().editStroke(
        base,
        mode: BorderStrokeEditingMode.draw,
        sampledPoints: const [GridPos(x: 2, y: 2), GridPos(x: 2, y: 4)],
      );

      expect(edited.strokes, hasLength(2));
      expect(edited.strokes.first.id, 'existing');
      expect(edited.strokes.last.points, const [
        GridPos(x: 2, y: 2),
        GridPos(x: 2, y: 3),
        GridPos(x: 2, y: 4),
      ]);
    });

    test('preview fingerprint changes with revision and feature seed', () {
      final result = BorderResolutionResult(
        materialization: null,
        diagnosticReport: BorderDiagnosticsReport(
          diagnostics: [
            BorderDiagnostic(
              code: 'border.test.expected_error',
              severity: BorderDiagnosticSeverity.error,
              phase: BorderDiagnosticPhase.authoring,
              scope: BorderDiagnosticScope.feature,
              suggestedAction: 'border.test.fix',
            ),
          ],
        ),
      );
      BorderPreviewArtifact artifact(String revision, String seed) =>
          BorderPreviewArtifact(
            mapId: 'map',
            layerId: 'border',
            featureId: 'feature',
            projectRevision: revision,
            seed: seed,
            blueprintId: 'blueprint',
            blueprintRevision: 2,
            resolverVersion: 1,
            result: result,
          );

      final baseline = artifact('map-revision-1', '37');
      expect(
          artifact('map-revision-1', '37').fingerprint, baseline.fingerprint);
      expect(
        artifact('map-revision-2', '37').fingerprint,
        isNot(baseline.fingerprint),
      );
      expect(
        artifact('map-revision-1', '38').fingerprint,
        isNot(baseline.fingerprint),
      );
    });

    test('canonical dispatcher exposes feature, relink, materialize and resize',
        () {
      final ids = MapMutationDispatcher.canonical()
          .descriptors
          .map((descriptor) => descriptor.id)
          .toSet();

      expect(
        ids,
        containsAll(<String>{
          'border_layer.feature_create',
          'border_layer.feature_delete',
          'border_layer.stroke_add',
          'border_layer.stroke_update',
          'border_layer.relink_apply',
          'border_layer.materialize_apply',
          'border_layer.resize_apply',
        }),
      );
    });
  });
}

BorderBlueprintRecord _draftOnlyRecord() => BorderBlueprintRecord(
      id: 'draft-border',
      draft: BorderBlueprintDraft(
        baseRevision: 0,
        definition: BorderBlueprintDraftDefinition(
          name: 'Draft border',
          previewSeed: BorderSignedInt64.zero,
          template: BorderBlueprintTemplate.masonryLine,
          primitives: const [],
          defaults: BorderGenerationParams(
            irregularityPermille: 0,
            detailDensityPermille: 0,
            variationPermille: 0,
            maxOverlapPx: 0,
            gapTolerancePx: 0,
            depthRows: 1,
          ),
          ground: null,
          categoryId: null,
          sortOrder: 0,
        ),
      ),
    );
```
