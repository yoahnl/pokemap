part of 'local_resource_adapter.dart';

extension _LocalResourceMutation on LocalResourceAdapter {
  Future<ResourceMutationReceipt> _run(
    String actionId,
    Map<String, Object?> Function(ProjectManifest manifest) parameters, {
    String? sourcePath,
    String? createdTilesetId,
    List<BorderResourcePrimitive>? borderSources,
    String? expectedBeforeRevision,
    String? expectedSnapshotRevision,
    bool confirmDestructive = false,
    String? Function()? validateBeforeApply,
  }) => mapAdapter.withResourceMutation(() async {
    try {
      if (_disposed || !LocalResourceAdapter._actions.contains(actionId)) {
        throw const ResourceFailure(
          'Cette opération de ressource est indisponible.',
        );
      }
      final before = await mapAdapter.resourceBaseline(session);
      _requireAvailable();
      if (expectedBeforeRevision != null &&
          before.revision != expectedBeforeRevision) {
        throw const ResourceFailure(
          'Le projet a changé pendant la préparation. Reprenez la bordure.',
        );
      }
      final fields = Map<String, Object?>.from(parameters(before.manifest));
      if (expectedSnapshotRevision == null &&
          resourceMutationIsUnchanged(before.manifest, actionId, fields)) {
        await mapAdapter.resourceBaseline(session);
        _requireAvailable();
        return ResourceMutationReceipt(
          before: before.manifest,
          manifest: before.manifest,
          beforeRevision: before.revision,
          revision: before.revision,
          changedPaths: const [],
        );
      }
      const reader = LocalProjectFileReader();
      final policy = await WorkspacePolicy.create(
        allowedRootPaths: [session.directoryPath],
        fileReader: reader,
      );
      final handles = WorkspaceHandleStore();
      final opened = await ProjectOpenService(
        policy: policy,
        fileReader: reader,
        handles: handles,
      ).openProject(session.directoryPath);
      final snapshots = ProjectSnapshotLoader(handles: handles);
      final artifacts = LocalArtifactStore(
        allowedSourceRoots: [session.directoryPath],
        maximumArtifactBytes: maximumAuthoringArtifactBytesV1,
      );
      final api = LocalMapAuthoringMutationApi(
        policy: policy,
        snapshotLoader: snapshots,
        artifactStore: artifacts,
      );
      String? artifactHandle;
      final stagedHandles = <String>{};
      var attached = false;
      try {
        if (sourcePath != null) {
          await artifacts.authorizeSourceFile(sourcePath);
          final staged = await api.stageArtifactFile(
            sourcePath: sourcePath,
            declaredMediaType: 'image/png',
          );
          artifactHandle = staged.reference.handle;
          stagedHandles.add(artifactHandle);
          fields['artifactHandle'] = artifactHandle;
        }
        if (borderSources != null) {
          final handlesByPath = <String, String>{};
          fields['primitiveSources'] = <Object?>[
            for (final source in borderSources)
              <String, Object?>{
                'primitiveId': source.draft.id,
                'frames': <Object?>[
                  for (final frame in source.frames)
                    <String, Object?>{
                      'artifactHandle': await _stageBorderFrame(
                        api,
                        artifacts,
                        frame,
                        handlesByPath,
                        stagedHandles,
                      ),
                      'sourceProjectRelativePath': frame.relativePath,
                      'sourceRectPx': <String, int>{
                        'x': frame.rect.x,
                        'y': frame.rect.y,
                        'width': frame.rect.width,
                        'height': frame.rect.height,
                      },
                      if (frame.durationMs != null)
                        'durationMs': frame.durationMs,
                      if (frame.transparentColorArgb != null)
                        'transparentColorArgb': frame.transparentColorArgb,
                    },
                ],
              },
          ];
        }
        await api.attachProject(
          projectRootPath: session.directoryPath,
          workspaceHandle: opened.workspaceHandle,
          projectHandle: opened.projectHandle,
        );
        attached = true;
        final snapshot = await snapshots.load(
          opened.projectHandle,
          policy: ProjectSnapshotLoadPolicy.editorReadProjection,
        );
        if (expectedSnapshotRevision != null &&
            snapshot.revision != expectedSnapshotRevision) {
          throw const ResourceFailure(
            'Le projet a changé depuis la préparation. Votre saisie est conservée.',
          );
        }
        if (narrativeEventBytesFingerprint(snapshot.resourceBytes('project')) !=
            before.revision) {
          throw const ResourceFailure(
            'Le projet a changé sur le disque. Rien n’a été écrasé.',
          );
        }
        final operationId = _identity('resource');
        final planned = await api.planMutation(
          opened.projectHandle,
          AuthoringRequest(
            requestId: operationId,
            actionId: actionId,
            actionVersion: 1,
            workspaceHandle: opened.workspaceHandle.value,
            parameters: fields,
            expectedRevision: snapshot.revision,
            idempotencyKey: operationId,
          ),
        );
        final changes = planned.plan.changeSet.changes;
        final mapPaths = before.manifest.maps
            .map((map) => map.relativePath)
            .toSet();
        if (changes.any(
          (change) =>
              change.resource.kind == 'map' ||
              mapPaths.contains(change.storageKey),
        )) {
          throw const ResourceFailure(
            'Cette publication toucherait une carte. Le travail ouvert a été préservé.',
          );
        }
        if (changes.isEmpty) {
          await mapAdapter.resourceBaseline(session);
          _requireAvailable();
          final problem = validateBeforeApply?.call();
          if (problem != null) throw ResourceFailure(problem);
          return ResourceMutationReceipt(
            before: before.manifest,
            manifest: before.manifest,
            beforeRevision: before.revision,
            revision: before.revision,
            changedPaths: const [],
          );
        }
        final receipt = _resourceReceipt(
          before.manifest,
          before.revision,
          planned.plan,
          createdTilesetId,
          operationId,
        );
        _requireAvailable();
        try {
          final confirmation = confirmDestructive
              ? await api.confirmMutation(
                  opened.projectHandle,
                  planId: planned.planId,
                )
              : null;
          await api.applyMutation(
            opened.projectHandle,
            planId: planned.planId,
            operationId: operationId,
            confirmationToken: confirmation?.confirmationToken,
            precondition: () async {
              await beforeTransactionPrecondition?.call();
              _requireAvailable();
              final problem = validateBeforeApply?.call();
              if (problem != null) throw ResourceFailure(problem);
            },
          );
        } on Object catch (failure, stack) {
          late final AuthoringMutationResult recovered;
          try {
            recovered = await api.recoverMutation(
              opened.projectHandle,
              operationId: operationId,
            );
          } on Object {
            Error.throwWithStackTrace(failure, stack);
          }
          if (recovered.receipt.status.name != 'applied' &&
              recovered.receipt.extensions['recoveryOutcome'] != 'resumed') {
            Error.throwWithStackTrace(failure, stack);
          }
        }
        try {
          await beforeReconciliation?.call();
          _requireAvailable();
          await mapAdapter.acceptResourceMutation(
            session,
            receipt,
            allowMapOrganization: actionId == 'map.library.reorganize',
          );
        } on Object catch (failure) {
          throw ResourceFailure(
            'La publication a réussi, mais la relecture a échoué. Ne relancez pas la mutation. $failure',
            partialReceipt: receipt,
          );
        }
        return receipt;
      } finally {
        for (final handle in stagedHandles) {
          await artifacts.release(handle);
        }
        if (attached) await api.detachWorkspace(opened.workspaceHandle);
        handles.closeWorkspace(opened.workspaceHandle);
      }
    } on ResourceFailure {
      rethrow;
    } on Object catch (error) {
      throw _resourceFailure(error);
    }
  });
}
