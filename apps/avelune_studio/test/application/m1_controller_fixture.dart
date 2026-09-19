import 'dart:async';

import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:map_core/map_core.dart';

const m1Session = ProjectSession(
  sessionId: 'test',
  name: 'Test',
  directoryPath: '/test',
);
const m1First = ProjectMapEntry(id: 'a', name: 'A', relativePath: 'a.json');
const m1Second = ProjectMapEntry(id: 'b', name: 'B', relativePath: 'b.json');

MapWorkspaceDocument m1Document(String id) => MapWorkspaceDocument(
  map: MapData(id: id, name: id, size: const GridSize(width: 4, height: 4)),
  revision: 'revision-$id',
  mapId: id,
);

class M1ControlledPort implements MapWorkspacePort {
  int projectLoads = 0;
  final mapLoads = <String, int>{};
  final pendingLoads = <String, Completer<MapWorkspaceDocument>>{};
  final saves =
      <
        ({MapWorkspaceDocument base, MapData current, Completer<String> result})
      >[];
  Completer<ProjectManifest>? pendingProject;
  final project = ProjectManifest(
    name: 'Test',
    maps: const [m1First, m1Second],
    tilesets: [],
  );

  @override
  Future<ProjectManifest> loadProject(ProjectSession session) async {
    projectLoads++;
    return pendingProject?.future ?? project;
  }

  @override
  Future<MapWorkspaceDocument> loadMap(
    ProjectSession session,
    ProjectMapEntry entry,
  ) async {
    mapLoads.update(entry.id, (value) => value + 1, ifAbsent: () => 1);
    return pendingLoads[entry.id]?.future ?? m1Document(entry.id);
  }

  @override
  Future<String> saveMap(
    ProjectSession session,
    MapWorkspaceDocument base,
    MapData current,
  ) {
    final result = Completer<String>();
    saves.add((base: base, current: current, result: result));
    return result.future;
  }
}
