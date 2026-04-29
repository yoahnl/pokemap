import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/importers/tiled_tsx_workspace.dart';
import 'package:path/path.dart' as p;

void main() {
  group('TiledTsxWorkspace import UI', () {
    testWidgets('loads a TSX, shows summary, imports atlas and animations',
        (tester) async {
      ProjectSurfaceCatalog? changedCatalog;

      await tester.pumpWidget(
        _wrap(
          TiledTsxWorkspace(
            catalog: ProjectSurfaceCatalog(),
            projectTilesets: const [
              ProjectTilesetEntry(
                id: 'tech-nature-animations',
                name: 'TECH Nature Animations',
                relativePath: 'Data/Tiled/Assets/TECH-Nature-animations.png',
              ),
            ],
            fileLoader: _FakeTsxFileLoader(_readTechAnimationsTsx()),
            onSurfaceCatalogChanged: (catalog) => changedCatalog = catalog,
          ),
        ),
      );

      expect(find.text('Aucune animation TSX importée.'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('tiled_tsx_workspace.import')));
      await tester.pumpAndSettle();

      expect(find.text('Résumé TSX'), findsOneWidget);
      expect(find.text('TECH-Animations'), findsWidgets);
      expect(find.text('242 animations'), findsWidgets);
      expect(find.text('../Assets/TECH-Nature-animations.png'), findsOneWidget);
      expect(find.textContaining('TECH Nature Animations'), findsWidgets);

      final confirm = find.byKey(
        const ValueKey('tiled_tsx_workspace.confirm_import'),
      );
      await tester.ensureVisible(confirm);
      await tester.tap(confirm);
      await tester.pumpAndSettle();

      expect(changedCatalog, isNotNull);
      expect(changedCatalog!.atlasCount, 1);
      expect(changedCatalog!.animationCount, 242);
      expect(changedCatalog!.presetCount, 0);
      expect(changedCatalog!.containsAtlas('tech-animations'), isTrue);
      expect(
        changedCatalog!.containsAnimation('tech-animations-tile-99'),
        isTrue,
      );
      expect(
        find.text('Import TSX prêt : 242 animations ajoutées.'),
        findsOneWidget,
      );
      expect(find.text('Animations TSX importées'), findsOneWidget);
      expect(find.text('tech-animations-tile-99'), findsWidgets);
    });

    testWidgets('blocks import when no matching tileset is available',
        (tester) async {
      ProjectSurfaceCatalog? changedCatalog;

      await tester.pumpWidget(
        _wrap(
          TiledTsxWorkspace(
            catalog: ProjectSurfaceCatalog(),
            projectTilesets: const [],
            fileLoader: _FakeTsxFileLoader(_readTechAnimationsTsx()),
            onSurfaceCatalogChanged: (catalog) => changedCatalog = catalog,
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('tiled_tsx_workspace.import')));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Ajoutez d’abord l’image comme tileset du projet, puis relancez l’import TSX.',
        ),
        findsOneWidget,
      );

      final confirm = find.byKey(
        const ValueKey('tiled_tsx_workspace.confirm_import'),
      );
      expect(tester.widget<ElevatedButton>(confirm).onPressed, isNull);
      expect(changedCatalog, isNull);
    });

    testWidgets('shows parser errors for invalid TSX', (tester) async {
      await tester.pumpWidget(
        _wrap(
          TiledTsxWorkspace(
            catalog: ProjectSurfaceCatalog(),
            projectTilesets: const [
              ProjectTilesetEntry(
                id: 'mini',
                name: 'Mini',
                relativePath: 'mini.png',
              ),
            ],
            fileLoader: const _FakeTsxFileLoader('<not-xml>'),
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('tiled_tsx_workspace.import')));
      await tester.pumpAndSettle();

      expect(find.text('Erreur import TSX'), findsOneWidget);
      expect(find.textContaining('XML'), findsWidgets);
    });

    testWidgets('blocks TSX without animations', (tester) async {
      await tester.pumpWidget(
        _wrap(
          TiledTsxWorkspace(
            catalog: ProjectSurfaceCatalog(),
            projectTilesets: const [
              ProjectTilesetEntry(
                id: 'static',
                name: 'Static',
                relativePath: 'static.png',
              ),
            ],
            fileLoader: const _FakeTsxFileLoader(_staticTsx),
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('tiled_tsx_workspace.import')));
      await tester.pumpAndSettle();

      expect(find.text('Le TSX ne contient aucune animation.'), findsOneWidget);
      final confirm = find.byKey(
        const ValueKey('tiled_tsx_workspace.confirm_import'),
      );
      expect(tester.widget<ElevatedButton>(confirm).onPressed, isNull);
    });

    testWidgets('reports duplicate atlas id without mutating the catalog',
        (tester) async {
      ProjectSurfaceCatalog? changedCatalog;
      final existing = ProjectSurfaceCatalog(
        atlases: [
          ProjectSurfaceAtlas(
            id: 'tech-animations',
            name: 'TECH-Animations',
            tilesetId: 'tech-nature-animations',
            geometry: SurfaceAtlasGeometry(
              tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
              gridSize: SurfaceAtlasGridSize(columns: 98, rows: 109),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        _wrap(
          TiledTsxWorkspace(
            catalog: existing,
            projectTilesets: const [
              ProjectTilesetEntry(
                id: 'tech-nature-animations',
                name: 'TECH Nature Animations',
                relativePath: 'Data/Tiled/Assets/TECH-Nature-animations.png',
              ),
            ],
            fileLoader: _FakeTsxFileLoader(_readTechAnimationsTsx()),
            onSurfaceCatalogChanged: (catalog) => changedCatalog = catalog,
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('tiled_tsx_workspace.import')));
      await tester.pumpAndSettle();
      final confirm = find.byKey(
        const ValueKey('tiled_tsx_workspace.confirm_import'),
      );
      await tester.ensureVisible(confirm);
      await tester.tap(confirm);
      await tester.pumpAndSettle();

      expect(changedCatalog, isNull);
      expect(
        find.text('Atlas TSX déjà présent dans le catalogue : tech-animations.'),
        findsOneWidget,
      );
    });
  });
}

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 1300,
        height: 900,
        child: child,
      ),
    ),
  );
}

String _readTechAnimationsTsx() {
  final repoRoot = Directory.current.parent.parent;
  final sdkProject = repoRoot
      .listSync()
      .whereType<Directory>()
      .firstWhere((dir) => p.basename(dir.path).contains('sdk_test_project'));
  final tsxFile = File(
    p.join(
      sdkProject.path,
      'Data',
      'Tiled',
      'Tilesets',
      'TECH-Animations.tsx',
    ),
  );
  return tsxFile.readAsStringSync();
}

final class _FakeTsxFileLoader implements TiledTsxFileLoader {
  const _FakeTsxFileLoader(this.xml);

  final String xml;

  @override
  Future<TiledTsxLoadedFile?> pickAndLoadTsx() async {
    return TiledTsxLoadedFile(
      path: '/tmp/TECH-Animations.tsx',
      fileName: 'TECH-Animations.tsx',
      xml: xml,
    );
  }
}

const _staticTsx = '''
<?xml version="1.0" encoding="UTF-8"?>
<tileset name="Static" tilewidth="32" tileheight="32" tilecount="1" columns="1">
 <image source="../Assets/static.png" width="32" height="32"/>
</tileset>
''';
