import 'package:map_authoring/map_authoring_api.dart' show ContentArtifactRef;
import 'package:map_core/map_core_domain.dart';

import '../application/project_resource_library.dart';
import 'resource_mutation_preparation.dart';
import 'resource_port.dart';

typedef LibraryImageSize = ({int width, int height});

final class PickedProjectLibraryFile {
  const PickedProjectLibraryFile({
    required this.path,
    required this.name,
    required this.artifact,
    this.imageSize,
    this.modelInspection,
  });

  final String path;
  final String name;
  final ContentArtifactRef artifact;
  final LibraryImageSize? imageSize;
  final Model3dInspection? modelInspection;
}

typedef ProjectLibraryEdit = ({
  ProjectLibraryItem item,
  ResourceMutationReceipt receipt,
});

typedef ProjectLibraryManagement = ({
  ProjectLibraryEditor editor,
  Future<PickedProjectLibraryFile?> Function() pickFile,
});

final class ProjectLibraryNeedsPreparation implements Exception {
  const ProjectLibraryNeedsPreparation();
}

abstract interface class ProjectLibraryEditor {
  Future<ProjectLibraryEdit> importResource(
    PickedProjectLibraryFile file, {
    required String name,
    required LibraryImageSize? tileSize,
    required String expectedRevision,
  });

  Future<ProjectLibraryEdit> renameResource(
    ProjectLibraryItem item, {
    required String name,
    required String expectedRevision,
  });

  Future<ProjectLibraryEdit> classifyResource(
    ProjectLibraryItem item, {
    required String? familyId,
    required ResourceLibraryRole role,
    required String expectedRevision,
  });

  Future<ProjectLibraryEdit> modifyLibraryResource(
    ProjectLibraryItem item, {
    required String? description,
    required ResourcePlacementContext? placementContext,
    required String expectedRevision,
  });

  Future<ProjectLibraryEdit> duplicateLibraryResource(
    ProjectLibraryItem item, {
    required String name,
    required String expectedRevision,
  });

  Future<ResourceMutationPreparation> prepareLibraryDeletion(
    ProjectLibraryItem item, {
    required String expectedRevision,
  });

  bool libraryDraftUses(
    ProjectLibraryItem item,
    Iterable<Map<String, Object?>> drafts,
  );

  Future<ResourceMutationReceipt> applyPrepared(
    ResourceMutationPreparation preparation, {
    bool confirmDestructive = false,
    String? Function()? validateBeforeApply,
  });

  Future<void> releasePreparation(ResourceMutationPreparation preparation);

  Future<ResourceMutationReceipt> prepareResourceIndexes({
    required String expectedSnapshotRevision,
  });
}
