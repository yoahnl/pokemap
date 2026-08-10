import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/misc.dart' show Override;
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
  testWidgets('compatible cross-source asset is immediately available', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final harness = await _AssetHarness.create(selectedSourceId: 'details');
    addTearDown(() => harness.dispose(tester));
    await harness.pump(tester);
    final cardFinder = find.byKey(MapLayerAssetPaletteKeys.elementCard('lamp'));
    final enabledCard = tester.widget<PokeMapAssetCard>(cardFinder);

    expect(enabledCard.onPressed, isNotNull);
    expect(enabledCard.disabledReason, isNull);
    expect(
      tester
          .widgetList<FocusableActionDetector>(
            find.descendant(
              of: cardFinder,
              matching: find.byType(FocusableActionDetector),
            ),
          )
          .single
          .enabled,
      isTrue,
    );

    await tester.tap(cardFinder);
    await tester.pump();
    expect(
      harness.notifier.state.activeBrush,
      const EditorBrush.projectElement(elementId: 'lamp'),
    );
    expect(harness.notifier.state.activeTool, EditorToolType.tilePaint);
    semantics.dispose();
  });

  testWidgets(
    'incompatible source stays disabled and cannot change brush or tool',
    (tester) async {
      final harness = await _AssetHarness.create(selectedSourceId: 'private');
      addTearDown(() => harness.dispose(tester));
      await harness.pump(tester);
      final cardFinder = find.byKey(
        MapLayerAssetPaletteKeys.elementCard('private-actor'),
      );
      final before = harness.notifier.state;
      final card = tester.widget<PokeMapAssetCard>(cardFinder);

      expect(card.onPressed, isNull);
      expect(card.disabledReason, contains('autre groupe'));
      await tester.pump();
      await tester.tap(cardFinder);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);

      expect(harness.notifier.state.activeBrush, before.activeBrush);
      expect(harness.notifier.state.activeTool, before.activeTool);
      expect(harness.notifier.state.mapUndoStack, before.mapUndoStack);
      expect(harness.notifier.state.activeMap, before.activeMap);
      expect(
        harness
            .notifier
            .state
            .paletteSession
            .contexts[harness.notifier.state.paletteSession.activeKey]
            ?.selectedTilesetId,
        'private',
      );
    },
  );
}

class _AssetHarness {
  const _AssetHarness({
    required this.container,
    required this.subscription,
    required this.image,
  });

  final ProviderContainer container;
  final ProviderSubscription<EditorState> subscription;
  final ui.Image image;

  EditorNotifier get notifier =>
      container.read(editorNotifierProvider.notifier);

  static Future<_AssetHarness> create({
    required String selectedSourceId,
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
          (ref, root) => _ImmediateImageCache(root, image),
        ),
      ],
    );
    final subscription = container.listen<EditorState>(
      editorNotifierProvider,
      (_, _) {},
      fireImmediately: true,
    );
    const contextKey = EditorPaletteContextKey(
      mapId: 'town',
      layerId: 'ground',
    );
    container.read(editorNotifierProvider.notifier).state = EditorState(
      projectRootPath: '/virtual/assets',
      activeMapPath: '/virtual/maps/town.json',
      project: _project,
      activeMap: _mapFor('world'),
      activeLayerId: 'ground',
      activeTool: EditorToolType.selection,
      paletteSession: EditorPaletteSession(
        activeKey: contextKey,
        contexts: <EditorPaletteContextKey, EditorLayerPaletteContext>{
          contextKey: EditorLayerPaletteContext(
            selectedTilesetId: selectedSourceId,
          ),
        },
      ),
    );
    return _AssetHarness(
      container: container,
      subscription: subscription,
      image: image,
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

  Future<void> dispose(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    subscription.close();
    container.dispose();
    image.dispose();
  }
}

class _ImmediateImageCache extends EditorImageCache {
  _ImmediateImageCache(String sessionKey, this.image)
    : super(sessionKey: sessionKey);

  final ui.Image image;

  @override
  Future<EditorImageLoadResult> load(
    String? path, {
    String variantKey = 'original',
    int? targetWidth,
    int? targetHeight,
    bool allowUpscaling = true,
    EditorImageBytesTransform? transformBytes,
  }) async {
    return EditorImageLoadResult.success(image.clone());
  }
}

const _project = ProjectManifest(
  name: 'Asset accessibility',
  groups: <ProjectMapGroup>[
    ProjectMapGroup(id: 'towns', name: 'Villes', type: MapGroupType.city),
    ProjectMapGroup(id: 'private', name: 'Privé', type: MapGroupType.special),
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
      id: 'private',
      name: 'Privé',
      relativePath: 'tilesets/private.png',
      scope: TilesetScope.group,
      groupId: 'private',
    ),
  ],
  elements: <ProjectElementEntry>[
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
      id: 'private-actor',
      name: 'Personnage privé',
      tilesetId: 'private',
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

MapData _mapFor(String sourceId) {
  return MapData(
    id: 'town',
    name: 'Ville',
    size: const GridSize(width: 2, height: 1),
    layers: <MapLayer>[
      TileLayer(
        id: 'ground',
        name: 'Sol',
        palette: <TileLayerPaletteEntry>[
          TileLayerPaletteEntry(tilesetId: sourceId, localTileId: 0),
        ],
        cells: const <int>[0, 0],
      ),
    ],
  );
}
