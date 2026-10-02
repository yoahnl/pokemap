part of 'local_resource_adapter.dart';

Future<void> _reconcileResourceReceipt(
  LocalResourceAdapter adapter,
  ResourceMutationReceipt receipt,
) => adapter.mapAdapter.withResourceMutation(() async {
  adapter._requireAvailable();
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
    var changed =
        narrativeEventBytesFingerprint(snapshot.resourceBytes('project')) !=
        receipt.revision;
    for (final entry in receipt.pathRevisions.entries) {
      final identity = await reader.readIdentity(
        projectRoot: adapter.session.directoryPath,
        relativePath: entry.key,
      );
      final revision = identity == null
          ? null
          : computeNarrativeProjectFingerprint([
              NarrativeProjectFingerprintEntry(
                relativePath: entry.key,
                bytes: await reader.readBytes(
                  projectRoot: adapter.session.directoryPath,
                  relativePath: entry.key,
                ),
              ),
            ]);
      if (revision != entry.value) changed = true;
    }
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
