import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectPathPatternPreset', () {
    test('creates a minimal preset with defaults', () {
      final centerPattern = _singleCellCenterPattern();

      final preset = ProjectPathPatternPreset(
        id: 'water-1x1',
        name: 'Water 1x1',
        basePathPresetId: 'legacy-water',
        centerPattern: centerPattern,
      );

      expect(preset.id, 'water-1x1');
      expect(preset.name, 'Water 1x1');
      expect(preset.basePathPresetId, 'legacy-water');
      expect(preset.centerPattern, centerPattern);
      expect(preset.transparentColor, isNull);
      expect(preset.categoryId, isNull);
      expect(preset.sortOrder, 0);
      expect(preset.hasTransparentColor, isFalse);
      expect(preset.usesSingleCellCenter, isTrue);
      expect(preset.usesMultiCellCenter, isFalse);
    });

    test('creates a complete preset with a 2x2 center pattern', () {
      final centerPattern = _twoByTwoCenterPattern();
      final transparentColor = TilesetTransparentColor.fromHexRgb('f05ba1');

      final preset = ProjectPathPatternPreset(
        id: 'water-sea-2x2',
        name: 'Mer 2x2',
        basePathPresetId: 'legacy-water',
        centerPattern: centerPattern,
        transparentColor: transparentColor,
        categoryId: 'water',
        sortOrder: 12,
      );

      expect(preset.id, 'water-sea-2x2');
      expect(preset.name, 'Mer 2x2');
      expect(preset.basePathPresetId, 'legacy-water');
      expect(preset.centerPattern, centerPattern);
      expect(preset.transparentColor, transparentColor);
      expect(preset.categoryId, 'water');
      expect(preset.sortOrder, 12);
      expect(preset.hasTransparentColor, isTrue);
      expect(preset.usesSingleCellCenter, isFalse);
      expect(preset.usesMultiCellCenter, isTrue);
    });

    test('rejects blank identity fields', () {
      final centerPattern = _singleCellCenterPattern();

      expect(
        () => ProjectPathPatternPreset(
          id: '',
          name: 'Water',
          basePathPresetId: 'legacy-water',
          centerPattern: centerPattern,
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => ProjectPathPatternPreset(
          id: '   ',
          name: 'Water',
          basePathPresetId: 'legacy-water',
          centerPattern: centerPattern,
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => ProjectPathPatternPreset(
          id: 'water',
          name: '',
          basePathPresetId: 'legacy-water',
          centerPattern: centerPattern,
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => ProjectPathPatternPreset(
          id: 'water',
          name: '   ',
          basePathPresetId: 'legacy-water',
          centerPattern: centerPattern,
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => ProjectPathPatternPreset(
          id: 'water',
          name: 'Water',
          basePathPresetId: '',
          centerPattern: centerPattern,
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => ProjectPathPatternPreset(
          id: 'water',
          name: 'Water',
          basePathPresetId: '   ',
          centerPattern: centerPattern,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('validates with trim but stores original strings', () {
      final preset = ProjectPathPatternPreset(
        id: ' water ',
        name: ' Water ',
        basePathPresetId: ' legacy-water ',
        centerPattern: _singleCellCenterPattern(),
      );

      expect(preset.id, ' water ');
      expect(preset.name, ' Water ');
      expect(preset.basePathPresetId, ' legacy-water ');
    });

    test('supports value equality and stable hashCode', () {
      final base = ProjectPathPatternPreset(
        id: 'water',
        name: 'Water',
        basePathPresetId: 'legacy-water',
        centerPattern: _singleCellCenterPattern(),
        transparentColor: TilesetTransparentColor.fromHexRgb('f05ba1'),
        categoryId: 'water',
        sortOrder: 1,
      );

      expect(
        base,
        ProjectPathPatternPreset(
          id: 'water',
          name: 'Water',
          basePathPresetId: 'legacy-water',
          centerPattern: _singleCellCenterPattern(),
          transparentColor: TilesetTransparentColor.fromHexRgb('#F05BA1'),
          categoryId: 'water',
          sortOrder: 1,
        ),
      );
      expect(
        base.hashCode,
        ProjectPathPatternPreset(
          id: 'water',
          name: 'Water',
          basePathPresetId: 'legacy-water',
          centerPattern: _singleCellCenterPattern(),
          transparentColor: TilesetTransparentColor.fromHexRgb('f05ba1'),
          categoryId: 'water',
          sortOrder: 1,
        ).hashCode,
      );
      expect(
        base,
        isNot(
          ProjectPathPatternPreset(
            id: 'water-2',
            name: 'Water',
            basePathPresetId: 'legacy-water',
            centerPattern: _singleCellCenterPattern(),
            transparentColor: TilesetTransparentColor.fromHexRgb('f05ba1'),
            categoryId: 'water',
            sortOrder: 1,
          ),
        ),
      );
      expect(
        base,
        isNot(
          ProjectPathPatternPreset(
            id: 'water',
            name: 'Water 2',
            basePathPresetId: 'legacy-water',
            centerPattern: _singleCellCenterPattern(),
            transparentColor: TilesetTransparentColor.fromHexRgb('f05ba1'),
            categoryId: 'water',
            sortOrder: 1,
          ),
        ),
      );
      expect(
        base,
        isNot(
          ProjectPathPatternPreset(
            id: 'water',
            name: 'Water',
            basePathPresetId: 'legacy-water-2',
            centerPattern: _singleCellCenterPattern(),
            transparentColor: TilesetTransparentColor.fromHexRgb('f05ba1'),
            categoryId: 'water',
            sortOrder: 1,
          ),
        ),
      );
      expect(
        base,
        isNot(
          ProjectPathPatternPreset(
            id: 'water',
            name: 'Water',
            basePathPresetId: 'legacy-water',
            centerPattern: _twoByTwoCenterPattern(),
            transparentColor: TilesetTransparentColor.fromHexRgb('f05ba1'),
            categoryId: 'water',
            sortOrder: 1,
          ),
        ),
      );
      expect(
        base,
        isNot(
          ProjectPathPatternPreset(
            id: 'water',
            name: 'Water',
            basePathPresetId: 'legacy-water',
            centerPattern: _singleCellCenterPattern(),
            transparentColor: TilesetTransparentColor.fromHexRgb('0000ff'),
            categoryId: 'water',
            sortOrder: 1,
          ),
        ),
      );
      expect(
        base,
        isNot(
          ProjectPathPatternPreset(
            id: 'water',
            name: 'Water',
            basePathPresetId: 'legacy-water',
            centerPattern: _singleCellCenterPattern(),
            transparentColor: TilesetTransparentColor.fromHexRgb('f05ba1'),
            categoryId: 'water-2',
            sortOrder: 1,
          ),
        ),
      );
      expect(
        base,
        isNot(
          ProjectPathPatternPreset(
            id: 'water',
            name: 'Water',
            basePathPresetId: 'legacy-water',
            centerPattern: _singleCellCenterPattern(),
            transparentColor: TilesetTransparentColor.fromHexRgb('f05ba1'),
            categoryId: 'water',
            sortOrder: 2,
          ),
        ),
      );
    });
  });
}

PathCenterPattern _singleCellCenterPattern() {
  return PathCenterPattern(
    size: PathCenterPatternSize(width: 1, height: 1),
    cells: [
      PathCenterPatternCell(
        localX: 0,
        localY: 0,
        frames: [_frame(0, 0)],
      ),
    ],
  );
}

PathCenterPattern _twoByTwoCenterPattern() {
  return PathCenterPattern(
    size: PathCenterPatternSize(width: 2, height: 2),
    cells: [
      PathCenterPatternCell(localX: 0, localY: 0, frames: [_frame(0, 0)]),
      PathCenterPatternCell(localX: 1, localY: 0, frames: [_frame(1, 0)]),
      PathCenterPatternCell(localX: 0, localY: 1, frames: [_frame(0, 1)]),
      PathCenterPatternCell(localX: 1, localY: 1, frames: [_frame(1, 1)]),
    ],
  );
}

TilesetVisualFrame _frame(int x, int y) {
  return TilesetVisualFrame(source: TilesetSourceRect(x: x, y: y));
}
