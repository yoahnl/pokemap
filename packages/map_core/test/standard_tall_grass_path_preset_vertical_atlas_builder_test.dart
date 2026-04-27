// ignore_for_file: prefer_const_literals_to_create_immutables

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  // Lot 19: same vertical-atlas contract as Lots 16–18; legacy [surfaceKind] is
  // always [PathSurfaceKind.tallGrass]. Encounters, overlay, and step rustle
  // are out of scope—this is only the standard animated path preset builder.
  group('createStandardTallGrassPathPresetFromVerticalAtlas', () {
    group('preset generation', () {
      test(
          'generates a tallGrass ProjectPathPreset with the full standard layout',
          () {
        final preset = _tallGrass(frameCount: 4);

        expect(preset.id, 'standard-tall-grass');
        expect(preset.name, 'Standard Tall Grass');
        expect(preset.surfaceKind, PathSurfaceKind.tallGrass);
        expect(preset.tilesetId, 'field-tall-grass');
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

      test('API specialization: generated presets are always tallGrass', () {
        // No public [surfaceKind]: callers cannot pick another kind via this
        // entry point; specialization is by function name and fixed enum.
        final preset = _tallGrass();

        expect(preset.surfaceKind, PathSurfaceKind.tallGrass);
      });

      test('preserves categoryId and sortOrder', () {
        final preset =
            _tallGrass(categoryId: 'tall-grass-category', sortOrder: 42);

        expect(preset.categoryId, 'tall-grass-category');
        expect(preset.sortOrder, 42);
      });

      test('respects firstColumn', () {
        final preset = _tallGrass(firstColumn: 10);

        expect(preset.variants.first.frames.first.source.x, 10);
        expect(preset.variants[1].frames.first.source.x, 11);
        expect(
          preset.variants.last.frames.first.source.x,
          10 + standardTerrainPathVariantVerticalAtlasOrder.length - 1,
        );
      });

      test('respects startRow', () {
        final preset = _tallGrass(startRow: 7, frameCount: 3);

        for (final mapping in preset.variants) {
          expect(mapping.frames.map((frame) => frame.source.y), [7, 8, 9]);
        }
      });

      test('generates a variant sub-layout', () {
        final preset = _tallGrass(variants: _subset);

        expect(preset.variants, hasLength(3));
        expect(preset.variants.map((mapping) => mapping.variant), _subset);
        expect(
          preset.variants.map((mapping) => mapping.frames.first.source.x),
          [0, 1, 2],
        );
      });

      test('generates a variant sub-layout with firstColumn', () {
        final preset = _tallGrass(variants: _subset, firstColumn: 20);

        expect(
          preset.variants.map((mapping) => mapping.frames.first.source.x),
          [20, 21, 22],
        );
      });

      test('respects sourceWidth and sourceHeight', () {
        final preset = _tallGrass(sourceWidth: 2, sourceHeight: 3);

        for (final frame in _allFrames(preset)) {
          expect(frame.source.width, 2);
          expect(frame.source.height, 3);
        }
      });

      test('distinguishes preset tilesetId from frameTilesetId', () {
        final preset = _tallGrass(
          tilesetId: 'main-tall-grass-tileset',
          frameTilesetId: 'animated-tall-grass-atlas',
        );

        expect(preset.tilesetId, 'main-tall-grass-tileset');
        for (final frame in _allFrames(preset)) {
          expect(frame.tilesetId, 'animated-tall-grass-atlas');
        }
      });

      test('preserves empty frameTilesetId', () {
        final preset = _tallGrass(frameTilesetId: '');

        for (final frame in _allFrames(preset)) {
          expect(frame.tilesetId, '');
        }
      });

      test('applies custom common duration', () {
        final preset = _tallGrass(defaultDurationMs: 80);

        for (final frame in _allFrames(preset)) {
          expect(frame.durationMs, 80);
        }
      });

      test('applies per-frame durations', () {
        final preset =
            _tallGrass(frameCount: 3, frameDurationsMs: [50, 100, 150]);

        for (final mapping in preset.variants) {
          expect(
            mapping.frames.map((frame) => frame.durationMs),
            [50, 100, 150],
          );
        }
      });

      test('replaces null frame durations with the default duration', () {
        final preset = _tallGrass(
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
        final preset = _tallGrass(variants: [TerrainPathVariant.isolated]);

        final view = createLegacyPathSurfaceView(preset);

        expect(view.id, 'standard-tall-grass');
        expect(view.surfaceKind, PathSurfaceKind.tallGrass);
        expect(
          view.framesForVariant(TerrainPathVariant.isolated),
          hasLength(2),
        );
      });

      test('is compatible with LegacyProjectSurfaceCatalogView', () {
        final preset = _tallGrass(variants: [TerrainPathVariant.isolated]);
        final manifest = ProjectManifest(
          name: 'Test Project',
          maps: [],
          tilesets: [],
          pathPresets: [preset],
        surfaceCatalog: ProjectSurfaceCatalog(),);

        final catalog = createLegacyProjectSurfaceCatalogView(manifest);

        expect(catalog.pathSurfaces, hasLength(1));
        expect(catalog.pathSurfaceById('standard-tall-grass'), isNotNull);
        expect(
          catalog.pathSurfaceById('standard-tall-grass')?.surfaceKind,
          PathSurfaceKind.tallGrass,
        );
      });

      test('is compatible with resolveTileVisualFrameTimeline', () {
        final preset = _tallGrass(
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
        _expectValidation(() => _tallGrass(id: ''));
        _expectValidation(() => _tallGrass(id: '   '));
      });

      test('delegates validation for empty name', () {
        _expectValidation(() => _tallGrass(name: ''));
        _expectValidation(() => _tallGrass(name: '   '));
      });

      test('delegates validation for empty tilesetId', () {
        _expectValidation(() => _tallGrass(tilesetId: ''));
        _expectValidation(() => _tallGrass(tilesetId: '   '));
      });

      test('delegates validation for negative firstColumn', () {
        _expectValidation(() => _tallGrass(firstColumn: -1));
      });

      test('delegates validation for negative startRow', () {
        _expectValidation(() => _tallGrass(startRow: -1));
      });

      test('delegates validation for empty variants', () {
        _expectValidation(() => _tallGrass(variants: []));
      });

      test('delegates validation for duplicate variants', () {
        _expectValidation(
          () => _tallGrass(
            variants: [
              TerrainPathVariant.isolated,
              TerrainPathVariant.isolated,
            ],
          ),
        );
      });

      test('delegates validation for invalid frameCount', () {
        _expectValidation(() => _tallGrass(frameCount: 0));
        _expectValidation(() => _tallGrass(frameCount: -1));
      });

      test('delegates validation for invalid source dimensions', () {
        for (final sourceWidth in [0, -1]) {
          _expectValidation(() => _tallGrass(sourceWidth: sourceWidth));
        }
        for (final sourceHeight in [0, -1]) {
          _expectValidation(() => _tallGrass(sourceHeight: sourceHeight));
        }
      });

      test('delegates validation for invalid defaultDurationMs', () {
        _expectValidation(() => _tallGrass(defaultDurationMs: 0));
        _expectValidation(() => _tallGrass(defaultDurationMs: -10));
      });

      test('delegates validation for frameDurationsMs length mismatch', () {
        _expectValidation(
          () => _tallGrass(frameCount: 3, frameDurationsMs: [100, 100]),
        );
        _expectValidation(
          () => _tallGrass(frameCount: 2, frameDurationsMs: [100, 100, 100]),
        );
      });

      test('delegates validation for non-positive frame durations', () {
        _expectValidation(
          () => _tallGrass(frameCount: 2, frameDurationsMs: [100, 0]),
        );
        _expectValidation(
          () => _tallGrass(frameCount: 2, frameDurationsMs: [100, -50]),
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

ProjectPathPreset _tallGrass({
  String id = 'standard-tall-grass',
  String name = 'Standard Tall Grass',
  String tilesetId = 'field-tall-grass',
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
  return createStandardTallGrassPathPresetFromVerticalAtlas(
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
