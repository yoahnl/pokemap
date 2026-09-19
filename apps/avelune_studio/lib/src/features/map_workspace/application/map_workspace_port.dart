import 'package:map_core/map_core_domain.dart';

import '../../project_session/application/project_session.dart';

class MapWorkspaceDocument {
  const MapWorkspaceDocument({
    required this.map,
    required this.revision,
    required this.mapId,
  });

  final MapData map;
  final String revision;
  final String mapId;
}

abstract interface class MapWorkspacePort {
  Future<ProjectManifest> loadProject(ProjectSession session);
  Future<MapWorkspaceDocument> loadMap(
    ProjectSession session,
    ProjectMapEntry entry,
  );
  Future<String> saveMap(
    ProjectSession session,
    MapWorkspaceDocument base,
    MapData current,
  );
}

enum MapWorkspaceProblem {
  invalidDocument,
  unavailable,
  unsafePath,
  conflict,
  writeFailed,
}

class MapWorkspaceFailure implements Exception {
  const MapWorkspaceFailure(this.problem, this.message);

  final MapWorkspaceProblem problem;
  final String message;

  @override
  String toString() => message;
}
