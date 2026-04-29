import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/importers/tiled_tsx_catalog_append.dart';

void main() {
  group('appendTiledTsxSurfaceImportToCatalog', () {
    test('adds atlas and animations to an empty catalog without presets', () {
      final result = appendTiledTsxSurfaceImportToCatalog(
        catalog: ProjectSurfaceCatalog(),
        atlas: _atlas('tech-animations'),
        animations: [_animation('tech-animations-tile-99')],
      );

      expect(result.hasErrors, isFalse);
      expect(result.catalog, isNotNull);
      expect(result.catalog!.atlasCount, 1);
      expect(result.catalog!.animationCount, 1);
      expect(result.catalog!.presetCount, 0);
      expect(result.catalog!.containsAtlas('tech-animations'), isTrue);
      expect(
        result.catalog!.containsAnimation('tech-animations-tile-99'),
        isTrue,
      );
    });

    test('preserves existing presets and never creates a preset', () {
      final preset = _preset('existing-water');
      final catalog = ProjectSurfaceCatalog(
        atlases: [_atlas('existing-atlas')],
        animations: [_animation('existing-animation')],
        presets: [preset],
      );

      final result = appendTiledTsxSurfaceImportToCatalog(
        catalog: catalog,
        atlas: _atlas('tech-animations'),
        animations: [_animation('tech-animations-tile-99')],
      );

      expect(result.hasErrors, isFalse);
      expect(result.catalog!.atlases.map((atlas) => atlas.id), [
        'existing-atlas',
        'tech-animations',
      ]);
      expect(result.catalog!.animations.map((animation) => animation.id), [
        'existing-animation',
        'tech-animations-tile-99',
      ]);
      expect(result.catalog!.presets, [preset]);
      expect(result.catalog!.presetCount, 1);
    });

    test('rejects duplicate atlas id', () {
      final result = appendTiledTsxSurfaceImportToCatalog(
        catalog: ProjectSurfaceCatalog(
          atlases: [_atlas('tech-animations')],
        ),
        atlas: _atlas('tech-animations'),
        animations: [_animation('tech-animations-tile-99')],
      );

      expect(result.hasErrors, isTrue);
      expect(result.catalog, isNull);
      expect(
        result.errors,
        contains('Atlas TSX déjà présent dans le catalogue : tech-animations.'),
      );
    });

    test('rejects duplicate animation id', () {
      final result = appendTiledTsxSurfaceImportToCatalog(
        catalog: ProjectSurfaceCatalog(
          animations: [_animation('tech-animations-tile-99')],
        ),
        atlas: _atlas('tech-animations'),
        animations: [_animation('tech-animations-tile-99')],
      );

      expect(result.hasErrors, isTrue);
      expect(result.catalog, isNull);
      expect(
        result.errors,
        contains(
          'Animation TSX déjà présente dans le catalogue : tech-animations-tile-99.',
        ),
      );
    });
  });
}

ProjectSurfaceAtlas _atlas(String id) {
  return ProjectSurfaceAtlas(
    id: id,
    name: id,
    tilesetId: 'tech-nature-animations',
    geometry: SurfaceAtlasGeometry(
      tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
      gridSize: SurfaceAtlasGridSize(columns: 2, rows: 2),
    ),
  );
}

ProjectSurfaceAnimation _animation(String id) {
  return ProjectSurfaceAnimation(
    id: id,
    name: id,
    timeline: SurfaceAnimationTimeline(
      frames: [
        SurfaceAnimationFrame(
          tileRef: SurfaceAtlasTileRef(
            atlasId: 'tech-animations',
            column: 0,
            row: 0,
          ),
          durationMs: 100,
        ),
      ],
    ),
  );
}

ProjectSurfacePreset _preset(String id) {
  return ProjectSurfacePreset(
    id: id,
    name: id,
    variantAnimations: SurfaceVariantAnimationRefSet(
      refs: [
        SurfaceVariantAnimationRef(
          role: SurfaceVariantRole.isolated,
          animationId: 'existing-animation',
        ),
      ],
    ),
  );
}
