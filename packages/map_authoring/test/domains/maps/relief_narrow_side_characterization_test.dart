import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/src/domains/maps/map3d_edit_batch_actions.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../../support/reliability_map_fixture.dart';
import '../assets/resource_library_actions_test.dart' show librarySnapshot;
import 'border_spatial_actions_test.dart' show context;

final _fixture =
    ReliabilityMapContent.create(ReliabilityMapVariant.missingCliff);

ProjectManifest _innerCornerJoins(int cells) {
  final raw = encodeBorderBlueprintRecordJson(
      _fixture.project.borderCatalog.records.single,
      formatVersion: 13);
  for (final key in ['draft', 'latestPublished']) {
    final definition = (raw[key] as Map)['definition'] as Map;
    for (final primitive in (definition['primitives'] as List).cast<Map>()) {
      if (primitive['id'] == 'corner-left')
        primitive['cornerJoinCells'] = cells;
    }
  }
  return _fixture.project.copyWith(
      borderCatalog: ProjectBorderCatalog(
          formatVersion: 13,
          records: [decodeBorderBlueprintRecordJson(raw, formatVersion: 13)]));
}

MapData _apply(ProjectManifest project, List<List<int>> rectangles) {
  final draft = const Map3dEditBatchActions().build(context(
      librarySnapshot([_fixture.map], project: project), 'map3d.edit_batch', {
    'mapId': 'map',
    'operations': [
      {
        'actionId': 'map3d.terrain.surface.upsert_batch',
        'actionVersion': 1,
        'parameters': {
          'surfaces': [
            for (final (index, r) in [
              [0, 0, 24, 16],
              ...rectangles
            ].indexed)
              {
                'id': 's$index',
                'x': r[0],
                'z': r[1],
                'height': index == 0 ? 1 : 2,
                'footprints': [
                  [
                    {'x': 0, 'z': 0},
                    {'x': r[2], 'z': 0},
                    {'x': r[2], 'z': r[3]},
                    {'x': 0, 'z': r[3]},
                  ]
                ],
              }
          ]
        },
      },
      {
        'actionId': 'intent.border.trace_step',
        'actionVersion': 1,
        'parameters': {
          'layerId': 'border',
          'featureId': 'relief',
          'blueprintId': 'fence',
          'lowerHeight': 1,
          'upperHeight': 2,
          'cells': [
            {'x': rectangles.first[0], 'y': rectangles.first[1]}
          ],
        },
      },
    ],
  }));
  return MapData.fromJson(Map<String, dynamic>.from(
      jsonDecode(utf8.decode(draft.changeSet.changes.single.afterBytes!))
          as Map));
}

void main() {
  final wide = _innerCornerJoins(1);

  test('a 2x2 plateau resolves when only inner corners are wide', () {
    final map = _apply(wide, [
      [8, 5, 2, 2]
    ]);
    expect(
        map.layers
            .whereType<BorderLayer>()
            .single
            .content
            .featureById('relief')!
            .materialization,
        isNotNull);
  });

  test('a wide inner corner next to another corner is refused', () {
    final notch = [
      [8, 5, 6, 2],
      [8, 7, 1, 1],
    ];
    expect(() => _apply(_innerCornerJoins(0), notch), returnsNormally);
    expect(
        () => _apply(wide, notch),
        throwsA(isA<MapAuthoringException>()
            .having((e) => e.code, 'code', 'intent.step_profile_incompatible')
            .having(
                (e) => {
                      for (final d
                          in (e.details['diagnostics'] as List).cast<Map>())
                        d['code']
                    },
                'codes',
                contains('border.spatial.corner_join_conflict'))));
  });
}
