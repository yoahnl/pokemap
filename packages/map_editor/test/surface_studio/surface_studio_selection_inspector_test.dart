// Tests widget — [SurfaceStudioSelectionInspector] (Lot 59).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_selection.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_selection_inspector.dart';

void main() {
  group('SurfaceStudioSelectionInspector (Lot 59)', () {
    testWidgets('1. titre Inspecteur Surface', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioSelectionInspector(
            readModel: _minimalRead(),
            selection: const SurfaceStudioSelection.none(),
          ),
        ),
      );
      expect(find.text('Inspecteur Surface'), findsOneWidget);
    });

    testWidgets('2. badge Lecture seule', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioSelectionInspector(
            readModel: _minimalRead(),
            selection: const SurfaceStudioSelection.none(),
          ),
        ),
      );
      expect(find.text('Lecture seule'), findsOneWidget);
    });

    testWidgets('3. état none', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioSelectionInspector(
            readModel: _minimalRead(),
            selection: const SurfaceStudioSelection.none(),
          ),
        ),
      );
      expect(find.text('Aucune sélection à inspecter'), findsOneWidget);
      expect(
        find.textContaining('Sélectionnez un atlas'),
        findsOneWidget,
      );
    });

    testWidgets('4. atlas introuvable', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioSelectionInspector(
            readModel: _minimalRead(),
            selection: SurfaceStudioSelection.atlas('missing-atlas'),
          ),
        ),
      );
      expect(find.text('Sélection introuvable'), findsOneWidget);
      expect(find.text('missing-atlas'), findsOneWidget);
    });

    testWidgets('5. animation introuvable', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioSelectionInspector(
            readModel: _minimalRead(),
            selection: SurfaceStudioSelection.animation('missing-animation'),
          ),
        ),
      );
      expect(find.text('missing-animation'), findsOneWidget);
    });

    testWidgets('6. preset introuvable', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioSelectionInspector(
            readModel: _minimalRead(),
            selection: SurfaceStudioSelection.preset('missing-preset'),
          ),
        ),
      );
      expect(find.text('missing-preset'), findsOneWidget);
    });

    testWidgets('7–9. atlas sélectionné — identité et champs', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioSelectionInspector(
            readModel: _minimalRead(),
            selection: SurfaceStudioSelection.atlas('water-atlas'),
          ),
        ),
      );
      expect(find.text('Atlas sélectionné'), findsWidgets);
      expect(find.text('Water Atlas'), findsOneWidget);
      expect(
        find.textContaining('Identifiant : water-atlas'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Tileset : nature-tileset'),
        findsOneWidget,
      );
      expect(find.textContaining('Tile : 32×32'), findsOneWidget);
      expect(find.textContaining('Grille : 2×2'), findsOneWidget);
      expect(find.textContaining('4 tuiles'), findsOneWidget);
      expect(
        find.textContaining('Colonnes = variantes, lignes = frames'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Catégorie : Aucune catégorie'),
        findsOneWidget,
      );
      expect(find.textContaining('Ordre : 0'), findsOneWidget);
      expect(
        find.textContaining('Utilisé par 1 animation'),
        findsOneWidget,
      );
      expect(find.text('water-isolated-loop'), findsWidgets);
    });

    testWidgets('10–11. animation sélectionnée', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioSelectionInspector(
            readModel: _minimalRead(),
            selection: SurfaceStudioSelection.animation('water-isolated-loop'),
          ),
        ),
      );
      expect(find.text('Animation sélectionnée'), findsWidgets);
      expect(find.text('Water Isolated Loop'), findsOneWidget);
      expect(
        find.textContaining('Identifiant : water-isolated-loop'),
        findsOneWidget,
      );
      expect(find.textContaining('Frames : 1 frame'), findsOneWidget);
      expect(
        find.textContaining('Durée totale : 120 ms'),
        findsOneWidget,
      );
      expect(find.text('water-atlas'), findsWidgets);
      expect(
        find.textContaining('Groupe de synchronisation : Aucun groupe'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Catégorie : Aucune catégorie'),
        findsOneWidget,
      );
    });

    testWidgets('12–13. preset sélectionné', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioSelectionInspector(
            readModel: _minimalRead(),
            selection: SurfaceStudioSelection.preset('water-surface'),
          ),
        ),
      );
      expect(find.text('Preset sélectionné'), findsWidgets);
      expect(find.text('Water Surface'), findsOneWidget);
      expect(
        find.textContaining('Identifiant : water-surface'),
        findsOneWidget,
      );
      expect(find.textContaining('Variantes : 1 variante'), findsOneWidget);
      expect(find.text('Isolé'), findsWidgets);
      expect(
        find.textContaining('Rôles standards incomplets'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Catégorie : Aucune catégorie'),
        findsOneWidget,
      );
    });

    testWidgets('14. pas de TextField', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioSelectionInspector(
            readModel: _minimalRead(),
            selection: SurfaceStudioSelection.atlas('water-atlas'),
          ),
        ),
      );
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('15. pas de libellés édition / save', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioSelectionInspector(
            readModel: _minimalRead(),
            selection: SurfaceStudioSelection.preset('water-surface'),
          ),
        ),
      );
      for (final s in <String>[
        'Modifier',
        'Supprimer',
        'Enregistrer',
        'Sauvegarder',
        'Save',
        'Edit',
        'Delete',
      ]) {
        expect(find.text(s), findsNothing);
      }
    });

    testWidgets('16. pas de noms de types internes en texte', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioSelectionInspector(
            readModel: _minimalRead(),
            selection: SurfaceStudioSelection.atlas('water-atlas'),
          ),
        ),
      );
      for (final term in <String>[
        'ProjectSurfaceCatalog',
        'ProjectSurfaceAtlas',
        'ProjectSurfaceAnimation',
        'ProjectSurfacePreset',
        'SurfaceStudioReadModel',
        'SurfaceStudioSelection',
        'SurfaceStudioSelectionInspector',
        'SurfaceVariantAnimationRefSet',
        'SurfaceAnimationTimeline',
      ]) {
        expect(
          find.descendant(
            of: find.byKey(kSurfaceStudioSelectionInspectorKey),
            matching: find.textContaining(term),
          ),
          findsNothing,
        );
      }
    });

    testWidgets('17. sans ProviderScope', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioSelectionInspector(
            readModel: _minimalRead(),
            selection: const SurfaceStudioSelection.none(),
          ),
        ),
      );
      expect(find.text('Aucune sélection à inspecter'), findsOneWidget);
    });

    testWidgets('18. largeur contrainte', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 320,
              child: SurfaceStudioSelectionInspector(
                readModel: _minimalRead(),
                selection: SurfaceStudioSelection.preset('water-surface'),
              ),
            ),
          ),
        ),
      );
      expect(find.text('Water Surface'), findsOneWidget);
    });

    testWidgets('19. read model avec diagnostics, sélection valide', (
      tester,
    ) async {
      final rm = buildSurfaceStudioReadModelFromCatalog(
        _catalogWithUnusedAtlas(),
      );
      expect(rm.diagnostics.hasErrors, isFalse);
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioSelectionInspector(
            readModel: rm,
            selection: SurfaceStudioSelection.atlas('used-atlas'),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(
        find.descendant(
          of: find.byKey(kSurfaceStudioSelectionInspectorKey),
          matching: find.text('Diagnostics Surface'),
        ),
        findsNothing,
      );
    });

    testWidgets('20. Lot 67 — callback édition : bouton inspecteur',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioSelectionInspector(
            readModel: _minimalRead(),
            selection: SurfaceStudioSelection.atlas('water-atlas'),
            onRequestEditSelectedAtlas: () {},
          ),
        ),
      );
      expect(
        find.byKey(const ValueKey('surface_studio_inspector_edit_atlas')),
        findsOneWidget,
      );
    });

    testWidgets('21. Lot 67 — sans callback : pas d’edit inspecteur',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioSelectionInspector(
            readModel: _minimalRead(),
            selection: SurfaceStudioSelection.atlas('water-atlas'),
          ),
        ),
      );
      expect(
        find.byKey(const ValueKey('surface_studio_inspector_edit_atlas')),
        findsNothing,
      );
    });

    testWidgets('22. Lot 69 — atlas référencé : préparer suppression absent',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioSelectionInspector(
            readModel: buildSurfaceStudioReadModelFromCatalog(
              _catalogWithUnusedAtlas(),
            ),
            selection: SurfaceStudioSelection.atlas('used-atlas'),
            onConfirmDeleteSelectedAtlas: () {},
          ),
        ),
      );
      expect(
        find.byKey(const ValueKey('surface_studio_inspector_delete_blocked')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('surface_studio_inspector_prepare_delete')),
        findsNothing,
      );
    });

    testWidgets('23. Lot 69 — atlas inutilisé : confirmation en deux étapes',
        (tester) async {
      var del = 0;
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioSelectionInspector(
            readModel: buildSurfaceStudioReadModelFromCatalog(
              _catalogWithUnusedAtlas(),
            ),
            selection: SurfaceStudioSelection.atlas('orphan-atlas'),
            onConfirmDeleteSelectedAtlas: () => del++,
          ),
        ),
      );
      expect(
        find.byKey(const ValueKey('surface_studio_inspector_delete_allowed')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_inspector_prepare_delete')),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_inspector_confirm_delete')),
      );
      await tester.pump();
      expect(del, 1);
    });
  });
}

Widget _wrap(Widget child) {
  return MaterialApp(
    home: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: child,
      ),
    ),
  );
}

SurfaceStudioReadModel _minimalRead() {
  return buildSurfaceStudioReadModelFromCatalog(_minimalCatalog());
}

ProjectSurfaceCatalog _minimalCatalog() {
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
  return ProjectSurfaceCatalog(
    atlases: [atlas],
    animations: [anim],
    presets: [preset],
  );
}

/// Catalogue avec atlas inutilisé (avertissements, pas d’erreur bloquante).
ProjectSurfaceCatalog _catalogWithUnusedAtlas() {
  final g = SurfaceAtlasGeometry(
    tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
    gridSize: SurfaceAtlasGridSize(columns: 2, rows: 2),
    layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
  );
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
    durationMs: 10,
  );
  final anim = ProjectSurfaceAnimation(
    id: 'a',
    name: 'a',
    timeline: SurfaceAnimationTimeline(frames: [f]),
  );
  return ProjectSurfaceCatalog(
    atlases: [used, unused],
    animations: [anim],
    presets: const [],
  );
}
