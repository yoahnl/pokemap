import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../editor/state/editor_notifier.dart';
import '../../editor/state/editor_selectors.dart';
import '../application/border_publication_transaction.dart';
import '../application/border_studio_draft.dart';
import '../application/border_studio_draft_controller.dart';
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
  return (manifest) =>
      ref.read(editorNotifierProvider.notifier).applyInMemoryProjectManifest(
            manifest,
            statusMessage: 'Blueprint de bordure publié.',
          );
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
  );
});
