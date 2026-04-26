import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('LegacyTerrainSurfaceView', () {
    test('adapts a simple grass ProjectTerrainPreset without changing values',
        () {
      // This is the terrain-side mirror of LegacyPathSurfaceView. It lets
      // future Surface Engine work inspect a legacy terrain preset as a
      // surface-like read-only object without creating persisted Surface JSON.
      final sourceFrame = visualFrame(0, durationMs: 100);
      final preset = terrainPreset(
        id: 'soft-grass',
        name: 'Soft Grass',
        terrainType: TerrainType.grass,
        tilesetId: 'outdoor',
        categoryId: 'nature',
        sortOrder: 9,
        variants: [
          terrainVariant([sourceFrame], weight: 1),
        ],
      );

      final view = createLegacyTerrainSurfaceView(preset);

      expect(view.id, 'soft-grass');
      expect(view.name, 'Soft Grass');
      expect(view.terrainType, TerrainType.grass);
      expect(view.tilesetId, 'outdoor');
      expect(view.categoryId, 'nature');
      expect(view.sortOrder, 9);
      expect(view.hasVariants, isTrue);
      expect(view.hasAnimatedVariants, isFalse);
      expect(view.hasWeightedVariants, isFalse);
      expect(view.variants, hasLength(1));
      expect(view.variants.single.weight, 1);
      expect(view.variants.single.frames.single, same(sourceFrame));
    });

    test('adapts multiple TerrainType values without PathSurfaceKind', () {
      // Terrain legacy surfaces are keyed by TerrainType, not PathSurfaceKind.
      // Keeping those concepts separate avoids folding terrain and paths into
      // one premature abstraction before the Surface model exists.
      final grass = createLegacyTerrainSurfaceView(
        terrainPreset(
          id: 'grass',
          terrainType: TerrainType.grass,
          variants: [
            terrainVariant([visualFrame(0)])
          ],
        ),
      );
      final sand = createLegacyTerrainSurfaceView(
        terrainPreset(
          id: 'sand',
          terrainType: TerrainType.sand,
          variants: [
            terrainVariant([visualFrame(1)])
          ],
        ),
      );
      final rock = createLegacyTerrainSurfaceView(
        terrainPreset(
          id: 'rock',
          terrainType: TerrainType.rock,
          variants: [
            terrainVariant([visualFrame(2)])
          ],
        ),
      );

      expect(grass.terrainType, TerrainType.grass);
      expect(sand.terrainType, TerrainType.sand);
      expect(rock.terrainType, TerrainType.rock);
    });

    test('preserves variant order exactly as authored by the preset', () {
      // Terrain variants are authored as a weighted list. V0 must not sort by
      // weight, shuffle for distribution, or collapse variants into a lookup.
      final preset = terrainPreset(
        variants: [
          terrainVariant([visualFrame(0)], weight: 3),
          terrainVariant([visualFrame(1)], weight: 1),
          terrainVariant([visualFrame(2)], weight: 7),
        ],
      );

      final view = createLegacyTerrainSurfaceView(preset);

      expect(view.variants.map((variant) => variant.weight), [3, 1, 7]);
      expect(view.variants.map((variant) => variant.frames.single.source.x), [
        0,
        1,
        2,
      ]);
    });

    test('preserves frame order and frame durations exactly', () {
      // Animated terrain-like atlases depend on frame order. This adapter only
      // carries frames; it does not normalize durations or resolve time.
      final frames = [
        visualFrame(0, durationMs: 60),
        visualFrame(1, durationMs: 120),
        visualFrame(2, durationMs: 240),
      ];
      final preset = terrainPreset(
        variants: [
          terrainVariant(frames),
        ],
      );

      final view = createLegacyTerrainSurfaceView(preset);

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
      // empty string. When terrain frames do carry an override, the terrain view
      // must keep it exactly for future multi-atlas surface comparisons.
      final overrideFrame = visualFrame(
        7,
        tilesetId: 'animated-terrain-atlas',
        durationMs: 90,
      );
      final preset = terrainPreset(
        variants: [
          terrainVariant([overrideFrame], weight: 2),
        ],
      );

      final view = createLegacyTerrainSurfaceView(preset);
      final frame = view.variants.single.frames.single;

      expect(frame, same(overrideFrame));
      expect(frame.tilesetId, 'animated-terrain-atlas');
      expect(frame.source, const TilesetSourceRect(x: 7, y: 0));
      expect(frame.durationMs, 90);
    });

    test('preserves variant weights exactly', () {
      // TerrainPresetVariant.weight is meaningful legacy authoring data. The
      // adapter should expose it as-is and should not normalize distribution.
      final preset = terrainPreset(
        variants: [
          terrainVariant([visualFrame(0)], weight: 1),
          terrainVariant([visualFrame(1)], weight: 4),
          terrainVariant([visualFrame(2)], weight: 9),
        ],
      );

      final view = createLegacyTerrainSurfaceView(preset);

      expect(view.variants.map((variant) => variant.weight), [1, 4, 9]);
      expect(view.hasWeightedVariants, isTrue);
    });

    test('exposes only unmodifiable variant and frame lists', () {
      // The adapter is read-only. Callers may inspect legacy terrain data, but
      // they should not be able to mutate the adapter and confuse later
      // migration/runtime code.
      final preset = terrainPreset(
        variants: [
          terrainVariant([visualFrame(0)]),
        ],
      );

      final view = createLegacyTerrainSurfaceView(preset);

      expect(
        () => view.variants.add(
          LegacyTerrainSurfaceVariantView(
            frames: const [],
            weight: 1,
          ),
        ),
        throwsUnsupportedError,
      );
      expect(
        () => view.variants.first.frames.add(visualFrame(99)),
        throwsUnsupportedError,
      );
    });

    test('does not mutate the source ProjectTerrainPreset', () {
      // The source preset remains the legacy source of truth. Creating a view
      // must not alter its variants, weights, or frames.
      final sourceFrames = [
        visualFrame(0, durationMs: 100),
        visualFrame(1, durationMs: 120),
      ];
      final sourceVariants = [
        terrainVariant(sourceFrames, weight: 5),
      ];
      final preset = terrainPreset(variants: sourceVariants);
      final beforeVariants = List<TerrainPresetVariant>.from(preset.variants);
      final beforeFrames = List<TilesetVisualFrame>.from(
        preset.variants.single.frames,
      );

      final view = createLegacyTerrainSurfaceView(preset);

      expect(preset.variants, beforeVariants);
      expect(preset.variants.single.weight, 5);
      expect(preset.variants.single.frames, beforeFrames);
      expect(view.variants.single.weight, 5);
      expect(view.variants.single.frames, beforeFrames);
    });

    test('accepts a preset without variants', () {
      // Empty terrain presets can exist as authoring placeholders. The Surface
      // bridge should accept them instead of inventing a fallback variant.
      const preset = ProjectTerrainPreset(
        id: 'empty-terrain',
        name: 'Empty Terrain',
        terrainType: TerrainType.grass,
      );

      final view = createLegacyTerrainSurfaceView(preset);

      expect(view.variants, isEmpty);
      expect(view.hasVariants, isFalse);
      expect(view.hasAnimatedVariants, isFalse);
      expect(view.hasWeightedVariants, isFalse);
      expect(
        () => view.variants.add(
          LegacyTerrainSurfaceVariantView(
            frames: const [],
            weight: 1,
          ),
        ),
        throwsUnsupportedError,
      );
    });

    test('hasAnimatedVariants is true when any variant has multiple frames',
        () {
      // Animation here is structural only: two frames means animated. Duration
      // validation and time resolution remain outside this adapter.
      final staticPreset = terrainPreset(
        variants: [
          terrainVariant([visualFrame(0)]),
          terrainVariant([visualFrame(1)]),
        ],
      );
      final animatedPreset = terrainPreset(
        variants: [
          terrainVariant([visualFrame(0)]),
          terrainVariant([
            visualFrame(1, durationMs: 90),
            visualFrame(2, durationMs: 110),
          ]),
        ],
      );

      expect(createLegacyTerrainSurfaceView(staticPreset).hasAnimatedVariants,
          isFalse);
      expect(createLegacyTerrainSurfaceView(animatedPreset).hasAnimatedVariants,
          isTrue);
    });

    test('LegacyTerrainSurfaceVariantView reports frame and animation state',
        () {
      // Variant views are intentionally tiny wrappers around terrain frames and
      // weight. They do not infer fallback visuals or resolve animation.
      final empty = LegacyTerrainSurfaceVariantView(
        frames: const [],
        weight: 1,
      );
      final single = LegacyTerrainSurfaceVariantView(
        frames: [visualFrame(0)],
        weight: 1,
      );
      final animated = LegacyTerrainSurfaceVariantView(
        frames: [visualFrame(0), visualFrame(1)],
        weight: 1,
      );

      expect(empty.hasFrames, isFalse);
      expect(empty.isAnimated, isFalse);
      expect(single.hasFrames, isTrue);
      expect(single.isAnimated, isFalse);
      expect(animated.hasFrames, isTrue);
      expect(animated.isAnimated, isTrue);
    });

    test('hasWeightedVariants compares weights to the model default of 1', () {
      // The audited default for TerrainPresetVariant.weight is @Default(1).
      // V0 documents that only non-default weights make a terrain surface view
      // "weighted"; all-default variants are treated as unweighted.
      final defaultWeightedPreset = terrainPreset(
        variants: [
          terrainVariant([visualFrame(0)]),
          terrainVariant([visualFrame(1)], weight: 1),
        ],
      );
      final customWeightedPreset = terrainPreset(
        variants: [
          terrainVariant([visualFrame(0)]),
          terrainVariant([visualFrame(1)], weight: 2),
        ],
      );

      expect(
          createLegacyTerrainSurfaceView(defaultWeightedPreset)
              .hasWeightedVariants,
          isFalse);
      expect(
          createLegacyTerrainSurfaceView(customWeightedPreset)
              .hasWeightedVariants,
          isTrue);
    });
  });
}

ProjectTerrainPreset terrainPreset({
  String id = 'legacy-terrain',
  String name = 'Legacy Terrain',
  TerrainType terrainType = TerrainType.grass,
  String tilesetId = '',
  String? categoryId,
  int sortOrder = 0,
  List<TerrainPresetVariant> variants = const [],
}) {
  return ProjectTerrainPreset(
    id: id,
    name: name,
    terrainType: terrainType,
    tilesetId: tilesetId,
    categoryId: categoryId,
    sortOrder: sortOrder,
    variants: variants,
  );
}

TerrainPresetVariant terrainVariant(
  List<TilesetVisualFrame> frames, {
  int weight = 1,
}) {
  return TerrainPresetVariant(
    frames: frames,
    weight: weight,
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
