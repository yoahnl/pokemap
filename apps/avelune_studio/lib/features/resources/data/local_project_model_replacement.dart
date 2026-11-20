part of 'local_resource_adapter.dart';

const _replaceModelFile = 'model3d.source.replace';
const _replaceModelUsages = 'resource.usages.replace';
const _staleReplacement = ResourceFailure(
  'Le catalogue a changé. Actualisez la bibliothèque puis reprenez l’opération.',
);

final class _LocalProjectModelReplacement
    implements ProjectModelReplacementPort {
  _LocalProjectModelReplacement(this.adapter);

  final LocalResourceAdapter adapter;
  final _preparations = <ProjectModelReplacement, _ModelReplacementPlan>{};

  @override
  Future<ProjectModelSourceReplacement> prepareSource({
    required String modelId,
    required PickedProjectLibraryFile file,
    required String expectedRevision,
  }) => _prepare(
    action: _replaceModelFile,
    parameters: {'modelId': modelId},
    expectedRevision: expectedRevision,
    file: file,
    build: (snapshot, planned) async {
      final before = snapshot.manifest.models3d.single;
      final after = planned.projectedProject?.models3d.single ?? before;
      final source = planned.plan.changeSet.changes
          .where((change) => change.storageKey == before.relativePath)
          .firstOrNull;
      final payload = source?.afterPayload;
      return ProjectModelSourceReplacement(
        before: before,
        after: after,
        inspectedBytes: Uint8List.fromList(
          payload == null
              ? snapshot.resourceBytes('model3d:$modelId')
              : await payload.readBytes(),
        ),
        fileName: p.basename(file.path),
        noChange: !planned.applicable,
      );
    },
  );

  @override
  Future<ProjectModelUsageReplacement> prepareUsages({
    required String modelId,
    required String replacementId,
    required String expectedRevision,
  }) => _prepare(
    action: _replaceModelUsages,
    parameters: {
      'family': 'models3d',
      'resourceId': modelId,
      'replacementId': replacementId,
    },
    expectedRevision: expectedRevision,
    build: (snapshot, planned) async {
      final preview = planned.plan.preview;
      final borderIds = (preview['repointedBorderIds'] as List?) ?? const [];
      return ProjectModelUsageReplacement(
        sourceId: modelId,
        targetId: replacementId,
        affectedMapIds: Set.unmodifiable(snapshot.maps.map((map) => map.id)),
        maps: List.unmodifiable([
          for (final value in preview['maps'] as List)
            (
              id: value['mapId'] as String,
              name: value['mapName'] as String,
              redirected: (value['instanceIds'] as List).length,
              recalculated: value['regeneratedInstanceCount'] as int,
            ),
        ]),
        borders: Map.unmodifiable({
          for (final record in snapshot.manifest.borderCatalog.records)
            if (borderIds.contains(record.id))
              record.id: record.draft.definition.name,
        }),
        redirected: preview['occurrenceCount'] as int,
        recalculated: preview['regeneratedInstanceCount'] as int? ?? 0,
        noChange: !planned.applicable,
      );
    },
  );

  Future<T> _prepare<T extends ProjectModelReplacement>({
    required String action,
    required Map<String, Object?> parameters,
    required String expectedRevision,
    required Future<T> Function(ProjectSnapshot, AuthoringMutationPlanResult)
    build,
    PickedProjectLibraryFile? file,
  }) => adapter.mapAdapter.withResourceMutation(() async {
    adapter._requireLibraryEditing();
    final session = adapter.session;
    final before = await adapter.mapAdapter.resourceBaseline(session);
    if (before.revision != expectedRevision) throw _staleReplacement;
    final context = await _LocalResourceMutationContext.create(session);
    final opened = context.opened;
    String? artifact;
    var retained = false;
    try {
      await context.attach();
      if (file != null) {
        if (file.imageSize != null) {
          throw const ResourceFailure('Sélectionnez un fichier GLB.');
        }
        final reader = await context.openService.catalogProject(
          opened.projectHandle,
        );
        final relations = await readCatalogResourceLibraryRelations(
          reader!.catalog.snapshot,
          CatalogDefinitionKey(
            CatalogDefinitionKind.model3d,
            parameters['modelId'] as String,
          ),
        );
        if (relations?.consumers == null) {
          throw const ProjectLibraryNeedsPreparation();
        }
        await context.artifacts.authorizeSourceFile(file.path);
        final staged = await context.api.stageArtifactFile(
          sourcePath: file.path,
          declaredMediaType: 'model/gltf-binary',
        );
        artifact = staged.reference.handle;
        if (staged.reference != file.artifact) {
          throw const ResourceFailure(
            'Le fichier choisi a changé. Sélectionnez-le à nouveau.',
          );
        }
        parameters['artifactHandle'] = artifact;
      }
      final snapshot = await context.api.readWorkshopSnapshot(
        opened.projectHandle,
        actionId: action,
        parameters: parameters,
      );
      final operation = adapter._identity('replace_model');
      final planned = await context.api.planMutation(
        opened.projectHandle,
        AuthoringRequest(
          requestId: operation,
          actionId: action,
          actionVersion: 1,
          workspaceHandle: opened.workspaceHandle.value,
          expectedRevision: snapshot.revision,
          idempotencyKey: operation,
          parameters: parameters,
        ),
      );
      final result = await build(snapshot, planned);
      if (await adapter.mapAdapter.resourceRevision(session) !=
          before.revision) {
        throw _staleReplacement;
      }
      adapter._requireAvailable();
      if (planned.applicable) {
        final model = result is ProjectModelSourceReplacement ? result : null;
        final after = model == null
            ? before.manifest
            : _mergeModelSourceProjection(
                before.manifest,
                planned.projectedProject!,
              );
        final nextRevision = await adapter._projectedLibraryRevision(
          planned.plan,
        );
        final undo = adapter._identity('restore_model');
        final changes = planned.plan.changeSet.changes;
        ResourceMutationReceipt receipt({required bool restore}) {
          final definition = restore ? model?.before : model?.after;
          final pathRevisions = {
            for (final change in changes)
              change.storageKey: restore
                  ? change.beforeRevision
                  : change.afterRevision,
          };
          return ResourceMutationReceipt(
            before: restore ? after : before.manifest,
            manifest: restore ? before.manifest : after,
            beforeRevision: restore ? nextRevision : before.revision,
            revision: restore ? before.revision : nextRevision,
            changedPaths: pathRevisions.keys.toList(growable: false),
            pathRevisions: Map.unmodifiable(pathRevisions),
            operationId: restore ? undo : operation,
            actionId: action,
            changedModels: definition == null
                ? const {}
                : {definition.id: definition},
            modelSourceRevisions: {
              if (pathRevisions[definition?.relativePath] case final String rev)
                definition!.sourceAssetId: rev,
            },
          );
        }

        adapter._requireAvailable();
        _preparations[result] = _ModelReplacementPlan(
          context: context,
          planned: planned,
          artifact: artifact,
          publication: receipt(restore: false),
          restoration: receipt(restore: true),
        );
        retained = true;
      }
      return result;
    } on Object catch (error) {
      throw _modelReplacementFailure(error);
    } finally {
      if (!retained) await _closeReplacementContext(context, artifact);
    }
  });

  @override
  Future<ProjectModelReplacementCommit> apply(
    ProjectModelReplacement preparation, {
    required String? Function() checkDrafts,
  }) => adapter.mapAdapter.withResourceMutation(() async {
    adapter._requireLibraryEditing();
    final plan = _preparations.remove(preparation);
    if (plan == null) {
      throw const ResourceFailure('Préparez de nouveau le remplacement.');
    }
    try {
      await _checkRevision(plan.publication.beforeRevision);
      _requireCleanDrafts(checkDrafts);
      final applied = await adapter._applyPlanned(
        api: plan.context.api,
        opened: plan.context.opened,
        planned: plan.planned,
        operationId: plan.publication.operationId!,
        confirmDestructive: preparation is ProjectModelUsageReplacement,
        validateBeforeApply: checkDrafts,
      );
      final usage = preparation is ProjectModelUsageReplacement
          ? preparation
          : null;
      return ProjectModelReplacementCommit(
        entryId: applied.receipt.receiptId,
        restorationOperationId: plan.restoration.operationId!,
        publication: plan.publication,
        restoration: plan.restoration,
        resources: Set.unmodifiable({
          for (final map in usage?.maps ?? const <ModelUsageMapImpact>[])
            (kind: 'map', id: map.id),
          for (final id in usage?.borders.keys ?? const <String>[])
            (kind: 'borderBlueprint', id: id),
        }),
        sourceModelId:
            usage?.sourceId ??
            (preparation as ProjectModelSourceReplacement).before.id,
        targetModelId: usage?.targetId,
        affectedMapIds: usage?.affectedMapIds ?? const {},
      );
    } on Object catch (error) {
      throw _modelReplacementFailure(error);
    } finally {
      await _closeReplacementContext(plan.context, plan.artifact);
    }
  });

  @override
  Future<ProjectModelReplacementCommit> undo(
    ProjectModelReplacementCommit commit, {
    required String? Function() checkDrafts,
  }) => adapter.mapAdapter.withResourceMutation(() async {
    adapter._requireLibraryEditing();
    if (commit.restored) return commit;
    final context = await _LocalResourceMutationContext.create(adapter.session);
    try {
      await context.attach();
      await _undoReviewedReplacement(adapter, context, commit, checkDrafts);
      return ProjectModelReplacementCommit(
        entryId: commit.entryId,
        restorationOperationId: commit.restorationOperationId,
        publication: commit.publication,
        restoration: commit.restoration,
        resources: commit.resources,
        sourceModelId: commit.sourceModelId,
        targetModelId: commit.targetModelId,
        affectedMapIds: commit.affectedMapIds,
        restored: true,
      );
    } on Object catch (error) {
      throw _modelReplacementFailure(error);
    } finally {
      await context.close();
    }
  });

  Future<void> _checkRevision(String expected) async {
    final revision = await adapter.mapAdapter.resourceRevision(adapter.session);
    if (revision != expected) throw _staleReplacement;
    adapter._requireAvailable();
  }

  @override
  Future<void> reconcile(ProjectModelReplacementCommit commit) async {
    final receipt = commit.receipt;
    await adapter.beforeReconciliation?.call();
    if (receipt.changedModels.isNotEmpty) {
      await adapter.reconcileReceipt(receipt);
    } else {
      await _verifyResourceReceiptPaths(adapter.session.directoryPath, receipt);
      await _checkRevision(receipt.revision);
    }
  }

  @override
  Future<void> release(ProjectModelReplacement preparation) async {
    final plan = _preparations.remove(preparation);
    if (plan != null) {
      await _closeReplacementContext(plan.context, plan.artifact);
    }
  }

  Future<void> close() async {
    for (final preparation in _preparations.keys.toList()) {
      await release(preparation);
    }
  }
}
