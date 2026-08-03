import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/application/world_map_tool_family.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/world_map_paint_inspection_intent.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';

void main() {
  test('owns setup intent outside the workspace session', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final editor = container.read(editorNotifierProvider.notifier)
      ..state = const EditorState(
        project: _project,
        activeMap: _mapA,
        activeLayerId: 'surface',
      );
    final subscription = container.listen(
      worldMapPaintInspectionIntentProvider,
      (_, __) {},
    );
    addTearDown(subscription.close);
    final controller =
        container.read(worldMapPaintInspectionIntentProvider.notifier);

    expect(container.read(worldMapPaintInspectionIntentProvider), isNull);

    controller.showSetup(
      mapId: 'map-a',
      layerId: 'surface',
      subtool: WorldMapPaintSubtool.surface,
    );

    expect(
      container.read(worldMapPaintInspectionIntentProvider),
      const WorldMapPaintInspectionIntent(
        scope: (
          projectRootPath: null,
          activeMapPath: null,
          activeMapId: 'map-a',
        ),
        layerId: 'surface',
        subtool: WorldMapPaintSubtool.surface,
      ),
    );
    expect(editor.state.activeMap, same(_mapA));
  });

  test('invalidates setup intent when map or layer ownership changes', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final editor = container.read(editorNotifierProvider.notifier)
      ..state = const EditorState(
        project: _project,
        activeMap: _mapA,
        activeLayerId: 'surface',
      );
    final subscription = container.listen(
      worldMapPaintInspectionIntentProvider,
      (_, __) {},
    );
    addTearDown(subscription.close);
    final controller =
        container.read(worldMapPaintInspectionIntentProvider.notifier);

    controller.showSetup(
      mapId: 'map-a',
      layerId: 'surface',
      subtool: WorldMapPaintSubtool.surface,
    );
    editor.state = editor.state.copyWith(activeLayerId: 'border');
    expect(container.read(worldMapPaintInspectionIntentProvider), isNull);

    controller.showSetup(
      mapId: 'map-a',
      layerId: 'border',
      subtool: WorldMapPaintSubtool.border,
    );
    editor.state = editor.state.copyWith(
      activeMap: _mapB,
      activeLayerId: 'border',
    );
    expect(container.read(worldMapPaintInspectionIntentProvider), isNull);
  });

  test('owns a compact layer choice without changing editor state', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final editor = container.read(editorNotifierProvider.notifier)
      ..state = const EditorState(
        project: _project,
        activeMap: _mapA,
        activeLayerId: 'surface',
      );
    final subscription = container.listen(
      worldMapPaintInspectionIntentProvider,
      (_, __) {},
    );
    addTearDown(subscription.close);
    final before = editor.state;
    final controller =
        container.read(worldMapPaintInspectionIntentProvider.notifier);

    controller.showLayerChoice(
      mapId: 'map-a',
      subtool: WorldMapPaintSubtool.border,
      compatibleLayerIds: const <String>['border', 'border-secondary'],
    );

    final intent = container.read(worldMapPaintInspectionIntentProvider);
    expect(intent?.kind, WorldMapPaintInspectionIntentKind.layerChoice);
    expect(intent?.mapId, 'map-a');
    expect(intent?.layerId, isNull);
    expect(intent?.subtool, WorldMapPaintSubtool.border);
    expect(
      intent?.compatibleLayerIds,
      const <String>['border', 'border-secondary'],
    );
    expect(editor.state, same(before));
  });

  test('owns guided missing-layer intent and invalidates it on map change', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final editor = container.read(editorNotifierProvider.notifier)
      ..state = const EditorState(
        project: _project,
        activeMap: _mapA,
        activeLayerId: 'surface',
      );
    final subscription = container.listen(
      worldMapPaintInspectionIntentProvider,
      (_, __) {},
    );
    addTearDown(subscription.close);
    final controller =
        container.read(worldMapPaintInspectionIntentProvider.notifier);

    controller.showMissingLayer(
      mapId: 'map-a',
      subtool: WorldMapPaintSubtool.collision,
    );

    final intent = container.read(worldMapPaintInspectionIntentProvider);
    expect(intent?.kind, WorldMapPaintInspectionIntentKind.missingLayer);
    expect(intent?.layerId, isNull);
    expect(intent?.compatibleLayerIds, isEmpty);

    editor.state = editor.state.copyWith(
      activeMap: _mapB,
      activeLayerId: 'border',
    );
    expect(container.read(worldMapPaintInspectionIntentProvider), isNull);
  });

  test(
    'invalidates an intent across homonymous maps in different documents',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final editor = container.read(editorNotifierProvider.notifier)
        ..state = const EditorState(
          projectRootPath: '/projects/alpha',
          activeMapPath: '/projects/alpha/maps/shared.json',
          project: _project,
          activeMap: _mapA,
          activeLayerId: 'surface',
        );
      final subscription = container.listen(
        worldMapPaintInspectionIntentProvider,
        (_, __) {},
      );
      addTearDown(subscription.close);
      final controller =
          container.read(worldMapPaintInspectionIntentProvider.notifier);

      controller.showSetup(
        mapId: 'map-a',
        layerId: 'surface',
        subtool: WorldMapPaintSubtool.surface,
      );
      expect(
        container.read(effectiveWorldMapPaintInspectionIntentProvider),
        isNotNull,
      );

      editor.state = editor.state.copyWith(
        projectRootPath: '/projects/beta',
        activeMapPath: '/projects/beta/maps/shared.json',
        activeMap: _mapA,
        activeLayerId: 'surface',
      );

      expect(
        container.read(effectiveWorldMapPaintInspectionIntentProvider),
        isNull,
      );
      expect(container.read(worldMapPaintInspectionIntentProvider), isNull);
    },
  );
}

const _project = ProjectManifest(
  name: 'Paint inspection intent',
  maps: <ProjectMapEntry>[],
  tilesets: <ProjectTilesetEntry>[],
);

const _mapA = MapData(
  id: 'map-a',
  name: 'Map A',
  version: ProjectVersion.v6,
  size: GridSize(width: 2, height: 2),
  layers: <MapLayer>[
    SmartTileLayer(
      id: 'surface',
      name: 'Surface',
      presetId: 'surface',
      usage: SmartTileUsage.forestSurface,
      field: SmartTileField.cell(),
    ),
    BorderLayer(id: 'border', name: 'Border'),
  ],
);

const _mapB = MapData(
  id: 'map-b',
  name: 'Map B',
  version: ProjectVersion.v6,
  size: GridSize(width: 2, height: 2),
  layers: <MapLayer>[
    BorderLayer(id: 'border', name: 'Border'),
  ],
);
