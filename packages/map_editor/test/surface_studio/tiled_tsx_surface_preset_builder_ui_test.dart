import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/importers/tiled_tsx_animation_browser.dart';

void main() {
  testWidgets(
    'creates a preset from selected TSX animations only after explicit role mapping',
    (tester) async {
      final catalog = _miniCatalog();
      ProjectSurfaceCatalog? changedCatalog;

      await tester.pumpWidget(
        _wrap(
          TiledTsxAnimationBrowser(
            atlas: catalog.atlases.single,
            animations: catalog.animations,
            catalog: catalog,
            onSurfaceCatalogChanged: (next) => changedCatalog = next,
          ),
        ),
      );

      final createSurface = find.byKey(
        const ValueKey('tiled_tsx_animation_browser.create_surface'),
      );
      await tester.ensureVisible(createSurface);
      await tester.tap(createSurface);
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey('tiled_tsx_surface_preset_builder.panel'),
        ),
        findsNothing,
      );

      final tile99Checkbox = find.byKey(
        const ValueKey(
            'tiled_tsx_animation_browser.checkbox.tech-animations-tile-99'),
      );
      await tester.ensureVisible(tile99Checkbox);
      await tester.tap(tile99Checkbox);
      await tester.pumpAndSettle();

      await tester.ensureVisible(createSurface);
      await tester.tap(createSurface);
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey('tiled_tsx_surface_preset_builder.panel'),
        ),
        findsOneWidget,
      );

      final createPreset = find.byKey(
        const ValueKey('tiled_tsx_surface_preset_builder.create'),
      );
      await tester.ensureVisible(createPreset);
      await tester.tap(createPreset);
      await tester.pumpAndSettle();

      expect(find.text('Plein(center) obligatoire.'), findsOneWidget);
      expect(changedCatalog, isNull);

      await tester.enterText(
        find.byKey(const ValueKey('tiled_tsx_surface_preset_builder.id')),
        'water-tsx-surface',
      );
      await tester.enterText(
        find.byKey(const ValueKey('tiled_tsx_surface_preset_builder.name')),
        'Water TSX Surface',
      );
      expect(
        find.byKey(
          const ValueKey('tiled_tsx_surface_preset_builder.role.isolated'),
        ),
        findsNothing,
      );

      final pickIsolated = find.byKey(
        const ValueKey('tiled_tsx_role_mapping_builder.pick.isolated'),
      );
      await tester.ensureVisible(pickIsolated);
      await tester.tap(pickIsolated);
      await tester.pumpAndSettle();

      final tile99Option = find.byKey(
        const ValueKey(
          'tiled_tsx_role_mapping_builder.option.isolated.tech-animations-tile-99',
        ),
      );
      await tester.ensureVisible(tile99Option);
      await tester.tap(tile99Option);
      await tester.pumpAndSettle();

      await tester.ensureVisible(createPreset);
      await tester.tap(createPreset);
      await tester.pumpAndSettle();

      expect(changedCatalog, isNotNull);
      expect(changedCatalog!.presetCount, 1);
      expect(changedCatalog!.animationCount, catalog.animationCount);
      expect(
        changedCatalog!
            .presetById('water-tsx-surface')!
            .animationIdForRole(SurfaceVariantRole.isolated),
        'tech-animations-tile-99',
      );
    },
  );
}

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 1100,
          height: 900,
          child: child,
        ),
      ),
    ),
  );
}

ProjectSurfaceCatalog _miniCatalog() {
  return ProjectSurfaceCatalog(
    atlases: [
      ProjectSurfaceAtlas(
        id: 'tech-animations',
        name: 'TECH-Animations',
        tilesetId: 'tech-nature-animations',
        geometry: SurfaceAtlasGeometry(
          tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
          gridSize: SurfaceAtlasGridSize(columns: 98, rows: 109),
          layout: SurfaceAtlasLayout.grid,
        ),
      ),
    ],
    animations: [
      _animation('tech-animations-tile-99', 1, 1),
      _animation('tech-animations-tile-105', 7, 1),
    ],
  );
}

ProjectSurfaceAnimation _animation(String id, int column, int row) {
  return ProjectSurfaceAnimation(
    id: id,
    name: id,
    timeline: SurfaceAnimationTimeline(
      frames: [
        SurfaceAnimationFrame(
          tileRef: SurfaceAtlasTileRef(
            atlasId: 'tech-animations',
            column: column,
            row: row,
          ),
          durationMs: 100,
        ),
      ],
    ),
  );
}
