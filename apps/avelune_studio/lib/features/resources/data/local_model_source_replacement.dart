part of 'local_resource_adapter.dart';

String _modelSourceDocumentRevision(
  ProjectSnapshot snapshot, {
  AuthoringPlan? plan,
}) {
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

ProjectManifest _mergeModelSourceProjection(
  ProjectManifest before,
  ProjectManifest selected,
) {
  final entries = before.models3d;
  if (entries is! ProjectModel3dEntries) {
    throw const ResourceFailure(
      'Rechargez le catalogue des modèles avant de remplacer cette source.',
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
