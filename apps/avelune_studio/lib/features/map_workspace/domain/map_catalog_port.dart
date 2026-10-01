import 'package:map_core/map_core_domain.dart';

import '../../project_session/domain/project_session.dart';
import 'map_workspace_port.dart';

final class MapCatalogReceipt {
  const MapCatalogReceipt({
    required this.before,
    required this.manifest,
    required this.beforeRevision,
    required this.revision,
    required this.changedPaths,
    this.documents = const {},
    this.createdMapId,
  });

  final ProjectManifest before;
  final ProjectManifest manifest;
  final String beforeRevision;
  final String revision;
  final List<String> changedPaths;
  final Map<String, MapWorkspaceDocument> documents;
  final String? createdMapId;
}

final class MapCatalogResult {
  const MapCatalogResult({
    this.published = false,
    this.integrated = false,
    this.error,
    this.receipt,
  });

  final bool published;
  final bool integrated;
  final String? error;
  final MapCatalogReceipt? receipt;
}

abstract interface class MapCatalogPort {
  Future<MapCatalogReceipt> mutate(
    ProjectSession session,
    String actionId,
    Map<String, Object?> parameters, {
    Map<String, String> expectedMapRevisions = const {},
    bool confirmDestructive = false,
    ProjectManifest? expectedManifest,
  });

  Future<void> reconcile(ProjectSession session, MapCatalogReceipt receipt);
}
