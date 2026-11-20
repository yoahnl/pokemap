part of 'local_resource_adapter.dart';

extension _LocalResourceMutation on LocalResourceAdapter {
  Future<ResourceMutationReceipt> _run(
    String actionId,
    Map<String, Object?> Function(ProjectManifest manifest) parameters, {
    String? sourcePath,
    String sourceMediaType = 'image/png',
    ContentArtifactRef? expectedSource,
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
      if (_disposed || !_resourceMutationActions.contains(actionId)) {
        throw const ResourceFailure(
          'Cette opération de ressource est indisponible.',
        );
      }
      if (session.storage == ProjectSessionStorage.portableCatalog &&
          actionId == 'model3d.configure') {
        throw const ResourceFailure(
          'Ce catalogue est en lecture seule. La définition du modèle n’a pas été modifiée.',
        );
      }
      phase('baseline.start');
      final before = await mapAdapter.resourceBaseline(session);
      phase('baseline.end');
      _requireAvailable();
      final scopedImport =
          session.storage == ProjectSessionStorage.workingCatalog &&
          const {
            'tileset.import_image',
            'model3d.import',
            'model3d.duplicate',
          }.contains(actionId);
      if (expectedBeforeRevision != null &&
          before.revision != expectedBeforeRevision) {
        throw ResourceFailure(switch (actionId) {
          'model3d.configure' =>
            'Le catalogue a changé. Votre réglage est conservé.',
          _ when scopedImport =>
            'Le catalogue a changé. Actualisez la bibliothèque puis réessayez.',
          _ =>
            'Le projet a changé pendant la préparation. Reprenez la bordure.',
        });
      }
      final fields = Map<String, Object?>.from(parameters(before.manifest));
      final scopedModelMutation =
          (session.storage == ProjectSessionStorage.workingCatalog &&
              {
                'model3d.source.replace',
                'model3d.source.replace_batch',
              }.contains(actionId)) ||
          (session.storage != ProjectSessionStorage.portableCatalog &&
              actionId == 'model3d.configure' &&
              fields.length == 2 &&
              fields.containsKey('modelId') &&
              fields.containsKey('castsShadowsByDefault'));
      if (session.storage != ProjectSessionStorage.portableCatalog &&
          expectedSnapshotRevision == null &&
          resourceMutationIsUnchanged(before.manifest, actionId, fields)) {
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
          if (expectedSource != null && staged.reference != expectedSource) {
            throw const ResourceFailure(
              'Le fichier choisi a changé. Sélectionnez-le à nouveau.',
            );
          }
          fields['artifactHandle'] = artifactHandle;
          phase('artifact.staged');
        }
        if (borderSources != null &&
            borderSources.any((source) => !source.draft.isSpatial)) {
          fields['primitiveSources'] = await _stagedBorderSources(
            api,
            artifacts,
            borderSources,
            stagedHandles,
          );
        }
        phase('attach.start');
        await context.attach();
        phase('attach.end');
        final snapshot = scopedModelMutation || scopedImport
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
        final observedRevision = scopedImport
            ? await mapAdapter.resourceRevision(session)
            : scopedModelMutation
            ? _modelSourceDocumentRevision(snapshot)
            : studioProjectSnapshotRevision(snapshot);
        if (observedRevision != before.revision) {
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
            extensions: scopedImport ? const {'workshopScope': true} : const {},
          ),
        );
        ownedPlan = planned.plan;
        phase('plan.end');
        final changes = planned.plan.changeSet.changes;
        final mapPaths = scopedModelMutation || scopedImport
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
        final projectedProject = scopedImport
            ? _mergeImportedLibraryResource(
                before.manifest,
                planned.projectedProject!,
                modelId: fields['modelId'] as String?,
              )
            : scopedModelMutation
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
          projectedRevision: scopedImport
              ? await _projectedLibraryRevision(planned.plan)
              : snapshot.materializedCatalogProject
              ? scopedModelMutation
                    ? _modelSourceDocumentRevision(snapshot, plan: planned.plan)
                    : studioProjectPlanRevision(snapshot, planned.plan)
              : null,
          changedModels: scopedModelMutation
              ? {
                  for (final model in planned.projectedProject!.models3d)
                    model.id: model,
                }
              : const {},
        );
        phase('receipt.end');
        _requireAvailable();
        await _applyPlanned(
          api: api,
          opened: opened,
          planned: planned,
          operationId: operationId,
          confirmDestructive: confirmDestructive,
          validateBeforeApply: validateBeforeApply,
        );
        await _rereadApplied(
          api: api,
          snapshots: snapshots,
          opened: opened,
          snapshot: snapshot,
          planned: planned,
          receipt: receipt,
          actionId: actionId,
          fields: fields,
          scopedModelMutation: scopedModelMutation,
          scopedImport: scopedImport,
          phase: phase,
        );
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
      throw expectedSource == null
          ? _resourceFailure(error)
          : _libraryImportFailure(error);
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
