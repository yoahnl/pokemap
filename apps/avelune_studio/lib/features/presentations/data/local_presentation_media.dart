part of 'local_presentation_adapter.dart';

extension LocalPresentationMedia on LocalPresentationAdapter {
  Future<PresentationStagedMedia> _stageMedia({
    required String sourcePath,
    required String label,
    required ProjectMediaKind kind,
  }) async {
    final connection = await LocalPresentationConnection.open(
      session,
      artifacts,
      faultInjector,
    );
    String? handle;
    try {
      await artifacts.authorizeSourceFile(sourcePath);
      final staged = await connection.api.stageArtifactFile(
        sourcePath: sourcePath,
      );
      handle = staged.reference.handle;
      final id = _identity();
      final fields = <String, Object?>{
        'artifactHandle': handle,
        'mediaId': id,
        'assetId': 'asset_$id',
        'label': label,
        'kind': kind.id,
        'logicalPath':
            'assets/presentation/$id${path.extension(sourcePath).toLowerCase()}',
      };
      final snapshot = await connection.read();
      final draft =
          await MapMutationDispatcher.canonical(artifactStore: artifacts).build(
            AuthoringPlanningContext(
              snapshot: snapshot,
              request: AuthoringRequest(
                requestId: id,
                actionId: 'presentationMedia.import',
                actionVersion: 1,
                workspaceHandle: connection.opened.workspaceHandle.value,
                expectedRevision: snapshot.revision,
                idempotencyKey: id,
                parameters: fields,
              ),
              planId: id,
              seed: 0,
            ),
          );
      final catalogBytes = draft.changeSet.changes
          .singleWhere((c) => c.storageKey == projectMediaCatalogStorageKey)
          .afterBytes!;
      final media = decodeProjectMediaCatalogBytes(catalogBytes).find(id)!;
      return PresentationStagedMedia(
        media: media,
        parameters: Map.unmodifiable(fields),
        previewBytes: List.unmodifiable(await artifacts.read(handle)),
      );
    } catch (failure) {
      if (handle != null) await artifacts.release(handle);
      throw PresentationFailure('Import impossible : $failure');
    } finally {
      await connection.close();
    }
  }

  Future<void> _releaseMedia(PresentationStagedMedia media) async {
    await artifacts.release(media.parameters['artifactHandle'] as String);
  }
}
