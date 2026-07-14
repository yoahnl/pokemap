import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../editor/state/editor_notifier.dart';
import '../../editor/state/editor_selectors.dart';
import '../application/border_project_element_asset_service.dart';
import '../application/border_publication_candidate_builder.dart';
import '../application/border_publication_transaction.dart';
import '../application/border_studio_draft.dart';
import '../application/border_studio_draft_controller.dart';
import '../application/border_studio_publication_coordinator.dart';
import '../infrastructure/filesystem/file_border_asset_snapshot_store.dart';
import '../infrastructure/filesystem/file_border_publication_manifest_port.dart';

/// Project-scoped Border authoring state.
///
/// The provider watches the manifest plus its stable project-root identity,
/// never active-map state. Border Studio therefore works without an open map.
final _borderStudioProjectSourceProvider =
    Provider<({ProjectManifest? manifest, String? projectRootPath})>((ref) {
  return (
    manifest: ref.watch(editorProjectManifestProvider),
    projectRootPath: ref.watch(editorProjectRootPathProvider),
  );
});

final borderStudioDraftControllerProvider =
    StateNotifierProvider<BorderStudioDraftController, BorderStudioDraftState>(
        (ref) {
  final controller = BorderStudioDraftController();
  ref.listen(
    _borderStudioProjectSourceProvider,
    (_, source) => controller.synchronizeFromManifest(
      source.manifest,
      projectIdentity: source.projectRootPath,
    ),
    fireImmediately: true,
  );
  return controller;
});

/// Focused seam between the filesystem publication transaction and the
/// existing editor session. Tests can replace it without constructing the
/// complete editor notifier graph.
final borderPublicationApplyInMemoryManifestProvider =
    Provider<void Function(ProjectManifest)>((ref) {
  final capturedProjectRootPath = ref.watch(editorProjectRootPathProvider);
  final capturedManifest = ref.watch(editorProjectManifestProvider);
  final capturedDraftState = ref.watch(borderStudioDraftControllerProvider);
  return (manifest) {
    final activeProjectRootPath = ref.read(editorProjectRootPathProvider);
    if (capturedProjectRootPath == null ||
        activeProjectRootPath != capturedProjectRootPath ||
        capturedManifest == null ||
        ref.read(editorProjectManifestProvider) != capturedManifest ||
        !identical(
          ref.read(borderStudioDraftControllerProvider),
          capturedDraftState,
        )) {
      throw StateError(
        'Border publication cannot refresh a stale editor session',
      );
    }
    ref.read(editorNotifierProvider.notifier).applyInMemoryProjectManifest(
          manifest,
          statusMessage: 'Blueprint de bordure publié.',
        );
  };
});

/// Project-scoped, crash-safe publication transaction.
///
/// It deliberately depends only on the project root and remains unavailable
/// when no project is open; an active map is never required by Border Studio.
final borderPublicationTransactionProvider =
    Provider<BorderPublicationTransaction?>((ref) {
  final projectRootPath = ref.watch(editorProjectRootPathProvider);
  if (projectRootPath == null || projectRootPath.trim().isEmpty) {
    return null;
  }
  final applyInMemory = ref.watch(
    borderPublicationApplyInMemoryManifestProvider,
  );
  return BorderPublicationTransaction(
    snapshotStore: FileBorderAssetSnapshotStore(
      projectRootPath: projectRootPath,
    ),
    manifestPort: FileBorderPublicationManifestPort(
      manifestPath: p.join(projectRootPath, 'project.json'),
      applyInMemoryManifest: applyInMemory,
    ),
    candidateValidator: const CoreBorderPublicationCandidateValidator(
      enabledTemplates: <BorderBlueprintTemplate>{
        BorderBlueprintTemplate.organicEdge,
      },
    ),
  );
});

/// Project-scoped BORD-03 organic publication orchestration.
///
/// Surface snapshot preparations remain explicit inputs to [prepare]; this
/// provider wires only the current-source primitive reader, pure candidate
/// builder, real canonical gallery, and crash-safe transaction.
final borderStudioPublicationCoordinatorProvider =
    Provider<BorderStudioPublicationCoordinator?>((ref) {
  final projectRootPath = ref.watch(editorProjectRootPathProvider);
  final transaction = ref.watch(borderPublicationTransactionProvider);
  if (projectRootPath == null ||
      projectRootPath.trim().isEmpty ||
      transaction == null) {
    return null;
  }
  const assetService = BorderProjectElementAssetService();
  const candidateBuilder = BorderPublicationCandidateBuilder();
  return BorderStudioPublicationCoordinator(
    prepareProjectElementAsset: assetService.prepare,
    buildCandidate: candidateBuilder.build,
    resolveCanonicalGallery: ({
      required blueprintId,
      required blueprintRevision,
      required visualSnapshots,
      required tileSizePx,
      required resolverVersion,
    }) =>
        BorderStudioCanonicalGalleryResolution.fromCore(
      resolveOrganicEdgeCanonicalGallery(
        blueprintId: blueprintId,
        blueprintRevision: blueprintRevision,
        visualSnapshots: visualSnapshots,
        tileSizePx: tileSizePx,
        resolverVersion: resolverVersion,
      ),
    ),
    publishRequest: transaction.publish,
  );
});
