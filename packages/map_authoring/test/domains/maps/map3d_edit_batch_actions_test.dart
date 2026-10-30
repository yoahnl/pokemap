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
