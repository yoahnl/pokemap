import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import 'semantic_map_action_support.dart';

final class SpatialMapActions {
  const SpatialMapActions();
  static const _fields = {
    'map3d.terrain.set_levels': 'cells',
    'map3d.terrain.configure_appearance': 'cliffFrame',
    'map3d.instance.upsert': 'instance',
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
          'cliffFrame' =>
            'Configure or clear the repeated terrain cliff texture',
          'instance' => 'Place or replace a 3D model instance',
          'instanceId' => 'Delete a 3D model instance',
          'navigation' => 'Configure spawn, ramps and exploration movement',
          _ => 'Configure a fixed 3D map camera',
        },
        inputSchemaId: 'schema.${entry.key}.input.v1',
        outputSchemaId: 'schema.map.semantic_mutation.output.v1',
        riskLevel: AuthoringRiskLevel.low,
        resourceKinds: const ['map'],
        requiredPermissions: const [AuthoringPermission.projectWrite],
        guarantees: const [
          AuthoringGuarantee.dryRun,
          AuthoringGuarantee.idempotent,
          AuthoringGuarantee.revisionChecked,
          AuthoringGuarantee.undoable
        ],
        extensions: {
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
    const operations = SpatialMapOperations();
    try {
      final after = switch (field) {
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
          changedItems: field == 'cells'
              ? _changedCells(context.map.spatialScene!, after.spatialScene!)
              : 1,
          preview: {'spatialScene': after.spatialScene!.toJson()});
    } on FormatException catch (error) {
      throw semanticFailure('map3d.parameters_invalid', error.message);
    } on TypeError {
      throw semanticFailure('map3d.parameters_invalid',
          'The spatial action parameters have invalid types or missing fields.');
    }
  }
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
