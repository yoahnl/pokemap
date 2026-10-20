import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:map_core/map_core.dart';

const scopedMapSession = ProjectSession(
  sessionId: 'scoped',
  name: 'Catalogue',
  directoryPath: '/project',
  storage: ProjectSessionStorage.workingCatalog,
);
const firstScopedMap = ProjectMapEntry(
  id: 'first',
  name: 'Première',
  relativePath: 'first.json',
);
const secondScopedMap = ProjectMapEntry(
  id: 'second',
  name: 'Seconde',
  relativePath: 'second.json',
);
const scopedMapMetadata = ProjectManifest(
  name: 'Catalogue',
  maps: [firstScopedMap, secondScopedMap],
  tilesets: [],
);
const scopedMapTilesets = [
  ProjectTilesetEntry(id: 'first', name: 'Première', relativePath: 'first.png'),
  ProjectTilesetEntry(
    id: 'second',
    name: 'Seconde',
    relativePath: 'second.png',
  ),
];

class ScopedTestMapPort implements MapWorkspacePort, MapWorkspaceScopedPort {
  ScopedTestMapPort({this.metadata = scopedMapMetadata});

  final ProjectManifest metadata;
  int fullReads = 0;
  final selections = <String>[];

  @override
  Future<ProjectManifest> loadProject(ProjectSession session) async {
    throw StateError(
      'The scoped controller must not read a complete project implicitly.',
    );
  }

  @override
  Future<MapWorkspaceCatalog> loadCatalog(ProjectSession session) async =>
      MapWorkspaceCatalog(metadata: metadata, revision: 'catalog-1');

  @override
  Future<MapWorkspaceSelection> loadMapSelection(
    ProjectSession session,
    ProjectMapEntry entry,
  ) async {
    selections.add(entry.id);
    return MapWorkspaceSelection(
      document: await loadMap(session, entry),
      definitions: metadata.copyWith(
        tilesets: scopedMapTilesets.where((e) => e.id == entry.id).toList(),
      ),
      catalogRevision: 'catalog-1',
      snapshotRevision: 'map-state-1',
    );
  }

  @override
  Future<ProjectManifest> materializeProject(ProjectSession session) async {
    fullReads++;
    return metadata.copyWith(tilesets: scopedMapTilesets);
  }

  @override
  Future<MapWorkspaceDocument> loadMap(
    ProjectSession session,
    ProjectMapEntry entry,
  ) async => MapWorkspaceDocument(
    map: MapData(
      id: entry.id,
      name: entry.name,
      size: const GridSize(width: 2, height: 2),
      visualStack: MapVisualStackConfig.canonicalV1,
      layers: [TileLayer(id: 'ground', name: 'Sol', cells: List.filled(4, 0))],
    ),
    revision: 'map-1',
    mapId: entry.id,
  );

  @override
  Future<String> saveMap(
    ProjectSession session,
    MapWorkspaceDocument base,
    MapData current,
  ) async => 'map-2';
}
