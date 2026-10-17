import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  for (final spatial in [false, true]) {
    for (final actionId in [
      'smart_tile.pattern.paint',
      'smart_tile.pattern.paint_batch'
    ]) {
      test(
          'patterns paint a newly published material through $actionId in ${spatial ? '3D' : '2D'}',
          () {
        final pattern = _rockPattern.copyWith(cells: [
          _rockPattern.cells.single.copyWith(eraseMaterial: false),
        ]);
        final fixture = _fixture(
            spatial: spatial,
            includePattern: true,
            pattern: pattern,
            extendedPublishedPreset: true);
        final paint = {
          'patternId': pattern.id,
          'strokeId': 'relief',
          'materialId': 'relief',
          'selection': {
            'kind': 'stamp',
            'anchor': {'x': 0, 'y': 0}
          },
        };
        final draft =
            _buildPattern(fixture.snapshot, actionId: actionId, parameters: {
          'mapId': 'map',
          'layerId': 'ground',
          if (actionId.endsWith('paint_batch'))
            'strokes': [paint]
          else
            ...paint,
        });
        final map = _map(draft);
        final layer = map.layers.single as SmartTileLayer;
        expect(layer.materialPalette, ['', 'grass', 'relief']);
        expect(smartTileSemanticCells(layer), [2, 0, 0, 0]);
        expect(map.spatialScene, fixture.map.spatialScene);
        expect(draft.changeSet.changes, hasLength(1));
        expect(MapData.fromJson(map.toJson()), map);
      });
    }
  }

  test('a catalog material outside the published preset remains forbidden', () {
    final fixture = _fixture(extendedPublishedPreset: true);
    final before = jsonEncode(fixture.map.toJson());
    expect(
        () => _build(fixture.snapshot,
                actionId: 'smart_tile.cell.paint_batch',
                parameters: {
                  'mapId': 'map',
                  'layerId': 'ground',
                  'strokes': [
                    {
                      'materialId': 'relief',
                      'cells': [
                        {'x': 0, 'y': 0}
                      ]
                    },
                    {
                      'materialId': 'forbidden',
                      'cells': [
                        {'x': 1, 'y': 0}
                      ]
                    },
                  ],
                }),
        _failure('smart_tile.cell.material_not_allowed'));
    expect(jsonEncode(fixture.map.toJson()), before);
  });

  for (final spatial in [false, true]) {
    for (final actionId in [
      'smart_tile.cell.paint',
      'smart_tile.cell.paint_batch',
      'smart_tile.corner.paint',
    ]) {
      test(
          'paints a newly published material through $actionId in ${spatial ? '3D' : '2D'}',
          () {
        final corner = actionId == 'smart_tile.corner.paint';
        final fixture = _fixture(
          spatial: spatial,
          extendedPublishedPreset: true,
          field: corner
              ? const SmartTileField.corner(
                  semanticCells: [0, 0, 0, 0],
                  corners: [0, 0, 0, 0, 0, 0, 0, 0, 0],
                )
              : null,
        );
        final before = fixture.map.layers.single as SmartTileLayer;
        expect(before.materialPalette, ['', 'grass']);
        final draft = _build(fixture.snapshot, actionId: actionId, parameters: {
          'mapId': 'map',
          'layerId': 'ground',
          if (actionId == 'smart_tile.cell.paint_batch')
            'strokes': [
              {
                'materialId': 'relief',
                'cells': [
                  {'x': 0, 'y': 0}
                ]
              },
            ]
          else ...{
            'materialId': 'relief',
            if (corner)
              'corners': [
                {'x': 0, 'y': 0}
              ]
            else
              'cells': [
                {'x': 0, 'y': 0}
              ],
          },
        });
        final map = _map(draft);
        final layer = map.layers.single as SmartTileLayer;
        expect(layer.materialPalette, ['', 'grass', 'relief']);
        if (corner) {
          expect((layer.field as SmartTileCornerField).corners.first, 2);
        } else {
          expect(smartTileSemanticCells(layer), [2, 0, 0, 0]);
        }
        expect(fixture.map.layers.single, before);
        expect(map.spatialScene, fixture.map.spatialScene);
        expect(draft.changeSet.changes, hasLength(1));
        expect(MapData.fromJson(map.toJson()), map);
      });
    }
  }

  test('pattern material painting and erasing share one atomic map mutation',
      () {
    final pattern = _rockPattern.copyWith(
        cells: [_rockPattern.cells.single.copyWith(eraseMaterial: false)]);
    final fixture = _fixture(
        includePattern: true,
        spatial: true,
        pattern: pattern,
        field: const SmartTileField.cell(semanticCells: [0, 0, 0, 0]));
    for (final actionId in [
      'smart_tile.pattern.paint',
      'smart_tile.pattern.paint_batch'
    ]) {
      final paint = <String, Object?>{
        'patternId': pattern.id,
        'strokeId': 'grass',
        'materialId': 'grass',
        'selection': {
          'kind': 'stamp',
          'anchor': {'x': 1, 'y': 1}
        },
      };
      final draft =
          _buildPattern(fixture.snapshot, actionId: actionId, parameters: {
        'mapId': 'map',
        'layerId': 'ground',
        if (actionId.endsWith('paint_batch')) 'strokes': [paint] else ...paint
      });
      final map = _map(draft);
      expect(smartTileSemanticCells(map.layers.single as SmartTileLayer),
          [0, 0, 0, 1]);
      expect(draft.changeSet.changes, hasLength(1));
      expect(map.spatialScene, fixture.map.spatialScene);
    }
    for (final materialId in ['water', '']) {
      expect(
          () => _buildPattern(fixture.snapshot,
                  actionId: 'smart_tile.pattern.paint',
                  parameters: {
                    'mapId': 'map',
                    'layerId': 'ground',
                    'patternId': pattern.id,
                    'strokeId': 'invalid',
                    'materialId': materialId,
                    'selection': {
                      'kind': 'stamp',
                      'anchor': {'x': 0, 'y': 0}
                    }
                  }),
          throwsA(isA<MapAuthoringException>()));
    }
    final eraseFixture = _fixture(
        includePattern: true,
        spatial: true,
        pattern: pattern,
        field: const SmartTileField.cell(semanticCells: [1, 0, 0, 0]),
        patternStrokes: [
          SmartTilePatternStroke(
              id: 'grass',
              patternId: pattern.id,
              cells: const [GridPos(x: 0, y: 0)])
        ]);
    final erased = _buildPattern(eraseFixture.snapshot,
        actionId: 'smart_tile.pattern.erase',
        parameters: {
          'mapId': 'map',
          'layerId': 'ground',
          'clearMaterial': true,
          'cells': [
            {'x': 0, 'y': 0}
          ]
        });
    final erasedLayer = _map(erased).layers.single as SmartTileLayer;
    expect(smartTileSemanticCells(erasedLayer), [0, 0, 0, 0]);
    expect(erasedLayer.patternStrokes, isEmpty);
    expect(erased.preview['clearMaterial'], true);
    expect(erased.changeSet.changes, hasLength(1));
  });

  group('pattern paint batch', () {
    Map<String, Object?> stroke(String id, int x, int y) => {
          'patternId': 'rock-stamp',
          'strokeId': id,
          'selection': {
            'kind': 'stamp',
            'anchor': {'x': x, 'y': y},
          },
        };

    test('paints ordered patterns and collisions in one map change', () {
      final fixture = _fixture(
        spatial: true,
        elevated: true,
        includePattern: true,
        includeCollision: true,
        field: const SmartTileField.cell(semanticCells: [1, 1, 1, 1]),
      );
      final draft = _buildPattern(
        fixture.snapshot,
        actionId: 'smart_tile.pattern.paint_batch',
        parameters: {
          'mapId': 'map',
          'layerId': 'ground',
          'collisionLayerId': 'collision',
          'strokes': [stroke('a', 0, 0), stroke('b', 1, 1)],
        },
      );
      final map = _map(draft);
      final layer = map.layers.whereType<SmartTileLayer>().single;
      expect(layer.patternStrokes.map((value) => value.id), ['a', 'b']);
      expect(smartTileSemanticCells(layer), [0, 1, 1, 0]);
      expect(map.layers.whereType<CollisionLayer>().single.collisions,
          [true, false, false, true]);
      expect(map.spatialScene, fixture.map.spatialScene);
      expect(draft.changeSet.changes, hasLength(1));
      expect(draft.preview['strokeCount'], 2);
      expect(draft.preview['gestureCellCount'], 2);
      expect(draft.preview['undoBoundary'], 'batch');
      expect(draft.preview['batchAtomicity'], 'all_or_nothing');
      expect(MapData.fromJson(map.toJson()), map);
    });

    test('preserves overlap order and signed phases', () {
      final fixture = _fixture(includePattern: true);
      final draft = _buildPattern(
        fixture.snapshot,
        actionId: 'smart_tile.pattern.paint_batch',
        parameters: {
          'mapId': 'map',
          'layerId': 'ground',
          'strokes': [
            {...stroke('lower', 0, 0), 'phaseX': -2, 'phaseY': 3},
            {...stroke('upper', 0, 0), 'phaseX': 4, 'phaseY': -5},
          ],
        },
      );
      final strokes =
          (_map(draft).layers.single as SmartTileLayer).patternStrokes;
      expect(strokes.map((value) => value.id), ['lower', 'upper']);
      expect(strokes.first.phaseX, -2);
      expect(strokes.first.phaseY, 3);
      expect(strokes.last.phaseX, 4);
      expect(strokes.last.phaseY, -5);
    });

    test('rejects a later invalid pattern without changing the snapshot', () {
      final fixture = _fixture(includePattern: true);
      final before = jsonEncode(fixture.map.toJson());
      expect(
        () => _buildPattern(
          fixture.snapshot,
          actionId: 'smart_tile.pattern.paint_batch',
          parameters: {
            'mapId': 'map',
            'layerId': 'ground',
            'strokes': [
              stroke('a', 0, 0),
              {...stroke('b', 1, 1), 'patternId': 'unknown'},
            ],
          },
        ),
        _failure('smart_tile.pattern.unknown'),
      );
      expect(jsonEncode(fixture.map.toJson()), before);
    });

    test('rejects empty, duplicate, malformed and oversized batches', () {
      final fixture = _fixture(includePattern: true);
      for (final strokes in <List<Object?>>[
        [],
        [stroke('same', 0, 0), stroke('same', 1, 1)],
        [
          stroke('a', 0, 0),
          {...stroke('b', 1, 1), 'unrecognized': true}
        ],
        [stroke('a', 0, 0), stroke('b', 2, 1)],
        [stroke('a', 0, 0), 3],
        List.generate(251, (index) => stroke('stroke-$index', 0, 0)),
      ]) {
        expect(
          () => _buildPattern(
            fixture.snapshot,
            actionId: 'smart_tile.pattern.paint_batch',
            parameters: {
              'mapId': 'map',
              'layerId': 'ground',
              'strokes': strokes,
            },
          ),
          throwsA(isA<MapAuthoringException>()),
        );
      }
    });

    test('advertises bounded ordered painting and a batch undo boundary', () {
      final descriptor = SmartTilePatternActions.descriptors.singleWhere(
        (value) => value.id == 'smart_tile.pattern.paint_batch',
      );
      expect(descriptor.extensions['maximumStrokeCount'], 250);
      expect(descriptor.extensions['maximumTotalCellCount'], 65536);
      expect(descriptor.extensions['overlapPolicy'], 'ordered_strokes');
      expect(descriptor.extensions['undoBoundary'], 'batch');
      expect(descriptor.extensions['inputSchema'], isA<Map>());
    });

    test('enforces the total cell limit including overlapping strokes', () {
      final fixture = _fixture(
        includePattern: true,
        mapSize: const GridSize(width: 256, height: 256),
        pattern: ProjectSmartTilePattern.fromJson({
          ..._rockPattern.toJson(),
          'repeatMode': 'tiled',
          'cells': [
            {
              ..._rockPattern.cells.single.toJson(),
              'eraseMaterial': false,
              'collision': 'inherit',
            },
          ],
        }),
      );
      expect(
        () => _buildPattern(
          fixture.snapshot,
          actionId: 'smart_tile.pattern.paint_batch',
          parameters: {
            'mapId': 'map',
            'layerId': 'ground',
            'strokes': [
              {
                'patternId': 'rock-stamp',
                'strokeId': 'full',
                'selection': {
                  'kind': 'rectangle',
                  'start': {'x': 0, 'y': 0},
                  'end': {'x': 255, 'y': 255},
                },
              },
              stroke('overflow', 0, 0),
            ],
          },
        ),
        _failure('smart_tile.pattern.batch_too_large'),
      );
    });
  });

  test(
      'pattern erase targets explicit strokes without deleting lower ownership',
      () {
    const lower = SmartTilePatternStroke(
      id: 'lower',
      patternId: 'rock-stamp',
      phaseX: 0,
      phaseY: 0,
      cells: [GridPos(x: 0, y: 0)],
    );
    final fixture = _fixture(
      spatial: true,
      elevated: true,
      includePattern: true,
      field: const SmartTileField.cell(semanticCells: [1, 1, 0, 0]),
      patternStrokes: const [
        lower,
        SmartTilePatternStroke(
          id: 'upper',
          patternId: 'rock-stamp',
          phaseX: 0,
          phaseY: 0,
          cells: [GridPos(x: 0, y: 0)],
        ),
      ],
    );
    final draft = _buildPattern(
      fixture.snapshot,
      actionId: 'smart_tile.pattern.erase',
      parameters: {
        'mapId': 'map',
        'layerId': 'ground',
        'strokeIds': ['upper'],
        'cells': [
          {'x': 0, 'y': 0},
        ],
      },
    );
    final map = _map(draft);
    final layer = map.layers.single as SmartTileLayer;
    expect(layer.patternStrokes, [lower]);
    expect(layer.field, (fixture.map.layers.single as SmartTileLayer).field);
    expect(map.spatialScene, fixture.map.spatialScene);
    expect(draft.preview['erasedOwnershipCount'], 1);
    expect(draft.preview['targetStrokeIds'], ['upper']);
    final descriptor = SmartTilePatternActions.descriptors
        .singleWhere((value) => value.id == 'smart_tile.pattern.erase');
    expect(descriptor.extensions['optionalEraseStrokeIds'], isTrue);
  });

  test('pattern erase rejects invalid stroke filters before mutation', () {
    final fixture = _fixture(
      spatial: true,
      includePattern: true,
      patternStrokes: const [
        SmartTilePatternStroke(
          id: 'upper',
          patternId: 'rock-stamp',
          phaseX: 0,
          phaseY: 0,
          cells: [GridPos(x: 0, y: 0)],
        ),
      ],
    );
    for (final ids in <List<Object?>>[
      [],
      ['upper', 'upper'],
      ['unknown'],
      ['upper', 'unknown'],
      [' upper'],
      [1],
    ]) {
      expect(
        () => _buildPattern(
          fixture.snapshot,
          actionId: 'smart_tile.pattern.erase',
          parameters: {
            'mapId': 'map',
            'layerId': 'ground',
            'strokeIds': ids,
            'cells': [
              {'x': 0, 'y': 0},
            ],
          },
        ),
        throwsA(isA<MapAuthoringException>()),
      );
      expect(
          (fixture.map.layers.single as SmartTileLayer)
              .patternStrokes
              .single
              .id,
          'upper');
    }
  });

  test('native 3D pattern erase preserves the material and elevated terrain',
      () {
    final fixture = _fixture(
      spatial: true,
      elevated: true,
      includePattern: true,
      field: const SmartTileField.cell(semanticCells: [1, 1, 0, 0]),
      patternStrokes: const [
        SmartTilePatternStroke(
          id: 'source-pattern',
          patternId: 'rock-stamp',
          phaseX: 3,
          phaseY: 4,
          cells: [GridPos(x: 0, y: 0), GridPos(x: 1, y: 0)],
        ),
      ],
    );
    final draft = _buildPattern(
      fixture.snapshot,
      actionId: 'smart_tile.pattern.erase',
      parameters: {
        'mapId': 'map',
        'layerId': 'ground',
        'cells': [
          {'x': 0, 'y': 0}
        ],
      },
    );
    final map = _map(draft);
    final layer = map.layers.single as SmartTileLayer;
    expect(layer.field, (fixture.map.layers.single as SmartTileLayer).field);
    expect(layer.patternStrokes.single.cells, [const GridPos(x: 1, y: 0)]);
    expect(layer.patternStrokes.single.phaseX, 3);
    expect(layer.patternStrokes.single.phaseY, 4);
    expect(map.spatialScene, fixture.map.spatialScene);
    expect(MapData.fromJson(map.toJson()), map);
  });
  group('SmartTileCellActions', () {
    for (final actionId in [
      'smart_tile.cell.paint',
      'smart_tile.cell.erase',
      'smart_tile.cell.paint_batch',
    ]) {
      test('$actionId removes only targeted native 3D pattern cells', () {
        final fixture = _fixture(
          spatial: true,
          includePattern: true,
          field: const SmartTileField.cell(semanticCells: [1, 1, 0, 0]),
          patternStrokes: const [
            SmartTilePatternStroke(
              id: 'source-pattern',
              patternId: 'rock-stamp',
              phaseX: 3,
              phaseY: 4,
              cells: [GridPos(x: 0, y: 0), GridPos(x: 1, y: 0)],
            ),
          ],
        );
        final cells = [
          {'x': 0, 'y': 0}
        ];
        final draft = _build(fixture.snapshot, actionId: actionId, parameters: {
          'mapId': 'map',
          'layerId': 'ground',
          if (actionId == 'smart_tile.cell.paint_batch')
            'strokes': [
              {'materialId': 'grass', 'cells': cells}
            ]
          else ...{
            if (actionId == 'smart_tile.cell.paint') 'materialId': 'grass',
            'cells': cells,
          },
        });
        final layer = _map(draft).layers.single as SmartTileLayer;
        expect(layer.patternStrokes.single.cells, [GridPos(x: 1, y: 0)]);
        expect(layer.patternStrokes.single.phaseX, 3);
        expect(layer.patternStrokes.single.phaseY, 4);
        expect(smartTileSemanticCells(layer),
            [actionId == 'smart_tile.cell.erase' ? 0 : 1, 1, 0, 0]);
        expect(draft.preview['changedCellCount'], 1);
        expect(fixture.map.layers.single, isNot(layer));
        expect(MapData.fromJson(_map(draft).toJson()), _map(draft));
      });
    }
    test('3D repaint clears higher soil through one canonical mutation', () {
      final fixture = _fixture(
          spatial: true,
          field: const SmartTileField.cell(semanticCells: [1, 0, 0, 0]),
          properties: const {
            'tileLayerOrder': 'bottom_to_top'
          },
          additionalLayers: [
            SmartTileLayer(
                id: 'higher-soil',
                name: 'Higher soil',
                presetId: 'grass-preset',
                usage: SmartTileUsage.terrain,
                materialPalette: const ['', 'grass'],
                field: const SmartTileField.cell(semanticCells: [1, 0, 0, 0]))
          ]);
      final draft = _build(fixture.snapshot,
          actionId: 'smart_tile.cell.paint',
          parameters: const {
            'mapId': 'map',
            'layerId': 'ground',
            'materialId': 'grass',
            'cells': [
              {'x': 0, 'y': 0}
            ]
          });
      final map = _map(draft);
      expect(smartTileSemanticCells(map.layers[0] as SmartTileLayer),
          [1, 0, 0, 0]);
      expect(smartTileSemanticCells(map.layers[1] as SmartTileLayer),
          [0, 0, 0, 0]);
      expect(draft.changeSet.changes, hasLength(1));
      expect(draft.preview['changedCellCount'], 1);
      expect(draft.changeSet.diff.entries.single.path, '/layers');
    });
    test(
        'paints and erases flat 3D surfaces with the existing gesture contract',
        () {
      final fixture = _fixture(spatial: true);
      final painted = _map(_build(fixture.snapshot,
          actionId: 'smart_tile.cell.paint',
          parameters: const {
            'mapId': 'map',
            'layerId': 'ground',
            'materialId': 'grass',
            'cells': [
              {'x': 1, 'y': 1}
            ],
          }));
      expect(painted.version, ProjectVersion.v9);
      expect(painted.spatialScene, fixture.map.spatialScene);
      expect(smartTileSemanticCells(painted.layers.single as SmartTileLayer),
          [0, 0, 0, 1]);
      final erased = _map(_build(
          _fixture(
                  spatial: true,
                  field: const SmartTileField.cell(semanticCells: [0, 0, 0, 1]))
              .snapshot,
          actionId: 'smart_tile.cell.erase',
          parameters: const {
            'mapId': 'map',
            'layerId': 'ground',
            'cells': [
              {'x': 1, 'y': 1}
            ],
          }));
      expect(smartTileSemanticCells(erased.layers.single as SmartTileLayer),
          [0, 0, 0, 0]);
    });
    test('paints elevated 3D terrain and preserves its supporting scene', () {
      final fixture = _fixture(spatial: true, elevated: true);
      final painted = _map(_build(fixture.snapshot,
          actionId: 'smart_tile.cell.paint',
          parameters: const {
            'mapId': 'map',
            'layerId': 'ground',
            'materialId': 'grass',
            'cells': [
              {'x': 1, 'y': 1}
            ],
          }));
      expect(painted.spatialScene, fixture.map.spatialScene);
      expect(smartTileSemanticCells(painted.layers.single as SmartTileLayer),
          [0, 0, 0, 1]);
    });
    test('registers atomic paint and erase contracts', () {
      expect(
        SmartTileCellActions.descriptors.map((descriptor) => descriptor.id),
        <String>[
          'smart_tile.cell.paint',
          'smart_tile.cell.paint_batch',
          'smart_tile.cell.erase',
          'smart_tile.corner.paint',
          'smart_tile.corner.erase',
        ],
      );
      for (final descriptor in SmartTileCellActions.descriptors.where(
          (descriptor) =>
              descriptor.id == 'smart_tile.cell.paint' ||
              descriptor.id == 'smart_tile.cell.erase')) {
        expect(descriptor.guarantees, contains(AuthoringGuarantee.atomic));
        expect(descriptor.guarantees, contains(AuthoringGuarantee.undoable));
        expect(descriptor.extensions['gestureAtomic'], isTrue);
        expect(descriptor.extensions['cellFieldOnly'], isFalse);
        expect(
          descriptor.extensions['supportedSelections'],
          <String>['cells', 'line', 'rectangle', 'floodFill'],
        );
        expect(
          descriptor.extensions['supportedFieldKinds'],
          <String>['cell', 'edge', 'corner', 'mixed'],
        );
        expect(descriptor.extensions['maximumExplicitCellCount'], 4096);
        expect(descriptor.extensions['geometricSelectionLimit'], 'mapExtent');
      }
    });

    test('paints one precise corner without widening its footprint', () {
      final fixture = _fixture(
        field: const SmartTileField.corner(
          semanticCells: <int>[1, 0, 0, 0],
          corners: <int>[0, 0, 0, 0, 0, 0, 0, 0, 0],
        ),
      );
      final draft = _build(
        fixture.snapshot,
        actionId: 'smart_tile.corner.paint',
        parameters: const <String, Object?>{
          'mapId': 'map',
          'layerId': 'ground',
          'materialId': 'grass',
          'corners': <Map<String, int>>[
            {'x': 1, 'y': 1}
          ],
        },
      );
      final layer = _map(draft).layers.single as SmartTileLayer;
      expect(smartTileCorners(layer), <int>[0, 0, 0, 0, 1, 0, 0, 0, 0]);
      expect(smartTileSemanticCells(layer), <int>[1, 0, 0, 0]);
      expect(draft.preview['changedCornerCount'], 1);
      expect(draft.preview['undoBoundary'], 'gesture');
    });

    test('accepts a corner on the outer map boundary', () {
      final fixture = _fixture(
        field: const SmartTileField.corner(
          semanticCells: <int>[0, 0, 0, 0],
          corners: <int>[0, 0, 0, 0, 0, 0, 0, 0, 0],
        ),
      );
      final draft = _build(
        fixture.snapshot,
        actionId: 'smart_tile.corner.paint',
        parameters: const <String, Object?>{
          'mapId': 'map',
          'layerId': 'ground',
          'materialId': 'grass',
          'corners': <Map<String, int>>[
            {'x': 2, 'y': 2}
          ],
        },
      );
      final layer = _map(draft).layers.single as SmartTileLayer;
      expect(smartTileCorners(layer), <int>[0, 0, 0, 0, 0, 0, 0, 0, 1]);
    });

    test('erases a precise corner while preserving mixed field edges', () {
      final fixture = _fixture(
        field: const SmartTileField.mixed(
          semanticCells: <int>[1, 1, 1, 1],
          horizontalEdges: <int>[1, 1, 1, 1, 1, 1],
          verticalEdges: <int>[1, 1, 1, 1, 1, 1],
          corners: <int>[1, 1, 1, 1, 1, 1, 1, 1, 1],
        ),
      );
      final draft = _build(
        fixture.snapshot,
        actionId: 'smart_tile.corner.erase',
        parameters: const <String, Object?>{
          'mapId': 'map',
          'layerId': 'ground',
          'corners': <Map<String, int>>[
            {'x': 1, 'y': 1}
          ],
        },
      );
      final layer = _map(draft).layers.single as SmartTileLayer;
      expect(smartTileCorners(layer), <int>[1, 1, 1, 1, 0, 1, 1, 1, 1]);
      expect(smartTileHorizontalEdges(layer), <int>[1, 1, 1, 1, 1, 1]);
      expect(smartTileVerticalEdges(layer), <int>[1, 1, 1, 1, 1, 1]);
      expect(smartTileSemanticCells(layer), <int>[1, 1, 1, 1]);
    });

    test('rejects precise corners on a cell-only field', () {
      expect(
        () => _build(
          _fixture().snapshot,
          actionId: 'smart_tile.corner.erase',
          parameters: const <String, Object?>{
            'mapId': 'map',
            'layerId': 'ground',
            'corners': <Map<String, int>>[
              {'x': 0, 'y': 0}
            ],
          },
        ),
        _failure('smart_tile.corner.field_invalid'),
      );
    });

    test('rejects invalid corner gestures before changing the map', () {
      final snapshot = _fixture(
        field: const SmartTileField.corner(
          semanticCells: <int>[0, 0, 0, 0],
          corners: <int>[0, 0, 0, 0, 0, 0, 0, 0, 0],
        ),
      ).snapshot;
      for (final invalid in <({List<Map<String, int>> corners, String code})>[
        (
          corners: <Map<String, int>>[
            {'x': -1, 'y': 0}
          ],
          code: 'smart_tile.corner.out_of_bounds'
        ),
        (
          corners: <Map<String, int>>[
            {'x': 3, 'y': 2}
          ],
          code: 'smart_tile.corner.out_of_bounds'
        ),
        (
          corners: <Map<String, int>>[
            {'x': 1, 'y': 1},
            {'x': 1, 'y': 1}
          ],
          code: 'smart_tile.corner.duplicate'
        ),
        (
          corners: List.filled(4097, <String, int>{'x': 0, 'y': 0}),
          code: 'smart_tile.corner.gesture_too_large'
        ),
      ]) {
        expect(
          () => _build(snapshot,
              actionId: 'smart_tile.corner.erase',
              parameters: <String, Object?>{
                'mapId': 'map',
                'layerId': 'ground',
                'corners': invalid.corners,
              }),
          _failure(invalid.code),
        );
      }
    });

    test('pattern action stamps visuals and collision in one undo boundary',
        () {
      final fixture = _fixture(
        field: const SmartTileField.cell(
          semanticCells: <int>[1, 0, 0, 0],
        ),
        includePattern: true,
        includeCollision: true,
      );
      final draft = _buildPattern(
        fixture.snapshot,
        actionId: 'smart_tile.pattern.paint',
        parameters: const <String, Object?>{
          'mapId': 'map',
          'layerId': 'ground',
          'patternId': 'rock-stamp',
          'strokeId': 'stroke-1',
          'collisionLayerId': 'collision',
          'selection': <String, Object?>{
            'kind': 'stamp',
            'anchor': <String, int>{'x': 0, 'y': 0},
          },
        },
      );
      final projected = _map(draft);
      final layer = projected.layers.whereType<SmartTileLayer>().single;
      final collision = projected.layers.whereType<CollisionLayer>().single;

      expect(layer.patternStrokes.single.patternId, 'rock-stamp');
      expect(smartTileSemanticCells(layer).first, 0);
      expect(collision.collisions.first, isTrue);
      expect(draft.preview['collisionApplied'], isTrue);
      expect(draft.preview['undoBoundary'], 'gesture');
    });

    test('paints one whole gesture independent of coordinate order', () {
      final fixture = _fixture();
      final forward = _build(
        fixture.snapshot,
        actionId: 'smart_tile.cell.paint',
        parameters: const <String, Object?>{
          'mapId': 'map',
          'layerId': 'ground',
          'materialId': 'grass',
          'cells': <Map<String, int>>[
            <String, int>{'x': 1, 'y': 1},
            <String, int>{'x': 0, 'y': 0},
          ],
        },
      );
      final reverse = _build(
        fixture.snapshot,
        actionId: 'smart_tile.cell.paint',
        parameters: const <String, Object?>{
          'mapId': 'map',
          'layerId': 'ground',
          'materialId': 'grass',
          'cells': <Map<String, int>>[
            <String, int>{'x': 0, 'y': 0},
            <String, int>{'x': 1, 'y': 1},
          ],
        },
      );

      expect(_mapBytes(forward), _mapBytes(reverse));
      expect(forward.preview['changedCellCount'], 2);
      expect(forward.preview['gestureCellCount'], 2);
      expect(forward.preview['undoBoundary'], 'gesture');
      expect(
        forward.preview['cells'],
        const <Map<String, int>>[
          <String, int>{'x': 0, 'y': 0},
          <String, int>{'x': 1, 'y': 1},
        ],
      );
      final layer = _map(forward).layers.single as SmartTileLayer;
      expect(smartTileSemanticCells(layer), <int>[1, 0, 0, 1]);
    });

    test('validates only the declared Smart Tile cell delta', () {
      final fixture = _fixture(includeInvalidUnrelatedLayer: true);
      final draft = _build(
        fixture.snapshot,
        actionId: 'smart_tile.cell.paint',
        parameters: const <String, Object?>{
          'mapId': 'map',
          'layerId': 'ground',
          'materialId': 'grass',
          'cells': <Map<String, int>>[
            <String, int>{'x': 1, 'y': 1},
          ],
        },
      );

      final layer = _map(draft).layers.first as SmartTileLayer;
      expect(smartTileSemanticCells(layer), <int>[0, 0, 0, 1]);
    });

    test('erases a gesture through the same canonical boundary', () {
      final fixture = _fixture(
        field: const SmartTileField.cell(
          semanticCells: <int>[1, 1, 1, 1],
        ),
      );
      final draft = _build(
        fixture.snapshot,
        actionId: 'smart_tile.cell.erase',
        parameters: const <String, Object?>{
          'mapId': 'map',
          'layerId': 'ground',
          'cells': <Map<String, int>>[
            <String, int>{'x': 0, 'y': 1},
            <String, int>{'x': 1, 'y': 1},
          ],
        },
      );

      final layer = _map(draft).layers.single as SmartTileLayer;
      expect(smartTileSemanticCells(layer), <int>[1, 1, 0, 0]);
      expect(draft.preview['materialId'], isNull);
      expect(draft.preview['changedCellCount'], 2);
    });

    test('compiles line and rectangle selections inside the atomic action', () {
      final snapshot = _fixture().snapshot;
      final line = _build(
        snapshot,
        actionId: 'smart_tile.cell.paint',
        parameters: const <String, Object?>{
          'mapId': 'map',
          'layerId': 'ground',
          'materialId': 'grass',
          'selection': <String, Object?>{
            'kind': 'line',
            'start': <String, int>{'x': 0, 'y': 0},
            'end': <String, int>{'x': 1, 'y': 1},
          },
        },
      );
      expect(
        smartTileSemanticCells(_map(line).layers.single as SmartTileLayer),
        <int>[1, 0, 0, 1],
      );
      expect(line.preview['gestureSelection'], 'line');

      final rectangle = _build(
        snapshot,
        actionId: 'smart_tile.cell.paint',
        parameters: const <String, Object?>{
          'mapId': 'map',
          'layerId': 'ground',
          'materialId': 'grass',
          'selection': <String, Object?>{
            'kind': 'rectangle',
            'start': <String, int>{'x': 1, 'y': 1},
            'end': <String, int>{'x': 0, 'y': 0},
          },
        },
      );
      expect(
        smartTileSemanticCells(
          _map(rectangle).layers.single as SmartTileLayer,
        ),
        <int>[1, 1, 1, 1],
      );
      expect(rectangle.preview['gestureCellCount'], 4);
    });

    test(
        'geometric selection may cover a map beyond the explicit payload limit',
        () {
      const mapSize = GridSize(width: 65, height: 64);
      final draft = _build(
        _fixture(mapSize: mapSize).snapshot,
        actionId: 'smart_tile.cell.paint',
        parameters: const <String, Object?>{
          'mapId': 'map',
          'layerId': 'ground',
          'materialId': 'grass',
          'selection': <String, Object?>{
            'kind': 'rectangle',
            'start': <String, int>{'x': 0, 'y': 0},
            'end': <String, int>{'x': 64, 'y': 63},
          },
        },
      );

      final layer = _map(draft).layers.single as SmartTileLayer;
      expect(draft.preview['gestureCellCount'], 4160);
      expect(smartTileSemanticCells(layer), hasLength(4160));
      expect(smartTileSemanticCells(layer).every((cell) => cell == 1), isTrue);
    });

    test('explicit cell payloads remain bounded to 4096 coordinates', () {
      const mapSize = GridSize(width: 65, height: 64);
      final cells = <Map<String, int>>[
        for (var index = 0; index < 4097; index++)
          <String, int>{
            'x': index % mapSize.width,
            'y': index ~/ mapSize.width,
          },
      ];

      expect(
        () => _build(
          _fixture(mapSize: mapSize).snapshot,
          actionId: 'smart_tile.cell.paint',
          parameters: <String, Object?>{
            'mapId': 'map',
            'layerId': 'ground',
            'materialId': 'grass',
            'cells': cells,
          },
        ),
        _failure('smart_tile.cell.gesture_too_large'),
      );
    });

    test('flood fill follows the source semantic region', () {
      final draft = _build(
        _fixture(
          field: const SmartTileField.cell(
            semanticCells: <int>[1, 1, 0, 1],
          ),
        ).snapshot,
        actionId: 'smart_tile.cell.erase',
        parameters: const <String, Object?>{
          'mapId': 'map',
          'layerId': 'ground',
          'selection': <String, Object?>{
            'kind': 'floodFill',
            'seed': <String, int>{'x': 0, 'y': 0},
          },
        },
      );

      final layer = _map(draft).layers.single as SmartTileLayer;
      expect(smartTileSemanticCells(layer), <int>[0, 0, 0, 0]);
      expect(draft.preview['gestureSelection'], 'floodFill');
      expect(draft.preview['gestureCellCount'], 3);
    });

    test('requires exactly one cells or geometric selection input', () {
      final snapshot = _fixture().snapshot;
      for (final parameters in <Map<String, Object?>>[
        const <String, Object?>{
          'mapId': 'map',
          'layerId': 'ground',
          'materialId': 'grass',
        },
        const <String, Object?>{
          'mapId': 'map',
          'layerId': 'ground',
          'materialId': 'grass',
          'cells': <Map<String, int>>[
            <String, int>{'x': 0, 'y': 0},
          ],
          'selection': <String, Object?>{
            'kind': 'floodFill',
            'seed': <String, int>{'x': 0, 'y': 0},
          },
        },
      ]) {
        expect(
          () => _build(
            snapshot,
            actionId: 'smart_tile.cell.paint',
            parameters: parameters,
          ),
          _failure('smart_tile.cell.selection_invalid'),
        );
      }
    });

    test('rejects duplicates, out-of-bounds cells, and unavailable materials',
        () {
      final snapshot = _fixture().snapshot;

      expect(
        () => _build(
          snapshot,
          actionId: 'smart_tile.cell.paint',
          parameters: const <String, Object?>{
            'mapId': 'map',
            'layerId': 'ground',
            'materialId': 'grass',
            'cells': <Map<String, int>>[
              <String, int>{'x': 0, 'y': 0},
              <String, int>{'x': 0, 'y': 0},
            ],
          },
        ),
        _failure('smart_tile.cell.duplicate'),
      );
      expect(
        () => _build(
          snapshot,
          actionId: 'smart_tile.cell.erase',
          parameters: const <String, Object?>{
            'mapId': 'map',
            'layerId': 'ground',
            'cells': <Map<String, int>>[
              <String, int>{'x': 2, 'y': 0},
            ],
          },
        ),
        _failure('smart_tile.cell.out_of_bounds'),
      );
      expect(
        () => _build(
          snapshot,
          actionId: 'smart_tile.cell.paint',
          parameters: const <String, Object?>{
            'mapId': 'map',
            'layerId': 'ground',
            'materialId': 'water',
            'cells': <Map<String, int>>[
              <String, int>{'x': 0, 'y': 0},
            ],
          },
        ),
        _failure('smart_tile.cell.material_not_allowed'),
      );
    });

    test('projects paint across edge, corner and mixed Wang fields', () {
      final cases =
          <({SmartTileField field, List<int> edges, List<int> corners})>[
        (
          field: const SmartTileField.edge(
            semanticCells: <int>[0, 0, 0, 0],
            horizontalEdges: <int>[0, 0, 0, 0, 0, 0],
            verticalEdges: <int>[0, 0, 0, 0, 0, 0],
          ),
          edges: <int>[1, 0, 1, 0, 0, 0, 1, 1, 0, 0, 0, 0],
          corners: <int>[],
        ),
        (
          field: const SmartTileField.corner(
            semanticCells: <int>[0, 0, 0, 0],
            corners: <int>[0, 0, 0, 0, 0, 0, 0, 0, 0],
          ),
          edges: <int>[],
          corners: <int>[1, 1, 0, 1, 1, 0, 0, 0, 0],
        ),
        (
          field: const SmartTileField.mixed(
            semanticCells: <int>[0, 0, 0, 0],
            horizontalEdges: <int>[0, 0, 0, 0, 0, 0],
            verticalEdges: <int>[0, 0, 0, 0, 0, 0],
            corners: <int>[0, 0, 0, 0, 0, 0, 0, 0, 0],
          ),
          edges: <int>[1, 0, 1, 0, 0, 0, 1, 1, 0, 0, 0, 0],
          corners: <int>[1, 1, 0, 1, 1, 0, 0, 0, 0],
        ),
      ];

      for (final paintCase in cases) {
        final draft = _build(
          _fixture(field: paintCase.field).snapshot,
          actionId: 'smart_tile.cell.paint',
          parameters: const <String, Object?>{
            'mapId': 'map',
            'layerId': 'ground',
            'materialId': 'grass',
            'cells': <Map<String, int>>[
              <String, int>{'x': 0, 'y': 0},
            ],
          },
        );
        final layer = _map(draft).layers.single as SmartTileLayer;

        expect(
          smartTileSemanticCells(layer),
          <int>[1, 0, 0, 0],
          reason: paintCase.field.runtimeType.toString(),
        );
        expect(
          <int>[
            ...smartTileHorizontalEdges(layer),
            ...smartTileVerticalEdges(layer),
          ],
          paintCase.edges,
          reason: paintCase.field.runtimeType.toString(),
        );
        expect(
          smartTileCorners(layer),
          paintCase.corners,
          reason: paintCase.field.runtimeType.toString(),
        );
        expect(draft.preview['changedCellCount'], 1);
        expect(draft.preview['fieldKind'], isNotEmpty);
      }
    });

    test('erases a mixed Wang gesture through the same undo boundary', () {
      final draft = _build(
        _fixture(
          field: const SmartTileField.mixed(
            semanticCells: <int>[0, 0, 0, 0],
            horizontalEdges: <int>[1, 1, 1, 1, 1, 1],
            verticalEdges: <int>[1, 1, 1, 1, 1, 1],
            corners: <int>[1, 1, 1, 1, 1, 1, 1, 1, 1],
          ),
        ).snapshot,
        actionId: 'smart_tile.cell.erase',
        parameters: const <String, Object?>{
          'mapId': 'map',
          'layerId': 'ground',
          'cells': <Map<String, int>>[
            <String, int>{'x': 0, 'y': 0},
          ],
        },
      );
      final layer = _map(draft).layers.single as SmartTileLayer;

      expect(smartTileHorizontalEdges(layer), <int>[0, 1, 0, 1, 1, 1]);
      expect(smartTileVerticalEdges(layer), <int>[0, 0, 1, 1, 1, 1]);
      expect(smartTileCorners(layer), <int>[0, 0, 1, 0, 0, 1, 1, 1, 1]);
      expect(draft.preview['undoBoundary'], 'gesture');
    });
  });
}

Matcher _failure(String code) => throwsA(
      isA<MapAuthoringException>().having(
        (failure) => failure.code,
        'code',
        code,
      ),
    );

AuthoringMutationDraft _build(
  ProjectSnapshot snapshot, {
  required String actionId,
  required Map<String, Object?> parameters,
}) =>
    const SmartTileCellActions().build(
      AuthoringPlanningContext(
        snapshot: snapshot,
        request: AuthoringRequest(
          requestId: 'request',
          actionId: actionId,
          actionVersion: 1,
          workspaceHandle: 'workspace:cells',
          parameters: parameters,
          expectedRevision: snapshot.revision,
          idempotencyKey: 'idempotency-$actionId',
        ),
        planId: 'plan-cells',
        seed: 17,
      ),
    );

({ProjectSnapshot snapshot, ProjectManifest manifest, MapData map}) _fixture({
  SmartTileField? field,
  GridSize mapSize = const GridSize(width: 2, height: 2),
  bool includePattern = false,
  bool extendedPublishedPreset = false,
  ProjectSmartTilePattern? pattern,
  bool includeCollision = false,
  bool includeInvalidUnrelatedLayer = false,
  bool spatial = false,
  bool elevated = false,
  List<SmartTileLayer> additionalLayers = const [],
  List<SmartTilePatternStroke> patternStrokes = const [],
  Map<String, dynamic> properties = const {},
}) {
  final resolvedField = field ??
      SmartTileField.cell(
        semanticCells: List<int>.filled(mapSize.width * mapSize.height, 0),
      );
  final map = MapData(
    id: 'map',
    name: 'Map',
    version: spatial ? ProjectVersion.v9 : ProjectVersion.v8,
    spatialScene: spatial
        ? MapSpatialScene(
            width: mapSize.width,
            depth: mapSize.height,
            heightLevels: elevated
                ? List.filled(mapSize.width * mapSize.height, 1)
                : null)
        : null,
    size: mapSize,
    properties: properties,
    layers: <MapLayer>[
      MapLayer.smartTile(
        id: 'ground',
        name: 'Ground',
        presetId: 'grass-preset',
        usage: SmartTileUsage.terrain,
        materialPalette: const <String>['', 'grass'],
        field: resolvedField,
        patternStrokes: patternStrokes,
      ),
      ...additionalLayers,
      if (includeCollision)
        MapLayer.collision(
          id: 'collision',
          name: 'Collision',
          collisions: List<bool>.filled(
            mapSize.width * mapSize.height,
            false,
          ),
        ),
      if (includeInvalidUnrelatedLayer)
        const MapLayer.collision(
          id: 'unrelated-invalid',
          name: 'Unrelated invalid collision',
          collisions: <bool>[],
        ),
    ],
  );
  final (topology, templateHint) = switch (resolvedField) {
    SmartTileCellField() => (
        SmartTileTopology.uniform,
        SmartTileTemplateHint.simple,
      ),
    SmartTileEdgeField() => (
        SmartTileTopology.wangEdge4,
        SmartTileTemplateHint.edge16,
      ),
    SmartTileCornerField() => (
        SmartTileTopology.wangCorner4,
        SmartTileTemplateHint.corner16,
      ),
    SmartTileMixedField() => (
        SmartTileTopology.wang8,
        SmartTileTemplateHint.mixed256,
      ),
  };
  final manifest = ProjectManifest(
    name: 'Cell actions fixture',
    version: spatial ? ProjectVersion.v9 : ProjectVersion.v8,
    settings: spatial
        ? ProjectSettings(
            dimension: ProjectDimension.threeD,
            spatialCamera: SpatialCameraProfile())
        : const ProjectSettings(),
    maps: const <ProjectMapEntry>[
      ProjectMapEntry(
        id: 'map',
        name: 'Map',
        relativePath: 'maps/map.json',
      ),
    ],
    tilesets: const <ProjectTilesetEntry>[
      ProjectTilesetEntry(
        id: 'tileset',
        name: 'Tileset',
        relativePath: 'assets/tileset.png',
      ),
    ],
    smartTileCatalog: ProjectSmartTileCatalog(
      atlases: <ProjectSmartTileAtlas>[
        ProjectSmartTileAtlas(
          id: 'atlas',
          name: 'Atlas',
          tilesetId: 'tileset',
          columns: 1,
          rows: 1,
        ),
      ],
      materials: <ProjectSmartTileMaterial>[
        if (extendedPublishedPreset)
          ProjectSmartTileMaterial(
              id: 'forbidden', name: 'Forbidden', connectionGroupId: 'ground'),
        if (extendedPublishedPreset)
          ProjectSmartTileMaterial(
              id: 'relief', name: 'Relief', connectionGroupId: 'ground'),
        ProjectSmartTileMaterial(
          id: 'grass',
          name: 'Grass',
          connectionGroupId: 'ground',
        ),
      ],
      presets: <ProjectSmartTilePreset>[
        ProjectSmartTilePreset(
          id: 'grass-preset',
          name: 'Grass',
          usage: SmartTileUsage.terrain,
          topology: topology,
          templateHint: templateHint,
          status: SmartTilePresetStatus.published,
          coveragePolicy: SmartTileCoveragePolicy.sparse,
          coverageProfile: SmartTileCoverageProfile(
            mode: SmartTileCoverageMode.template,
          ),
          transformPolicy: SmartTileTransformPolicy(),
          defaultMaterialId: 'grass',
          allowedMaterialIds: <String>[
            'grass',
            if (extendedPublishedPreset) 'relief'
          ],
          rules: <SmartTileRule>[
            if (extendedPublishedPreset)
              SmartTileRule(
                id: 'relief',
                centerMatch: SmartTileSlotMatch.material('relief'),
                candidates: [
                  SmartTileCandidate(id: 'relief', parts: [
                    SmartTileVisualPart(
                        source: SmartTileVisualSource.frame(
                      frame: SmartTileFrameRef(
                          atlasId: 'atlas', column: 0, row: 0),
                    )),
                  ]),
                ],
              ),
            SmartTileRule(
              id: 'base',
              centerMatch: SmartTileSlotMatch.material('grass'),
              signature: SmartTileSignature(),
              candidates: <SmartTileCandidate>[
                SmartTileCandidate(
                  id: 'base',
                  parts: <SmartTileVisualPart>[
                    SmartTileVisualPart(
                      source: SmartTileVisualSource.frame(
                        frame: SmartTileFrameRef(
                          atlasId: 'atlas',
                          column: 0,
                          row: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
      patterns: <ProjectSmartTilePattern>[
        if (includePattern) pattern ?? _rockPattern,
      ],
    ),
  );
  final projectBytes = _encode(manifest.toJson());
  final mapBytes = _encode(map.toJson());
  return (
    manifest: manifest,
    map: map,
    snapshot: ProjectSnapshot(
      projectHandle: const ProjectHandle('project_cells'),
      revision: computeAuthoringBytesFingerprint(
        utf8.encode('cell-snapshot-${map.toJson()}'),
        logicalName: 'snapshot',
      ),
      manifest: manifest,
      maps: <MapData>[map],
      resourceFingerprints: <String, String>{
        'project': computeAuthoringBytesFingerprint(
          projectBytes,
          logicalName: 'project.json',
        ),
        'map:map': computeAuthoringBytesFingerprint(
          mapBytes,
          logicalName: 'maps/map.json',
        ),
      },
      resourceBytes: <String, List<int>>{
        'project': projectBytes,
        'map:map': mapBytes,
      },
      resourceStorageKeys: const <String, String>{
        'project': 'project.json',
        'map:map': 'maps/map.json',
      },
    ),
  );
}

AuthoringMutationDraft _buildPattern(
  ProjectSnapshot snapshot, {
  required String actionId,
  required Map<String, Object?> parameters,
}) =>
    const SmartTilePatternActions().build(
      AuthoringPlanningContext(
        snapshot: snapshot,
        request: AuthoringRequest(
          requestId: 'request-pattern',
          actionId: actionId,
          actionVersion: 1,
          workspaceHandle: 'workspace:patterns',
          parameters: parameters,
          expectedRevision: snapshot.revision,
          idempotencyKey: 'idempotency-$actionId',
        ),
        planId: 'plan-patterns',
        seed: 19,
      ),
    );

const _rockPattern = ProjectSmartTilePattern(
  id: 'rock-stamp',
  name: 'Rock stamp',
  usage: SmartTileUsage.terrain,
  width: 1,
  height: 1,
  repeatMode: SmartTilePatternRepeatMode.stamp,
  cells: <SmartTilePatternCell>[
    SmartTilePatternCell(
      x: 0,
      y: 0,
      eraseMaterial: true,
      collision: SmartTilePatternCollision.blocked,
      parts: <SmartTileVisualPart>[
        SmartTileVisualPart(
          source: SmartTileVisualSource.frame(
            frame: SmartTileFrameRef(
              atlasId: 'atlas',
              column: 0,
              row: 0,
            ),
          ),
        ),
      ],
    ),
  ],
);

MapData _map(AuthoringMutationDraft draft) => MapData.fromJson(
      jsonDecode(utf8.decode(_mapBytes(draft))) as Map<String, dynamic>,
    );

List<int> _mapBytes(AuthoringMutationDraft draft) => draft.changeSet.changes
    .singleWhere((change) => change.resource.kind == 'map')
    .afterBytes!;

List<int> _encode(Object? value) =>
    utf8.encode(const JsonEncoder.withIndent('  ').convert(value));
