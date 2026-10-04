part of 'local_resource_adapter.dart';

Future<String?> _readResourceFingerprint(
  LocalResourceAdapter adapter,
  String tilesetId,
  String revision,
) => _readResourceSnapshot(adapter, (snapshot, _) {
  if (snapshot.revision != revision) {
    throw const ResourceFailure(
      'Les informations ont changé pendant leur lecture.',
    );
  }
  final tileset = snapshot.manifest.tilesets
      .where((t) => t.id == tilesetId)
      .firstOrNull;
  if (tileset == null) {
    throw const ResourceFailure('Cette planche n’existe plus.');
  }
  final bytes = snapshot.findResourceBytes('assetCatalog');
  if (bytes == null) return null;
  final catalog = AssetCatalog.fromJson(
    jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>,
  );
  final matches = catalog.records
      .where((a) => a.logicalPath == tileset.relativePath)
      .toList();
  return matches.length == 1 ? matches.single.artifact.digest : null;
});

Future<T> _readResourceSnapshot<T>(
  LocalResourceAdapter adapter,
  FutureOr<T> Function(ProjectSnapshot snapshot, OpenedProject opened) read,
) => adapter.mapAdapter.withResourceMutation(() async {
  adapter._requireAvailable();
  final before = await adapter.mapAdapter.resourceBaseline(adapter.session);
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
    if (narrativeEventBytesFingerprint(snapshot.resourceBytes('project')) !=
        before.revision) {
      throw const ResourceFailure(
        'Le projet a changé sur le disque. Relisez ses informations.',
      );
    }
    return await read(snapshot, opened);
  } on ResourceFailure {
    rethrow;
  } on Object catch (error) {
    throw _resourceFailure(error);
  } finally {
    handles.closeWorkspace(opened.workspaceHandle);
  }
});

Future<ResourceMutationPreparation> _prepareResourceOperation(
  LocalResourceAdapter adapter,
  String actionId,
  Map<String, Object?> parameters,
  String? expectedSnapshotRevision,
) => _readResourceSnapshot(adapter, (snapshot, opened) {
  if (!ResourceManagementActions.actionIds.contains(actionId)) {
    throw const ResourceFailure('Cette préparation est indisponible.');
  }
  if (expectedSnapshotRevision != null &&
      snapshot.revision != expectedSnapshotRevision) {
    throw const ResourceFailure(
      'Les informations ont changé depuis l’ouverture. Votre saisie est conservée.',
    );
  }
  final id = adapter._identity('resource_preview');
  final draft = const ResourceManagementActions().analyze(
    AuthoringPlanningContext(
      snapshot: snapshot,
      request: AuthoringRequest(
        requestId: id,
        actionId: actionId,
        actionVersion: 1,
        workspaceHandle: opened.workspaceHandle.value,
        parameters: parameters,
        expectedRevision: snapshot.revision,
        idempotencyKey: id,
      ),
      planId: id,
      seed: 0,
    ),
  );
  return ResourceMutationPreparation(
    sessionId: adapter.session.sessionId,
    actionId: actionId,
    parameters: parameters,
    snapshotRevision: snapshot.revision,
    manifestRevision: narrativeEventBytesFingerprint(
      snapshot.resourceBytes('project'),
    ),
    changedPaths: draft.changeSet.changes.map((c) => c.storageKey).toList(),
    confirmationRequired: actionId.endsWith('.delete'),
  );
});
