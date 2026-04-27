// Tests widget — Surface Studio atlas detail (Lot 56).
// API publique `map_core` uniquement (pas de `package:map_core/src/...`).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_atlas_detail_view.dart';

void main() {
  group('SurfaceStudioAtlasDetailView (Lot 56)', () {
    testWidgets('1. title Atlas Surface', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioAtlasDetailView(readModel: _emptyReadModel())),
      );
      expect(find.text('Atlas Surface'), findsOneWidget);
    });

    testWidgets('2. empty: main message', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioAtlasDetailView(readModel: _emptyReadModel())),
      );
      expect(find.text('Aucun atlas Surface'), findsOneWidget);
    });

    testWidgets('3. empty: explainer mentions grilles / animations', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioAtlasDetailView(readModel: _emptyReadModel())),
      );
      final t = _allText(tester);
      expect(
        t.contains('grilles') && t.contains('animations Surface'),
        isTrue,
      );
    });

    testWidgets('4. simple: name and id', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioAtlasDetailView(readModel: _oneWaterAtlasModel())),
      );
      expect(find.text('Water Atlas'), findsOneWidget);
      expect(
        find.textContaining('Identifiant : water-atlas'),
        findsOneWidget,
      );
    });

    testWidgets('5. simple: tileset', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioAtlasDetailView(readModel: _oneWaterAtlasModel())),
      );
      expect(
        find.textContaining('Tileset : nature-tileset'),
        findsOneWidget,
      );
    });

    testWidgets('6. simple: tile 32×32', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioAtlasDetailView(readModel: _oneWaterAtlasModel())),
      );
      expect(find.textContaining('Tile : 32×32'), findsOneWidget);
    });

    testWidgets('7. simple: grid 23×32', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAtlasDetailView(
            readModel: _bigGridAtlasModel(),
          ),
        ),
      );
      expect(find.textContaining('Grille : 23×32'), findsOneWidget);
    });

    testWidgets('8. simple: tile count French', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAtlasDetailView(
            readModel: _bigGridAtlasModel(),
          ),
        ),
      );
      expect(find.textContaining('736 tuiles'), findsOneWidget);
    });

    testWidgets('9. layout humanisé columnsAreVariantsRowsAreFrames', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioAtlasDetailView(readModel: _oneWaterAtlasModel())),
      );
      expect(
        find.textContaining('Colonnes = variantes, lignes = frames'),
        findsOneWidget,
      );
    });

    testWidgets('10. categoryId null', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioAtlasDetailView(readModel: _oneWaterAtlasModel())),
      );
      expect(
        find.textContaining('Catégorie : Aucune catégorie'),
        findsOneWidget,
      );
    });

    testWidgets('11. categoryId set', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAtlasDetailView(
            readModel: _atlasWithCategoryModel(),
          ),
        ),
      );
      expect(
        find.textContaining('Catégorie : animated-surfaces'),
        findsOneWidget,
      );
    });

    testWidgets('12. sortOrder', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAtlasDetailView(
            readModel: _atlasOrder42Model(),
          ),
        ),
      );
      expect(find.textContaining('Ordre : 42'), findsOneWidget);
    });

    testWidgets('13. unused atlas', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAtlasDetailView(
            readModel: _orphanAtlasModel(),
          ),
        ),
      );
      expect(
        find.textContaining('Utilisation : Non utilisé'),
        findsOneWidget,
      );
    });

    testWidgets('14. used by one animation', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioAtlasDetailView(readModel: _oneWaterAtlasModel())),
      );
      expect(
        find.textContaining('Utilisé par 1 animation'),
        findsOneWidget,
      );
      expect(find.text('water-isolated-loop'), findsOneWidget);
    });

    testWidgets('15. used by two animations', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAtlasDetailView(
            readModel: _sharedAtlasTwoAnimsModel(),
          ),
        ),
      );
      expect(
        find.textContaining('Utilisé par 2 animations'),
        findsOneWidget,
      );
      expect(find.text('anim-1'), findsOneWidget);
      expect(find.text('anim-2'), findsOneWidget);
    });

    testWidgets('16. animation id order preserved (b, a, c)', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAtlasDetailView(
            readModel: _threeAnimsOrderModel(),
          ),
        ),
      );
      final b = _allText(tester);
      final iB = b.indexOf('water-b');
      final iA = b.indexOf('water-a');
      final iC = b.indexOf('water-c');
      expect(iB, lessThan(iA));
      expect(iA, lessThan(iC));
    });

    testWidgets('17. atlas order water / lava / grass', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAtlasDetailView(
            readModel: _threeAtlasesModel(),
          ),
        ),
      );
      final t = _allText(tester);
      expect(t.indexOf('Wet'), lessThan(t.indexOf('Lav')));
      expect(t.indexOf('Lav'), lessThan(t.indexOf('Gra')));
    });

    testWidgets('18. not sorted by sortOrder (First before Second)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAtlasDetailView(
            readModel: _sortOrderConflictModel(),
          ),
        ),
      );
      final t = _allText(tester);
      expect(t.indexOf('First'), lessThan(t.indexOf('Second')));
    });

    testWidgets('19. no TextField', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioAtlasDetailView(readModel: _oneWaterAtlasModel())),
      );
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('20. no active edit/save copy', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioAtlasDetailView(readModel: _oneWaterAtlasModel())),
      );
      for (final s in <String>[
        'Créer',
        'Modifier',
        'Supprimer',
        'Enregistrer',
        'Sauvegarder',
        'Save',
        'Delete',
        'Edit'
      ]) {
        expect(find.text(s), findsNothing);
      }
    });

    testWidgets('21. no internal type names in visible tree', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioAtlasDetailView(readModel: _oneWaterAtlasModel())),
      );
      expect(find.textContaining('ProjectSurfaceAtlas'), findsNothing);
      expect(find.textContaining('ProjectSurfaceCatalog'), findsNothing);
      expect(find.textContaining('SurfaceStudioReadModel'), findsNothing);
      expect(find.textContaining('SurfaceStudioAtlasReadModel'), findsNothing);
      expect(find.textContaining('SurfaceAtlasGeometry'), findsNothing);
      expect(find.textContaining('SurfaceAtlasLayout'), findsNothing);
    });

    testWidgets('22. builds with diagnostics in read model, no throw', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAtlasDetailView(
            readModel: _withCatalogDiagnosticsModel(),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('U'), findsOneWidget);
    });

    testWidgets('27. no ProviderScope', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SurfaceStudioAtlasDetailView(
            readModel: _oneWaterAtlasModel(),
          ),
        ),
      );
      expect(find.text('Atlas Surface'), findsOneWidget);
    });

    testWidgets('28. bounded width, no throw', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 360,
              child: SingleChildScrollView(
                child: SurfaceStudioAtlasDetailView(
                  readModel: _oneWaterAtlasModel(),
                ),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('29. public map_core import smoke', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioAtlasDetailView(readModel: _emptyReadModel())),
      );
      expect(find.text('Atlas Surface'), findsOneWidget);
    });

    testWidgets('30. layout rowsAreVariants (fallback string)', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAtlasDetailView(
            readModel: _rowsAreVariantsModel(),
          ),
        ),
      );
      expect(
        find.textContaining('Lignes = variantes, colonnes = frames'),
        findsOneWidget,
      );
    });

    testWidgets('31. layout grid (fallback string)', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAtlasDetailView(
            readModel: _gridLayoutModel(),
          ),
        ),
      );
      expect(
        find.textContaining('Grille arbitraire'),
        findsOneWidget,
      );
    });
  });
}

String _allText(WidgetTester tester) {
  return tester
      .widgetList<Text>(find.byType(Text))
      .map((e) => e.data ?? '')
      .join('\n');
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

SurfaceStudioReadModel _emptyReadModel() =>
    buildSurfaceStudioReadModelFromCatalog(ProjectSurfaceCatalog());

SurfaceStudioReadModel _oneWaterAtlasModel() =>
    buildSurfaceStudioReadModelFromCatalog(_minimalWater());

SurfaceStudioReadModel _bigGridAtlasModel() =>
    buildSurfaceStudioReadModelFromCatalog(_bigGridWater());

SurfaceStudioReadModel _atlasWithCategoryModel() {
  final g = _geom();
  final atlas = ProjectSurfaceAtlas(
    id: 'a',
    name: 'Cat A',
    tilesetId: 't',
    geometry: g,
    categoryId: 'animated-surfaces',
  );
  return buildSurfaceStudioReadModelFromCatalog(
    ProjectSurfaceCatalog(
      atlases: [atlas],
      animations: const [],
      presets: const [],
    ),
  );
}

SurfaceStudioReadModel _atlasOrder42Model() {
  final g = _geom();
  final atlas = ProjectSurfaceAtlas(
    id: 'a',
    name: 'Ord',
    tilesetId: 't',
    geometry: g,
    sortOrder: 42,
  );
  return buildSurfaceStudioReadModelFromCatalog(
    ProjectSurfaceCatalog(
      atlases: [atlas],
      animations: const [],
      presets: const [],
    ),
  );
}

SurfaceStudioReadModel _orphanAtlasModel() {
  final g = _geom();
  final orphan = ProjectSurfaceAtlas(
    id: 'orphan',
    name: 'Orp',
    tilesetId: 't',
    geometry: g,
  );
  return buildSurfaceStudioReadModelFromCatalog(
    ProjectSurfaceCatalog(
      atlases: [orphan],
      animations: const [],
      presets: const [],
    ),
  );
}

SurfaceStudioReadModel _sharedAtlasTwoAnimsModel() =>
    buildSurfaceStudioReadModelFromCatalog(
      _catalogSharedAtlasTwoAnims(),
    );

SurfaceStudioReadModel _threeAnimsOrderModel() {
  final g = _geom();
  final atlas = ProjectSurfaceAtlas(
    id: 'shared',
    name: 'S',
    tilesetId: 't',
    geometry: g,
  );
  SurfaceAnimationFrame f(String aid) => SurfaceAnimationFrame(
        tileRef: SurfaceAtlasTileRef(atlasId: 'shared', column: 0, row: 0),
        durationMs: 1,
      );
  ProjectSurfaceAnimation a(String id) => ProjectSurfaceAnimation(
        id: id,
        name: id,
        timeline: SurfaceAnimationTimeline(frames: [f(id)]),
      );
  return buildSurfaceStudioReadModelFromCatalog(
    ProjectSurfaceCatalog(
      atlases: [atlas],
      animations: [a('water-b'), a('water-a'), a('water-c')],
      presets: const [],
    ),
  );
}

SurfaceStudioReadModel _threeAtlasesModel() {
  final g = _geom();
  ProjectSurfaceAtlas ax(String id, String n) => ProjectSurfaceAtlas(
        id: id,
        name: n,
        tilesetId: 't',
        geometry: g,
      );
  return buildSurfaceStudioReadModelFromCatalog(
    ProjectSurfaceCatalog(
      atlases: [
        ax('w', 'Wet'),
        ax('l', 'Lav'),
        ax('g', 'Gra'),
      ],
      animations: const [],
      presets: const [],
    ),
  );
}

SurfaceStudioReadModel _sortOrderConflictModel() {
  final g = _geom();
  final aFirst = ProjectSurfaceAtlas(
    id: 'first-atlas',
    name: 'First',
    tilesetId: 't',
    geometry: g,
    sortOrder: 99,
  );
  final aSecond = ProjectSurfaceAtlas(
    id: 'second-atlas',
    name: 'Second',
    tilesetId: 't',
    geometry: g,
    sortOrder: 1,
  );
  return buildSurfaceStudioReadModelFromCatalog(
    ProjectSurfaceCatalog(
      atlases: [aFirst, aSecond],
      animations: const [],
      presets: const [],
    ),
  );
}

SurfaceStudioReadModel _withCatalogDiagnosticsModel() {
  final g = _geom();
  final used = ProjectSurfaceAtlas(
    id: 'used-atlas',
    name: 'U',
    tilesetId: 't',
    geometry: g,
  );
  final unused = ProjectSurfaceAtlas(
    id: 'orphan-atlas',
    name: 'O',
    tilesetId: 't',
    geometry: g,
  );
  final f = SurfaceAnimationFrame(
    tileRef: SurfaceAtlasTileRef(atlasId: 'used-atlas', column: 0, row: 0),
    durationMs: 1,
  );
  final anim = ProjectSurfaceAnimation(
    id: 'a',
    name: 'A',
    timeline: SurfaceAnimationTimeline(frames: [f]),
  );
  // Diagnostics non vides (atlas inutilisé) ; la vue atlas n’affiche pas l’onglet diagnostiques.
  return buildSurfaceStudioReadModelFromCatalog(
    ProjectSurfaceCatalog(
      atlases: [used, unused],
      animations: [anim],
      presets: const [],
    ),
  );
}

SurfaceStudioReadModel _rowsAreVariantsModel() {
  final geo = SurfaceAtlasGeometry(
    tileSize: SurfaceAtlasTileSize(width: 16, height: 16),
    gridSize: SurfaceAtlasGridSize(columns: 2, rows: 2),
    layout: SurfaceAtlasLayout.rowsAreVariantsColumnsAreFrames,
  );
  final atlas = ProjectSurfaceAtlas(
    id: 'rv',
    name: 'RV',
    tilesetId: 't',
    geometry: geo,
  );
  return buildSurfaceStudioReadModelFromCatalog(
    ProjectSurfaceCatalog(
      atlases: [atlas],
      animations: const [],
      presets: const [],
    ),
  );
}

SurfaceStudioReadModel _gridLayoutModel() {
  final geo = SurfaceAtlasGeometry(
    tileSize: SurfaceAtlasTileSize(width: 16, height: 16),
    gridSize: SurfaceAtlasGridSize(columns: 4, rows: 4),
    layout: SurfaceAtlasLayout.grid,
  );
  final atlas = ProjectSurfaceAtlas(
    id: 'gr',
    name: 'Gr',
    tilesetId: 't',
    geometry: geo,
  );
  return buildSurfaceStudioReadModelFromCatalog(
    ProjectSurfaceCatalog(
      atlases: [atlas],
      animations: const [],
      presets: const [],
    ),
  );
}

ProjectSurfaceCatalog _catalogSharedAtlasTwoAnims() {
  final g = _geom();
  final atlas = ProjectSurfaceAtlas(
    id: 'shared',
    name: 'Shared',
    tilesetId: 't',
    geometry: g,
  );
  final f1 = SurfaceAnimationFrame(
    tileRef: SurfaceAtlasTileRef(atlasId: 'shared', column: 0, row: 0),
    durationMs: 10,
  );
  final f2 = SurfaceAnimationFrame(
    tileRef: SurfaceAtlasTileRef(atlasId: 'shared', column: 1, row: 0),
    durationMs: 10,
  );
  return ProjectSurfaceCatalog(
    atlases: [atlas],
    animations: [
      ProjectSurfaceAnimation(
        id: 'anim-1',
        name: 'A1',
        timeline: SurfaceAnimationTimeline(frames: [f1]),
      ),
      ProjectSurfaceAnimation(
        id: 'anim-2',
        name: 'A2',
        timeline: SurfaceAnimationTimeline(frames: [f2]),
      ),
    ],
    presets: const [],
  );
}

SurfaceAtlasGeometry _geom() => SurfaceAtlasGeometry(
      tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
      gridSize: SurfaceAtlasGridSize(columns: 2, rows: 2),
      layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
    );

ProjectSurfaceCatalog _minimalWater() {
  final g = _geom();
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
  return ProjectSurfaceCatalog(
    atlases: [atlas],
    animations: [anim],
    presets: const [],
  );
}

ProjectSurfaceCatalog _bigGridWater() {
  final g = SurfaceAtlasGeometry(
    tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
    gridSize: SurfaceAtlasGridSize(columns: 23, rows: 32),
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
    id: 'w',
    name: 'W',
    timeline: SurfaceAnimationTimeline(frames: [frame]),
  );
  return ProjectSurfaceCatalog(
    atlases: [atlas],
    animations: [anim],
    presets: const [],
  );
}
