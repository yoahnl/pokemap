import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

void main() {
  test('native edit actions publish their real input schema', () {
    final required = {
      'smart_tile.cell.paint',
      'smart_tile.cell.erase',
      'border_layer.stroke_add',
      'border_layer.stroke_update',
      'border_layer.stroke_delete',
      'border_layer.feature_delete',
      'border_layer.feature_move',
      'border_layer.region_fill',
      'border_layer.region_clear',
      'border_layer.feature_set_keep_out',
    };
    final actions = MapMutationDispatcher.canonical().descriptors;
    for (final id in required) {
      expect(
          actions
              .singleWhere((action) => action.id == id)
              .extensions['inputSchema'],
          isA<Map>(),
          reason: id);
    }
  });
  final description = <String, Object?>{
    'protocol': 'pokemap.authoring.v1',
    'schemaVersion': 1,
    'mutationActions': [
      for (final id in [
        'map3d.terrain.surface.upsert_batch',
        'border_layer.feature_delete',
        'smart_tile.cell.paint_batch',
        'map.create',
        'scene.create',
      ])
        {
          'id': id,
          'version': 1,
          'summary': 'Execute $id',
          'resourceKinds': ['map'],
          'riskLevel': 'low',
          'requiredPermissions': ['projectWrite'],
          'extensions': {
            'inputSchema': {
              'type': 'object',
              'additionalProperties': false,
              'required': ['mapId'],
              'properties': {
                'mapId': {'type': 'string', 'minLength': 1},
              },
            },
          },
        },
    ],
    'resourceKinds': [
      {'id': 'map'},
      {'id': 'scene'},
    ],
    'unrelatedLargeSection': 'x' * 100000,
  };

  test('default discovery preserves the historical complete response', () {
    expect(identical(describeAuthoringCapabilities(description), description),
        isTrue);
  });

  test('map3d includes native Borders, Smart Tile and map creation', () {
    final result = describeAuthoringCapabilities(description,
        domain: 'map3d', view: 'compact');
    final actions = (result['mutationActions'] as List).cast<Map>();
    expect(actions.map((action) => action['id']), [
      'border_layer.feature_delete',
      'map.create',
      'map3d.terrain.surface.upsert_batch',
      'smart_tile.cell.paint_batch',
    ]);
    expect(actions.every((action) => action['version'] == 1), isTrue);
    expect(actions.every((action) => action['inputSchemaAvailable'] == true),
        isTrue);
    expect(utf8.encode(jsonEncode(result)).length, lessThan(40000));
    expect(result.containsKey('unrelatedLargeSection'), isFalse);
  });

  test('action detail retains the actual schema and canonical contract', () {
    final result = describeAuthoringCapabilities(description,
        actionIds: ['border_layer.feature_delete'], view: 'compact');
    final action = (result['mutationActions'] as List).single as Map;
    expect(
        (action['extensions'] as Map)['inputSchema'],
        ((description['mutationActions'] as List)[1] as Map)['extensions']
            .cast<String, Object?>()['inputSchema']);
    expect(action['requiredPermissions'], ['projectWrite']);
  });

  test('missing schemas are explicitly unavailable rather than invented', () {
    final result = describeAuthoringCapabilities({
      'mutationActions': [
        {
          'id': 'border_layer.feature_delete',
          'version': 1,
          'summary': 'Delete feature',
          'inputSchemaId': 'schema.only.an.identifier',
        },
      ],
    }, domain: 'map3d', view: 'compact');
    final action = (result['mutationActions'] as List).single as Map;
    expect(action['inputSchemaAvailable'], isFalse);
  });

  test('unknown filters and action identities are rejected', () {
    for (final callback in [
      () => describeAuthoringCapabilities(description, domain: 'unknown'),
      () => describeAuthoringCapabilities(description, view: 'unknown'),
      () => describeAuthoringCapabilities(description, actionIds: ['missing']),
      () => describeAuthoringCapabilities(description,
          actionIds: ['map.create', 'map.create']),
    ]) {
      expect(callback, throwsFormatException);
    }
  });
}
