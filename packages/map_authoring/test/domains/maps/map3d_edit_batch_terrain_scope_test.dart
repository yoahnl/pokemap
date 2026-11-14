import 'dart:convert';

import 'package:map_authoring/src/domains/maps/map3d_edit_batch_actions.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../../support/reliability_map_fixture.dart';
import '../assets/resource_library_actions_test.dart' show librarySnapshot;
import 'border_spatial_actions_test.dart' show context;

final _fixture =
    ReliabilityMapContent.create(ReliabilityMapVariant.missingCliff);

Map<String, Object?> _surface(String id, double height, List<int> r) => {
      'id': id,
      'x': r[0],
      'z': r[1],
      'height': height,
      'footprints': [
        [
          {'x': 0, 'z': 0},
          {'x': r[2], 'z': 0},
          {'x': r[2], 'z': r[3]},
          {'x': 0, 'z': r[3]},
        ]
      ],
    };

Map<String, Object?> _upsert(List<Map<String, Object?>> surfaces) => {
      'actionId': 'map3d.terrain.surface.upsert_batch',
      'actionVersion': 1,
      'parameters': {'surfaces': surfaces},
    };

Map<String, Object?> _trace(String featureId, int x, int y) => {
      'actionId': 'intent.border.trace_step',
      'actionVersion': 1,
      'parameters': {
        'layerId': 'border',
        'featureId': featureId,
        'blueprintId': 'fence',
        'lowerHeight': 1,
        'upperHeight': 2,
        'cells': [
          {'x': x, 'y': y}
        ],
      },
    };

({MapData map, Map<String, Object?> work}) _batch(
    MapData map, List<Map<String, Object?>> operations) {
  final draft = const Map3dEditBatchActions().build(context(
      librarySnapshot([map], project: _fixture.project),
      'map3d.edit_batch',
      {'mapId': 'map', 'operations': operations}));
  return (
    map: MapData.fromJson(Map<String, dynamic>.from(
        jsonDecode(utf8.decode(draft.changeSet.changes.single.afterBytes!))
            as Map)),
    work: Map<String, Object?>.from(draft.preview['work'] as Map),
  );
}

void main() {
  test('a terrain edit rediagnoses only the borders near it', () {
    final painted = _batch(_fixture.map, [
      _upsert([
        _surface('base', 1, [0, 0, 24, 16]),
        _surface('west', 2, [2, 3, 4, 4]),
        _surface('east', 2, [16, 3, 4, 4]),
      ]),
      _trace('west-cliff', 3, 4),
      _trace('east-cliff', 17, 4),
    ]).map;
    final edited = _batch(painted, [
      _upsert([
        _surface('east', 2, [16, 3, 5, 4])
      ]),
      _trace('east-cliff', 17, 4),
    ]);
    expect(edited.work['touchedBorderCount'], 1);
    expect(edited.work['borderDiagnoses'], 3);
    final west = edited.map.layers
        .whereType<BorderLayer>()
        .single
        .content
        .featureById('west-cliff')!;
    expect(
        west,
        painted.layers
            .whereType<BorderLayer>()
            .single
            .content
            .featureById('west-cliff'));
  });
}
