part of 'local_resource_adapter.dart';

extension _LocalResourceMutation on LocalResourceAdapter {
  Future<ResourceMutationReceipt> _run(
    String actionId,
    Map<String, Object?> Function(ProjectManifest manifest) parameters, {
    String? sourcePath,
    String sourceMediaType = 'image/png',
    String? createdTilesetId,
    List<BorderResourcePrimitive>? borderSources,
    String? expectedBeforeRevision,
    String? expectedSnapshotRevision,
    bool confirmDestructive = false,
    String? Function()? validateBeforeApply,
  }) => mapAdapter.withResourceMutation(() async {
    _resourceMutationActive = true;
    final trace = developer.TimelineTask()..start('studio.resource.save');
    void phase(String name) {
      trace.instant(name);
      mutationPhaseObserver?.call(name);
    }
    try {
      if (_disposed || !LocalResourceAdapter._actions.contains(actionId)) {
        throw const ResourceFailure(
          'Cette opération de ressource est indisponible.',
        );
      }
      phase('baseline.start');
      final before = await mapAdapter.resourceBaseline(session);
      phase('baseline.end');
      _requireAvailable();
      if (expectedBeforeRevision != null &&
          before.revision != expectedBeforeRevision) {
        throw const ResourceFailure(
          'Le projet a changé pendant la préparation. Reprenez la bordure.',
        );
      }
      final fields = Map<String, Object?>.from(parameters(before.manifest));
      final scopedModelSource =
          session.storage == ProjectSessionStorage.workingCatalog &&
          {
            'model3d.source.replace',
            'model3d.source.replace_batch',
          }.contains(actionId);
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
      if (session.storage == ProjectSessionStorage.manifest &&
          actionId == 'characterStudio.character.update' &&
          fields.length == 2 &&
          fields.containsKey('characterId') &&
          fields.containsKey('contactShadow') &&
          sourcePath == null &&
          expectedSnapshotRevision == null) {
        return await _setCharacterContactShadow(
          before.manifest,
          before.revision,
          fields,
          validateBeforeApply: validateBeforeApply,
        );
      }
      final context = await _requireMutationContext();
      phase('context.ready');
      final snapshots = context.snapshots;
      final opened = context.opened;
      final artifacts = context.artifacts;
      final api = context.api;
      context.profiles.sink = (profile) => trace.instant(
        'snapshot.loaded',
        arguments: {
          'readUs': profile.initialReadMicroseconds,
          'decodeUs': profile.decodeModelMicroseconds,
          'observeUs': profile.secondObservationMicroseconds,
          'fingerprintUs': profile.fingerprintMicroseconds,
          'projectionUs': profile.projectionMicroseconds,
          'totalUs': profile.totalMicroseconds,
          'resources': profile.resourceCount,
          'bytes': profile.resourceBytes,
          'cacheHit': profile.cacheHit,
        },
      );
      String? artifactHandle;
      final stagedHandles = <String>{};
      AuthoringPlan? ownedPlan;
      try {
        if (sourcePath != null) {
          await artifacts.authorizeSourceFile(sourcePath);
          final staged = await api.stageArtifactFile(
            sourcePath: sourcePath,
            declaredMediaType: sourceMediaType,
          );
          artifactHandle = staged.reference.handle;
          stagedHandles.add(artifactHandle);
          fields['artifactHandle'] = artifactHandle;
          phase('artifact.staged');
        }
        if (borderSources != null &&
            borderSources.any((source) => !source.draft.isSpatial)) {
          final handlesByPath = <String, String>{};
          fields['primitiveSources'] = <Object?>[
            for (final source in borderSources)
              if (!source.draft.isSpatial)
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
        phase('attach.start');
        await context.attach();
        phase('attach.end');
        final snapshot = scopedModelSource
            ? await api.readWorkshopSnapshot(
                opened.projectHandle,
                actionId: actionId,
                parameters: fields,
              )
            : await snapshots.load(
                opened.projectHandle,
                policy: ProjectSnapshotLoadPolicy.editorReadProjection,
              );
        if (expectedSnapshotRevision != null &&
            snapshot.revision != expectedSnapshotRevision) {
          throw const ResourceFailure(
            'Le projet a changé depuis la préparation. Votre saisie est conservée.',
          );
        }
        if ((scopedModelSource
                ? _modelSourceDocumentRevision(snapshot)
                : studioProjectSnapshotRevision(snapshot)) !=
            before.revision) {
          throw const ResourceFailure(
            'Le projet a changé sur le disque. Rien n’a été écrasé.',
          );
        }
        phase('snapshot.end');
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
        ownedPlan = planned.plan;
        phase('plan.end');
        final changes = planned.plan.changeSet.changes;
        final mapPaths = scopedModelSource
            ? const <String>{}
            : before.manifest.maps.map((map) => map.relativePath).toSet();
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
        final projectedProject = scopedModelSource
            ? _mergeModelSourceProjection(
                before.manifest,
                planned.projectedProject ?? snapshot.manifest,
              )
            : planned.projectedProject;
        final receipt = _resourceReceipt(
          before.manifest,
          before.revision,
          planned.plan,
          createdTilesetId,
          operationId,
          projectedProject: projectedProject,
          projectedRevision: snapshot.materializedCatalogProject
              ? scopedModelSource
                    ? _modelSourceDocumentRevision(snapshot, plan: planned.plan)
                    : studioProjectPlanRevision(snapshot, planned.plan)
              : null,
          changedModels: scopedModelSource
              ? {
                  for (final model in planned.projectedProject!.models3d)
                    model.id: model,
                }
              : const {},
        );
        phase('receipt.end');
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
          phase('apply.end');
          await beforeReconciliation?.call();
          _requireAvailable();
          if (snapshot.materializedCatalogProject) {
            final after = scopedModelSource
                ? await api.readWorkshopSnapshot(
                    opened.projectHandle,
                    actionId: actionId,
                    parameters: fields,
                  )
                : await snapshots.load(
                    opened.projectHandle,
                    policy: ProjectSnapshotLoadPolicy.editorReadProjection,
                  );
            if ((scopedModelSource
                        ? _modelSourceDocumentRevision(after)
                        : studioProjectSnapshotRevision(after)) !=
                    receipt.revision ||
                (scopedModelSource
                    ? !_modelSourcesMatch(
                        after.manifest,
                        planned.projectedProject ?? snapshot.manifest,
                      )
                    : after.manifest != receipt.manifest)) {
              throw const ResourceFailure(
                'La publication a changé avant sa relecture. Relisez sans la rejouer.',
              );
            }
          }
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
        phase('reconciliation.end');
        return receipt;
      } finally {
        try {
          await ownedPlan?.releaseAppliedPayload();
          for (final handle in stagedHandles) {
            await artifacts.release(handle);
          }
        } finally {
          context.profiles.sink = null;
        }
      }
    } on ResourceFailure {
      rethrow;
    } on Object catch (error) {
      throw _resourceFailure(error);
    } finally {
      _resourceMutationActive = false;
      try {
        if (_disposed) await _closeMutationContext();
      } finally {
        trace.finish();
      }
    }
  });
}
