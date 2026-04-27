# Lot 56 — Surface Studio Atlas Detail / Empty State V0

## Passes (1–5)
1. Audit : section Atlas = `_AtlasCard` (Lot 54) ; données = `SurfaceStudioAtlasReadModel` (Lot 51).
2. Implémentation : `SurfaceStudioAtlasDetailView` ; remplacement du bloc ; suppression `_AtlasCard`.
3. Tests : `surface_studio_atlas_detail_view_test.dart` ; alignement browser, panel, workspace.
4. Review : read-only, ordre = `readModel.atlases`.
5. Evidence : ce document.

## `git status` initial (session de travail)
```text
(vide)
```

## Résumé exécutif
Vue **Atlas Surface** (titre, vide, fiches) — lecture seule, ordre source, tuiles en français, layout humanisé, `usedByAnimationIds` sans re-calcul UI.

## Tableau des lots 39–60
Les lots 39–55 et 57–60 suivent le tableau du cahier des charges Lot 56 ; le présent lot est le **Lot 56**.

## Suite du Lot 55
Après la vue diagnostics, l’atlas est lisible fiche par fiche dans le browser.

## Fichiers créés
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_detail_view.dart`
- `packages/map_editor/test/surface_studio/surface_studio_atlas_detail_view_test.dart`
- `reports/surface/surface_engine_lot_56_surface_studio_atlas_detail_view.md`

## Fichiers modifiés
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_catalog_browser.dart`
- `packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart`
- `packages/map_editor/test/surface_studio/surface_studio_panel_test.dart`
- `packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart`

## `git status` final
```text
M packages/map_editor/lib/src/features/surface_studio/surface_studio_catalog_browser.dart
 M packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart
 M packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
 M packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart
?? packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_detail_view.dart
?? packages/map_editor/test/surface_studio/surface_studio_atlas_detail_view_test.dart
```

## Décision : vue read-only
Pas de formulaire, pas d’I/O, pas d’appel de diagnostic. Les textes proviennent des getters sur `SurfaceStudioReadModel` / lignes `SurfaceStudioAtlasReadModel` déjà peuplées en Lot 51.

## Décision : ne pas lire le catalogue brut
L’UI itère `readModel.atlases` (liste de read models) ; n’ouvre pas `ProjectSurfaceCatalog` pour reconstruire les usages.

## Fichiers formatés (`dart format`)
- les six chemins Dart créés ou modifiés (voir audit).

# Evidence Pack (contenus et sorties intégrales)

## A. `surface_studio_atlas_detail_view.dart`
``````dart
// Surface Studio — détail des atlas (Lot 56).
//
// Lecture seule : affiche uniquement [SurfaceStudioReadModel.atlases] et les
// champs dérivés de [SurfaceStudioAtlasReadModel] (Lot 51). Aucun catalogue
// brut, aucun re-calcul d’usages, aucun JSON, aucun I/O, aucune mutation de
// manifest.

import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../ui/shared/cupertino_editor_widgets.dart';

/// Textes visibles (aucun nom de type de la couche domaine dans l’UI).
class SurfaceStudioAtlasDetailViewLabels {
  const SurfaceStudioAtlasDetailViewLabels._();

  static const String title = 'Atlas Surface';
  static const String emptyTitle = 'Aucun atlas Surface';
  static const String emptyHint =
      'Les atlas définissent les grilles d’images utilisées par les animations '
      'Surface.';

  static const String labelIdentifiant = 'Identifiant';
  static const String labelTileset = 'Tileset';
  static const String labelTile = 'Tile';
  static const String labelGrille = 'Grille';
  static const String labelTuiles = 'Tuiles';
  static const String labelLayout = 'Layout';
  static const String labelCategorie = 'Catégorie';
  static const String labelOrdre = 'Ordre';
  static const String labelUtilisation = 'Utilisation';
  static const String labelAnimationsUtilisatrices = 'Animations utilisatrices';

  static const String categorieAucune = 'Aucune catégorie';

  static String tileCountLigne(int n) {
    if (n <= 1) {
      return '1 tuile';
    }
    return '$n tuiles';
  }

  /// Libellé principal pour le layout d’atlas (aucun nom d’énum en UI).
  static String layoutHumain(SurfaceAtlasLayout layout) {
    switch (layout) {
      case SurfaceAtlasLayout.grid:
        return 'Grille arbitraire (pas d’axes variante/frame imposés)';
      case SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames:
        return 'Colonnes = variantes, lignes = frames';
      case SurfaceAtlasLayout.rowsAreVariantsColumnsAreFrames:
        return 'Lignes = variantes, colonnes = frames';
    }
  }

  static String utilisationLigne(int n) {
    if (n <= 0) {
      return 'Non utilisé';
    }
    if (n == 1) {
      return 'Utilisé par 1 animation';
    }
    return 'Utilisé par $n animations';
  }
}

/// Fiches atlas **lecture seule** : ordre = [SurfaceStudioReadModel.atlases].
class SurfaceStudioAtlasDetailView extends StatelessWidget {
  const SurfaceStudioAtlasDetailView({
    super.key,
    required this.readModel,
  });

  final SurfaceStudioReadModel readModel;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          SurfaceStudioAtlasDetailViewLabels.title,
          style: TextStyle(
            color: label,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 10),
        if (readModel.atlases.isEmpty) ...[
          Text(
            SurfaceStudioAtlasDetailViewLabels.emptyTitle,
            style: TextStyle(
              color: subtle,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            SurfaceStudioAtlasDetailViewLabels.emptyHint,
            style: TextStyle(
              color: subtle,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
        ] else
          ...readModel.atlases.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _AtlasFiche(
                row: row,
                label: label,
                subtle: subtle,
              ),
            ),
          ),
      ],
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: EditorChrome.elevatedPanelBackground(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: EditorChrome.editorIslandRim(context),
          width: 1,
        ),
        boxShadow: EditorChrome.sectionCardShadows(context),
      ),
      child: child,
    );
  }
}

class _KeyVal extends StatelessWidget {
  const _KeyVal({
    required this.k,
    required this.v,
    required this.valueColor,
  });

  final String k;
  final String v;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        '$k : $v',
        style: TextStyle(
          color: valueColor,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          height: 1.3,
        ),
      ),
    );
  }
}

class _AtlasFiche extends StatelessWidget {
  const _AtlasFiche({
    required this.row,
    required this.label,
    required this.subtle,
  });

  final SurfaceStudioAtlasReadModel row;
  final Color label;
  final Color subtle;

  @override
  Widget build(BuildContext context) {
    final nAnim = row.usedByAnimationIds.length;
    return _DetailCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            row.name,
            style: TextStyle(
              color: label,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          _KeyVal(
            k: SurfaceStudioAtlasDetailViewLabels.labelIdentifiant,
            v: row.id,
            valueColor: label,
          ),
          _KeyVal(
            k: SurfaceStudioAtlasDetailViewLabels.labelTileset,
            v: row.tilesetId,
            valueColor: label,
          ),
          _KeyVal(
            k: SurfaceStudioAtlasDetailViewLabels.labelTile,
            v: '${row.tileWidth}×${row.tileHeight}',
            valueColor: label,
          ),
          _KeyVal(
            k: SurfaceStudioAtlasDetailViewLabels.labelGrille,
            v: '${row.columns}×${row.rows}',
            valueColor: label,
          ),
          _KeyVal(
            k: SurfaceStudioAtlasDetailViewLabels.labelTuiles,
            v: SurfaceStudioAtlasDetailViewLabels.tileCountLigne(row.tileCount),
            valueColor: label,
          ),
          _KeyVal(
            k: SurfaceStudioAtlasDetailViewLabels.labelLayout,
            v: SurfaceStudioAtlasDetailViewLabels.layoutHumain(row.layout),
            valueColor: label,
          ),
          _KeyVal(
            k: SurfaceStudioAtlasDetailViewLabels.labelCategorie,
            v: row.categoryId == null || row.categoryId!.isEmpty
                ? SurfaceStudioAtlasDetailViewLabels.categorieAucune
                : row.categoryId!,
            valueColor: label,
          ),
          _KeyVal(
            k: SurfaceStudioAtlasDetailViewLabels.labelOrdre,
            v: row.sortOrder.toString(),
            valueColor: label,
          ),
          _KeyVal(
            k: SurfaceStudioAtlasDetailViewLabels.labelUtilisation,
            v: SurfaceStudioAtlasDetailViewLabels.utilisationLigne(nAnim),
            valueColor: label,
          ),
          if (nAnim > 0) ...[
            const SizedBox(height: 4),
            Text(
              SurfaceStudioAtlasDetailViewLabels.labelAnimationsUtilisatrices,
              style: TextStyle(
                color: subtle,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
            ...row.usedByAnimationIds.map(
              (id) => Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  id,
                  style: TextStyle(
                    color: label,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

``````

## A. `surface_studio_atlas_detail_view_test.dart`
``````dart
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

``````

## C. Diff `git` fichiers modifiés
`````diff
diff --git a/packages/map_editor/lib/src/features/surface_studio/surface_studio_catalog_browser.dart b/packages/map_editor/lib/src/features/surface_studio/surface_studio_catalog_browser.dart
index 138d9b23..627f253e 100644
--- a/packages/map_editor/lib/src/features/surface_studio/surface_studio_catalog_browser.dart
+++ b/packages/map_editor/lib/src/features/surface_studio/surface_studio_catalog_browser.dart
@@ -8,6 +8,7 @@ import 'package:flutter/cupertino.dart';
 import 'package:map_core/map_core.dart';
 
 import '../../ui/shared/cupertino_editor_widgets.dart';
+import 'surface_studio_atlas_detail_view.dart';
 
 /// Libellés visibles (aucun nom de type Dart interne).
 class SurfaceStudioCatalogBrowserLabels {
@@ -119,23 +120,7 @@ class SurfaceStudioCatalogBrowser extends StatelessWidget {
           ),
           const SizedBox(height: 16),
         ],
-        _SectionHeader(
-          title: SurfaceStudioCatalogBrowserLabels.sectionAtlas,
-          subtle: subtle,
-        ),
-        const SizedBox(height: 8),
-        if (readModel.atlases.isEmpty)
-          _EmptyLine(
-            text: SurfaceStudioCatalogBrowserLabels.emptyAtlas,
-            subtle: subtle,
-          )
-        else
-          ...readModel.atlases.map(
-            (row) => Padding(
-              padding: const EdgeInsets.only(bottom: 10),
-              child: _AtlasCard(row: row, label: label),
-            ),
-          ),
+        SurfaceStudioAtlasDetailView(readModel: readModel),
         const SizedBox(height: 18),
         _SectionHeader(
           title: SurfaceStudioCatalogBrowserLabels.sectionAnimations,
@@ -271,71 +256,6 @@ class _KeyVal extends StatelessWidget {
   }
 }
 
-class _AtlasCard extends StatelessWidget {
-  const _AtlasCard({
-    required this.row,
-    required this.label,
-  });
-
-  final SurfaceStudioAtlasReadModel row;
-  final Color label;
-
-  @override
-  Widget build(BuildContext context) {
-    final n = row.usedByAnimationIds.length;
-    return _BrowserCard(
-      child: Column(
-        crossAxisAlignment: CrossAxisAlignment.start,
-        children: [
-          Text(
-            row.name,
-            style: TextStyle(
-              color: label,
-              fontSize: 15,
-              fontWeight: FontWeight.w800,
-            ),
-          ),
-          _KeyVal(
-            k: SurfaceStudioCatalogBrowserLabels.labelId,
-            v: row.id,
-            valueColor: label,
-          ),
-          _KeyVal(
-            k: SurfaceStudioCatalogBrowserLabels.labelTileset,
-            v: row.tilesetId,
-            valueColor: label,
-          ),
-          _KeyVal(
-            k: SurfaceStudioCatalogBrowserLabels.labelTile,
-            v: '${row.tileWidth}×${row.tileHeight}',
-            valueColor: label,
-          ),
-          _KeyVal(
-            k: SurfaceStudioCatalogBrowserLabels.labelGrid,
-            v: '${row.columns}×${row.rows}',
-            valueColor: label,
-          ),
-          _KeyVal(
-            k: 'Tuiles',
-            v: '${row.tileCount} tiles',
-            valueColor: label,
-          ),
-          _KeyVal(
-            k: SurfaceStudioCatalogBrowserLabels.labelLayout,
-            v: row.layout.name,
-            valueColor: label,
-          ),
-          _KeyVal(
-            k: SurfaceStudioCatalogBrowserLabels.labelUsedBy,
-            v: SurfaceStudioCatalogBrowserLabels.usedByAnimations(n),
-            valueColor: label,
-          ),
-        ],
-      ),
-    );
-  }
-}
-
 class _AnimationCard extends StatelessWidget {
   const _AnimationCard({
     required this.row,
diff --git a/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart b/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart
index f8f1b566..f9a8f2e9 100644
--- a/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart
+++ b/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart
@@ -35,7 +35,7 @@ void main() {
       await tester.pumpWidget(
         _wrap(SurfaceStudioCatalogBrowser(readModel: _minimalWaterReadModel())),
       );
-      expect(find.text('Atlas'), findsOneWidget);
+      expect(find.text('Atlas Surface'), findsOneWidget);
       expect(find.text('Animations'), findsOneWidget);
       expect(find.text('Presets'), findsOneWidget);
     });
@@ -52,12 +52,17 @@ void main() {
           ),
         ),
       );
+      expect(find.text('Atlas Surface'), findsOneWidget);
       expect(find.text('Water Atlas'), findsOneWidget);
       expect(find.textContaining('Identifiant : water-atlas'), findsOneWidget);
       expect(find.textContaining('Tileset : nature-tileset'), findsOneWidget);
       expect(find.textContaining('32×32'), findsWidgets);
       expect(find.textContaining('23×32'), findsOneWidget);
-      expect(find.textContaining('736'), findsOneWidget);
+      expect(find.textContaining('736 tuiles'), findsOneWidget);
+      expect(
+        find.textContaining('Colonnes = variantes, lignes = frames'),
+        findsOneWidget,
+      );
     });
 
     testWidgets('6. minimal catalog: animation details', (tester) async {
diff --git a/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart b/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
index 903c568a..c69f3701 100644
--- a/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
+++ b/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
@@ -267,6 +267,7 @@ void main() {
         _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
       );
       expect(find.text('Catalogue Surface'), findsOneWidget);
+      expect(find.text('Atlas Surface'), findsOneWidget);
       expect(find.text('Diagnostics Surface'), findsOneWidget);
       expect(find.text('Water Atlas'), findsOneWidget);
     });
diff --git a/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart b/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart
index 295b854b..58110bdb 100644
--- a/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart
+++ b/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart
@@ -103,6 +103,7 @@ void main() {
       expect(find.text('Lecture seule'), findsOneWidget);
       expect(find.byType(SurfaceStudioPanel), findsOneWidget);
       expect(find.text('Catalogue Surface'), findsOneWidget);
+      expect(find.text('Atlas Surface'), findsOneWidget);
       expect(find.text('Water Atlas'), findsOneWidget);
       expect(find.text('Diagnostics Surface'), findsOneWidget);
     });

`````

## C (suite) — diff `/dev/null` atlas
`````diff
diff --git a/packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_detail_view.dart b/packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_detail_view.dart
new file mode 100644
--- /dev/null
+++ b/packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_detail_view.dart
@@ -0,0 +1,281 @@
+// Surface Studio — détail des atlas (Lot 56).
+//
+// Lecture seule : affiche uniquement [SurfaceStudioReadModel.atlases] et les
+// champs dérivés de [SurfaceStudioAtlasReadModel] (Lot 51). Aucun catalogue
+// brut, aucun re-calcul d’usages, aucun JSON, aucun I/O, aucune mutation de
+// manifest.
+
+import 'package:flutter/cupertino.dart';
+import 'package:map_core/map_core.dart';
+
+import '../../ui/shared/cupertino_editor_widgets.dart';
+
+/// Textes visibles (aucun nom de type de la couche domaine dans l’UI).
+class SurfaceStudioAtlasDetailViewLabels {
+  const SurfaceStudioAtlasDetailViewLabels._();
+
+  static const String title = 'Atlas Surface';
+  static const String emptyTitle = 'Aucun atlas Surface';
+  static const String emptyHint =
+      'Les atlas définissent les grilles d’images utilisées par les animations '
+      'Surface.';
+
+  static const String labelIdentifiant = 'Identifiant';
+  static const String labelTileset = 'Tileset';
+  static const String labelTile = 'Tile';
+  static const String labelGrille = 'Grille';
+  static const String labelTuiles = 'Tuiles';
+  static const String labelLayout = 'Layout';
+  static const String labelCategorie = 'Catégorie';
+  static const String labelOrdre = 'Ordre';
+  static const String labelUtilisation = 'Utilisation';
+  static const String labelAnimationsUtilisatrices = 'Animations utilisatrices';
+
+  static const String categorieAucune = 'Aucune catégorie';
+
+  static String tileCountLigne(int n) {
+    if (n <= 1) {
+      return '1 tuile';
+    }
+    return '$n tuiles';
+  }
+
+  /// Libellé principal pour le layout d’atlas (aucun nom d’énum en UI).
+  static String layoutHumain(SurfaceAtlasLayout layout) {
+    switch (layout) {
+      case SurfaceAtlasLayout.grid:
+        return 'Grille arbitraire (pas d’axes variante/frame imposés)';
+      case SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames:
+        return 'Colonnes = variantes, lignes = frames';
+      case SurfaceAtlasLayout.rowsAreVariantsColumnsAreFrames:
+        return 'Lignes = variantes, colonnes = frames';
+    }
+  }
+
+  static String utilisationLigne(int n) {
+    if (n <= 0) {
+      return 'Non utilisé';
+    }
+    if (n == 1) {
+      return 'Utilisé par 1 animation';
+    }
+    return 'Utilisé par $n animations';
+  }
+}
+
+/// Fiches atlas **lecture seule** : ordre = [SurfaceStudioReadModel.atlases].
+class SurfaceStudioAtlasDetailView extends StatelessWidget {
+  const SurfaceStudioAtlasDetailView({
+    super.key,
+    required this.readModel,
+  });
+
+  final SurfaceStudioReadModel readModel;
+
+  @override
+  Widget build(BuildContext context) {
+    final label = EditorChrome.primaryLabel(context);
+    final subtle = EditorChrome.subtleLabel(context);
+    return Column(
+      crossAxisAlignment: CrossAxisAlignment.stretch,
+      children: [
+        Text(
+          SurfaceStudioAtlasDetailViewLabels.title,
+          style: TextStyle(
+            color: label,
+            fontSize: 16,
+            fontWeight: FontWeight.w800,
+            letterSpacing: -0.2,
+          ),
+        ),
+        const SizedBox(height: 10),
+        if (readModel.atlases.isEmpty) ...[
+          Text(
+            SurfaceStudioAtlasDetailViewLabels.emptyTitle,
+            style: TextStyle(
+              color: subtle,
+              fontSize: 14,
+              fontWeight: FontWeight.w600,
+              fontStyle: FontStyle.italic,
+            ),
+          ),
+          const SizedBox(height: 6),
+          Text(
+            SurfaceStudioAtlasDetailViewLabels.emptyHint,
+            style: TextStyle(
+              color: subtle,
+              fontSize: 12,
+              fontWeight: FontWeight.w500,
+              height: 1.35,
+            ),
+          ),
+        ] else
+          ...readModel.atlases.map(
+            (row) => Padding(
+              padding: const EdgeInsets.only(bottom: 10),
+              child: _AtlasFiche(
+                row: row,
+                label: label,
+                subtle: subtle,
+              ),
+            ),
+          ),
+      ],
+    );
+  }
+}
+
+class _DetailCard extends StatelessWidget {
+  const _DetailCard({required this.child});
+
+  final Widget child;
+
+  @override
+  Widget build(BuildContext context) {
+    return Container(
+      padding: const EdgeInsets.all(14),
+      decoration: BoxDecoration(
+        color: EditorChrome.elevatedPanelBackground(context),
+        borderRadius: BorderRadius.circular(14),
+        border: Border.all(
+          color: EditorChrome.editorIslandRim(context),
+          width: 1,
+        ),
+        boxShadow: EditorChrome.sectionCardShadows(context),
+      ),
+      child: child,
+    );
+  }
+}
+
+class _KeyVal extends StatelessWidget {
+  const _KeyVal({
+    required this.k,
+    required this.v,
+    required this.valueColor,
+  });
+
+  final String k;
+  final String v;
+  final Color valueColor;
+
+  @override
+  Widget build(BuildContext context) {
+    return Padding(
+      padding: const EdgeInsets.only(top: 4),
+      child: Text(
+        '$k : $v',
+        style: TextStyle(
+          color: valueColor,
+          fontSize: 13,
+          fontWeight: FontWeight.w500,
+          height: 1.3,
+        ),
+      ),
+    );
+  }
+}
+
+class _AtlasFiche extends StatelessWidget {
+  const _AtlasFiche({
+    required this.row,
+    required this.label,
+    required this.subtle,
+  });
+
+  final SurfaceStudioAtlasReadModel row;
+  final Color label;
+  final Color subtle;
+
+  @override
+  Widget build(BuildContext context) {
+    final nAnim = row.usedByAnimationIds.length;
+    return _DetailCard(
+      child: Column(
+        crossAxisAlignment: CrossAxisAlignment.start,
+        children: [
+          Text(
+            row.name,
+            style: TextStyle(
+              color: label,
+              fontSize: 15,
+              fontWeight: FontWeight.w800,
+            ),
+          ),
+          _KeyVal(
+            k: SurfaceStudioAtlasDetailViewLabels.labelIdentifiant,
+            v: row.id,
+            valueColor: label,
+          ),
+          _KeyVal(
+            k: SurfaceStudioAtlasDetailViewLabels.labelTileset,
+            v: row.tilesetId,
+            valueColor: label,
+          ),
+          _KeyVal(
+            k: SurfaceStudioAtlasDetailViewLabels.labelTile,
+            v: '${row.tileWidth}×${row.tileHeight}',
+            valueColor: label,
+          ),
+          _KeyVal(
+            k: SurfaceStudioAtlasDetailViewLabels.labelGrille,
+            v: '${row.columns}×${row.rows}',
+            valueColor: label,
+          ),
+          _KeyVal(
+            k: SurfaceStudioAtlasDetailViewLabels.labelTuiles,
+            v: SurfaceStudioAtlasDetailViewLabels.tileCountLigne(row.tileCount),
+            valueColor: label,
+          ),
+          _KeyVal(
+            k: SurfaceStudioAtlasDetailViewLabels.labelLayout,
+            v: SurfaceStudioAtlasDetailViewLabels.layoutHumain(row.layout),
+            valueColor: label,
+          ),
+          _KeyVal(
+            k: SurfaceStudioAtlasDetailViewLabels.labelCategorie,
+            v: row.categoryId == null || row.categoryId!.isEmpty
+                ? SurfaceStudioAtlasDetailViewLabels.categorieAucune
+                : row.categoryId!,
+            valueColor: label,
+          ),
+          _KeyVal(
+            k: SurfaceStudioAtlasDetailViewLabels.labelOrdre,
+            v: row.sortOrder.toString(),
+            valueColor: label,
+          ),
+          _KeyVal(
+            k: SurfaceStudioAtlasDetailViewLabels.labelUtilisation,
+            v: SurfaceStudioAtlasDetailViewLabels.utilisationLigne(nAnim),
+            valueColor: label,
+          ),
+          if (nAnim > 0) ...[
+            const SizedBox(height: 4),
+            Text(
+              SurfaceStudioAtlasDetailViewLabels.labelAnimationsUtilisatrices,
+              style: TextStyle(
+                color: subtle,
+                fontSize: 11,
+                fontWeight: FontWeight.w800,
+                letterSpacing: 0.4,
+              ),
+            ),
+            ...row.usedByAnimationIds.map(
+              (id) => Padding(
+                padding: const EdgeInsets.only(top: 2),
+                child: Text(
+                  id,
+                  style: TextStyle(
+                    color: label,
+                    fontSize: 13,
+                    fontWeight: FontWeight.w600,
+                  ),
+                ),
+              ),
+            ),
+          ],
+        ],
+      ),
+    );
+  }
+}

`````

## C (fin) — diff `/dev/null` test
`````diff
diff --git a/packages/map_editor/test/surface_studio/surface_studio_atlas_detail_view_test.dart b/packages/map_editor/test/surface_studio/surface_studio_atlas_detail_view_test.dart
new file mode 100644
--- /dev/null
+++ b/packages/map_editor/test/surface_studio/surface_studio_atlas_detail_view_test.dart
@@ -0,0 +1,658 @@
+// Tests widget — Surface Studio atlas detail (Lot 56).
+// API publique `map_core` uniquement (pas de `package:map_core/src/...`).
+
+import 'package:flutter/material.dart';
+import 'package:flutter_test/flutter_test.dart';
+import 'package:map_core/map_core.dart';
+import 'package:map_editor/src/features/surface_studio/surface_studio_atlas_detail_view.dart';
+
+void main() {
+  group('SurfaceStudioAtlasDetailView (Lot 56)', () {
+    testWidgets('1. title Atlas Surface', (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioAtlasDetailView(readModel: _emptyReadModel())),
+      );
+      expect(find.text('Atlas Surface'), findsOneWidget);
+    });
+
+    testWidgets('2. empty: main message', (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioAtlasDetailView(readModel: _emptyReadModel())),
+      );
+      expect(find.text('Aucun atlas Surface'), findsOneWidget);
+    });
+
+    testWidgets('3. empty: explainer mentions grilles / animations', (
+      tester,
+    ) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioAtlasDetailView(readModel: _emptyReadModel())),
+      );
+      final t = _allText(tester);
+      expect(
+        t.contains('grilles') && t.contains('animations Surface'),
+        isTrue,
+      );
+    });
+
+    testWidgets('4. simple: name and id', (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioAtlasDetailView(readModel: _oneWaterAtlasModel())),
+      );
+      expect(find.text('Water Atlas'), findsOneWidget);
+      expect(
+        find.textContaining('Identifiant : water-atlas'),
+        findsOneWidget,
+      );
+    });
+
+    testWidgets('5. simple: tileset', (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioAtlasDetailView(readModel: _oneWaterAtlasModel())),
+      );
+      expect(
+        find.textContaining('Tileset : nature-tileset'),
+        findsOneWidget,
+      );
+    });
+
+    testWidgets('6. simple: tile 32×32', (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioAtlasDetailView(readModel: _oneWaterAtlasModel())),
+      );
+      expect(find.textContaining('Tile : 32×32'), findsOneWidget);
+    });
+
+    testWidgets('7. simple: grid 23×32', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioAtlasDetailView(
+            readModel: _bigGridAtlasModel(),
+          ),
+        ),
+      );
+      expect(find.textContaining('Grille : 23×32'), findsOneWidget);
+    });
+
+    testWidgets('8. simple: tile count French', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioAtlasDetailView(
+            readModel: _bigGridAtlasModel(),
+          ),
+        ),
+      );
+      expect(find.textContaining('736 tuiles'), findsOneWidget);
+    });
+
+    testWidgets('9. layout humanisé columnsAreVariantsRowsAreFrames', (
+      tester,
+    ) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioAtlasDetailView(readModel: _oneWaterAtlasModel())),
+      );
+      expect(
+        find.textContaining('Colonnes = variantes, lignes = frames'),
+        findsOneWidget,
+      );
+    });
+
+    testWidgets('10. categoryId null', (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioAtlasDetailView(readModel: _oneWaterAtlasModel())),
+      );
+      expect(
+        find.textContaining('Catégorie : Aucune catégorie'),
+        findsOneWidget,
+      );
+    });
+
+    testWidgets('11. categoryId set', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioAtlasDetailView(
+            readModel: _atlasWithCategoryModel(),
+          ),
+        ),
+      );
+      expect(
+        find.textContaining('Catégorie : animated-surfaces'),
+        findsOneWidget,
+      );
+    });
+
+    testWidgets('12. sortOrder', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioAtlasDetailView(
+            readModel: _atlasOrder42Model(),
+          ),
+        ),
+      );
+      expect(find.textContaining('Ordre : 42'), findsOneWidget);
+    });
+
+    testWidgets('13. unused atlas', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioAtlasDetailView(
+            readModel: _orphanAtlasModel(),
+          ),
+        ),
+      );
+      expect(
+        find.textContaining('Utilisation : Non utilisé'),
+        findsOneWidget,
+      );
+    });
+
+    testWidgets('14. used by one animation', (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioAtlasDetailView(readModel: _oneWaterAtlasModel())),
+      );
+      expect(
+        find.textContaining('Utilisé par 1 animation'),
+        findsOneWidget,
+      );
+      expect(find.text('water-isolated-loop'), findsOneWidget);
+    });
+
+    testWidgets('15. used by two animations', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioAtlasDetailView(
+            readModel: _sharedAtlasTwoAnimsModel(),
+          ),
+        ),
+      );
+      expect(
+        find.textContaining('Utilisé par 2 animations'),
+        findsOneWidget,
+      );
+      expect(find.text('anim-1'), findsOneWidget);
+      expect(find.text('anim-2'), findsOneWidget);
+    });
+
+    testWidgets('16. animation id order preserved (b, a, c)', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioAtlasDetailView(
+            readModel: _threeAnimsOrderModel(),
+          ),
+        ),
+      );
+      final b = _allText(tester);
+      final iB = b.indexOf('water-b');
+      final iA = b.indexOf('water-a');
+      final iC = b.indexOf('water-c');
+      expect(iB, lessThan(iA));
+      expect(iA, lessThan(iC));
+    });
+
+    testWidgets('17. atlas order water / lava / grass', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioAtlasDetailView(
+            readModel: _threeAtlasesModel(),
+          ),
+        ),
+      );
+      final t = _allText(tester);
+      expect(t.indexOf('Wet'), lessThan(t.indexOf('Lav')));
+      expect(t.indexOf('Lav'), lessThan(t.indexOf('Gra')));
+    });
+
+    testWidgets('18. not sorted by sortOrder (First before Second)', (
+      tester,
+    ) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioAtlasDetailView(
+            readModel: _sortOrderConflictModel(),
+          ),
+        ),
+      );
+      final t = _allText(tester);
+      expect(t.indexOf('First'), lessThan(t.indexOf('Second')));
+    });
+
+    testWidgets('19. no TextField', (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioAtlasDetailView(readModel: _oneWaterAtlasModel())),
+      );
+      expect(find.byType(TextField), findsNothing);
+    });
+
+    testWidgets('20. no active edit/save copy', (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioAtlasDetailView(readModel: _oneWaterAtlasModel())),
+      );
+      for (final s in <String>[
+        'Créer',
+        'Modifier',
+        'Supprimer',
+        'Enregistrer',
+        'Sauvegarder',
+        'Save',
+        'Delete',
+        'Edit'
+      ]) {
+        expect(find.text(s), findsNothing);
+      }
+    });
+
+    testWidgets('21. no internal type names in visible tree', (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioAtlasDetailView(readModel: _oneWaterAtlasModel())),
+      );
+      expect(find.textContaining('ProjectSurfaceAtlas'), findsNothing);
+      expect(find.textContaining('ProjectSurfaceCatalog'), findsNothing);
+      expect(find.textContaining('SurfaceStudioReadModel'), findsNothing);
+      expect(find.textContaining('SurfaceStudioAtlasReadModel'), findsNothing);
+      expect(find.textContaining('SurfaceAtlasGeometry'), findsNothing);
+      expect(find.textContaining('SurfaceAtlasLayout'), findsNothing);
+    });
+
+    testWidgets('22. builds with diagnostics in read model, no throw', (
+      tester,
+    ) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioAtlasDetailView(
+            readModel: _withCatalogDiagnosticsModel(),
+          ),
+        ),
+      );
+      expect(tester.takeException(), isNull);
+      expect(find.text('U'), findsOneWidget);
+    });
+
+    testWidgets('27. no ProviderScope', (tester) async {
+      await tester.pumpWidget(
+        MaterialApp(
+          home: SurfaceStudioAtlasDetailView(
+            readModel: _oneWaterAtlasModel(),
+          ),
+        ),
+      );
+      expect(find.text('Atlas Surface'), findsOneWidget);
+    });
+
+    testWidgets('28. bounded width, no throw', (tester) async {
+      await tester.pumpWidget(
+        MaterialApp(
+          home: Center(
+            child: SizedBox(
+              width: 360,
+              child: SingleChildScrollView(
+                child: SurfaceStudioAtlasDetailView(
+                  readModel: _oneWaterAtlasModel(),
+                ),
+              ),
+            ),
+          ),
+        ),
+      );
+      expect(tester.takeException(), isNull);
+    });
+
+    testWidgets('29. public map_core import smoke', (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioAtlasDetailView(readModel: _emptyReadModel())),
+      );
+      expect(find.text('Atlas Surface'), findsOneWidget);
+    });
+
+    testWidgets('30. layout rowsAreVariants (fallback string)', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioAtlasDetailView(
+            readModel: _rowsAreVariantsModel(),
+          ),
+        ),
+      );
+      expect(
+        find.textContaining('Lignes = variantes, colonnes = frames'),
+        findsOneWidget,
+      );
+    });
+
+    testWidgets('31. layout grid (fallback string)', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioAtlasDetailView(
+            readModel: _gridLayoutModel(),
+          ),
+        ),
+      );
+      expect(
+        find.textContaining('Grille arbitraire'),
+        findsOneWidget,
+      );
+    });
+  });
+}
+
+String _allText(WidgetTester tester) {
+  return tester
+      .widgetList<Text>(find.byType(Text))
+      .map((e) => e.data ?? '')
+      .join('\n');
+}
+
+Widget _wrap(Widget child) {
+  return MaterialApp(
+    home: SingleChildScrollView(
+      child: Padding(
+        padding: const EdgeInsets.all(16),
+        child: child,
+      ),
+    ),
+  );
+}
+
+SurfaceStudioReadModel _emptyReadModel() =>
+    buildSurfaceStudioReadModelFromCatalog(ProjectSurfaceCatalog());
+
+SurfaceStudioReadModel _oneWaterAtlasModel() =>
+    buildSurfaceStudioReadModelFromCatalog(_minimalWater());
+
+SurfaceStudioReadModel _bigGridAtlasModel() =>
+    buildSurfaceStudioReadModelFromCatalog(_bigGridWater());
+
+SurfaceStudioReadModel _atlasWithCategoryModel() {
+  final g = _geom();
+  final atlas = ProjectSurfaceAtlas(
+    id: 'a',
+    name: 'Cat A',
+    tilesetId: 't',
+    geometry: g,
+    categoryId: 'animated-surfaces',
+  );
+  return buildSurfaceStudioReadModelFromCatalog(
+    ProjectSurfaceCatalog(
+      atlases: [atlas],
+      animations: const [],
+      presets: const [],
+    ),
+  );
+}
+
+SurfaceStudioReadModel _atlasOrder42Model() {
+  final g = _geom();
+  final atlas = ProjectSurfaceAtlas(
+    id: 'a',
+    name: 'Ord',
+    tilesetId: 't',
+    geometry: g,
+    sortOrder: 42,
+  );
+  return buildSurfaceStudioReadModelFromCatalog(
+    ProjectSurfaceCatalog(
+      atlases: [atlas],
+      animations: const [],
+      presets: const [],
+    ),
+  );
+}
+
+SurfaceStudioReadModel _orphanAtlasModel() {
+  final g = _geom();
+  final orphan = ProjectSurfaceAtlas(
+    id: 'orphan',
+    name: 'Orp',
+    tilesetId: 't',
+    geometry: g,
+  );
+  return buildSurfaceStudioReadModelFromCatalog(
+    ProjectSurfaceCatalog(
+      atlases: [orphan],
+      animations: const [],
+      presets: const [],
+    ),
+  );
+}
+
+SurfaceStudioReadModel _sharedAtlasTwoAnimsModel() =>
+    buildSurfaceStudioReadModelFromCatalog(
+      _catalogSharedAtlasTwoAnims(),
+    );
+
+SurfaceStudioReadModel _threeAnimsOrderModel() {
+  final g = _geom();
+  final atlas = ProjectSurfaceAtlas(
+    id: 'shared',
+    name: 'S',
+    tilesetId: 't',
+    geometry: g,
+  );
+  SurfaceAnimationFrame f(String aid) => SurfaceAnimationFrame(
+        tileRef: SurfaceAtlasTileRef(atlasId: 'shared', column: 0, row: 0),
+        durationMs: 1,
+      );
+  ProjectSurfaceAnimation a(String id) => ProjectSurfaceAnimation(
+        id: id,
+        name: id,
+        timeline: SurfaceAnimationTimeline(frames: [f(id)]),
+      );
+  return buildSurfaceStudioReadModelFromCatalog(
+    ProjectSurfaceCatalog(
+      atlases: [atlas],
+      animations: [a('water-b'), a('water-a'), a('water-c')],
+      presets: const [],
+    ),
+  );
+}
+
+SurfaceStudioReadModel _threeAtlasesModel() {
+  final g = _geom();
+  ProjectSurfaceAtlas ax(String id, String n) => ProjectSurfaceAtlas(
+        id: id,
+        name: n,
+        tilesetId: 't',
+        geometry: g,
+      );
+  return buildSurfaceStudioReadModelFromCatalog(
+    ProjectSurfaceCatalog(
+      atlases: [
+        ax('w', 'Wet'),
+        ax('l', 'Lav'),
+        ax('g', 'Gra'),
+      ],
+      animations: const [],
+      presets: const [],
+    ),
+  );
+}
+
+SurfaceStudioReadModel _sortOrderConflictModel() {
+  final g = _geom();
+  final aFirst = ProjectSurfaceAtlas(
+    id: 'first-atlas',
+    name: 'First',
+    tilesetId: 't',
+    geometry: g,
+    sortOrder: 99,
+  );
+  final aSecond = ProjectSurfaceAtlas(
+    id: 'second-atlas',
+    name: 'Second',
+    tilesetId: 't',
+    geometry: g,
+    sortOrder: 1,
+  );
+  return buildSurfaceStudioReadModelFromCatalog(
+    ProjectSurfaceCatalog(
+      atlases: [aFirst, aSecond],
+      animations: const [],
+      presets: const [],
+    ),
+  );
+}
+
+SurfaceStudioReadModel _withCatalogDiagnosticsModel() {
+  final g = _geom();
+  final used = ProjectSurfaceAtlas(
+    id: 'used-atlas',
+    name: 'U',
+    tilesetId: 't',
+    geometry: g,
+  );
+  final unused = ProjectSurfaceAtlas(
+    id: 'orphan-atlas',
+    name: 'O',
+    tilesetId: 't',
+    geometry: g,
+  );
+  final f = SurfaceAnimationFrame(
+    tileRef: SurfaceAtlasTileRef(atlasId: 'used-atlas', column: 0, row: 0),
+    durationMs: 1,
+  );
+  final anim = ProjectSurfaceAnimation(
+    id: 'a',
+    name: 'A',
+    timeline: SurfaceAnimationTimeline(frames: [f]),
+  );
+  // Diagnostics non vides (atlas inutilisé) ; la vue atlas n’affiche pas l’onglet diagnostiques.
+  return buildSurfaceStudioReadModelFromCatalog(
+    ProjectSurfaceCatalog(
+      atlases: [used, unused],
+      animations: [anim],
+      presets: const [],
+    ),
+  );
+}
+
+SurfaceStudioReadModel _rowsAreVariantsModel() {
+  final geo = SurfaceAtlasGeometry(
+    tileSize: SurfaceAtlasTileSize(width: 16, height: 16),
+    gridSize: SurfaceAtlasGridSize(columns: 2, rows: 2),
+    layout: SurfaceAtlasLayout.rowsAreVariantsColumnsAreFrames,
+  );
+  final atlas = ProjectSurfaceAtlas(
+    id: 'rv',
+    name: 'RV',
+    tilesetId: 't',
+    geometry: geo,
+  );
+  return buildSurfaceStudioReadModelFromCatalog(
+    ProjectSurfaceCatalog(
+      atlases: [atlas],
+      animations: const [],
+      presets: const [],
+    ),
+  );
+}
+
+SurfaceStudioReadModel _gridLayoutModel() {
+  final geo = SurfaceAtlasGeometry(
+    tileSize: SurfaceAtlasTileSize(width: 16, height: 16),
+    gridSize: SurfaceAtlasGridSize(columns: 4, rows: 4),
+    layout: SurfaceAtlasLayout.grid,
+  );
+  final atlas = ProjectSurfaceAtlas(
+    id: 'gr',
+    name: 'Gr',
+    tilesetId: 't',
+    geometry: geo,
+  );
+  return buildSurfaceStudioReadModelFromCatalog(
+    ProjectSurfaceCatalog(
+      atlases: [atlas],
+      animations: const [],
+      presets: const [],
+    ),
+  );
+}
+
+ProjectSurfaceCatalog _catalogSharedAtlasTwoAnims() {
+  final g = _geom();
+  final atlas = ProjectSurfaceAtlas(
+    id: 'shared',
+    name: 'Shared',
+    tilesetId: 't',
+    geometry: g,
+  );
+  final f1 = SurfaceAnimationFrame(
+    tileRef: SurfaceAtlasTileRef(atlasId: 'shared', column: 0, row: 0),
+    durationMs: 10,
+  );
+  final f2 = SurfaceAnimationFrame(
+    tileRef: SurfaceAtlasTileRef(atlasId: 'shared', column: 1, row: 0),
+    durationMs: 10,
+  );
+  return ProjectSurfaceCatalog(
+    atlases: [atlas],
+    animations: [
+      ProjectSurfaceAnimation(
+        id: 'anim-1',
+        name: 'A1',
+        timeline: SurfaceAnimationTimeline(frames: [f1]),
+      ),
+      ProjectSurfaceAnimation(
+        id: 'anim-2',
+        name: 'A2',
+        timeline: SurfaceAnimationTimeline(frames: [f2]),
+      ),
+    ],
+    presets: const [],
+  );
+}
+
+SurfaceAtlasGeometry _geom() => SurfaceAtlasGeometry(
+      tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
+      gridSize: SurfaceAtlasGridSize(columns: 2, rows: 2),
+      layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
+    );
+
+ProjectSurfaceCatalog _minimalWater() {
+  final g = _geom();
+  final atlas = ProjectSurfaceAtlas(
+    id: 'water-atlas',
+    name: 'Water Atlas',
+    tilesetId: 'nature-tileset',
+    geometry: g,
+  );
+  final frame = SurfaceAnimationFrame(
+    tileRef: SurfaceAtlasTileRef(atlasId: 'water-atlas', column: 0, row: 0),
+    durationMs: 120,
+  );
+  final anim = ProjectSurfaceAnimation(
+    id: 'water-isolated-loop',
+    name: 'Water Isolated Loop',
+    timeline: SurfaceAnimationTimeline(frames: [frame]),
+  );
+  return ProjectSurfaceCatalog(
+    atlases: [atlas],
+    animations: [anim],
+    presets: const [],
+  );
+}
+
+ProjectSurfaceCatalog _bigGridWater() {
+  final g = SurfaceAtlasGeometry(
+    tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
+    gridSize: SurfaceAtlasGridSize(columns: 23, rows: 32),
+    layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
+  );
+  final atlas = ProjectSurfaceAtlas(
+    id: 'water-atlas',
+    name: 'Water Atlas',
+    tilesetId: 'nature-tileset',
+    geometry: g,
+  );
+  final frame = SurfaceAnimationFrame(
+    tileRef: SurfaceAtlasTileRef(atlasId: 'water-atlas', column: 0, row: 0),
+    durationMs: 120,
+  );
+  final anim = ProjectSurfaceAnimation(
+    id: 'w',
+    name: 'W',
+    timeline: SurfaceAnimationTimeline(frames: [frame]),
+  );
+  return ProjectSurfaceCatalog(
+    atlases: [atlas],
+    animations: [anim],
+    presets: const [],
+  );
+}

`````

## D. Sorties (tests et analyse)
### D1 ciblé Lot 56
```text

00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_detail_view_test.dart                                                               
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_detail_view_test.dart                                                               
00:01 +0: SurfaceStudioAtlasDetailView (Lot 56) 1. title Atlas Surface                                                                                                                                 
00:01 +1: SurfaceStudioAtlasDetailView (Lot 56) 1. title Atlas Surface                                                                                                                                 
00:01 +1: SurfaceStudioAtlasDetailView (Lot 56) 2. empty: main message                                                                                                                                 
00:01 +2: SurfaceStudioAtlasDetailView (Lot 56) 2. empty: main message                                                                                                                                 
00:01 +2: SurfaceStudioAtlasDetailView (Lot 56) 3. empty: explainer mentions grilles / animations                                                                                                      
00:01 +3: SurfaceStudioAtlasDetailView (Lot 56) 3. empty: explainer mentions grilles / animations                                                                                                      
00:01 +3: SurfaceStudioAtlasDetailView (Lot 56) 4. simple: name and id                                                                                                                                 
00:01 +4: SurfaceStudioAtlasDetailView (Lot 56) 4. simple: name and id                                                                                                                                 
00:01 +4: SurfaceStudioAtlasDetailView (Lot 56) 5. simple: tileset                                                                                                                                     
00:02 +4: SurfaceStudioAtlasDetailView (Lot 56) 5. simple: tileset                                                                                                                                     
00:02 +5: SurfaceStudioAtlasDetailView (Lot 56) 5. simple: tileset                                                                                                                                     
00:02 +5: SurfaceStudioAtlasDetailView (Lot 56) 6. simple: tile 32×32                                                                                                                                  
00:02 +6: SurfaceStudioAtlasDetailView (Lot 56) 6. simple: tile 32×32                                                                                                                                  
00:02 +6: SurfaceStudioAtlasDetailView (Lot 56) 7. simple: grid 23×32                                                                                                                                  
00:02 +7: SurfaceStudioAtlasDetailView (Lot 56) 7. simple: grid 23×32                                                                                                                                  
00:02 +7: SurfaceStudioAtlasDetailView (Lot 56) 8. simple: tile count French                                                                                                                           
00:02 +8: SurfaceStudioAtlasDetailView (Lot 56) 8. simple: tile count French                                                                                                                           
00:02 +8: SurfaceStudioAtlasDetailView (Lot 56) 9. layout humanisé columnsAreVariantsRowsAreFrames                                                                                                     
00:02 +9: SurfaceStudioAtlasDetailView (Lot 56) 9. layout humanisé columnsAreVariantsRowsAreFrames                                                                                                     
00:02 +9: SurfaceStudioAtlasDetailView (Lot 56) 10. categoryId null                                                                                                                                    
00:02 +10: SurfaceStudioAtlasDetailView (Lot 56) 10. categoryId null                                                                                                                                   
00:02 +10: SurfaceStudioAtlasDetailView (Lot 56) 11. categoryId set                                                                                                                                    
00:02 +11: SurfaceStudioAtlasDetailView (Lot 56) 11. categoryId set                                                                                                                                    
00:02 +11: SurfaceStudioAtlasDetailView (Lot 56) 12. sortOrder                                                                                                                                         
00:02 +12: SurfaceStudioAtlasDetailView (Lot 56) 12. sortOrder                                                                                                                                         
00:02 +12: SurfaceStudioAtlasDetailView (Lot 56) 13. unused atlas                                                                                                                                      
00:02 +13: SurfaceStudioAtlasDetailView (Lot 56) 13. unused atlas                                                                                                                                      
00:02 +13: SurfaceStudioAtlasDetailView (Lot 56) 14. used by one animation                                                                                                                             
00:02 +14: SurfaceStudioAtlasDetailView (Lot 56) 14. used by one animation                                                                                                                             
00:02 +14: SurfaceStudioAtlasDetailView (Lot 56) 15. used by two animations                                                                                                                            
00:02 +15: SurfaceStudioAtlasDetailView (Lot 56) 15. used by two animations                                                                                                                            
00:02 +15: SurfaceStudioAtlasDetailView (Lot 56) 16. animation id order preserved (b, a, c)                                                                                                            
00:02 +16: SurfaceStudioAtlasDetailView (Lot 56) 16. animation id order preserved (b, a, c)                                                                                                            
00:02 +16: SurfaceStudioAtlasDetailView (Lot 56) 17. atlas order water / lava / grass                                                                                                                  
00:02 +17: SurfaceStudioAtlasDetailView (Lot 56) 17. atlas order water / lava / grass                                                                                                                  
00:02 +17: SurfaceStudioAtlasDetailView (Lot 56) 18. not sorted by sortOrder (First before Second)                                                                                                     
00:02 +18: SurfaceStudioAtlasDetailView (Lot 56) 18. not sorted by sortOrder (First before Second)                                                                                                     
00:02 +18: SurfaceStudioAtlasDetailView (Lot 56) 19. no TextField                                                                                                                                      
00:02 +19: SurfaceStudioAtlasDetailView (Lot 56) 19. no TextField                                                                                                                                      
00:02 +19: SurfaceStudioAtlasDetailView (Lot 56) 20. no active edit/save copy                                                                                                                          
00:02 +20: SurfaceStudioAtlasDetailView (Lot 56) 20. no active edit/save copy                                                                                                                          
00:02 +20: SurfaceStudioAtlasDetailView (Lot 56) 21. no internal type names in visible tree                                                                                                            
00:02 +21: SurfaceStudioAtlasDetailView (Lot 56) 21. no internal type names in visible tree                                                                                                            
00:02 +21: SurfaceStudioAtlasDetailView (Lot 56) 22. builds with diagnostics in read model, no throw                                                                                                   
00:02 +22: SurfaceStudioAtlasDetailView (Lot 56) 22. builds with diagnostics in read model, no throw                                                                                                   
00:02 +22: SurfaceStudioAtlasDetailView (Lot 56) 27. no ProviderScope                                                                                                                                  
00:02 +23: SurfaceStudioAtlasDetailView (Lot 56) 27. no ProviderScope                                                                                                                                  
00:02 +23: SurfaceStudioAtlasDetailView (Lot 56) 28. bounded width, no throw                                                                                                                           
00:02 +24: SurfaceStudioAtlasDetailView (Lot 56) 28. bounded width, no throw                                                                                                                           
00:02 +24: SurfaceStudioAtlasDetailView (Lot 56) 29. public map_core import smoke                                                                                                                      
00:02 +25: SurfaceStudioAtlasDetailView (Lot 56) 29. public map_core import smoke                                                                                                                      
00:02 +25: SurfaceStudioAtlasDetailView (Lot 56) 30. layout rowsAreVariants (fallback string)                                                                                                          
00:02 +26: SurfaceStudioAtlasDetailView (Lot 56) 30. layout rowsAreVariants (fallback string)                                                                                                          
00:02 +26: SurfaceStudioAtlasDetailView (Lot 56) 31. layout grid (fallback string)                                                                                                                     
00:02 +27: SurfaceStudioAtlasDetailView (Lot 56) 31. layout grid (fallback string)                                                                                                                     
00:02 +27: All tests passed!                                                                                                                                                                           

```

### D2 Lot 55
```text

00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_diagnostics_view_test.dart                                                                
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_diagnostics_view_test.dart                                                                
00:01 +0: SurfaceStudioDiagnosticsView (Lot 55) 1. title Diagnostics Surface                                                                                                                           
00:01 +1: SurfaceStudioDiagnosticsView (Lot 55) 1. title Diagnostics Surface                                                                                                                           
00:01 +1: SurfaceStudioDiagnosticsView (Lot 55) 2. clean: main message                                                                                                                                 
00:01 +2: SurfaceStudioDiagnosticsView (Lot 55) 2. clean: main message                                                                                                                                 
00:01 +2: SurfaceStudioDiagnosticsView (Lot 55) 3. clean: ni erreur ni avertissement                                                                                                                   
00:01 +3: SurfaceStudioDiagnosticsView (Lot 55) 3. clean: ni erreur ni avertissement                                                                                                                   
00:01 +3: SurfaceStudioDiagnosticsView (Lot 55) 4. clean: counts zero                                                                                                                                  
00:01 +4: SurfaceStudioDiagnosticsView (Lot 55) 4. clean: counts zero                                                                                                                                  
00:01 +4: SurfaceStudioDiagnosticsView (Lot 55) 5. error missingPresetAnimation                                                                                                                        
00:01 +5: SurfaceStudioDiagnosticsView (Lot 55) 5. error missingPresetAnimation                                                                                                                        
00:01 +5: SurfaceStudioDiagnosticsView (Lot 55) 6. error missingAnimationAtlas                                                                                                                         
00:01 +6: SurfaceStudioDiagnosticsView (Lot 55) 6. error missingAnimationAtlas                                                                                                                         
00:01 +6: SurfaceStudioDiagnosticsView (Lot 55) 7. error animationFrameOutsideAtlasGeometry                                                                                                            
00:01 +7: SurfaceStudioDiagnosticsView (Lot 55) 7. error animationFrameOutsideAtlasGeometry                                                                                                            
00:01 +7: SurfaceStudioDiagnosticsView (Lot 55) 8. warning unusedAtlas                                                                                                                                 
00:01 +8: SurfaceStudioDiagnosticsView (Lot 55) 8. warning unusedAtlas                                                                                                                                 
00:01 +8: SurfaceStudioDiagnosticsView (Lot 55) 9. warning unusedAnimation                                                                                                                             
00:01 +9: SurfaceStudioDiagnosticsView (Lot 55) 9. warning unusedAnimation                                                                                                                             
00:01 +9: SurfaceStudioDiagnosticsView (Lot 55) 10. mixed: Erreurs and Avertissements sections                                                                                                         
00:01 +10: SurfaceStudioDiagnosticsView (Lot 55) 10. mixed: Erreurs and Avertissements sections                                                                                                        
00:01 +10: SurfaceStudioDiagnosticsView (Lot 55) 11. mixed: summary counts                                                                                                                             
00:01 +11: SurfaceStudioDiagnosticsView (Lot 55) 11. mixed: summary counts                                                                                                                             
00:01 +11: SurfaceStudioDiagnosticsView (Lot 55) 12. error order preserved                                                                                                                             
00:01 +12: SurfaceStudioDiagnosticsView (Lot 55) 12. error order preserved                                                                                                                             
00:01 +12: SurfaceStudioDiagnosticsView (Lot 55) 13. warning order preserved                                                                                                                           
00:01 +13: SurfaceStudioDiagnosticsView (Lot 55) 13. warning order preserved                                                                                                                           
00:01 +13: SurfaceStudioDiagnosticsView (Lot 55) 14. warnings only: no errors line empty section                                                                                                       
00:01 +14: SurfaceStudioDiagnosticsView (Lot 55) 14. warnings only: no errors line empty section                                                                                                       
00:01 +14: SurfaceStudioDiagnosticsView (Lot 55) 15. errors only: no warnings line empty section                                                                                                       
00:01 +15: SurfaceStudioDiagnosticsView (Lot 55) 15. errors only: no warnings line empty section                                                                                                       
00:01 +15: SurfaceStudioDiagnosticsView (Lot 55) 16. no TextField                                                                                                                                      
00:01 +16: SurfaceStudioDiagnosticsView (Lot 55) 16. no TextField                                                                                                                                      
00:01 +16: SurfaceStudioDiagnosticsView (Lot 55) 17. no fix affordances on view                                                                                                                        
00:01 +17: SurfaceStudioDiagnosticsView (Lot 55) 17. no fix affordances on view                                                                                                                        
00:01 +17: SurfaceStudioDiagnosticsView (Lot 55) 18. no internal type names in UI text                                                                                                                 
00:01 +18: SurfaceStudioDiagnosticsView (Lot 55) 18. no internal type names in UI text                                                                                                                 
00:01 +18: SurfaceStudioDiagnosticsView (Lot 55) 19. many diagnostics build without throw                                                                                                              
00:01 +19: SurfaceStudioDiagnosticsView (Lot 55) 19. many diagnostics build without throw                                                                                                              
00:01 +19: SurfaceStudioDiagnosticsView (Lot 55) 20. messages follow readModel.diagnostics                                                                                                             
00:01 +20: SurfaceStudioDiagnosticsView (Lot 55) 20. messages follow readModel.diagnostics                                                                                                             
00:01 +20: SurfaceStudioDiagnosticsView (Lot 55) 25. no ProviderScope                                                                                                                                  
00:01 +21: SurfaceStudioDiagnosticsView (Lot 55) 25. no ProviderScope                                                                                                                                  
00:01 +21: SurfaceStudioDiagnosticsView (Lot 55) 26. bounded width                                                                                                                                     
00:01 +22: SurfaceStudioDiagnosticsView (Lot 55) 26. bounded width                                                                                                                                     
00:01 +22: SurfaceStudioDiagnosticsView (Lot 55) 27. public map_core only (smoke)                                                                                                                      
00:01 +23: SurfaceStudioDiagnosticsView (Lot 55) 27. public map_core only (smoke)                                                                                                                      
00:01 +23: All tests passed!                                                                                                                                                                           

```

### D3 Lot 54
```text

00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart                                                                 
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart                                                                 
00:01 +0: SurfaceStudioCatalogBrowser (Lot 54) 1. browser shows title Catalogue Surface                                                                                                                
00:01 +1: SurfaceStudioCatalogBrowser (Lot 54) 1. browser shows title Catalogue Surface                                                                                                                
00:01 +1: SurfaceStudioCatalogBrowser (Lot 54) 2. empty catalog: global empty message                                                                                                                  
00:01 +2: SurfaceStudioCatalogBrowser (Lot 54) 2. empty catalog: global empty message                                                                                                                  
00:01 +2: SurfaceStudioCatalogBrowser (Lot 54) 3. empty catalog: per-section empty lines                                                                                                               
00:01 +3: SurfaceStudioCatalogBrowser (Lot 54) 3. empty catalog: per-section empty lines                                                                                                               
00:01 +3: SurfaceStudioCatalogBrowser (Lot 54) 4. minimal catalog: section headers visible                                                                                                             
00:01 +4: SurfaceStudioCatalogBrowser (Lot 54) 4. minimal catalog: section headers visible                                                                                                             
00:01 +4: SurfaceStudioCatalogBrowser (Lot 54) 5. minimal catalog: atlas details (736-tile grid)                                                                                                       
00:01 +5: SurfaceStudioCatalogBrowser (Lot 54) 5. minimal catalog: atlas details (736-tile grid)                                                                                                       
00:01 +5: SurfaceStudioCatalogBrowser (Lot 54) 6. minimal catalog: animation details                                                                                                                   
00:01 +6: SurfaceStudioCatalogBrowser (Lot 54) 6. minimal catalog: animation details                                                                                                                   
00:01 +6: SurfaceStudioCatalogBrowser (Lot 54) 7. minimal catalog: preset details                                                                                                                      
00:01 +7: SurfaceStudioCatalogBrowser (Lot 54) 7. minimal catalog: preset details                                                                                                                      
00:01 +7: SurfaceStudioCatalogBrowser (Lot 54) 8. full animation: sync group and category                                                                                                              
00:01 +8: SurfaceStudioCatalogBrowser (Lot 54) 8. full animation: sync group and category                                                                                                              
00:01 +8: SurfaceStudioCatalogBrowser (Lot 54) 9. atlas used by two animations                                                                                                                         
00:01 +9: SurfaceStudioCatalogBrowser (Lot 54) 9. atlas used by two animations                                                                                                                         
00:01 +9: SurfaceStudioCatalogBrowser (Lot 54) 10. atlas unused                                                                                                                                        
00:01 +10: SurfaceStudioCatalogBrowser (Lot 54) 10. atlas unused                                                                                                                                       
00:01 +10: SurfaceStudioCatalogBrowser (Lot 54) 11. animation referenced atlas ids deduped order                                                                                                       
00:01 +11: SurfaceStudioCatalogBrowser (Lot 54) 11. animation referenced atlas ids deduped order                                                                                                       
00:01 +11: SurfaceStudioCatalogBrowser (Lot 54) 12. preset referenced animation ids deduped order                                                                                                      
00:01 +12: SurfaceStudioCatalogBrowser (Lot 54) 12. preset referenced animation ids deduped order                                                                                                      
00:01 +12: SurfaceStudioCatalogBrowser (Lot 54) 13. preset roles source order                                                                                                                          
00:01 +13: SurfaceStudioCatalogBrowser (Lot 54) 13. preset roles source order                                                                                                                          
00:01 +13: SurfaceStudioCatalogBrowser (Lot 54) 14. atlas order preserved                                                                                                                              
00:01 +14: SurfaceStudioCatalogBrowser (Lot 54) 14. atlas order preserved                                                                                                                              
00:01 +14: SurfaceStudioCatalogBrowser (Lot 54) 15. animation order preserved                                                                                                                          
00:01 +15: SurfaceStudioCatalogBrowser (Lot 54) 15. animation order preserved                                                                                                                          
00:01 +15: SurfaceStudioCatalogBrowser (Lot 54) 16. preset order preserved                                                                                                                             
00:01 +16: SurfaceStudioCatalogBrowser (Lot 54) 16. preset order preserved                                                                                                                             
00:01 +16: SurfaceStudioCatalogBrowser (Lot 54) 17. order is list order not sortOrder                                                                                                                  
00:01 +17: SurfaceStudioCatalogBrowser (Lot 54) 17. order is list order not sortOrder                                                                                                                  
00:01 +17: SurfaceStudioCatalogBrowser (Lot 54) 18. browser in scrollable ancestor                                                                                                                     
00:01 +18: SurfaceStudioCatalogBrowser (Lot 54) 18. browser in scrollable ancestor                                                                                                                     
00:01 +18: SurfaceStudioCatalogBrowser (Lot 54) 19. no TextField in browser                                                                                                                            
00:01 +19: SurfaceStudioCatalogBrowser (Lot 54) 19. no TextField in browser                                                                                                                            
00:01 +19: SurfaceStudioCatalogBrowser (Lot 54) 20. browser has no active edit affordances                                                                                                             
00:01 +20: SurfaceStudioCatalogBrowser (Lot 54) 20. browser has no active edit affordances                                                                                                             
00:01 +20: SurfaceStudioCatalogBrowser (Lot 54) 21. no internal type names in UI                                                                                                                       
00:01 +21: SurfaceStudioCatalogBrowser (Lot 54) 21. no internal type names in UI                                                                                                                       
00:01 +21: SurfaceStudioCatalogBrowser (Lot 54) 24. error read model builds without throw                                                                                                              
00:01 +22: SurfaceStudioCatalogBrowser (Lot 54) 24. error read model builds without throw                                                                                                              
00:01 +22: SurfaceStudioCatalogBrowser (Lot 54) 25. derived row fields drive display                                                                                                                   
00:01 +23: SurfaceStudioCatalogBrowser (Lot 54) 25. derived row fields drive display                                                                                                                   
00:01 +23: SurfaceStudioCatalogBrowser (Lot 54) 28. builds without ProviderScope                                                                                                                       
00:02 +23: SurfaceStudioCatalogBrowser (Lot 54) 28. builds without ProviderScope                                                                                                                       
00:02 +24: SurfaceStudioCatalogBrowser (Lot 54) 28. builds without ProviderScope                                                                                                                       
00:02 +24: SurfaceStudioCatalogBrowser (Lot 54) 29. accepts bounded width                                                                                                                              
00:02 +25: SurfaceStudioCatalogBrowser (Lot 54) 29. accepts bounded width                                                                                                                              
00:02 +25: SurfaceStudioCatalogBrowser (Lot 54) 30. public map_core only (import smoke)                                                                                                                
00:02 +26: SurfaceStudioCatalogBrowser (Lot 54) 30. public map_core only (import smoke)                                                                                                                
00:02 +26: All tests passed!                                                                                                                                                                           

```

### D4 Lot 52 (panel)
```text

00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart                                                                           
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart                                                                           
00:01 +0: SurfaceStudioPanel (Lot 52) 1. title Surface Studio is visible                                                                                                                               
00:01 +1: SurfaceStudioPanel (Lot 52) 1. title Surface Studio is visible                                                                                                                               
00:01 +1: SurfaceStudioPanel (Lot 52) 2. read-only badge is visible                                                                                                                                    
00:01 +2: SurfaceStudioPanel (Lot 52) 2. read-only badge is visible                                                                                                                                    
00:01 +2: SurfaceStudioPanel (Lot 52) 3. three counters are zero for empty catalog                                                                                                                     
00:01 +3: SurfaceStudioPanel (Lot 52) 3. three counters are zero for empty catalog                                                                                                                     
00:01 +3: SurfaceStudioPanel (Lot 52) 4. empty catalog shows empty state copy                                                                                                                          
00:01 +4: SurfaceStudioPanel (Lot 52) 4. empty catalog shows empty state copy                                                                                                                          
00:01 +4: SurfaceStudioPanel (Lot 52) 5. minimal catalog shows 1/1/1                                                                                                                                   
00:01 +5: SurfaceStudioPanel (Lot 52) 5. minimal catalog shows 1/1/1                                                                                                                                   
00:01 +5: SurfaceStudioPanel (Lot 52) 6. non-empty shows catalog browser content                                                                                                                       
00:01 +6: SurfaceStudioPanel (Lot 52) 6. non-empty shows catalog browser content                                                                                                                       
00:01 +6: SurfaceStudioPanel (Lot 52) 7. clean diagnostics for minimal coherent catalog                                                                                                                
00:01 +7: SurfaceStudioPanel (Lot 52) 7. clean diagnostics for minimal coherent catalog                                                                                                                
00:01 +7: SurfaceStudioPanel (Lot 52) 8. warning state when unused atlas                                                                                                                               
00:01 +8: SurfaceStudioPanel (Lot 52) 8. warning state when unused atlas                                                                                                                               
00:01 +8: SurfaceStudioPanel (Lot 52) 9. error state when preset animation missing                                                                                                                     
00:01 +9: SurfaceStudioPanel (Lot 52) 9. error state when preset animation missing                                                                                                                     
00:01 +9: SurfaceStudioPanel (Lot 52) 10. future action labels are visible                                                                                                                             
00:01 +10: SurfaceStudioPanel (Lot 52) 10. future action labels are visible                                                                                                                            
00:01 +10: SurfaceStudioPanel (Lot 52) 11. future actions are disabled (onPressed null)                                                                                                                
00:01 +11: SurfaceStudioPanel (Lot 52) 11. future actions are disabled (onPressed null)                                                                                                                
00:01 +11: SurfaceStudioPanel (Lot 52) 12. section placeholder titles are visible                                                                                                                      
00:01 +12: SurfaceStudioPanel (Lot 52) 12. section placeholder titles are visible                                                                                                                      
00:01 +12: SurfaceStudioPanel (Lot 52) 13. SurfaceStudioPanelFromManifest uses manifest catalog                                                                                                        
00:01 +13: SurfaceStudioPanel (Lot 52) 13. SurfaceStudioPanelFromManifest uses manifest catalog                                                                                                        
00:01 +13: SurfaceStudioPanel (Lot 52) 14. manifest is not mutated after pump                                                                                                                          
00:01 +14: SurfaceStudioPanel (Lot 52) 14. manifest is not mutated after pump                                                                                                                          
00:01 +14: SurfaceStudioPanel (Lot 52) 15. does not require provider setup — panel builds without ProviderScope                                                                                        
00:02 +14: SurfaceStudioPanel (Lot 52) 15. does not require provider setup — panel builds without ProviderScope                                                                                        
00:02 +15: SurfaceStudioPanel (Lot 52) 15. does not require provider setup — panel builds without ProviderScope                                                                                        
00:02 +15: SurfaceStudioPanel (Lot 52) 16. content is in a scrollable                                                                                                                                  
00:02 +16: SurfaceStudioPanel (Lot 52) 16. content is in a scrollable                                                                                                                                  
00:02 +16: SurfaceStudioPanel (Lot 52) 17. no internal domain type names in user-visible strings                                                                                                       
00:02 +17: SurfaceStudioPanel (Lot 52) 17. no internal domain type names in user-visible strings                                                                                                       
00:02 +17: SurfaceStudioPanel (Lot 52) 18. error read model does not throw on build                                                                                                                    
00:02 +18: SurfaceStudioPanel (Lot 52) 18. error read model does not throw on build                                                                                                                    
00:02 +18: SurfaceStudioPanel (Lot 52) 19. warning read model does not throw on build                                                                                                                  
00:02 +19: SurfaceStudioPanel (Lot 52) 19. warning read model does not throw on build                                                                                                                  
00:02 +19: SurfaceStudioPanel (Lot 52) 20. displayed counts match read model summary                                                                                                                   
00:02 +20: SurfaceStudioPanel (Lot 52) 20. displayed counts match read model summary                                                                                                                   
00:02 +20: SurfaceStudioPanel (Lot 52) 22. no TextField in panel                                                                                                                                       
00:02 +21: SurfaceStudioPanel (Lot 52) 22. no TextField in panel                                                                                                                                       
00:02 +21: SurfaceStudioPanel (Lot 52) 23. no save affordances                                                                                                                                         
00:02 +22: SurfaceStudioPanel (Lot 52) 23. no save affordances                                                                                                                                         
00:02 +22: SurfaceStudioPanel (Lot 52) 22. panel shows catalog browser for minimal catalog                                                                                                             
00:02 +23: SurfaceStudioPanel (Lot 52) 22. panel shows catalog browser for minimal catalog                                                                                                             
00:02 +23: SurfaceStudioPanel (Lot 52) 24. test file uses public map_core only (smoke)                                                                                                                 
00:02 +24: SurfaceStudioPanel (Lot 52) 24. test file uses public map_core only (smoke)                                                                                                                 
00:02 +24: SurfaceStudioPanel (Lot 52) 25. Lot 55 — clean diagnostics view in panel                                                                                                                    
00:02 +25: SurfaceStudioPanel (Lot 52) 25. Lot 55 — clean diagnostics view in panel                                                                                                                    
00:02 +25: SurfaceStudioPanel (Lot 52) 26. Lot 55 — error diagnostics visible in panel                                                                                                                 
00:02 +26: SurfaceStudioPanel (Lot 52) 26. Lot 55 — error diagnostics visible in panel                                                                                                                 
00:02 +26: SurfaceStudioPanel (Lot 52) 27. Lot 55 — browser and diagnostics cohabit (minimal cat)                                                                                                      
00:02 +27: SurfaceStudioPanel (Lot 52) 27. Lot 55 — browser and diagnostics cohabit (minimal cat)                                                                                                      
00:02 +27: SurfaceStudioPanel (Lot 52) 30. Lot 55 — surfaceCatalog unchanged after panel pump                                                                                                          
00:02 +28: SurfaceStudioPanel (Lot 52) 30. Lot 55 — surfaceCatalog unchanged after panel pump                                                                                                          
00:02 +28: All tests passed!                                                                                                                                                                           

```

### D5 Lot 53
```text

00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart                                                                 
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart                                                                 
00:02 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart                                                                 
00:03 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart                                                                 
00:04 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart                                                                 
00:05 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart                                                                 
00:05 +0: Surface Studio workspace entry (Lot 53) EditorWorkspaceMode.surfaceStudio exists in enum                                                                                                     
00:05 +1: Surface Studio workspace entry (Lot 53) EditorWorkspaceMode.surfaceStudio exists in enum                                                                                                     
00:05 +1: Surface Studio workspace entry (Lot 53) entry title Surface Studio is visible in explorer                                                                                                    
00:06 +1: Surface Studio workspace entry (Lot 53) entry title Surface Studio is visible in explorer                                                                                                    
00:06 +2: Surface Studio workspace entry (Lot 53) entry title Surface Studio is visible in explorer                                                                                                    
00:06 +2: Surface Studio workspace entry (Lot 53) subtitle mentions animated surfaces (Surfaces animées)                                                                                               
00:06 +3: Surface Studio workspace entry (Lot 53) subtitle mentions animated surfaces (Surfaces animées)                                                                                               
00:06 +3: Surface Studio workspace entry (Lot 53) Terrain / Surface Studio / Path Library order in column                                                                                              
00:06 +4: Surface Studio workspace entry (Lot 53) Terrain / Surface Studio / Path Library order in column                                                                                              
00:06 +4: Surface Studio workspace entry (Lot 53) tap entry opens center panel with Lecture seule                                                                                                      
00:07 +4: Surface Studio workspace entry (Lot 53) tap entry opens center panel with Lecture seule                                                                                                      
00:07 +5: Surface Studio workspace entry (Lot 53) tap entry opens center panel with Lecture seule                                                                                                      
00:07 +5: Surface Studio workspace entry (Lot 53) EditorCanvasHost builds SurfaceStudioPanel in surface mode                                                                                           
00:07 +6: Surface Studio workspace entry (Lot 53) EditorCanvasHost builds SurfaceStudioPanel in surface mode                                                                                           
00:07 +6: Surface Studio workspace entry (Lot 53) works without an active map (no map required)                                                                                                        
00:07 +7: Surface Studio workspace entry (Lot 53) works without an active map (no map required)                                                                                                        
00:07 +7: Surface Studio workspace entry (Lot 53) panel shows 1/1/1 from manifest when catalog is minimal                                                                                              
00:07 +8: Surface Studio workspace entry (Lot 53) panel shows 1/1/1 from manifest when catalog is minimal                                                                                              
00:07 +8: Surface Studio workspace entry (Lot 53) read-only: future action CupertinoButtons are disabled, no TextField                                                                                 
00:07 +9: Surface Studio workspace entry (Lot 53) read-only: future action CupertinoButtons are disabled, no TextField                                                                                 
00:07 +9: Surface Studio workspace entry (Lot 53) no Surface save button labels                                                                                                                        
00:08 +9: Surface Studio workspace entry (Lot 53) no Surface save button labels                                                                                                                        
00:08 +10: Surface Studio workspace entry (Lot 53) no Surface save button labels                                                                                                                       
00:08 +10: Surface Studio workspace entry (Lot 53) no internal type names in visible shell copy                                                                                                        
00:08 +11: Surface Studio workspace entry (Lot 53) no internal type names in visible shell copy                                                                                                        
00:08 +11: All tests passed!                                                                                                                                                                           

```

### D6 map_core Lot 51
```text

00:00 [32m+0[0m: [1m[90mloading test/surface_studio_read_model_test.dart[0m[0m                                                                                                                                             
00:00 [32m+0[0m: Surface Studio read model (Lot 51) 1. empty catalog: summary, lists, clean diagnostics[0m                                                                                                       
00:00 [32m+1[0m: Surface Studio read model (Lot 51) 1. empty catalog: summary, lists, clean diagnostics[0m                                                                                                       
00:00 [32m+1[0m: Surface Studio read model (Lot 51) 2. buildSurfaceStudioReadModel uses manifest catalog; no manifest mutation[0m                                                                                
00:00 [32m+2[0m: Surface Studio read model (Lot 51) 2. buildSurfaceStudioReadModel uses manifest catalog; no manifest mutation[0m                                                                                
00:00 [32m+2[0m: Surface Studio read model (Lot 51) 3. minimal water — summary counts and non-empty[0m                                                                                                           
00:00 [32m+3[0m: Surface Studio read model (Lot 51) 3. minimal water — summary counts and non-empty[0m                                                                                                           
00:00 [32m+3[0m: Surface Studio read model (Lot 51) 4. minimal water — atlas row main fields[0m                                                                                                                  
00:00 [32m+4[0m: Surface Studio read model (Lot 51) 4. minimal water — atlas row main fields[0m                                                                                                                  
00:00 [32m+4[0m: Surface Studio read model (Lot 51) 5. atlas rows preserve catalog order[0m                                                                                                                      
00:00 [32m+5[0m: Surface Studio read model (Lot 51) 5. atlas rows preserve catalog order[0m                                                                                                                      
00:00 [32m+5[0m: Surface Studio read model (Lot 51) 6. atlas usedByAnimationIds — two animations, one atlas[0m                                                                                                   
00:00 [32m+6[0m: Surface Studio read model (Lot 51) 6. atlas usedByAnimationIds — two animations, one atlas[0m                                                                                                   
00:00 [32m+6[0m: Surface Studio read model (Lot 51) 7. atlas usedByAnimationIds — one animation twice same atlas[0m                                                                                              
00:00 [32m+7[0m: Surface Studio read model (Lot 51) 7. atlas usedByAnimationIds — one animation twice same atlas[0m                                                                                              
00:00 [32m+7[0m: Surface Studio read model (Lot 51) 8. minimal water — animation row main fields[0m                                                                                                              
00:00 [32m+8[0m: Surface Studio read model (Lot 51) 8. minimal water — animation row main fields[0m                                                                                                              
00:00 [32m+8[0m: Surface Studio read model (Lot 51) 9. animation rows preserve catalog order[0m                                                                                                                  
00:00 [32m+9[0m: Surface Studio read model (Lot 51) 9. animation rows preserve catalog order[0m                                                                                                                  
00:00 [32m+9[0m: Surface Studio read model (Lot 51) 10. animation referencedAtlasIds — first appearance order[0m                                                                                                 
00:00 [32m+10[0m: Surface Studio read model (Lot 51) 10. animation referencedAtlasIds — first appearance order[0m                                                                                                
00:00 [32m+10[0m: Surface Studio read model (Lot 51) 11. animation read model does not validate atlas existence[0m                                                                                               
00:00 [32m+11[0m: Surface Studio read model (Lot 51) 11. animation read model does not validate atlas existence[0m                                                                                               
00:00 [32m+11[0m: Surface Studio read model (Lot 51) 12. minimal water — preset row main fields[0m                                                                                                               
00:00 [32m+12[0m: Surface Studio read model (Lot 51) 12. minimal water — preset row main fields[0m                                                                                                               
00:00 [32m+12[0m: Surface Studio read model (Lot 51) 13. preset rows preserve catalog order[0m                                                                                                                   
00:00 [32m+13[0m: Surface Studio read model (Lot 51) 13. preset rows preserve catalog order[0m                                                                                                                   
00:00 [32m+13[0m: Surface Studio read model (Lot 51) 14. preset referencedAnimationIds — dedupe keeps order[0m                                                                                                   
00:00 [32m+14[0m: Surface Studio read model (Lot 51) 14. preset referencedAnimationIds — dedupe keeps order[0m                                                                                                   
00:00 [32m+14[0m: Surface Studio read model (Lot 51) 15. preset read model does not validate animation existence[0m                                                                                              
00:00 [32m+15[0m: Surface Studio read model (Lot 51) 15. preset read model does not validate animation existence[0m                                                                                              
00:00 [32m+15[0m: Surface Studio read model (Lot 51) 16. full water — preset role order cross, isolated, horizontal[0m                                                                                           
00:00 [32m+16[0m: Surface Studio read model (Lot 51) 16. full water — preset role order cross, isolated, horizontal[0m                                                                                           
00:00 [32m+16[0m: Surface Studio read model (Lot 51) 17. minimal water — diagnostics clean flags on read model[0m                                                                                                
00:00 [32m+17[0m: Surface Studio read model (Lot 51) 17. minimal water — diagnostics clean flags on read model[0m                                                                                                
00:00 [32m+17[0m: Surface Studio read model (Lot 51) 18. diagnostics error — missing animation atlas[0m                                                                                                          
00:00 [32m+18[0m: Surface Studio read model (Lot 51) 18. diagnostics error — missing animation atlas[0m                                                                                                          
00:00 [32m+18[0m: Surface Studio read model (Lot 51) 19. diagnostics error — missing preset animation[0m                                                                                                         
00:00 [32m+19[0m: Surface Studio read model (Lot 51) 19. diagnostics error — missing preset animation[0m                                                                                                         
00:00 [32m+19[0m: Surface Studio read model (Lot 51) 20. diagnostics warning — unused atlas[0m                                                                                                                   
00:00 [32m+20[0m: Surface Studio read model (Lot 51) 20. diagnostics warning — unused atlas[0m                                                                                                                   
00:00 [32m+20[0m: Surface Studio read model (Lot 51) 21. root lists are unmodifiable[0m                                                                                                                          
00:00 [32m+21[0m: Surface Studio read model (Lot 51) 21. root lists are unmodifiable[0m                                                                                                                          
00:00 [32m+21[0m: Surface Studio read model (Lot 51) 22. nested lists are unmodifiable[0m                                                                                                                        
00:00 [32m+22[0m: Surface Studio read model (Lot 51) 22. nested lists are unmodifiable[0m                                                                                                                        
00:00 [32m+22[0m: Surface Studio read model (Lot 51) 23. builder does not order by sortOrder — source list order[0m                                                                                              
00:00 [32m+23[0m: Surface Studio read model (Lot 51) 23. builder does not order by sortOrder — source list order[0m                                                                                              
00:00 [32m+23[0m: Surface Studio read model (Lot 51) 24. builder does not mutate the source catalog[0m                                                                                                           
00:00 [32m+24[0m: Surface Studio read model (Lot 51) 24. builder does not mutate the source catalog[0m                                                                                                           
00:00 [32m+24[0m: Surface Studio read model (Lot 51) 25. value equality of read models for equivalent catalogs[0m                                                                                                
00:00 [32m+25[0m: Surface Studio read model (Lot 51) 25. value equality of read models for equivalent catalogs[0m                                                                                                
00:00 [32m+25[0m: Surface Studio read model (Lot 51) 26. inequality when content differs[0m                                                                                                                      
00:00 [32m+26[0m: Surface Studio read model (Lot 51) 26. inequality when content differs[0m                                                                                                                      
00:00 [32m+26[0m: Surface Studio read model (Lot 51) 27. public export — map_core[0m                                                                                                                             
00:00 [32m+27[0m: Surface Studio read model (Lot 51) 27. public export — map_core[0m                                                                                                                             
00:00 [32m+27[0m: Surface Studio read model (Lot 51) 28. ProjectManifest toJson still Lot 49 — surfaceCatalog only[0m                                                                                            
00:00 [32m+28[0m: Surface Studio read model (Lot 51) 28. ProjectManifest toJson still Lot 49 — surfaceCatalog only[0m                                                                                            
00:00 [32m+28[0m: Surface Studio read model (Lot 51) 29. Lot 47 fixtures — valid JSON, no top-level surfaceCatalog[0m                                                                                            
00:00 [32m+29[0m: Surface Studio read model (Lot 51) 29. Lot 47 fixtures — valid JSON, no top-level surfaceCatalog[0m                                                                                            
00:00 [32m+29[0m: Surface Studio read model (Lot 51) 30. no Flutter / Riverpod in surface read model public API[0m                                                                                               
00:00 [32m+30[0m: Surface Studio read model (Lot 51) 30. no Flutter / Riverpod in surface read model public API[0m                                                                                               
00:00 [32m+30[0m: All tests passed![0m                                                                                                                                                                           

```

### D7 `flutter analyze`
```text
Analyzing 9 items...                                            
No issues found! (ran in 5.5s)

```

### D8 Combiné (5 tests surface_studio) — dernière ligne
```text
00:06 +115: All tests passed!
```

**Commande** : `cd packages/map_editor && flutter test` + les 5 chemins `test/surface_studio/…` (voir D8 complet).

**Total tests combinés** : 115 (ligne de fin `+115: All tests passed!`).

### D8 complet
```text

00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_detail_view_test.dart                                                               
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_detail_view_test.dart                                                               
00:02 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_detail_view_test.dart                                                               
00:02 +0: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_detail_view_test.dart: SurfaceStudioAtlasDetailView (Lot 56) 1. title Atlas Surface         
00:03 +0: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_detail_view_test.dart: SurfaceStudioAtlasDetailView (Lot 56) 1. title Atlas Surface         
00:03 +1: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_diagnostics_view_test.dart: SurfaceStudioDiagnosticsView (Lot 55) 1. title Diagnostics Surface    
00:03 +2: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_diagnostics_view_test.dart: SurfaceStudioDiagnosticsView (Lot 55) 1. title Diagnostics Surface    
00:03 +3: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_diagnostics_view_test.dart: SurfaceStudioDiagnosticsView (Lot 55) 1. title Diagnostics Surface    
00:03 +4: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: ... (Lot 54) 1. browser shows title Catalogue Surface                  
00:03 +5: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: ... (Lot 54) 1. browser shows title Catalogue Surface                  
00:03 +6: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: ... (Lot 54) 1. browser shows title Catalogue Surface                  
00:03 +7: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: ... (Lot 54) 1. browser shows title Catalogue Surface                  
00:03 +8: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: ... (Lot 54) 1. browser shows title Catalogue Surface                  
00:03 +9: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: ... (Lot 54) 1. browser shows title Catalogue Surface                  
00:03 +10: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: ... (Lot 54) 1. browser shows title Catalogue Surface                 
00:03 +11: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: ... (Lot 54) 1. browser shows title Catalogue Surface                 
00:03 +12: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: ... (Lot 54) 1. browser shows title Catalogue Surface                 
00:03 +13: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: ... (Lot 54) 1. browser shows title Catalogue Surface                 
00:03 +14: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: ... (Lot 54) 1. browser shows title Catalogue Surface                 
00:03 +15: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: ... (Lot 54) 1. browser shows title Catalogue Surface                 
00:03 +16: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: ... (Lot 54) 1. browser shows title Catalogue Surface                 
00:03 +17: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: ... (Lot 54) 1. browser shows title Catalogue Surface                 
00:03 +18: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: ... (Lot 54) 1. browser shows title Catalogue Surface                 
00:03 +19: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 1. title Surface Studio is visible                  
00:03 +20: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 1. title Surface Studio is visible                  
00:03 +21: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 1. title Surface Studio is visible                  
00:03 +22: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 1. title Surface Studio is visible                  
00:03 +23: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 1. title Surface Studio is visible                  
00:03 +24: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 1. title Surface Studio is visible                  
00:03 +25: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 1. title Surface Studio is visible                  
00:03 +26: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 1. title Surface Studio is visible                  
00:03 +27: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 1. title Surface Studio is visible                  
00:03 +28: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 1. title Surface Studio is visible                  
00:03 +29: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 1. title Surface Studio is visible                  
00:03 +30: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 1. title Surface Studio is visible                  
00:03 +31: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 1. title Surface Studio is visible                  
00:03 +32: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 1. title Surface Studio is visible                  
00:03 +33: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 1. title Surface Studio is visible                  
00:04 +33: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 1. title Surface Studio is visible                  
00:04 +34: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 1. title Surface Studio is visible                  
00:04 +35: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:04 +36: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:04 +37: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:04 +38: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:04 +39: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:04 +40: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:04 +41: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:04 +42: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:04 +43: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:04 +44: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:04 +45: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:04 +46: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:04 +47: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:04 +48: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:04 +49: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:04 +50: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:04 +51: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:04 +52: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:04 +53: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:04 +54: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:04 +55: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:04 +56: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:04 +57: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:04 +58: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:04 +59: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:04 +60: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:04 +61: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:04 +62: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:04 +63: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:04 +64: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:04 +65: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:04 +66: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:04 +67: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:04 +68: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:04 +69: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:04 +70: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:04 +71: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:04 +72: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:04 +73: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:04 +74: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:04 +75: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:04 +76: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:04 +77: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:04 +78: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:04 +79: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:04 +80: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:04 +81: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:04 +82: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:04 +83: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:04 +84: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:04 +85: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:04 +86: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:04 +87: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:04 +88: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:04 +89: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:04 +90: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:04 +91: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:04 +92: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:04 +93: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 16. content is in a scrollable                      
00:04 +94: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... (Lot 53) subtitle mentions animated surfaces (Surfaces animées)   
00:04 +95: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... (Lot 53) subtitle mentions animated surfaces (Surfaces animées)   
00:04 +96: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... (Lot 53) subtitle mentions animated surfaces (Surfaces animées)   
00:05 +96: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... (Lot 53) subtitle mentions animated surfaces (Surfaces animées)   
00:05 +97: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... (Lot 53) subtitle mentions animated surfaces (Surfaces animées)   
00:05 +98: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... (Lot 53) subtitle mentions animated surfaces (Surfaces animées)   
00:05 +99: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... (Lot 53) subtitle mentions animated surfaces (Surfaces animées)   
00:05 +100: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 23. no save affordances                            
00:05 +101: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... (Lot 53) Terrain / Surface Studio / Path Library order in column 
00:05 +102: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... (Lot 53) Terrain / Surface Studio / Path Library order in column 
00:05 +103: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... (Lot 53) Terrain / Surface Studio / Path Library order in column 
00:05 +104: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... (Lot 53) Terrain / Surface Studio / Path Library order in column 
00:05 +105: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... (Lot 53) Terrain / Surface Studio / Path Library order in column 
00:05 +106: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... (Lot 53) Terrain / Surface Studio / Path Library order in column 
00:05 +107: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: ... (Lot 52) 30. Lot 55 — surfaceCatalog unchanged after panel pump            
00:05 +108: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) tap entry opens center panel with Lecture seule   
00:05 +109: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) tap entry opens center panel with Lecture seule   
00:05 +109: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... 53) EditorCanvasHost builds SurfaceStudioPanel in surface mode   
00:05 +110: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... 53) EditorCanvasHost builds SurfaceStudioPanel in surface mode   
00:05 +110: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) works without an active map (no map required)     
00:06 +110: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) works without an active map (no map required)     
00:06 +111: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) works without an active map (no map required)     
00:06 +111: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... (Lot 53) panel shows 1/1/1 from manifest when catalog is minimal 
00:06 +112: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... (Lot 53) panel shows 1/1/1 from manifest when catalog is minimal 
00:06 +112: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... future action CupertinoButtons are disabled, no TextField        
00:06 +113: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... future action CupertinoButtons are disabled, no TextField        
00:06 +113: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry (Lot 53) no Surface save button labels
00:06 +114: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry (Lot 53) no Surface save button labels
00:06 +114: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) no internal type names in visible shell copy      
00:06 +115: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) no internal type names in visible shell copy      
00:06 +115: All tests passed!                                                                                                                                                                          

```
