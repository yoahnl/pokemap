import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('createLegacyProjectPathPresetCenterPatternView', () {
    test('uses cross by default and creates a 1x1 center pattern', () {
      final isolatedFrames = [_frame(1)];
      final crossFrames = [_frame(99)];
      final preset = _preset(
        variants: [
          PathPresetVariantMapping(
            variant: TerrainPathVariant.isolated,
            frames: isolatedFrames,
          ),
          PathPresetVariantMapping(
            variant: TerrainPathVariant.cross,
            frames: crossFrames,
          ),
        ],
      );

      final view = createLegacyProjectPathPresetCenterPatternView(
        preset: preset,
      );

      expect(view.presetId, 'legacy-water');
      expect(view.presetName, 'Legacy Water');
      expect(view.defaultTilesetId, 'main_tileset');
      expect(view.surfaceKind, PathSurfaceKind.water);
      expect(view.categoryId, 'water-category');
      expect(view.sortOrder, 7);
      expect(view.sourceVariant, TerrainPathVariant.cross);
      expect(
        view.centerPattern.size,
        PathCenterPatternSize(width: 1, height: 1),
      );
      expect(view.centerPattern.cellAt(0, 0).frames, crossFrames);
      expect(view.centerPattern.cellAt(0, 0).frames, isNot(isolatedFrames));
    });

    test('does not assume isolated is the center', () {
      final preset = _preset(
        variants: [
          PathPresetVariantMapping(
            variant: TerrainPathVariant.isolated,
            frames: [_frame(1)],
          ),
          PathPresetVariantMapping(
            variant: TerrainPathVariant.cross,
            frames: [_frame(99)],
          ),
        ],
      );

      final view = createLegacyProjectPathPresetCenterPatternView(
        preset: preset,
      );

      expect(view.centerPattern.cellAt(0, 0).frames.single.source.x, 99);
    });

    test('can adapt an explicit variant for debug or compatibility', () {
      final preset = _preset(
        variants: [
          PathPresetVariantMapping(
            variant: TerrainPathVariant.isolated,
            frames: [_frame(1)],
          ),
          PathPresetVariantMapping(
            variant: TerrainPathVariant.cross,
            frames: [_frame(99)],
          ),
        ],
      );

      final view = createLegacyProjectPathPresetCenterPatternView(
        preset: preset,
        centerVariant: TerrainPathVariant.isolated,
      );

      expect(view.sourceVariant, TerrainPathVariant.isolated);
      expect(view.centerPattern.cellAt(0, 0).frames.single.source.x, 1);
    });

    test('preserves frame order and durations', () {
      final crossFrames = [
        _frame(10, durationMs: 80),
        _frame(11, durationMs: 120),
        _frame(12, durationMs: 160),
      ];
      final preset = _preset(
        variants: [
          PathPresetVariantMapping(
            variant: TerrainPathVariant.cross,
            frames: crossFrames,
          ),
        ],
      );

      final view = createLegacyProjectPathPresetCenterPatternView(
        preset: preset,
      );

      final frames = view.centerPattern.cellAt(0, 0).frames;
      expect(frames.map((frame) => frame.source.x), [10, 11, 12]);
      expect(frames.map((frame) => frame.durationMs), [80, 120, 160]);
    });

    test('exposes global tileset id and preserves frame tileset overrides', () {
      final crossFrames = [
        _frame(10),
        _frame(11, tilesetId: 'override_tileset'),
      ];
      final preset = _preset(
        tilesetId: 'main_tileset',
        variants: [
          PathPresetVariantMapping(
            variant: TerrainPathVariant.cross,
            frames: crossFrames,
          ),
        ],
      );

      final view = createLegacyProjectPathPresetCenterPatternView(
        preset: preset,
      );

      final frames = view.centerPattern.cellAt(0, 0).frames;
      expect(view.defaultTilesetId, 'main_tileset');
      expect(frames, crossFrames);
      expect(frames[0].tilesetId, '');
      expect(frames[1].tilesetId, 'override_tileset');
      expect(identical(frames[0], crossFrames[0]), isTrue);
      expect(identical(frames[1], crossFrames[1]), isTrue);
    });

    test('rejects missing center variant', () {
      final preset = _preset(
        variants: [
          PathPresetVariantMapping(
            variant: TerrainPathVariant.isolated,
            frames: [_frame(1)],
          ),
        ],
      );

      expect(
        () => createLegacyProjectPathPresetCenterPatternView(preset: preset),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects empty center variant frames', () {
      final preset = _preset(
        variants: [
          PathPresetVariantMapping(
            variant: TerrainPathVariant.cross,
            frames: const [],
          ),
        ],
      );

      expect(
        () => createLegacyProjectPathPresetCenterPatternView(preset: preset),
        throwsA(isA<ArgumentError>()),
      );
    });

    test(
      'does not mutate the source preset and copies frame lists into pattern',
      () {
        final crossFrames = [_frame(99)];
        final preset = _preset(
          variants: [
            PathPresetVariantMapping(
              variant: TerrainPathVariant.cross,
              frames: crossFrames,
            ),
          ],
        );
        final beforeVariants = List<PathPresetVariantMapping>.from(
          preset.variants,
        );

        final view = createLegacyProjectPathPresetCenterPatternView(
          preset: preset,
        );
        crossFrames.add(_frame(100));

        expect(preset.variants, beforeVariants);
        expect(view.centerPattern.cellAt(0, 0).frames.length, 1);
        expect(view.centerPattern.cellAt(0, 0).frames.single.source.x, 99);
      },
    );

    test('view has value equality and hashCode', () {
      final preset = _preset(
        variants: [
          PathPresetVariantMapping(
            variant: TerrainPathVariant.cross,
            frames: [_frame(99)],
          ),
          PathPresetVariantMapping(
            variant: TerrainPathVariant.isolated,
            frames: [_frame(1)],
          ),
        ],
      );

      final a = createLegacyProjectPathPresetCenterPatternView(preset: preset);
      final b = LegacyProjectPathPresetCenterPatternView(
        presetId: a.presetId,
        presetName: a.presetName,
        defaultTilesetId: a.defaultTilesetId,
        surfaceKind: a.surfaceKind,
        sourceVariant: a.sourceVariant,
        centerPattern: a.centerPattern,
        categoryId: a.categoryId,
        sortOrder: a.sortOrder,
      );
      final c = createLegacyProjectPathPresetCenterPatternView(
        preset: preset,
        centerVariant: TerrainPathVariant.isolated,
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });
  });
}

ProjectPathPreset _preset({
  required List<PathPresetVariantMapping> variants,
  String tilesetId = 'main_tileset',
}) {
  return ProjectPathPreset(
    id: 'legacy-water',
    name: 'Legacy Water',
    surfaceKind: PathSurfaceKind.water,
    categoryId: 'water-category',
    tilesetId: tilesetId,
    variants: variants,
    sortOrder: 7,
  );
}

TilesetVisualFrame _frame(
  int sourceX, {
  int? durationMs,
  String tilesetId = '',
}) {
  return TilesetVisualFrame(
    tilesetId: tilesetId,
    source: TilesetSourceRect(x: sourceX, y: 0),
    durationMs: durationMs,
  );
}
