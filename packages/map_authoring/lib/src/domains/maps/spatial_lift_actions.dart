import 'package:map_core/map_core.dart';
import '../../contracts/action_descriptor.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import 'semantic_map_action_support.dart';

final class SpatialLiftActions {
  const SpatialLiftActions();
  static const upsert = 'map3d.lift.upsert_batch';
  static const delete = 'map3d.lift.delete_batch';
  static final descriptors = [
    for (final action in [upsert, delete])
      AuthoringActionDescriptor(
          id: action,
          version: 1,
          summary: action == upsert
              ? 'Configure reusable native vertical platforms'
              : 'Remove native vertical platforms',
          inputSchemaId: 'schema.$action.input.v1',
          outputSchemaId: 'schema.map.semantic_mutation.output.v1',
          riskLevel: AuthoringRiskLevel.low,
          resourceKinds: const [
            'map'
          ],
          requiredPermissions: const [
            AuthoringPermission.projectWrite
          ],
          guarantees: const [
            AuthoringGuarantee.dryRun,
            AuthoringGuarantee.idempotent,
            AuthoringGuarantee.revisionChecked,
            AuthoringGuarantee.undoable,
            AuthoringGuarantee.atomic
          ],
          extensions: {
            'scope': 'selectedMap',
            'state': 'spatialWorldState.modelsByMap.translationY',
            'command': 'movePlatform',
            'motion': {
              'forward': 'upperStop',
              'backward': 'lowerStop',
              'rotateClockwise': 'blocked'
            },
            'inputSchema': {
              'type': 'object',
              'additionalProperties': false,
              'required': ['mapId', action == upsert ? 'lifts' : 'liftIds'],
              'properties': {
                'mapId': {'type': 'string', 'minLength': 1},
                action == upsert ? 'lifts' : 'liftIds': {
                  'type': 'array',
                  'minItems': 1,
                  'maxItems': 64,
                  'items': action == delete
                      ? {'type': 'string', 'minLength': 1}
                      : {
                          'type': 'object',
                          'additionalProperties': false,
                          'required': [
                            'id',
                            'name',
                            'instanceId',
                            'x',
                            'z',
                            'width',
                            'depth',
                            'lowerHeight',
                            'upperHeight',
                            'durationMs'
                          ],
                          'properties': {
                            for (final key in ['id', 'name', 'instanceId'])
                              key: {'type': 'string', 'minLength': 1},
                            for (final key in [
                              'x',
                              'z',
                              'width',
                              'depth',
                              'durationMs'
                            ])
                              key: {'type': 'integer'},
                            for (final key in ['lowerHeight', 'upperHeight'])
                              key: {'type': 'number'}
                          }
                        }
                }
              }
            }
          })
  ];
  AuthoringMutationDraft build(AuthoringPlanningContext planning) {
    final remove = planning.request.actionId == delete;
    final field = remove ? 'liftIds' : 'lifts';
    final context =
        SemanticMapActionContext.read(planning, allowedParameters: {field});
    if (context.manifest.settings.dimension != ProjectDimension.threeD ||
        context.map.spatialScene == null) {
      throw semanticFailure(
          'map3d.dimension_required', 'Vertical platforms require a 3D map.');
    }
    try {
      final raw = context.parameters.list(field);
      if (raw.isEmpty || raw.length > 64) {
        throw const FormatException('Lift batches require 1 to 64 entries.');
      }
      final values = remove
          ? <SpatialLiftDefinition>[]
          : [
              for (final row in raw)
                SpatialLiftDefinition.fromJson(
                    Map<String, dynamic>.from(row as Map))
            ];
      final ids = remove
          ? [for (final id in raw) id as String]
          : values.map((v) => v.id).toList();
      if (ids.toSet().length != ids.length) {
        throw const FormatException('Duplicate lift identities.');
      }
      final operations = const SpatialMapOperations();
      final after = remove
          ? operations.deleteLifts(context.map, ids)
          : operations.upsertLifts(context.map, values);
      final before = {
        for (final lift in context.map.spatialScene!.lifts) lift.id: lift
      };
      final next = {
        for (final lift in after.spatialScene!.lifts) lift.id: lift
      };
      final changed = ids.where((id) => before[id] != next[id]).length;
      return context.draftMap(
          after: after,
          operation: planning.request.actionId,
          changedItems: changed,
          preview: {
            'liftIds': ids,
            'changedLiftCount': changed,
            'terrainAndInstancesPreserved': true,
            'batchAtomicity': 'all_or_nothing'
          });
    } on FormatException catch (error) {
      throw semanticFailure('map3d.lift.invalid', error.message);
    } on TypeError {
      throw semanticFailure(
          'map3d.lift.invalid', 'Lift fields have invalid types.');
    }
  }
}
