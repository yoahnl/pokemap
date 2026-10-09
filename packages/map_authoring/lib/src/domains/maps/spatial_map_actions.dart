import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import 'semantic_map_action_support.dart';

final class SpatialMapActions {
  const SpatialMapActions();
  static const int maximumInstancesPerBatch = 50;
  static const _fields = {
    'map3d.terrain.set_levels': 'cells',
    'map3d.terrain.configure_height': 'levelHeight',
    'map3d.terrain.configure_appearance': 'cliffFrame',
    'map3d.instance.upsert': 'instance',
    'map3d.instance.upsert_batch': 'instances',
    'map3d.instance.delete': 'instanceId',
    'map3d.camera.configure': 'camera',
    'map3d.navigation.configure': 'navigation',
  };
  static final descriptors = [
    for (final entry in _fields.entries)
      AuthoringActionDescriptor(
        id: entry.key,
        version: 1,
        summary: switch (entry.value) {
          'cells' => 'Set discrete terrain levels on a 3D map',
          'levelHeight' =>
            'Configure physical terrain level height and preserve instance offsets',
          'cliffFrame' =>
            'Configure or clear the repeated terrain cliff texture',
          'instance' => 'Place or replace a 3D model instance',
          'instances' =>
            'Place or replace bounded 3D instances atomically on one map',
          'instanceId' => 'Delete a 3D model instance',
          'navigation' => 'Configure spawn, ramps and exploration movement',
          _ => 'Configure a fixed 3D map camera',
        },
        inputSchemaId: 'schema.${entry.key}.input.v1',
        outputSchemaId: 'schema.map.semantic_mutation.output.v1',
        riskLevel: AuthoringRiskLevel.low,
        resourceKinds: const ['map'],
        requiredPermissions: const [AuthoringPermission.projectWrite],
        guarantees: [
          AuthoringGuarantee.dryRun,
          AuthoringGuarantee.idempotent,
          AuthoringGuarantee.revisionChecked,
          AuthoringGuarantee.undoable,
          if (entry.value == 'instances') AuthoringGuarantee.atomic,
        ],
        extensions: {
          if (entry.value == 'instances') ...{
            'maximumInstanceCount': maximumInstancesPerBatch,
            'batchAtomicity': 'all_or_nothing',
            'undoBoundary': 'batch',
            'duplicateInstanceIds': 'reject',
          },
          'inputSchema': {
            'type': 'object',
            'additionalProperties': false,
            'required': ['mapId', entry.value],
            'properties': {
              'mapId': {'type': 'string', 'minLength': 1},
              entry.value: _schema(entry.value)
            }
          }
        },
      ),
  ];

  AuthoringMutationDraft build(AuthoringPlanningContext planning) {
    final action = planning.request.actionId;
    final field = _fields[action];
    if (field == null) {
      throw semanticFailure(
          'map3d.action_unsupported', 'Unsupported spatial map action.');
    }
    final context =
        SemanticMapActionContext.read(planning, allowedParameters: {field});
    if (context.manifest.settings.dimension != ProjectDimension.threeD ||
        context.map.spatialScene == null) {
      throw semanticFailure('map3d.dimension_required',
          'This operation requires a 3D project and map.');
    }
    if (field == 'cells' && context.parameters.list(field).length > 65536) {
      throw semanticFailure('map3d.parameters_invalid',
          'A terrain operation supports at most 65536 cells.');
    }
    if (!context.parameters.contains(field)) {
      throw semanticFailure('map3d.parameters_invalid',
          'The spatial action requires its configuration field.');
    }
    if (field == 'instanceId') {
      final instanceId = context.parameters.string(field);
      final index = buildNarrativeDependencyIndex(
          project: context.manifest, maps: planning.snapshot.maps);
      final usages = index.usagesFor(NarrativeDependencyKey.mapSource(
          mapId: context.map.id,
          sourceKind: 'modelInstance',
          sourceId: instanceId));
      if (usages.isNotEmpty) {
        throw semanticFailure('map3d.instance_referenced',
            'The 3D instance is still referenced and cannot be deleted.',
            details: {
              'instanceId': instanceId,
              'references': usages.map((usage) => usage.path).toList()..sort(),
            });
      }
    }
    const operations = SpatialMapOperations();
    try {
      final after = switch (field) {
        'instances' => _upsertInstances(context),
        'levelHeight' =>
          _configureTerrainHeight(context.map, context.parameters.value(field)),
        'cliffFrame' => operations.configureTerrainAppearance(context.map,
            cliffFrame: context.parameters.value(field) == null
                ? null
                : SmartTileFrameRef.fromJson(_object(
                    context.parameters.value(field),
                    {'atlasId', 'column', 'row', 'columnSpan', 'rowSpan'}))),
        'cells' => operations.setLevels(
            context.map,
            context.parameters.list(field).map((value) {
              final cell = _object(value, {'x', 'z', 'level'});
              return SpatialCellLevel(
                  x: cell['x'] as int,
                  z: cell['z'] as int,
                  level: cell['level'] as int);
            }).toList()),
        'instance' => operations.upsertInstance(
            context.map,
            SpatialModelInstance.fromJson(
                _object(context.parameters.object(field), {
              'id',
              'modelId',
              'position',
              'rotationDegrees',
              'scale',
              'animationIndex',
              'animationLoop',
              'animationSpeed',
              'blocksMovement'
            }))),
        'navigation' => operations.configureNavigation(
            context.map,
            SpatialNavigationProfile.fromJson(_object(
                context.parameters.object(field),
                {'spawn', 'allowDiagonalMovement', 'ramps', 'blockedAreas'}))),
        'instanceId' => operations.deleteInstance(
            context.map, context.parameters.string(field)),
        _ => operations.configureCamera(
            context.map,
            SpatialCameraProfile.fromJson(_object(
                context.parameters.object(field), {
              'mode',
              'pitchDegrees',
              'yawDegrees',
              'fieldOfViewDegrees',
              'distance'
            }))),
      };
      return context.draftMap(
          after: after,
          operation: action,
          changedItems: switch (field) {
            'cells' =>
              _changedCells(context.map.spatialScene!, after.spatialScene!),
            'instances' =>
              _changedInstances(context.map.spatialScene!, after.spatialScene!),
            _ => 1,
          },
          preview: field == 'instances'
              ? {
                  'instanceIds': context.parameters
                      .list(field)
                      .map((item) => (item as Map)['id'])
                      .toList(),
                  'instanceCount': context.parameters.list(field).length,
                  'changedInstanceCount': _changedInstances(
                      context.map.spatialScene!, after.spatialScene!),
                  'batchAtomicity': 'all_or_nothing',
                  'undoBoundary': 'batch',
                }
              : {'spatialScene': after.spatialScene!.toJson()});
    } on FormatException catch (error) {
      throw semanticFailure('map3d.parameters_invalid', error.message);
    } on TypeError {
      throw semanticFailure('map3d.parameters_invalid',
          'The spatial action parameters have invalid types or missing fields.');
    }
  }
}

MapData _upsertInstances(SemanticMapActionContext context) {
  final raw = context.parameters.list('instances');
  if (raw.isEmpty) {
    throw const FormatException(
        'An instance batch requires at least one instance.');
  }
  if (raw.length > SpatialMapActions.maximumInstancesPerBatch) {
    throw semanticFailure('map3d.instance.batch_too_large',
        'An instance batch supports at most fifty instances.',
        details: {
          'instanceCount': raw.length,
          'maximumInstanceCount': SpatialMapActions.maximumInstancesPerBatch
        });
  }
  final instances = <SpatialModelInstance>[];
  final ids = <String>{};
  final models = {
    for (final model in context.manifest.models3d) model.id: model
  };
  for (final value in raw) {
    final instance = SpatialModelInstance.fromJson(_object(value, {
      'id',
      'modelId',
      'position',
      'rotationDegrees',
      'scale',
      'animationIndex',
      'animationLoop',
      'animationSpeed',
      'blocksMovement',
    }));
    if (!ids.add(instance.id)) {
      throw semanticFailure('map3d.instance.batch_duplicate',
          'An instance batch cannot repeat an instance identity.',
          details: {'instanceId': instance.id});
    }
    final model = models[instance.modelId];
    if (model == null) {
      throw semanticFailure('map3d.instance.model_not_found',
          'The instance source model does not exist in the project.',
          details: {'instanceId': instance.id, 'modelId': instance.modelId});
    }
    if (instance.animationIndex != null &&
        !model.inspection.animations
            .any((clip) => clip.index == instance.animationIndex)) {
      throw semanticFailure('map3d.instance.animation_invalid',
          'The instance animation is absent from the inspected source model.',
          details: {
            'instanceId': instance.id,
            'modelId': instance.modelId,
            'animationIndex': instance.animationIndex
          });
    }
    instances.add(instance);
  }
  final before = context.map.spatialScene!;
  final replacements = {
    for (final instance in instances) instance.id: instance
  };
  final existingIds = before.instances.map((instance) => instance.id).toSet();
  final projected = context.map.copyWith(
      spatialScene: before.copyWith(instances: [
    for (final existing in before.instances)
      replacements[existing.id] ?? existing,
    for (final instance in instances)
      if (!existingIds.contains(instance.id)) instance,
  ]));
  validateSpatialMapStructure(projected);
  var after = context.map;
  const operations = SpatialMapOperations();
  for (final instance in instances) {
    after = operations.upsertInstance(after, instance);
  }
  return after;
}

int _changedInstances(MapSpatialScene before, MapSpatialScene after) {
  final existing = {
    for (final instance in before.instances) instance.id: instance
  };
  return after.instances
      .where((instance) => existing[instance.id] != instance)
      .length;
}

MapData _configureTerrainHeight(MapData map, Object? value) {
  if (value is! num || !value.isFinite || value <= 0 || value > 16) {
    throw const FormatException(
        'Terrain level height must be finite, greater than 0 and at most 16.');
  }
  validateSpatialMapStructure(map);
  final before = map.spatialScene!;
  if (value.toDouble() == before.levelHeight) return map;
  final after = MapSpatialScene(
    width: before.width,
    depth: before.depth,
    heightLevels: before.heightLevels,
    levelHeight: value.toDouble(),
    cliffFrame: before.cliffFrame,
    instances: before.instances,
    camera: before.camera,
    navigation: before.navigation,
  );
  return map.copyWith(spatialScene: after.copyWith(
    instances: before.instances.map((instance) {
      final position = instance.position;
      return instance.copyWith(
          position: Model3dVector3(
        x: position.x,
        y: position.y +
            (after.worldHeightAt(position.x, position.z) -
                before.worldHeightAt(position.x, position.z)),
        z: position.z,
      ));
    }),
  ));
}

Map<String, dynamic> _object(Object? value, Set<String> allowed) {
  if (value is! Map || value.keys.any((key) => !allowed.contains(key))) {
    throw const FormatException('Invalid spatial object fields.');
  }
  return Map<String, dynamic>.from(value);
}

int _changedCells(MapSpatialScene before, MapSpatialScene after) {
  var count = 0;
  for (var i = 0; i < before.heightLevels.length; i++) {
    if (before.heightLevels[i] != after.heightLevels[i]) count++;
  }
  return count;
}

Map<String, Object?> _schema(String field) => switch (field) {
      'instances' => {
          'type': 'array',
          'minItems': 1,
          'maxItems': SpatialMapActions.maximumInstancesPerBatch,
          'items': _schema('instance'),
        },
      'levelHeight' => {
          'type': 'number',
          'exclusiveMinimum': 0,
          'maximum': 16,
        },
      'cliffFrame' => {
          'type': ['object', 'null'],
          'additionalProperties': false,
          'required': ['atlasId', 'column', 'row'],
          'properties': {
            'atlasId': {'type': 'string', 'minLength': 1},
            'column': {'type': 'integer', 'minimum': 0},
            'row': {'type': 'integer', 'minimum': 0},
            'columnSpan': {'type': 'integer', 'minimum': 1},
            'rowSpan': {'type': 'integer', 'minimum': 1},
          },
        },
      'navigation' => {
          'type': 'object',
          'additionalProperties': false,
          'required': [
            'spawn',
            'allowDiagonalMovement',
            'ramps',
            'blockedAreas'
          ],
          'properties': {
            'spawn': {
              'type': 'object',
              'additionalProperties': false,
              'required': ['x', 'z'],
              'properties': {
                'x': {'type': 'number', 'minimum': 0, 'exclusiveMaximum': 256},
                'z': {'type': 'number', 'minimum': 0, 'exclusiveMaximum': 256}
              }
            },
            'allowDiagonalMovement': {'type': 'boolean'},
            'ramps': {
              'type': 'array',
              'maxItems': 256,
              'items': {
                'type': 'object',
                'additionalProperties': false,
                'required': [
                  'id',
                  'x',
                  'z',
                  'width',
                  'depth',
                  'lowLevel',
                  'highLevel',
                  'direction'
                ],
                'properties': {
                  ..._rectangleProperties,
                  'id': {
                    'type': 'string',
                    'pattern': r'^[a-zA-Z0-9_-]{1,128}$'
                  },
                  'lowLevel': {'type': 'integer', 'minimum': 0, 'maximum': 31},
                  'highLevel': {'type': 'integer', 'minimum': 1, 'maximum': 32},
                  'direction': {
                    'enum': ['north', 'south', 'east', 'west']
                  }
                }
              }
            },
            'blockedAreas': {
              'type': 'array',
              'maxItems': 4096,
              'items': {
                'type': 'object',
                'additionalProperties': false,
                'required': ['x', 'z', 'width', 'depth'],
                'properties': _rectangleProperties
              }
            }
          }
        },
      'instanceId' => {'type': 'string', 'minLength': 1},
      'cells' => {
          'type': 'array',
          'maxItems': 65536,
          'items': {
            'type': 'object',
            'additionalProperties': false,
            'required': ['x', 'z', 'level'],
            'properties': {
              'x': {'type': 'integer', 'minimum': 0, 'maximum': 255},
              'z': {'type': 'integer', 'minimum': 0, 'maximum': 255},
              'level': {'type': 'integer', 'minimum': 0, 'maximum': 32}
            }
          }
        },
      'instance' => {
          'type': 'object',
          'additionalProperties': false,
          'required': [
            'id',
            'modelId',
            'position',
            'rotationDegrees',
            'scale',
            'blocksMovement'
          ],
          'properties': {
            'id': {'type': 'string'},
            'modelId': {'type': 'string'},
            'position': {
              'type': 'object',
              'additionalProperties': false,
              'required': ['x', 'y', 'z'],
              'properties': {
                for (final axis in ['x', 'y', 'z']) axis: {'type': 'number'}
              }
            },
            'rotationDegrees': {'type': 'number'},
            'scale': {'type': 'number', 'exclusiveMinimum': 0, 'maximum': 1000},
            'animationIndex': {
              'type': ['integer', 'null'],
              'minimum': 0
            },
            'animationLoop': {'type': 'boolean'},
            'animationSpeed': {
              'type': 'number',
              'exclusiveMinimum': 0,
              'maximum': 16
            },
            'blocksMovement': {'type': 'boolean'}
          }
        },
      _ => {
          'type': 'object',
          'additionalProperties': false,
          'required': [
            'mode',
            'pitchDegrees',
            'yawDegrees',
            'fieldOfViewDegrees',
            'distance'
          ],
          'properties': {
            'mode': {
              'enum': ['fixed']
            },
            'pitchDegrees': {
              'type': 'number',
              'exclusiveMinimum': 0,
              'exclusiveMaximum': 90
            },
            'yawDegrees': {'type': 'number'},
            'fieldOfViewDegrees': {
              'type': 'number',
              'exclusiveMinimum': 1,
              'exclusiveMaximum': 120
            },
            'distance': {
              'type': 'number',
              'exclusiveMinimum': 0,
              'maximum': 10000
            }
          }
        },
    };

const _rectangleProperties = <String, Object?>{
  'x': {'type': 'number', 'minimum': 0, 'maximum': 256},
  'z': {'type': 'number', 'minimum': 0, 'maximum': 256},
  'width': {'type': 'number', 'exclusiveMinimum': 0, 'maximum': 256},
  'depth': {'type': 'number', 'exclusiveMinimum': 0, 'maximum': 256},
};
