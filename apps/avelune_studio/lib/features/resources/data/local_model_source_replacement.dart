part of 'local_resource_adapter.dart';

final class _ModelReplacementPlan {
  const _ModelReplacementPlan({
    required this.context,
    required this.planned,
    required this.artifact,
    required this.publication,
    required this.restoration,
  });

  final _LocalResourceMutationContext context;
  final AuthoringMutationPlanResult planned;
  final String? artifact;
  final ResourceMutationReceipt publication;
  final ResourceMutationReceipt restoration;
}

String _modelSourceDocumentRevision(
  ProjectSnapshot snapshot, {
  AuthoringPlan? plan,
}) {
  if (!snapshot.materializedCatalogProject) {
    return plan == null
        ? studioProjectSnapshotRevision(snapshot)
        : studioProjectPlanRevision(snapshot, plan);
  }
  final head = plan?.changeSet.changes
      .where(
        (change) => change.storageKey == CatalogStorageStore.headStorageKey,
      )
      .firstOrNull;
  return studioProjectDocumentRevision(
    descriptorBytes: snapshot.resourceBytes('catalogDescriptor'),
    headBytes: head?.afterBytes ?? snapshot.resourceBytes('catalogHead'),
  );
}

void _requireCleanDrafts(String? Function() check) {
  if (check() case final problem?) throw ResourceFailure(problem);
}

Future<void> _closeReplacementContext(
  _LocalResourceMutationContext context,
  String? artifact,
) async {
  try {
    if (artifact != null) await context.artifacts.release(artifact);
  } finally {
    await context.close();
  }
}

Future<void> _undoReviewedReplacement(
  LocalResourceAdapter adapter,
  _LocalResourceMutationContext context,
  ProjectModelReplacementCommit commit,
  String? Function() checkDrafts,
) async {
  Future<String> revision() =>
      adapter.mapAdapter.resourceRevision(adapter.session);
  final operationId = commit.restorationOperationId;
  Future<AuthoringMutationResult> undo() => context.api.undoMutation(
    context.opened.projectHandle,
    entryId: commit.entryId,
    idempotencyKey: operationId,
    precondition: () async {
      adapter._requireAvailable();
      if (await revision() != commit.publication.revision) {
        throw _staleReplacement;
      }
      _requireCleanDrafts(checkDrafts);
    },
  );
  try {
    await undo();
  } on Object catch (error, stack) {
    try {
      await _recoverPublishedResourceMutation(
        context.api,
        context.opened,
        operationId,
        error,
        stack,
      );
    } on Object {
      if (await revision() != commit.restoration.revision) {
        Error.throwWithStackTrace(error, stack);
      }
      await undo();
    }
  }
}

ProjectManifest _mergeModelSourceProjection(
  ProjectManifest before,
  ProjectManifest selected,
) {
  final entries = before.models3d;
  if (entries is! ProjectModel3dEntries) {
    throw const ResourceFailure(
      'Rechargez le catalogue des modèles avant de reprendre cette modification.',
    );
  }
  return before.copyWith(
    models3d: entries.replaceSelected(
      selected.models3d.where((model) => entries.lookup(model.id) != null),
    ),
  );
}

bool _modelSourcesMatch(ProjectManifest selected, ProjectManifest expected) {
  final models = {for (final model in selected.models3d) model.id: model};
  return models.length == expected.models3d.length &&
      expected.models3d.every((model) => models[model.id] == model);
}

Future<Uint8List> _readCatalogModelSource(
  LocalResourceAdapter adapter,
  String modelId,
) => adapter.mapAdapter.withResourceMutation(() async {
  adapter._requireAvailable();
  final before = await adapter.mapAdapter.resourceBaseline(adapter.session);
  final context = await adapter._requireMutationContext();
  await context.attach();
  final snapshot = await context.api.readWorkshopSnapshot(
    context.opened.projectHandle,
    actionId: 'model3d.source.replace',
    parameters: {'modelId': modelId},
  );
  adapter._requireAvailable();
  if (_modelSourceDocumentRevision(snapshot) != before.revision) {
    throw const ResourceFailure(
      'Le projet a changé pendant la lecture du modèle.',
    );
  }
  final bytes = snapshot.resourceBytes('model3d:$modelId');
  adapter._requireAvailable();
  if (await adapter.mapAdapter.resourceRevision(adapter.session) !=
      before.revision) {
    throw const ResourceFailure(
      'Le projet a changé pendant la lecture du modèle.',
    );
  }
  return Uint8List.fromList(bytes);
});

Object _modelReplacementFailure(Object error) => switch (error) {
  ResourceFailure() || ProjectLibraryNeedsPreparation() => error,
  CatalogStorageException(
    code: 'catalog.resource_usage.preparation_required',
  ) =>
    const ProjectLibraryNeedsPreparation(),
  AuthoringPlanException(code: 'catalog.model_source_shared') =>
    const ResourceFailure(
      'Ce fichier GLB est partagé par plusieurs ressources.',
    ),
  FormatException(:final message)
      when message.contains('exterior.resource_in_use') =>
    const ResourceFailure(
      'Le modèle ou une de ses bordures est utilisé dans un décor extérieur.',
    ),
  FormatException(:final message)
      when message.contains('exterior.reference_index_recovery_required') =>
    const ResourceFailure(
      'Les références du décor extérieur doivent être réparées avant ce remplacement.',
    ),
  VisualLibraryException(code: 'resource.usages.replacement_incompatible') =>
    const ResourceFailure(
      'Le modèle choisi est incompatible avec au moins un placement.',
    ),
  VisualLibraryException(code: 'resource.usages.border_regeneration_refused') =>
    const ResourceFailure(
      'Le modèle choisi ne permet pas de reconstruire une bordure à l’identique.',
    ),
  _ => _resourceFailure(error),
};
