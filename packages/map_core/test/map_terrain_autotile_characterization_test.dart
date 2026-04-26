import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('map_terrain_autotile characterization', () {
    group('mask table', () {
      test('documents the public mask-to-variant mapping', () {
        // The resolver first converts cardinal neighbors into a four-bit mask:
        // north = 1, east = 2, south = 4, west = 8.
        //
        // These expectations intentionally mirror the current production table.
        // A future Surface Engine can replace the model, but these names are the
        // compatibility contract for current path/terrain autotiles.
        expect(resolvePathVariantFromMask(0), TerrainPathVariant.isolated);
        expect(resolvePathVariantFromMask(1), TerrainPathVariant.endNorth);
        expect(resolvePathVariantFromMask(2), TerrainPathVariant.endEast);
        expect(resolvePathVariantFromMask(3), TerrainPathVariant.cornerNE);
        expect(resolvePathVariantFromMask(4), TerrainPathVariant.endSouth);
        expect(resolvePathVariantFromMask(5), TerrainPathVariant.vertical);
        expect(resolvePathVariantFromMask(6), TerrainPathVariant.cornerSE);
        expect(resolvePathVariantFromMask(7), TerrainPathVariant.teeEast);
        expect(resolvePathVariantFromMask(8), TerrainPathVariant.endWest);
        expect(resolvePathVariantFromMask(9), TerrainPathVariant.cornerNW);
        expect(resolvePathVariantFromMask(10), TerrainPathVariant.horizontal);
        expect(resolvePathVariantFromMask(11), TerrainPathVariant.teeNorth);
        expect(resolvePathVariantFromMask(12), TerrainPathVariant.cornerSW);
        expect(resolvePathVariantFromMask(13), TerrainPathVariant.teeWest);
        expect(resolvePathVariantFromMask(14), TerrainPathVariant.teeSouth);
        expect(resolvePathVariantFromMask(15), TerrainPathVariant.cross);
      });

      test('rejects masks outside the current four-bit range', () {
        expect(
          () => resolvePathVariantFromMask(-1),
          throwsA(isA<ValidationException>()),
        );
        expect(
          () => resolvePathVariantFromMask(16),
          throwsA(isA<ValidationException>()),
        );
      });
    });

    group('cardinal path shapes', () {
      test('isolated active cell resolves to isolated', () {
        // Conceptual shape:
        // ...
        // .X.
        // ...
        //
        // This is the smallest path/surface island. It is important for future
        // migration because a Surface Engine must preserve how one-cell paths
        // pick their fallback visual role.
        final grid = boolGridFromAscii([
          '...',
          '.X.',
          '...',
        ]);

        expect(pathMaskAt(grid, 1, 1), 0);
        expect(pathVariantAt(grid, 1, 1), TerrainPathVariant.isolated);
      });

      test('horizontal line resolves center and both ends distinctly', () {
        // Conceptual shape:
        // .....
        // .XXX.
        // .....
        //
        // The center has west/east neighbors and becomes horizontal. The ends
        // only point toward the remaining connected path cell.
        final grid = boolGridFromAscii([
          '.....',
          '.XXX.',
          '.....',
        ]);

        expect(pathMaskAt(grid, 2, 1), 10);
        expect(pathVariantAt(grid, 2, 1), TerrainPathVariant.horizontal);

        expect(pathMaskAt(grid, 1, 1), 2);
        expect(pathVariantAt(grid, 1, 1), TerrainPathVariant.endEast);

        expect(pathMaskAt(grid, 3, 1), 8);
        expect(pathVariantAt(grid, 3, 1), TerrainPathVariant.endWest);
      });

      test('vertical line resolves center and both ends distinctly', () {
        // Conceptual shape:
        // ..X..
        // ..X..
        // ..X..
        //
        // The center has north/south neighbors and becomes vertical. The end
        // names follow the current mask table: a top end has a south neighbor,
        // so it resolves to endSouth.
        final grid = boolGridFromAscii([
          '..X..',
          '..X..',
          '..X..',
        ]);

        expect(pathMaskAt(grid, 2, 1), 5);
        expect(pathVariantAt(grid, 2, 1), TerrainPathVariant.vertical);

        expect(pathMaskAt(grid, 2, 0), 4);
        expect(pathVariantAt(grid, 2, 0), TerrainPathVariant.endSouth);

        expect(pathMaskAt(grid, 2, 2), 1);
        expect(pathVariantAt(grid, 2, 2), TerrainPathVariant.endNorth);
      });

      test('four cardinal L joins resolve to the matching corner variants', () {
        // The current resolver names corners by the connected cardinal sides,
        // not by a future visual interpretation. These four tiny L shapes lock
        // down that exact compatibility behavior.
        final northEast = boolGridFromAscii([
          '.X.',
          '.XX',
          '...',
        ]);
        final northWest = boolGridFromAscii([
          '.X.',
          'XX.',
          '...',
        ]);
        final southEast = boolGridFromAscii([
          '...',
          '.XX',
          '.X.',
        ]);
        final southWest = boolGridFromAscii([
          '...',
          'XX.',
          '.X.',
        ]);

        expect(pathMaskAt(northEast, 1, 1), 3);
        expect(pathVariantAt(northEast, 1, 1), TerrainPathVariant.cornerNE);

        expect(pathMaskAt(northWest, 1, 1), 9);
        expect(pathVariantAt(northWest, 1, 1), TerrainPathVariant.cornerNW);

        expect(pathMaskAt(southEast, 1, 1), 6);
        expect(pathVariantAt(southEast, 1, 1), TerrainPathVariant.cornerSE);

        expect(pathMaskAt(southWest, 1, 1), 12);
        expect(pathVariantAt(southWest, 1, 1), TerrainPathVariant.cornerSW);
      });

      test('four T joins resolve to the current tee variants', () {
        // The tee names are also direct products of the current mask table:
        // - teeNorth has north/east/west connections.
        // - teeEast has north/east/south connections.
        // - teeSouth has east/south/west connections.
        // - teeWest has north/south/west connections.
        //
        // These tests are intentionally about the existing enum mapping, not
        // about the naming a future Surface Engine might choose.
        final teeNorth = boolGridFromAscii([
          '.X.',
          'XXX',
          '...',
        ]);
        final teeSouth = boolGridFromAscii([
          '...',
          'XXX',
          '.X.',
        ]);
        final teeWest = boolGridFromAscii([
          '.X.',
          'XX.',
          '.X.',
        ]);
        final teeEast = boolGridFromAscii([
          '.X.',
          '.XX',
          '.X.',
        ]);

        expect(pathMaskAt(teeNorth, 1, 1), 11);
        expect(pathVariantAt(teeNorth, 1, 1), TerrainPathVariant.teeNorth);

        expect(pathMaskAt(teeSouth, 1, 1), 14);
        expect(pathVariantAt(teeSouth, 1, 1), TerrainPathVariant.teeSouth);

        expect(pathMaskAt(teeWest, 1, 1), 13);
        expect(pathVariantAt(teeWest, 1, 1), TerrainPathVariant.teeWest);

        expect(pathMaskAt(teeEast, 1, 1), 7);
        expect(pathVariantAt(teeEast, 1, 1), TerrainPathVariant.teeEast);
      });

      test('four-way intersection resolves to cross', () {
        // Conceptual shape:
        // .X.
        // XXX
        // .X.
        //
        // With all four cardinal neighbors present and no qualifying interior
        // corner diagonal pattern, the current resolver returns cross.
        final grid = boolGridFromAscii([
          '.X.',
          'XXX',
          '.X.',
        ]);

        expect(pathMaskAt(grid, 1, 1), 15);
        expect(pathVariantAt(grid, 1, 1), TerrainPathVariant.cross);
      });

      test('full 3x3 block center is cross and edges receive border fill', () {
        // Conceptual shape:
        // XXX
        // XXX
        // XXX
        //
        // There is no separate "center fill" enum today. The central tile has
        // all cardinal and diagonal neighbors, so it stays cross.
        //
        // A non-corner edge tile is more surprising: its cardinal mask would be
        // a tee, but edge fill replacement upgrades it to cross because the
        // missing side points off-map.
        final grid = boolGridFromAscii([
          'XXX',
          'XXX',
          'XXX',
        ]);

        expect(pathMaskAt(grid, 1, 1), 15);
        expect(pathVariantAt(grid, 1, 1), TerrainPathVariant.cross);

        expect(pathMaskAt(grid, 1, 0), 14);
        expect(pathVariantAt(grid, 1, 0), TerrainPathVariant.cross);

        expect(pathMaskAt(grid, 0, 0), 6);
        expect(pathVariantAt(grid, 0, 0), TerrainPathVariant.cornerSE);
      });
    });

    group('diagonal-aware interior corners', () {
      test(
          'single missing diagonal with all cardinals present creates inner corners',
          () {
        // The resolver only consults diagonals after the cardinal mask is 15.
        // When exactly one diagonal is missing and the other three diagonals are
        // present, it returns the matching innerCorner* variant.
        //
        // Missing NE:
        // XX.
        // XXX
        // XXX
        //
        // Missing SE:
        // XXX
        // XXX
        // XX.
        //
        // Missing SW:
        // XXX
        // XXX
        // .XX
        //
        // Missing NW:
        // .XX
        // XXX
        // XXX
        final missingNE = boolGridFromAscii([
          'XX.',
          'XXX',
          'XXX',
        ]);
        final missingSE = boolGridFromAscii([
          'XXX',
          'XXX',
          'XX.',
        ]);
        final missingSW = boolGridFromAscii([
          'XXX',
          'XXX',
          '.XX',
        ]);
        final missingNW = boolGridFromAscii([
          '.XX',
          'XXX',
          'XXX',
        ]);

        expect(pathMaskAt(missingNE, 1, 1), 15);
        expect(
            pathVariantAt(missingNE, 1, 1), TerrainPathVariant.innerCornerNE);

        expect(pathMaskAt(missingSE, 1, 1), 15);
        expect(
            pathVariantAt(missingSE, 1, 1), TerrainPathVariant.innerCornerSE);

        expect(pathMaskAt(missingSW, 1, 1), 15);
        expect(
            pathVariantAt(missingSW, 1, 1), TerrainPathVariant.innerCornerSW);

        expect(pathMaskAt(missingNW, 1, 1), 15);
        expect(
            pathVariantAt(missingNW, 1, 1), TerrainPathVariant.innerCornerNW);
      });

      test('multiple missing diagonals keep the all-cardinal cell as cross',
          () {
        // Conceptual shape:
        // .X.
        // XXX
        // .X.
        //
        // All four cardinal neighbors are active, but all diagonals are absent.
        // The current diagonal rule is strict: it only produces an inner corner
        // when exactly one diagonal is missing and the other three are present.
        final grid = boolGridFromAscii([
          '.X.',
          'XXX',
          '.X.',
        ]);

        expect(pathMaskAt(grid, 1, 1), 15);
        expect(pathVariantAt(grid, 1, 1), TerrainPathVariant.cross);
      });
    });

    group('map edges and out-of-map neighbors', () {
      test('non-corner edge cells can be promoted to cross', () {
        // These four shapes document the edge-fill rule. Off-map neighbors are
        // not matches for mask calculation, but a mid-path variant on an edge
        // can still be promoted to cross when the missing side points outside.
        final top = boolGridFromAscii([
          'XXX',
          '...',
          '...',
        ]);
        final bottom = boolGridFromAscii([
          '...',
          '...',
          'XXX',
        ]);
        final left = boolGridFromAscii([
          'X..',
          'X..',
          'X..',
        ]);
        final right = boolGridFromAscii([
          '..X',
          '..X',
          '..X',
        ]);

        expect(pathMaskAt(top, 1, 0), 10);
        expect(pathVariantAt(top, 1, 0), TerrainPathVariant.cross);

        expect(pathMaskAt(bottom, 1, 2), 10);
        expect(pathVariantAt(bottom, 1, 2), TerrainPathVariant.cross);

        expect(pathMaskAt(left, 0, 1), 5);
        expect(pathVariantAt(left, 0, 1), TerrainPathVariant.cross);

        expect(pathMaskAt(right, 2, 1), 5);
        expect(pathVariantAt(right, 2, 1), TerrainPathVariant.cross);
      });

      test('map corner cells keep corner variants when two map edges touch',
          () {
        // Conceptual shape at the top-left map corner:
        // XX.
        // X..
        // ...
        //
        // This is deliberately different from the non-corner edge rule. The
        // corner-specific replacement only fires when exactly one map edge is
        // touched, so this two-edge map corner keeps cornerSE.
        final grid = boolGridFromAscii([
          'XX.',
          'X..',
          '...',
        ]);

        expect(pathMaskAt(grid, 0, 0), 6);
        expect(pathVariantAt(grid, 0, 0), TerrainPathVariant.cornerSE);
      });

      test(
          'single-edge corner replacements turn some corner variants into ends',
          () {
        // Conceptual shape on the top edge but not in a map corner:
        // .XX.
        // .X..
        // ....
        //
        // The tested cell has east/south neighbors, so the base mask variant is
        // cornerSE. Because it touches exactly the north map edge, the current
        // resolver replaces cornerSE with endEast.
        final grid = boolGridFromAscii([
          '.XX.',
          '.X..',
          '....',
        ]);

        expect(pathMaskAt(grid, 1, 0), 6);
        expect(pathVariantAt(grid, 1, 0), TerrainPathVariant.endEast);
      });
    });

    group('inactive cells and invalid inputs', () {
      test('inactive current cell is not checked before resolving neighbors',
          () {
        // Conceptual shape:
        // .X.
        // X.X
        // .X.
        //
        // The center cell is inactive, but the public resolver does not require
        // the current cell to match. It resolves purely from neighbors and
        // returns cross. The runtime/editor normally call this for active path
        // cells, so this test is documentation rather than a recommended use.
        final grid = boolGridFromAscii([
          '.X.',
          'X.X',
          '.X.',
        ]);

        expect(grid.cells[grid.indexOf(1, 1)], isFalse);
        expect(pathMaskAt(grid, 1, 1), 15);
        expect(pathVariantAt(grid, 1, 1), TerrainPathVariant.cross);
      });

      test('coordinates outside the grid throw validation errors', () {
        final grid = boolGridFromAscii(['X']);

        expect(
          () => pathVariantAt(grid, -1, 0),
          throwsA(isA<ValidationException>()),
        );
        expect(
          () => pathVariantAt(grid, 0, -1),
          throwsA(isA<ValidationException>()),
        );
        expect(
          () => pathVariantAt(grid, 1, 0),
          throwsA(isA<ValidationException>()),
        );
        expect(
          () => pathVariantAt(grid, 0, 1),
          throwsA(isA<ValidationException>()),
        );
      });

      test('empty sizes and incomplete grids throw validation errors', () {
        expect(
          () => resolvePathVariantAt(
            cells: const [],
            mapSize: const GridSize(width: 0, height: 1),
            pos: const GridPos(x: 0, y: 0),
          ),
          throwsA(isA<ValidationException>()),
        );
        expect(
          () => resolvePathVariantAt(
            cells: const [],
            mapSize: const GridSize(width: 1, height: 0),
            pos: const GridPos(x: 0, y: 0),
          ),
          throwsA(isA<ValidationException>()),
        );
        expect(
          () => resolvePathVariantAt(
            cells: const [true],
            mapSize: const GridSize(width: 2, height: 2),
            pos: const GridPos(x: 0, y: 0),
          ),
          throwsA(isA<ValidationException>()),
        );
      });

      test('extra path cells beyond map bounds are tolerated and ignored', () {
        // Validation only rejects grids shorter than width * height. A longer
        // list is accepted, and index math only reads cells inside map bounds.
        // This is a fragile compatibility detail worth recording before any
        // future grid storage refactor.
        expect(
          resolvePathVariantAt(
            cells: const [true, false, false, false, true],
            mapSize: const GridSize(width: 2, height: 2),
            pos: const GridPos(x: 0, y: 0),
          ),
          TerrainPathVariant.isolated,
        );
      });
    });

    group('terrain resolver parity', () {
      test('terrain autotile uses the selected terrain type as the matcher',
          () {
        // The terrain resolver shares the same variant machinery as paths, but
        // its matcher is "same TerrainType" instead of "path cell is true".
        //
        // Grass cells form a horizontal line, while the requested dirt terrain
        // has no matching neighbors. This documents that terrain type selection
        // is part of the current compatibility behavior.
        final grid = terrainGridFromAscii([
          '.....',
          '.GGG.',
          '.....',
        ]);

        expect(
          terrainMaskAt(grid, 2, 1, terrain: TerrainType.grass),
          10,
        );
        expect(
          terrainVariantAt(grid, 2, 1, terrain: TerrainType.grass),
          TerrainPathVariant.horizontal,
        );

        expect(
          terrainMaskAt(grid, 2, 1, terrain: TerrainType.dirt),
          0,
        );
        expect(
          terrainVariantAt(grid, 2, 1, terrain: TerrainType.dirt),
          TerrainPathVariant.isolated,
        );
      });

      test('terrain resolver has the same inactive-current-cell behavior', () {
        // The center is TerrainType.none, but grass cardinals surround it. Like
        // the path resolver, the terrain resolver does not check that the
        // current cell itself is the requested terrain.
        final grid = terrainGridFromAscii([
          '.G.',
          'G.G',
          '.G.',
        ]);

        expect(grid.terrains[grid.indexOf(1, 1)], TerrainType.none);
        expect(
          terrainVariantAt(grid, 1, 1, terrain: TerrainType.grass),
          TerrainPathVariant.cross,
        );
      });

      test(
          'terrain validation rejects incomplete grids and out-of-bounds positions',
          () {
        expect(
          () => resolveTerrainPathVariantAt(
            terrains: const [TerrainType.grass],
            mapSize: const GridSize(width: 2, height: 2),
            pos: const GridPos(x: 0, y: 0),
          ),
          throwsA(isA<ValidationException>()),
        );

        final grid = terrainGridFromAscii(['G']);
        expect(
          () => terrainVariantAt(grid, 1, 0, terrain: TerrainType.grass),
          throwsA(isA<ValidationException>()),
        );
      });
    });
  });
}

BoolGrid boolGridFromAscii(List<String> rows) {
  assert(rows.isNotEmpty, 'Use direct resolver calls for invalid empty grids.');
  final width = rows.first.length;
  assert(width > 0, 'Use direct resolver calls for invalid empty rows.');
  assert(
    rows.every((row) => row.length == width),
    'ASCII grids must be rectangular.',
  );

  return BoolGrid(
    size: GridSize(width: width, height: rows.length),
    cells: [
      for (final row in rows)
        for (final char in row.split('')) char == 'X',
    ],
  );
}

TerrainGrid terrainGridFromAscii(List<String> rows) {
  assert(rows.isNotEmpty, 'Use direct resolver calls for invalid empty grids.');
  final width = rows.first.length;
  assert(width > 0, 'Use direct resolver calls for invalid empty rows.');
  assert(
    rows.every((row) => row.length == width),
    'ASCII grids must be rectangular.',
  );

  return TerrainGrid(
    size: GridSize(width: width, height: rows.length),
    terrains: [
      for (final row in rows)
        for (final char in row.split(''))
          switch (char) {
            'G' => TerrainType.grass,
            'D' => TerrainType.dirt,
            'S' => TerrainType.sand,
            '.' => TerrainType.none,
            _ => throw ArgumentError.value(
                char,
                'char',
                'Use G, D, S, or . in terrain ASCII grids.',
              ),
          },
    ],
  );
}

int pathMaskAt(BoolGrid grid, int x, int y) {
  return resolvePathCardinalMaskAt(
    cells: grid.cells,
    mapSize: grid.size,
    pos: GridPos(x: x, y: y),
  );
}

TerrainPathVariant pathVariantAt(BoolGrid grid, int x, int y) {
  return resolvePathVariantAt(
    cells: grid.cells,
    mapSize: grid.size,
    pos: GridPos(x: x, y: y),
  );
}

int terrainMaskAt(
  TerrainGrid grid,
  int x,
  int y, {
  required TerrainType terrain,
}) {
  return resolveTerrainCardinalMaskAt(
    terrains: grid.terrains,
    mapSize: grid.size,
    pos: GridPos(x: x, y: y),
    terrain: terrain,
  );
}

TerrainPathVariant terrainVariantAt(
  TerrainGrid grid,
  int x,
  int y, {
  required TerrainType terrain,
}) {
  return resolveTerrainPathVariantAt(
    terrains: grid.terrains,
    mapSize: grid.size,
    pos: GridPos(x: x, y: y),
    terrain: terrain,
  );
}

class BoolGrid {
  const BoolGrid({
    required this.size,
    required this.cells,
  });

  final GridSize size;
  final List<bool> cells;

  int indexOf(int x, int y) => y * size.width + x;
}

class TerrainGrid {
  const TerrainGrid({
    required this.size,
    required this.terrains,
  });

  final GridSize size;
  final List<TerrainType> terrains;

  int indexOf(int x, int y) => y * size.width + x;
}
