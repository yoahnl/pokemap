import 'dart:typed_data';

import 'package:map_core/map_core_domain.dart';

import 'project_library_editor.dart';
import 'resource_port.dart';

typedef ModelReplacementResource = ({String kind, String id});

typedef ModelUsageMapImpact = ({
  String id,
  String name,
  int redirected,
  int recalculated,
});

sealed class ProjectModelReplacement {
  const ProjectModelReplacement({required this.noChange});

  final bool noChange;
}

final class ProjectModelSourceReplacement extends ProjectModelReplacement {
  const ProjectModelSourceReplacement({
    required this.before,
    required this.after,
    required this.inspectedBytes,
    required this.fileName,
    required super.noChange,
  });

  final ProjectModel3dEntry before;
  final ProjectModel3dEntry after;
  final Uint8List inspectedBytes;
  final String fileName;
}

final class ProjectModelUsageReplacement extends ProjectModelReplacement {
  const ProjectModelUsageReplacement({
    required this.sourceId,
    required this.targetId,
    required this.affectedMapIds,
    required this.maps,
    required this.borders,
    required this.redirected,
    required this.recalculated,
    required super.noChange,
  });

  final String sourceId;
  final String targetId;
  final Set<String> affectedMapIds;
  final List<ModelUsageMapImpact> maps;
  final Map<String, String> borders;
  final int redirected;
  final int recalculated;
}

final class ProjectModelReplacementCommit {
  const ProjectModelReplacementCommit({
    required this.entryId,
    required this.restorationOperationId,
    required this.publication,
    required this.restoration,
    required this.resources,
    required this.sourceModelId,
    this.targetModelId,
    this.affectedMapIds = const {},
    this.restored = false,
  });

  final String entryId;
  final String restorationOperationId;
  final ResourceMutationReceipt publication;
  final ResourceMutationReceipt restoration;
  final Set<ModelReplacementResource> resources;
  final String sourceModelId;
  final String? targetModelId;
  final Set<String> affectedMapIds;
  final bool restored;

  ResourceMutationReceipt get receipt => restored ? restoration : publication;
  Set<String> get relatedModels => {sourceModelId, ?targetModelId};
}

abstract interface class ProjectModelReplacementProvider {
  ProjectModelReplacementPort get modelReplacement;
}

abstract interface class ProjectModelReplacementPort {
  Future<ProjectModelSourceReplacement> prepareSource({
    required String modelId,
    required PickedProjectLibraryFile file,
    required String expectedRevision,
  });

  Future<ProjectModelUsageReplacement> prepareUsages({
    required String modelId,
    required String replacementId,
    required String expectedRevision,
  });

  Future<ProjectModelReplacementCommit> apply(
    ProjectModelReplacement preparation, {
    required String? Function() checkDrafts,
  });

  Future<ProjectModelReplacementCommit> undo(
    ProjectModelReplacementCommit commit, {
    required String? Function() checkDrafts,
  });

  Future<void> reconcile(ProjectModelReplacementCommit commit);

  Future<void> release(ProjectModelReplacement preparation);
}
