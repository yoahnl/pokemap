import 'dart:async';

import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_visuals.dart';
import 'package:avelune_studio/presentation/features/map_workspace/workspace_resource_diagnostic.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flutter/widgets.dart';
import 'package:map_core/map_core.dart';

const workspaceSession = ProjectSession(
  sessionId: 'test',
  name: 'Exemple de test',
  directoryPath: '/fixture',
);
const workspaceEntries = [
  ProjectMapEntry(id: 'a', name: 'Clairière', relativePath: 'a.json'),
  ProjectMapEntry(id: 'b', name: 'Jardin', relativePath: 'b.json'),
];
const workspaceElement = ProjectElementEntry(
  id: 'tree',
  name: 'Arbre',
  tilesetId: 'atlas',
  categoryId: 'decor',
  frames: [
    TilesetVisualFrame(
      source: TilesetSourceRect(x: 0, y: 0, width: 2, height: 2),
    ),
  ],
);
const workspaceProject = ProjectManifest(
  name: 'Exemple de test',
  maps: workspaceEntries,
  tilesets: [
    ProjectTilesetEntry(
      id: 'atlas',
      name: 'Exemple',
      relativePath: 'atlas.png',
    ),
  ],
  elements: [workspaceElement],
);

MapData workspaceMap(String id) => MapData(
  id: id,
  name: id,
  size: const GridSize(width: 20, height: 16),
  layers: [
    MapLayer.tile(
      id: 'ground',
      name: 'Sol',
      palette: [
        const TileLayerPaletteEntry(tilesetId: 'atlas', localTileId: 0),
      ],
      cells: List.filled(320, 0),
    ),
  ],
);

class WorkspaceMemoryPort implements MapWorkspacePort {
  final saved = <String, MapData>{};
  int reads = 0;
  int writes = 0;
  int catalogs = 0;
  bool failSave = false;
  String? failedMap;
  Completer<void>? saveGate;
  @override
  Future<ProjectManifest> loadProject(ProjectSession session) async {
    catalogs++;
    return workspaceProject;
  }

  @override
  Future<MapWorkspaceDocument> loadMap(
    ProjectSession session,
    ProjectMapEntry entry,
  ) async {
    reads++;
    if (entry.id == failedMap) {
      throw const MapWorkspaceFailure(
        MapWorkspaceProblem.unavailable,
        'Carte indisponible',
      );
    }
    return MapWorkspaceDocument(
      map: saved[entry.id] ?? workspaceMap(entry.id),
      revision: 'r$writes',
      mapId: entry.id,
    );
  }

  @override
  Future<String> saveMap(
    ProjectSession session,
    MapWorkspaceDocument base,
    MapData current,
  ) async {
    await saveGate?.future;
    if (failSave) {
      throw const MapWorkspaceFailure(
        MapWorkspaceProblem.conflict,
        'Conflit détecté',
      );
    }
    saved[base.mapId] = current;
    return 'r${++writes}';
  }
}

class WorkspaceTestVisuals implements MapWorkspaceVisuals {
  bool disposed = false;
  @override
  void addListener(VoidCallback listener) {}
  @override
  void removeListener(VoidCallback listener) {}
  @override
  List<WorkspaceResourceDiagnostic> get diagnostics => [];
  @override
  Set<String> get activeResourceIds => {};
  @override
  void setActiveMap(MapData map) {}
  @override
  void setBrush(ProjectElementEntry? element, TileLayerPaletteEntry? tile) {}
  @override
  Future<void> retryResources(Iterable<String> resourceIds) async {}
  @override
  Widget tileThumbnail(TileLayerPaletteEntry tile, {double size = 48}) =>
      SizedBox.square(dimension: size);
  @override
  Widget canvas(MapData map) => const SizedBox.expand();
  @override
  Widget thumbnail(ProjectElementEntry element, {double size = 48}) =>
      SizedBox(width: size, height: size);
  @override
  List<String> get warnings => [];
  @override
  Future<void> dispose() async {
    disposed = true;
  }
}
