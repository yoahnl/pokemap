import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/importers/tiled_tsx_workspace.dart';

void main() {
  testWidgets(
      'reference workspace does not render the legacy browser by default',
      (tester) async {
    await tester.pumpWidget(_wrap(TiledTsxWorkspace(catalog: _catalog())));

    expect(
      find.byKey(const ValueKey('tiled_tsx_reference_builder.root')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('tiled_tsx_animation_browser.root')),
      findsNothing,
    );

    final showAll = find.byKey(
      const ValueKey('tiled_tsx_reference.show_all_animations'),
    );
    expect(showAll, findsOneWidget);

    await tester.ensureVisible(showAll);
    await tester.tap(showAll);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('tiled_tsx_animation_browser.root')),
      findsOneWidget,
    );

    final close = find.byKey(
      const ValueKey('tiled_tsx_reference.close_all_animations'),
    );
    await tester.ensureVisible(close);
    await tester.tap(close);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('tiled_tsx_animation_browser.root')),
      findsNothing,
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
