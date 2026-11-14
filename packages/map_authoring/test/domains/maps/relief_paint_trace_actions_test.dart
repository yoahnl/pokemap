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

ProjectManifest _withTwoLevelProfile(ProjectManifest project) {
  final raw = encodeBorderBlueprintRecordJson(
      project.borderCatalog.records.single,
      formatVersion: 5);
  raw['id'] = 'fence-2';
  for (final key in ['draft', 'latestPublished']) {
    final definition = (raw[key] as Map)['definition'] as Map;
    for (final primitive in (definition['primitives'] as List).cast<Map>()) {
      primitive['sourceModelId'] = 'cliff-2';
    }
  }
  final cliff = project.models3d.singleWhere((model) => model.id == 'cliff');
  return project.copyWith(
    models3d: [
      ...project.models3d,
      ProjectModel3dEntry(
        id: 'cliff-2',
        name: 'Two level cliff face',
        sourceAssetId: 'cliff-2-source',
        relativePath: 'assets/models3d/cliff-2.glb',
        inspection: Model3dInspection(
          bounds: Model3dBounds(
            min: Model3dVector3(x: -.2, y: -2, z: -.2),
            max: Model3dVector3(x: .2, y: 0, z: .2),
          ),
          meshCount: cliff.inspection.meshCount,
          triangleCount: cliff.inspection.triangleCount,
        ),
      ),
    ],
    borderCatalog: ProjectBorderCatalog(formatVersion: 5, records: [
      ...project.borderCatalog.records,
      decodeBorderBlueprintRecordJson(raw, formatVersion: 5),
    ]),
  );
}

ProjectManifest _leftHanded(ProjectManifest project) => project.copyWith(
      models3d: [
        for (final model in project.models3d)
          model.id == 'cliff'
              ? ProjectModel3dEntry(
                  id: model.id,
                  name: model.name,
                  sourceAssetId: model.sourceAssetId,
                  relativePath: model.relativePath,
                  inspection: Model3dInspection(
                    bounds: Model3dBounds(
                      min: Model3dVector3(x: -.5, y: -1, z: 0),
                      max: Model3dVector3(x: .5, y: 0, z: 1),
                    ),
                    meshCount: model.inspection.meshCount,
                    triangleCount: model.inspection.triangleCount,
                  ),
                )
              : model
      ],
    );

Map<String, Object?> _surface(String id, double height, List<int> r) => {
      'id': id,
      'x': 0,
      'z': 0,
      'height': height,
      'footprints': [
        [
          {'x': r[0], 'z': r[1]},
          {'x': r[0] + r[2], 'z': r[1]},
          {'x': r[0] + r[2], 'z': r[1] + r[3]},
          {'x': r[0], 'z': r[1] + r[3]},
        ]
      ],
    };

Map<String, Object?> _trace(String featureId, double lower, double upper,
        {String blueprintId = 'fence', bool exact = true}) =>
    {
      'actionId': 'intent.border.trace_step',
      'actionVersion': 1,
      'parameters': {
        'layerId': 'border',
        'featureId': featureId,
        'blueprintId': blueprintId,
        'lowerHeight': lower,
        'upperHeight': upper,
        'cells': [
          {'x': 7, 'y': 7}
        ],
        'exactHeights': exact,
      },
    };

MapData _apply(ProjectManifest project, List<Map<String, Object?>> surfaces,
    List<Map<String, Object?>> traces) {
  final draft = const Map3dEditBatchActions().build(context(
      librarySnapshot([_fixture.map], project: project), 'map3d.edit_batch', {
    'mapId': 'map',
    'operations': [
      {
        'actionId': 'map3d.terrain.surface.upsert_batch',
        'actionVersion': 1,
        'parameters': {
          'surfaces': [
            _surface('base', 1, [0, 0, 24, 16]),
            ...surfaces
          ]
        },
      },
      ...traces,
    ],
  }));
  return MapData.fromJson(Map<String, dynamic>.from(
      jsonDecode(utf8.decode(draft.changeSet.changes.single.afterBytes!))
          as Map));
}

BorderFeature _feature(MapData map, String id) =>
    map.layers.whereType<BorderLayer>().single.content.featureById(id)!;

List<BorderStroke> _strokes(MapData map, String id) =>
    (_feature(map, id).geometry as BorderStrokeGeometry).strokes;

List<String> _diagnostics(ProjectManifest project, MapData map, String id) => [
      for (final diagnostic in diagnoseSpatialBorderFeature(
              manifest: project, map: map, layerId: 'border', featureId: id)
          .diagnostics)
        diagnostic.code
    ];

void main() {
  final plateau = _surface('plateau', 2, [6, 4, 10, 8]);
  final terrace = _surface('terrace', 3, [6, 6, 3, 3]);

  test('painted cells trace only their own plateau', () {
    final map = _apply(_fixture.project, [
      plateau,
      _surface('island', 2, [18, 2, 3, 3]),
    ], [
      _trace('relief', 1, 2, exact: false)
    ]);
    final stroke = _strokes(map, 'relief').single;
    expect(stroke.closed, isTrue);
    expect(stroke.points, hasLength(36));
    expect(stroke.points.every((point) => point.x <= 16), isTrue);
  });

  test('exact steps trace a terrace on the contour without a double wall', () {
    final project = _withTwoLevelProfile(_fixture.project);
    final map = _apply(project, [
      plateau,
      terrace
    ], [
      _trace('relief', 1, 2),
      _trace('terrace', 2, 3),
      _trace('cliff', 1, 3, blueprintId: 'fence-2'),
    ]);
    final shared = {
      for (var y = 6; y <= 9; y++) GridPos(x: 6, y: y),
    };
    final relief = _strokes(map, 'relief').single;
    final upper = _strokes(map, 'terrace').single;
    final cliff = _strokes(map, 'cliff').single;
    expect([relief.closed, upper.closed, cliff.closed], [false, false, false]);
    expect(cliff.points, [
      for (var y = 9; y >= 6; y--) GridPos(x: 6, y: y),
    ]);
    expect(relief.points.toSet().intersection(shared),
        {const GridPos(x: 6, y: 6), const GridPos(x: 6, y: 9)});
    expect(upper.points.toSet().intersection(shared),
        {const GridPos(x: 6, y: 6), const GridPos(x: 6, y: 9)});
    for (final id in ['relief', 'terrace', 'cliff']) {
      expect(_diagnostics(project, map, id), isEmpty, reason: id);
    }
  });

  test('a one-level profile on the two-level edge is refused by name', () {
    expect(
        () => _apply(_fixture.project, [
              plateau,
              terrace
            ], [
              _trace('relief', 1, 2),
              _trace('terrace', 2, 3),
              _trace('cliff', 1, 3),
            ]),
        throwsA(isA<MapAuthoringException>()
            .having((e) => e.code, 'code', 'intent.step_profile_incompatible')
            .having(
                (e) => {
                      for (final d
                          in (e.details['diagnostics'] as List).cast<Map>())
                        (d['featureId'], d['code'])
                    },
                'diagnostics',
                {('cliff', 'border.spatial.face_base_mismatch')})));
  });

  test('a profile with faces on the high side is refused before tracing', () {
    final project = _leftHanded(_fixture.project);
    final silent = _apply(project, [
      plateau
    ], [
      {
        'actionId': 'border_layer.feature_create',
        'actionVersion': 1,
        'parameters': {
          'layerId': 'border',
          'featureId': 'buried',
          'name': 'buried',
          'blueprintId': 'fence',
          'seed': 0,
          'geometry': {
            'kind': 'stroke',
            'alignment': 'gridEdges',
            'strokes': [
              {
                'id': 'step-0',
                'closed': false,
                'points': [
                  for (var x = 8; x <= 12; x++) {'x': x, 'y': 4}
                ],
              }
            ],
          },
        },
      }
    ]);
    expect(_feature(silent, 'buried').materialization, isNotNull);
    expect(_diagnostics(project, silent, 'buried'), isEmpty);
    expect(
        () => _apply(project, [plateau], [_trace('relief', 1, 2)]),
        throwsA(isA<MapAuthoringException>()
            .having((e) => e.code, 'code', 'map3d.edit_batch.operation_failed')
            .having((e) => (e.details['cause'] as Map)['code'], 'cause',
                'intent.step_profile_faces_high_side')
            .having(
                (e) => ((e.details['cause'] as Map)['details']
                    as Map)['primitiveCount'],
                'primitives',
                greaterThan(0))));
    expect(() => _apply(_fixture.project, [plateau], [_trace('relief', 1, 2)]),
        returnsNormally);
  });
}
