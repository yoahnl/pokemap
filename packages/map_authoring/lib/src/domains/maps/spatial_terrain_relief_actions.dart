import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import 'map_action_examples.dart';
import 'semantic_map_action_support.dart';

final class SpatialTerrainReliefActions {
  const SpatialTerrainReliefActions();

  static const paintHeight = 'map3d.terrain.paint_height';

  static final descriptor = AuthoringActionDescriptor(
    id: paintHeight,
    version: 1,
    summary:
        'Paint cells at an absolute level and trace their cliffs in one edit',
    inputSchemaId: 'schema.$paintHeight.input.v1',
    outputSchemaId: 'schema.map.semantic_mutation.output.v1',
    riskLevel: AuthoringRiskLevel.low,
    resourceKinds: const ['map'],
    requiredPermissions: const [AuthoringPermission.projectWrite],
    guarantees: const [
      AuthoringGuarantee.dryRun,
      AuthoringGuarantee.idempotent,
      AuthoringGuarantee.revisionChecked,
      AuthoringGuarantee.undoable,
      AuthoringGuarantee.atomic,
    ],
    extensions: {
      'inputExample': mapActionInputExample(paintHeight),
      'batchAtomicity': 'all_or_nothing',
      'undoBoundary': 'action',
      'heightUnit': 'level; height = level * spatialScene.levelHeight',
      'lowerLevelDigs': true,
      'cliffs':
          'one-level steps use blueprintId, two-level steps twoLevelBlueprintId; existing cliffs on the old or new contour are updated or deleted; borders within two cells are rematerialized',
      'refusalCodes': const [
        'spatial.relief.profile_unavailable',
        'spatial.relief.profile_faces_high_side',
        'spatial.relief.profile_level_span',
        'spatial.relief.level_invalid',
        'spatial.relief.step_not_level',
        'spatial.relief.two_level_profile_missing',
        'spatial.relief.step_too_high',
        'spatial.relief.step_ambiguous',
        'spatial.relief.trace_refused',
        'spatial.relief.profile_incompatible',
        'spatial.terrain.paint.surface_limit',
        'spatial.terrain.paint.footprint_limit',
        'spatial.terrain.paint.ramp_conflict',
      ],
      'warnings': const ['zone_unreachable'],
      'inputSchema': {
        'type': 'object',
        'additionalProperties': false,
        'required': ['mapId', 'level', 'blueprintId'],
        'oneOf': [
          {
            'required': ['cells'],
          },
          {
            'required': ['region'],
          },
        ],
        'properties': {
          'mapId': _id,
          'level': {'type': 'integer', 'minimum': 0, 'maximum': 1024},
          'blueprintId': _id,
          'twoLevelBlueprintId': _id,
          'layerId': _id,
          'reanchorInstances': {'type': 'boolean', 'default': true},
          'cells': {
            'type': 'array',
            'minItems': 1,
            'maxItems': 4096,
            'items': _cell,
          },
          'region': _region,
        },
      },
    },
  );

  AuthoringMutationDraft build(AuthoringPlanningContext planning) =>
      project(planning).finalize();

  SemanticMapProjection project(
    AuthoringPlanningContext planning, {
    MapData? projectedMap,
    bool deferFinalization = false,
  }) {
    final context = SemanticMapActionContext.read(
      planning,
      projectedMap: projectedMap,
      deferFinalization: deferFinalization,
      allowedParameters: {
        'cells',
        'region',
        'level',
        'blueprintId',
        'twoLevelBlueprintId',
        'layerId',
        'reanchorInstances',
      },
    );
    if (context.manifest.settings.dimension != ProjectDimension.threeD ||
        context.map.spatialScene == null) {
      throw semanticFailure(
        'map3d.dimension_required',
        'Painting a relief requires a 3D project and map.',
      );
    }
    final parameters = context.parameters;
    final hasCells = parameters.contains('cells');
    if (hasCells == parameters.contains('region')) {
      throw semanticFailure(
        'map3d.terrain.paint_height.selection_invalid',
        'Provide cells or a region.',
      );
    }
    try {
      final cells = hasCells
          ? _cells(parameters.list('cells'))
          : _regionCells(parameters.object('region'));
      final painted = paintTerrainRelief(
        manifest: context.manifest,
        map: context.map,
        cells: cells,
        level: parameters.integer('level'),
        blueprintId: parameters.string('blueprintId'),
        twoLevelBlueprintId: parameters.optionalString('twoLevelBlueprintId'),
        layerId: parameters.optionalString('layerId'),
        reanchorInstances: !parameters.contains('reanchorInstances') ||
            parameters.boolean('reanchorInstances'),
      );
      return context.projectMap(
        after: painted.map,
        operation: paintHeight,
        changedItems: painted.surfaces.upsertedSurfaceIds.length +
            painted.surfaces.deletedSurfaceIds.length +
            painted.traces.length,
        preview: reliefPaintPreview(painted),
      );
    } on ValidationException catch (error) {
      throw semanticFailure(
        error.code ?? 'map3d.terrain.paint_height.invalid',
        error.message,
        details: error.details,
      );
    } on FormatException catch (error) {
      throw semanticFailure(
        'map3d.terrain.paint_height.invalid',
        error.message,
      );
    }
  }
}

Map<String, Object?> reliefPaintPreview(TerrainReliefPaint painted) => {
      'surfaceId': painted.surfaces.surfaceId,
      'upsertedSurfaceIds': painted.surfaces.upsertedSurfaceIds,
      'deletedSurfaceIds': painted.surfaces.deletedSurfaceIds,
      'traces': [
        for (final trace in painted.traces)
          {
            'lowerHeight': trace.lowerHeight,
            'upperHeight': trace.upperHeight,
            'layerId': trace.layerId,
            'featureId': trace.featureId,
            'blueprintId': trace.blueprintId,
            'change': trace.change.name,
          },
      ],
      'refreshedBorderFeatures': painted.refreshedBorders,
      'staleBorderFeatures': painted.staleBorders,
      'warnings': [if (painted.unreachable) 'zone_unreachable'],
      'work': {
        'borderResolutions': painted.resolvedBorderFeatures.length,
        'resolvedBorderFeatures':
            painted.resolvedBorderFeatures.take(20).toList(),
      },
    };

List<GridPos> _cells(List<Object?> values) => [
      for (final value in values)
        if (value is Map && value['x'] is int && value['y'] is int)
          GridPos(x: value['x'] as int, y: value['y'] as int)
        else
          throw const FormatException('Each cell needs integer x and y.'),
    ];

List<GridPos> _regionCells(Map<String, Object?> raw) {
  final values =
      SemanticParameters(raw, allowed: {'x', 'y', 'width', 'height'});
  final x = values.integer('x'), y = values.integer('y');
  final width = values.integer('width'), height = values.integer('height');
  if (width < 1 || height < 1 || width * height > 4096) {
    throw const FormatException('Choose a bounded nonempty region.');
  }
  return [
    for (var row = y; row < y + height; row++)
      for (var column = x; column < x + width; column++)
        GridPos(x: column, y: row),
  ];
}

const _id = {'type': 'string', 'minLength': 1};
const _cell = {
  'type': 'object',
  'additionalProperties': false,
  'required': ['x', 'y'],
  'properties': {
    'x': {'type': 'integer', 'minimum': 0},
    'y': {'type': 'integer', 'minimum': 0},
  },
};
const _region = {
  'type': 'object',
  'additionalProperties': false,
  'required': ['x', 'y', 'width', 'height'],
  'properties': {
    'x': {'type': 'integer', 'minimum': 0},
    'y': {'type': 'integer', 'minimum': 0},
    'width': {'type': 'integer', 'minimum': 1},
    'height': {'type': 'integer', 'minimum': 1},
  },
};
