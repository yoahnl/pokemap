import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_atlas_editing.dart';

void main() {
  group('surface_studio_atlas_editing (Lot 68–69)', () {
    test('countAnimationsReferencingAtlasId compte par animation', () {
      final g = SurfaceAtlasGeometry(
        tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
        gridSize: SurfaceAtlasGridSize(columns: 1, rows: 1),
        layout: SurfaceAtlasLayout.grid,
      );
      final a1 = ProjectSurfaceAtlas(
        id: 'A',
        name: 'a',
        tilesetId: 't',
        geometry: g,
      );
      final a2 = ProjectSurfaceAtlas(
        id: 'B',
        name: 'b',
        tilesetId: 't',
        geometry: g,
      );
      final f1 = SurfaceAnimationFrame(
        tileRef: SurfaceAtlasTileRef(atlasId: 'A', column: 0, row: 0),
        durationMs: 1,
      );
      final f2 = SurfaceAnimationFrame(
        tileRef: SurfaceAtlasTileRef(atlasId: 'A', column: 0, row: 0),
        durationMs: 1,
      );
      final anim1 = ProjectSurfaceAnimation(
        id: 'm1',
        name: 'm1',
        timeline: SurfaceAnimationTimeline(frames: [f1]),
      );
      final anim2 = ProjectSurfaceAnimation(
        id: 'm2',
        name: 'm2',
        timeline: SurfaceAnimationTimeline(frames: [f2, f1]),
      );
      final anim3 = ProjectSurfaceAnimation(
        id: 'm3',
        name: 'm3',
        timeline: SurfaceAnimationTimeline(frames: [
          SurfaceAnimationFrame(
            tileRef: SurfaceAtlasTileRef(atlasId: 'B', column: 0, row: 0),
            durationMs: 1,
          ),
        ]),
      );
      final cat = ProjectSurfaceCatalog(
        atlases: [a1, a2],
        animations: [anim1, anim2, anim3],
        presets: const [],
      );
      expect(countAnimationsReferencingAtlasId(cat, 'A'), 2);
      expect(countAnimationsReferencingAtlasId(cat, 'B'), 1);
    });

    test('replaceAtlasInCatalogInPlace préserve ordre, animations, presets',
        () {
      final g0 = SurfaceAtlasGeometry(
        tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
        gridSize: SurfaceAtlasGridSize(columns: 2, rows: 2),
        layout: SurfaceAtlasLayout.grid,
      );
      final g1 = SurfaceAtlasGeometry(
        tileSize: SurfaceAtlasTileSize(width: 16, height: 16),
        gridSize: SurfaceAtlasGridSize(columns: 2, rows: 2),
        layout: SurfaceAtlasLayout.grid,
      );
      final a1 = ProjectSurfaceAtlas(
        id: 'x',
        name: 'n1',
        tilesetId: 't',
        geometry: g0,
      );
      final a2 = ProjectSurfaceAtlas(
        id: 'y',
        name: 'n2',
        tilesetId: 't',
        geometry: g0,
      );
      final anim = ProjectSurfaceAnimation(
        id: 'anim',
        name: 'anim',
        timeline: SurfaceAnimationTimeline(frames: [
          SurfaceAnimationFrame(
            tileRef: SurfaceAtlasTileRef(atlasId: 'x', column: 0, row: 0),
            durationMs: 1,
          ),
        ]),
      );
      var cat = ProjectSurfaceCatalog(
        atlases: [a1, a2],
        animations: [anim],
        presets: const [],
      );
      final updated = ProjectSurfaceAtlas(
        id: 'x',
        name: 'renamed',
        tilesetId: 't2',
        geometry: g1,
        sortOrder: 0,
      );
      cat = replaceAtlasInCatalogInPlace(cat, updated);
      expect(cat.atlases.length, 2);
      expect(cat.atlases[0].id, 'x');
      expect(cat.atlases[0].name, 'renamed');
      expect(cat.atlases[0].tilesetId, 't2');
      expect(cat.atlases[0].geometry.tileSize.width, 16);
      expect(cat.atlases[1].id, 'y');
      expect(cat.animations.single.id, 'anim');
      expect(cat.presets, isEmpty);
    });

    test('removeAtlasIdFromWorkCatalog lève si absent', () {
      final cat = ProjectSurfaceCatalog();
      expect(
        () => removeAtlasIdFromWorkCatalog(cat, 'nope'),
        throwsA(isA<StateError>()),
      );
    });
  });
}
