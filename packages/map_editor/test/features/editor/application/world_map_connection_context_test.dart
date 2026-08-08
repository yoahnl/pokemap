import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/app/providers/core/repository_providers.dart';
import 'package:map_editor/src/domain/repositories/repositories.dart';
import 'package:map_editor/src/features/editor/application/world_map_connection_context.dart';
import 'package:map_editor/src/features/editor/application/world_map_connection_context_loader.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/world_map_connection_context_provider.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';

void main() {
  group('WorldMapConnectionContextLoader', () {
    test('projects four directions and bounds the first-level context',
        () async {
      final repository = _MapRepository({
        '/project/maps/north.json': _map(
          'north',
          6,
          4,
          connections: const [
            MapConnection(
              direction: MapConnectionDirection.south,
              targetMapId: 'source',
              offset: 0,
            ),
          ],
        ),
        '/project/maps/east.json': _map('east', 5, 6),
        '/project/maps/south.json': _map('south', 7, 3),
        '/project/maps/west.json': _map('west', 4, 7),
      });
      final context = await WorldMapConnectionContextLoader(
        mapRepository: repository,
      ).load(
        workspace: const FileProjectWorkspaceFactory().create('/project'),
        project: _project,
        sourceMap: _source,
      );

      expect(context.neighbors.keys, {
        MapConnectionDirection.north,
        MapConnectionDirection.east,
        MapConnectionDirection.south,
        MapConnectionDirection.west,
      });
      expect(
        context.neighbors[MapConnectionDirection.north]!.tileBounds,
        const Rect.fromLTWH(0, -4, 6, 4),
      );
      expect(
        context.neighbors[MapConnectionDirection.east]!.tileBounds,
        const Rect.fromLTWH(10, 0, 5, 6),
      );
      expect(
        context.neighbors[MapConnectionDirection.south]!.tileBounds,
        const Rect.fromLTWH(0, 8, 7, 3),
      );
      expect(
        context.neighbors[MapConnectionDirection.west]!.tileBounds,
        const Rect.fromLTWH(-4, 0, 4, 7),
      );
      expect(context.contentTileBounds, const Rect.fromLTRB(-4, -4, 15, 11));
      expect(context.issues, isEmpty);
      expect(repository.loadedPaths, hasLength(4));
      expect(
        context.neighbors[MapConnectionDirection.north]!.exactReciprocalPair,
        isTrue,
      );
      expect(
        context.neighbors[MapConnectionDirection.east]!.exactReciprocalPair,
        isFalse,
      );
    });

    test('uses canonical alignment for positive and negative offsets', () {
      const projector = WorldMapConnectionContextProjector();
      final target = _map('target', 5, 4);

      Rect bounds(MapConnectionDirection direction, int offset) => projector
          .projectNeighbor(
            sourceMap: _map('source', 10, 8),
            connection: MapConnection(
              direction: direction,
              targetMapId: 'target',
              offset: offset,
            ),
            entry: const ProjectMapEntry(
              id: 'target',
              name: 'Target',
              relativePath: 'maps/target.json',
            ),
            targetMap: target,
          )
          .tileBounds;

      expect(
        bounds(MapConnectionDirection.east, 3),
        const Rect.fromLTWH(10, 3, 5, 4),
      );
      expect(
        bounds(MapConnectionDirection.east, -3),
        const Rect.fromLTWH(10, -3, 5, 4),
      );
      expect(
        bounds(MapConnectionDirection.north, 3),
        const Rect.fromLTWH(3, -4, 5, 4),
      );
      expect(
        bounds(MapConnectionDirection.north, -3),
        const Rect.fromLTWH(-3, -4, 5, 4),
      );
    });

    test('keeps missing manifest file and invalid JSON errors local', () async {
      final repository = _MapRepository({
        '/project/maps/east.json':
            const MapLoadException('Map file does not exist'),
        '/project/maps/south.json':
            const MapLoadException('Failed to load map: invalid JSON'),
        '/project/maps/west.json': _map('west', 4, 7),
      });
      final project = _project.copyWith(
        maps: _project.maps
            .where((entry) => entry.id != 'north')
            .toList(growable: false),
      );

      final context = await WorldMapConnectionContextLoader(
        mapRepository: repository,
      ).load(
        workspace: const FileProjectWorkspaceFactory().create('/project'),
        project: project,
        sourceMap: _source,
      );

      expect(context.neighbors.keys, {MapConnectionDirection.west});
      expect(context.issues[MapConnectionDirection.north]!.code,
          'target_not_in_manifest');
      expect(context.issues[MapConnectionDirection.east]!.code,
          'target_file_missing');
      expect(context.issues[MapConnectionDirection.south]!.code,
          'target_unreadable');
      expect(repository.loadedPaths, hasLength(3));
    });

    test('does not traverse a reciprocal cycle or read more than four maps',
        () async {
      final repository = _MapRepository({
        '/project/maps/north.json': _map(
          'north',
          6,
          4,
          connections: const [
            MapConnection(
              direction: MapConnectionDirection.south,
              targetMapId: 'source',
              offset: 0,
            ),
            MapConnection(
              direction: MapConnectionDirection.north,
              targetMapId: 'beyond',
              offset: 0,
            ),
          ],
        ),
        '/project/maps/east.json': _map('east', 5, 6),
        '/project/maps/south.json': _map('south', 7, 3),
        '/project/maps/west.json': _map('west', 4, 7),
        '/project/maps/beyond.json': _map('beyond', 20, 20),
      });

      await WorldMapConnectionContextLoader(mapRepository: repository).load(
        workspace: const FileProjectWorkspaceFactory().create('/project'),
        project: _project.copyWith(
          maps: [
            ..._project.maps,
            const ProjectMapEntry(
              id: 'beyond',
              name: 'Beyond',
              relativePath: 'maps/beyond.json',
            ),
          ],
        ),
        sourceMap: _source,
      );

      expect(repository.loadedPaths, hasLength(4));
      expect(
          repository.loadedPaths, isNot(contains('/project/maps/beyond.json')));
    });
  });

  test('Riverpod request and selected direction are shared and stable',
      () async {
    final repository = _MapRepository({
      '/project/maps/north.json': _map('north', 6, 4),
      '/project/maps/east.json': _map('east', 5, 6),
      '/project/maps/south.json': _map('south', 7, 3),
      '/project/maps/west.json': _map('west', 4, 7),
    });
    final container = ProviderContainer(
      overrides: [mapRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    const request = WorldMapConnectionContextRequest(
      projectRootPath: '/project',
      project: _project,
      sourceMap: _source,
    );

    final context = await container.read(
      worldMapConnectionContextProvider(request).future,
    );
    expect(context.neighbors, hasLength(4));
    expect(container.read(worldMapConnectionDirectionProvider),
        MapConnectionDirection.north);
    container.read(worldMapConnectionDirectionProvider.notifier).state =
        MapConnectionDirection.east;
    expect(container.read(worldMapConnectionDirectionProvider),
        MapConnectionDirection.east);
  });
}

class _MapRepository implements MapRepository {
  _MapRepository(this.responses);

  final Map<String, Object> responses;
  final List<String> loadedPaths = [];

  @override
  Future<MapData> loadMap(String path) async {
    loadedPaths.add(path);
    final response = responses[path];
    if (response is MapData) return response;
    if (response is Object) throw response;
    throw const MapLoadException('Map file does not exist');
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
  }) async {}
}

const _project = ProjectManifest(
  name: 'World context',
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
    ProjectMapEntry(
      id: 'south',
      name: 'South',
      relativePath: 'maps/south.json',
    ),
    ProjectMapEntry(
      id: 'west',
      name: 'West',
      relativePath: 'maps/west.json',
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
    MapConnection(
      direction: MapConnectionDirection.south,
      targetMapId: 'south',
      offset: 0,
    ),
    MapConnection(
      direction: MapConnectionDirection.west,
      targetMapId: 'west',
      offset: 0,
    ),
  ],
);

MapData _map(
  String id,
  int width,
  int height, {
  List<MapConnection> connections = const [],
}) {
  return MapData(
    id: id,
    name: id,
    size: GridSize(width: width, height: height),
    connections: connections,
  );
}
