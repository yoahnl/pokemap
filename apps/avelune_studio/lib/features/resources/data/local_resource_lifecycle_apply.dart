part of 'local_resource_adapter.dart';

Future<ResourceMutationReceipt> _applyLifecycleOperation(
  LocalResourceAdapter adapter,
  ResourceMutationPreparation preparation, {
  required bool confirmDestructive,
  String? Function()? validateBeforeApply,
}) => adapter.mapAdapter.withResourceMutation(() async {
  final retained = adapter._prepared[preparation];
  if (retained == null || retained.closed) {
    throw const ResourceFailure(
      'Cette préparation a expiré. Inspectez de nouveau la ressource.',
    );
  }
  adapter._requireAvailable();
  if (preparation.confirmationRequired && !confirmDestructive) {
    throw const ResourceFailure(
      'Confirmez les impacts avant cette publication.',
    );
  }
  final before = await adapter.mapAdapter.resourceBaseline(adapter.session);
  adapter._requireAvailable();
  if (before.revision != preparation.manifestRevision) {
    throw const ResourceFailure('Le projet a changé depuis la préparation.');
  }
  final problem = validateBeforeApply?.call();
  if (problem != null) throw ResourceFailure(problem);
  if (preparation.noChange) {
    final revision = await ProjectSnapshotLoader(handles: retained.handles)
        .load(
          retained.opened.projectHandle,
          policy: ProjectSnapshotLoadPolicy.editorReadProjection,
        );
    adapter._requireAvailable();
    if (revision.revision != preparation.snapshotRevision) {
      throw const ResourceFailure('Le projet a changé depuis la préparation.');
    }
    await adapter.releasePreparation(preparation);
    return ResourceMutationReceipt(
      before: before.manifest,
      manifest: before.manifest,
      beforeRevision: before.revision,
      revision: before.revision,
      changedPaths: const [],
    );
  }
  final operationId = adapter._identity('resource');
  final receipt = _resourceReceipt(
    retained.manifest,
    preparation.manifestRevision,
    retained.plan,
    null,
    operationId,
  );
  retained.applying = true;
  try {
    final confirmation = confirmDestructive
        ? await retained.api.confirmMutation(
            retained.opened.projectHandle,
            planId: retained.plan.planId,
          )
        : null;
    try {
      await retained.api.applyMutation(
        retained.opened.projectHandle,
        planId: retained.plan.planId,
        operationId: operationId,
        confirmationToken: confirmation?.confirmationToken,
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
        recovered = await retained.api.recoverMutation(
          retained.opened.projectHandle,
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
      await adapter.beforeReconciliation?.call();
      adapter._requireAvailable();
      await adapter.mapAdapter.acceptResourceMutation(adapter.session, receipt);
    } on Object catch (failure) {
      throw ResourceFailure(
        'La publication a réussi, mais la relecture a échoué. Relisez sans la rejouer. $failure',
        partialReceipt: receipt,
      );
    }
    await adapter.releasePreparation(preparation);
    return receipt;
  } on Object catch (error) {
    if (error is ResourceFailure) rethrow;
    throw _resourceFailure(error);
  } finally {
    retained.applying = false;
    if (adapter._disposed || retained.releaseRequested) {
      await adapter.releasePreparation(preparation);
    }
  }
});
