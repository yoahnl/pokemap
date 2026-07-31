import 'package:map_core/map_core.dart';

import '../models/map_document_persistence.dart';

abstract class ProjectRepository {
  Future<void> saveProject(ProjectManifest project, String path);

  Future<ProjectManifest> loadProject(String path);
}

abstract class MapRepository {
  Future<void> saveMap(
    MapData map,
    String path, {
    ProjectManifest? projectDialogueContext,
  });

  Future<MapData> loadMap(String path);

  Future<void> deleteMap(String path);

  Future<void> renameMap(String oldPath, String newPath);
}

/// Optional capability for a repository whose reads are backed by a cached
/// project-wide snapshot.
///
/// Ordinary project/map navigation deliberately shares that snapshot. An
/// explicit user or recovery reload can request a fresh disk projection before
/// loading so external edits are not hidden by the cache.
abstract interface class RefreshableMapReadRepository {
  Future<void> refreshMapReadSnapshot(String path);
}

/// Optional raw durable-read capability for transaction/recovery protocols.
///
/// These protocols must inspect a just-written file even while `project.json`
/// still describes the previous multi-file transaction state.
abstract interface class DurableMapDocumentRepository {
  Future<RevisionedMapDocument> loadDurableMapDocument(String path);
}

/// Optional strict capability used by every product map-writing path.
///
/// Keeping it separate preserves source compatibility for legacy in-memory
/// fakes while the real filesystem repository fails closed on stale bytes.
abstract interface class RevisionedMapRepository implements MapRepository {
  Future<RevisionedMapDocument> loadMapDocument(String path);

  Future<RevisionedMapDocument> saveMapDocument(
    MapData map,
    String path, {
    required MapDocumentWritePrecondition precondition,
    ProjectManifest? projectDialogueContext,
  });

  Future<void> deleteMapDocument(
    String path, {
    required String expectedRevision,
  });

  Future<MapDocumentRecoveryResult> recoverMapDocument(String path);
}

abstract class TilesetRepository {
  Future<void> saveTileset(TilesetConfig tileset, String path);

  Future<TilesetConfig> loadTileset(String path);
}
