import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('BorderRegionGeometry', () {
    test('owns an ordered immutable row-major mask with value semantics', () {
      final input = <bool>[true, false, false, true];
      final region = BorderRegionGeometry(
        width: 2,
        height: 2,
        cells: input,
      );

      input
        ..clear()
        ..add(true);

      expect(region.width, 2);
      expect(region.height, 2);
      expect(region.cells, <bool>[true, false, false, true]);
      expect(() => region.cells.add(false), throwsUnsupportedError);
      expect(
        region,
        BorderRegionGeometry(
          width: 2,
          height: 2,
          cells: const <bool>[true, false, false, true],
        ),
      );
      expect(
        region.hashCode,
        BorderRegionGeometry(
          width: 2,
          height: 2,
          cells: const <bool>[true, false, false, true],
        ).hashCode,
      );
      expect(
        region,
        isNot(
          BorderRegionGeometry(
            width: 2,
            height: 2,
            cells: const <bool>[false, true, false, true],
          ),
        ),
      );

      final BorderFeatureGeometry geometry = region;
      expect(geometry, same(region));
    });

    test('accepts an all-false region as an empty draft', () {
      final region = BorderRegionGeometry(
        width: 3,
        height: 2,
        cells: List<bool>.filled(6, false),
      );

      expect(region.cells, everyElement(isFalse));
    });

    test('requires positive dimensions and exactly width times height cells',
        () {
      for (final createInvalid in <BorderRegionGeometry Function()>[
        () => BorderRegionGeometry(
              width: 0,
              height: 1,
              cells: const <bool>[],
            ),
        () => BorderRegionGeometry(
              width: 1,
              height: -1,
              cells: const <bool>[],
            ),
        () => BorderRegionGeometry(
              width: 2,
              height: 2,
              cells: const <bool>[false, false, false],
            ),
        () => BorderRegionGeometry(
              width: 2,
              height: 2,
              cells: const <bool>[false, false, false, false, false],
            ),
      ]) {
        expect(createInvalid, throwsA(isA<ValidationException>()));
      }
    });

    test('validates huge dimensions without multiplying them', () {
      expect(
        () => BorderRegionGeometry(
          width: 9223372036854775807,
          height: 9223372036854775807,
          cells: const <bool>[false],
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('BorderStroke', () {
    test('owns ordered points and preserves direction with value semantics',
        () {
      final input = <GridPos>[
        const GridPos(x: -2, y: 50),
        const GridPos(x: -1, y: 50),
        const GridPos(x: -1, y: 51),
      ];
      final stroke = BorderStroke(
        id: 'outer-west',
        points: input,
        closed: false,
      );

      input.clear();

      expect(stroke.id, 'outer-west');
      expect(stroke.closed, isFalse);
      expect(
        stroke.points,
        const <GridPos>[
          GridPos(x: -2, y: 50),
          GridPos(x: -1, y: 50),
          GridPos(x: -1, y: 51),
        ],
      );
      expect(
        () => stroke.points.add(const GridPos(x: -1, y: 52)),
        throwsUnsupportedError,
      );
      expect(
        stroke,
        BorderStroke(
          id: 'outer-west',
          points: const <GridPos>[
            GridPos(x: -2, y: 50),
            GridPos(x: -1, y: 50),
            GridPos(x: -1, y: 51),
          ],
          closed: false,
        ),
      );
      expect(
        stroke,
        isNot(
          BorderStroke(
            id: 'outer-west',
            points: const <GridPos>[
              GridPos(x: -1, y: 51),
              GridPos(x: -1, y: 50),
              GridPos(x: -2, y: 50),
            ],
            closed: false,
          ),
        ),
      );
    });

    test('requires a nonblank already-trimmed stable id', () {
      for (final id in <String>['', '   ', ' stroke', 'stroke ', '\tstroke']) {
        expect(
          () => BorderStroke(
            id: id,
            points: const <GridPos>[
              GridPos(x: 0, y: 0),
              GridPos(x: 1, y: 0),
            ],
            closed: false,
          ),
          throwsA(isA<ValidationException>()),
          reason: id,
        );
      }
    });

    test('requires at least two distinct points for an open stroke', () {
      for (final points in <List<GridPos>>[
        const <GridPos>[],
        const <GridPos>[GridPos(x: 0, y: 0)],
        const <GridPos>[
          GridPos(x: 0, y: 0),
          GridPos(x: 0, y: 0),
        ],
      ]) {
        expect(
          () => BorderStroke(id: 'open', points: points, closed: false),
          throwsA(isA<ValidationException>()),
        );
      }
    });

    test('closed strokes use four distinct points and an implicit edge', () {
      final closed = BorderStroke(
        id: 'island',
        points: const <GridPos>[
          GridPos(x: 0, y: 0),
          GridPos(x: 1, y: 0),
          GridPos(x: 1, y: 1),
          GridPos(x: 0, y: 1),
        ],
        closed: true,
      );

      expect(closed.points, hasLength(4));
      expect(closed.points.first, isNot(closed.points.last));

      expect(
        () => BorderStroke(
          id: 'too-short',
          points: const <GridPos>[
            GridPos(x: 0, y: 0),
            GridPos(x: 1, y: 0),
            GridPos(x: 0, y: 1),
          ],
          closed: true,
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => BorderStroke(
          id: 'duplicated-closure',
          points: const <GridPos>[
            GridPos(x: 0, y: 0),
            GridPos(x: 1, y: 0),
            GridPos(x: 1, y: 1),
            GridPos(x: 0, y: 1),
            GridPos(x: 0, y: 0),
          ],
          closed: true,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('requires unit-cardinal consecutive and closing edges', () {
      for (final createInvalid in <BorderStroke Function()>[
        () => BorderStroke(
              id: 'long-segment',
              points: const <GridPos>[
                GridPos(x: 0, y: 0),
                GridPos(x: 2, y: 0),
              ],
              closed: false,
            ),
        () => BorderStroke(
              id: 'diagonal',
              points: const <GridPos>[
                GridPos(x: 0, y: 0),
                GridPos(x: 1, y: 1),
              ],
              closed: false,
            ),
        () => BorderStroke(
              id: 'invalid-closing-edge',
              points: const <GridPos>[
                GridPos(x: 0, y: 0),
                GridPos(x: 1, y: 0),
                GridPos(x: 2, y: 0),
                GridPos(x: 2, y: 1),
              ],
              closed: true,
            ),
      ]) {
        expect(createInvalid, throwsA(isA<ValidationException>()));
      }
    });

    test('does not treat signed-int64 extrema as adjacent after overflow', () {
      const minInt64 = -9223372036854775808;
      const maxInt64 = 9223372036854775807;
      const extremePairs = <List<GridPos>>[
        <GridPos>[
          GridPos(x: minInt64, y: 0),
          GridPos(x: maxInt64, y: 0),
        ],
        <GridPos>[
          GridPos(x: maxInt64, y: 0),
          GridPos(x: minInt64, y: 0),
        ],
        <GridPos>[
          GridPos(x: 0, y: minInt64),
          GridPos(x: 0, y: maxInt64),
        ],
        <GridPos>[
          GridPos(x: 0, y: maxInt64),
          GridPos(x: 0, y: minInt64),
        ],
      ];

      for (final points in extremePairs) {
        expect(
          () => BorderStroke(
            id: 'not-adjacent',
            points: points,
            closed: false,
          ),
          throwsA(isA<ValidationException>()),
          reason: points.toString(),
        );
      }
    });

    test('deeply owns externally implemented mutable points', () {
      final first = _MutableGridPos(x: 0, y: 0);
      final second = _MutableGridPos(x: 1, y: 0);
      final stroke = BorderStroke(
        id: 'mutable-source',
        points: <GridPos>[first, second],
        closed: false,
      );
      final expected = BorderStroke(
        id: 'mutable-source',
        points: const <GridPos>[
          GridPos(x: 0, y: 0),
          GridPos(x: 1, y: 0),
        ],
        closed: false,
      );
      final hashBeforeMutation = stroke.hashCode;

      first
        ..x = 100
        ..y = 100;
      second
        ..x = -100
        ..y = -100;

      expect(
        stroke.points,
        const <GridPos>[
          GridPos(x: 0, y: 0),
          GridPos(x: 1, y: 0),
        ],
      );
      expect(stroke, expected);
      expect(stroke.hashCode, hashBeforeMutation);
      expect(
        () => BorderStroke(
          id: 'topology-copy',
          points: stroke.points,
          closed: false,
        ),
        returnsNormally,
      );
    });

    test('allows adjacent hairpins but rejects repeated cells and backtracking',
        () {
      final hairpin = BorderStroke(
        id: 'hairpin',
        points: const <GridPos>[
          GridPos(x: 0, y: 0),
          GridPos(x: 1, y: 0),
          GridPos(x: 2, y: 0),
          GridPos(x: 2, y: 1),
          GridPos(x: 1, y: 1),
        ],
        closed: false,
      );

      expect(hairpin.points, hasLength(5));

      for (final points in <List<GridPos>>[
        const <GridPos>[
          GridPos(x: 0, y: 0),
          GridPos(x: 1, y: 0),
          GridPos(x: 0, y: 0),
        ],
        const <GridPos>[
          GridPos(x: 0, y: 0),
          GridPos(x: 1, y: 0),
          GridPos(x: 1, y: 1),
          GridPos(x: 0, y: 1),
          GridPos(x: 0, y: 0),
        ],
      ]) {
        expect(
          () => BorderStroke(id: 'invalid', points: points, closed: false),
          throwsA(isA<ValidationException>()),
        );
      }
    });

    test('keeps negative and future map-out-of-bounds coordinates', () {
      final stroke = BorderStroke(
        id: 'diagnosed-later',
        points: const <GridPos>[
          GridPos(x: -100, y: 5000),
          GridPos(x: -99, y: 5000),
        ],
        closed: false,
      );

      expect(stroke.points.first, const GridPos(x: -100, y: 5000));
    });
  });

  group('BorderStrokeGeometry', () {
    test('alignment participates in equality and hashing', () {
      final stroke = _openStroke('edge');
      final cellCenters = BorderStrokeGeometry(
        strokes: <BorderStroke>[stroke],
      );
      final equalCellCenters = BorderStrokeGeometry(
        strokes: <BorderStroke>[_openStroke('edge')],
      );
      final gridEdges = BorderStrokeGeometry(
        strokes: <BorderStroke>[_openStroke('edge')],
        alignment: BorderStrokeAlignment.gridEdges,
      );

      expect(cellCenters, equalCellCenters);
      expect(cellCenters.hashCode, equalCellCenters.hashCode);
      expect(gridEdges, isNot(cellCenters));
      expect(gridEdges.hashCode, isNot(cellCenters.hashCode));
      expect(<BorderStrokeGeometry>{cellCenters, equalCellCenters, gridEdges},
          hasLength(2));
    });

    test('owns ordered strokes without canonicalizing their order', () {
      final input = <BorderStroke>[
        _openStroke('west', x: -3, y: 0),
        _openStroke('east', x: 5, y: 0),
      ];
      final geometry = BorderStrokeGeometry(strokes: input);

      input.clear();

      expect(geometry.strokes.map((stroke) => stroke.id), <String>[
        'west',
        'east',
      ]);
      expect(() => geometry.strokes.clear(), throwsUnsupportedError);
      expect(
        geometry,
        BorderStrokeGeometry(
          strokes: <BorderStroke>[
            _openStroke('west', x: -3, y: 0),
            _openStroke('east', x: 5, y: 0),
          ],
        ),
      );
      expect(
        geometry,
        isNot(
          BorderStrokeGeometry(
            strokes: <BorderStroke>[
              _openStroke('east', x: 5, y: 0),
              _openStroke('west', x: -3, y: 0),
            ],
          ),
        ),
      );

      final BorderFeatureGeometry featureGeometry = geometry;
      expect(featureGeometry, same(geometry));
    });

    test('accepts an empty strokes list as a line draft with openings', () {
      final geometry = BorderStrokeGeometry(strokes: const <BorderStroke>[]);

      expect(geometry.strokes, isEmpty);
      expect(
        () => geometry.strokes.add(_openStroke('new')),
        throwsUnsupportedError,
      );
    });

    test('rejects duplicate stroke ids', () {
      expect(
        () => BorderStrokeGeometry(
          strokes: <BorderStroke>[
            _openStroke('same', x: 0, y: 0),
            _openStroke('same', x: 10, y: 0),
          ],
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects strokes that share a cell or edge', () {
      expect(
        () => BorderStrokeGeometry(
          strokes: <BorderStroke>[
            _openStroke('first', x: 0, y: 0),
            BorderStroke(
              id: 'shared-cell',
              points: const <GridPos>[
                GridPos(x: 1, y: 0),
                GridPos(x: 1, y: 1),
              ],
              closed: false,
            ),
          ],
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => BorderStrokeGeometry(
          strokes: <BorderStroke>[
            _openStroke('forward', x: 0, y: 0),
            BorderStroke(
              id: 'reverse-edge',
              points: const <GridPos>[
                GridPos(x: 1, y: 0),
                GridPos(x: 0, y: 0),
              ],
              closed: false,
            ),
          ],
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('BorderKeepOutRegion', () {
    test('has a stable id and region value semantics', () {
      final keepOut = BorderKeepOutRegion(
        id: 'opening-a',
        region: _singleCellRegion(true),
      );
      final equal = BorderKeepOutRegion(
        id: 'opening-a',
        region: _singleCellRegion(true),
      );

      expect(keepOut, equal);
      expect(keepOut.hashCode, equal.hashCode);
      expect(
        keepOut,
        isNot(
          BorderKeepOutRegion(
            id: 'opening-a',
            region: _singleCellRegion(false),
          ),
        ),
      );
    });

    test('requires a nonblank already-trimmed stable id', () {
      for (final id in <String>['', ' ', ' keep-out', 'keep-out ']) {
        expect(
          () => BorderKeepOutRegion(
            id: id,
            region: _singleCellRegion(false),
          ),
          throwsA(isA<ValidationException>()),
        );
      }
    });
  });
}

BorderStroke _openStroke(String id, {int x = 0, int y = 0}) {
  return BorderStroke(
    id: id,
    points: <GridPos>[
      GridPos(x: x, y: y),
      GridPos(x: x + 1, y: y),
    ],
    closed: false,
  );
}

BorderRegionGeometry _singleCellRegion(bool value) {
  return BorderRegionGeometry(
    width: 1,
    height: 1,
    cells: <bool>[value],
  );
}

final class _MutableGridPos implements GridPos {
  _MutableGridPos({required this.x, required this.y});

  @override
  int x;

  @override
  int y;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GridPos && x == other.x && y == other.y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
