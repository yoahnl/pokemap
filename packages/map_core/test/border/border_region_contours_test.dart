import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../fixtures/border/border_region_contour_golden.dart';

void main() {
  group('extractCanonicalBorderRegionContours', () {
    test('extracts one clockwise land loop for a single cell', () {
      final contours = extractCanonicalBorderRegionContours(
        region: _region(['#']),
        tileSizePx: const GridSize(width: 16, height: 24),
      );

      expect(contours, hasLength(1));
      final contour = contours.single;
      expect(contour.kind, BorderRegionContourKind.landBoundary);
      expect(contour.originWorldPx, const BorderPixelPos(x: 0, y: 0));
      expect(contour.perimeterPx, 80);
      expect(
        contour.edges.map((edge) => edge.direction),
        [
          BorderCardinalDirection.east,
          BorderCardinalDirection.south,
          BorderCardinalDirection.west,
          BorderCardinalDirection.north,
        ],
      );
      expect(
        contour.edges.map((edge) => edge.outwardSide),
        [
          BorderCardinalDirection.north,
          BorderCardinalDirection.east,
          BorderCardinalDirection.south,
          BorderCardinalDirection.west,
        ],
      );
      expect(
        contour.edges.map((edge) => edge.turnToNext),
        List.filled(4, BorderContourTurn.right),
      );
      expect(
        contour.edges.map((edge) => (edge.startAbscissaPx, edge.endAbscissaPx)),
        [(0, 16), (16, 40), (40, 56), (56, 80)],
      );
      expect(
        contour.edges.map((edge) => edge.interiorCell),
        List.filled(4, const GridPos(x: 0, y: 0)),
      );
    });

    test('keeps exactly one tile contribution per rectangular edge', () {
      final contour = extractCanonicalBorderRegionContours(
        region: _region(['##']),
        tileSizePx: const GridSize(width: 7, height: 11),
      ).single;

      expect(
        contour.edges.map((edge) => edge.lengthPx),
        [7, 7, 11, 7, 7, 11],
      );
      expect(contour.perimeterPx, 50);
      expect(
        contour.edges.last.endWorldPx,
        contour.edges.first.startWorldPx,
      );
      for (var index = 0; index < contour.edges.length; index += 1) {
        final edge = contour.edges[index];
        final next = contour.edges[(index + 1) % contour.edges.length];
        expect(edge.endVertex, next.startVertex);
        expect(edge.endWorldPx, next.startWorldPx);
        if (index + 1 < contour.edges.length) {
          expect(edge.endAbscissaPx, next.startAbscissaPx);
        } else {
          expect(edge.endAbscissaPx, contour.perimeterPx);
          expect(next.startAbscissaPx, 0);
        }
      }
    });

    test('extracts concave boundaries without reusing an edge', () {
      final contour = extractCanonicalBorderRegionContours(
        region: _region(['##', '#.']),
        tileSizePx: const GridSize(width: 1, height: 1),
      ).single;

      expect(contour.kind, BorderRegionContourKind.landBoundary);
      expect(contour.edges, hasLength(8));
      expect(contour.perimeterPx, 8);
      expect(
        contour.edges.map(_edgeIdentity).toSet(),
        hasLength(contour.edges.length),
      );
      expect(
        contour.edges.where(
          (edge) => edge.turnToNext == BorderContourTurn.left,
        ),
        hasLength(1),
      );
    });

    test('classifies and orders an outer boundary and one hole', () {
      final contours = extractCanonicalBorderRegionContours(
        region: _region(['###', '#.#', '###']),
        tileSizePx: const GridSize(width: 2, height: 3),
      );

      expect(
        contours.map((contour) => contour.kind),
        [
          BorderRegionContourKind.landBoundary,
          BorderRegionContourKind.holeBoundary,
        ],
      );
      expect(
        contours.map((contour) => contour.originWorldPx),
        [
          const BorderPixelPos(x: 0, y: 0),
          const BorderPixelPos(x: 2, y: 3),
        ],
      );
      expect(contours[0].perimeterPx, 30);
      expect(contours[1].perimeterPx, 10);
    });

    test('supports nested hole and island contours canonically', () {
      final contours = extractCanonicalBorderRegionContours(
        region: _region([
          '#####',
          '#...#',
          '#.#.#',
          '#...#',
          '#####',
        ]),
        tileSizePx: const GridSize(width: 1, height: 1),
      );

      expect(
        contours.map((contour) => contour.kind),
        [
          BorderRegionContourKind.landBoundary,
          BorderRegionContourKind.holeBoundary,
          BorderRegionContourKind.landBoundary,
        ],
      );
      expect(
        contours.map((contour) => contour.originWorldPx),
        [
          const BorderPixelPos(x: 0, y: 0),
          const BorderPixelPos(x: 1, y: 1),
          const BorderPixelPos(x: 2, y: 2),
        ],
      );
    });

    test('orders disconnected islands by minimal starting edge', () {
      final contours = extractCanonicalBorderRegionContours(
        region: _region(['#..', '...', '..#']),
        tileSizePx: const GridSize(width: 5, height: 5),
      );

      expect(contours, hasLength(2));
      expect(
        contours.map((contour) => contour.originWorldPx),
        [
          const BorderPixelPos(x: 0, y: 0),
          const BorderPixelPos(x: 10, y: 10),
        ],
      );
      expect(
        contours.map((contour) => contour.kind),
        everyElement(BorderRegionContourKind.landBoundary),
      );
    });

    test('translation changes positions but not the canonical turn signature',
        () {
      final base = extractCanonicalBorderRegionContours(
        region: _region(['##', '#.']),
        tileSizePx: const GridSize(width: 4, height: 6),
      ).single;
      final translated = extractCanonicalBorderRegionContours(
        region: _region(['....', '..##', '..#.']),
        tileSizePx: const GridSize(width: 4, height: 6),
      ).single;

      expect(
        translated.originWorldPx,
        const BorderPixelPos(x: 8, y: 6),
      );
      expect(
        translated.edges.map((edge) => edge.direction),
        base.edges.map((edge) => edge.direction),
      );
      expect(
        translated.edges.map((edge) => edge.turnToNext),
        base.edges.map((edge) => edge.turnToNext),
      );
      expect(translated.perimeterPx, base.perimeterPx);
    });

    test('right-turn priority keeps diagonal land components separate', () {
      final contours = extractCanonicalBorderRegionContours(
        region: _region(['#.', '.#']),
        tileSizePx: const GridSize(width: 1, height: 1),
      );

      expect(contours, hasLength(2));
      expect(contours.every((contour) => contour.edges.length == 4), isTrue);
      expect(
        contours.map((contour) => contour.originWorldPx),
        [
          const BorderPixelPos(x: 0, y: 0),
          const BorderPixelPos(x: 1, y: 1),
        ],
      );
    });

    test('right-turn priority makes diagonal holes one self-touching loop', () {
      final contours = extractCanonicalBorderRegionContours(
        region: _region([
          '####',
          '#.##',
          '##.#',
          '####',
        ]),
        tileSizePx: const GridSize(width: 1, height: 1),
      );

      expect(contours, hasLength(2));
      final hole = contours.singleWhere(
        (contour) => contour.kind == BorderRegionContourKind.holeBoundary,
      );
      expect(hole.edges, hasLength(8));
      expect(
        hole.edges.map((edge) => edge.startVertex).where(
              (vertex) => vertex == const GridPos(x: 2, y: 2),
            ),
        hasLength(2),
      );
      expect(hole.edges.map(_edgeIdentity).toSet(), hasLength(8));
    });

    test('empty regions produce no contour', () {
      expect(
        extractCanonicalBorderRegionContours(
          region: _region(['...', '...']),
          tileSizePx: const GridSize(width: 16, height: 16),
        ),
        isEmpty,
      );
    });

    test('rejects non-positive tile dimensions', () {
      final region = _region(['#']);

      expect(
        () => extractCanonicalBorderRegionContours(
          region: region,
          tileSizePx: const GridSize(width: 0, height: 1),
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => extractCanonicalBorderRegionContours(
          region: region,
          tileSizePx: const GridSize(width: 1, height: -1),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects non-portable tile sizes and derived perimeters', () {
      final region = _region(['#']);

      for (final tileSize in <GridSize>[
        GridSize(width: int.parse('9007199254740992'), height: 1),
        GridSize(width: int.parse('9007199254740991'), height: 2),
      ]) {
        expect(
          () => extractCanonicalBorderRegionContours(
            region: region,
            tileSizePx: tileSize,
          ),
          throwsA(isA<ValidationException>()),
        );
      }
    });

    test('rejects derived world positions outside the portable range', () {
      final translatedSingleCell = _region(['...#']);
      final width = int.parse('3002399751580331');

      expect(
        () => extractCanonicalBorderRegionContours(
          region: translatedSingleCell,
          tileSizePx: GridSize(width: width, height: 1),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('public contour values reject non-canonical metadata', () {
      final valid = extractCanonicalBorderRegionContours(
        region: _region(['#']),
        tileSizePx: const GridSize(width: 3, height: 4),
      ).single;
      final first = valid.edges.first;

      expect(
        () => _copyEdge(
          first,
          direction: BorderCardinalDirection.south,
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => _copyEdge(
          first,
          outwardSide: BorderCardinalDirection.west,
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => _copyEdge(
          first,
          interiorCell: const GridPos(x: 1, y: 0),
        ),
        throwsA(isA<ValidationException>()),
      );

      final wrongTurn = <BorderRegionContourEdge>[
        _copyEdge(first, turnToNext: BorderContourTurn.straight),
        ...valid.edges.skip(1),
      ];
      expect(
        () => BorderRegionContour(
          kind: BorderRegionContourKind.landBoundary,
          edges: wrongTurn,
          perimeterPx: valid.perimeterPx,
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => BorderRegionContour(
          kind: BorderRegionContourKind.holeBoundary,
          edges: valid.edges,
          perimeterPx: valid.perimeterPx,
        ),
        throwsA(isA<ValidationException>()),
      );

      final rotated = [...valid.edges.skip(1), valid.edges.first];
      var abscissa = 0;
      final rebased = <BorderRegionContourEdge>[
        for (final edge in rotated)
          _copyEdge(
            edge,
            startAbscissaPx: abscissa,
            endAbscissaPx: abscissa += edge.lengthPx,
          ),
      ];
      expect(
        () => BorderRegionContour(
          kind: BorderRegionContourKind.landBoundary,
          edges: rebased,
          perimeterPx: valid.perimeterPx,
        ),
        throwsA(
          isA<ValidationException>().having(
            (error) => error.message,
            'message',
            contains('minimal canonical edge'),
          ),
        ),
      );
    });

    test('public contours reject the same segment in opposite directions', () {
      final vertices = <GridPos>[
        const GridPos(x: 0, y: 0),
        const GridPos(x: 1, y: 0),
        const GridPos(x: 1, y: 1),
        const GridPos(x: 2, y: 1),
        const GridPos(x: 1, y: 1),
        const GridPos(x: 0, y: 1),
        const GridPos(x: 0, y: 0),
      ];
      final directions = <BorderCardinalDirection>[
        BorderCardinalDirection.east,
        BorderCardinalDirection.south,
        BorderCardinalDirection.east,
        BorderCardinalDirection.west,
        BorderCardinalDirection.west,
        BorderCardinalDirection.north,
      ];
      final turns = <BorderContourTurn>[
        BorderContourTurn.right,
        BorderContourTurn.left,
        BorderContourTurn.uTurn,
        BorderContourTurn.straight,
        BorderContourTurn.right,
        BorderContourTurn.right,
      ];
      final interiorCells = <GridPos>[
        const GridPos(x: 0, y: 0),
        const GridPos(x: 0, y: 0),
        const GridPos(x: 1, y: 1),
        const GridPos(x: 1, y: 0),
        const GridPos(x: 0, y: 0),
        const GridPos(x: 0, y: 0),
      ];
      final edges = <BorderRegionContourEdge>[
        for (var index = 0; index < directions.length; index += 1)
          BorderRegionContourEdge(
            startVertex: vertices[index],
            endVertex: vertices[index + 1],
            startWorldPx: BorderPixelPos(
              x: vertices[index].x,
              y: vertices[index].y,
            ),
            endWorldPx: BorderPixelPos(
              x: vertices[index + 1].x,
              y: vertices[index + 1].y,
            ),
            interiorCell: interiorCells[index],
            direction: directions[index],
            outwardSide: _leftOfForTest(directions[index]),
            turnToNext: turns[index],
            startAbscissaPx: index,
            endAbscissaPx: index + 1,
          ),
      ];

      expect(
        () => BorderRegionContour(
          kind: BorderRegionContourKind.landBoundary,
          edges: edges,
          perimeterPx: edges.length,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('returns deeply immutable value objects with value semantics', () {
      final first = extractCanonicalBorderRegionContours(
        region: _region(['#']),
        tileSizePx: const GridSize(width: 3, height: 4),
      );
      final second = extractCanonicalBorderRegionContours(
        region: _region(['#']),
        tileSizePx: const GridSize(width: 3, height: 4),
      );

      expect(first, second);
      expect(first.single, second.single);
      expect(first.single.hashCode, second.single.hashCode);
      expect(
        () => first.add(first.single),
        throwsUnsupportedError,
      );
      expect(
        () => first.single.edges.add(first.single.edges.first),
        throwsUnsupportedError,
      );
    });

    test('has a stable cross-platform canonical signature', () {
      final contours = extractCanonicalBorderRegionContours(
        region: _region(canonicalContourGoldenRows),
        tileSizePx: const GridSize(width: 7, height: 11),
      );

      expect(
        _signature(contours),
        canonicalContourGoldenSignature,
      );
    });
  });
}

BorderRegionGeometry _region(List<String> rows) {
  final width = rows.first.length;
  assert(rows.every((row) => row.length == width));
  return BorderRegionGeometry(
    width: width,
    height: rows.length,
    cells: [
      for (final row in rows)
        for (final cell in row.split('')) cell == '#',
    ],
  );
}

String _edgeIdentity(BorderRegionContourEdge edge) =>
    '${edge.startVertex.x},${edge.startVertex.y}>'
    '${edge.endVertex.x},${edge.endVertex.y}';

BorderCardinalDirection _leftOfForTest(BorderCardinalDirection direction) =>
    switch (direction) {
      BorderCardinalDirection.east => BorderCardinalDirection.north,
      BorderCardinalDirection.south => BorderCardinalDirection.east,
      BorderCardinalDirection.west => BorderCardinalDirection.south,
      BorderCardinalDirection.north => BorderCardinalDirection.west,
    };

BorderRegionContourEdge _copyEdge(
  BorderRegionContourEdge source, {
  BorderCardinalDirection? direction,
  BorderCardinalDirection? outwardSide,
  GridPos? interiorCell,
  BorderContourTurn? turnToNext,
  int? startAbscissaPx,
  int? endAbscissaPx,
}) =>
    BorderRegionContourEdge(
      startVertex: source.startVertex,
      endVertex: source.endVertex,
      startWorldPx: source.startWorldPx,
      endWorldPx: source.endWorldPx,
      interiorCell: interiorCell ?? source.interiorCell,
      direction: direction ?? source.direction,
      outwardSide: outwardSide ?? source.outwardSide,
      turnToNext: turnToNext ?? source.turnToNext,
      startAbscissaPx: startAbscissaPx ?? source.startAbscissaPx,
      endAbscissaPx: endAbscissaPx ?? source.endAbscissaPx,
    );

String _signature(List<BorderRegionContour> contours) => contours
    .map(
      (contour) => '${contour.kind.name}@${contour.originWorldPx.x},'
          '${contour.originWorldPx.y}/${contour.perimeterPx}:'
          '${contour.edges.map((edge) => '${_edgeIdentity(edge)}:'
              '${edge.direction.name}:${edge.startAbscissaPx}-'
              '${edge.endAbscissaPx}:${edge.turnToNext.name}').join('|')}',
    )
    .join(';');
