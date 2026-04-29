import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_atlas_grid_preview.dart';

void main() {
  testWidgets('section visible et métriques de grille', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const SurfaceStudioAtlasGridPreview(
          sourceLabel: 'eau_atlas',
          tileWidth: 32,
          tileHeight: 32,
          columns: 4,
          rows: 8,
          layoutLabel: 'Grille libre',
        ),
      ),
    );

    expect(
        find.byKey(kSurfaceStudioAtlasGridPreviewSectionKey), findsOneWidget);
    expect(find.text('Aperçu de la grille atlas'), findsOneWidget);
    expect(find.text('Source : eau_atlas'), findsOneWidget);
    expect(find.text('Tile : 32×32 px'), findsOneWidget);
    expect(find.text('Grille : 4 colonnes × 8 lignes'), findsOneWidget);
    expect(find.text('Total : 32 cases'), findsOneWidget);
    expect(find.text('Disposition : Grille libre'), findsOneWidget);
  });

  testWidgets('état vide sans source', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const SurfaceStudioAtlasGridPreview(
          sourceLabel: null,
          tileWidth: 32,
          tileHeight: 32,
          columns: 4,
          rows: 8,
          layoutLabel: 'Grille libre',
        ),
      ),
    );

    expect(
      find.text('Choisissez une image source pour prévisualiser la grille.'),
      findsOneWidget,
    );
  });

  testWidgets('état invalide dimensions', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const SurfaceStudioAtlasGridPreview(
          sourceLabel: 'eau_atlas',
          tileWidth: 0,
          tileHeight: 32,
          columns: 4,
          rows: 8,
          layoutLabel: 'Grille libre',
        ),
      ),
    );

    expect(
      find.text('Corrigez les dimensions de grille pour afficher la preview.'),
      findsOneWidget,
    );
  });

  testWidgets('aperçu réduit si grille grande', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const SurfaceStudioAtlasGridPreview(
          sourceLabel: 'eau_atlas',
          tileWidth: 16,
          tileHeight: 16,
          columns: 20,
          rows: 10,
          layoutLabel: 'Grille libre',
        ),
      ),
    );

    expect(find.text('Aperçu réduit'), findsOneWidget);
    expect(find.byKey(const ValueKey('surface_studio_grid_cell_95')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('surface_studio_grid_cell_96')),
        findsNothing);
  });

  testWidgets('pas de jargon interdit dans la preview', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const SurfaceStudioAtlasGridPreview(
          sourceLabel: 'eau_atlas',
          tileWidth: 32,
          tileHeight: 32,
          columns: 2,
          rows: 2,
          layoutLabel: 'Grille libre',
        ),
      ),
    );

    for (final term in const <String>[
      'tilesetId',
      'ProjectSurfaceAtlas',
      'ProjectSurfaceCatalog',
      'SurfaceStudioReadModel',
      'callback',
      'copyWith',
    ]) {
      expect(find.textContaining(term), findsNothing);
    }
  });
}

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: child,
      ),
    ),
  );
}
