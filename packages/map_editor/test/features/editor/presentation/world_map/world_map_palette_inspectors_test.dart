import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/app/providers/editor/editor_asset_cache_providers.dart';
import 'package:map_editor/src/features/editor/application/world_map_inspector_projector.dart';
import 'package:map_editor/src/features/editor/application/world_map_tool_activation.dart';
import 'package:map_editor/src/features/editor/application/world_map_tool_family.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/adaptive_map_inspector.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/world_map_paint_inspector.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/world_map_place_inspector.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/world_map_workspace_session.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor/tools/editor_tool.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/assets/editor_image_cache.dart';
import 'package:map_editor/src/ui/panels/tileset_palette/widgets/browser/map_palette_asset_browser.dart';
import 'package:map_editor/src/ui/panels/tileset_palette/widgets/palette/map_layer_asset_palette.dart';

void main() {
  testWidgets(
    'Paint Elements renders named cards and keeps Paint after selection',
    (tester) async {
      final harness = await _InspectorHarness.create();
      addTearDown(harness.dispose);
      harness.session.activateTool(
        harness.notifier,
        const ActivateWorldMapPaint(WorldMapPaintSubtool.tile),
      );

      await harness.pump(tester, const AdaptiveMapInspector());

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label ==
                  'Catalogue d’éléments à placer du calque actif',
        ),
        findsOneWidget,
      );
      expect(find.byType(MapPaletteAssetBrowserLauncher), findsOneWidget);
      expect(find.text('Changer de source'), findsOneWidget);
      expect(
        find.byKey(MapLayerAssetPaletteKeys.elementCard('tree')),
        findsOneWidget,
      );
      expect(find.text('Arbre'), findsOneWidget);
      expect(find.byWidgetPredicate(_isRawTileCell), findsNothing);

      await tester.tap(
        find.byKey(MapLayerAssetPaletteKeys.elementCard('tree')),
      );
      await tester.pump();

      expect(
        harness.notifier.state.activeBrush,
        const EditorBrush.projectElement(elementId: 'tree'),
      );
      expect(harness.notifier.state.activeTool, EditorToolType.tilePaint);
      expect(
        harness.container.read(worldMapWorkspaceSessionProvider).activeFamily,
        WorldMapToolFamily.paint,
      );
      expect(
        harness.container.read(worldMapInspectorSnapshotProvider).kind,
        WorldMapInspectorKind.paint,
      );
      expect(find.byType(WorldMapPaintInspector), findsOneWidget);
      expect(find.byType(WorldMapPlaceInspector), findsNothing);
    },
  );

  testWidgets(
    'Paint non-tile subtools show non-mutating guidance without an asset palette',
    (tester) async {
      final harness = await _InspectorHarness.create(
        initialSession: const WorldMapWorkspaceSession(
          activeFamily: WorldMapToolFamily.paint,
          lastPaintSubtool: WorldMapPaintSubtool.terrain,
        ),
      );
      addTearDown(harness.dispose);
      final before = harness.notifier.state;

      await harness.pump(tester, const WorldMapPaintInspector());

      expect(find.byType(MapLayerAssetPalette), findsNothing);
      expect(find.textContaining('Terrain'), findsWidgets);
      expect(harness.notifier.state, before);
    },
  );

  testWidgets(
    'Place Object keeps its named-card selection in Place',
    (tester) async {
      final harness = await _InspectorHarness.create();
      addTearDown(harness.dispose);
      harness.session.activateTool(
        harness.notifier,
        const ActivateWorldMapPlacement(WorldMapPlacementSubtool.object),
      );

      await harness.pump(tester, const AdaptiveMapInspector());

      expect(
        find.byKey(MapLayerAssetPaletteKeys.elementCard('tree')),
        findsOneWidget,
      );
      expect(find.byType(MapPaletteAssetBrowserLauncher), findsOneWidget);
      expect(find.text('Changer de source'), findsOneWidget);

      await tester.tap(
        find.byKey(MapLayerAssetPaletteKeys.elementCard('tree')),
      );
      await tester.pump();

      expect(
        harness.notifier.state.activeBrush,
        const EditorBrush.projectElement(elementId: 'tree'),
      );
      expect(harness.notifier.state.activeTool, EditorToolType.tilePaint);
      expect(
        harness.container.read(worldMapWorkspaceSessionProvider).activeFamily,
        WorldMapToolFamily.place,
      );
      expect(
        harness.container.read(worldMapInspectorSnapshotProvider).kind,
        WorldMapInspectorKind.place,
      );
      expect(find.byType(WorldMapPlaceInspector), findsOneWidget);
      expect(find.byType(WorldMapPaintInspector), findsNothing);
    },
  );

  testWidgets(
    'Place non-object subtools show non-mutating guidance without an asset palette',
    (tester) async {
      final harness = await _InspectorHarness.create(
        initialSession: const WorldMapWorkspaceSession(
          activeFamily: WorldMapToolFamily.place,
          lastPlacementSubtool: WorldMapPlacementSubtool.entity,
        ),
      );
      addTearDown(harness.dispose);
      final before = harness.notifier.state;

      await harness.pump(tester, const WorldMapPlaceInspector());

      expect(find.byType(MapLayerAssetPalette), findsNothing);
      expect(find.textContaining('Entity'), findsWidgets);
      expect(harness.notifier.state, before);
    },
  );
}

bool _isRawTileCell(Widget widget) {
  final key = widget.key;
  return key is ValueKey<String> &&
      key.value.startsWith('world-map-layer-asset-tile-');
}

class _InspectorHarness {
  _InspectorHarness._({
    required this.container,
    required this.image,
  }) {
    keepAlive = container.listen(editorNotifierProvider, (_, __) {});
    notifier.state = const EditorState(
      projectRootPath: '/virtual/project',
      project: _project,
      workspaceMode: EditorWorkspaceMode.map,
      activeMap: _map,
      activeLayerId: 'ground',
    );
  }

  static Future<_InspectorHarness> create({
    WorldMapWorkspaceSession initialSession = const WorldMapWorkspaceSession(),
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 1, 1),
      Paint()..color = const Color(0xFFFFFFFF),
    );
    final picture = recorder.endRecording();
    final image = await picture.toImage(1, 1);
    picture.dispose();
    final container = ProviderContainer(
      overrides: <Override>[
        editorImageCacheProvider.overrideWith(
          (ref, projectRoot) => _ImmediateEditorImageCache(
            projectRoot,
            image,
          ),
        ),
        worldMapWorkspaceSessionProvider.overrideWith(
          () => _TestWorldMapWorkspaceSessionController(initialSession),
        ),
      ],
    );
    return _InspectorHarness._(
      container: container,
      image: image,
    );
  }

  final ProviderContainer container;
  final ui.Image image;
  late final ProviderSubscription<EditorState> keepAlive;

  EditorNotifier get notifier =>
      container.read(editorNotifierProvider.notifier);

  WorldMapWorkspaceSessionController get session =>
      container.read(worldMapWorkspaceSessionProvider.notifier);

  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: PokeMapTheme.light(),
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 600,
              child: child,
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

class _TestWorldMapWorkspaceSessionController
    extends WorldMapWorkspaceSessionController {
  _TestWorldMapWorkspaceSessionController(this.initialSession);

  final WorldMapWorkspaceSession initialSession;

  @override
  WorldMapWorkspaceSession build() => initialSession;
}

const _project = ProjectManifest(
  name: 'Inspecteurs palette',
  maps: <ProjectMapEntry>[
    ProjectMapEntry(
      id: 'town',
      name: 'Ville',
      relativePath: 'maps/town.json',
    ),
  ],
  tilesets: <ProjectTilesetEntry>[
    ProjectTilesetEntry(
      id: 'world',
      name: 'Monde',
      relativePath: 'tilesets/world.png',
    ),
  ],
  elementCategories: <ProjectElementCategory>[
    ProjectElementCategory(id: 'nature', name: 'Nature'),
  ],
  elements: <ProjectElementEntry>[
    ProjectElementEntry(
      id: 'tree',
      name: 'Arbre',
      tilesetId: 'world',
      categoryId: 'nature',
      frames: <TilesetVisualFrame>[
        TilesetVisualFrame(
          source: TilesetSourceRect(x: 0, y: 0),
        ),
      ],
    ),
  ],
  settings: ProjectSettings(tileWidth: 1, tileHeight: 1),
);

const _map = MapData(
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
