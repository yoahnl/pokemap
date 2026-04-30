import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/importers/tiled_tsx_workspace.dart';

void main() {
  testWidgets('local detection activates a real group and save uses the draft',
      (tester) async {
    ProjectSurfaceCatalog? changedCatalog;

    await tester.pumpWidget(
      _wrap(
        TiledTsxWorkspace(
          catalog: _catalog(animationCount: 85),
          onSurfaceCatalogChanged: (catalog) => changedCatalog = catalog,
        ),
      ),
    );

    expect(find.text('Groupe actif : Groupe détecté 1'), findsNothing);

    final detect = find.byKey(const ValueKey('tiled_tsx_reference.detect'));
    await tester.ensureVisible(detect);
    await tester.tap(detect);
    await tester.pumpAndSettle();

    expect(find.text('Détection locale basique appliquée.'), findsOneWidget);
    expect(find.text('Groupe actif : Groupe détecté 1'), findsOneWidget);

    final pickIsolated = find.byKey(
      const ValueKey('tiled_tsx_role_mapping_builder.pick.isolated'),
    );
    await tester.ensureVisible(pickIsolated);
    await tester.tap(pickIsolated);
    await tester.pumpAndSettle();

    expect(
      find.byKey(
        const ValueKey(
          'tiled_tsx_role_mapping_builder.option.isolated.tech-animations-tile-1000',
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey(
          'tiled_tsx_role_mapping_builder.option.isolated.tech-animations-tile-1080',
        ),
      ),
      findsNothing,
    );

    await tester.tap(
      find.byKey(
        const ValueKey(
          'tiled_tsx_role_mapping_builder.option.isolated.tech-animations-tile-1000',
        ),
      ),
    );
    await tester.pumpAndSettle();

    final save = find.byKey(
      const ValueKey('tiled_tsx_reference_builder.save_surface'),
    );
    expect(tester.widget<ElevatedButton>(save).onPressed, isNotNull);
    expect(changedCatalog, isNull);

    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(changedCatalog, isNotNull);
    expect(changedCatalog!.presetCount, 1);
    expect(
      changedCatalog!.presets.single
          .animationIdForRole(SurfaceVariantRole.isolated),
      'tech-animations-tile-1000',
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

ProjectSurfaceCatalog _catalog({required int animationCount}) {
  return ProjectSurfaceCatalog(
    atlases: [_atlas()],
    animations: [
      for (var i = 0; i < animationCount; i++)
        _animation(
          'tech-animations-tile-${1000 + i}',
          (i % 98),
          i ~/ 98,
        ),
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
