import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import 'map_action_examples.dart';
import 'semantic_map_action_support.dart';
import 'spatial_terrain_relief_actions.dart' show reliefTracePreview;

final class SpatialTerrainSlopeActions {
  const SpatialTerrainSlopeActions();

  static const paintSlope = 'map3d.terrain.paint_slope';
  static const placeStair = 'map3d.terrain.place_stair';

  static final descriptors = [
    _descriptor(
      paintSlope,
      'Slope the low cells between a drag start and a higher plateau in one edit',
      required: const ['mapId', 'from', 'to'],
      properties: const {'from': _cell, 'to': _cell},
      extensions: const {
        'heights': 'read from the terrain at from (low) and to (high)',
        'flatGround': 'climbs one level over the dragged cells',
        'flanks': 'closedFlanks: the sides block movement',
        'cliffs': 'existing cliffs on the step are cut at the slope',
      },
      refusals: const [
        'spatial.slope.cells_invalid',
        'spatial.slope.direction_ambiguous',
        'spatial.slope.downhill',
        'spatial.slope.ground_not_flat',
      ],
    ),
    _descriptor(
      placeStair,
      'Snap a stair model onto a clicked cliff edge and make it walkable',
      required: const ['mapId', 'cell', 'modelId'],
      properties: const {'cell': _cell, 'modelId': _id},
      extensions: const {
        'orientation': 'climbs from the low side toward the high side',
        'model':
            'climbing axis = shorter horizontal extent, native climb toward -z or -x; blocksMovement false',
        'walkability': 'one-cell-deep gradient surface with closedFlanks',
        'cliffs': 'the cliff on that step is cut where the stair stands',
      },
      refusals: const [
        'spatial.stair.cells_invalid',
        'spatial.stair.no_cliff',
        'spatial.stair.edge_ambiguous',
        'spatial.stair.height_mismatch',
        'spatial.stair.no_room',
        'spatial.stair.model_unavailable',
      ],
    ),
  ];

  AuthoringMutationDraft build(AuthoringPlanningContext planning) =>
      project(planning).finalize();

  SemanticMapProjection project(
    AuthoringPlanningContext planning, {
    MapData? projectedMap,
    bool deferFinalization = false,
  }) {
    final action = planning.request.actionId;
    final stair = action == placeStair;
    final context = SemanticMapActionContext.read(
      planning,
      projectedMap: projectedMap,
      deferFinalization: deferFinalization,
      allowedParameters: stair
          ? const {'cell', 'modelId', 'reanchorInstances'}
          : const {'from', 'to', 'reanchorInstances'},
    );
    if (context.manifest.settings.dimension != ProjectDimension.threeD ||
        context.map.spatialScene == null) {
      throw semanticFailure(
        'map3d.dimension_required',
        'Slopes and stairs require a 3D project and map.',
      );
    }
    final parameters = context.parameters;
    final reanchor = !parameters.contains('reanchorInstances') ||
        parameters.boolean('reanchorInstances');
    try {
      final TerrainSlopePaint slope;
      String? instanceId;
      if (stair) {
        final placed = placeTerrainStair(
          manifest: context.manifest,
          map: context.map,
          cell: _cellOf(parameters.object('cell')),
          modelId: parameters.string('modelId'),
          reanchorInstances: reanchor,
        );
        slope = placed.slope;
        instanceId = placed.instance.id;
      } else {
        slope = paintTerrainSlope(
          manifest: context.manifest,
          map: context.map,
          from: _cellOf(parameters.object('from')),
          to: _cellOf(parameters.object('to')),
          reanchorInstances: reanchor,
        );
      }
      return context.projectMap(
        after: slope.map,
        operation: action,
        changedItems: 1 + slope.traces.length + (instanceId == null ? 0 : 1),
        preview: {
          ...slopePreview(slope),
          if (instanceId != null) 'instanceId': instanceId,
        },
      );
    } on ValidationException catch (error) {
      throw semanticFailure(
        error.code ?? '$action.invalid',
        error.message,
        details: error.details,
      );
    } on FormatException catch (error) {
      throw semanticFailure('$action.invalid', error.message);
    }
  }
}

Map<String, Object?> slopePreview(TerrainSlopePaint slope) => {
      'surfaceId': slope.surfaceId,
      'direction': slope.plan.direction.name,
      'lowerHeight': slope.plan.lowerHeight,
      'upperHeight': slope.plan.upperHeight,
      'region': {
        'x': slope.plan.left,
        'y': slope.plan.top,
        'width': slope.plan.width,
        'height': slope.plan.depth,
      },
      'traces': [for (final trace in slope.traces) reliefTracePreview(trace)],
      'refreshedBorderFeatures': slope.refreshedBorders,
      'staleBorderFeatures': slope.staleBorders,
      'work': {
        'borderResolutions': slope.resolvedBorderFeatures.length,
        'resolvedBorderFeatures':
            slope.resolvedBorderFeatures.take(20).toList(),
      },
    };

AuthoringActionDescriptor _descriptor(
  String id,
  String summary, {
  required List<String> required,
  required Map<String, Object?> properties,
  required Map<String, Object?> extensions,
  required List<String> refusals,
}) =>
    AuthoringActionDescriptor(
      id: id,
      version: 1,
      summary: summary,
      inputSchemaId: 'schema.$id.input.v1',
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
        'inputExample': mapActionInputExample(id),
        'batchAtomicity': 'all_or_nothing',
        'undoBoundary': 'action',
        ...extensions,
        'refusalCodes': [
          ...refusals,
          'spatial.relief.step_ambiguous',
          'spatial.relief.trace_refused',
          'spatial.relief.profile_incompatible',
          'spatial.terrain.paint.surface_limit',
          'spatial.terrain.paint.ramp_conflict',
        ],
        'inputSchema': {
          'type': 'object',
          'additionalProperties': false,
          'required': required,
          'properties': {
            'mapId': _id,
            'reanchorInstances': {'type': 'boolean', 'default': true},
            ...properties,
          },
        },
      },
    );

GridPos _cellOf(Map<String, Object?> raw) {
  final x = raw['x'], y = raw['y'];
  if (raw.length != 2 || x is! int || y is! int) {
    throw const FormatException('A cell needs integer x and y.');
  }
  return GridPos(x: x, y: y);
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
