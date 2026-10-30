import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/src/domains/maps/map3d_edit_batch_actions.dart';
import 'package:map_authoring/src/domains/maps/map3d_edit_projection.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../../support/reliability_map_fixture.dart';
import '../assets/resource_library_actions_test.dart' show librarySnapshot;
import 'border_spatial_actions_test.dart' show context;

void main() {
  test('descriptor admits exactly the 24 semantic operations', () {
    final descriptor =
        MapMutationDispatcher.canonical().descriptor('map3d.edit_batch');
    expect(descriptor.extensions['admittedActions'], hasLength(24));
    expect(descriptor.extensions['defaultSeed'], 0);
    expect(Map3dEditProjection.admittedActions,
        isNot(contains('map3d.edit_batch')));
  });

  test('three paint operations compose on one map and one final encoding', () {
    final f = ReliabilityMapContent.create(ReliabilityMapVariant.healthy);
    final source = f.map.toJson();
    final draft =
        _build(f, [for (var x = 10; x < 13; x++) _paint(x, 8, 'sea')]);
    final after = _decode(draft);
    final layer = after.layers.whereType<SmartTileLayer>().first;
    for (var x = 10; x < 13; x++) {
      expect(
          smartTileMaterialIdAt(layer, mapSize: after.size, x: x, y: 8), 'sea');
    }
    expect(draft.changeSet.changes, hasLength(1));
    expect(draft.preview['operationCount'], 3);
    expect(draft.preview['work'], containsPair('mapEncodings', 1));
    expect(draft.preview['work'], containsPair('integrityInspections', 2));
    expect(f.map.toJson(), source);
  });

  test('operation three failure leaves source unchanged with indexed cause',
      () {
    final f = ReliabilityMapContent.create(ReliabilityMapVariant.healthy);
    final source = f.map.toJson();
    expect(
        () => _build(f, [
              _paint(10, 8, 'sea'),
              _paint(11, 8, 'sea'),
              _paint(12, 8, 'missing')
            ]),
        throwsA(isA<MapAuthoringException>()
            .having((e) => e.code, 'code', 'map3d.edit_batch.operation_failed')
            .having((e) => e.details['operationIndex'], 'operationIndex', 2)
            .having((e) => (e.details['cause'] as Map)['code'], 'cause',
                'smart_tile.cell.material_not_allowed')));
    expect(f.map.toJson(), source);
  });

  test('empty and excessive operation counts are rejected', () {
    final f = ReliabilityMapContent.create(ReliabilityMapVariant.healthy);
    for (final operations in [
      <Map<String, Object?>>[],
      List.filled(65, _paint(10, 8, 'sea'))
    ]) {
      expect(
          () => _build(f, operations),
          throwsA(isA<MapAuthoringException>().having(
              (e) => e.code, 'code', 'map3d.edit_batch.request_invalid')));
    }
  });

  test(
      'foreign maps recursive batches and foreign resource writes are rejected',
      () {
    final f = ReliabilityMapContent.create(ReliabilityMapVariant.healthy);
    for (final operation in [
      {
        'actionId': 'map3d.edit_batch',
        'actionVersion': 1,
        'parameters': <String, Object?>{}
      },
      {
        'actionId': 'smart_tile.material.create',
        'actionVersion': 1,
        'parameters': <String, Object?>{}
      },
      {
        ..._paint(10, 8, 'sea'),
        'parameters': {
          'mapId': 'other',
          ...(_paint(10, 8, 'sea')['parameters'] as Map)
        }
      }
    ]) {
      expect(
          () => _build(f, [operation]),
          throwsA(isA<MapAuthoringException>().having(
              (e) => e.code, 'code', 'map3d.edit_batch.operation_failed')));
    }
  });

  test('entirely unchanged batch produces no resource write', () {
    final f = ReliabilityMapContent.create(ReliabilityMapVariant.healthy);
    final draft = _build(f, [_paint(10, 8, 'grass'), _paint(11, 8, 'grass')]);
    expect(draft.changeSet.changes, isEmpty);
    expect(draft.preview['status'], 'unchanged');
    expect(draft.preview['operations'],
        everyElement(containsPair('status', 'unchanged')));
  });

  test('a transient ground gap can be restored before final guards', () {
    final f = ReliabilityMapContent.create(ReliabilityMapVariant.healthy);
    final draft = _build(f, [
      {
        'actionId': 'smart_tile.cell.erase',
        'actionVersion': 1,
        'parameters': {
          'layerId': 'terrain',
          'cells': [
            {'x': 12, 'y': 8}
          ]
        }
      },
      _paint(12, 8, 'sea'),
    ]);
    expect(draft.changeSet.changes, hasLength(1));
    expect(draft.preview['groundGapsIntroducedCount'], 0);
  });

  test('new exposed gaps refuse by default and report when explicit', () {
    final f = ReliabilityMapContent.create(ReliabilityMapVariant.healthy);
    final op = {
      'actionId': 'smart_tile.cell.erase',
      'actionVersion': 1,
      'parameters': {
        'layerId': 'terrain',
        'cells': [
          {'x': 12, 'y': 8}
        ]
      }
    };
    expect(
        () => _build(f, [op]),
        throwsA(isA<MapAuthoringException>()
            .having((e) => e.code, 'code', 'map3d.edit_batch.guard_refused')));
    final draft = _build(f, [op], guards: {'groundGaps': 'report'});
    expect(draft.preview['groundGapsIntroducedCount'], 1);
  });

  test('preexisting unrelated exposed gap does not reject a local repair', () {
    final f = ReliabilityMapContent.create(ReliabilityMapVariant.interiorHole);
    final draft = _build(f, [_paint(10, 8, 'sea')]);
    expect(draft.changeSet.changes, hasLength(1));
    expect(draft.preview['groundGapsIntroducedCount'], 0);
    expect(
        draft.preview['finalIntegrity'], containsPair('exposedCellCount', 1));
  });

  test('removing a shore and restoring ground is one final valid state', () {
    final f = ReliabilityMapContent.create(ReliabilityMapVariant.shoreGap);
    final draft = _build(f, [
      {
        'actionId': 'border_layer.feature_delete',
        'actionVersion': 1,
        'parameters': {'layerId': 'border', 'featureId': 'fence'}
      },
      for (var x = 3; x <= 6; x++) _paint(x, f.contourY, 'grass'),
    ]);
    final after = _decode(draft);
    expect(
        after.layers.whereType<BorderLayer>().single.content.features, isEmpty);
    expect(
        inspectSpatialMapIntegrity(manifest: f.project, map: after).groundGaps,
        isEmpty);
  });

  test(
      '64 operations keep one final encoding and at most two integrity inspections',
      () {
    final f = ReliabilityMapContent.create(ReliabilityMapVariant.healthy);
    final draft = _build(f, [
      for (var i = 0; i < 64; i++)
        _paint(10 + i % 4, 8 + i ~/ 4 % 4, i.isEven ? 'sea' : 'grass')
    ]);
    expect(draft.preview['work'], containsPair('mapEncodings', 1));
    expect(draft.preview['work'], containsPair('integrityInspections', 2));
  });
  for (final count in [1, 3, 64]) {
    test(
        '$count operations invoke the real final codec once and integrity twice',
        () {
      final fixture =
          ReliabilityMapContent.create(ReliabilityMapVariant.healthy);
      var encodes = 0, inspections = 0;
      final actions = Map3dEditBatchActions(encodeMap: (map) {
        encodes++;
        return encodeMapAuthoringDocument(map);
      }, inspectIntegrity: ({required manifest, required map}) {
        inspections++;
        return inspectSpatialMapIntegrity(manifest: manifest, map: map);
      });
      final snapshot = librarySnapshot([fixture.map], project: fixture.project);
      actions.build(context(snapshot, 'map3d.edit_batch', {
        'mapId': fixture.map.id,
        'operations': [for (var i = 0; i < count; i++) _paint(10, 8, 'sea')],
      }));
      expect(encodes, 1);
      expect(inspections, 2);
    });
  }

  test('multiple edits rematerialize the same touched Border once', () {
    final fixture = ReliabilityMapContent.create(ReliabilityMapVariant.healthy);
    final slot =
        fixture.feature.materialization!.spatialPlacements.first.slotKey;
    final draft = _build(fixture, [
      {
        'actionId': 'border_layer.feature_update',
        'actionVersion': 1,
        'parameters': {
          'layerId': 'border',
          'featureId': 'fence',
          'name': 'Renamed'
        }
      },
      {
        'actionId': 'border_layer.feature_set_suppressed',
        'actionVersion': 1,
        'parameters': {
          'layerId': 'border',
          'featureId': 'fence',
          'slotKey': slot,
          'suppressed': true
        }
      },
      for (var i = 0; i < 2; i++)
        {
          'actionId': 'border_layer.materialize_batch_apply',
          'actionVersion': 1,
          'parameters': {
            'features': [
              {'layerId': 'border', 'featureId': 'fence'}
            ],
            'tileWidthPx': 32,
            'tileHeightPx': 32,
            'resolverVersion': borderResolverVersion
          }
        },
    ], guards: {
      'groundGaps': 'report'
    });
    expect(draft.preview['rematerializedFeatures'], hasLength(1));
    final after = _decode(draft);
    final feature =
        after.layers.whereType<BorderLayer>().single.content.features.single;
    expect(feature.name, 'Renamed');
    expect(feature.overrides.single.suppressed, isTrue);
    expect(
        diagnoseSpatialBorderFeature(
                manifest: fixture.project,
                map: after,
                layerId: 'border',
                featureId: 'fence')
            .diagnostics
            .where((d) => d.code == 'border.spatial.materialization_stale'),
        isEmpty);
  });

  test('already absent semantic deletions are accepted as unchanged', () {
    final fixture =
        ReliabilityMapContent.create(ReliabilityMapVariant.missingCliff);
    final draft = _build(fixture, [
      {
        'actionId': 'border_layer.feature_delete',
        'actionVersion': 1,
        'parameters': {'layerId': 'border', 'featureId': 'fence'}
      },
      {
        'actionId': 'map3d.instance.delete_batch',
        'actionVersion': 1,
        'parameters': {
          'instanceIds': ['already-absent']
        }
      },
    ]);
    expect(draft.changeSet.changes, isEmpty);
    expect(draft.preview['operations'],
        everyElement(containsPair('status', 'unchanged')));
  });
  test('every admitted operation runs its shared raw semantic projection', () {
    final fixture = ReliabilityMapContent.create(ReliabilityMapVariant.healthy);
    final source = fixture.feature;
    final slot = source.materialization!.spatialPlacements.first;
    final replacement = encodeBorderBlueprintRecordJson(
        fixture.project.borderCatalog.records.single,
        formatVersion: ProjectBorderCatalog.latestSupportedFormatVersion)
      ..['id'] = 'replacement';
    final project = fixture.project.copyWith(
        borderCatalog: ProjectBorderCatalog(
            formatVersion: ProjectBorderCatalog.latestSupportedFormatVersion,
            records: [
          ...fixture.project.borderCatalog.records,
          decodeBorderBlueprintRecordJson(replacement,
              formatVersion: ProjectBorderCatalog.latestSupportedFormatVersion)
        ]));
    final surface = SpatialTerrainSurface(
        id: 'plateau',
        x: 10,
        z: 10,
        height: 1,
        footprints: [
          BorderGroundFootprint(points: [
            BorderGroundPoint(x: 0, z: 0),
            BorderGroundPoint(x: 2, z: 0),
            BorderGroundPoint(x: 2, z: 2),
            BorderGroundPoint(x: 0, z: 2),
          ])
        ]);
    final base = const SpatialMapOperations()
        .upsertTerrainSurfaces(fixture.map, [surface]);
    final operations = <String, Map<String, Object?>>{
      'smart_tile.cell.paint': {
        'layerId': 'terrain',
        'materialId': 'sea',
        'cells': [
          {'x': 10, 'y': 8}
        ]
      },
      'smart_tile.cell.paint_batch': {
        'layerId': 'terrain',
        'strokes': [
          {
            'materialId': 'sea',
            'cells': [
              {'x': 10, 'y': 8}
            ]
          }
        ]
      },
      'smart_tile.cell.erase': {
        'layerId': 'terrain',
        'cells': [
          {'x': 10, 'y': 8}
        ]
      },
      'map3d.terrain.surface.upsert_batch': {
        'surfaces': [surface.copyWith(height: 2).toJson()]
      },
      'map3d.terrain.surface.delete_batch': {
        'surfaceIds': ['plateau']
      },
      'map3d.instance.upsert_batch': {
        'instances': [
          SpatialModelInstance(
                  id: 'new-object',
                  modelId: 'tree',
                  position: Model3dVector3(x: 15, y: 1, z: 12))
              .toJson()
        ]
      },
      'map3d.instance.delete_batch': {
        'instanceIds': ['unrelated-object']
      },
      'border_layer.feature_create': {
        'layerId': 'border',
        'featureId': 'new-feature',
        'name': 'New',
        'blueprintId': 'fence',
        'seed': 17,
        'geometry': encodeBorderFeatureGeometryJson(source.geometry)
      },
      'border_layer.feature_update': {
        'layerId': 'border',
        'featureId': 'fence',
        'name': 'Renamed'
      },
      'border_layer.feature_delete': {
        'layerId': 'border',
        'featureId': 'fence'
      },
      'border_layer.feature_move': {
        'layerId': 'border',
        'featureId': 'fence',
        'dx': 1,
        'dy': 0
      },
      'border_layer.stroke_add': {
        'layerId': 'border',
        'featureId': 'fence',
        'strokeId': 'new-stroke',
        'points': [
          {'x': 8, 'y': 4},
          {'x': 9, 'y': 4}
        ]
      },
      'border_layer.stroke_update': {
        'layerId': 'border',
        'featureId': 'fence',
        'strokeId': 'step',
        'points': [
          {'x': 3, 'y': 4},
          {'x': 4, 'y': 4},
          {'x': 5, 'y': 4}
        ]
      },
      'border_layer.stroke_delete': {
        'layerId': 'border',
        'featureId': 'fence',
        'strokeId': 'step'
      },
      'border_layer.stroke_erase': {
        'layerId': 'border',
        'featureId': 'fence',
        'points': [
          {'x': 3, 'y': 4}
        ]
      },
      'border_layer.region_fill': {
        'layerId': 'border',
        'featureId': 'fence',
        'x': 3,
        'y': 4,
        'width': 2,
        'height': 1
      },
      'border_layer.region_clear': {
        'layerId': 'border',
        'featureId': 'fence',
        'x': 3,
        'y': 4,
        'width': 2,
        'height': 1
      },
      'border_layer.feature_set_replacement': {
        'layerId': 'border',
        'featureId': 'fence',
        'slotKey': slot.slotKey,
        'primitiveId': slot.primitiveId
      },
      'border_layer.feature_set_suppressed': {
        'layerId': 'border',
        'featureId': 'fence',
        'slotKey': slot.slotKey,
        'suppressed': true
      },
      'border_layer.feature_clear_slot_override': {
        'layerId': 'border',
        'featureId': 'fence',
        'slotKey': slot.slotKey
      },
      'border_layer.feature_set_keep_out': {
        'layerId': 'border',
        'featureId': 'fence',
        'regions': [
          {
            'id': 'keepout',
            'region': {
              'width': 24,
              'height': 16,
              'cells': List.filled(24 * 16, false)..[4 * 24 + 3] = true
            }
          }
        ]
      },
      for (final action in [
        'border_layer.relink_apply',
        'border_layer.feature_set_blueprint'
      ])
        action: {
          'layerId': 'border',
          'featureId': 'fence',
          'targetBlueprintId': 'replacement'
        },
      'border_layer.materialize_batch_apply': {
        'features': [
          {'layerId': 'border', 'featureId': 'fence'}
        ],
        'tileWidthPx': 32,
        'tileHeightPx': 32,
        'resolverVersion': borderResolverVersion
      },
    };
    expect(operations.keys.toSet(), Map3dEditProjection.admittedActions);
    for (final operation in operations.entries) {
      var map = base;
      if (operation.key.startsWith('border_layer.region_')) {
        map = updateBorderFeatureGeometry(map,
            layerId: 'border',
            featureId: 'fence',
            geometry: BorderRegionGeometry(
                width: 24, height: 16, cells: List.filled(24 * 16, false)));
      }
      final snapshot = librarySnapshot([map], project: project);
      final planning = context(snapshot, 'map3d.edit_batch', {'mapId': 'map'});
      final result = const Map3dEditProjection().project(
          planning: planning,
          map: map,
          operation: {
            'actionId': operation.key,
            'actionVersion': 1,
            'parameters': operation.value
          },
          operationIndex: 0,
          seed: 0);
      expect(result.operation, operation.key, reason: operation.key);
      expect(result.map.id, map.id, reason: operation.key);
    }
  });
  for (final size in [
    const GridSize(width: 24, height: 16),
    const GridSize(width: 48, height: 32)
  ]) {
    for (final unrelated in [0, 900]) {
      test(
          'fixed-region edit reports the unclosed whole-map cost for $size and $unrelated foreign objects',
          () {
        final fixture =
            ReliabilityMapContent.create(ReliabilityMapVariant.healthy);
        final original = fixture.map;
        final ground = original.layers.whereType<SmartTileLayer>().single;
        final cells = [
          for (var y = 0; y < size.height; y++)
            for (var x = 0; x < size.width; x++)
              x < original.size.width && y < original.size.height
                  ? ground.field.semanticCells[y * original.size.width + x]
                  : 1
        ];
        final map = original.copyWith(
            size: size,
            layers: [
              for (final layer in original.layers)
                layer is SmartTileLayer
                    ? layer.copyWith(
                        field: SmartTileField.cell(semanticCells: cells))
                    : layer,
            ],
            spatialScene: MapSpatialScene(
                width: size.width,
                depth: size.height,
                heightLevels: [
                  for (var y = 0; y < size.height; y++)
                    for (var x = 0; x < size.width; x++) y >= 4 ? 1 : 0
                ],
                instances: [
                  ...original.spatialScene!.instances,
                  for (var i = 0; i < unrelated; i++)
                    SpatialModelInstance(
                        id: 'foreign-object-$i',
                        modelId: 'tree',
                        position: Model3dVector3(x: 20, y: 1, z: 12))
                ]));
        final inspectedAreas = <int>[], inspectedObjects = <int>[];
        final actions = Map3dEditBatchActions(
            inspectIntegrity: ({required manifest, required map}) {
          inspectedAreas.add(map.spatialScene!.width * map.spatialScene!.depth);
          inspectedObjects.add(map.spatialScene!.instances.length);
          return inspectSpatialMapIntegrity(manifest: manifest, map: map);
        });
        final planning = context(
            librarySnapshot([map], project: fixture.project),
            'map3d.edit_batch', {
          'mapId': 'map',
          'operations': [_paint(12, 8, 'sea')]
        });
        final timer = Stopwatch()..start();
        final draft = actions.build(planning);
        timer.stop();
        expect(inspectedAreas,
            [size.width * size.height, size.width * size.height]);
        expect(inspectedObjects, [
          map.spatialScene!.instances.length,
          map.spatialScene!.instances.length
        ]);
        expect(draft.preview['work'],
            containsPair('localCostAcceptance', 'PARTIAL'));
        expect(draft.preview['work'],
            containsPair('integrityScope', 'whole_selected_map'));
        final after = _decode(draft);
        expect(after.spatialScene, map.spatialScene);
        expect(after.layers.whereType<BorderLayer>().single,
            original.layers.whereType<BorderLayer>().single);
        print(
            'R3 projection-only cells=${size.width * size.height} unrelatedObjects=$unrelated elapsedUs=${timer.elapsedMicroseconds}');
      });
    }
  }
}

Map<String, Object?> _paint(int x, int y, String material) => {
      'actionId': 'smart_tile.cell.paint',
      'actionVersion': 1,
      'parameters': {
        'layerId': 'terrain',
        'materialId': material,
        'cells': [
          {'x': x, 'y': y}
        ]
      },
    };

AuthoringMutationDraft _build(
    ReliabilityMapContent fixture, List<Map<String, Object?>> operations,
    {Map<String, Object?> guards = const {}}) {
  final snapshot = librarySnapshot([fixture.map], project: fixture.project);
  return const Map3dEditBatchActions()
      .build(context(snapshot, 'map3d.edit_batch', {
    'mapId': fixture.map.id,
    'operations': operations,
    'guards': guards,
  }));
}

MapData _decode(AuthoringMutationDraft draft) =>
    MapData.fromJson(Map<String, dynamic>.from(
        jsonDecode(utf8.decode(draft.changeSet.changes.single.afterBytes!))
            as Map));
