import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/importers/tiled_tsx_workspace.dart';

void main() {
  testWidgets('TSX workspace matches the reference builder structure',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        TiledTsxWorkspace(
          catalog: _catalog(),
          projectTilesets: const [
            ProjectTilesetEntry(
              id: 'tech-nature-animations',
              name: 'TECH Nature Animations',
              relativePath: 'Data/Tiled/Assets/TECH-Nature-animations.png',
            ),
          ],
        ),
      ),
    );

    expect(find.text('Créer une surface'), findsWidgets);
    expect(find.text('Importer un TSX'), findsOneWidget);
    expect(find.text('Détection auto'), findsOneWidget);
    expect(find.text('Appliquer les suggestions'), findsOneWidget);
    expect(find.textContaining('Assistant IA'), findsOneWidget);

    expect(find.text('1. Choisir un groupe d’animations'), findsOneWidget);
    expect(find.text('2. Assigner les rôles'), findsOneWidget);
    expect(find.text('3. Prévisualiser et enregistrer'), findsOneWidget);

    expect(find.text('Groupes détectés'), findsOneWidget);
    expect(find.text('Rôles de surface'), findsOneWidget);
    expect(find.text('Prévisualisation'), findsOneWidget);
    expect(find.text('État de la surface'), findsOneWidget);
    expect(find.text('Enregistrer la surface'), findsOneWidget);

    expect(find.text('Groupe détecté 1'), findsOneWidget);
    expect(find.text('2 animations'), findsWidgets);
    expect(find.text('Utiliser'), findsWidgets);
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
