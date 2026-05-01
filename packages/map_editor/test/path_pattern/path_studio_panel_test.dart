import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/path_studio/path_studio_panel.dart';
import 'package:map_editor/src/features/path_studio/path_studio_new_path_build_request.dart';
import 'package:map_editor/src/features/path_studio/path_studio_save_flow.dart';
import 'package:path/path.dart' as p;

void main() {
  group('PathStudioPanel', () {
    testWidgets('renders a dark empty state when no PathPattern preset exists',
        (tester) async {
      await _pumpPathStudio(
        tester,
        manifest: _manifest(),
      );

      expect(find.text('Path Studio'), findsOneWidget);
      expect(find.text('Créer des motifs de chemin'), findsOneWidget);
      expect(find.text('Aucun motif PathPattern'), findsWidgets);
      expect(find.text('Aucun preset sélectionné'), findsOneWidget);
      expect(find.text('Propriétés du preset'), findsOneWidget);
    });

    testWidgets('lists presets and updates summary and inspector selection',
        (tester) async {
      await _pumpPathStudio(
        tester,
        manifest: _manifest(
          pathPresets: [
            _legacyPathPreset(id: 'legacy-water', name: 'Base eau'),
          ],
          pathPatternPresets: [
            _pathPatternPreset(
              id: 'water-sea-2x2',
              name: 'Mer 2x2',
              pattern: _twoByTwoPattern(animatedTopLeft: true),
              transparentColor: TilesetTransparentColor.fromHexRgb('f05ba1'),
            ),
            _pathPatternPreset(
              id: 'sand-broken',
              name: 'Sable cassé',
              basePathPresetId: 'missing-base',
            ),
          ],
        ),
      );

      expect(find.text('Mer 2x2'), findsWidgets);
      expect(find.text('Sable cassé'), findsOneWidget);
      expect(find.text('Prêt'), findsWidgets);
      expect(find.text('2×2'), findsWidgets);
      expect(find.text('water-sea-2x2'), findsWidgets);
      expect(find.text('f05ba1'), findsWidgets);

      await tester.tap(find.text('Sable cassé'));
      await tester.pumpAndSettle();

      expect(find.text('missing-base'), findsWidgets);
      expect(find.text('Bloqué'), findsWidgets);
      expect(find.text('Preset de base introuvable'), findsWidgets);
    });

    testWidgets(
        'selected saved preset shows read-only center and inspector detail',
        (tester) async {
      await _pumpPathStudio(
        tester,
        manifest: _manifest(
          pathPresets: [
            _legacyPathPreset(
              id: 'legacy-water',
              name: 'Base eau',
              tilesetId: 'tileset-main',
            ),
          ],
          tilesets: [
            _tileset(id: 'tileset-main', name: 'Chemins principaux'),
          ],
          pathPatternPresets: [
            _pathPatternPreset(
              id: 'water-sea-2x2',
              name: 'Mer 2x2',
              pattern: _twoByTwoPattern(animatedTopLeft: true),
            ),
          ],
        ),
      );

      await tester.tap(find.byKey(const Key('path-studio-preset-card-0')));
      await tester.pumpAndSettle();

      expect(find.text('PathPattern sauvegardé'), findsOneWidget);
      expect(find.text('Present dans le projet'), findsWidgets);
      expect(find.text('Base path preset id'), findsWidgets);
      expect(find.text('legacy-water'), findsWidgets);
      expect(find.text('Base eau'), findsWidgets);
      expect(find.text('Tileset de base'), findsWidgets);
      expect(find.byKey(const Key('path-studio-saved-cell-thumbnail-A')),
          findsOneWidget);
      expect(find.text('Anime - 2 frames'), findsOneWidget);
    });

    testWidgets('saved preset uses image-backed thumbnail when tileset exists',
        (tester) async {
      final temp = (await tester.runAsync(
        () => Directory.systemTemp.createTemp('path_studio_saved_img_'),
      ))!;
      addTearDown(() => temp.delete(recursive: true));
      final imageFile = File(p.join(temp.path, 'tilesets/tileset-main.png'));
      await tester.runAsync(() async {
        await imageFile.parent.create(recursive: true);
        await imageFile.writeAsBytes(await _pngBytes(width: 64, height: 32));
      });

      await _pumpPathStudio(
        tester,
        projectRootPath: temp.path,
        manifest: _manifest(
          pathPresets: [
            _legacyPathPreset(
              id: 'legacy-water',
              name: 'Base eau',
              tilesetId: 'tileset-main',
            ),
          ],
          tilesets: [
            _tileset(id: 'tileset-main', name: 'Chemins principaux'),
          ],
          pathPatternPresets: [
            _pathPatternPreset(id: 'saved-water'),
          ],
        ),
      );

      await tester.tap(find.byKey(const Key('path-studio-preset-card-0')));
      await _pumpPathStudioAsync(tester);

      expect(find.byKey(const Key('path-studio-saved-cell-thumbnail-A')),
          findsOneWidget);
      expect(
        find.byKey(const Key('path-studio-saved-cell-thumbnail-image-A')),
        findsOneWidget,
      );
    });

    testWidgets(
        'saved preset missing image falls back to readable source label',
        (tester) async {
      final temp = (await tester.runAsync(
        () => Directory.systemTemp.createTemp('path_studio_saved_missing_'),
      ))!;
      addTearDown(() => temp.delete(recursive: true));

      await _pumpPathStudio(
        tester,
        projectRootPath: temp.path,
        manifest: _manifest(
          pathPresets: [
            _legacyPathPreset(
              id: 'legacy-water',
              name: 'Base eau',
              tilesetId: 'tileset-main',
            ),
          ],
          tilesets: [
            _tileset(id: 'tileset-main', name: 'Chemins principaux'),
          ],
          pathPatternPresets: [
            _pathPatternPreset(id: 'saved-water'),
          ],
        ),
      );

      await tester.tap(find.byKey(const Key('path-studio-preset-card-0')));
      await _pumpPathStudioAsync(tester);

      expect(find.byKey(const Key('path-studio-saved-cell-thumbnail-A')),
          findsOneWidget);
      expect(find.text('0,0'), findsWidgets);
    });

    testWidgets('saved preset with missing base path shows diagnostic',
        (tester) async {
      await _pumpPathStudio(
        tester,
        manifest: _manifest(
          pathPatternPresets: [
            _pathPatternPreset(
              id: 'missing-base',
              basePathPresetId: 'absent-base',
            ),
          ],
        ),
      );

      await tester.tap(find.byKey(const Key('path-studio-preset-card-0')));
      await tester.pumpAndSettle();

      expect(find.text('Preset de base introuvable'), findsWidgets);
      expect(find.text('Base path name'), findsWidgets);
      expect(find.text('Introuvable'), findsWidgets);
    });

    testWidgets(
        'saved preset exposes Modifier and disables it when base missing',
        (tester) async {
      await _pumpPathStudio(
        tester,
        manifest: _manifest(
          pathPatternPresets: [
            _pathPatternPreset(
              id: 'missing-base',
              basePathPresetId: 'absent-base',
            ),
          ],
        ),
      );

      await tester.tap(find.byKey(const Key('path-studio-preset-card-0')));
      await tester.pumpAndSettle();

      final editButton = tester.widget<CupertinoButton>(
        find.byKey(const Key('path-studio-saved-preset-edit-button')),
      );
      expect(editButton.onPressed, isNull);
      expect(
        find.byKey(const Key('path-studio-saved-preset-edit-disabled-reason')),
        findsOneWidget,
      );
      expect(find.text('Base path introuvable'), findsWidgets);
    });

    testWidgets(
        'Modifier ouvre un brouillon de modification avec frames existantes',
        (tester) async {
      await _pumpPathStudio(
        tester,
        manifest: _manifest(
          pathPresets: [
            _legacyPathPreset(
              id: 'legacy-water',
              name: 'Base eau',
              tilesetId: 'tileset-main',
            ),
          ],
          tilesets: [_tileset(id: 'tileset-main', name: 'Chemins principaux')],
          pathPatternPresets: [
            _pathPatternPreset(
              id: 'water-sea-2x2',
              name: 'Mer 2x2',
              pattern: _twoByTwoPattern(animatedTopLeft: true),
            ),
          ],
        ),
      );

      await tester.tap(find.byKey(const Key('path-studio-preset-card-0')));
      await tester.pumpAndSettle();
      await tester
          .tap(find.byKey(const Key('path-studio-saved-preset-edit-button')));
      await _pumpPathStudioAsync(tester);

      expect(find.text('Modification du chemin'), findsWidgets);
      expect(find.text('Propriétés de la modification'), findsOneWidget);
      expect(find.text('Animée — 2 frames'), findsWidgets);
      expect(find.text('Frame 1 / 2'), findsOneWidget);
      expect(find.text('ID path pattern'), findsWidgets);
      expect(find.text('water-sea-2x2'), findsWidgets);
    });

    testWidgets('filters presets locally and clears selection on no result',
        (tester) async {
      await _pumpPathStudio(
        tester,
        manifest: _manifest(
          pathPresets: [
            _legacyPathPreset(id: 'legacy-water'),
          ],
          pathPatternPresets: [
            _pathPatternPreset(id: 'water-sea', name: 'Mer profonde'),
            _pathPatternPreset(id: 'stone-road', name: 'Route pavée'),
          ],
        ),
      );

      await tester.enterText(
        find.byKey(const Key('path-studio-search-field')),
        'pavée',
      );
      await tester.pumpAndSettle();

      expect(find.text('Route pavée'), findsWidgets);
      expect(find.text('Mer profonde'), findsNothing);
      expect(find.text('stone-road'), findsWidgets);

      await tester.enterText(
        find.byKey(const Key('path-studio-search-field')),
        'zzz',
      );
      await tester.pumpAndSettle();

      expect(find.text('Aucun preset trouvé'), findsOneWidget);
      expect(find.text('Aucun preset sélectionné'), findsWidgets);
    });

    testWidgets('creates a new path draft without legacy base presets',
        (tester) async {
      await _pumpPathStudio(
        tester,
        manifest: _manifest(),
      );

      final newPathButton = tester.widget<CupertinoButton>(
        find.widgetWithText(CupertinoButton, 'Nouveau chemin'),
      );
      final duplicateButton = tester.widget<CupertinoButton>(
        find.widgetWithText(CupertinoButton, 'Dupliquer'),
      );
      final saveButton = tester.widget<CupertinoButton>(
        find.widgetWithText(CupertinoButton, 'Appliquer au projet'),
      );

      expect(find.text('Nouveau preset'), findsNothing);
      expect(newPathButton.onPressed, isNotNull);
      expect(duplicateButton.onPressed, isNull);
      expect(saveButton.onPressed, isNull);
      expect(find.widgetWithText(CupertinoButton, 'Enregistrer'), findsNothing);
      expect(find.text('lot futur'), findsWidgets);

      await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau chemin'));
      await _pumpPathStudioAsync(tester);

      expect(find.text('Brouillon nouveau chemin'), findsWidgets);
      expect(find.text('Brouillon non sauvegardé'), findsWidgets);
      expect(find.text('Propriétés du nouveau chemin'), findsOneWidget);
      expect(find.text('Nouveau chemin'), findsWidgets);
      expect(find.text('1×1'), findsWidgets);
      expect(find.text('Aucun preset Path de base disponible'), findsNothing);
      expect(find.text('Preset de base'), findsNothing);
      expect(find.text('Base path preset id'), findsNothing);
      expect(
        find.byKey(const Key('path-studio-new-path-cell-0-0')),
        findsOneWidget,
      );
    });

    testWidgets('new path draft does not force existing legacy path choices',
        (tester) async {
      await _pumpPathStudio(
        tester,
        manifest: _manifest(
          pathPresets: [
            _legacyPathPreset(id: 'mountain-rock', name: 'mountain rock'),
            _legacyPathPreset(id: 'tall_grass', name: 'tall_grass'),
          ],
        ),
      );

      await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau chemin'));
      await _pumpPathStudioAsync(tester);

      expect(find.text('Propriétés du nouveau chemin'), findsOneWidget);
      expect(find.text('mountain rock'), findsNothing);
      expect(find.text('tall_grass'), findsNothing);
      expect(
        find.byKey(const Key('path-studio-draft-base-popup')),
        findsNothing,
      );
    });

    testWidgets('new path draft can select a project tileset', (tester) async {
      await _pumpPathStudio(
        tester,
        manifest: _manifest(
          tilesets: [
            _tileset(id: 'tileset-main', name: 'Chemins principaux'),
            _tileset(id: 'tileset-extra', name: 'Décor extra'),
          ],
        ),
      );

      await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau chemin'));
      await _pumpPathStudioAsync(tester);

      expect(find.text('Tileset'), findsWidgets);
      expect(find.text('À choisir'), findsWidgets);
      expect(find.text('Tileset requis'), findsWidgets);

      final popup = tester.widget<MacosPopupButton<String>>(
        find.byKey(const Key('path-studio-new-path-tileset-popup')),
      );
      popup.onChanged?.call('tileset-main');
      await tester.pumpAndSettle();

      expect(find.text('Chemins principaux (tileset-main)'), findsWidgets);
      expect(find.text('Tileset requis'), findsNothing);
      expect(find.text('Centre incomplet'), findsWidgets);
      expect(find.text('À configurer'), findsWidgets);
      expect(find.text('Aucune tuile'), findsWidgets);
      expect(
          find.text('Sélectionnez une tuile pour la cellule A'), findsWidgets);
      expect(find.text('Bords, coins et jonctions'), findsWidgets);
      expect(find.byKey(const Key('path-studio-new-path-variant-progress')),
          findsOneWidget);
    });

    testWidgets('new path variant section can be collapsed and expanded',
        (tester) async {
      await _pumpPathStudio(
        tester,
        manifest: _manifest(
          tilesets: [_tileset(id: 'tileset-main', name: 'Chemins principaux')],
        ),
      );

      await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau chemin'));
      await _pumpPathStudioAsync(tester);
      tester
          .widget<MacosPopupButton<String>>(
            find.byKey(const Key('path-studio-new-path-tileset-popup')),
          )
          .onChanged
          ?.call('tileset-main');
      await _pumpPathStudioAsync(tester);

      expect(
        find.byKey(const Key('path-studio-new-path-variant-isolated')),
        findsOneWidget,
      );

      final accordionToggle = find.byKey(
        const Key('path-studio-new-path-variants-accordion-toggle'),
      );
      await tester.ensureVisible(accordionToggle);
      await tester.pumpAndSettle();
      await tester.tap(accordionToggle);
      await _pumpPathStudioAsync(tester);

      expect(
        find.byKey(const Key('path-studio-new-path-variant-isolated')),
        findsNothing,
      );
      expect(find.text('Déplier'), findsWidgets);

      await tester.ensureVisible(accordionToggle);
      await tester.pumpAndSettle();
      await tester.tap(accordionToggle);
      await _pumpPathStudioAsync(tester);

      expect(
        find.byKey(const Key('path-studio-new-path-variant-isolated')),
        findsOneWidget,
      );
      expect(find.text('Replier'), findsWidgets);
    });

    testWidgets('new path draft stays usable when the project has no tileset',
        (tester) async {
      await _pumpPathStudio(
        tester,
        manifest: _manifest(),
      );

      await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau chemin'));
      await _pumpPathStudioAsync(tester);

      expect(find.text('Brouillon nouveau chemin'), findsWidgets);
      expect(
          find.text('Aucun tileset disponible dans le projet'), findsWidgets);
      expect(find.text('Sélectionnez d’abord un tileset'), findsWidgets);
      expect(find.text('Tileset requis'), findsWidgets);
    });

    testWidgets('assigns a tileset tile to the 1x1 active cell',
        (tester) async {
      await _pumpPathStudio(
        tester,
        manifest: _manifest(
          tilesets: [_tileset(id: 'tileset-main', name: 'Chemins principaux')],
        ),
      );

      await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau chemin'));
      await _pumpPathStudioAsync(tester);
      tester
          .widget<MacosPopupButton<String>>(
            find.byKey(const Key('path-studio-new-path-tileset-popup')),
          )
          .onChanged
          ?.call('tileset-main');
      await _pumpPathStudioAsync(tester);

      final tile = find.byKey(const Key('path-studio-new-path-tile-2-1'));
      await tester.ensureVisible(tile);
      await tester.pumpAndSettle();
      await tester.tap(tile);
      await tester.pumpAndSettle();

      expect(find.text('Statique — 1 frame'), findsWidgets);
      expect(find.text('Centre incomplet'), findsNothing);
      expect(find.text('Aucun variant legacy configuré'), findsWidgets);
      expect(find.text('Tileset requis'), findsNothing);
    });

    testWidgets('new path center cell exposes animation frame controls',
        (tester) async {
      await _pumpPathStudio(
        tester,
        manifest: _manifest(
          tilesets: [_tileset(id: 'tileset-main', name: 'Chemins principaux')],
        ),
      );

      await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau chemin'));
      await _pumpPathStudioAsync(tester);
      tester
          .widget<MacosPopupButton<String>>(
            find.byKey(const Key('path-studio-new-path-tileset-popup')),
          )
          .onChanged
          ?.call('tileset-main');
      await _pumpPathStudioAsync(tester);
      await _tapNewPathTile(tester, tileX: 2, tileY: 1);

      expect(find.text('Animation du centre — Cellule A'), findsWidgets);
      expect(
        find.text(
          'Chaque frame correspond à une tuile du tileset.\nLe runtime joue les frames dans l’ordre avec la durée indiquée.\nAvec une seule frame, la cellule reste statique.',
        ),
        findsOneWidget,
      );
      expect(find.text('Statique — 1 frame'), findsWidgets);
      expect(
        find.byKey(const Key('path-studio-new-path-center-animation-summary')),
        findsOneWidget,
      );
      expect(find.textContaining('Centre : 1 cellules · 1 frames'),
          findsOneWidget);
      expect(
        find.byKey(const Key('path-studio-new-path-active-frame-title')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('path-studio-new-path-active-frame-index')),
        findsOneWidget,
      );
      expect(find.text('Frame 1 / 1'), findsOneWidget);
      expect(find.text('Durée de la frame (ms)'), findsOneWidget);

      final addFrame = find.byKey(const Key('path-studio-new-path-add-frame'));
      await tester.ensureVisible(addFrame);
      await tester.pumpAndSettle();
      await tester.tap(addFrame);
      await _pumpPathStudioAsync(tester);
      expect(find.text('Animée — 2 frames'), findsWidgets);
      expect(find.text('Ajouter une frame dupliquée'), findsWidgets);
      expect(find.text('Frame 2 / 2'), findsOneWidget);
      expect(find.textContaining('Centre : 1 cellules · 2 frames'),
          findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('path-studio-new-path-frame-duration-1')),
        '333',
      );
      await _pumpPathStudioAsync(tester);
      expect(find.text('Durée 333 ms'), findsOneWidget);

      final firstFrameChip =
          find.byKey(const Key('path-studio-new-path-frame-chip-0'));
      await tester.ensureVisible(firstFrameChip);
      await tester.pumpAndSettle();
      await tester.tap(firstFrameChip);
      await _pumpPathStudioAsync(tester);
      await _tapNewPathTile(tester, tileX: 5, tileY: 1);
      expect(find.textContaining('Tuile 5,1'), findsWidgets);
    });

    testWidgets('missing tileset image keeps the logical picker fallback',
        (tester) async {
      final temp = (await tester.runAsync(
        () => Directory.systemTemp.createTemp('path_studio_missing_'),
      ))!;
      addTearDown(() => temp.delete(recursive: true));
      await _pumpPathStudio(
        tester,
        manifest: _manifest(
          tilesets: [_tileset(id: 'tileset-main', name: 'Chemins principaux')],
        ),
        projectRootPath: temp.path,
      );

      await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau chemin'));
      await _pumpPathStudioAsync(tester);
      tester
          .widget<MacosPopupButton<String>>(
            find.byKey(const Key('path-studio-new-path-tileset-popup')),
          )
          .onChanged
          ?.call('tileset-main');
      await _pumpPathStudioAsync(tester);

      expect(find.text('Image du tileset introuvable'), findsWidgets);
      expect(find.byKey(const Key('path-studio-new-path-tile-2-1')),
          findsOneWidget);

      await _tapNewPathTile(tester, tileX: 2, tileY: 1);

      expect(find.text('Tuile 2,1'), findsWidgets);
      expect(find.text('Centre incomplet'), findsNothing);
      final fallbackThumbSize = tester.getSize(
        find.byKey(const Key('path-studio-cell-thumbnail-A')),
      );
      expect(fallbackThumbSize.width, 46);
      expect(fallbackThumbSize.height, 46);
      expect(
        find.byKey(const Key('path-studio-cell-thumbnail-label-A')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('path-studio-cell-thumbnail-A')),
          matching: find.text('2,1'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('image-backed tileset picker assigns the active cell',
        (tester) async {
      final temp = (await tester.runAsync(
        () => Directory.systemTemp.createTemp('path_studio_image_'),
      ))!;
      addTearDown(() => temp.delete(recursive: true));
      final imageFile = File(p.join(temp.path, 'tilesets/tileset-main.png'));
      await tester.runAsync(() async {
        await imageFile.parent.create(recursive: true);
        await imageFile.writeAsBytes(await _pngBytes(width: 64, height: 32));
      });

      await _pumpPathStudio(
        tester,
        manifest: _manifest(
          settings: const ProjectSettings(tileWidth: 16, tileHeight: 16),
          tilesets: [_tileset(id: 'tileset-main', name: 'Chemins principaux')],
        ),
        projectRootPath: temp.path,
      );

      await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau chemin'));
      await _pumpPathStudioAsync(tester);
      tester
          .widget<MacosPopupButton<String>>(
            find.byKey(const Key('path-studio-new-path-tileset-popup')),
          )
          .onChanged
          ?.call('tileset-main');
      await _pumpPathStudioAsync(tester);

      expect(find.byKey(const Key('path-studio-image-backed-tileset-picker')),
          findsOneWidget);
      expect(find.text('Image du tileset chargée'), findsWidgets);
      expect(find.text('Grille 4×2'), findsWidgets);
      expect(find.byKey(const Key('path-studio-tileset-zoom-out')),
          findsOneWidget);
      expect(
          find.byKey(const Key('path-studio-tileset-zoom-in')), findsOneWidget);
      expect(find.byKey(const Key('path-studio-tileset-zoom-reset')),
          findsOneWidget);
      expect(find.byKey(const Key('path-studio-tileset-zoom-fit')),
          findsOneWidget);

      final zoomIn = find.byKey(const Key('path-studio-tileset-zoom-in'));
      await tester.ensureVisible(zoomIn);
      await _pumpPathStudioAsync(tester);
      await tester.tap(zoomIn);
      await _pumpPathStudioAsync(tester);
      expect(find.text('125%'), findsOneWidget);
      await tester.tap(find.byKey(const Key('path-studio-tileset-zoom-out')));
      await _pumpPathStudioAsync(tester);
      _expectPathStudioZoomLabel(tester, '100%');
      await tester.tap(zoomIn);
      await _pumpPathStudioAsync(tester);
      await tester.tap(find.byKey(const Key('path-studio-tileset-zoom-reset')));
      await _pumpPathStudioAsync(tester);
      _expectPathStudioZoomLabel(tester, '100%');
      await tester.tap(zoomIn);
      await _pumpPathStudioAsync(tester);
      await tester.tap(find.byKey(const Key('path-studio-tileset-zoom-fit')));
      await _pumpPathStudioAsync(tester);
      _expectPathStudioZoomLabel(tester, '100%');
      await tester.tap(zoomIn);
      await _pumpPathStudioAsync(tester);

      await _tapImageBackedTile(tester,
          tileX: 2, tileY: 1, columns: 4, rows: 2);

      expect(find.text('Tuile 2,1'), findsWidgets);
      expect(find.text('Centre incomplet'), findsNothing);
      final imageThumbSize = tester.getSize(
        find.byKey(const Key('path-studio-cell-thumbnail-A')),
      );
      expect(imageThumbSize.width, 46);
      expect(imageThumbSize.height, 46);
      expect(
        find.descendant(
          of: find.byKey(const Key('path-studio-cell-thumbnail-A')),
          matching: find.byKey(const Key('path-studio-tile-preview-image')),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('path-studio-cell-thumbnail-A')),
          matching:
              find.byKey(const Key('path-studio-tile-preview-checkerboard')),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('path-studio-cell-thumbnail-label-A')),
        findsOneWidget,
      );
    });

    testWidgets('image-backed picker fills all 2x2 cells and supports clear',
        (tester) async {
      final temp = (await tester.runAsync(
        () => Directory.systemTemp.createTemp('path_studio_2x2_'),
      ))!;
      addTearDown(() => temp.delete(recursive: true));
      final imageFile = File(p.join(temp.path, 'tilesets/tileset-main.png'));
      await tester.runAsync(() async {
        await imageFile.parent.create(recursive: true);
        await imageFile.writeAsBytes(await _pngBytes(width: 64, height: 32));
      });

      await _pumpPathStudio(
        tester,
        manifest: _manifest(
          settings: const ProjectSettings(tileWidth: 16, tileHeight: 16),
          tilesets: [_tileset(id: 'tileset-main', name: 'Chemins principaux')],
        ),
        projectRootPath: temp.path,
      );

      await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau chemin'));
      await _pumpPathStudioAsync(tester);
      tester
          .widget<MacosPopupButton<String>>(
            find.byKey(const Key('path-studio-new-path-tileset-popup')),
          )
          .onChanged
          ?.call('tileset-main');
      await _pumpPathStudioAsync(tester);
      final size2x2 = find.byKey(const Key('path-studio-new-path-size-2x2'));
      await tester.ensureVisible(size2x2);
      await tester.pumpAndSettle();
      await tester.tap(size2x2);
      await tester.pumpAndSettle();

      await _assignImageBackedTile(
        tester,
        cellX: 0,
        cellY: 0,
        tileX: 0,
        tileY: 0,
        columns: 4,
        rows: 2,
      );
      await _assignImageBackedTile(
        tester,
        cellX: 1,
        cellY: 0,
        tileX: 1,
        tileY: 0,
        columns: 4,
        rows: 2,
      );
      await _assignImageBackedTile(
        tester,
        cellX: 0,
        cellY: 1,
        tileX: 2,
        tileY: 0,
        columns: 4,
        rows: 2,
      );

      expect(find.text('Centre incomplet'), findsWidgets);

      await _assignImageBackedTile(
        tester,
        cellX: 1,
        cellY: 1,
        tileX: 3,
        tileY: 0,
        columns: 4,
        rows: 2,
      );

      expect(find.text('Centre incomplet'), findsNothing);
      expect(find.text('Tuile 3,0'), findsWidgets);

      final clearButton =
          find.byKey(const Key('path-studio-new-path-clear-selected-cell'));
      await tester.ensureVisible(clearButton);
      await tester.pumpAndSettle();
      await tester.tap(clearButton);
      await tester.pumpAndSettle();

      expect(find.text('Centre incomplet'), findsWidgets);
      expect(find.text('Aucune tuile configurée pour cette cellule.'),
          findsWidgets);
    });

    testWidgets('assigns independent tiles to all 2x2 center cells',
        (tester) async {
      await _pumpPathStudio(
        tester,
        manifest: _manifest(
          tilesets: [_tileset(id: 'tileset-main', name: 'Chemins principaux')],
        ),
      );

      await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau chemin'));
      await tester.pumpAndSettle();
      tester
          .widget<MacosPopupButton<String>>(
            find.byKey(const Key('path-studio-new-path-tileset-popup')),
          )
          .onChanged
          ?.call('tileset-main');
      await tester.pumpAndSettle();
      final size2x2 = find.byKey(const Key('path-studio-new-path-size-2x2'));
      await tester.ensureVisible(size2x2);
      await tester.pumpAndSettle();
      await tester.tap(size2x2);
      await tester.pumpAndSettle();

      await _assignNewPathTile(tester, cellX: 0, cellY: 0, tileX: 0, tileY: 0);
      await _assignNewPathTile(tester, cellX: 1, cellY: 0, tileX: 1, tileY: 0);
      await _assignNewPathTile(tester, cellX: 0, cellY: 1, tileX: 0, tileY: 1);

      expect(find.text('Centre incomplet'), findsWidgets);

      await _assignNewPathTile(tester, cellX: 1, cellY: 1, tileX: 1, tileY: 1);

      expect(find.text('Statique — 1 frame'), findsWidgets);
      expect(find.text('Centre incomplet'), findsNothing);
    });

    testWidgets('replaces and clears the active cell tile', (tester) async {
      await _pumpPathStudio(
        tester,
        manifest: _manifest(
          tilesets: [_tileset(id: 'tileset-main', name: 'Chemins principaux')],
        ),
      );

      await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau chemin'));
      await tester.pumpAndSettle();
      tester
          .widget<MacosPopupButton<String>>(
            find.byKey(const Key('path-studio-new-path-tileset-popup')),
          )
          .onChanged
          ?.call('tileset-main');
      await tester.pumpAndSettle();

      await _tapNewPathTile(tester, tileX: 0, tileY: 0);
      await _tapNewPathTile(tester, tileX: 1, tileY: 0);

      expect(find.text('Tuile 1,0'), findsWidgets);
      expect(find.text('Tuile 0,0'), findsNothing);

      final clearButton =
          find.byKey(const Key('path-studio-new-path-clear-selected-cell'));
      await tester.ensureVisible(clearButton);
      await tester.pumpAndSettle();
      await tester.tap(clearButton);
      await tester.pumpAndSettle();

      expect(find.text('Tuile 1,0'), findsNothing);
      expect(find.text('Aucune tuile configurée pour cette cellule.'),
          findsWidgets);
      expect(find.text('Centre incomplet'), findsWidgets);
    });

    testWidgets('changing tileset clears configured center cells',
        (tester) async {
      await _pumpPathStudio(
        tester,
        manifest: _manifest(
          tilesets: [
            _tileset(id: 'tileset-main', name: 'Chemins principaux'),
            _tileset(id: 'tileset-extra', name: 'Décor extra'),
          ],
        ),
      );

      await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau chemin'));
      await tester.pumpAndSettle();
      final popupFinder =
          find.byKey(const Key('path-studio-new-path-tileset-popup'));
      tester.widget<MacosPopupButton<String>>(popupFinder).onChanged?.call(
            'tileset-main',
          );
      await tester.pumpAndSettle();
      await _tapNewPathTile(tester, tileX: 2, tileY: 1);

      expect(find.text('Tuile 2,1'), findsWidgets);
      expect(find.text('Centre incomplet'), findsNothing);

      tester.widget<MacosPopupButton<String>>(popupFinder).onChanged?.call(
            'tileset-extra',
          );
      await tester.pumpAndSettle();

      expect(find.text('Décor extra (tileset-extra)'), findsWidgets);
      expect(find.text('Tuile 2,1'), findsNothing);
      expect(find.text('Centre incomplet'), findsWidgets);
    });

    testWidgets('resizes the new path draft to 2x2 and selects a cell',
        (tester) async {
      await _pumpPathStudio(
        tester,
        manifest: _manifest(
          pathPresets: [_legacyPathPreset(id: 'legacy-water')],
          tilesets: [_tileset(id: 'tileset-main', name: 'Chemins principaux')],
        ),
      );

      await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau chemin'));
      await tester.pumpAndSettle();
      tester
          .widget<MacosPopupButton<String>>(
            find.byKey(const Key('path-studio-new-path-tileset-popup')),
          )
          .onChanged
          ?.call('tileset-main');
      await tester.pumpAndSettle();
      final size2x2 = find.byKey(const Key('path-studio-new-path-size-2x2'));
      await tester.ensureVisible(size2x2);
      await tester.pumpAndSettle();
      await tester.tap(size2x2);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('path-studio-new-path-cell-0-0')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('path-studio-new-path-cell-1-0')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('path-studio-new-path-cell-0-1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('path-studio-new-path-cell-1-1')),
        findsOneWidget,
      );
      expect(find.text('A'), findsWidgets);
      expect(find.text('B'), findsWidgets);
      expect(find.text('C'), findsWidgets);
      expect(find.text('D'), findsWidgets);
      expect(find.text('À configurer'), findsWidgets);
      expect(find.text('Aucune tuile'), findsWidgets);
      expect(find.text('Chemins principaux (tileset-main)'), findsWidgets);
      expect(find.textContaining('source '), findsNothing);

      final bottomRightCell =
          find.byKey(const Key('path-studio-new-path-cell-1-1'));
      await tester.ensureVisible(bottomRightCell);
      await tester.pumpAndSettle();
      await tester.tap(bottomRightCell);
      await tester.pumpAndSettle();

      expect(find.text('Cellule sélectionnée'), findsWidgets);
      expect(find.text('Position 1,1'), findsWidgets);
      expect(find.text('Cellule D'), findsWidgets);
    });

    testWidgets('edits new path draft name and keeps save disabled',
        (tester) async {
      await _pumpPathStudio(
        tester,
        manifest: _manifest(
          pathPresets: [_legacyPathPreset(id: 'legacy-water')],
        ),
      );

      await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau chemin'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('path-studio-new-path-name-field')),
        'Route brouillon',
      );
      await tester.pumpAndSettle();

      expect(find.text('Route brouillon'), findsWidgets);
      final saveButton = tester.widget<CupertinoButton>(
        find.widgetWithText(CupertinoButton, 'Appliquer au projet'),
      );
      expect(saveButton.onPressed, isNull);
    });

    testWidgets('new path save status explains missing path variant mapping',
        (tester) async {
      await _pumpPathStudio(
        tester,
        manifest: _manifest(),
      );

      await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau chemin'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('path-studio-save-status-card')),
          findsOneWidget);
      expect(find.text('Plan de création local'), findsWidgets);
      expect(find.text('Brouillon de nouveau chemin'), findsWidgets);
      expect(find.text('Création en mémoire'), findsWidgets);
      expect(find.text('Requête locale bloquée'), findsWidgets);
      expect(find.text('Couverture partielle des variants'), findsNothing);
      expect(
        find.text(
          'Corrigez les erreurs bloquantes pour préparer la sauvegarde en mémoire.',
        ),
        findsWidgets,
      );
      expect(find.text('Aucun variant legacy configuré'), findsWidgets);

      final saveButton = tester.widget<CupertinoButton>(
        find.byKey(const Key('path-studio-save-button')),
      );
      expect(saveButton.onPressed, isNull);
    });

    testWidgets('new path with complete center stays disabled without callback',
        (tester) async {
      await _pumpPathStudio(
        tester,
        manifest: _manifest(
          tilesets: [_tileset(id: 'tileset-main', name: 'Chemins principaux')],
        ),
      );

      await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau chemin'));
      await tester.pumpAndSettle();
      tester
          .widget<MacosPopupButton<String>>(
            find.byKey(const Key('path-studio-new-path-tileset-popup')),
          )
          .onChanged
          ?.call('tileset-main');
      await tester.pumpAndSettle();
      await _tapNewPathTile(tester, tileX: 2, tileY: 1);

      expect(find.text('prêt'), findsWidgets);
      expect(find.text('Cellules du centre à configurer'), findsNothing);
      expect(find.text('Callback de sauvegarde absent'), findsWidgets);
      expect(find.text('Aucun variant legacy configuré'), findsWidgets);

      final saveButton = tester.widget<CupertinoButton>(
        find.byKey(const Key('path-studio-save-button')),
      );
      expect(saveButton.onPressed, isNull);
    });

    testWidgets(
        'new path with variants partiels enables save when callback exists',
        (tester) async {
      await _pumpPathStudio(
        tester,
        manifest: _manifest(
          tilesets: [_tileset(id: 'tileset-main', name: 'Chemins principaux')],
        ),
        onNewPathSaveRequested: (_) {},
      );

      await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau chemin'));
      await tester.pumpAndSettle();
      tester
          .widget<MacosPopupButton<String>>(
            find.byKey(const Key('path-studio-new-path-tileset-popup')),
          )
          .onChanged
          ?.call('tileset-main');
      await tester.pumpAndSettle();
      await _tapNewPathTile(tester, tileX: 2, tileY: 1);

      expect(find.text('application en mémoire prête'), findsWidgets);
      expect(
        find.text('Warnings présents, mais sauvegarde en mémoire possible.'),
        findsWidgets,
      );
      expect(find.text('Aucun variant legacy configuré'), findsWidgets);

      final saveButton = tester.widget<CupertinoButton>(
        find.byKey(const Key('path-studio-save-button')),
      );
      expect(saveButton.onPressed, isNotNull);
    });

    testWidgets(
        'new path save updates parent manifest and selects saved preset',
        (tester) async {
      var parentManifest = _manifest(
        tilesets: [_tileset(id: 'tileset-main', name: 'Chemins principaux')],
      );
      var callbackCount = 0;

      await tester.binding.setSurfaceSize(const Size(1440, 920));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MacosApp(
          theme: MacosThemeData.dark(),
          home: MacosScaffold(
            children: [
              ContentArea(
                builder: (context, scrollController) {
                  return StatefulBuilder(
                    builder: (context, setParentState) {
                      return PathStudioPanel(
                        manifest: parentManifest,
                        onNewPathSaveRequested: (request) {
                          callbackCount += 1;
                          setParentState(() {
                            parentManifest = applyNewPathBuildRequestToManifest(
                              manifest: parentManifest,
                              request: request,
                            );
                          });
                        },
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      );
      await _pumpPathStudioAsync(tester);

      await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau chemin'));
      await _pumpPathStudioAsync(tester);
      tester
          .widget<MacosPopupButton<String>>(
            find.byKey(const Key('path-studio-new-path-tileset-popup')),
          )
          .onChanged
          ?.call('tileset-main');
      await _pumpPathStudioAsync(tester);
      await _tapNewPathTile(tester, tileX: 2, tileY: 1);
      final isolatedVariant =
          find.byKey(const Key('path-studio-new-path-variant-isolated'));
      await tester.ensureVisible(isolatedVariant);
      await tester.pumpAndSettle();
      await tester.tap(isolatedVariant);
      await _pumpPathStudioAsync(tester);
      await _tapNewPathTile(tester, tileX: 4, tileY: 1);

      await tester.tap(find.byKey(const Key('path-studio-save-button')));
      await tester.pumpAndSettle();

      expect(callbackCount, 1);
      expect(
        parentManifest.pathPresets
            .any((preset) => preset.id == 'nouveau-chemin'),
        isTrue,
      );
      expect(
        parentManifest.pathPatternPresets
            .any((preset) => preset.id == 'nouveau-chemin-pattern'),
        isTrue,
      );
      expect(find.byKey(const Key('path-studio-new-path-draft-card')),
          findsNothing);
      expect(
        find.byKey(const Key('path-studio-save-success-message')),
        findsOneWidget,
      );
      expect(find.textContaining('en mémoire'), findsWidgets);
      expect(find.textContaining('disquette'), findsWidgets);
      expect(find.text('PathPattern sauvegardé'), findsOneWidget);
      expect(find.text('nouveau-chemin-pattern'), findsWidgets);
    });

    testWidgets('edit save remplace en mémoire et nettoie le brouillon',
        (tester) async {
      var parentManifest = _manifest(
        pathPresets: [
          _legacyPathPreset(
            id: 'legacy-water',
            name: 'Base eau',
            tilesetId: 'tileset-main',
          ),
        ],
        tilesets: [_tileset(id: 'tileset-main', name: 'Chemins principaux')],
        pathPatternPresets: [
          _pathPatternPreset(
            id: 'water-sea-2x2',
            name: 'Mer 2x2',
            pattern: _twoByTwoPattern(animatedTopLeft: true),
          ),
        ],
      );

      await tester.binding.setSurfaceSize(const Size(1440, 920));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MacosApp(
          theme: MacosThemeData.dark(),
          home: MacosScaffold(
            children: [
              ContentArea(
                builder: (context, scrollController) {
                  return StatefulBuilder(
                    builder: (context, setParentState) {
                      return PathStudioPanel(
                        manifest: parentManifest,
                        onEditPathSaveRequested: (request) {
                          setParentState(() {
                            parentManifest =
                                applyPathPatternEditRequestToManifest(
                              manifest: parentManifest,
                              request: request,
                            );
                          });
                        },
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      );
      await _pumpPathStudioAsync(tester);

      await tester.tap(find.byKey(const Key('path-studio-preset-card-0')));
      await _pumpPathStudioAsync(tester);
      await tester
          .tap(find.byKey(const Key('path-studio-saved-preset-edit-button')));
      await _pumpPathStudioAsync(tester);

      await tester.enterText(
        find.byKey(const Key('path-studio-new-path-name-field')),
        'Mer éditée',
      );
      await _pumpPathStudioAsync(tester);

      final addFrame = find.byKey(const Key('path-studio-new-path-add-frame'));
      await tester.ensureVisible(addFrame);
      await tester.pumpAndSettle();
      await tester.tap(addFrame);
      await _pumpPathStudioAsync(tester);
      await tester.enterText(
        find.byKey(const Key('path-studio-new-path-frame-duration-2')),
        '444',
      );
      await _pumpPathStudioAsync(tester);

      expect(
        find.widgetWithText(CupertinoButton, 'Appliquer les modifications'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('path-studio-save-button')));
      await _pumpPathStudioAsync(tester);

      final updatedPattern = parentManifest.pathPatternPresets.single;
      final updatedBase = parentManifest.pathPresets.single;
      expect(updatedPattern.id, 'water-sea-2x2');
      expect(updatedBase.id, 'legacy-water');
      expect(updatedPattern.name, 'Mer éditée');
      expect(updatedBase.name, 'Mer éditée');
      expect(updatedPattern.centerPattern.cells.first.frames.length, 3);
      expect(
          updatedPattern.centerPattern.cells.first.frames[2].durationMs, 444);
      expect(find.byKey(const Key('path-studio-new-path-draft-card')),
          findsNothing);
      expect(find.textContaining('en mémoire'), findsWidgets);
      expect(find.textContaining('disquette'), findsWidgets);
      expect(find.text('PathPattern sauvegardé'), findsOneWidget);
      expect(find.text('Mer éditée'), findsWidgets);
    });

    testWidgets('legacy save request is prepared but disabled without callback',
        (tester) async {
      await _pumpPathStudio(
        tester,
        manifest: _manifest(
          pathPresets: [_legacyPathPreset(id: 'legacy-water')],
        ),
      );

      await tester.tap(
        find.widgetWithText(CupertinoButton, 'Depuis un path existant'),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('path-studio-draft-name-field')),
        'Motif eau',
      );
      await tester.pumpAndSettle();

      expect(find.text('Motif PathPattern depuis path existant'), findsWidgets);
      expect(find.text('Requête prête'), findsWidgets);
      expect(find.text('Callback de sauvegarde absent'), findsWidgets);

      final saveButton = tester.widget<CupertinoButton>(
        find.byKey(const Key('path-studio-save-button')),
      );
      expect(saveButton.onPressed, isNull);
    });

    testWidgets(
        'legacy save updates parent manifest and panel exits draft state',
        (tester) async {
      var parentManifest = _manifest(
        pathPresets: [_legacyPathPreset(id: 'legacy-water')],
      );
      var callbackCount = 0;

      await tester.binding.setSurfaceSize(const Size(1440, 920));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MacosApp(
          theme: MacosThemeData.dark(),
          home: MacosScaffold(
            children: [
              ContentArea(
                builder: (context, scrollController) {
                  return StatefulBuilder(
                    builder: (context, setParentState) {
                      return PathStudioPanel(
                        manifest: parentManifest,
                        onPathPatternPresetSaveRequested: (preset) {
                          callbackCount += 1;
                          setParentState(() {
                            parentManifest =
                                applyLegacyPathPatternSaveToManifest(
                              manifest: parentManifest,
                              preset: preset,
                            );
                          });
                        },
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      );
      await _pumpPathStudioAsync(tester);

      await tester.tap(
        find.widgetWithText(CupertinoButton, 'Depuis un path existant'),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('path-studio-draft-name-field')),
        'Motif eau',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('path-studio-save-button')));
      await tester.pumpAndSettle();

      expect(callbackCount, 1);
      expect(
        parentManifest.pathPatternPresets
            .any((preset) => preset.id == 'motif-eau'),
        isTrue,
      );
      expect(find.byKey(const Key('path-studio-draft-card')), findsNothing);
      expect(
        find.byKey(const Key('path-studio-save-success-message')),
        findsOneWidget,
      );
      expect(find.textContaining('en mémoire'), findsWidgets);
      expect(find.textContaining('disquette'), findsWidgets);
      expect(find.text('Propriétés du preset'), findsOneWidget);
      expect(find.text('motif-eau'), findsWidgets);
      expect(find.text('Motif PathPattern depuis path existant'), findsNothing);
    });

    testWidgets('legacy duplicate proposed id blocks save', (tester) async {
      await _pumpPathStudio(
        tester,
        manifest: _manifest(
          pathPresets: [_legacyPathPreset(id: 'legacy-water')],
          pathPatternPresets: [
            _pathPatternPreset(
                id: 'motif-eau', basePathPresetId: 'legacy-water')
          ],
        ),
      );

      await tester.tap(
        find.widgetWithText(CupertinoButton, 'Depuis un path existant'),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('path-studio-draft-name-field')),
        'Motif eau',
      );
      await tester.pumpAndSettle();

      expect(find.text('ID PathPattern déjà utilisé'), findsWidgets);
      final saveButton = tester.widget<CupertinoButton>(
        find.byKey(const Key('path-studio-save-button')),
      );
      expect(saveButton.onPressed, isNull);
    });

    testWidgets('secondary legacy flow changes inherited structure locally',
        (tester) async {
      await _pumpPathStudio(
        tester,
        manifest: _manifest(
          pathPresets: [
            _legacyPathPreset(id: 'legacy-water', name: 'Base eau'),
            _legacyPathPreset(
              id: 'legacy-sand',
              name: 'Base sable',
              crossSourceX: 5,
            ),
          ],
        ),
      );

      await tester.tap(
        find.widgetWithText(CupertinoButton, 'Depuis un path existant'),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('path-studio-draft-name-field')),
        'Mer brouillon',
      );
      await tester.pumpAndSettle();

      final popup = tester.widget<MacosPopupButton<String>>(
        find.byKey(const Key('path-studio-draft-base-popup')),
      );
      popup.onChanged?.call('legacy-sand');
      await tester.pumpAndSettle();

      expect(find.text('Propriétés du motif depuis path existant'),
          findsOneWidget);
      expect(find.text('Structure héritée'), findsWidgets);
      expect(find.text('Mer brouillon'), findsWidgets);
      expect(find.text('legacy-sand'), findsWidgets);
      expect(find.text('source 5,0'), findsWidgets);
      expect(find.text('Brouillon non sauvegardé'), findsWidgets);
    });

    testWidgets('empty new path name shows a local diagnostic', (tester) async {
      await _pumpPathStudio(
        tester,
        manifest: _manifest(
          pathPresets: [_legacyPathPreset(id: 'legacy-water')],
        ),
      );

      await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau chemin'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('path-studio-new-path-name-field')),
        '   ',
      );
      await tester.pumpAndSettle();

      expect(find.text('Nom requis'), findsWidgets);
    });

    testWidgets(
        'new path variants can be selected assigned and cleared with picker',
        (tester) async {
      await _pumpPathStudio(
        tester,
        manifest: _manifest(
          tilesets: [_tileset(id: 'tileset-main', name: 'Chemins principaux')],
        ),
      );

      await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau chemin'));
      await _pumpPathStudioAsync(tester);
      tester
          .widget<MacosPopupButton<String>>(
            find.byKey(const Key('path-studio-new-path-tileset-popup')),
          )
          .onChanged
          ?.call('tileset-main');
      await _pumpPathStudioAsync(tester);

      final variantCard =
          find.byKey(const Key('path-studio-new-path-variant-isolated'));
      await tester.ensureVisible(variantCard);
      await tester.pumpAndSettle();
      await tester.tap(variantCard);
      await _pumpPathStudioAsync(tester);

      expect(
        find.text('Sélectionnez une tuile pour le variant isolated'),
        findsWidgets,
      );

      await _tapNewPathTile(tester, tileX: 4, tileY: 1);

      expect(find.text('Tuile 4,1'), findsWidgets);
      expect(
        find.byKey(const Key('path-studio-cell-thumbnail-isolated')),
        findsOneWidget,
      );

      final clearVariant = find.byKey(
        const Key('path-studio-new-path-clear-variant-isolated'),
      );
      await tester.ensureVisible(clearVariant);
      await tester.pumpAndSettle();
      await tester.tap(clearVariant);
      await _pumpPathStudioAsync(tester);

      expect(find.text('Aucun variant legacy configuré'), findsWidgets);
    });

    testWidgets(
        'all variants configured clears variant diagnostic but save stays disabled',
        (tester) async {
      await _pumpPathStudio(
        tester,
        manifest: _manifest(
          tilesets: [_tileset(id: 'tileset-main', name: 'Chemins principaux')],
        ),
      );

      await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau chemin'));
      await _pumpPathStudioAsync(tester);
      tester
          .widget<MacosPopupButton<String>>(
            find.byKey(const Key('path-studio-new-path-tileset-popup')),
          )
          .onChanged
          ?.call('tileset-main');
      await _pumpPathStudioAsync(tester);
      await _tapNewPathTile(tester, tileX: 0, tileY: 0);

      final variants = TerrainPathVariant.values
          .where((variant) => variant != TerrainPathVariant.cross)
          .toList();
      for (var i = 0; i < variants.length; i += 1) {
        final name = variants[i].name;
        final cardKey = Key('path-studio-new-path-variant-$name');
        final card = find.byKey(cardKey);
        await tester.ensureVisible(card);
        await tester.pumpAndSettle();
        await tester.tap(card);
        await _pumpPathStudioAsync(tester);
        await _tapNewPathTile(tester, tileX: i % 8, tileY: i ~/ 8);
      }

      expect(find.text('Couverture partielle des variants'), findsNothing);
      expect(find.text('Aucun variant legacy configuré'), findsNothing);
      expect(find.text('Callback de sauvegarde absent'), findsWidgets);

      final saveButton = tester.widget<CupertinoButton>(
        find.byKey(const Key('path-studio-save-button')),
      );
      expect(saveButton.onPressed, isNull);
    });

    testWidgets('secondary legacy flow reports missing existing paths',
        (tester) async {
      await _pumpPathStudio(
        tester,
        manifest: _manifest(),
      );

      await tester.tap(
        find.widgetWithText(CupertinoButton, 'Depuis un path existant'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Aucun path existant disponible'), findsWidgets);

      await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau chemin'));
      await tester.pumpAndSettle();

      expect(find.text('Brouillon nouveau chemin'), findsWidgets);
      expect(find.text('Aucun path existant disponible'), findsNothing);
    });
  });
}

Future<void> _pumpPathStudio(
  WidgetTester tester, {
  required ProjectManifest manifest,
  String? projectRootPath,
  ValueChanged<ProjectPathPatternPreset>? onPathPatternPresetSaveRequested,
  ValueChanged<PathStudioNewPathBuildRequest>? onNewPathSaveRequested,
}) async {
  await tester.binding.setSurfaceSize(const Size(1440, 920));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    MacosApp(
      theme: MacosThemeData.dark(),
      home: MacosScaffold(
        children: [
          ContentArea(
            builder: (context, scrollController) {
              return PathStudioPanel(
                manifest: manifest,
                projectRootPath: projectRootPath,
                onPathPatternPresetSaveRequested:
                    onPathPatternPresetSaveRequested,
                onNewPathSaveRequested: onNewPathSaveRequested,
              );
            },
          ),
        ],
      ),
    ),
  );
  await _pumpPathStudioAsync(tester);
}

Future<void> _pumpPathStudioAsync(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 250));
  await tester.pump(const Duration(milliseconds: 250));
}

void _expectPathStudioZoomLabel(WidgetTester tester, String value) {
  final label = tester.widget<Text>(
    find.byKey(const Key('path-studio-tileset-zoom-label')),
  );
  expect(label.data, value);
}

Future<void> _assignImageBackedTile(
  WidgetTester tester, {
  required int cellX,
  required int cellY,
  required int tileX,
  required int tileY,
  required int columns,
  required int rows,
}) async {
  final cell = find.byKey(Key('path-studio-new-path-cell-$cellX-$cellY'));
  await tester.ensureVisible(cell);
  await _pumpPathStudioAsync(tester);
  await tester.tap(cell);
  await _pumpPathStudioAsync(tester);
  await _tapImageBackedTile(
    tester,
    tileX: tileX,
    tileY: tileY,
    columns: columns,
    rows: rows,
  );
}

Future<void> _tapImageBackedTile(
  WidgetTester tester, {
  required int tileX,
  required int tileY,
  required int columns,
  required int rows,
}) async {
  final picker =
      find.byKey(const Key('path-studio-image-backed-tileset-canvas'));
  await tester.ensureVisible(picker);
  await _pumpPathStudioAsync(tester);
  final topLeft = tester.getTopLeft(picker);
  final size = tester.getSize(picker);
  await tester.tapAt(
    topLeft +
        Offset(
          (tileX + 0.5) * size.width / columns,
          (tileY + 0.5) * size.height / rows,
        ),
  );
  await _pumpPathStudioAsync(tester);
}

Future<void> _assignNewPathTile(
  WidgetTester tester, {
  required int cellX,
  required int cellY,
  required int tileX,
  required int tileY,
}) async {
  final cell = find.byKey(Key('path-studio-new-path-cell-$cellX-$cellY'));
  await tester.ensureVisible(cell);
  await _pumpPathStudioAsync(tester);
  await tester.tap(cell);
  await _pumpPathStudioAsync(tester);
  await _tapNewPathTile(tester, tileX: tileX, tileY: tileY);
}

Future<void> _tapNewPathTile(
  WidgetTester tester, {
  required int tileX,
  required int tileY,
}) async {
  final tile = find.byKey(Key('path-studio-new-path-tile-$tileX-$tileY'));
  await tester.ensureVisible(tile);
  await _pumpPathStudioAsync(tester);
  await tester.tap(tile);
  await _pumpPathStudioAsync(tester);
}

ProjectManifest _manifest({
  List<ProjectPathPreset> pathPresets = const [],
  List<ProjectPathPatternPreset> pathPatternPresets = const [],
  List<ProjectTilesetEntry> tilesets = const [],
  ProjectSettings settings = const ProjectSettings(),
}) {
  return ProjectManifest(
    name: 'Project',
    settings: settings,
    maps: const [],
    tilesets: tilesets,
    pathPresets: pathPresets,
    pathPatternPresets: pathPatternPresets,
    surfaceCatalog: ProjectSurfaceCatalog(),
  );
}

Future<Uint8List> _pngBytes({
  required int width,
  required int height,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  final colors = [
    const ui.Color(0xFFEBCB8B),
    const ui.Color(0xFFA3BE8C),
    const ui.Color(0xFF88C0D0),
    const ui.Color(0xFFB48EAD),
  ];
  var colorIndex = 0;
  for (var y = 0; y < height; y += 16) {
    for (var x = 0; x < width; x += 16) {
      final paint = ui.Paint()..color = colors[colorIndex % colors.length];
      canvas.drawRect(
        ui.Rect.fromLTWH(x.toDouble(), y.toDouble(), 16, 16),
        paint,
      );
      colorIndex += 1;
    }
  }
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}

ProjectTilesetEntry _tileset({
  required String id,
  required String name,
}) {
  return ProjectTilesetEntry(
    id: id,
    name: name,
    relativePath: 'tilesets/$id.png',
  );
}

ProjectPathPreset _legacyPathPreset({
  required String id,
  String name = 'Legacy Water',
  int crossSourceX = 0,
  String tilesetId = '',
}) {
  return ProjectPathPreset(
    id: id,
    name: name,
    tilesetId: tilesetId,
    surfaceKind: PathSurfaceKind.water,
    variants: [
      PathPresetVariantMapping(
        variant: TerrainPathVariant.cross,
        frames: [_frame(crossSourceX)],
      ),
    ],
  );
}

ProjectPathPatternPreset _pathPatternPreset({
  required String id,
  String? name,
  String basePathPresetId = 'legacy-water',
  PathCenterPattern? pattern,
  TilesetTransparentColor? transparentColor,
}) {
  return ProjectPathPatternPreset(
    id: id,
    name: name ?? id,
    basePathPresetId: basePathPresetId,
    centerPattern: pattern ?? _singleCellPattern(),
    transparentColor: transparentColor,
  );
}

PathCenterPattern _singleCellPattern() {
  return PathCenterPattern(
    size: PathCenterPatternSize(width: 1, height: 1),
    cells: [
      PathCenterPatternCell(
        localX: 0,
        localY: 0,
        frames: [_frame(0)],
      ),
    ],
  );
}

PathCenterPattern _twoByTwoPattern({bool animatedTopLeft = false}) {
  return PathCenterPattern(
    size: PathCenterPatternSize(width: 2, height: 2),
    cells: [
      PathCenterPatternCell(
        localX: 0,
        localY: 0,
        frames: animatedTopLeft ? [_frame(0), _frame(1)] : [_frame(0)],
      ),
      PathCenterPatternCell(localX: 1, localY: 0, frames: [_frame(2)]),
      PathCenterPatternCell(localX: 0, localY: 1, frames: [_frame(3)]),
      PathCenterPatternCell(localX: 1, localY: 1, frames: [_frame(4)]),
    ],
  );
}

TilesetVisualFrame _frame(int sourceX) {
  return TilesetVisualFrame(
    source: TilesetSourceRect(x: sourceX, y: 0),
  );
}
