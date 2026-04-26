import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('LegacyPathSurfaceView', () {
    test('adapts a simple water ProjectPathPreset without changing values', () {
      // This is the smallest useful bridge from the current path preset model
      // toward a future Surface Engine view. The adapter must expose legacy
      // water as a surface-like read-only object without creating new persisted
      // Surface JSON.
      final sourceFrame = visualFrame(0, durationMs: 100);
      final preset = pathPreset(
        id: 'route-water',
        name: 'Route Water',
        surfaceKind: PathSurfaceKind.water,
        tilesetId: 'outdoor',
        categoryId: 'liquids',
        sortOrder: 12,
        variants: [
          mapping(TerrainPathVariant.isolated, [sourceFrame]),
        ],
      );

      final view = createLegacyPathSurfaceView(preset);

      expect(view.id, 'route-water');
      expect(view.name, 'Route Water');
      expect(view.surfaceKind, PathSurfaceKind.water);
      expect(view.tilesetId, 'outdoor');
      expect(view.categoryId, 'liquids');
      expect(view.sortOrder, 12);
      expect(view.hasVariants, isTrue);
      expect(view.hasAnimatedVariants, isFalse);
      expect(view.variants, hasLength(1));
      expect(view.variants.single.variant, TerrainPathVariant.isolated);
      expect(view.variants.single.frames.single, same(sourceFrame));
    });

    test('adapts a tallGrass preset as a legacy surface kind', () {
      // Tall grass will need gameplay semantics that differ from water, but the
      // existing path preset enum already identifies it. This adapter should
      // expose that fact without pretending tall grass and water behave alike.
      final preset = pathPreset(
        id: 'field-grass',
        name: 'Field Grass',
        surfaceKind: PathSurfaceKind.tallGrass,
        variants: [
          mapping(TerrainPathVariant.isolated, [visualFrame(1)]),
        ],
      );

      final view = createLegacyPathSurfaceView(preset);

      expect(view.surfaceKind, PathSurfaceKind.tallGrass);
      expect(view.id, 'field-grass');
      expect(view.tilesetId, '');
    });

    test('preserves variant order exactly as authored by the preset', () {
      // The source model is a list, not a canonical map. The adapter must keep
      // authoring order stable so future migration tools can compare legacy
      // presets to Surface definitions without hidden sorting.
      final preset = pathPreset(
        variants: [
          mapping(TerrainPathVariant.cross, [visualFrame(0)]),
          mapping(TerrainPathVariant.isolated, [visualFrame(1)]),
          mapping(TerrainPathVariant.cornerNE, [visualFrame(2)]),
          mapping(TerrainPathVariant.horizontal, [visualFrame(3)]),
        ],
      );

      final view = createLegacyPathSurfaceView(preset);

      expect(view.variants.map((variant) => variant.variant), [
        TerrainPathVariant.cross,
        TerrainPathVariant.isolated,
        TerrainPathVariant.cornerNE,
        TerrainPathVariant.horizontal,
      ]);
    });

    test('preserves frame order and frame durations exactly', () {
      // Animated water-like atlases depend on frame order. This bridge should
      // not normalize durations or resolve time; Lot 2 owns timeline behavior.
      final frames = [
        visualFrame(0, durationMs: 60),
        visualFrame(1, durationMs: 120),
        visualFrame(2, durationMs: 240),
      ];
      final preset = pathPreset(
        variants: [
          mapping(TerrainPathVariant.horizontal, frames),
        ],
      );

      final view = createLegacyPathSurfaceView(preset);

      expect(view.variants.single.frames, frames);
      expect(view.variants.single.frames.map((frame) => frame.durationMs), [
        60,
        120,
        240,
      ]);
      expect(view.variants.single.isAnimated, isTrue);
    });

    test('preserves per-frame tilesetId overrides', () {
      // Lot 3 characterized that missing frame overrides are represented by an
      // empty string. When an override is present, the view must keep it exactly
      // for future multi-atlas surface comparisons.
      final overrideFrame = visualFrame(
        7,
        tilesetId: 'animated-water-atlas',
        durationMs: 90,
      );
      final preset = pathPreset(
        variants: [
          mapping(TerrainPathVariant.cross, [overrideFrame]),
        ],
      );

      final view = createLegacyPathSurfaceView(preset);
      final frame = view.variants.single.frames.single;

      expect(frame, same(overrideFrame));
      expect(frame.tilesetId, 'animated-water-atlas');
      expect(frame.source, const TilesetSourceRect(x: 7, y: 0));
      expect(frame.durationMs, 90);
    });

    test('framesForVariant returns first matching mapping or an empty list',
        () {
      // Duplicate mappings are legal in the legacy list shape. V0 deliberately
      // does not merge or de-duplicate them; it returns the first match so the
      // behavior is simple, visible, and migration-safe.
      final firstHorizontal = [visualFrame(1, durationMs: 80)];
      final secondHorizontal = [visualFrame(2, durationMs: 160)];
      final cross = [visualFrame(3, durationMs: 200)];
      final preset = pathPreset(
        variants: [
          mapping(TerrainPathVariant.horizontal, firstHorizontal),
          mapping(TerrainPathVariant.cross, cross),
          mapping(TerrainPathVariant.horizontal, secondHorizontal),
        ],
      );

      final view = createLegacyPathSurfaceView(preset);

      expect(
        view.framesForVariant(TerrainPathVariant.horizontal),
        firstHorizontal,
      );
      expect(view.framesForVariant(TerrainPathVariant.cross), cross);
      expect(view.framesForVariant(TerrainPathVariant.cornerNE), isEmpty);
    });

    test('exposes only unmodifiable variant and frame lists', () {
      // The adapter is read-only. Callers may inspect legacy data, but they
      // should not be able to mutate the adapter and accidentally confuse later
      // migration/runtime code.
      final preset = pathPreset(
        variants: [
          mapping(TerrainPathVariant.isolated, [visualFrame(0)]),
        ],
      );

      final view = createLegacyPathSurfaceView(preset);

      expect(
        () => view.variants.add(
          LegacyPathSurfaceVariantView(
            variant: TerrainPathVariant.cross,
            frames: const [],
          ),
        ),
        throwsUnsupportedError,
      );
      expect(
        () => view.variants.first.frames.add(visualFrame(99)),
        throwsUnsupportedError,
      );
      expect(
        () => view
            .framesForVariant(TerrainPathVariant.cornerNE)
            .add(visualFrame(100)),
        throwsUnsupportedError,
      );
    });

    test('does not mutate the source ProjectPathPreset', () {
      // The source preset remains the legacy source of truth. Creating a view
      // must not alter its variants or frames.
      final sourceFrames = [
        visualFrame(0, durationMs: 100),
        visualFrame(1, durationMs: 120),
      ];
      final sourceVariants = [
        mapping(TerrainPathVariant.horizontal, sourceFrames),
      ];
      final preset = pathPreset(variants: sourceVariants);
      final beforeVariants = List<PathPresetVariantMapping>.from(
        preset.variants,
      );
      final beforeFrames = List<TilesetVisualFrame>.from(
        preset.variants.single.frames,
      );

      final view = createLegacyPathSurfaceView(preset);

      expect(preset.variants, beforeVariants);
      expect(preset.variants.single.frames, beforeFrames);
      expect(view.variants.single.frames, beforeFrames);
    });

    test('accepts a preset without variants', () {
      // Empty legacy path presets exist as authoring placeholders. The Surface
      // bridge should accept them and return empty, unmodifiable lookups instead
      // of inventing default autotile mappings.
      const preset = ProjectPathPreset(
        id: 'empty-path',
        name: 'Empty Path',
        surfaceKind: PathSurfaceKind.path,
      );

      final view = createLegacyPathSurfaceView(preset);

      expect(view.variants, isEmpty);
      expect(view.hasVariants, isFalse);
      expect(view.hasAnimatedVariants, isFalse);
      expect(view.framesForVariant(TerrainPathVariant.cross), isEmpty);
      expect(
        () => view.framesForVariant(TerrainPathVariant.cross).add(
              visualFrame(0),
            ),
        throwsUnsupportedError,
      );
    });

    test('hasAnimatedVariants is true when any variant has multiple frames',
        () {
      // Animation here is structural only: two frames means animated. Duration
      // validation and time resolution remain outside this adapter.
      final staticPreset = pathPreset(
        variants: [
          mapping(TerrainPathVariant.isolated, [visualFrame(0)]),
          mapping(TerrainPathVariant.cross, [visualFrame(1)]),
        ],
      );
      final animatedPreset = pathPreset(
        variants: [
          mapping(TerrainPathVariant.isolated, [visualFrame(0)]),
          mapping(TerrainPathVariant.cross, [
            visualFrame(1, durationMs: 90),
            visualFrame(2, durationMs: 110),
          ]),
        ],
      );

      expect(createLegacyPathSurfaceView(staticPreset).hasAnimatedVariants,
          isFalse);
      expect(createLegacyPathSurfaceView(animatedPreset).hasAnimatedVariants,
          isTrue);
    });

    test('LegacyPathSurfaceVariantView reports frame and animation state', () {
      // Variant views are intentionally tiny wrappers around a legacy
      // TerrainPathVariant and its frames. They do not infer fallback visuals.
      final empty = LegacyPathSurfaceVariantView(
        variant: TerrainPathVariant.cross,
        frames: const [],
      );
      final single = LegacyPathSurfaceVariantView(
        variant: TerrainPathVariant.cross,
        frames: [visualFrame(0)],
      );
      final animated = LegacyPathSurfaceVariantView(
        variant: TerrainPathVariant.cross,
        frames: [visualFrame(0), visualFrame(1)],
      );

      expect(empty.hasFrames, isFalse);
      expect(empty.isAnimated, isFalse);
      expect(single.hasFrames, isTrue);
      expect(single.isAnimated, isFalse);
      expect(animated.hasFrames, isTrue);
      expect(animated.isAnimated, isTrue);
    });
  });
}

ProjectPathPreset pathPreset({
  String id = 'legacy-path',
  String name = 'Legacy Path',
  PathSurfaceKind surfaceKind = PathSurfaceKind.path,
  String tilesetId = '',
  String? categoryId,
  int sortOrder = 0,
  List<PathPresetVariantMapping> variants = const [],
}) {
  return ProjectPathPreset(
    id: id,
    name: name,
    surfaceKind: surfaceKind,
    tilesetId: tilesetId,
    categoryId: categoryId,
    sortOrder: sortOrder,
    variants: variants,
  );
}

PathPresetVariantMapping mapping(
  TerrainPathVariant variant,
  List<TilesetVisualFrame> frames,
) {
  return PathPresetVariantMapping(
    variant: variant,
    frames: frames,
  );
}

TilesetVisualFrame visualFrame(
  int x, {
  String tilesetId = '',
  int? durationMs,
}) {
  return TilesetVisualFrame(
    tilesetId: tilesetId,
    source: TilesetSourceRect(x: x, y: 0),
    durationMs: durationMs,
  );
}
