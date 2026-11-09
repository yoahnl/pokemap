part of 'local_resource_adapter.dart';

const _catalogClassificationActions = {
  'resource.classify',
  'resource.classify_batch',
  'resource.family.create',
  'resource.family.update',
  'resource.family.delete',
};

bool _isCatalogClassification(LocalResourceAdapter adapter, String actionId) =>
    adapter.session.storage == ProjectSessionStorage.workingCatalog &&
    _catalogClassificationActions.contains(actionId);

Future<String> _captureCatalogRevision(LocalResourceAdapter adapter) =>
    adapter.mapAdapter.withResourceMutation(() async {
      adapter._requireAvailable();
      return (await adapter.mapAdapter.resourceBaseline(adapter.session))
          .revision;
    });

bool _matchesCapturedRevision(
  LocalResourceAdapter adapter,
  ProjectSnapshot snapshot,
  String? expected,
) =>
    expected == null ||
    (adapter.session.storage == ProjectSessionStorage.workingCatalog
            ? studioProjectSnapshotRevision(snapshot)
            : snapshot.revision) ==
        expected;

Future<ResourceMutationPreparation> _prepareCatalogClassification(
  LocalResourceAdapter adapter,
  String actionId,
  Map<String, Object?> parameters,
  String? expectedRevision,
) async {
  final revision = await _captureCatalogRevision(adapter);
  if (expectedRevision != null && revision != expectedRevision) {
    throw const ResourceFailure(
      'Les informations ont changé depuis l’ouverture. Votre saisie est conservée.',
    );
  }
  return ResourceMutationPreparation(
    sessionId: adapter.session.sessionId,
    actionId: actionId,
    parameters: parameters,
    snapshotRevision: revision,
    manifestRevision: revision,
    changedPaths: const [CatalogStorageStore.headStorageKey],
    confirmationRequired: false,
  );
}

Future<ResourceMutationReceipt> _applyCatalogClassification(
  LocalResourceAdapter adapter,
  ResourceMutationPreparation preparation, {
  String? Function()? validateBeforeApply,
}) async {
  final scoped = await _applyScopedClassification(
    adapter,
    preparation,
    validateBeforeApply: validateBeforeApply,
  );
  if (scoped != null) return scoped;
  return adapter._run(
    preparation.actionId,
    (_) => preparation.parameters,
    expectedBeforeRevision: preparation.manifestRevision,
    validateBeforeApply: validateBeforeApply,
  );
}

Future<ResourceMutationReceipt?> _applyScopedClassification(
  LocalResourceAdapter adapter,
  ResourceMutationPreparation preparation, {
  String? Function()? validateBeforeApply,
}) => adapter.mapAdapter.withResourceMutation(() async {
  adapter._resourceMutationActive = true;
  final trace = developer.TimelineTask()..start('studio.resource.classify');
  void phase(String name) {
    trace.instant(name);
    adapter.mutationPhaseObserver?.call(name);
  }

  try {
    adapter._requireAvailable();
    phase('baseline.start');
    final before = await adapter.mapAdapter.resourceBaseline(adapter.session);
    phase('baseline.end');
    if (before.revision != preparation.manifestRevision) {
      throw const ResourceFailure(
        'Le projet a changé depuis l’ouverture. Votre saisie est conservée.',
      );
    }
    final context = await adapter._requireMutationContext();
    await context.attach();
    final api = context.api;
    final opened = context.opened;
    final parameters = Map<String, Object?>.from(preparation.parameters);
    final operationId = adapter._identity('resource');
    final AuthoringMutationPlanResult planned;
    try {
      final snapshot = await api.readWorkshopSnapshot(
        opened.projectHandle,
        actionId: preparation.actionId,
        parameters: parameters,
      );
      phase('snapshot.end');
      planned = await api.planMutation(
        opened.projectHandle,
        AuthoringRequest(
          requestId: operationId,
          actionId: preparation.actionId,
          actionVersion: 1,
          workspaceHandle: opened.workspaceHandle.value,
          parameters: parameters,
          expectedRevision: snapshot.revision,
          idempotencyKey: operationId,
          extensions: const {'workshopScope': true},
        ),
      );
      phase('plan.end');
    } on AuthoringPlanException catch (failure) {
      if (failure.code == 'catalog.mutation_scope_required') return null;
      rethrow;
    } on CatalogStorageException catch (failure) {
      if (failure.code == 'catalog.preparation_required') return null;
      rethrow;
    } on FormatException catch (failure) {
      if (failure.message.startsWith('catalog.resource_positions.')) {
        return null;
      }
      rethrow;
    }
    try {
      adapter._requireAvailable();
      if (await adapter.mapAdapter.resourceRevision(adapter.session) !=
          before.revision) {
        throw const ResourceFailure(
          'Le projet a changé sur le disque. Rien n’a été écrasé.',
        );
      }
      final changes = planned.plan.changeSet.changes;
      if (changes.isEmpty) {
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
      final selected =
          planned.projectedProject ??
          (throw const ResourceFailure(
            'Le rangement n’a pas pu être préparé. Rien n’a été écrit.',
          ));
      final merged = mergeResourceLibraryCatalogs(
        before.manifest.resourceLibraryCatalog,
        selected.resourceLibraryCatalog,
      );
      final cleared = _clearedClassifications(
        preparation.actionId,
        parameters,
        selected.resourceLibraryCatalog,
      );
      final manifest = before.manifest.copyWith(
        resourceLibraryCatalog: cleared.isEmpty
            ? merged
            : ResourceLibraryCatalog(
                families: merged.families,
                entries: merged.entries.where(
                  (entry) => !cleared.contains(entry.identity),
                ),
              ),
      );
      final publishedManifest = preparation.actionId == 'resource.family.delete'
          ? manifest.copyWith(resourceLibraryCatalog: ResourceLibraryCatalog(
              families: manifest.resourceLibraryCatalog.families.where(
                  (family) => family.id != parameters['familyId']),
              entries: manifest.resourceLibraryCatalog.entries))
          : manifest;
      try {
        await api.applyMutation(
          opened.projectHandle,
          planId: planned.planId,
          operationId: operationId,
          precondition: () async {
            await adapter.beforeTransactionPrecondition?.call();
            adapter._requireAvailable();
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
      phase('apply.end');
      final receipt = ResourceMutationReceipt(
        before: before.manifest,
        manifest: publishedManifest,
        beforeRevision: before.revision,
        revision: await adapter.mapAdapter.resourceRevision(adapter.session),
        changedPaths: List.unmodifiable(changes.map((c) => c.storageKey)),
        operationId: operationId,
        actionId: preparation.actionId,
        snapshotBeforeRevision: planned.plan.baseRevision,
      );
      try {
        await adapter.beforeReconciliation?.call();
        adapter._requireAvailable();
        await adapter.mapAdapter.acceptResourceMutation(
          adapter.session,
          receipt,
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
      await planned.plan.releaseAppliedPayload();
    }
  } on ResourceFailure {
    rethrow;
  } on Object catch (error) {
    if (error is CatalogStorageException && error.code == 'catalog.resource_usage.preparation_required') {
      throw const ResourceFailure('Préparez les usages et les familles depuis « Familles » dans la bibliothèque, puis réessayez. Rien n’a été modifié.');
    }
    throw _resourceFailure(error);
  } finally {
    adapter._resourceMutationActive = false;
    try {
      if (adapter._disposed) await adapter._closeMutationContext();
    } finally {
      trace.finish();
    }
  }
});

Future<bool> _reconcileCatalogClassification(
  LocalResourceAdapter adapter,
  ResourceMutationReceipt receipt,
) async {
  if (adapter.session.storage != ProjectSessionStorage.workingCatalog ||
      !_catalogClassificationActions.contains(receipt.actionId) ||
      receipt.pathRevisions.isNotEmpty ||
      receipt.changedModels.isNotEmpty) {
    return false;
  }
  await adapter.mapAdapter.withResourceMutation(() async {
    adapter._requireAvailable();
    if (await adapter.mapAdapter.resourceRevision(adapter.session) !=
        receipt.revision) {
      throw const ResourceFailure(
        'Les ressources ont changé depuis la publication. Une relecture du projet est nécessaire.',
      );
    }
    await adapter.mapAdapter.acceptResourceMutation(adapter.session, receipt);
  });
  return true;
}

Set<String> _clearedClassifications(
  String actionId,
  Map<String, Object?> parameters,
  ResourceLibraryCatalog selected,
) {
  final targets = switch (actionId) {
    'resource.classify' => [parameters],
    'resource.classify_batch' => [
      for (final entry in parameters['entries'] as List) entry as Map,
    ],
    _ => const <Map>[],
  };
  return {
    for (final target in targets)
      if (selected.entryFor(
            target['resourceKind'] as String,
            target['resourceId'] as String,
          ) ==
          null)
        '${target['resourceKind']}:${target['resourceId']}',
  };
}
