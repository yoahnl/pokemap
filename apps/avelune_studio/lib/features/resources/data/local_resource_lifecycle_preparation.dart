part of 'local_resource_adapter.dart';

const _lifecycleActions = {
  'tileset.source.replace',
  'tileset.remove',
  'element.duplicate',
  'element.delete',
  'element.upsert',
};

final class _ResourcePreparedContext {
  _ResourcePreparedContext({
    required this.handles,
    required this.opened,
    required this.api,
    required this.artifacts,
    required this.plan,
    required this.manifest,
    this.artifactHandle,
    this.beforeBytes,
  });

  final WorkspaceHandleStore handles;
  final OpenedProject opened;
  final LocalMapAuthoringMutationApi api;
  final LocalArtifactStore artifacts;
  final AuthoringPlan plan;
  final ProjectManifest manifest;
  final String? artifactHandle;
  final Uint8List? beforeBytes;
  bool closed = false;
  bool applying = false;
  bool releaseRequested = false;

  Future<void> close() async {
    if (closed) return;
    closed = true;
    if (artifactHandle != null) await artifacts.release(artifactHandle!);
    await api.detachWorkspace(opened.workspaceHandle);
    handles.closeWorkspace(opened.workspaceHandle);
  }
}

Future<ResourceMutationPreparation> _prepareLifecycleOperation(
  LocalResourceAdapter adapter,
  String actionId,
  Map<String, Object?> parameters, {
  String? expectedSnapshotRevision,
  ResourceReplacementRequest? replacement,
}) => adapter.mapAdapter.withResourceMutation(() async {
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
  final artifacts = LocalArtifactStore(
    allowedSourceRoots: [adapter.session.directoryPath],
    maximumArtifactBytes: maximumAuthoringArtifactBytesV1,
  );
  final loader = ProjectSnapshotLoader(handles: handles);
  final api = LocalMapAuthoringMutationApi(
    policy: policy,
    snapshotLoader: loader,
    artifactStore: artifacts,
  );
  String? artifactHandle;
  try {
    await api.attachProject(
      projectRootPath: adapter.session.directoryPath,
      workspaceHandle: opened.workspaceHandle,
      projectHandle: opened.projectHandle,
    );
    final snapshot = await loader.load(
      opened.projectHandle,
      policy: ProjectSnapshotLoadPolicy.editorReadProjection,
    );
    adapter._requireAvailable();
    if ((expectedSnapshotRevision != null &&
            snapshot.revision != expectedSnapshotRevision) ||
        narrativeEventBytesFingerprint(snapshot.resourceBytes('project')) !=
            before.revision) {
      throw const ResourceFailure(
        'Le projet a changé depuis l’ouverture. Votre saisie est conservée.',
      );
    }
    final fields = Map<String, Object?>.from(parameters);
    Uint8List? beforeBytes;
    if (replacement != null) {
      final staged = await artifacts.put(
        replacement.bytes,
        declaredMediaType: 'image/png',
      );
      artifactHandle = staged.reference.handle;
      fields['artifactHandle'] = artifactHandle;
      final tileset = snapshot.manifest.tilesets
          .where((t) => t.id == replacement.tilesetId)
          .firstOrNull;
      if (tileset == null) {
        throw const ResourceFailure('Cette planche n’existe plus.');
      }
      final catalogBytes = snapshot.findResourceBytes('assetCatalog');
      if (catalogBytes == null) {
        throw const ResourceFailure(
          'Le catalogue des images est indisponible.',
        );
      }
      final catalog = AssetCatalog.fromJson(
        jsonDecode(utf8.decode(catalogBytes)) as Map<String, dynamic>,
      );
      final records = catalog.records
          .where((a) => a.logicalPath == tileset.relativePath)
          .toList();
      if (records.length != 1) {
        throw const ResourceFailure('La source de cette planche est ambiguë.');
      }
      beforeBytes = Uint8List.fromList(
        snapshot.resourceBytes(
          assetBlobResourceIdentity(records.single.artifact.digest),
        ),
      );
    }
    final id = adapter._identity('resource_preview');
    final planned = await api.planMutation(
      opened.projectHandle,
      AuthoringRequest(
        requestId: id,
        actionId: actionId,
        actionVersion: 1,
        workspaceHandle: opened.workspaceHandle.value,
        parameters: fields,
        expectedRevision: snapshot.revision,
        idempotencyKey: id,
      ),
    );
    adapter._requireAvailable();
    final mapPaths = before.manifest.maps.map((m) => m.relativePath).toSet();
    if (planned.plan.changeSet.changes.any(
      (c) => c.resource.kind == 'map' || mapPaths.contains(c.storageKey),
    )) {
      throw const ResourceFailure(
        'Cette opération exige le propriétaire de la carte concernée.',
      );
    }
    final preparation = ResourceMutationPreparation(
      sessionId: adapter.session.sessionId,
      actionId: actionId,
      parameters: fields,
      snapshotRevision: snapshot.revision,
      manifestRevision: before.revision,
      changedPaths: planned.plan.changeSet.changes
          .map((c) => c.storageKey)
          .toList(),
      confirmationRequired:
          planned.plan.changeSet.changes.isNotEmpty &&
          api
                  .describeMutationContracts()
                  .actions
                  .firstWhere((a) => a.id == actionId)
                  .riskLevel ==
              AuthoringRiskLevel.high,
      impact: {...planned.plan.preview, ...planned.plan.referenceImpact},
    );
    adapter._prepared[preparation] = _ResourcePreparedContext(
      handles: handles,
      opened: opened,
      api: api,
      artifacts: artifacts,
      plan: planned.plan,
      manifest: before.manifest,
      artifactHandle: artifactHandle,
      beforeBytes: beforeBytes,
    );
    return preparation;
  } on Object catch (error) {
    if (artifactHandle != null) await artifacts.release(artifactHandle);
    await api.detachWorkspace(opened.workspaceHandle);
    handles.closeWorkspace(opened.workspaceHandle);
    if (error is ResourceFailure) rethrow;
    throw _resourceFailure(error);
  }
});

Future<ResourceReplacementPreview> _prepareResourceReplacement(
  LocalResourceAdapter adapter,
  ResourceReplacementRequest request,
) async {
  final preparation = await _prepareLifecycleOperation(
    adapter,
    'tileset.source.replace',
    {'tilesetId': request.tilesetId},
    replacement: request,
  );
  final retained = adapter._prepared[preparation]!;
  final source =
      retained.manifest.tilesets
              .firstWhere((t) => t.id == request.tilesetId)
              .source
          as ProjectRegularAtlasTilesetSource;
  return ResourceReplacementPreview(
    preparation: preparation,
    beforeBytes: retained.beforeBytes!,
    candidateBytes: request.bytes,
    width: source.pixelWidth,
    height: source.pixelHeight,
    impact: preparation.impact,
  );
}
