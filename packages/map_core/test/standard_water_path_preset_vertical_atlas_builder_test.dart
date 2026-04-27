// ignore_for_file: prefer_const_literals_to_create_immutables

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  // Lot 16 is a tiny specialization of Lot 15: the vertical atlas contract is
  // unchanged, but the resulting legacy preset is always tagged as water via
  // [PathSurfaceKind.water]. This suite mirrors the Lot 15 tests to prove the
  // wrapper does not fork validation or frame layout semantics.
  group('createStandardWaterPathPresetFromVerticalAtlas', () {
    group('preset generation', () {
      test('generates a water ProjectPathPreset with the full standard layout',
          () {
        final preset = _water(frameCount: 4);

        expect(preset.id, 'standard-water');
        expect(preset.name, 'Standard Water');
        expect(preset.surfaceKind, PathSurfaceKind.water);
        expect(preset.tilesetId, 'outdoor-water');
        expect(preset.variants,
            hasLength(standardTerrainPathVariantVerticalAtlasOrder.length));
        expect(
          preset.variants.first.variant,
          standardTerrainPathVariantVerticalAtlasOrder.first,
        );
        expect(
          preset.variants.last.variant,
          standardTerrainPathVariantVerticalAtlasOrder.last,
        );
        expect(preset.variants.first.frames.first.source.x, 0);
        expect(
          preset.variants.last.frames.first.source.x,
          standardTerrainPathVariantVerticalAtlasOrder.length - 1,
        );
        expect(
          preset.variants.every((mapping) => mapping.frames.length == 4),
          isTrue,
        );
      });

      test('API specialization: generated presets are always water', () {
        // This is intentionally not a "compilation test". The contract is that
        // Lot 16 does not expose a [surfaceKind] parameter, so callers cannot
        // accidentally build a different legacy surface kind while reusing the
        // same vertical atlas parameters.
        final preset = _water();

        expect(preset.surfaceKind, PathSurfaceKind.water);
      });

      test('preserves categoryId and sortOrder', () {
        final preset = _water(categoryId: 'water-category', sortOrder: 42);

        expect(preset.categoryId, 'water-category');
        expect(preset.sortOrder, 42);
      });

      test('respects firstColumn', () {
        final preset = _water(firstColumn: 10);

        expect(preset.variants.first.frames.first.source.x, 10);
        expect(preset.variants[1].frames.first.source.x, 11);
        expect(
          preset.variants.last.frames.first.source.x,
          10 + standardTerrainPathVariantVerticalAtlasOrder.length - 1,
        );
      });

      test('respects startRow', () {
        final preset = _water(startRow: 7, frameCount: 3);

        for (final mapping in preset.variants) {
          expect(mapping.frames.map((frame) => frame.source.y), [7, 8, 9]);
        }
      });

      test('generates a variant sub-layout', () {
        final preset = _water(variants: _subset);

        expect(preset.variants, hasLength(3));
        expect(preset.variants.map((mapping) => mapping.variant), _subset);
        expect(
          preset.variants.map((mapping) => mapping.frames.first.source.x),
          [0, 1, 2],
        );
      });

      test('generates a variant sub-layout with firstColumn', () {
        final preset = _water(variants: _subset, firstColumn: 20);

        expect(
          preset.variants.map((mapping) => mapping.frames.first.source.x),
          [20, 21, 22],
        );
      });

      test('respects sourceWidth and sourceHeight', () {
        final preset = _water(sourceWidth: 2, sourceHeight: 3);

        for (final frame in _allFrames(preset)) {
          expect(frame.source.width, 2);
          expect(frame.source.height, 3);
        }
      });

      test('distinguishes preset tilesetId from frameTilesetId', () {
        final preset = _water(
          tilesetId: 'main-water-tileset',
          frameTilesetId: 'animated-water-atlas',
        );

        expect(preset.tilesetId, 'main-water-tileset');
        for (final frame in _allFrames(preset)) {
          expect(frame.tilesetId, 'animated-water-atlas');
        }
      });

      test('preserves empty frameTilesetId', () {
        final preset = _water(frameTilesetId: '');

        for (final frame in _allFrames(preset)) {
          expect(frame.tilesetId, '');
        }
      });

      test('applies custom common duration', () {
        final preset = _water(defaultDurationMs: 80);

        for (final frame in _allFrames(preset)) {
          expect(frame.durationMs, 80);
        }
      });

      test('applies per-frame durations', () {
        final preset = _water(frameCount: 3, frameDurationsMs: [50, 100, 150]);

        for (final mapping in preset.variants) {
          expect(
            mapping.frames.map((frame) => frame.durationMs),
            [50, 100, 150],
          );
        }
      });

      test('replaces null frame durations with the default duration', () {
        final preset = _water(
          frameCount: 3,
          defaultDurationMs: 90,
          frameDurationsMs: [50, null, 150],
        );

        for (final mapping in preset.variants) {
          expect(
            mapping.frames.map((frame) => frame.durationMs),
            [50, 90, 150],
          );
        }
      });
    });

    group('compatibility', () {
      test('is compatible with LegacyPathSurfaceView', () {
        final preset = _water(variants: [TerrainPathVariant.isolated]);

        final view = createLegacyPathSurfaceView(preset);

        expect(view.id, 'standard-water');
        expect(view.surfaceKind, PathSurfaceKind.water);
        expect(
          view.framesForVariant(TerrainPathVariant.isolated),
          hasLength(2),
        );
      });

      test('is compatible with LegacyProjectSurfaceCatalogView', () {
        final preset = _water(variants: [TerrainPathVariant.isolated]);
        final manifest = ProjectManifest(
          name: 'Test Project',
          maps: [],
          tilesets: [],
          pathPresets: [preset],
        surfaceCatalog: ProjectSurfaceCatalog(),);

        final catalog = createLegacyProjectSurfaceCatalogView(manifest);

        expect(catalog.pathSurfaces, hasLength(1));
        expect(catalog.pathSurfaceById('standard-water'), isNotNull);
        expect(
          catalog.pathSurfaceById('standard-water')?.surfaceKind,
          PathSurfaceKind.water,
        );
      });

      test('is compatible with resolveTileVisualFrameTimeline', () {
        final preset = _water(
          variants: [TerrainPathVariant.isolated],
          frameCount: 3,
          frameDurationsMs: [100, 100, 100],
        );

        final timeline = resolveTileVisualFrameTimeline(
          frames: preset.variants.single.frames,
          elapsedMs: 100,
          mode: TileVisualFrameTimelinePlaybackMode.loop,
        );

        expect(timeline.frameIndex, 1);
      });
    });

    group('validation delegation', () {
      test('delegates validation for empty id', () {
        _expectValidation(() => _water(id: ''));
        _expectValidation(() => _water(id: '   '));
      });

      test('delegates validation for empty name', () {
        _expectValidation(() => _water(name: ''));
        _expectValidation(() => _water(name: '   '));
      });

      test('delegates validation for empty tilesetId', () {
        _expectValidation(() => _water(tilesetId: ''));
        _expectValidation(() => _water(tilesetId: '   '));
      });

      test('delegates validation for negative firstColumn', () {
        _expectValidation(() => _water(firstColumn: -1));
      });

      test('delegates validation for negative startRow', () {
        _expectValidation(() => _water(startRow: -1));
      });

      test('delegates validation for empty variants', () {
        _expectValidation(() => _water(variants: []));
      });

      test('delegates validation for duplicate variants', () {
        _expectValidation(
          () => _water(
            variants: [
              TerrainPathVariant.isolated,
              TerrainPathVariant.isolated,
            ],
          ),
        );
      });

      test('delegates validation for invalid frameCount', () {
        _expectValidation(() => _water(frameCount: 0));
        _expectValidation(() => _water(frameCount: -1));
      });

      test('delegates validation for invalid source dimensions', () {
        for (final sourceWidth in [0, -1]) {
          _expectValidation(() => _water(sourceWidth: sourceWidth));
        }
        for (final sourceHeight in [0, -1]) {
          _expectValidation(() => _water(sourceHeight: sourceHeight));
        }
      });

      test('delegates validation for invalid defaultDurationMs', () {
        _expectValidation(() => _water(defaultDurationMs: 0));
        _expectValidation(() => _water(defaultDurationMs: -10));
      });

      test('delegates validation for frameDurationsMs length mismatch', () {
        _expectValidation(
          () => _water(frameCount: 3, frameDurationsMs: [100, 100]),
        );
        _expectValidation(
          () => _water(frameCount: 2, frameDurationsMs: [100, 100, 100]),
        );
      });

      test('delegates validation for non-positive frame durations', () {
        _expectValidation(
          () => _water(frameCount: 2, frameDurationsMs: [100, 0]),
        );
        _expectValidation(
          () => _water(frameCount: 2, frameDurationsMs: [100, -50]),
        );
      });
    });
  });
}

const _subset = [
  TerrainPathVariant.isolated,
  TerrainPathVariant.horizontal,
  TerrainPathVariant.vertical,
];

ProjectPathPreset _water({
  String id = 'standard-water',
  String name = 'Standard Water',
  String tilesetId = 'outdoor-water',
  String? categoryId,
  int sortOrder = 0,
  int firstColumn = 0,
  int startRow = 0,
  List<TerrainPathVariant> variants =
      standardTerrainPathVariantVerticalAtlasOrder,
  int frameCount = 2,
  int sourceWidth = 1,
  int sourceHeight = 1,
  String frameTilesetId = '',
  int defaultDurationMs = defaultPlacedElementAnimationFrameDurationMs,
  List<int?>? frameDurationsMs,
}) {
  return createStandardWaterPathPresetFromVerticalAtlas(
    id: id,
    name: name,
    tilesetId: tilesetId,
    categoryId: categoryId,
    sortOrder: sortOrder,
    firstColumn: firstColumn,
    startRow: startRow,
    variants: variants,
    frameCount: frameCount,
    sourceWidth: sourceWidth,
    sourceHeight: sourceHeight,
    frameTilesetId: frameTilesetId,
    defaultDurationMs: defaultDurationMs,
    frameDurationsMs: frameDurationsMs,
  );
}

List<TilesetVisualFrame> _allFrames(ProjectPathPreset preset) {
  return [
    for (final mapping in preset.variants) ...mapping.frames,
  ];
}

void _expectValidation(Object? Function() callback) {
  expect(callback, throwsA(isA<ValidationException>()));
}
