import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/importers/tiled_tsx_workspace.dart';

void main() {
  testWidgets('reference builder saves a preset only after visual role mapping',
      (tester) async {
    ProjectSurfaceCatalog? changedCatalog;

    await tester.pumpWidget(
      _wrap(
        TiledTsxWorkspace(
          catalog: _catalog(),
          onSurfaceCatalogChanged: (catalog) => changedCatalog = catalog,
        ),
      ),
    );

    final save = find.byKey(
      const ValueKey('tiled_tsx_reference_builder.save_surface'),
    );
    expect(tester.widget<ElevatedButton>(save).onPressed, isNull);
    expect(changedCatalog, isNull);

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

    expect(find.text('Centre'), findsOneWidget);
    expect(find.text('OK'), findsWidgets);
    expect(tester.widget<ElevatedButton>(save).onPressed, isNotNull);

    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(changedCatalog, isNotNull);
    expect(changedCatalog!.presetCount, 1);
    expect(
      changedCatalog!
          .presets.single
          .animationIdForRole(SurfaceVariantRole.isolated),
      'tech-animations-tile-99',
    );
  });
}

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(width: 1500, height: 980, child: child),
    ),
  );
}

ProjectSurfaceCatalog _catalog() {
  return ProjectSurfaceCatalog(
    atlases: [_atlas()],
    animations: [
      _animation('tech-animations-tile-99', 1, 1),
      _animation('tech-animations-tile-105', 7, 1),
      _animation('tech-animations-tile-111', 13, 1),
    ],
  );
}

ProjectSurfaceAtlas _atlas() {
  return ProjectSurfaceAtlas(
    id: 'tech-animations',
    name: 'TECH-Animations',
    tilesetId: 'tech-nature-animations',
    geometry: SurfaceAtlasGeometry(
      tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
      gridSize: SurfaceAtlasGridSize(columns: 98, rows: 109),
      layout: SurfaceAtlasLayout.grid,
    ),
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
