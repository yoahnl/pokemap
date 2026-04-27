import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_atlas_authoring_prep.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_selection.dart';

void main() {
  group('SurfaceStudioAtlasAuthoringPrep (Lot 60)', () {
    testWidgets('titre, brouillon local, défauts 32/1/1', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAtlasAuthoringPrep(
            readModel: _minimalRead(),
            selection: const SurfaceStudioSelection.none(),
          ),
        ),
      );
      expect(find.text('Préparation atlas'), findsOneWidget);
      expect(find.text('Brouillon local non sauvegardé'), findsOneWidget);
      expect(find.text('Brouillon local'), findsOneWidget);
      expect(find.text('Non sauvegardé'), findsOneWidget);
      final w = find.byKey(const ValueKey('atlas_draft_tile_w'));
      final h = find.byKey(const ValueKey('atlas_draft_tile_h'));
      final c = find.byKey(const ValueKey('atlas_draft_cols'));
      final r = find.byKey(const ValueKey('atlas_draft_rows'));
      expect(
        (tester.widget(w) as TextField).controller!.text,
        '32',
      );
      expect(
        (tester.widget(h) as TextField).controller!.text,
        '32',
      );
      expect(
        (tester.widget(c) as TextField).controller!.text,
        '1',
      );
      expect(
        (tester.widget(r) as TextField).controller!.text,
        '1',
      );
    });

    testWidgets('id / nom / tileset vides: erreurs', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAtlasAuthoringPrep(
            readModel: _emptyReadModel(),
            selection: const SurfaceStudioSelection.none(),
          ),
        ),
      );
      expect(find.text('Identifiant requis'), findsOneWidget);
      expect(find.text('Nom requis'), findsOneWidget);
      expect(find.text('Identifiant tileset requis'), findsOneWidget);
    });

    testWidgets('taille tuile x non entier: erreur', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAtlasAuthoringPrep(
            readModel: _minimalRead(),
            selection: const SurfaceStudioSelection.none(),
          ),
        ),
      );
      final w = find.byKey(const ValueKey('atlas_draft_tile_w'));
      await tester.enterText(w, 'abc');
      await tester.pump();
      expect(find.text('Largeur de tuile : entier requis'), findsOneWidget);
    });

    testWidgets('hauteur / colonnes / lignes <= 0: erreur', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAtlasAuthoringPrep(
            readModel: _minimalRead(),
            selection: const SurfaceStudioSelection.none(),
          ),
        ),
      );
      final idF = find.byKey(const ValueKey('atlas_draft_id'));
      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
      final tsF = find.byKey(const ValueKey('atlas_draft_tileset'));
      final hF = find.byKey(const ValueKey('atlas_draft_tile_h'));
      final cF = find.byKey(const ValueKey('atlas_draft_cols'));
      final rF = find.byKey(const ValueKey('atlas_draft_rows'));
      final sF = find.byKey(const ValueKey('atlas_draft_sort'));
      await tester.enterText(idF, 'n');
      await tester.enterText(nameF, 'N');
      await tester.enterText(tsF, 't');
      await tester.enterText(hF, '0');
      await tester.pump();
      expect(
        find.text('Hauteur de tuile : valeur positive requise'),
        findsOneWidget,
      );
      await tester.enterText(hF, '32');
      await tester.enterText(cF, '0');
      await tester.pump();
      expect(
        find.text('Colonnes : valeur positive requise'),
        findsOneWidget,
      );
      await tester.enterText(cF, '1');
      await tester.enterText(rF, '0');
      await tester.pump();
      expect(find.text('Lignes : valeur positive requise'), findsOneWidget);
      await tester.enterText(rF, '1');
      await tester.enterText(sF, 'notint');
      await tester.pump();
      expect(find.text('Ordre : entier requis'), findsOneWidget);
    });

    testWidgets('sortOrder négatif: erreur', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAtlasAuthoringPrep(
            readModel: _minimalRead(),
            selection: const SurfaceStudioSelection.none(),
          ),
        ),
      );
      final idF = find.byKey(const ValueKey('atlas_draft_id'));
      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
      final tsF = find.byKey(const ValueKey('atlas_draft_tileset'));
      final sF = find.byKey(const ValueKey('atlas_draft_sort'));
      await tester.enterText(idF, 'n');
      await tester.enterText(nameF, 'N');
      await tester.enterText(tsF, 't');
      await tester.enterText(sF, '-1');
      await tester.pump();
      expect(
        find.text('Ordre : valeur négative interdite pour ce brouillon'),
        findsOneWidget,
      );
    });

    testWidgets('id dupliqué cat sans exemption: erreur', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAtlasAuthoringPrep(
            readModel: _minimalRead(),
            selection: const SurfaceStudioSelection.none(),
          ),
        ),
      );
      final idF = find.byKey(const ValueKey('atlas_draft_id'));
      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
      final tsF = find.byKey(const ValueKey('atlas_draft_tileset'));
      await tester.enterText(idF, 'water-atlas');
      await tester.enterText(nameF, 'X');
      await tester.enterText(tsF, 't');
      await tester.pump();
      expect(
        find.text('Cet identifiant existe déjà dans le catalogue'),
        findsOneWidget,
      );
    });

    testWidgets('Charger la sélection: champs = atlas, catalogue inchangé',
        (tester) async {
      final rm = _minimalRead();
      final beforeCat = rm.catalog;
      final sel = SurfaceStudioSelection.atlas('water-atlas');
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAtlasAuthoringPrep(
            readModel: rm,
            selection: sel,
          ),
        ),
      );
      await tester.tap(
        find.text('Charger la sélection dans le brouillon'),
      );
      await tester.pump();
      final idF = find.byKey(const ValueKey('atlas_draft_id'));
      expect(
        (tester.widget(idF) as TextField).controller!.text,
        'water-atlas',
      );
      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
      expect(
        (tester.widget(nameF) as TextField).controller!.text,
        'Water Atlas',
      );
      final tsF = find.byKey(const ValueKey('atlas_draft_tileset'));
      expect(
        (tester.widget(tsF) as TextField).controller!.text,
        'nature-tileset',
      );
      expect(identical(rm.catalog, beforeCat), isTrue);
    });

    testWidgets('sélection animation: brouillon stable + note', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAtlasAuthoringPrep(
            readModel: _minimalRead(),
            selection: SurfaceStudioSelection.animation('water-isolated-loop'),
          ),
        ),
      );
      expect(
        find.text('La sélection actuelle n’est pas un atlas.'),
        findsOneWidget,
      );
      expect(
        (tester.widget(find.byKey(const ValueKey('atlas_draft_id')))
                as TextField)
            .controller!
            .text
            .isEmpty,
        isTrue,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('sélection atlas manquant: note + stable', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAtlasAuthoringPrep(
            readModel: _minimalRead(),
            selection: SurfaceStudioSelection.atlas('nope-missing'),
          ),
        ),
      );
      expect(
        find.text(
            'Atlas sélectionné introuvable, brouillon atlas indépendant.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('pas de libellés d’action dangereux', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAtlasAuthoringPrep(
            readModel: _minimalRead(),
            selection: const SurfaceStudioSelection.none(),
          ),
        ),
      );
      for (final s in <String>[
        'Sauvegarder',
        'Enregistrer',
        'Créer l’atlas',
        'Modifier l’atlas',
        'Supprimer',
        'Delete',
        'Save',
        'Create',
        'Update',
      ]) {
        expect(find.text(s), findsNothing);
      }
    });

    testWidgets('sans ProviderScope', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAtlasAuthoringPrep(
            readModel: _minimalRead(),
            selection: const SurfaceStudioSelection.none(),
          ),
        ),
      );
      expect(find.byKey(kSurfaceStudioAtlasAuthoringPrepKey), findsOneWidget);
    });

    testWidgets('brouillon valide + prévisu: texte aperçu', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAtlasAuthoringPrep(
            readModel: _emptyReadModel(),
            selection: const SurfaceStudioSelection.none(),
          ),
        ),
      );
      final idF = find.byKey(const ValueKey('atlas_draft_id'));
      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
      final tsF = find.byKey(const ValueKey('atlas_draft_tileset'));
      await tester.enterText(idF, 'new-a');
      await tester.enterText(nameF, 'New');
      await tester.enterText(tsF, 'ts');
      await tester.pump();
      final swFinder = find.byType(Switch);
      await tester.ensureVisible(swFinder);
      await tester.tap(swFinder);
      await tester.pump();
      expect(find.textContaining('Aperçu : 32×32'), findsOneWidget);
    });
  });
}

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    ),
  );
}

SurfaceStudioReadModel _minimalRead() {
  return buildSurfaceStudioReadModelFromCatalog(_cat());
}

SurfaceStudioReadModel _emptyReadModel() {
  return buildSurfaceStudioReadModelFromCatalog(ProjectSurfaceCatalog());
}

ProjectSurfaceCatalog _cat() {
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
