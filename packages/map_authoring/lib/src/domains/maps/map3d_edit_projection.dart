import 'package:map_core/map_core.dart';

import '../../contracts/authoring_request.dart';
import '../../transactions/action_planner.dart';
import 'border_actions.dart';
import 'border_materialization_batch_actions.dart';
import 'semantic_map_action_support.dart';
import 'smart_tile_cell_actions.dart';
import 'spatial_map_actions.dart';
import 'spatial_terrain_surface_actions.dart';

final class Map3dEditProjection {
  const Map3dEditProjection();

  static const admittedActions = {
    'smart_tile.cell.paint',
    'smart_tile.cell.paint_batch',
    'smart_tile.cell.erase',
    'map3d.terrain.surface.upsert_batch',
    'map3d.terrain.surface.delete_batch',
    'map3d.instance.upsert_batch',
    'map3d.instance.delete_batch',
    'border_layer.feature_create',
    'border_layer.feature_update',
    'border_layer.feature_delete',
    'border_layer.feature_move',
    'border_layer.stroke_add',
    'border_layer.stroke_update',
    'border_layer.stroke_delete',
    'border_layer.stroke_erase',
    'border_layer.region_fill',
    'border_layer.region_clear',
    'border_layer.feature_set_replacement',
    'border_layer.feature_set_suppressed',
    'border_layer.feature_clear_slot_override',
    'border_layer.feature_set_keep_out',
    'border_layer.relink_apply',
    'border_layer.feature_set_blueprint',
    'border_layer.materialize_batch_apply',
  };

  SemanticMapProjection project({
    required AuthoringPlanningContext planning,
    required MapData map,
    required Map<String, Object?> operation,
    required int operationIndex,
    required int seed,
  }) {
    final action = operation['actionId'] as String;
    if (!admittedActions.contains(action)) {
      throw semanticFailure(
          action == 'map3d.edit_batch'
              ? 'map3d.edit_batch.action_not_admitted'
              : 'map3d.edit_batch.foreign_resource',
          'This action is not admitted in an atomic map edit.',
          details: {'actionId': action});
    }
    final parameters =
        Map<String, Object?>.from(operation['parameters'] as Map);
    if (parameters.containsKey('mapId') && parameters['mapId'] != map.id) {
      throw semanticFailure('map3d.edit_batch.foreign_resource',
          'Every operation must target the common map.',
          details: {'mapId': parameters['mapId'], 'expectedMapId': map.id});
    }
    final context = AuthoringPlanningContext(
      snapshot: planning.snapshot,
      request: AuthoringRequest(
        requestId: planning.request.requestId,
        workspaceHandle: planning.request.workspaceHandle,
        actionId: action,
        actionVersion: operation['actionVersion'] as int,
        parameters: {...parameters, 'mapId': map.id},
        expectedRevision: planning.request.expectedRevision,
        dryRun: planning.request.dryRun,
      ),
      planId: planning.planId,
      seed: seed,
      logicalOperationId:
          '${planning.logicalOperationId ?? planning.planId}/$operationIndex',
    );
    if (action.startsWith('smart_tile.')) {
      return const SmartTileCellActions()
          .project(context, projectedMap: map, deferFinalization: true);
    }
    if (action.startsWith('map3d.terrain.surface.')) {
      return const SpatialTerrainSurfaceActions()
          .project(context, projectedMap: map, deferFinalization: true);
    }
    if (action.startsWith('map3d.instance.')) {
      return const SpatialMapActions()
          .project(context, projectedMap: map, deferFinalization: true);
    }
    if (action == 'border_layer.materialize_batch_apply') {
      return const BorderMaterializationBatchActions()
          .project(context, projectedMap: map, deferFinalization: true);
    }
    return const BorderActions()
        .project(context, projectedMap: map, deferFinalization: true);
  }
}
