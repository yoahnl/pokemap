import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('resolvePathPatternVisual center-only 1x1', () {
    test('uses center pattern for multiple variants when no mapping exists',
        () {
      final preset = _pathPatternPreset(centerPattern: _singleCellPattern());
      final base = _basePathPreset(variants: const []);

      final variants = [
        TerrainPathVariant.endNorth,
        TerrainPathVariant.cornerNE,
        TerrainPathVariant.isolated,
      ];
      for (final variant in variants) {
        final resolution = resolvePathPatternVisual(
          pathPatternPreset: preset,
          basePathPreset: base,
          resolvedVariant: variant,
          mapX: 7,
          mapY: 3,
        );
        expect(resolution.kind, PathPatternVisualResolutionKind.centerPattern);
        expect(resolution.resolvedVariant, variant);
        expect(resolution.centerLocalX, 0);
        expect(resolution.centerLocalY, 0);
        expect(resolution.frames.single.source,
            const TilesetSourceRect(x: 10, y: 0));
      }
    });
  });

  group('resolvePathPatternVisual center-only 2x2 repetition', () {
    test('repeats A/B/C/D by map coordinates', () {
      final preset = _pathPatternPreset(centerPattern: _twoByTwoPattern());
      final base = _basePathPreset(variants: const []);

      _expectCenter(preset, base,
          mapX: 0, mapY: 0, expectedSourceX: 0, expectedSourceY: 0);
      _expectCenter(preset, base,
          mapX: 1, mapY: 0, expectedSourceX: 1, expectedSourceY: 0);
      _expectCenter(preset, base,
          mapX: 0, mapY: 1, expectedSourceX: 0, expectedSourceY: 1);
      _expectCenter(preset, base,
          mapX: 1, mapY: 1, expectedSourceX: 1, expectedSourceY: 1);
      _expectCenter(preset, base,
          mapX: 2, mapY: 0, expectedSourceX: 0, expectedSourceY: 0);
      _expectCenter(preset, base,
          mapX: 3, mapY: 1, expectedSourceX: 1, expectedSourceY: 1);
    });
  });

  group('resolvePathPatternVisual configured variant', () {
    test('uses legacy variant frames when mapping exists', () {
      final preset = _pathPatternPreset(centerPattern: _singleCellPattern());
      final base = _basePathPreset(
        variants: [
          PathPresetVariantMapping(
            variant: TerrainPathVariant.endNorth,
            frames: const [
              TilesetVisualFrame(
                tilesetId: 'variant-tileset',
                source: TilesetSourceRect(x: 30, y: 5),
                durationMs: 90,
              ),
            ],
          ),
        ],
      );

      final resolution = resolvePathPatternVisual(
        pathPatternPreset: preset,
        basePathPreset: base,
        resolvedVariant: TerrainPathVariant.endNorth,
        mapX: 4,
        mapY: 2,
      );

      expect(resolution.kind, PathPatternVisualResolutionKind.legacyVariant);
      expect(resolution.centerLocalX, isNull);
      expect(resolution.centerLocalY, isNull);
      expect(resolution.frames.single.tilesetId, 'variant-tileset');
      expect(resolution.frames.single.source,
          const TilesetSourceRect(x: 30, y: 5));
      expect(resolution.frames.single.durationMs, 90);
    });
  });

  group('resolvePathPatternVisual missing variant', () {
    test('falls back to center pattern', () {
      final preset = _pathPatternPreset(centerPattern: _singleCellPattern());
      final base = _basePathPreset(variants: const []);

      final resolution = resolvePathPatternVisual(
        pathPatternPreset: preset,
        basePathPreset: base,
        resolvedVariant: TerrainPathVariant.cornerNE,
        mapX: 0,
        mapY: 0,
      );

      expect(resolution.kind, PathPatternVisualResolutionKind.centerPattern);
      expect(resolution.frames.single.source,
          const TilesetSourceRect(x: 10, y: 0));
    });
  });

  group('resolvePathPatternVisual cross policy', () {
    test('always uses center pattern even when cross mapping exists', () {
      final preset = _pathPatternPreset(centerPattern: _singleCellPattern());
      final base = _basePathPreset(
        variants: [
          PathPresetVariantMapping(
            variant: TerrainPathVariant.cross,
            frames: const [
              TilesetVisualFrame(source: TilesetSourceRect(x: 99, y: 99)),
            ],
          ),
        ],
      );

      final resolution = resolvePathPatternVisual(
        pathPatternPreset: preset,
        basePathPreset: base,
        resolvedVariant: TerrainPathVariant.cross,
        mapX: 2,
        mapY: 2,
      );

      expect(resolution.kind, PathPatternVisualResolutionKind.centerPattern);
      expect(resolution.frames.single.source,
          const TilesetSourceRect(x: 10, y: 0));
    });
  });

  group('resolvePathPatternVisual frame metadata', () {
    test('keeps frame order, duration and tileset override on center fallback',
        () {
      final preset = _pathPatternPreset(
        centerPattern: PathCenterPattern(
          size: PathCenterPatternSize(width: 1, height: 1),
          cells: [
            PathCenterPatternCell(
              localX: 0,
              localY: 0,
              frames: const [
                TilesetVisualFrame(
                  tilesetId: 'override-a',
                  source: TilesetSourceRect(x: 1, y: 2),
                  durationMs: 80,
                ),
                TilesetVisualFrame(
                  tilesetId: 'override-b',
                  source: TilesetSourceRect(x: 3, y: 4),
                  durationMs: 120,
                ),
              ],
            ),
          ],
        ),
      );
      final base = _basePathPreset(variants: const []);

      final resolution = resolvePathPatternVisual(
        pathPatternPreset: preset,
        basePathPreset: base,
        resolvedVariant: TerrainPathVariant.teeNorth,
        mapX: 0,
        mapY: 0,
      );

      expect(resolution.kind, PathPatternVisualResolutionKind.centerPattern);
      expect(resolution.frames.length, 2);
      expect(resolution.frames[0].tilesetId, 'override-a');
      expect(resolution.frames[0].source, const TilesetSourceRect(x: 1, y: 2));
      expect(resolution.frames[0].durationMs, 80);
      expect(resolution.frames[1].tilesetId, 'override-b');
      expect(resolution.frames[1].source, const TilesetSourceRect(x: 3, y: 4));
      expect(resolution.frames[1].durationMs, 120);
    });

    test('keeps frame order, duration and tileset override on legacy variant',
        () {
      final preset = _pathPatternPreset(centerPattern: _singleCellPattern());
      final base = _basePathPreset(
        variants: [
          PathPresetVariantMapping(
            variant: TerrainPathVariant.cornerSE,
            frames: const [
              TilesetVisualFrame(
                tilesetId: 'legacy-a',
                source: TilesetSourceRect(x: 7, y: 8),
                durationMs: 70,
              ),
              TilesetVisualFrame(
                tilesetId: 'legacy-b',
                source: TilesetSourceRect(x: 9, y: 10),
                durationMs: 110,
              ),
            ],
          ),
        ],
      );

      final resolution = resolvePathPatternVisual(
        pathPatternPreset: preset,
        basePathPreset: base,
        resolvedVariant: TerrainPathVariant.cornerSE,
        mapX: 6,
        mapY: 6,
      );

      expect(resolution.kind, PathPatternVisualResolutionKind.legacyVariant);
      expect(resolution.frames.length, 2);
      expect(resolution.frames[0].tilesetId, 'legacy-a');
      expect(resolution.frames[0].source, const TilesetSourceRect(x: 7, y: 8));
      expect(resolution.frames[0].durationMs, 70);
      expect(resolution.frames[1].tilesetId, 'legacy-b');
      expect(resolution.frames[1].source, const TilesetSourceRect(x: 9, y: 10));
      expect(resolution.frames[1].durationMs, 110);
    });
  });

  group('resolvePathPatternVisual invalid coordinates', () {
    test('rejects negative coordinates', () {
      final preset = _pathPatternPreset(centerPattern: _singleCellPattern());
      final base = _basePathPreset(
        variants: [
          PathPresetVariantMapping(
            variant: TerrainPathVariant.endSouth,
            frames: const [
              TilesetVisualFrame(source: TilesetSourceRect(x: 1, y: 1)),
            ],
          ),
        ],
      );

      expect(
        () => resolvePathPatternVisual(
          pathPatternPreset: preset,
          basePathPreset: base,
          resolvedVariant: TerrainPathVariant.endSouth,
          mapX: -1,
          mapY: 0,
        ),
        throwsArgumentError,
      );
      expect(
        () => resolvePathPatternVisual(
          pathPatternPreset: preset,
          basePathPreset: base,
          resolvedVariant: TerrainPathVariant.endSouth,
          mapX: 0,
          mapY: -1,
        ),
        throwsArgumentError,
      );
    });
  });

  group('resolvePathPatternVisual empty mapping frames', () {
    test('falls back to center pattern when mapping has no frames', () {
      final preset = _pathPatternPreset(centerPattern: _singleCellPattern());
      final base = _basePathPreset(
        variants: [
          PathPresetVariantMapping(
            variant: TerrainPathVariant.endWest,
            frames: const [],
          ),
        ],
      );

      final resolution = resolvePathPatternVisual(
        pathPatternPreset: preset,
        basePathPreset: base,
        resolvedVariant: TerrainPathVariant.endWest,
        mapX: 4,
        mapY: 4,
      );

      expect(resolution.kind, PathPatternVisualResolutionKind.centerPattern);
      expect(resolution.frames.single.source,
          const TilesetSourceRect(x: 10, y: 0));
    });
  });
}

void _expectCenter(
  ProjectPathPatternPreset pathPatternPreset,
  ProjectPathPreset basePathPreset, {
  required int mapX,
  required int mapY,
  required int expectedSourceX,
  required int expectedSourceY,
}) {
  final resolution = resolvePathPatternVisual(
    pathPatternPreset: pathPatternPreset,
    basePathPreset: basePathPreset,
    resolvedVariant: TerrainPathVariant.cornerNW,
    mapX: mapX,
    mapY: mapY,
  );
  expect(resolution.kind, PathPatternVisualResolutionKind.centerPattern);
  expect(
    resolution.frames.single.source,
    TilesetSourceRect(x: expectedSourceX, y: expectedSourceY),
  );
}

ProjectPathPatternPreset _pathPatternPreset({
  required PathCenterPattern centerPattern,
}) {
  return ProjectPathPatternPreset(
    id: 'pattern',
    name: 'Pattern',
    basePathPresetId: 'base',
    centerPattern: centerPattern,
  );
}

ProjectPathPreset _basePathPreset({
  required List<PathPresetVariantMapping> variants,
}) {
  return ProjectPathPreset(
    id: 'base',
    name: 'Base',
    tilesetId: 'base-tileset',
    variants: variants,
  );
}

PathCenterPattern _singleCellPattern() {
  return PathCenterPattern(
    size: PathCenterPatternSize(width: 1, height: 1),
    cells: [
      PathCenterPatternCell(
        localX: 0,
        localY: 0,
        frames: const [
          TilesetVisualFrame(
            source: TilesetSourceRect(x: 10, y: 0),
          ),
        ],
      ),
    ],
  );
}

PathCenterPattern _twoByTwoPattern() {
  return PathCenterPattern(
    size: PathCenterPatternSize(width: 2, height: 2),
    cells: [
      PathCenterPatternCell(
        localX: 0,
        localY: 0,
        frames: const [
          TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
        ],
      ),
      PathCenterPatternCell(
        localX: 1,
        localY: 0,
        frames: const [
          TilesetVisualFrame(source: TilesetSourceRect(x: 1, y: 0)),
        ],
      ),
      PathCenterPatternCell(
        localX: 0,
        localY: 1,
        frames: const [
          TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 1)),
        ],
      ),
      PathCenterPatternCell(
        localX: 1,
        localY: 1,
        frames: const [
          TilesetVisualFrame(source: TilesetSourceRect(x: 1, y: 1)),
        ],
      ),
    ],
  );
}
