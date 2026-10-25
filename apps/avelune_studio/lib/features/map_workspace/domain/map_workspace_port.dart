import 'package:map_core/map_core_domain.dart';

import 'map_workspace_workshop.dart';
export 'map_workspace_workshop.dart';

import 'package:avelune_studio/features/project_session/domain/project_session.dart';

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

enum MapWorkspaceProjectScope { catalogMetadata, mapSelection, completeProject }

final class MapWorkspaceCatalog {
  const MapWorkspaceCatalog({required this.metadata, required this.revision});

  final ProjectManifest metadata;
  final String revision;
}

final class MapWorkspaceSelection {
  const MapWorkspaceSelection({
    required this.document,
    required this.definitions,
    required this.catalogRevision,
    required this.snapshotRevision,
  });

  final MapWorkspaceDocument document;
  final ProjectManifest definitions;
  final String catalogRevision;
  final String snapshotRevision;
}

abstract interface class MapWorkspaceScopedPort implements MapWorkspacePort {
  Future<MapWorkspaceCatalog> loadCatalog(ProjectSession session);
  Future<MapWorkspaceSelection> loadMapSelection(
    ProjectSession session,
    ProjectMapEntry entry,
  );
  Future<ProjectManifest> materializeProject(ProjectSession session);
}

abstract interface class MapWorkspaceWorkshopPort
    implements MapWorkspaceScopedPort {
  Future<MapWorkspaceCatalog> loadWorkshop(
    ProjectSession session,
    MapWorkspaceWorkshop workshop,
  );
}

abstract interface class MapWorkspaceResourceKindPort {
  Future<MapWorkspaceCatalog> loadResourceKind(
    ProjectSession session,
    String canonicalKind,
  );
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
