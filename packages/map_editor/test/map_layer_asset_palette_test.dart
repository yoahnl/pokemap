import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/app/providers/editor/editor_asset_cache_providers.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor/tools/editor_tool.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/assets/editor_image_cache.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';
import 'package:map_editor/src/ui/panels/tileset_palette/widgets/palette/map_layer_asset_palette.dart';

void main() {
  testWidgets(
    'multi-cell atlas without project elements renders no raw tiles and explains where to define objects',
    (tester) async {
      final harness = await _PaletteHarness.create(
        project: _projectWithoutElements,
      );
      addTearDown(harness.dispose);

      await harness.pump(tester);

      expect(find.byType(PokeMapAssetCard), findsNothing);
      expect(find.text('Aucun objet à placer'), findsOneWidget);
      expect(
        find.textContaining('Tileset Library'),
        findsOneWidget,
      );
      expect(harness.notifier.state.activeBrush, const EditorBrush.none());
      expect(harness.notifier.state.activeTool, EditorToolType.selection);
      expect(harness.notifier.state.mapUndoStack, isEmpty);
    },
  );

  testWidgets(
    'renders real project-element cards from the assigned source',
    (tester) async {
      final harness = await _PaletteHarness.create();
      addTearDown(harness.dispose);

      await harness.pump(tester);

      expect(
        find.byKey(MapLayerAssetPaletteKeys.elementCard('tree')),
        findsOneWidget,
      );
      final treeCard = find.byKey(
        MapLayerAssetPaletteKeys.elementCard('tree'),
      );
      expect(find.text('Arbre'), findsOneWidget);
      expect(
        find.descendant(
          of: treeCard,
          matching: find.textContaining('Type : Arbre'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: treeCard,
          matching: find.textContaining('Collision : 2'),
        ),
        findsOneWidget,
      );
      expect(find.text('Lampe'), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(MapLayerAssetPaletteKeys.root),
          matching: find.byType(Scrollable),
        ),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(MapLayerAssetPaletteKeys.elementCard('tree')),
      );
      await tester.pump();

      expect(
        harness.notifier.state.activeBrush,
        const EditorBrush.projectElement(elementId: 'tree'),
      );
      expect(harness.notifier.state.activeTool, EditorToolType.tilePaint);
      expect(harness.notifier.state.mapUndoStack, isEmpty);
    },
  );

  testWidgets(
    'compatible but unassigned assets expose a reason and cannot mutate through pointer Enter or Space',
    (tester) async {
      final harness = await _PaletteHarness.create(
        selectedTilesetId: 'details',
        activeBrush: const EditorBrush.projectElement(elementId: 'tree'),
        activeTool: EditorToolType.tilePaint,
      );
      addTearDown(harness.dispose);
      final before = harness.notifier.state;

      await harness.pump(tester);

      final cardFinder = find.byKey(
        MapLayerAssetPaletteKeys.elementCard('lamp'),
      );
      final card = tester.widget<PokeMapAssetCard>(cardFinder);
      expect(card.onPressed, isNull);
      expect(card.disabledReason, contains('Assignez'));
      expect(
        tester
            .widget<Tooltip>(
              find.descendant(
                of: cardFinder,
                matching: find.byType(Tooltip),
              ),
            )
            .message,
        contains('Assignez'),
      );

      await tester.tap(cardFinder);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();

      _expectNoEditorMutation(harness.notifier.state, before);
    },
  );

  testWidgets(
    'incompatible source reason comes from the canonical browser projection and stays inert',
    (tester) async {
      final harness = await _PaletteHarness.create(
        selectedTilesetId: 'private_characters',
      );
      addTearDown(harness.dispose);
      final before = harness.notifier.state;

      await harness.pump(tester);

      final cardFinder = find.byKey(
        MapLayerAssetPaletteKeys.elementCard('private_actor'),
      );
      final card = tester.widget<PokeMapAssetCard>(cardFinder);
      expect(card.onPressed, isNull);
      expect(card.disabledReason, contains('autre groupe'));
      expect(find.text('Personnage privé'), findsOneWidget);

      await tester.tap(cardFinder);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();

      _expectNoEditorMutation(harness.notifier.state, before);
    },
  );

  testWidgets(
    'active filters with no match give context-neutral reset guidance',
    (tester) async {
      final harness = await _PaletteHarness.create(
        projectElementCategoryId: 'decor',
      );
      addTearDown(harness.dispose);

      await harness.pump(tester);

      expect(
        find.text('Aucun objet ne correspond aux filtres actifs'),
        findsOneWidget,
      );
      expect(
        find.text(
          'Modifiez ou réinitialisez les filtres actifs pour afficher les '
          'objets.',
        ),
        findsOneWidget,
      );
      expect(find.byType(PokeMapAssetCard), findsNothing);
    },
  );

  testWidgets(
    'A to B to A restores each layer source and selected asset',
    (tester) async {
      final harness = await _PaletteHarness.create();
      addTearDown(harness.dispose);

      await harness.pump(tester);
      await tester.tap(
        find.byKey(MapLayerAssetPaletteKeys.elementCard('tree')),
      );
      await tester.pump();

      harness.notifier.setActiveLayer('details');
      await tester.pump();
      await tester.pump();
      expect(find.text('Détails'), findsWidgets);
      expect(
        find.byKey(MapLayerAssetPaletteKeys.elementCard('lamp')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(MapLayerAssetPaletteKeys.elementCard('lamp')),
      );
      await tester.pump();

      harness.notifier.setActiveLayer('ground');
      await tester.pump();
      await tester.pump();
      expect(find.text('Monde'), findsWidgets);
      expect(
        tester
            .widget<PokeMapAssetCard>(
              find.byKey(MapLayerAssetPaletteKeys.elementCard('tree')),
            )
            .selected,
        isTrue,
      );
      expect(
        harness.notifier.getSelectedTilesetEntry()?.id,
        'world',
      );
      expect(
        harness.notifier.state.activeBrush,
        const EditorBrush.projectElement(elementId: 'tree'),
      );

      harness.notifier.setActiveLayer('details');
      await tester.pump();
      await tester.pump();
      expect(
        tester
            .widget<PokeMapAssetCard>(
              find.byKey(MapLayerAssetPaletteKeys.elementCard('lamp')),
            )
            .selected,
        isTrue,
      );
      expect(
        harness.notifier.getSelectedTilesetEntry()?.id,
        'details',
      );
      expect(
        harness.notifier.state.activeBrush,
        const EditorBrush.projectElement(elementId: 'lamp'),
      );
      expect(harness.notifier.state.mapUndoStack, isEmpty);
    },
  );
}

void _expectNoEditorMutation(EditorState actual, EditorState before) {
  expect(actual.activeBrush, before.activeBrush);
  expect(actual.activeTool, before.activeTool);
  expect(actual.activeLayerId, before.activeLayerId);
  expect(actual.paletteSession, before.paletteSession);
  expect(actual.mapUndoStack, before.mapUndoStack);
  expect(actual.mapRedoStack, before.mapRedoStack);
  expect(actual.isDirty, before.isDirty);
}

class _PaletteHarness {
  _PaletteHarness({
    required this.container,
    required this.image,
    required this.keepAlive,
  });

  final ProviderContainer container;
  final ui.Image image;
  final ProviderSubscription<EditorState> keepAlive;

  EditorNotifier get notifier =>
      container.read(editorNotifierProvider.notifier);

  static Future<_PaletteHarness> create({
    ProjectManifest project = _project,
    String? selectedTilesetId,
    String? projectElementCategoryId,
    EditorBrush activeBrush = const EditorBrush.none(),
    EditorToolType activeTool = EditorToolType.selection,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 2, 1),
      Paint()..color = const Color(0xFFFFFFFF),
    );
    final picture = recorder.endRecording();
    final image = await picture.toImage(2, 1);
    picture.dispose();
    final container = ProviderContainer(
      overrides: <Override>[
        editorImageCacheProvider.overrideWith(
          (ref, projectRoot) => _ImmediateEditorImageCache(
            projectRoot,
            image,
          ),
        ),
      ],
    );
    final keepAlive = container.listen(
      editorNotifierProvider,
      (_, __) {},
    );
    const contextKey = EditorPaletteContextKey(
      mapId: 'town',
      layerId: 'ground',
    );
    container.read(editorNotifierProvider.notifier).state = EditorState(
      projectRootPath: '/virtual/project',
      project: project,
      workspaceMode: EditorWorkspaceMode.map,
      activeMap: _map,
      activeLayerId: 'ground',
      activeTool: activeTool,
      activeBrush: activeBrush,
      paletteSession: selectedTilesetId == null &&
              projectElementCategoryId == null
          ? const EditorPaletteSession()
          : EditorPaletteSession(
              activeKey: contextKey,
              contexts: <EditorPaletteContextKey, EditorLayerPaletteContext>{
                contextKey: EditorLayerPaletteContext(
                  selectedTilesetId: selectedTilesetId,
                  projectElementCategoryId: projectElementCategoryId,
                ),
              },
            ),
    );
    return _PaletteHarness(
      container: container,
      image: image,
      keepAlive: keepAlive,
    );
  }

  Future<void> pump(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 620));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: PokeMapTheme.light(),
          home: const Scaffold(
            body: SizedBox(
              width: 400,
              height: 600,
              child: MapLayerAssetPalette(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  void dispose() {
    keepAlive.close();
    container.dispose();
    image.dispose();
  }
}

class _ImmediateEditorImageCache extends EditorImageCache {
  _ImmediateEditorImageCache(String sessionKey, this._image)
      : super(sessionKey: sessionKey);

  final ui.Image _image;

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
      EditorImageLoadResult.success(_image.clone()),
    );
  }
}

const _project = ProjectManifest(
  name: 'Palette publique',
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
  tilesets: <ProjectTilesetEntry>[
    ProjectTilesetEntry(
      id: 'world',
      name: 'Monde',
      relativePath: 'tilesets/world.png',
    ),
    ProjectTilesetEntry(
      id: 'details',
      name: 'Détails',
      relativePath: 'tilesets/details.png',
    ),
    ProjectTilesetEntry(
      id: 'private_characters',
      name: 'Personnages privés',
      relativePath: 'tilesets/private.png',
      scope: TilesetScope.group,
      groupId: 'private',
    ),
  ],
  elementCategories: <ProjectElementCategory>[
    ProjectElementCategory(id: 'nature', name: 'Nature'),
    ProjectElementCategory(id: 'decor', name: 'Décor'),
  ],
  elements: <ProjectElementEntry>[
    ProjectElementEntry(
      id: 'tree',
      name: 'Arbre',
      tilesetId: 'world',
      categoryId: 'nature',
      presetKind: ElementPresetKind.tree,
      collisionProfile: ElementCollisionProfile(
        cells: <GridPos>[
          GridPos(x: 0, y: 0),
          GridPos(x: 0, y: 1),
        ],
      ),
      frames: <TilesetVisualFrame>[
        TilesetVisualFrame(
          source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 1),
        ),
      ],
    ),
    ProjectElementEntry(
      id: 'lamp',
      name: 'Lampe',
      tilesetId: 'details',
      categoryId: 'decor',
      frames: <TilesetVisualFrame>[
        TilesetVisualFrame(
          source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 1),
        ),
      ],
    ),
    ProjectElementEntry(
      id: 'private_actor',
      name: 'Personnage privé',
      tilesetId: 'private_characters',
      categoryId: 'decor',
      frames: <TilesetVisualFrame>[
        TilesetVisualFrame(
          source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 1),
        ),
      ],
    ),
  ],
  settings: ProjectSettings(tileWidth: 1, tileHeight: 1),
);

const _projectWithoutElements = ProjectManifest(
  name: 'Palette sans objets',
  maps: <ProjectMapEntry>[
    ProjectMapEntry(
      id: 'town',
      name: 'Ville',
      relativePath: 'maps/town.json',
      groupId: 'towns',
    ),
  ],
  groups: <ProjectMapGroup>[
    ProjectMapGroup(
      id: 'towns',
      name: 'Villes',
      type: MapGroupType.city,
    ),
  ],
  tilesets: <ProjectTilesetEntry>[
    ProjectTilesetEntry(
      id: 'world',
      name: 'Monde',
      relativePath: 'tilesets/world.png',
    ),
    ProjectTilesetEntry(
      id: 'details',
      name: 'Détails',
      relativePath: 'tilesets/details.png',
    ),
  ],
  settings: ProjectSettings(tileWidth: 1, tileHeight: 1),
);

const _map = MapData(
  id: 'town',
  name: 'Ville',
  size: GridSize(width: 2, height: 1),
  layers: <MapLayer>[
    TileLayer(
      id: 'ground',
      name: 'Sol',
      tilesetId: 'world',
      tiles: <int>[0, 0],
    ),
    TileLayer(
      id: 'details',
      name: 'Détails',
      tilesetId: 'details',
      tiles: <int>[0, 0],
    ),
  ],
);
