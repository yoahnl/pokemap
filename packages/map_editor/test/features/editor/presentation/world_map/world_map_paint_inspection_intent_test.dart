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
        mapId: 'map-a',
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
}

const _project = ProjectManifest(
  name: 'Paint inspection intent',
  maps: <ProjectMapEntry>[],
  tilesets: <ProjectTilesetEntry>[],
  surfaceCatalog: ProjectSurfaceCatalog.empty(),
);

const _mapA = MapData(
  id: 'map-a',
  name: 'Map A',
  size: GridSize(width: 2, height: 2),
  layers: <MapLayer>[
    SurfaceLayer(id: 'surface', name: 'Surface'),
    BorderLayer(id: 'border', name: 'Border'),
  ],
);

const _mapB = MapData(
  id: 'map-b',
  name: 'Map B',
  size: GridSize(width: 2, height: 2),
  layers: <MapLayer>[
    BorderLayer(id: 'border', name: 'Border'),
  ],
);
