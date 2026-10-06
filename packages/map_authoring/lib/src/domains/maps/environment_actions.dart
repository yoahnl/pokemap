import 'package:map_core/map_core.dart';

import '../../editing/environment_editing.dart';
import '../../contracts/action_descriptor.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import 'semantic_map_action_support.dart';

export '../../editing/environment_editing.dart'
    show
        EnvironmentGeneratedPlacement,
        EnvironmentGenerationPreview,
        EnvironmentGenerationRegion;

final class EnvironmentActions extends EnvironmentEditing {
  const EnvironmentActions();

  static const generationHaloCells = EnvironmentEditing.generationHaloCells;
  static const maxGenerationCells = EnvironmentEditing.maxGenerationCells;

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
          'cells',
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
        updated = attachToTileLayer(
          context.map,
          layerId: layerId,
          targetTileLayerId: parameters.string('targetTileLayerId'),
        );
      case 'environment.detach_from_tile_layer':
        updated = detachFromTileLayer(
          context.map,
          layerId: layerId,
        );
      case 'environment.area_create':
        updated = createArea(
          context.map,
          manifest: context.manifest,
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
        updated = updateArea(
          context.map,
          manifest: context.manifest,
          layerId: layerId,
          areaId: parameters.string('areaId'),
          name: parameters.optionalString('name'),
          presetId: parameters.optionalString('presetId'),
          seed: parameters.optionalInteger('seed'),
          paramsOverride: parameters.contains('paramsOverride')
              ? _params(parameters.object('paramsOverride'))
              : null,
          clearParamsOverride: clear,
        );
      case 'environment.area_delete':
        updated = deleteArea(
          context.map,
          layerId: layerId,
          areaId: parameters.string('areaId'),
        );
      case 'environment.area_set_preset':
        updated = updateArea(context.map,
            manifest: context.manifest,
            layerId: layerId,
            areaId: parameters.string('areaId'),
            presetId: parameters.string('presetId'));
      case 'environment.area_set_seed':
        updated = setSeed(context.map,
            layerId: layerId,
            areaId: parameters.string('areaId'),
            seed: parameters.integer('seed'));
      case 'environment.mask_paint':
      case 'environment.mask_erase':
        final region = _parameterRegion(parameters, context.map.size);
        final hasCells = parameters.contains('cells');
        if ((region == null) == !hasCells) {
          throw invalidSemanticField(
            'maskSelection',
            'exactly one rectangular region or explicit cell list',
          );
        }
        if (hasCells) {
          final cells = EnvironmentEditing.parseMaskCells(
            parameters.list('cells'),
            context.map.size,
          );
          updated = paintCells(
            context.map,
            layerId: layerId,
            areaId: parameters.string('areaId'),
            cells: [for (final cell in cells) GridPos(x: cell.x, y: cell.y)],
            value: actionId == 'environment.mask_paint',
          );
          changedItems = cells.length;
          extraPreview['editedCellCount'] = cells.length;
        } else {
          updated = paintRegion(
            context.map,
            layerId: layerId,
            areaId: parameters.string('areaId'),
            region: region!,
            value: actionId == 'environment.mask_paint',
          );
          changedItems = region.width * region.height;
          extraPreview['editedRegion'] = region.toJson();
        }
        extraPreview['regenerationHaloCells'] = generationHaloCells;
      case 'environment.mask_clear':
        updated = clearMask(
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
        final area = areaOf(context.map, layerId: layerId, areaId: areaId);
        final nextSeed = parameters.optionalInteger('newSeed') ??
            EnvironmentEditing.nextSeed(area.seed);
        final seeded = setSeed(context.map,
            layerId: layerId, areaId: areaId, seed: nextSeed);
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
        updated = addGeneratedPlacement(
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
        updated = moveGeneratedPlacement(
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
        updated = deleteGeneratedPlacement(
          context.map,
          layerId: layerId,
          areaId: parameters.string('areaId'),
          placementId: parameters.string('placementId'),
        );
      case 'environment.generated_placements_clear':
        final area = areaOf(context.map,
            layerId: layerId, areaId: parameters.string('areaId'));
        changedItems = area.generatedPlacementIds.length;
        updated = clearGeneratedPlacements(
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
  EnvironmentEditing.validateRegion(region, size);
  return region;
}

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
