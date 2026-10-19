import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../editing/moving_prop_editing.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import 'semantic_map_action_support.dart';

final class MovingPropActions {
  const MovingPropActions();

  static final descriptors = [
    for (final action in ['map.prop.upsert', 'map.prop.delete'])
      AuthoringActionDescriptor(
        id: action,
        version: 1,
        summary: action.endsWith('upsert')
            ? 'Create or replace a generic 2D movable prop with closed and open positions'
            : 'Delete an unreferenced movable prop while keeping its placed visual',
        inputSchemaId: 'schema.$action.input.v1',
        outputSchemaId: 'schema.map.semantic_mutation.output.v1',
        riskLevel: AuthoringRiskLevel.low,
        resourceKinds: const ['map'],
        requiredPermissions: const [AuthoringPermission.projectWrite],
        guarantees: const [
          AuthoringGuarantee.dryRun,
          AuthoringGuarantee.idempotent,
          AuthoringGuarantee.revisionChecked,
          AuthoringGuarantee.undoable,
        ],
        extensions: {
          'dimensions': ['twoD'],
          'states': ['closed', 'open'],
          'motion': 'straightRailAtomicGroup',
          'persistence': 'movingPropWorldState',
          'collision': 'relativeRectangleSweptAlongRail',
          'inputSchema': {
            'type': 'object',
            'additionalProperties': false,
            'required': [
              'mapId',
              action.endsWith('upsert') ? 'prop' : 'propId'
            ],
            'properties': {
              'mapId': {'type': 'string', 'minLength': 1},
              if (action.endsWith('upsert')) 'prop': _definitionSchema,
              if (action.endsWith('delete'))
                'propId': {'type': 'string', 'minLength': 1},
            },
          },
        },
      ),
  ];

  AuthoringMutationDraft build(AuthoringPlanningContext planning) {
    final upsert = planning.request.actionId == 'map.prop.upsert';
    final context = SemanticMapActionContext.read(planning,
        allowedParameters: {upsert ? 'prop' : 'propId'});
    try {
      final prop = upsert
          ? MovingPropDefinition.fromJson(
              Map<String, dynamic>.from(context.parameters.object('prop')))
          : null;
      final id = prop?.id ?? context.parameters.string('propId');
      if (!upsert) {
        if (!context.map.movingProps.any((value) => value.id == id)) {
          throw semanticFailure(
              'map.prop_not_found', 'The moving prop does not exist.');
        }
        final dependencies = buildNarrativeDependencyIndex(
            project: context.manifest, maps: planning.snapshot.maps);
        final usages = dependencies.usagesFor(NarrativeDependencyKey.mapSource(
            mapId: context.map.id, sourceKind: 'movingProp', sourceId: id));
        if (usages.isNotEmpty) {
          throw semanticFailure(
              'map.prop_referenced', 'The prop is used by a Scene.', details: {
            'references': usages.map((usage) => usage.path).toList()
          });
        }
      }
      final after = prop == null
          ? const MovingPropEditing()
              .delete(map: context.map, project: context.manifest, propId: id)
          : const MovingPropEditing()
              .upsert(map: context.map, project: context.manifest, prop: prop);
      return context.draftMap(
          after: after,
          operation: planning.request.actionId,
          changedItems: 1,
          preview: {'propId': id});
    } on FormatException catch (error) {
      throw semanticFailure('map.prop_invalid', error.message.toString());
    }
  }
}

const _pointSchema = {
  'type': 'object',
  'additionalProperties': false,
  'required': ['x', 'y'],
  'properties': {
    'x': {'type': 'integer'},
    'y': {'type': 'integer'}
  },
};

const _definitionSchema = {
  'type': 'object',
  'additionalProperties': false,
  'required': [
    'id',
    'placedElementId',
    'closedPositionPx',
    'openPositionPx',
    'collisionRect',
  ],
  'properties': {
    'id': {'type': 'string', 'minLength': 1},
    'placedElementId': {'type': 'string', 'minLength': 1},
    'closedPositionPx': _pointSchema,
    'openPositionPx': _pointSchema,
    'initialState': {
      'type': 'string',
      'enum': ['closed', 'open']
    },
    'collisionRect': {
      'type': 'object',
      'additionalProperties': false,
      'required': ['leftPx', 'topPx', 'widthPx', 'heightPx'],
      'properties': {
        'leftPx': {'type': 'integer'},
        'topPx': {'type': 'integer'},
        'widthPx': {'type': 'integer', 'minimum': 1},
        'heightPx': {'type': 'integer', 'minimum': 1},
      },
    },
  },
};
