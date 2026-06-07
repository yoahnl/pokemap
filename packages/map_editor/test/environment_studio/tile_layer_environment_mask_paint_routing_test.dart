import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/ui/shared/pokemap_macos_ui_shim.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor/state/environment_mask_brush_size_provider.dart';
import 'package:map_editor/src/features/editor/tools/editor_tool.dart';
import 'package:map_editor/src/ui/canvas/map_canvas.dart';

void main() {
  testWidgets('tap canvas peint le masque attaché quand le TileLayer est actif',
      (tester) async {
    final area = _area();
    final map = MapData(
      id: 'route_1',
      name: 'Route 1',
      size: const GridSize(width: 4, height: 4),
      layers: <MapLayer>[
        const TileLayer(
          id: 'tiles',
          name: 'Sol',
          tiles: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        ),
        MapLayer.environment(
          id: 'env',
          name: 'Environment',
          content: EnvironmentLayerContent(
            targetTileLayerId: 'tiles',
            areas: [area],
          ),
        ),
      ],
    );
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = EditorState(
      projectRootPath: '/tmp/map_editor_env34',
      project: _manifest(),
      activeMap: map,
      activeLayerId: 'tiles',
      selectedEnvironmentAreaId: area.id,
      environmentMaskEditMode: EnvironmentMaskEditMode.paint,
    );

    await tester.binding.setSurfaceSize(const Size(900, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MacosTheme(
          data: MacosThemeData.light(),
          child: const MaterialApp(
            home: CupertinoPageScaffold(
              child: Center(
                child: SizedBox(
                  width: 900,
                  height: 700,
                  child: MapCanvas(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final mapBox = tester.getRect(find.byType(MapCanvas));
    await tester.tapAt(mapBox.topLeft + const Offset(48, 48));
    await tester.pump();

    final state = container.read(editorNotifierProvider);
    final envLayer =
        state.activeMap!.layers.whereType<EnvironmentLayer>().single;
    final painted = envLayer.content.areas.single;
    expect(state.activeLayerId, 'tiles');
    expect(envLayer.content.targetTileLayerId, 'tiles');
    expect(painted.mask.isActiveAt(1, 1), isTrue);
    expect(painted.mask.activeCellCount, 1);
    expect(state.activeMap!.placedElements, isEmpty);
  });

  testWidgets('tap canvas peint un carré 3x3 avec brush size 3',
      (tester) async {
    final area = _area();
    final map = MapData(
      id: 'route_1',
      name: 'Route 1',
      size: const GridSize(width: 4, height: 4),
      layers: <MapLayer>[
        const TileLayer(
          id: 'tiles',
          name: 'Sol',
          tiles: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        ),
        MapLayer.environment(
          id: 'env',
          name: 'Environment',
          content: EnvironmentLayerContent(
            targetTileLayerId: 'tiles',
            areas: [area],
          ),
        ),
      ],
    );
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(environmentMaskBrushSizeProvider.notifier).state = 3;
    container.read(editorNotifierProvider.notifier).state = EditorState(
      projectRootPath: '/tmp/map_editor_env35',
      project: _manifest(),
      activeMap: map,
      activeLayerId: 'tiles',
      selectedEnvironmentAreaId: area.id,
      environmentMaskEditMode: EnvironmentMaskEditMode.paint,
    );

    await tester.binding.setSurfaceSize(const Size(900, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MacosTheme(
          data: MacosThemeData.light(),
          child: const MaterialApp(
            home: CupertinoPageScaffold(
              child: Center(
                child: SizedBox(
                  width: 900,
                  height: 700,
                  child: MapCanvas(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final mapBox = tester.getRect(find.byType(MapCanvas));
    await tester.tapAt(mapBox.topLeft + const Offset(48, 48));
    await tester.pump();

    final state = container.read(editorNotifierProvider);
    final envLayer =
        state.activeMap!.layers.whereType<EnvironmentLayer>().single;
    final painted = envLayer.content.areas.single;
    expect(state.activeLayerId, 'tiles');
    expect(painted.mask.activeCellCount, 9);
    expect(painted.mask.isActiveAt(0, 0), isTrue);
    expect(painted.mask.isActiveAt(1, 1), isTrue);
    expect(painted.mask.isActiveAt(2, 2), isTrue);
    expect(painted.mask.isActiveAt(3, 3), isFalse);
    expect(state.activeMap!.placedElements, isEmpty);
  });

  testWidgets('tap canvas efface un carré 3x3 avec brush size 3',
      (tester) async {
    final area = _areaWithActiveMask();
    final map = MapData(
      id: 'route_1',
      name: 'Route 1',
      size: const GridSize(width: 4, height: 4),
      layers: <MapLayer>[
        const TileLayer(
          id: 'tiles',
          name: 'Sol',
          tiles: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        ),
        MapLayer.environment(
          id: 'env',
          name: 'Environment',
          content: EnvironmentLayerContent(
            targetTileLayerId: 'tiles',
            areas: [area],
          ),
        ),
      ],
    );
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(environmentMaskBrushSizeProvider.notifier).state = 3;
    container.read(editorNotifierProvider.notifier).state = EditorState(
      projectRootPath: '/tmp/map_editor_env36',
      project: _manifest(),
      activeMap: map,
      activeLayerId: 'tiles',
      selectedEnvironmentAreaId: area.id,
      environmentMaskEditMode: EnvironmentMaskEditMode.erase,
    );

    await tester.binding.setSurfaceSize(const Size(900, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MacosTheme(
          data: MacosThemeData.light(),
          child: const MaterialApp(
            home: CupertinoPageScaffold(
              child: Center(
                child: SizedBox(
                  width: 900,
                  height: 700,
                  child: MapCanvas(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final mapBox = tester.getRect(find.byType(MapCanvas));
    await tester.tapAt(mapBox.topLeft + const Offset(48, 48));
    await tester.pump();

    final state = container.read(editorNotifierProvider);
    final envLayer =
        state.activeMap!.layers.whereType<EnvironmentLayer>().single;
    final erased = envLayer.content.areas.single;
    expect(state.activeLayerId, 'tiles');
    expect(state.selectedEnvironmentAreaId, area.id);
    expect(erased.mask.activeCellCount, 7);
    expect(erased.mask.isActiveAt(0, 0), isFalse);
    expect(erased.mask.isActiveAt(1, 1), isFalse);
    expect(erased.mask.isActiveAt(2, 2), isFalse);
    expect(erased.mask.isActiveAt(3, 3), isTrue);
    expect(state.activeMap!.placedElements, isEmpty);
  });

  testWidgets('tap canvas erase taille 1 efface exactement la cellule centrale',
      (tester) async {
    final area = _areaWithActiveMask();
    final map = MapData(
      id: 'route_1',
      name: 'Route 1',
      size: const GridSize(width: 4, height: 4),
      layers: <MapLayer>[
        const TileLayer(
          id: 'tiles',
          name: 'Sol',
          tiles: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        ),
        MapLayer.environment(
          id: 'env',
          name: 'Environment',
          content: EnvironmentLayerContent(
            targetTileLayerId: 'tiles',
            areas: [area],
          ),
        ),
      ],
    );
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = EditorState(
      projectRootPath: '/tmp/map_editor_env36',
      project: _manifest(),
      activeMap: map,
      activeLayerId: 'tiles',
      selectedEnvironmentAreaId: area.id,
      environmentMaskEditMode: EnvironmentMaskEditMode.erase,
    );

    await tester.binding.setSurfaceSize(const Size(900, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MacosTheme(
          data: MacosThemeData.light(),
          child: const MaterialApp(
            home: CupertinoPageScaffold(
              child: Center(
                child: SizedBox(
                  width: 900,
                  height: 700,
                  child: MapCanvas(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final mapBox = tester.getRect(find.byType(MapCanvas));
    await tester.tapAt(mapBox.topLeft + const Offset(48, 48));
    await tester.pump();

    final state = container.read(editorNotifierProvider);
    final envLayer =
        state.activeMap!.layers.whereType<EnvironmentLayer>().single;
    final erased = envLayer.content.areas.single;
    expect(state.activeLayerId, 'tiles');
    expect(state.selectedEnvironmentAreaId, area.id);
    expect(erased.mask.activeCellCount, 15);
    expect(erased.mask.isActiveAt(1, 1), isFalse);
    expect(erased.mask.isActiveAt(1, 0), isTrue);
    expect(erased.mask.isActiveAt(0, 1), isTrue);
    expect(state.activeMap!.placedElements, isEmpty);
  });
}

EnvironmentArea _area() {
  return EnvironmentArea(
    id: 'area_forest',
    name: 'Forêt',
    presetId: 'forest',
    mask: EnvironmentAreaMask(
      width: 4,
      height: 4,
      cells: List<bool>.filled(16, false),
    ),
    seed: 0,
  );
}

EnvironmentArea _areaWithActiveMask() {
  return EnvironmentArea(
    id: 'area_forest',
    name: 'Forêt',
    presetId: 'forest',
    mask: EnvironmentAreaMask(
      width: 4,
      height: 4,
      cells: List<bool>.filled(16, true),
    ),
    seed: 0,
  );
}

ProjectManifest _manifest() {
  return ProjectManifest(
    name: 'Project',
    maps: const [],
    tilesets: const [],
    elements: const [
      ProjectElementEntry(
        id: 'tree',
        name: 'Tree',
        tilesetId: 'nature',
        categoryId: 'trees',
        frames: [
          TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
        ],
      ),
    ],
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
    environmentPresets: [
      EnvironmentPreset(
        id: 'forest',
        name: 'Forêt',
        templateId: 'forest',
        palette: [
          EnvironmentPaletteItem(elementId: 'tree', weight: 1),
        ],
        defaultParams: EnvironmentGenerationParams.standard(),
        sortOrder: 0,
      ),
    ],
  );
}
