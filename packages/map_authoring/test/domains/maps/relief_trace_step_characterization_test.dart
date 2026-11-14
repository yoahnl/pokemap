import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/src/domains/maps/map3d_edit_batch_actions.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../../support/reliability_map_fixture.dart';
import '../assets/resource_library_actions_test.dart' show librarySnapshot;
import 'border_spatial_actions_test.dart' show context;

Map<String, Object?> _surface(String id, double height, List<List<int>> rects,
        {double gradientZ = 0, double originZ = 0}) =>
    {
      'id': id,
      'x': 0,
      'z': originZ,
      'height': height,
      'gradientZ': gradientZ,
      'footprints': [
        for (final r in rects)
          [
            {'x': r[0], 'z': r[1] - originZ},
            {'x': r[0] + r[2], 'z': r[1] - originZ},
            {'x': r[0] + r[2], 'z': r[1] + r[3] - originZ},
            {'x': r[0], 'z': r[1] + r[3] - originZ},
          ]
      ],
    };

Map<String, Object?> _op(String action, Map<String, Object?> parameters) =>
    {'actionId': action, 'actionVersion': 1, 'parameters': parameters};

Map<String, Object?> _trace(String featureId, double lower, double upper) =>
    _op('intent.border.trace_step', {
      'layerId': 'border',
      'featureId': featureId,
      'blueprintId': 'fence',
      'lowerHeight': lower,
      'upperHeight': upper,
    });

final _fixture =
    ReliabilityMapContent.create(ReliabilityMapVariant.missingCliff);

MapData _apply(
    List<Map<String, Object?>> surfaces, List<Map<String, Object?>> traces) {
  final draft = const Map3dEditBatchActions().build(context(
      librarySnapshot([_fixture.map], project: _fixture.project),
      'map3d.edit_batch', {
    'mapId': 'map',
    'operations': [
      _op('map3d.terrain.surface.upsert_batch', {
        'surfaces': [
          _surface('base', 1, [
            [0, 0, 24, 16]
          ]),
          ...surfaces
        ]
      }),
      ...traces,
    ],
  }));
  return MapData.fromJson(Map<String, dynamic>.from(
      jsonDecode(utf8.decode(draft.changeSet.changes.single.afterBytes!))
          as Map));
}

BorderFeature _feature(MapData map, String id) =>
    map.layers.whereType<BorderLayer>().single.content.featureById(id)!;

Map<String, int> _pieces(BorderFeature feature) {
  final counts = <String, int>{};
  for (final placement in feature.materialization!.spatialPlacements) {
    counts.update(placement.primitiveId, (value) => value + 1,
        ifAbsent: () => 1);
  }
  return counts;
}

List<String> _diagnostics(MapData map, String featureId) => [
      for (final diagnostic in diagnoseSpatialBorderFeature(
              manifest: _fixture.project,
              map: map,
              layerId: 'border',
              featureId: featureId)
          .diagnostics)
        diagnostic.code
    ];

Set<GridPos> _nodes(BorderFeature feature) => {
      for (final stroke in (feature.geometry as BorderStrokeGeometry).strokes)
        ...stroke.points
    };

void main() {
  test('a closed painted rectangle resolves four outer corners in one gesture',
      () {
    final map = _apply([
      _surface('plateau', 2, [
        [8, 5, 6, 4]
      ])
    ], [
      _trace('relief', 1, 2)
    ]);
    final feature = _feature(map, 'relief');
    final stroke = (feature.geometry as BorderStrokeGeometry).strokes.single;
    expect(stroke.closed, isTrue);
    expect(stroke.points, hasLength(20));
    expect(_pieces(feature), {'corner-right': 4, 'lineStraight': 16});
    expect(_diagnostics(map, 'relief'), isEmpty);
    expect(
        inspectSpatialMapIntegrity(manifest: _fixture.project, map: map)
            .exposedCellCount,
        0);
  });

  test('an L region picks the inner corner piece for its single left turn', () {
    final map = _apply([
      _surface('plateau', 2, [
        [6, 4, 6, 3],
        [6, 7, 3, 3]
      ])
    ], [
      _trace('relief', 1, 2)
    ]);
    final feature = _feature(map, 'relief');
    expect((feature.geometry as BorderStrokeGeometry).strokes.single.closed,
        isTrue);
    expect(_pieces(feature),
        {'corner-right': 5, 'corner-left': 1, 'lineStraight': 18});
    expect(_diagnostics(map, 'relief'), isEmpty);
  });

  test('a region touching the map border ends with two caps', () {
    final map = _apply([
      _surface('plateau', 2, [
        [0, 5, 4, 4]
      ])
    ], [
      _trace('relief', 1, 2)
    ]);
    final feature = _feature(map, 'relief');
    final stroke = (feature.geometry as BorderStrokeGeometry).strokes.single;
    expect(stroke.closed, isFalse);
    expect(stroke.points.first, const GridPos(x: 0, y: 5));
    expect(stroke.points.last, const GridPos(x: 0, y: 9));
    expect(
        _pieces(feature), {'lineCap': 2, 'corner-right': 2, 'lineStraight': 9});
  });

  test('an inner terrace adds its own loop and leaves the outer walls intact',
      () {
    final plateau = _surface('plateau', 2, [
      [6, 4, 10, 8]
    ]);
    final alone = _apply([plateau], [_trace('relief', 1, 2)]);
    final map = _apply([
      plateau,
      _surface('terrace', 3, [
        [9, 6, 3, 3]
      ])
    ], [
      _trace('relief', 1, 2),
      _trace('terrace', 2, 3)
    ]);
    expect(_feature(map, 'relief').materialization,
        _feature(alone, 'relief').materialization);
    expect(_pieces(_feature(map, 'terrace')),
        {'corner-right': 4, 'lineStraight': 8});
    expect(
        _nodes(_feature(map, 'relief'))
            .intersection(_nodes(_feature(map, 'terrace'))),
        isEmpty);
    expect(_diagnostics(map, 'terrace'), isEmpty);
  });

  test('a terrace touching the outer contour is refused by a one-level profile',
      () {
    for (final traces in [
      [_trace('relief', 1, 2)],
      [_trace('relief', 1, 2), _trace('terrace', 2, 3)],
    ]) {
      expect(
          () => _apply([
                _surface('plateau', 2, [
                  [6, 4, 10, 8]
                ]),
                _surface('terrace', 3, [
                  [6, 6, 3, 3]
                ])
              ], traces),
          throwsA(isA<MapAuthoringException>()
              .having((e) => e.code, 'code', 'intent.step_profile_incompatible')
              .having(
                  (e) => {
                        for (final d
                            in (e.details['diagnostics'] as List).cast<Map>())
                          d['code']
                      },
                  'codes',
                  {'border.spatial.face_base_mismatch'})));
    }
  });

  test('a gradient ramp opens the loop with caps and leaves its flanks bare',
      () {
    final map = _apply([
      _surface('plateau', 2, [
        [8, 3, 6, 4]
      ]),
      _surface(
          'ramp',
          2,
          [
            [10, 7, 2, 2]
          ],
          gradientZ: -.5,
          originZ: 7)
    ], [
      _trace('relief', 1, 2)
    ]);
    final feature = _feature(map, 'relief');
    final stroke = (feature.geometry as BorderStrokeGeometry).strokes.single;
    expect(stroke.closed, isFalse);
    expect(stroke.points.first, const GridPos(x: 10, y: 7));
    expect(stroke.points.last, const GridPos(x: 12, y: 7));
    expect(_pieces(feature),
        {'lineCap': 2, 'corner-right': 4, 'lineStraight': 13});
    expect(
        _nodes(feature).intersection({
          const GridPos(x: 10, y: 8),
          const GridPos(x: 12, y: 8),
          const GridPos(x: 11, y: 7),
        }),
        isEmpty);
    expect(_diagnostics(map, 'relief'), isEmpty);
  });
}
