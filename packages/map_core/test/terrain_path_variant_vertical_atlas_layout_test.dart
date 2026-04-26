// ignore_for_file: prefer_const_literals_to_create_immutables

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('standardTerrainPathVariantVerticalAtlasOrder', () {
    test('covers exactly the TerrainPathVariant enum values once', () {
      // This test is an enum-evolution guard. If a future lot adds a path
      // variant, the standard atlas order must be reviewed explicitly instead
      // of inheriting an accidental enum order.
      expect(
        standardTerrainPathVariantVerticalAtlasOrder.toSet(),
        TerrainPathVariant.values.toSet(),
      );
      expect(
        standardTerrainPathVariantVerticalAtlasOrder,
        hasLength(TerrainPathVariant.values.length),
      );
    });

    test('uses the explicit V0 atlas order', () {
      expect(
        standardTerrainPathVariantVerticalAtlasOrder,
        [
          TerrainPathVariant.isolated,
          TerrainPathVariant.endNorth,
          TerrainPathVariant.endEast,
          TerrainPathVariant.endSouth,
          TerrainPathVariant.endWest,
          TerrainPathVariant.horizontal,
          TerrainPathVariant.vertical,
          TerrainPathVariant.cornerNE,
          TerrainPathVariant.cornerSE,
          TerrainPathVariant.cornerSW,
          TerrainPathVariant.cornerNW,
          TerrainPathVariant.innerCornerNE,
          TerrainPathVariant.innerCornerSE,
          TerrainPathVariant.innerCornerSW,
          TerrainPathVariant.innerCornerNW,
          TerrainPathVariant.teeNorth,
          TerrainPathVariant.teeEast,
          TerrainPathVariant.teeSouth,
          TerrainPathVariant.teeWest,
          TerrainPathVariant.cross,
        ],
      );
    });
  });

  group('createStandardTerrainPathVariantVerticalAtlasColumns', () {
    test('generates columns from zero', () {
      final columns = createStandardTerrainPathVariantVerticalAtlasColumns();

      expect(columns,
          hasLength(standardTerrainPathVariantVerticalAtlasOrder.length));
      for (var i = 0; i < columns.length; i += 1) {
        expect(columns[i].variant,
            standardTerrainPathVariantVerticalAtlasOrder[i]);
        expect(columns[i].column, i);
        expect(columns[i].startRow, 0);
      }
    });

    test('respects firstColumn', () {
      final columns = createStandardTerrainPathVariantVerticalAtlasColumns(
        firstColumn: 10,
      );

      expect(columns.first.column, 10);
      expect(columns[1].column, 11);
      expect(columns.last.column, 10 + columns.length - 1);
    });

    test('respects startRow', () {
      final columns = createStandardTerrainPathVariantVerticalAtlasColumns(
        startRow: 5,
      );

      expect(columns.every((column) => column.startRow == 5), isTrue);
    });

    test('generates a sub-layout', () {
      final columns = createStandardTerrainPathVariantVerticalAtlasColumns(
        variants: [
          TerrainPathVariant.isolated,
          TerrainPathVariant.horizontal,
          TerrainPathVariant.vertical,
        ],
      );

      expect(columns, hasLength(3));
      expect(columns[0].variant, TerrainPathVariant.isolated);
      expect(columns[0].column, 0);
      expect(columns[1].variant, TerrainPathVariant.horizontal);
      expect(columns[1].column, 1);
      expect(columns[2].variant, TerrainPathVariant.vertical);
      expect(columns[2].column, 2);
    });

    test('generates a sub-layout with firstColumn', () {
      final columns = createStandardTerrainPathVariantVerticalAtlasColumns(
        firstColumn: 20,
        variants: [
          TerrainPathVariant.isolated,
          TerrainPathVariant.horizontal,
          TerrainPathVariant.vertical,
        ],
      );

      expect(columns.map((column) => column.column), [20, 21, 22]);
    });

    test('returns an unmodifiable list', () {
      final columns = createStandardTerrainPathVariantVerticalAtlasColumns(
        variants: [TerrainPathVariant.isolated],
      );

      expect(
        () => columns.add(
          PathVariantVerticalAtlasColumn(
            variant: TerrainPathVariant.horizontal,
            column: 1,
          ),
        ),
        throwsUnsupportedError,
      );
    });

    test('is compatible with createPathVariantMappingsFromVerticalAtlas', () {
      // Lot 14 only creates the column layout. Lot 12 remains responsible for
      // turning that layout into legacy variant mappings and animation frames.
      final columns = createStandardTerrainPathVariantVerticalAtlasColumns(
        firstColumn: 3,
        startRow: 2,
        variants: [
          TerrainPathVariant.isolated,
          TerrainPathVariant.horizontal,
          TerrainPathVariant.vertical,
        ],
      );

      final mappings = createPathVariantMappingsFromVerticalAtlas(
        columns: columns,
        frameCount: 2,
      );

      expect(mappings, hasLength(3));
      expect(mappings[0].variant, TerrainPathVariant.isolated);
      expect(mappings[0].frames[0].source.x, 3);
      expect(mappings[0].frames[0].source.y, 2);
      expect(mappings[1].variant, TerrainPathVariant.horizontal);
      expect(mappings[1].frames[0].source.x, 4);
      expect(mappings[2].variant, TerrainPathVariant.vertical);
      expect(mappings[2].frames[0].source.x, 5);
    });

    test('is compatible with createProjectPathPresetFromVerticalAtlas', () {
      // Lot 13 can consume this standard layout without any runtime/editor
      // integration or new persistent Surface model.
      final columns = createStandardTerrainPathVariantVerticalAtlasColumns(
        firstColumn: 7,
        variants: [
          TerrainPathVariant.isolated,
          TerrainPathVariant.horizontal,
        ],
      );

      final preset = createProjectPathPresetFromVerticalAtlas(
        id: 'standard-water',
        name: 'Standard Water',
        surfaceKind: PathSurfaceKind.water,
        tilesetId: 'water-tileset',
        columns: columns,
        frameCount: 3,
      );

      expect(preset.id, 'standard-water');
      expect(preset.variants, hasLength(2));
      expect(preset.variants[0].variant, TerrainPathVariant.isolated);
      expect(preset.variants[0].frames, hasLength(3));
      expect(preset.variants[0].frames[0].source.x, 7);
      expect(preset.variants[1].variant, TerrainPathVariant.horizontal);
      expect(preset.variants[1].frames[0].source.x, 8);
    });

    test('rejects negative firstColumn', () {
      expect(
        () => createStandardTerrainPathVariantVerticalAtlasColumns(
          firstColumn: -1,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects negative startRow', () {
      expect(
        () => createStandardTerrainPathVariantVerticalAtlasColumns(
          startRow: -1,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects empty variants', () {
      expect(
        () => createStandardTerrainPathVariantVerticalAtlasColumns(
          variants: [],
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects duplicate variants', () {
      expect(
        () => createStandardTerrainPathVariantVerticalAtlasColumns(
          variants: [
            TerrainPathVariant.isolated,
            TerrainPathVariant.isolated,
          ],
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
