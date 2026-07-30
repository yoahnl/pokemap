import 'dart:io';
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/app/providers/editor/editor_asset_cache_providers.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor/tools/editor_tool.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/assets/editor_image_cache.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';
import 'package:map_editor/src/ui/panels/tileset_palette_panel.dart';
import 'package:map_editor/src/ui/panels/tileset_palette/widgets/browser/map_palette_asset_browser.dart';
import 'package:path/path.dart' as p;

void main() {
  testWidgets(
    'public side-sheet and inspector presentations share browser state',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final inspectorSearchFocusNode = FocusNode(
        debugLabel: 'inspector asset browser search',
      );
      addTearDown(inspectorSearchFocusNode.dispose);
      final notifier = container.read(editorNotifierProvider.notifier)
        ..state = const EditorState(
          project: project,
          workspaceMode: EditorWorkspaceMode.map,
          activeMap: map,
          activeLayerId: 'ground',
        );

      await tester.binding.setSurfaceSize(const Size(1100, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: PokeMapTheme.light(),
            home: Scaffold(
              body: Row(
                children: [
                  const Expanded(
                    child: MapPaletteAssetBrowser(
                      presentation:
                          MapPaletteAssetBrowserPresentation.sideSheet,
                    ),
                  ),
                  Expanded(
                    child: MapPaletteAssetBrowser(
                      presentation:
                          MapPaletteAssetBrowserPresentation.inspector,
                      searchFocusNode: inspectorSearchFocusNode,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(MapPaletteAssetBrowser), findsNWidgets(2));
      expect(find.byType(TextField), findsNWidgets(2));

      await tester.enterText(find.byType(TextField).first, 'Détails');
      await tester.pump();

      expect(
        tester
            .widgetList<TextField>(find.byType(TextField))
            .map((field) => field.controller!.text),
        everyElement('Détails'),
      );
      expect(_activeBrowserContext(notifier).browserQuery, 'Détails');

      notifier.setPaletteBrowserCollection(
        EditorPaletteAssetCollection.recent,
      );
      notifier.togglePaletteTilesetFavorite('details');
      notifier.selectTilesetEditorContext('details');
      await tester.pump();

      expect(
        _activeBrowserContext(notifier).browserCollection,
        EditorPaletteAssetCollection.recent,
      );
      expect(
        notifier.state.paletteSession.favoriteTilesetIds,
        <String>['details'],
      );
      expect(
        notifier.state.paletteSession.recentTilesetIds,
        contains('details'),
      );
      expect(
        find.byKey(MapPaletteAssetBrowserKeys.collectionRecent),
        findsNWidgets(2),
      );
      expect(
        tester
            .widgetList<PokeMapButton>(
              find.ancestor(
                of: find.byKey(MapPaletteAssetBrowserKeys.collectionRecent),
                matching: find.byType(PokeMapButton),
              ),
            )
            .every((button) => button.isSelected),
        isTrue,
      );
    },
  );

  testWidgets(
    'choosing an incompatible source cannot change brush tool or history',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      const contextKey = EditorPaletteContextKey(
        mapId: 'town',
        layerId: 'ground',
      );
      final keepAlive = container.listen(editorNotifierProvider, (_, __) {});
      addTearDown(keepAlive.close);
      final notifier = container.read(editorNotifierProvider.notifier)
        ..state = EditorState(
          project: project,
          workspaceMode: EditorWorkspaceMode.map,
          activeMap: map,
          activeLayerId: 'ground',
          activeTool: EditorToolType.tilePaint,
          activeBrush: const EditorBrush.tile(
            tileId: 1,
            tilesetId: 'world',
          ),
          paletteSession: EditorPaletteSession(
            activeKey: contextKey,
            contexts: <EditorPaletteContextKey, EditorLayerPaletteContext>{
              contextKey: const EditorLayerPaletteContext(
                selectedTilesetId: 'world',
                showIncompatible: true,
              ),
            },
          ),
        );
      final before = notifier.state;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: PokeMapTheme.light(),
            home: const Scaffold(
              body: SizedBox(
                width: 560,
                height: 650,
                child: MapPaletteAssetBrowser(
                  presentation: MapPaletteAssetBrowserPresentation.inspector,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(
        find.byKey(
          MapPaletteAssetBrowserKeys.tilesetRow('private_characters'),
        ),
      );
      await tester.pump();

      expect(notifier.state.activeBrush, before.activeBrush);
      expect(notifier.state.activeTool, before.activeTool);
      expect(notifier.state.paletteSession, before.paletteSession);
      expect(notifier.state.mapUndoStack, before.mapUndoStack);
      expect(notifier.state.mapRedoStack, before.mapRedoStack);
      expect(notifier.state.isDirty, before.isDirty);
    },
  );

  testWidgets(
    'browser filters declared sources without dirtying the map',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier)
        ..state = const EditorState(
          project: project,
          workspaceMode: EditorWorkspaceMode.map,
          activeMap: map,
          activeLayerId: 'ground',
        );

      await tester.binding.setSurfaceSize(const Size(800, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: PokeMapTheme.light(),
            home: const Scaffold(
              body: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: 360,
                  child: MapPaletteAssetBrowserLauncher(),
                ),
              ),
            ),
          ),
        ),
      );

      expect(
        find.byKey(MapPaletteAssetBrowserKeys.openButton),
        findsOneWidget,
      );
      await tester.tap(find.byKey(MapPaletteAssetBrowserKeys.openButton));
      await tester.pumpAndSettle();

      expect(find.byKey(MapPaletteAssetBrowserKeys.sheet), findsOneWidget);
      expect(find.byKey(MapPaletteAssetBrowserKeys.search), findsOneWidget);
      expect(
        FocusManager.instance.primaryFocus?.debugLabel,
        'world map asset browser search',
      );
      expect(find.text('Monde'), findsWidgets);
      expect(find.text('Détails'), findsOneWidget);
      expect(find.text('Personnages privés'), findsNothing);
      expect(find.byKey(MapPaletteAssetBrowserKeys.folderRail), findsOneWidget);
      expect(find.byKey(MapPaletteAssetBrowserKeys.folderAll), findsOneWidget);
      expect(
        find.byKey(MapPaletteAssetBrowserKeys.folder('root')),
        findsOneWidget,
      );

      await tester.enterText(
        find.byKey(MapPaletteAssetBrowserKeys.search),
        'Détails',
      );
      await tester.pump();

      expect(
        find.byKey(MapPaletteAssetBrowserKeys.tilesetRow('details')),
        findsOneWidget,
      );
      expect(
        find.byKey(MapPaletteAssetBrowserKeys.tilesetRow('world')),
        findsNothing,
      );
      expect(notifier.state.isDirty, isFalse);
      expect(notifier.state.mapUndoStack, isEmpty);

      await tester.tap(
        find.byKey(MapPaletteAssetBrowserKeys.favoriteButton('details')),
      );
      await tester.pump();
      expect(
        notifier.state.paletteSession.favoriteTilesetIds,
        <String>['details'],
      );

      await tester.enterText(
        find.byKey(MapPaletteAssetBrowserKeys.search),
        '',
      );
      await tester.tap(
        find.byKey(MapPaletteAssetBrowserKeys.collectionFavorites),
      );
      await tester.pump();
      expect(
        find.byKey(MapPaletteAssetBrowserKeys.tilesetRow('details')),
        findsOneWidget,
      );
      expect(
        find.byKey(MapPaletteAssetBrowserKeys.tilesetRow('world')),
        findsNothing,
      );

      await tester.tap(find.byKey(MapPaletteAssetBrowserKeys.collectionAll));
      await tester.tap(
        find.byKey(MapPaletteAssetBrowserKeys.showIncompatible),
      );
      await tester.pump();
      expect(
        find.byKey(
          MapPaletteAssetBrowserKeys.tilesetRow('private_characters'),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('autre groupe'), findsOneWidget);
      final disabledReason = tester.widget<Text>(
        find.textContaining('Cette source appartient à un autre groupe'),
      );
      expect(disabledReason.maxLines, 2);
      expect(tester.takeException(), isNull);

      await tester.tap(
        find.byKey(MapPaletteAssetBrowserKeys.folder('outdoor')),
      );
      await tester.pump();
      expect(
        find.byKey(
          MapPaletteAssetBrowserKeys.tilesetRow('private_characters'),
        ),
        findsNothing,
      );
      expect(
        _activeBrowserContext(notifier).browserFolderId,
        'outdoor',
      );
      expect(notifier.state.isDirty, isFalse);
      expect(notifier.state.mapUndoStack, isEmpty);

      await tester.tap(find.byKey(MapPaletteAssetBrowserKeys.folderAll));
      await tester.pump();
      expect(
        find.byKey(
          MapPaletteAssetBrowserKeys.tilesetRow('private_characters'),
        ),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(MapPaletteAssetBrowserKeys.tilesetRow('details')),
      );
      await tester.pump();
      expect(notifier.getSelectedTilesetEntry()?.id, 'details');
      expect(notifier.state.isDirty, isFalse);
      expect(notifier.state.mapUndoStack, isEmpty);
      expect(
        find.byKey(MapPaletteAssetBrowserKeys.assignButton('details')),
        findsOneWidget,
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byKey(MapPaletteAssetBrowserKeys.sheet), findsNothing);
      expect(
        FocusManager.instance.primaryFocus?.debugLabel,
        'world map asset browser launcher',
      );
    },
  );

  testWidgets('compact browser replaces the folder rail with a picker',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      project: project,
      workspaceMode: EditorWorkspaceMode.map,
      activeMap: map,
      activeLayerId: 'ground',
    );

    await tester.binding.setSurfaceSize(const Size(420, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: PokeMapTheme.dark(),
          home: const Scaffold(
            body: MapPaletteAssetBrowserLauncher(),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(MapPaletteAssetBrowserKeys.openButton));
    await tester.pumpAndSettle();

    expect(
      find.byKey(MapPaletteAssetBrowserKeys.folderPicker),
      findsOneWidget,
    );
    expect(find.byKey(MapPaletteAssetBrowserKeys.folderRail), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('missing assigned source stays visible as a recovery warning',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = EditorState(
      project: project,
      workspaceMode: EditorWorkspaceMode.map,
      activeMap: map.copyWith(
        layers: const <MapLayer>[
          TileLayer(
            id: 'ground',
            name: 'Sol',
            tilesetId: 'deleted_source',
            tiles: <int>[0],
          ),
        ],
      ),
      activeLayerId: 'ground',
    );

    await tester.binding.setSurfaceSize(const Size(800, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: PokeMapTheme.light(),
          home: const Scaffold(
            body: MapPaletteAssetBrowserLauncher(),
          ),
        ),
      ),
    );

    expect(find.text('Source introuvable : deleted_source'), findsOneWidget);
    await tester.tap(find.byKey(MapPaletteAssetBrowserKeys.openButton));
    await tester.pumpAndSettle();

    expect(
      find.text('Assignée introuvable : deleted_source'),
      findsOneWidget,
    );
    expect(find.textContaining('deleted_source'), findsWidgets);
    expect(find.textContaining('n’existe plus dans le projet'), findsOneWidget);
  });

  testWidgets('keyboard and semantics expose browser item states',
      (tester) async {
    final semantics = tester.ensureSemantics();
    final container = ProviderContainer();
    addTearDown(container.dispose);
    const contextKey = EditorPaletteContextKey(
      mapId: 'town',
      layerId: 'ground',
    );
    container.read(editorNotifierProvider.notifier).state = EditorState(
      project: project,
      workspaceMode: EditorWorkspaceMode.map,
      activeMap: map,
      activeLayerId: 'ground',
      paletteSession: EditorPaletteSession(
        activeKey: contextKey,
        contexts: <EditorPaletteContextKey, EditorLayerPaletteContext>{
          contextKey: const EditorLayerPaletteContext(
            selectedTilesetId: 'details',
            showIncompatible: true,
          ),
        },
        recentTilesetIds: <String>['details'],
        favoriteTilesetIds: <String>['details'],
      ),
    );

    await tester.binding.setSurfaceSize(const Size(800, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: PokeMapTheme.dark(),
          home: const Scaffold(
            body: MapPaletteAssetBrowserLauncher(),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(MapPaletteAssetBrowserKeys.openButton));
    await tester.pumpAndSettle();

    final assigned = tester.getSemantics(
      find.byKey(MapPaletteAssetBrowserKeys.tilesetSemantics('world')),
    );
    expect(assigned.label, contains('Assignée au calque actif'));

    final selectedFavorite = tester.getSemantics(
      find.byKey(MapPaletteAssetBrowserKeys.tilesetSemantics('details')),
    );
    expect(selectedFavorite.flagsCollection.isSelected, Tristate.isTrue);
    expect(selectedFavorite.label, contains('Favori de cette session'));

    final disabled = tester.getSemantics(
      find.byKey(
        MapPaletteAssetBrowserKeys.tilesetSemantics('private_characters'),
      ),
    );
    expect(disabled.flagsCollection.isEnabled, Tristate.isFalse);
    expect(disabled.label, contains('Désactivée'));
    expect(disabled.label, contains('autre groupe'));

    expect(
      FocusManager.instance.primaryFocus?.debugLabel,
      'world map asset browser search',
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(
      container
          .read(editorNotifierProvider)
          .paletteSession
          .contexts[contextKey]
          ?.browserCollection,
      EditorPaletteAssetCollection.recent,
    );
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('embedded palette keeps the launcher without a selected image',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final keepAlive = container.listen(
      editorNotifierProvider,
      (_, __) {},
    );
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      project: project,
      workspaceMode: EditorWorkspaceMode.map,
      activeMap: MapData(
        id: 'town',
        name: 'Ville',
        size: GridSize(width: 1, height: 1),
        layers: <MapLayer>[
          TileLayer(
            id: 'ground',
            name: 'Sol',
            tiles: <int>[0],
          ),
        ],
      ),
      activeLayerId: 'ground',
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: PokeMapTheme.light(),
          home: const Scaffold(
            body: SizedBox(
              width: 360,
              height: 600,
              child: TilesetPalettePanel(embedded: true),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(MapPaletteAssetBrowserKeys.openButton),
      findsOneWidget,
    );
    expect(find.text('Aucun tileset sélectionné'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    keepAlive.close();
    await container.pump();
    await tester.pump();
  });

  testWidgets('embedded palette keeps the launcher after an image failure',
      (tester) async {
    final container = ProviderContainer(
      overrides: <Override>[
        editorImageCacheProvider.overrideWith(
          (ref, projectRoot) {
            final cache = _FailingEditorImageCache(projectRoot);
            ref.onDispose(cache.dispose);
            return cache;
          },
        ),
      ],
    );
    container.listen(editorNotifierProvider, (_, __) {});
    container.read(editorNotifierProvider.notifier).state = EditorState(
      projectRootPath: p.join(
        Directory.systemTemp.path,
        'pokemap_asset_browser_missing_project',
      ),
      project: project,
      workspaceMode: EditorWorkspaceMode.map,
      activeMap: map,
      activeLayerId: 'ground',
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: PokeMapTheme.light(),
          home: const Scaffold(
            body: SizedBox(
              width: 360,
              height: 600,
              child: TilesetPalettePanel(embedded: true),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(
      find.byKey(MapPaletteAssetBrowserKeys.openButton),
      findsOneWidget,
    );
    expect(find.text('Tileset image unavailable'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
    await tester.pump();
  });

  testWidgets('explicit browser assignment is one local undoable mutation',
      (tester) async {
    final root = await tester.runAsync(() async {
      final directory = await Directory.systemTemp.createTemp(
        'pokemap_asset_browser_assignment_',
      );
      await FileProjectRepository().saveProject(
        project,
        p.join(directory.path, 'project.json'),
      );
      await FileMapRepository().saveMap(
        map,
        p.join(directory.path, 'maps', 'town.json'),
        projectDialogueContext: project,
      );
      return directory;
    });
    final projectRoot = root!;
    addTearDown(() async {
      if (await projectRoot.exists()) {
        await projectRoot.delete(recursive: true);
      }
    });
    final mapPath = p.join(projectRoot.path, 'maps', 'town.json');

    final container = ProviderContainer();
    addTearDown(container.dispose);
    final keepAlive = container.listen(
      editorNotifierProvider,
      (_, __) {},
    );
    final notifier = container.read(editorNotifierProvider.notifier)
      ..state = EditorState(
        projectRootPath: projectRoot.path,
        project: project,
        workspaceMode: EditorWorkspaceMode.map,
        activeMap: map,
        activeMapPath: mapPath,
        activeLayerId: 'ground',
        savedMapSnapshot: map,
      );

    await tester.binding.setSurfaceSize(const Size(800, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: PokeMapTheme.light(),
          home: const Scaffold(
            body: MapPaletteAssetBrowserLauncher(),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(MapPaletteAssetBrowserKeys.openButton));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(MapPaletteAssetBrowserKeys.tilesetRow('details')),
    );
    await tester.pump();
    expect(notifier.getSelectedTilesetEntry()?.id, 'details');
    await tester.tap(
      find.byKey(MapPaletteAssetBrowserKeys.assignButton('details')),
    );
    await tester.pump();

    expect(notifier.state.isDirty, isTrue);
    expect(notifier.state.mapUndoStack, hasLength(1));
    expect(
      (notifier.state.activeMap!.layers.first as TileLayer).tilesetId,
      'details',
    );
    expect(
      (await tester.runAsync(
        () => FileMapRepository().loadMap(mapPath),
      ))!
          .layers
          .first,
      isA<TileLayer>().having(
        (layer) => layer.tilesetId,
        'tilesetId',
        'world',
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
    keepAlive.close();
    await container.pump();
    await tester.pump();
  });
}

const project = ProjectManifest(
  name: 'Browser widget',
  groups: <ProjectMapGroup>[
    ProjectMapGroup(
      id: 'towns',
      name: 'Villes',
      type: MapGroupType.city,
    ),
    ProjectMapGroup(
      id: 'private',
      name: 'Privé',
      type: MapGroupType.special,
    ),
  ],
  maps: <ProjectMapEntry>[
    ProjectMapEntry(
      id: 'town',
      name: 'Ville',
      relativePath: 'maps/town.json',
      groupId: 'towns',
    ),
  ],
  tilesetFolders: <ProjectTilesetFolder>[
    ProjectTilesetFolder(id: 'outdoor', name: 'Extérieur'),
    ProjectTilesetFolder(id: 'root', name: 'Racine'),
  ],
  tilesets: <ProjectTilesetEntry>[
    ProjectTilesetEntry(
      id: 'world',
      name: 'Monde',
      relativePath: 'tilesets/world.png',
      folderId: 'outdoor',
    ),
    ProjectTilesetEntry(
      id: 'details',
      name: 'Détails',
      relativePath: 'tilesets/details.png',
      folderId: 'outdoor',
      sortOrder: 1,
    ),
    ProjectTilesetEntry(
      id: 'private_characters',
      name: 'Personnages privés',
      relativePath: 'tilesets/private.png',
      scope: TilesetScope.group,
      groupId: 'private',
    ),
  ],
);

const map = MapData(
  id: 'town',
  name: 'Ville',
  size: GridSize(width: 1, height: 1),
  layers: <MapLayer>[
    TileLayer(
      id: 'ground',
      name: 'Sol',
      tilesetId: 'world',
      tiles: <int>[0],
    ),
  ],
);

class _FailingEditorImageCache extends EditorImageCache {
  _FailingEditorImageCache(String sessionKey) : super(sessionKey: sessionKey);

  @override
  Future<EditorImageLoadResult> load(
    String? path, {
    String variantKey = 'original',
    int? targetWidth,
    int? targetHeight,
    bool allowUpscaling = true,
    EditorImageBytesTransform? transformBytes,
  }) {
    return Future<EditorImageLoadResult>.value(
      EditorImageLoadResult.failure(
        EditorImageFailure(
          kind: EditorImageFailureKind.missingFile,
          path: path ?? '',
          message: 'Synthetic missing image.',
        ),
      ),
    );
  }
}

EditorLayerPaletteContext _activeBrowserContext(EditorNotifier notifier) {
  final activeMap = notifier.state.activeMap!;
  final key = EditorPaletteContextKey(
    mapId: activeMap.id,
    layerId: notifier.state.activeLayerId!,
  );
  return notifier.state.paletteSession.contexts[key]!;
}
