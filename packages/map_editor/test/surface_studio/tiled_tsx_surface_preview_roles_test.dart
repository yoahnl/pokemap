import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/importers/tiled_tsx_workspace.dart';

void main() {
  testWidgets('reference preview reflects assigned center, edges, and corners',
      (tester) async {
    await tester.pumpWidget(_wrap(TiledTsxWorkspace(catalog: _catalog())));

    await _assign(
      tester,
      role: SurfaceVariantRole.isolated,
      animationId: 'tech-animations-tile-99',
    );

    expect(
      find.text('Preview partielle : seuls les centres sont assignés.'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('tiled_tsx_reference_preview.role.isolated')),
      findsWidgets,
    );

    await _assign(
      tester,
      role: SurfaceVariantRole.endNorth,
      animationId: 'tech-animations-tile-105',
    );
    await _assign(
      tester,
      role: SurfaceVariantRole.endEast,
      animationId: 'tech-animations-tile-111',
    );

    expect(find.text('2 / 4 assignés'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('tiled_tsx_reference_preview.role.endNorth')),
      findsWidgets,
    );
    expect(
      find.byKey(const ValueKey('tiled_tsx_reference_preview.role.endEast')),
      findsWidgets,
    );

    await _assign(
      tester,
      role: SurfaceVariantRole.cornerNW,
      animationId: 'tech-animations-tile-117',
    );

    expect(find.text('1 / 4 assignés'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('tiled_tsx_reference_preview.role.cornerNW')),
      findsWidgets,
    );
  });
}

Future<void> _assign(
  WidgetTester tester, {
  required SurfaceVariantRole role,
  required String animationId,
}) async {
  final pick = find.byKey(
    ValueKey('tiled_tsx_role_mapping_builder.pick.${role.name}'),
  );
  await tester.ensureVisible(pick);
  await tester.tap(pick);
  await tester.pumpAndSettle();

  final option = find.byKey(
    ValueKey('tiled_tsx_role_mapping_builder.option.${role.name}.$animationId'),
  );
  await tester.ensureVisible(option);
  await tester.tap(option);
  await tester.pumpAndSettle();
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
      _animation('tech-animations-tile-117', 19, 1),
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
