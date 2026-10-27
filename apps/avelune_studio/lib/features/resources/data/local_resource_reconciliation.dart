part of 'local_resource_adapter.dart';

Future<void> _reconcileResourceReceipt(
  LocalResourceAdapter adapter,
  ResourceMutationReceipt receipt,
) => adapter.mapAdapter.withResourceMutation(() async {
  adapter._requireAvailable();
  if (adapter.session.storage == ProjectSessionStorage.workingCatalog &&
      receipt.changedModels.isNotEmpty) {
    final context = await adapter._requireMutationContext();
    await context.attach();
    final snapshot = await context.api.readWorkshopSnapshot(
      context.opened.projectHandle,
      actionId: 'model3d.source.replace_batch',
      parameters: {
        'models': [
          for (final modelId in receipt.changedModels.keys)
            {'modelId': modelId},
        ],
      },
    );
    if (_modelSourceDocumentRevision(snapshot) != receipt.revision ||
        snapshot.manifest.models3d.length != receipt.changedModels.length ||
        snapshot.manifest.models3d.any(
          (model) => receipt.changedModels[model.id] != model,
        )) {
      throw const ResourceFailure(
        'Les modèles ont changé depuis la publication. Une relecture est nécessaire.',
      );
    }
    await _verifyResourceReceiptPaths(adapter.session.directoryPath, receipt);
    adapter._requireAvailable();
    await adapter.mapAdapter.acceptResourceMutation(adapter.session, receipt);
    return;
  }
  const reader = LocalProjectFileReader();
  final policy = await WorkspacePolicy.create(
    allowedRootPaths: [adapter.session.directoryPath],
    fileReader: reader,
  );
  final handles = WorkspaceHandleStore();
  final opened = await ProjectOpenService(
    policy: policy,
    fileReader: reader,
    handles: handles,
  ).openProject(adapter.session.directoryPath);
  try {
    final snapshot = await ProjectSnapshotLoader(handles: handles).load(
      opened.projectHandle,
      policy: ProjectSnapshotLoadPolicy.editorReadProjection,
    );
    adapter._requireAvailable();
    var changed = studioProjectSnapshotRevision(snapshot) != receipt.revision;
    await _verifyResourceReceiptPaths(adapter.session.directoryPath, receipt);
    if (changed) {
      throw const ResourceFailure(
        'Les ressources ont changé depuis la publication. Une relecture du projet est nécessaire.',
      );
    }
    await adapter.mapAdapter.acceptResourceMutation(
      adapter.session,
      receipt,
      allowMapOrganization: receipt.actionId == 'map.library.reorganize',
    );
  } finally {
    handles.closeWorkspace(opened.workspaceHandle);
  }
});

Future<void> _verifyResourceReceiptPaths(
  String projectRoot,
  ResourceMutationReceipt receipt,
) async {
  const reader = LocalProjectFileReader();
  for (final entry in receipt.pathRevisions.entries) {
    final identity = await reader.readIdentity(
      projectRoot: projectRoot,
      relativePath: entry.key,
    );
    String? revision;
    if (identity != null) {
      final fingerprint = NarrativeProjectFingerprintBuilder()
        ..startEntry(relativePath: entry.key, byteLength: identity.byteLength);
      await for (final chunk in reader.openRead(
        projectRoot: projectRoot,
        relativePath: entry.key,
      )) {
        fingerprint.addBytes(chunk);
      }
      fingerprint.endEntry();
      revision = fingerprint.close();
    }
    if (revision != entry.value) {
      throw const ResourceFailure(
        'Les ressources ont changé depuis la publication. Une relecture du projet est nécessaire.',
      );
    }
  }
}
