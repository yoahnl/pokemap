import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/app/providers/core/repository_providers.dart';
import 'package:map_editor/src/app/providers/editor/map_use_case_providers.dart';
import 'package:map_editor/src/application/use_cases/map_use_cases.dart';
import 'package:map_editor/src/domain/repositories/repositories.dart';
import 'package:map_editor/src/features/editor/application/world_map_connection_context.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/world_map_workspace_session.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/map_canvas.dart';
import 'package:map_editor/src/ui/shared/pokemap_macos_ui_shim.dart';

void main() {
  testWidgets(
    'renders non-interactive north/east previews below the active map',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: PokeMapTheme.dark(),
          home: SizedBox.expand(
            child: Stack(
              key: const ValueKey<String>(
                'map-connection-context-host-stack',
              ),
              children: [
                MapConnectionContextLayer(
                  context: _context,
                  selectedDirection: MapConnectionDirection.east,
                  zoom: 2,
                  offset: const Offset(100, 120),
                  tileWidth: 16,
                  tileHeight: 16,
                  sourceTileWidth: 16,
                  sourceTileHeight: 16,
                  tilesetImagesById: const <String, ui.Image?>{},
                  tilesPerRowById: const <String, int>{},
                  project: _project,
                ),
                const Positioned.fill(
                  child: ColoredBox(
                    key: ValueKey<String>('active-map-painter'),
                    color: Colors.transparent,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      final hostStack = tester.widget<Stack>(
        find.byKey(
          const ValueKey<String>('map-connection-context-host-stack'),
        ),
      );
      expect(hostStack.children.first, isA<MapConnectionContextLayer>());
      expect(
        (hostStack.children.last as Positioned).child.key,
        const ValueKey<String>('active-map-painter'),
      );

      final northOpacity = tester.widget<Opacity>(
        find.byKey(
          const ValueKey<String>('map-connection-context-opacity-north'),
        ),
      );
      final eastOpacity = tester.widget<Opacity>(
        find.byKey(
          const ValueKey<String>('map-connection-context-opacity-east'),
        ),
      );
      expect(northOpacity.opacity, 0.36);
      expect(eastOpacity.opacity, 0.62);

      for (final direction in ['north', 'east']) {
        final ignorePointer = tester.widget<IgnorePointer>(
          find.byKey(
            ValueKey<String>(
              'map-connection-context-ignore-pointer-$direction',
            ),
          ),
        );
        expect(ignorePointer.ignoring, isTrue);
        expect(
          find.ancestor(
            of: find.byKey(
              ValueKey<String>('map-connection-context-label-$direction'),
            ),
            matching: find.byKey(
              ValueKey<String>('map-connection-context-opacity-$direction'),
            ),
          ),
          findsNothing,
        );
        expect(
          find.ancestor(
            of: find.byKey(
              ValueKey<String>('map-connection-context-painter-$direction'),
            ),
            matching: find.byType(ExcludeSemantics),
          ),
          findsOneWidget,
        );
      }

      final northPaint = tester.widget<CustomPaint>(
        find.byKey(
          const ValueKey<String>('map-connection-context-painter-north'),
        ),
      );
      final eastPaint = tester.widget<CustomPaint>(
        find.byKey(
          const ValueKey<String>('map-connection-context-painter-east'),
        ),
      );
      final northPainter = northPaint.painter! as MapGridPainter;
      final eastPainter = eastPaint.painter! as MapGridPainter;
      expect(northPainter.map.id, 'north');
      expect(northPainter.offset, const Offset(100, -8));
      expect(eastPainter.map.id, 'east');
      expect(eastPainter.offset, const Offset(420, 120));
      for (final painter in [northPainter, eastPainter]) {
        expect(painter.showGrid, isFalse);
        expect(painter.showEntityEditorChrome, isFalse);
        expect(painter.showEditorOverlays, isFalse);
      }
      final northOutline = tester.widget<CustomPaint>(
        find.byKey(
          const ValueKey<String>('map-connection-context-outline-north'),
        ),
      );
      final eastOutline = tester.widget<CustomPaint>(
        find.byKey(
          const ValueKey<String>('map-connection-context-outline-east'),
        ),
      );
      expect(
        (northOutline.painter! as MapConnectionContextOutlinePainter).color,
        PokeMapColorTokens.dark.borderStrong,
      );
      expect(
        (eastOutline.painter! as MapConnectionContextOutlinePainter).color,
        PokeMapColorTokens.dark.mapAccent,
      );

      await tester.tap(
        find.byKey(
          const ValueKey<String>('map-connection-context-painter-east'),
        ),
        warnIfMissed: false,
      );
      await tester.pump();
      expect(
        tester
            .widget<Opacity>(
              find.byKey(
                const ValueKey<String>(
                  'map-connection-context-opacity-east',
                ),
              ),
            )
            .opacity,
        0.62,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('keeps a local error label when a neighbor cannot be loaded',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: MapConnectionContextLayer(
          context: _contextWithIssue,
          selectedDirection: MapConnectionDirection.west,
          zoom: 1,
          offset: Offset.zero,
          tileWidth: 16,
          tileHeight: 16,
          sourceTileWidth: 16,
          sourceTileHeight: 16,
          tilesetImagesById: const <String, ui.Image?>{},
          tilesPerRowById: const <String, int>{},
          project: _project,
        ),
      ),
    );

    expect(
      find.byKey(
        const ValueKey<String>('map-connection-context-issue-west'),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('West'), findsOneWidget);
    expect(find.textContaining('introuvable'), findsOneWidget);
  });

  test('collects active and neighbor tilesets once per resource id', () {
    final resolveCalls = <String>[];
    final paths = collectMapCanvasTilesetPaths(
      maps: const [
        MapData(
          id: 'source',
          name: 'Source',
          size: GridSize(width: 1, height: 1),
          layers: [
            TileLayer(
              id: 'source-ground',
              name: 'Source ground',
              palette: [
                TileLayerPaletteEntry(
                  tilesetId: 'shared',
                  localTileId: 0,
                ),
              ],
              cells: [1],
            ),
          ],
        ),
        MapData(
          id: 'east',
          name: 'East',
          size: GridSize(width: 1, height: 1),
          layers: [
            TileLayer(
              id: 'east-ground',
              name: 'East ground',
              palette: [
                TileLayerPaletteEntry(
                  tilesetId: 'shared',
                  localTileId: 0,
                ),
                TileLayerPaletteEntry(
                  tilesetId: 'east-only',
                  localTileId: 1,
                ),
              ],
              cells: [2],
            ),
          ],
        ),
      ],
      resolveTilesetAbsolutePath: (tilesetId) {
        resolveCalls.add(tilesetId);
        return '/project/tilesets/$tilesetId.png';
      },
      activeBrushTilesetId: null,
      project: null,
      projectRootPath: '/project',
      activeMap: null,
      borderPreview: null,
    );

    expect(paths.keys, {'shared', 'east-only'});
    expect(resolveCalls.where((id) => id == 'shared'), hasLength(1));
    expect(resolveCalls.where((id) => id == 'east-only'), hasLength(1));
  });

  testWidgets(
    'clicking a neighbor saves the active map before opening the target',
    (tester) async {
      final repository = _MapRepository({
        '/project/maps/north.json': _north,
        '/project/maps/east.json': _east,
      });
      final selectedCells = <GridPos?>[];
      final container = await _pumpDirtyConnectionsCanvas(
        tester,
        repository: repository,
        onCellSelected: selectedCells.add,
      );

      expect(find.byType(MapConnectionContextLayer), findsOneWidget);
      expect(
        find.byKey(
          const ValueKey<String>('map-connection-context-painter-east'),
        ),
        findsOneWidget,
      );
      repository.operations.clear();

      await tester.tapAt(_eastNeighborCenter(tester));
      await tester.pumpAndSettle();
      final after = container.read(editorNotifierProvider);

      expect(after.activeMap?.id, 'east');
      expect(repository.operations.first, 'save:/project/maps/source.json');
      expect(repository.operations, contains('load:/project/maps/east.json'));
      expect(selectedCells.whereType<GridPos>(), isEmpty);
    },
  );

  testWidgets('a failed neighbor save keeps the active map open',
      (tester) async {
    final repository = _MapRepository(
      {
        '/project/maps/north.json': _north,
        '/project/maps/east.json': _east,
      },
      saveError: StateError('disk unavailable'),
    );
    final container = await _pumpDirtyConnectionsCanvas(
      tester,
      repository: repository,
    );

    repository.operations.clear();

    await tester.tapAt(_eastNeighborCenter(tester));
    await tester.pumpAndSettle();
    final after = container.read(editorNotifierProvider);

    expect(after.activeMap?.id, 'source');
    expect(repository.operations, ['save:/project/maps/source.json']);
    expect(after.errorMessage, contains('disk unavailable'));
  });

  testWidgets('a late neighbor load cannot replace the current map context',
      (tester) async {
    final oldTarget = Completer<MapData>();
    final newTarget = Completer<MapData>();
    final repository = _DeferredMapRepository({
      '/project/maps/old-target.json': oldTarget,
      '/project/maps/new-target.json': newTarget,
    });
    final container = ProviderContainer(
      overrides: [mapRepositoryProvider.overrideWithValue(repository)],
    );
    final subscription = container.listen<EditorState>(
      editorNotifierProvider,
      (_, __) {},
      fireImmediately: true,
    );
    addTearDown(() {
      subscription.close();
      container.dispose();
    });
    final notifier = container.read(editorNotifierProvider.notifier);
    notifier.state = const EditorState(
      projectRootPath: '/project',
      project: _switchProject,
      activeMap: _oldSource,
      savedMapSnapshot: _oldSource,
    );
    final activation = container
        .read(worldMapWorkspaceSessionProvider.notifier)
        .activateConnections(notifier);
    expect(activation.accepted, isTrue);
    await tester.binding.setSurfaceSize(const Size(900, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MacosTheme(
          data: MacosThemeData.light(),
          child: MaterialApp(
            theme: PokeMapTheme.dark(),
            home: const CupertinoPageScaffold(child: MapCanvas()),
          ),
        ),
      ),
    );
    await tester.pump();

    notifier.state = const EditorState(
      projectRootPath: '/project',
      project: _switchProject,
      activeMap: _newSource,
      savedMapSnapshot: _newSource,
    );
    await tester.pump();
    newTarget.complete(_newTargetMap);
    await tester.pump();
    await tester.pump();

    MapGridPainter currentEastPainter() => tester
        .widget<CustomPaint>(
          find.byKey(
            const ValueKey<String>(
              'map-connection-context-painter-east',
            ),
          ),
        )
        .painter! as MapGridPainter;

    expect(currentEastPainter().map.id, 'new-target');
    oldTarget.complete(_oldTargetMap);
    await tester.pump();
    await tester.pump();
    expect(currentEastPainter().map.id, 'new-target');
  });
}

Future<ProviderContainer> _pumpDirtyConnectionsCanvas(
  WidgetTester tester, {
  required _MapRepository repository,
  ValueChanged<GridPos?>? onCellSelected,
}) async {
  final container = ProviderContainer(
    overrides: [
      mapRepositoryProvider.overrideWithValue(repository),
      saveMapUseCaseProvider.overrideWith(
        (ref) => SaveMapUseCase(repository),
      ),
    ],
  );
  final subscription = container.listen<EditorState>(
    editorNotifierProvider,
    (_, __) {},
    fireImmediately: true,
  );
  addTearDown(() {
    subscription.close();
    container.dispose();
  });
  final notifier = container.read(editorNotifierProvider.notifier);
  notifier.state = EditorState(
    projectRootPath: '/project',
    project: _project,
    activeMap: _source.copyWith(name: 'Source modifiée'),
    activeMapPath: '/project/maps/source.json',
    savedMapSnapshot: _source,
    isDirty: true,
  );
  final activation = container
      .read(worldMapWorkspaceSessionProvider.notifier)
      .activateConnections(notifier);
  expect(activation.accepted, isTrue);
  await tester.binding.setSurfaceSize(const Size(900, 700));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MacosTheme(
        data: MacosThemeData.light(),
        child: MaterialApp(
          theme: PokeMapTheme.dark(),
          home: CupertinoPageScaffold(
            child: MapCanvas(onCellSelected: onCellSelected),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

Offset _eastNeighborCenter(WidgetTester tester) {
  final painter = tester
      .widget<CustomPaint>(
        find.byKey(
          const ValueKey<String>('map-connection-context-painter-east'),
        ),
      )
      .painter! as MapGridPainter;
  return tester.getTopLeft(find.byType(MapCanvas)) +
      painter.offset +
      Offset(
        _east.size.width * painter.tileWidth * painter.zoom / 2,
        _east.size.height * painter.tileHeight * painter.zoom / 2,
      );
}

const _project = ProjectManifest(
  name: 'Canvas connections',
  maps: [
    ProjectMapEntry(
      id: 'source',
      name: 'Source',
      relativePath: 'maps/source.json',
    ),
    ProjectMapEntry(
      id: 'north',
      name: 'North',
      relativePath: 'maps/north.json',
    ),
    ProjectMapEntry(
      id: 'east',
      name: 'East',
      relativePath: 'maps/east.json',
    ),
  ],
  tilesets: [],
);

const _source = MapData(
  id: 'source',
  name: 'Source',
  size: GridSize(width: 10, height: 8),
  connections: [
    MapConnection(
      direction: MapConnectionDirection.north,
      targetMapId: 'north',
      offset: 0,
    ),
    MapConnection(
      direction: MapConnectionDirection.east,
      targetMapId: 'east',
      offset: 0,
    ),
  ],
);

const _north = MapData(
  id: 'north',
  name: 'North',
  size: GridSize(width: 6, height: 4),
);

const _east = MapData(
  id: 'east',
  name: 'East',
  size: GridSize(width: 5, height: 6),
);

final _context = WorldMapConnectionContext(
  sourceMap: _source,
  neighbors: const {
    MapConnectionDirection.north: WorldMapConnectionNeighbor(
      direction: MapConnectionDirection.north,
      connection: MapConnection(
        direction: MapConnectionDirection.north,
        targetMapId: 'north',
        offset: 0,
      ),
      entry: ProjectMapEntry(
        id: 'north',
        name: 'North',
        relativePath: 'maps/north.json',
      ),
      map: _north,
      tileBounds: Rect.fromLTWH(0, -4, 6, 4),
      exactReciprocalPair: true,
    ),
    MapConnectionDirection.east: WorldMapConnectionNeighbor(
      direction: MapConnectionDirection.east,
      connection: MapConnection(
        direction: MapConnectionDirection.east,
        targetMapId: 'east',
        offset: 0,
      ),
      entry: ProjectMapEntry(
        id: 'east',
        name: 'East',
        relativePath: 'maps/east.json',
      ),
      map: _east,
      tileBounds: Rect.fromLTWH(10, 0, 5, 6),
      exactReciprocalPair: false,
    ),
  },
  issues: const {},
);

final _contextWithIssue = WorldMapConnectionContext(
  sourceMap: _source,
  neighbors: const {},
  issues: const {
    MapConnectionDirection.west: WorldMapConnectionContextIssue(
      direction: MapConnectionDirection.west,
      targetMapId: 'missing',
      code: 'target_file_missing',
      message: 'La map West est introuvable.',
    ),
  },
);

class _MapRepository implements MapRepository {
  _MapRepository(this.mapsByPath, {this.saveError});

  final Map<String, MapData> mapsByPath;
  final Object? saveError;
  final List<String> operations = [];

  @override
  Future<MapData> loadMap(String path) async {
    operations.add('load:$path');
    return mapsByPath[path] ??
        (throw const MapLoadException('Map file does not exist'));
  }

  @override
  Future<void> deleteMap(String path) async {}

  @override
  Future<void> renameMap(String oldPath, String newPath) async {}

  @override
  Future<void> saveMap(
    MapData map,
    String path, {
    ProjectManifest? projectDialogueContext,
  }) async {
    operations.add('save:$path');
    if (saveError case final error?) throw error;
    mapsByPath[path] = map;
  }
}

const _switchProject = ProjectManifest(
  name: 'Context switch',
  maps: [
    ProjectMapEntry(
      id: 'old-source',
      name: 'Old source',
      relativePath: 'maps/old-source.json',
    ),
    ProjectMapEntry(
      id: 'old-target',
      name: 'Old target',
      relativePath: 'maps/old-target.json',
    ),
    ProjectMapEntry(
      id: 'new-source',
      name: 'New source',
      relativePath: 'maps/new-source.json',
    ),
    ProjectMapEntry(
      id: 'new-target',
      name: 'New target',
      relativePath: 'maps/new-target.json',
    ),
  ],
  tilesets: [],
);

const _oldSource = MapData(
  id: 'old-source',
  name: 'Old source',
  size: GridSize(width: 8, height: 8),
  connections: [
    MapConnection(
      direction: MapConnectionDirection.east,
      targetMapId: 'old-target',
      offset: 0,
    ),
  ],
);

const _newSource = MapData(
  id: 'new-source',
  name: 'New source',
  size: GridSize(width: 8, height: 8),
  connections: [
    MapConnection(
      direction: MapConnectionDirection.east,
      targetMapId: 'new-target',
      offset: 0,
    ),
  ],
);

const _oldTargetMap = MapData(
  id: 'old-target',
  name: 'Old target',
  size: GridSize(width: 4, height: 4),
);

const _newTargetMap = MapData(
  id: 'new-target',
  name: 'New target',
  size: GridSize(width: 5, height: 5),
);

class _DeferredMapRepository implements MapRepository {
  _DeferredMapRepository(this.mapsByPath);

  final Map<String, Completer<MapData>> mapsByPath;

  @override
  Future<MapData> loadMap(String path) =>
      mapsByPath[path]?.future ??
      Future<MapData>.error(
        const MapLoadException('Map file does not exist'),
      );

  @override
  Future<void> deleteMap(String path) async {}

  @override
  Future<void> renameMap(String oldPath, String newPath) async {}

  @override
  Future<void> saveMap(
    MapData map,
    String path, {
    ProjectManifest? projectDialogueContext,
  }) async {}
}
