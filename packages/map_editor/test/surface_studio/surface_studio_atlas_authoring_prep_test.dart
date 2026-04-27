import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_atlas_authoring_prep.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_atlas_grid_preview.dart';
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
      expect(
        find.textContaining('Brouillon : rien n’est écrit sur le disque'),
        findsOneWidget,
      );
      expect(
        find.text('Brouillon local · non sauvegardé · en mémoire seulement'),
        findsOneWidget,
      );
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
      expect(
        find.text('Une source d’image (jeu d’images) est requise'),
        findsOneWidget,
      );
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
      final tsF = find.byKey(const ValueKey('atlas_draft_tileset_advanced'));
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
      final tsF = find.byKey(const ValueKey('atlas_draft_tileset_advanced'));
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

    testWidgets('id dupliqué dans le catalogue: erreur', (tester) async {
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
      final tsF = find.byKey(const ValueKey('atlas_draft_tileset_advanced'));
      await tester.enterText(idF, 'water-atlas');
      await tester.enterText(nameF, 'X');
      await tester.enterText(tsF, 't');
      await tester.pump();
      expect(
        find.text('Un atlas existe déjà avec cet id.'),
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
      final tsF = find.byKey(const ValueKey('atlas_draft_tileset_advanced'));
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
      final tsF = find.byKey(const ValueKey('atlas_draft_tileset_advanced'));
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

  group('SurfaceStudioAtlasAuthoringPrep (Lot 61)', () {
    testWidgets('création brouillon valide émet le catalogue + atlas', (tester) async {
      final out = <ProjectSurfaceCatalog>[];
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAtlasAuthoringPrep(
            readModel: _emptyReadModel(),
            selection: const SurfaceStudioSelection.none(),
            onSurfaceCatalogChanged: out.add,
          ),
        ),
      );
      final idF = find.byKey(const ValueKey('atlas_draft_id'));
      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
      final tsF = find.byKey(const ValueKey('atlas_draft_tileset_advanced'));
      await tester.enterText(idF, 'a-new');
      await tester.enterText(nameF, 'My');
      await tester.enterText(tsF, 'tset');
      await tester.pump();
      final createBtn = find.byKey(
        const ValueKey('surface_studio_create_atlas_work_catalog'),
      );
      await tester.ensureVisible(createBtn);
      await tester.tap(createBtn);
      await tester.pump();
      expect(out, hasLength(1));
      final c = out.single;
      expect(c.atlases, hasLength(1));
      expect(c.animations, isEmpty);
      expect(c.presets, isEmpty);
      final a = c.atlases.single;
      expect(a.id, 'a-new');
      expect(a.name, 'My');
      expect(a.tilesetId, 'tset');
      expect(a.sortOrder, 0);
      expect(a.categoryId, isNull);
      expect(a.geometry.tileSize.width, 32);
      expect(a.geometry.tileSize.height, 32);
      expect(a.geometry.gridSize.columns, 1);
      expect(a.geometry.gridSize.rows, 1);
      expect(a.geometry.layout, SurfaceAtlasLayout.grid);
      expect(
        find.text(
          'Atlas créé dans le catalogue de travail. Sauvegarde projet non effectuée.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('création refusée si brouillon invalide (pas de callback)',
        (tester) async {
      final out = <ProjectSurfaceCatalog>[];
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAtlasAuthoringPrep(
            readModel: _emptyReadModel(),
            selection: const SurfaceStudioSelection.none(),
            onSurfaceCatalogChanged: out.add,
          ),
        ),
      );
      final create = find.descendant(
        of: find.byKey(kSurfaceStudioAtlasAuthoringPrepKey),
        matching: find.byKey(
          const ValueKey('surface_studio_create_atlas_work_catalog'),
        ),
      );
      final btn = tester.widget<CupertinoButton>(create);
      expect(btn.onPressed, isNull);
      expect(out, isEmpty);
    });

    testWidgets('id vide: pas d’appel callback en tap (bouton inactif)',
        (tester) async {
      final out = <ProjectSurfaceCatalog>[];
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAtlasAuthoringPrep(
            readModel: _emptyReadModel(),
            selection: const SurfaceStudioSelection.none(),
            onSurfaceCatalogChanged: out.add,
          ),
        ),
      );
      final idF = find.byKey(const ValueKey('atlas_draft_id'));
      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
      final tsF = find.byKey(const ValueKey('atlas_draft_tileset_advanced'));
      await tester.enterText(nameF, 'N');
      await tester.enterText(tsF, 't');
      await tester.enterText(idF, '');
      await tester.pump();
      final create = find.descendant(
        of: find.byKey(kSurfaceStudioAtlasAuthoringPrepKey),
        matching: find.byKey(
          const ValueKey('surface_studio_create_atlas_work_catalog'),
        ),
      );
      expect(tester.widget<CupertinoButton>(create).onPressed, isNull);
    });

    testWidgets('dupliquer id: création inactivable', (tester) async {
      final out = <ProjectSurfaceCatalog>[];
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAtlasAuthoringPrep(
            readModel: _minimalRead(),
            selection: const SurfaceStudioSelection.none(),
            onSurfaceCatalogChanged: out.add,
          ),
        ),
      );
      final idF = find.byKey(const ValueKey('atlas_draft_id'));
      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
      final tsF = find.byKey(const ValueKey('atlas_draft_tileset_advanced'));
      await tester.enterText(idF, 'water-atlas');
      await tester.enterText(nameF, 'X');
      await tester.enterText(tsF, 't');
      await tester.pump();
      final create = find.descendant(
        of: find.byKey(kSurfaceStudioAtlasAuthoringPrepKey),
        matching: find.byKey(
          const ValueKey('surface_studio_create_atlas_work_catalog'),
        ),
      );
      expect(tester.widget<CupertinoButton>(create).onPressed, isNull);
      expect(out, isEmpty);
    });

    testWidgets('chargé depuis sélection: même id = doublon; nouvel id = ajout',
        (tester) async {
      final out = <ProjectSurfaceCatalog>[];
      var rm = _minimalRead();
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAtlasAuthoringPrep(
            readModel: rm,
            selection: SurfaceStudioSelection.atlas('water-atlas'),
            onSurfaceCatalogChanged: out.add,
          ),
        ),
      );
      await tester.tap(
        find.text('Charger la sélection dans le brouillon'),
      );
      await tester.pump();
      var create = find.descendant(
        of: find.byKey(kSurfaceStudioAtlasAuthoringPrepKey),
        matching: find.byKey(
          const ValueKey('surface_studio_create_atlas_work_catalog'),
        ),
      );
      expect(tester.widget<CupertinoButton>(create).onPressed, isNull);
      final idF = find.byKey(const ValueKey('atlas_draft_id'));
      await tester.enterText(idF, 'water-bis');
      await tester.pump();
      expect(tester.widget<CupertinoButton>(create).onPressed, isNotNull);
      final beforeAtlas = rm.catalog.atlases.single;
      await tester.tap(create);
      await tester.pump();
      expect(out, hasLength(1));
      expect(out.single.atlases, hasLength(2));
      expect(
        out.single.atlases.map((a) => a.id).toList(),
        ['water-atlas', 'water-bis'],
      );
      expect(
        out.single.atlases.first,
        beforeAtlas,
      );
    });

    testWidgets('interdits save projet (libellés)', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAtlasAuthoringPrep(
            readModel: _minimalRead(),
            selection: const SurfaceStudioSelection.none(),
            onSurfaceCatalogChanged: (_) {},
          ),
        ),
      );
      for (final s in <String>[
        'Sauvegarder le projet',
        'Enregistrer le projet',
        'Écrire sur disque',
        'Save project',
        'Write to disk',
      ]) {
        expect(find.text(s), findsNothing);
      }
    });
  });

  group('SurfaceStudioAtlasAuthoringPrep (Lot 67–68)', () {
    testWidgets('mode édition : libellé, id readOnly, pas Créer', (tester) async {
      final out = <ProjectSurfaceCatalog>[];
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAtlasAuthoringPrep(
            readModel: _minimalRead(),
            selection: SurfaceStudioSelection.atlas('water-atlas'),
            onSurfaceCatalogChanged: out.add,
          ),
        ),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_start_edit_atlas')),
      );
      await tester.pump();
      expect(
        find.byKey(const ValueKey('surface_studio_atlas_edit_mode_label')),
        findsOneWidget,
      );
      final idF = find.byKey(const ValueKey('atlas_draft_id'));
      expect((tester.widget(idF) as TextField).readOnly, isTrue);
      expect(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('surface_studio_apply_atlas_edit')),
        findsOneWidget,
      );
    });

    testWidgets('édition : renommer et appliquer, ordre et animations', (
        tester,
      ) async {
      final out = <ProjectSurfaceCatalog>[];
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAtlasAuthoringPrep(
            readModel: _minimalRead(),
            selection: SurfaceStudioSelection.atlas('water-atlas'),
            onSurfaceCatalogChanged: out.add,
          ),
        ),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_start_edit_atlas')),
      );
      await tester.pump();
      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
      await tester.enterText(nameF, 'Eau v2');
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_apply_atlas_edit')),
      );
      await tester.pump();
      expect(out, hasLength(1));
      expect(out.single.atlases.length, 1);
      expect(out.single.atlases.single.id, 'water-atlas');
      expect(out.single.atlases.single.name, 'Eau v2');
      expect(out.single.animations.length, 1);
      expect(out.single.presets.length, 1);
    });

    testWidgets('annuler l’édition : sortie mode édition', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAtlasAuthoringPrep(
            readModel: _minimalRead(),
            selection: SurfaceStudioSelection.atlas('water-atlas'),
            onSurfaceCatalogChanged: (_) {},
          ),
        ),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_start_edit_atlas')),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_cancel_atlas_edit')),
      );
      await tester.pump();
      expect(
        find.byKey(const ValueKey('surface_studio_atlas_edit_mode_label')),
        findsNothing,
      );
    });

    testWidgets('pas d’action Renommer id / Changer l’id', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAtlasAuthoringPrep(
            readModel: _minimalRead(),
            selection: SurfaceStudioSelection.atlas('water-atlas'),
            onSurfaceCatalogChanged: (_) {},
          ),
        ),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_start_edit_atlas')),
      );
      await tester.pump();
      expect(find.textContaining('Changer l’id'), findsNothing);
      expect(find.textContaining('Renommer l’atlas'), findsNothing);
    });
  });

  group('SurfaceStudioAtlasAuthoringPrep (Lot 70)', () {
    testWidgets(
      'section image source, pas d’ancien label tileset principal, fallback',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            SurfaceStudioAtlasAuthoringPrep(
              readModel: _emptyReadModel(),
              selection: const SurfaceStudioSelection.none(),
            ),
          ),
        );
        expect(
          find.byKey(const ValueKey('surface_studio_atlas_image_source_section')),
          findsOneWidget,
        );
        expect(find.text('Image source de l’atlas'), findsOneWidget);
        expect(find.text('ID du jeu d’images (tileset)'), findsNothing);
        expect(find.text('Options avancées'), findsOneWidget);
        expect(
          find.text('Identifiant technique du jeu d’images'),
          findsOneWidget,
        );
        expect(
          find.textContaining('Temporaire : ce champ sera remplacé'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'tilesets projet : menu déroulant, pas de champ avancé tileset',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            SurfaceStudioAtlasAuthoringPrep(
              readModel: _emptyReadModel(),
              selection: const SurfaceStudioSelection.none(),
              projectTilesets: const [
                ProjectTilesetEntry(
                  id: 'nature',
                  name: 'Nature',
                  relativePath: 'art/nature.png',
                  sortOrder: 0,
                ),
              ],
            ),
          ),
        );
        expect(
          find.byKey(const ValueKey('surface_studio_atlas_tileset_picker')),
          findsOneWidget,
        );
        expect(find.text('Choisir une image'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('atlas_draft_tileset_advanced')),
          findsNothing,
        );
      },
    );
  });

  group('SurfaceStudioAtlasAuthoringPrep (Lot 71)', () {
    testWidgets('section aperçu grille visible avec métriques', (tester) async {
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
      final tsF = find.byKey(const ValueKey('atlas_draft_tileset_advanced'));
      final cF = find.byKey(const ValueKey('atlas_draft_cols'));
      final rF = find.byKey(const ValueKey('atlas_draft_rows'));
      await tester.enterText(idF, 'a');
      await tester.enterText(nameF, 'Atlas');
      await tester.enterText(tsF, 'eau_atlas');
      await tester.enterText(cF, '4');
      await tester.enterText(rF, '8');
      await tester.pump();

      expect(
        find.byKey(kSurfaceStudioAtlasGridPreviewSectionKey),
        findsOneWidget,
      );
      expect(find.text('Aperçu de la grille atlas'), findsOneWidget);
      expect(find.text('Source : eau_atlas'), findsOneWidget);
      expect(find.text('Tile : 32×32 px'), findsOneWidget);
      expect(find.text('Grille : 4 colonnes × 8 lignes'), findsOneWidget);
      expect(find.text('Total : 32 cases'), findsOneWidget);
      expect(find.text('Disposition : Grille libre'), findsOneWidget);
    });

    testWidgets('aperçu état vide sans source', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAtlasAuthoringPrep(
            readModel: _emptyReadModel(),
            selection: const SurfaceStudioSelection.none(),
          ),
        ),
      );
      expect(
        find.text('Choisissez une image source pour prévisualiser la grille.'),
        findsOneWidget,
      );
    });

    testWidgets('aperçu état invalide dimensions', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAtlasAuthoringPrep(
            readModel: _emptyReadModel(),
            selection: const SurfaceStudioSelection.none(),
          ),
        ),
      );
      final tsF = find.byKey(const ValueKey('atlas_draft_tileset_advanced'));
      final wF = find.byKey(const ValueKey('atlas_draft_tile_w'));
      await tester.enterText(tsF, 'eau_atlas');
      await tester.enterText(wF, '0');
      await tester.pump();
      expect(
        find.text('Corrigez les dimensions de grille pour afficher la preview.'),
        findsOneWidget,
      );
    });

    testWidgets('aperçu mis à jour en mode édition', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAtlasAuthoringPrep(
            readModel: _minimalRead(),
            selection: SurfaceStudioSelection.atlas('water-atlas'),
            onSurfaceCatalogChanged: (_) {},
          ),
        ),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_start_edit_atlas')),
      );
      await tester.pump();
      expect(find.text('Source : nature-tileset'), findsOneWidget);
      final cF = find.byKey(const ValueKey('atlas_draft_cols'));
      await tester.enterText(cF, '20');
      await tester.pump();
      expect(find.text('Aperçu réduit'), findsOneWidget);
      expect(find.text('Total : 40 cases'), findsOneWidget);
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
