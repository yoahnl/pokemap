import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/path_studio/path_studio_panel.dart';

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
        find.widgetWithText(CupertinoButton, 'Enregistrer'),
      );

      expect(find.text('Nouveau preset'), findsNothing);
      expect(newPathButton.onPressed, isNotNull);
      expect(duplicateButton.onPressed, isNull);
      expect(saveButton.onPressed, isNull);
      expect(find.text('lot futur'), findsWidgets);

      await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau chemin'));
      await tester.pumpAndSettle();

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
      await tester.pumpAndSettle();

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
      await tester.pumpAndSettle();

      expect(find.text('Tileset'), findsWidgets);
      expect(find.text('À choisir'), findsWidgets);
      expect(find.text('Tileset à choisir'), findsWidgets);

      final popup = tester.widget<MacosPopupButton<String>>(
        find.byKey(const Key('path-studio-new-path-tileset-popup')),
      );
      popup.onChanged?.call('tileset-main');
      await tester.pumpAndSettle();

      expect(find.text('Chemins principaux (tileset-main)'), findsWidgets);
      expect(find.text('Tileset à choisir'), findsNothing);
      expect(find.text('Cellules à configurer'), findsWidgets);
      expect(find.text('À configurer'), findsWidgets);
      expect(find.text('Aucune tuile'), findsWidgets);
    });

    testWidgets('new path draft stays usable when the project has no tileset',
        (tester) async {
      await _pumpPathStudio(
        tester,
        manifest: _manifest(),
      );

      await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau chemin'));
      await tester.pumpAndSettle();

      expect(find.text('Brouillon nouveau chemin'), findsWidgets);
      expect(
          find.text('Aucun tileset disponible dans le projet'), findsWidgets);
      expect(find.text('Tileset à choisir'), findsWidgets);
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
      await tester.tap(
        find.byKey(const Key('path-studio-new-path-size-2x2')),
      );
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
        find.widgetWithText(CupertinoButton, 'Enregistrer'),
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
              return PathStudioPanel(manifest: manifest);
            },
          ),
        ],
      ),
    ),
  );
  await tester.pumpAndSettle();
}

ProjectManifest _manifest({
  List<ProjectPathPreset> pathPresets = const [],
  List<ProjectPathPatternPreset> pathPatternPresets = const [],
  List<ProjectTilesetEntry> tilesets = const [],
}) {
  return ProjectManifest(
    name: 'Project',
    maps: const [],
    tilesets: tilesets,
    pathPresets: pathPresets,
    pathPatternPresets: pathPatternPresets,
    surfaceCatalog: ProjectSurfaceCatalog(),
  );
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
}) {
  return ProjectPathPreset(
    id: id,
    name: name,
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
