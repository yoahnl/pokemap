part of 'studio_map_resources.dart';

Future<StudioMapResources> _loadStudioMapResources(
  ProjectSession session,
  ProjectManifest manifest, {
  required int maximumBytes,
  required StudioImageDecoder decode,
}) async {
  final result = StudioMapResources._(session.directoryPath, manifest);
  try {
    result.paths.addAll(
      await resolveStudioResourcePaths(
        session.directoryPath,
        manifest,
        result._index.supported,
      ),
    );
  } on Object catch (error) {
    result._failed(
      'catalogue',
      StudioResourceFailure(
        WorkspaceResourceCause.readFailure,
        error.toString(),
      ),
    );
  }
  result.store = StudioImageStore(
    projectRoot: result.projectRoot,
    maximumBytes: maximumBytes,
    paths: result.paths,
    colors: result._index.colors,
    decode: decode,
    changed: result._notify,
    failed: result._failed,
  );
  return result;
}

extension StudioMapResourcesCatalog on StudioMapResources {
  Future<void> _updateModelSources(
    ProjectManifest updated,
    Map<String, ProjectModel3dEntry> definitions,
    Map<String, String> revisions,
  ) async {
    if (_disposed) return;
    manifest = updated;
    modelSourceUpdates.publish(revisions: revisions, definitions: definitions);
    catalogVersion++;
    _notify();
  }

  Future<void> _updateCatalog(
    ProjectManifest updated, {
    required Set<String> changedRelativePaths,
  }) async {
    if (_disposed) return;
    final next = StudioResourceIndex(updated);
    final resolved = await resolveStudioResourcePaths(
      projectRoot,
      updated,
      next.supported,
    );
    Set<String> invalidResourceIds() => changedStudioResourceIds(
      root: projectRoot,
      before: paths,
      after: resolved,
      previousColors: _index.colors,
      nextColors: next.colors,
      changedRelativePaths: changedRelativePaths,
    );
    var invalid = invalidResourceIds();
    if (invalid.isNotEmpty) {
      await store.settled;
      invalid = invalidResourceIds();
    }
    if (_disposed) return;
    final borderChanged =
        manifest.borderCatalog != updated.borderCatalog ||
        manifest.settings != updated.settings ||
        updated.borderCatalog.visualSnapshots.any(
          (snapshot) => snapshot.frames.any(
            (frame) => changedRelativePaths.contains(frame.relativeAssetPath),
          ),
        );
    manifest = updated;
    _index = next;
    paths
      ..clear()
      ..addAll(resolved);
    store.colors
      ..clear()
      ..addAll(next.colors);
    store.invalidate(invalid);
    catalogVersion++;
    if (_activeMap != null) {
      if (borderChanged) {
        borderPreview.invalidate(updated, _activeMap!);
      }
      setActiveMap(_activeMap!);
    }
    _refreshBrushAfterCatalog(updated);
    _notify();
  }
}
