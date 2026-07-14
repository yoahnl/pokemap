import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('resolveBorderGroundBand', () {
    test('materializes only the requested inner morphological band', () {
      final result = resolveBorderGroundBand(
        region: _region(List<String>.filled(5, '#####')),
        ground: _ground(edgeBandCells: 1),
      );

      expect(result, hasLength(16));
      expect(
        result.any((cell) => cell.x == 2 && cell.y == 2),
        isFalse,
      );
      expect(
        result.map((cell) => (cell.y, cell.x)),
        orderedEquals(<(int, int)>[
          for (var y = 0; y < 5; y += 1)
            for (var x = 0; x < 5; x += 1)
              if (x == 0 || y == 0 || x == 4 || y == 4) (y, x),
        ]),
      );
    });

    test('resolves roles against the complete region before band filtering',
        () {
      final result = resolveBorderGroundBand(
        region: _region(List<String>.filled(5, '#####')),
        ground: _ground(edgeBandCells: 1),
      );
      final topMiddle = result.singleWhere(
        (cell) => cell.x == 2 && cell.y == 0,
      );

      expect(topMiddle.resolvedRole, SurfaceVariantRole.teeSouth);
      expect(
        topMiddle.visualSnapshotId,
        _snapshotFor(SurfaceVariantRole.teeSouth),
      );
    });

    test('treats holes as exterior and never emits outside a filled cell', () {
      final region = _region([
        '#####',
        '#####',
        '##.##',
        '#####',
        '#####',
      ]);
      final result = resolveBorderGroundBand(
        region: region,
        ground: _ground(edgeBandCells: 1),
      );

      expect(result, hasLength(20));
      expect(result.any((cell) => cell.x == 2 && cell.y == 2), isFalse);
      expect(
        result.every((cell) => region.cells[cell.y * region.width + cell.x]),
        isTrue,
      );
    });

    test('a wider band peels repeated cardinal erosions', () {
      final result = resolveBorderGroundBand(
        region: _region(List<String>.filled(5, '#####')),
        ground: _ground(edgeBandCells: 2),
      );

      expect(result, hasLength(24));
      expect(result.any((cell) => cell.x == 2 && cell.y == 2), isFalse);
      expect(result, isNotEmpty);
      expect(() => result.add(result.first), throwsUnsupportedError);
    });

    test('empty regions produce no ground', () {
      expect(
        resolveBorderGroundBand(
          region: _region(['...', '...']),
          ground: _ground(edgeBandCells: 3),
        ),
        isEmpty,
      );
    });
  });
}

BorderRegionGeometry _region(List<String> rows) => BorderRegionGeometry(
      width: rows.first.length,
      height: rows.length,
      cells: <bool>[
        for (final row in rows)
          for (final cell in row.split('')) cell == '#',
      ],
    );

BorderPublishedGround _ground({required int edgeBandCells}) =>
    BorderPublishedGround(
      sourceSurfacePresetId: 'ground',
      edgeBandCells: edgeBandCells,
      visualSnapshotIdsByRole: <SurfaceVariantRole, String>{
        for (final role in standardSurfaceVariantRoleOrder)
          role: _snapshotFor(role),
      },
    );

String _snapshotFor(SurfaceVariantRole role) => 'border-snapshot-sha256:'
    '${(standardSurfaceVariantRoleOrder.indexOf(role) + 1).toRadixString(16).padLeft(64, '0')}';
