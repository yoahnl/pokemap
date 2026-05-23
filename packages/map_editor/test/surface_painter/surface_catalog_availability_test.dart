import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_painter/surface_catalog_availability.dart';

void main() {
  group('SurfaceCatalogAvailability', () {
    test('empty catalog explains missing paintable surface data', () {
      final availability = SurfaceCatalogAvailability.fromCatalog(
        const ProjectSurfaceCatalog.empty(),
      );

      expect(availability.atlasCount, 0);
      expect(availability.animationCount, 0);
      expect(availability.presetCount, 0);
      expect(availability.canPaint, isFalse);
      expect(availability.primaryMessage, 'Aucun preset Surface disponible');
      expect(
        availability.secondaryMessage,
        'Ajoutez au catalogue un atlas, des animations et un preset Surface.',
      );
    });

    test('atlas without animation explains the next authoring step', () {
      final availability = SurfaceCatalogAvailability.fromCatalog(
        ProjectSurfaceCatalog(atlases: [_atlas('water')]),
      );

      expect(availability.atlasCount, 1);
      expect(availability.animationCount, 0);
      expect(availability.presetCount, 0);
      expect(availability.canPaint, isFalse);
      expect(
        availability.primaryMessage,
        'Atlas Surface trouvé, mais aucune animation ni preset peignable.',
      );
      expect(
        availability.secondaryMessage,
        'Ajoutez des animations et un preset Surface au catalogue du projet.',
      );
    });

    test('animations without preset explains the observed 84-ter blocker', () {
      final availability = SurfaceCatalogAvailability.fromCatalog(
        ProjectSurfaceCatalog(
          atlases: [_atlas('water')],
          animations: List.generate(20, (index) => _animation('water-$index')),
        ),
      );

      expect(availability.atlasCount, 1);
      expect(availability.animationCount, 20);
      expect(availability.presetCount, 0);
      expect(availability.canPaint, isFalse);
      expect(
        availability.primaryMessage,
        'Animations Surface trouvées, mais aucun preset peignable.',
      );
      expect(
        availability.secondaryMessage,
        'Ajoutez un preset Surface au catalogue du projet pour rendre ces animations peignables.',
      );
    });

    test('presets make the Surface Painter available', () {
      final availability = SurfaceCatalogAvailability.fromCatalog(
        ProjectSurfaceCatalog(presets: [_preset('water')]),
      );

      expect(availability.presetCount, 1);
      expect(availability.canPaint, isTrue);
      expect(
          availability.primaryMessage, 'Sélectionnez une surface à peindre.');
      expect(
        availability.secondaryMessage,
        'Les presets sont les surfaces que vous pouvez peindre sur la map.',
      );
    });
  });
}

SurfaceAtlasGeometry _geometry() {
  return SurfaceAtlasGeometry(
    tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
    gridSize: SurfaceAtlasGridSize(columns: 2, rows: 2),
    layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
  );
}

ProjectSurfaceAtlas _atlas(String id) {
  return ProjectSurfaceAtlas(
    id: id,
    name: 'Atlas $id',
    tilesetId: 'tileset-$id',
    geometry: _geometry(),
  );
}

SurfaceAnimationTimeline _timeline() {
  return SurfaceAnimationTimeline(
    frames: [
      SurfaceAnimationFrame(
        tileRef: SurfaceAtlasTileRef(
          atlasId: 'water',
          column: 0,
          row: 0,
        ),
        durationMs: 100,
      ),
    ],
  );
}

ProjectSurfaceAnimation _animation(String id) {
  return ProjectSurfaceAnimation(
    id: id,
    name: 'Animation $id',
    timeline: _timeline(),
  );
}

ProjectSurfacePreset _preset(String id) {
  return ProjectSurfacePreset(
    id: id,
    name: 'Preset $id',
    variantAnimations: SurfaceVariantAnimationRefSet(
      refs: [
        SurfaceVariantAnimationRef(
          role: SurfaceVariantRole.isolated,
          animationId: '$id-isolated',
        ),
      ],
    ),
  );
}
