// Tests widget — sélection Surface Studio (Lot 58).
// `map_core` public uniquement.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_animation_detail_view.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_atlas_detail_view.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_catalog_browser.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_preset_detail_view.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_selection.dart';

void main() {
  group('Fiches sélectionnables (Lot 58)', () {
    testWidgets('8. atlas sans badge si none', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAtlasDetailView(
            readModel: _oneWaterAtlasModel(),
            selection: const SurfaceStudioSelection.none(),
            onSelectionChanged: (_) {},
          ),
        ),
      );
      expect(find.text('Atlas sélectionné'), findsNothing);
    });

    testWidgets('9. atlas affiche état sélectionné', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAtlasDetailView(
            readModel: _oneWaterAtlasModel(),
            selection: SurfaceStudioSelection.atlas('water-atlas'),
            onSelectionChanged: (_) {},
          ),
        ),
      );
      expect(find.text('Atlas sélectionné'), findsOneWidget);
    });

    testWidgets('10. tap atlas déclenche callback', (tester) async {
      SurfaceStudioSelection? captured;
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAtlasDetailView(
            readModel: _oneWaterAtlasModel(),
            selection: const SurfaceStudioSelection.none(),
            onSelectionChanged: (s) => captured = s,
          ),
        ),
      );
      await tester.tap(find.text('Water Atlas'));
      expect(
        captured,
        SurfaceStudioSelection.atlas('water-atlas'),
      );
    });

    testWidgets('11. animation affiche état sélectionné', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAnimationDetailView(
            readModel: _minimalWaterModel(),
            selection: SurfaceStudioSelection.animation('water-isolated-loop'),
            onSelectionChanged: (_) {},
          ),
        ),
      );
      expect(find.text('Animation sélectionnée'), findsOneWidget);
    });

    testWidgets('12. tap animation déclenche callback', (tester) async {
      SurfaceStudioSelection? captured;
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAnimationDetailView(
            readModel: _minimalWaterModel(),
            selection: const SurfaceStudioSelection.none(),
            onSelectionChanged: (s) => captured = s,
          ),
        ),
      );
      await tester.tap(find.text('Water Isolated Loop'));
      expect(
        captured,
        SurfaceStudioSelection.animation('water-isolated-loop'),
      );
    });

    testWidgets('13. preset affiche état sélectionné', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPresetDetailView(
            readModel: _minimalWaterModel(),
            selection: SurfaceStudioSelection.preset('water-surface'),
            onSelectionChanged: (_) {},
          ),
        ),
      );
      expect(find.text('Preset sélectionné'), findsOneWidget);
    });

    testWidgets('14. tap preset déclenche callback', (tester) async {
      SurfaceStudioSelection? captured;
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPresetDetailView(
            readModel: _minimalWaterModel(),
            selection: const SurfaceStudioSelection.none(),
            onSelectionChanged: (s) => captured = s,
          ),
        ),
      );
      final target = find.text('Water Surface');
      await tester.ensureVisible(target);
      await tester.pump();
      await tester.tap(target);
      expect(
        captured,
        SurfaceStudioSelection.preset('water-surface'),
      );
    });
  });

  group('SurfaceStudioCatalogBrowser sélection (Lot 58)', () {
    testWidgets('15. browser transmet sélection atlas', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioCatalogBrowser(
            readModel: _minimalWaterModel(),
            selection: SurfaceStudioSelection.atlas('water-atlas'),
            onSelectionChanged: (_) {},
          ),
        ),
      );
      expect(find.text('Atlas sélectionné'), findsOneWidget);
    });

    testWidgets('16. browser transmet sélection animation', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioCatalogBrowser(
            readModel: _minimalWaterModel(),
            selection: SurfaceStudioSelection.animation('water-isolated-loop'),
            onSelectionChanged: (_) {},
          ),
        ),
      );
      expect(find.text('Animation sélectionnée'), findsOneWidget);
    });

    testWidgets('17. browser transmet sélection preset', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioCatalogBrowser(
            readModel: _minimalWaterModel(),
            selection: SurfaceStudioSelection.preset('water-surface'),
            onSelectionChanged: (_) {},
          ),
        ),
      );
      expect(find.text('Preset sélectionné'), findsOneWidget);
    });

    testWidgets('18. browser remonte tap atlas', (tester) async {
      SurfaceStudioSelection? last;
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioCatalogBrowser(
            readModel: _minimalWaterModel(),
            selection: const SurfaceStudioSelection.none(),
            onSelectionChanged: (s) => last = s,
          ),
        ),
      );
      await tester.tap(find.text('Water Atlas'));
      expect(last, SurfaceStudioSelection.atlas('water-atlas'));
    });

    testWidgets('19. browser remonte tap animation', (tester) async {
      SurfaceStudioSelection? last;
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioCatalogBrowser(
            readModel: _minimalWaterModel(),
            selection: const SurfaceStudioSelection.none(),
            onSelectionChanged: (s) => last = s,
          ),
        ),
      );
      await tester.tap(find.text('Water Isolated Loop'));
      expect(last, SurfaceStudioSelection.animation('water-isolated-loop'));
    });

    testWidgets('20. browser remonte tap preset', (tester) async {
      SurfaceStudioSelection? last;
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioCatalogBrowser(
            readModel: _minimalWaterModel(),
            selection: const SurfaceStudioSelection.none(),
            onSelectionChanged: (s) => last = s,
          ),
        ),
      );
      final target = find.text('Water Surface');
      await tester.ensureVisible(target);
      await tester.pump();
      await tester.tap(target);
      expect(last, SurfaceStudioSelection.preset('water-surface'));
    });
  });
}

Widget _wrap(Widget child) {
  return MaterialApp(
    home: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    ),
  );
}

SurfaceStudioReadModel _oneWaterAtlasModel() {
  final g = SurfaceAtlasGeometry(
    tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
    gridSize: SurfaceAtlasGridSize(columns: 2, rows: 2),
    layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
  );
  final atlas = ProjectSurfaceAtlas(
    id: 'water-atlas',
    name: 'Water Atlas',
    tilesetId: 'nature-tileset',
    geometry: g,
  );
  return buildSurfaceStudioReadModelFromCatalog(
    ProjectSurfaceCatalog(
      atlases: [atlas],
      animations: const [],
      presets: const [],
    ),
  );
}

SurfaceStudioReadModel _minimalWaterModel() {
  final g = SurfaceAtlasGeometry(
    tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
    gridSize: SurfaceAtlasGridSize(columns: 2, rows: 2),
    layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
  );
  final atlas = ProjectSurfaceAtlas(
    id: 'water-atlas',
    name: 'Water Atlas',
    tilesetId: 'nature-tileset',
    geometry: g,
  );
  final frame = SurfaceAnimationFrame(
    tileRef: SurfaceAtlasTileRef(atlasId: 'water-atlas', column: 0, row: 0),
    durationMs: 120,
  );
  final anim = ProjectSurfaceAnimation(
    id: 'water-isolated-loop',
    name: 'Water Isolated Loop',
    timeline: SurfaceAnimationTimeline(frames: [frame]),
  );
  final refs = SurfaceVariantAnimationRefSet(
    refs: [
      SurfaceVariantAnimationRef(
        role: SurfaceVariantRole.isolated,
        animationId: 'water-isolated-loop',
      ),
    ],
  );
  final preset = ProjectSurfacePreset(
    id: 'water-surface',
    name: 'Water Surface',
    variantAnimations: refs,
  );
  return buildSurfaceStudioReadModelFromCatalog(
    ProjectSurfaceCatalog(
      atlases: [atlas],
      animations: [anim],
      presets: [preset],
    ),
  );
}
