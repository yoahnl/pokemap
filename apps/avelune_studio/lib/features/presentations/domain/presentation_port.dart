import 'package:map_core/map_core_domain.dart';

import '../../resources/domain/resource_port.dart';

abstract interface class PresentationPort {
  Future<PresentationSourceSnapshot> load(String id);
  Future<PresentationDraftProjection> prepare(ProjectManifest project);
  Future<PresentationPublicationReceipt> publish({
    required PresentationCinematicAsset asset,
    required PresentationSourceSnapshot? base,
    String? folderId,
    bool changeFolder = false,
    PresentationSceneLink? link,
    List<PresentationStagedMedia> imports = const [],
    List<Map<String, Object?>> mediaBaselines = const [],
  });
  Future<PresentationPublicationReceipt> createFolder({
    required String id,
    required String name,
    String? parentFolderId,
  });
  Future<PresentationPublicationReceipt> delete(
    PresentationSourceSnapshot base,
  );
  Future<PresentationPublicationReceipt> setArchived(
    PresentationSourceSnapshot base,
    bool archived,
  );
  Future<PresentationStagedMedia> stageMedia({
    required String sourcePath,
    required String label,
    required ProjectMediaKind kind,
  });
  Future<void> releaseMedia(PresentationStagedMedia media);
}

abstract interface class PresentationDraftProjection {
  ProjectManifest get manifest;
  ProjectMediaCatalog get mediaCatalog;
  List<Map<String, Object?>> get mediaBaselines;
  ProjectManifest apply(PresentationCommand command);
  void adopt(ProjectManifest manifest);
  void includeMedia(List<PresentationStagedMedia> imports);
  PresentationCinematicAsset instantiate({
    required String id,
    required String title,
    required String templateId,
    required int durationUs,
  });
}

class PresentationCommand {
  PresentationCommand(this.actionId, Map<String, Object?> parameters)
    : parameters = Map.unmodifiable(parameters);
  final String actionId;
  final Map<String, Object?> parameters;
}

class PresentationSourceSnapshot {
  const PresentationSourceSnapshot({
    required this.asset,
    required this.revision,
    required this.projection,
    this.entry,
    this.mediaBaselines = const [],
  });
  final PresentationCinematicAsset asset;
  final String revision;
  final CinematicLibraryEntry? entry;
  final PresentationDraftProjection projection;
  final List<Map<String, Object?>> mediaBaselines;
}

class PresentationSceneLink {
  const PresentationSceneLink({
    required this.baseScene,
    required this.scene,
    required this.nodeId,
    required this.targetNodeId,
  });
  final SceneAsset baseScene;
  final SceneAsset scene;
  final String nodeId;
  final String targetNodeId;
}

class PresentationStagedMedia {
  const PresentationStagedMedia({
    required this.media,
    required this.parameters,
    required this.previewBytes,
  });
  final ProjectMediaAsset media;
  final Map<String, Object?> parameters;
  final List<int> previewBytes;
}

class PresentationPublicationReceipt {
  const PresentationPublicationReceipt({
    required this.resources,
    this.snapshot,
  });
  final ResourceMutationReceipt resources;
  final PresentationSourceSnapshot? snapshot;
}

class PresentationFailure implements Exception {
  const PresentationFailure(this.message);
  final String message;
  @override
  String toString() => message;
}
