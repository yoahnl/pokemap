import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import 'semantic_map_action_support.dart';

final class SpatialTerrainSurfaceActions {
  const SpatialTerrainSurfaceActions();

  static const upsert = 'map3d.terrain.surface.upsert_batch';
  static const delete = 'map3d.terrain.surface.delete_batch';

  static final descriptors = [
    for (final action in [upsert, delete])
      AuthoringActionDescriptor(
        id: action,
        version: 1,
        summary: action == upsert
            ? 'Create or edit bounded native continuous terrain surfaces'
            : 'Delete bounded native continuous terrain surfaces',
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
          AuthoringGuarantee.atomic,
        ],
        extensions: {
          'maximumSurfaceCount': maximumSpatialTerrainSurfaces,
          'batchAtomicity': 'all_or_nothing',
          'undoBoundary': 'batch',
          'duplicateSurfaceIds': 'reject',
          'dependentSpatialBorders':
              'rematerializedInTheSameChange; preview lists refreshedBorderFeatures and staleBorderFeatures',
          'inputSchema': {
            'type': 'object',
            'additionalProperties': false,
            'required': ['mapId', action == upsert ? 'surfaces' : 'surfaceIds'],
            'properties': {
              'mapId': {'type': 'string', 'minLength': 1},
              'reanchorInstances': {'type': 'boolean', 'default': true},
              action == upsert ? 'surfaces' : 'surfaceIds': {
                'type': 'array',
                'minItems': 1,
                'maxItems': maximumSpatialTerrainSurfaces,
                'items': action == upsert ? _surfaceSchema : _idSchema,
              },
            },
          },
        },
      ),
  ];

  AuthoringMutationDraft build(AuthoringPlanningContext planning) {
    final action = planning.request.actionId;
    if (action != upsert && action != delete) {
      throw semanticFailure(
        'map3d.action_unsupported',
        'Unsupported continuous terrain action.',
      );
    }
    final field = action == upsert ? 'surfaces' : 'surfaceIds';
    final context = SemanticMapActionContext.read(
      planning,
      allowedParameters: {field, 'reanchorInstances'},
    );
    if (context.manifest.settings.dimension != ProjectDimension.threeD ||
        context.map.spatialScene == null) {
      throw semanticFailure(
        'map3d.dimension_required',
        'Continuous terrain requires a 3D project and map.',
      );
    }
    try {
      final raw = context.parameters.list(field);
      if (raw.isEmpty || raw.length > maximumSpatialTerrainSurfaces) {
        throw const FormatException(
          'Terrain batches require 1 to 128 surfaces.',
        );
      }
      const operations = SpatialMapOperations();
      final reanchorInstances = context.parameters.contains('reanchorInstances')
          ? context.parameters.boolean('reanchorInstances')
          : true;
      final List<String> ids;
      final MapData after;
      if (action == upsert) {
        final surfaces = [
          for (final item in raw) SpatialTerrainSurface.fromJson(_object(item)),
        ];
        ids = [for (final surface in surfaces) surface.id];
        after = operations.upsertTerrainSurfaces(context.map, surfaces,
            reanchorInstances: reanchorInstances,
            pinBorderOwnedInstances: true);
      } else {
        ids = [
          for (final item in raw)
            if (item is String)
              item
            else
              throw const FormatException(
                  'Terrain surface IDs must be strings.'),
        ];
        after = operations.deleteTerrainSurfaces(context.map, ids,
            reanchorInstances: reanchorInstances,
            pinBorderOwnedInstances: true);
      }
      final refresh = refreshSpatialBordersForTerrainChange(
        manifest: context.manifest,
        before: context.map,
        after: after,
      );
      final before = context.map.spatialScene!;
      final next = after.spatialScene!;
      final previous = {
        for (final surface in before.terrainSurfaces.surfaces)
          surface.id: surface,
      };
      final changed = action == delete
          ? ids.length
          : next.terrainSurfaces.surfaces
              .where((surface) => previous[surface.id] != surface)
              .length;
      return context.draftMap(
        after: refresh.map,
        operation: action,
        changedItems: changed,
        preview: {
          'surfaceIds': ids,
          'surfaceCount': next.terrainSurfaces.surfaces.length,
          'changedSurfaceCount': changed,
          'reanchorInstances': reanchorInstances,
          'refreshedBorderFeatures': refresh.refreshed,
          'staleBorderFeatures': refresh.stale,
          'reanchoredInstanceCount': [
            for (var index = 0; index < before.instances.length; index++)
              if (before.instances[index] != next.instances[index]) index,
          ].length,
          'batchAtomicity': 'all_or_nothing',
          'undoBoundary': 'batch',
        },
      );
    } on FormatException catch (error) {
      throw semanticFailure('map3d.terrain.surface.invalid', error.message);
    } on ValidationException catch (error) {
      throw semanticFailure('map3d.terrain.surface.invalid', error.message);
    } on TypeError {
      throw semanticFailure(
        'map3d.terrain.surface.invalid',
        'Continuous terrain fields have invalid types.',
      );
    }
  }
}

Map<String, dynamic> _object(Object? value) {
  if (value is! Map || value.keys.any((key) => key is! String)) {
    throw const FormatException('A terrain surface must be an object.');
  }
  return Map<String, dynamic>.from(value);
}

const _idSchema = {
  'type': 'string',
  'minLength': 1,
  'maxLength': 128,
  'pattern': r'^[a-zA-Z0-9_-]{1,128}$',
};

const _surfaceSchema = {
  'type': 'object',
  'additionalProperties': false,
  'required': ['id', 'x', 'z', 'height', 'footprints'],
  'properties': {
    'id': _idSchema,
    'x': {'type': 'number'},
    'z': {'type': 'number'},
    'height': {'type': 'number'},
    'gradientX': {'type': 'number'},
    'gradientZ': {'type': 'number'},
    'footprints': {
      'type': 'array',
      'minItems': 1,
      'maxItems': maximumSpatialTerrainSurfaceFootprints,
      'items': {
        'type': 'array',
        'minItems': 3,
        'maxItems': 16,
        'items': {
          'type': 'object',
          'additionalProperties': false,
          'required': ['x', 'z'],
          'properties': {
            'x': {'type': 'number'},
            'z': {'type': 'number'},
          },
        },
      },
    },
  },
};
