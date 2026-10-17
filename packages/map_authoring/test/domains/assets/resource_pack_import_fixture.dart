import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/src/infrastructure/local_resource_pack_store.dart';
import 'package:map_authoring/src/ports/file_backed_payload_store.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';

import 'resource_pack_export_test.dart' as source;

final class ResourcePackImportFixture {
  ResourcePackImportFixture._(
      this.directory, this.store, this.archive, this.preparer, this.snapshot);
  final Directory directory;
  final LocalResourcePackStore store;
  final OwnedResourcePackExport archive;
  final ResourcePackImportPreparer preparer;
  ProjectSnapshot snapshot;
  static const scope =
      FileBackedPayloadScope(sessionId: 'session', projectId: 'project');
  static const workspace = 'workspace';

  static Future<ResourcePackImportFixture> create({
    Iterable<NativeResourcePackRef>? roots,
    ProjectManifest? target,
    ProjectManifest? sourceManifest,
    List<NativeResourcePackFile>? sourceFiles,
    DateTime Function()? clock,
    Future<ProjectResourceProbe> Function(String)? probe,
    ResourcePackMetadata? metadata,
    NativeResourcePackAttribution? attribution,
    Iterable<String> smartTilePatternIds = const [],
  }) async {
    final directory = await Directory.systemTemp.createTemp('p08-test-');
    final store = LocalResourcePackStore(
        cacheDirectory: '${directory.path}/cache',
        allowedSourceRoots: const [],
        clock: clock);
    final mixed = source.mixedFixture();
    final projection = await ResourcePackProjectionBuilder().project(
      manifest: sourceManifest ?? mixed.$1,
      files: sourceFiles ?? mixed.$2,
      roots: roots ??
          [
            for (final root in [
              (ResourcePackKind.element, 'decor'),
              (ResourcePackKind.model3d, 'model'),
              (ResourcePackKind.smartTilePreset, 'sol'),
              (ResourcePackKind.tileset, 'atlas'),
              (ResourcePackKind.borderBlueprint, 'border'),
              (ResourcePackKind.environmentPreset, 'environment'),
              (ResourcePackKind.character, 'person')
            ])
              NativeResourcePackRef(kind: root.$1, id: root.$2)
          ],
      smartTilePatternIds: smartTilePatternIds,
      author: 'Original',
      attribution: attribution,
      sourceRevision: 'revision',
      localLicenses: attribution == null
          ? [fixtureLicense('Licensed for this fixture')]
          : [],
    );
    final archive =
        await CanonicalResourcePackExportService(store: store, scope: scope)
            .export(
                projection: projection,
                metadata: metadata ?? source.metadata(),
                expectedRevision: 'revision',
                readCurrentRevision: () async => 'revision');
    var snapshot = makeSnapshot(target ??
        ProjectManifest(
            name: 'Target',
            maps: [],
            tilesets: [],
            settings: ProjectSettings(tileWidth: 2, tileHeight: 2)));
    late ResourcePackImportFixture fixture;
    final preparer = ResourcePackImportPreparer(
        store: store,
        scope: scope,
        workspaceHandle: workspace,
        loadSnapshot: () async => fixture.snapshot,
        probeResource:
            probe ?? (_) async => const ProjectResourceProbe.missing(),
        clock: clock);
    fixture = ResourcePackImportFixture._(
        directory, store, archive, preparer, snapshot);
    return fixture;
  }

  Future<ResourcePackImportSelection> select({List<ResourcePackRef>? roots}) =>
      preparer.select(
          archiveHandle: archive.payload.handle,
          roots: roots ??
              [
                for (final kind in ResourcePackKind.values)
                  ResourcePackRef(kind: kind, id: _portableRoot(kind))
              ]);
  String _portableRoot(ResourcePackKind kind) => switch (kind) {
        ResourcePackKind.element =>
          archive.inspection.catalog.elements.first.id,
        ResourcePackKind.model3d =>
          archive.inspection.catalog.models3d.first.id,
        ResourcePackKind.smartTilePreset =>
          archive.inspection.catalog.smartTileCatalog.presets.first.id,
        ResourcePackKind.tileset =>
          archive.inspection.catalog.tilesets.first.id,
        ResourcePackKind.borderBlueprint =>
          archive.inspection.catalog.borderCatalog.records.first.id,
        ResourcePackKind.environmentPreset =>
          archive.inspection.catalog.environmentPresets.first.id,
        ResourcePackKind.character =>
          archive.inspection.catalog.characters.first.id,
      };
  Future<ResourcePackPreparedImport> prepare(
      {ResourcePackImportSelection? selection,
      ResourcePackConflictPolicy policy =
          ResourcePackConflictPolicy.preserveProject}) async {
    final selected = selection ?? await select();
    return preparer.prepare(
        selectionHandle: selected.handle,
        selectionRevision: selected.revision,
        expectedRevision: snapshot.revision,
        conflictPolicy: policy);
  }

  AuthoringRequest request(String handle,
          {bool dryRun = false, String key = 'import'}) =>
      AuthoringRequest(
          requestId: key,
          actionId: 'resource_pack.import',
          actionVersion: 1,
          workspaceHandle: workspace,
          expectedRevision: snapshot.revision,
          idempotencyKey: key,
          dryRun: dryRun,
          parameters: {'preparedImportHandle': handle});
  Future<void> dispose() async {
    await preparer.dispose();
    await archive.dispose();
    await store.close();
    if (await directory.exists()) await directory.delete(recursive: true);
  }
}

ProjectSnapshot makeSnapshot(ProjectManifest manifest,
    {Map<String, List<int>> resources = const {},
    Map<String, String> storageKeys = const {}}) {
  final bytes = {
    'project': utf8.encode(jsonEncode(manifest.toJson())),
    ...resources
  };
  final fingerprints = {
    for (final entry in bytes.entries)
      entry.key: computeAuthoringBytesFingerprint(entry.value,
          logicalName:
              entry.key == 'project' ? 'project.json' : storageKeys[entry.key]!)
  };
  return ProjectSnapshot(
      projectHandle: ProjectHandle('project_handle'),
      revision: computeAuthoringJsonFingerprint(fingerprints,
          logicalName: 'test-project'),
      manifest: manifest,
      maps: const [],
      resourceBytes: bytes,
      resourceFingerprints: fingerprints,
      resourceStorageKeys: {'project': 'project.json', ...storageKeys});
}

final class NativeResourcePackImportFixture {
  NativeResourcePackImportFixture._(
      this.source, this.root, this.clock, this.faultInjector);
  final ResourcePackImportFixture source;
  final Directory root;
  final DateTime Function()? clock;
  final AuthoringTransactionFaultInjector? faultInjector;
  late WorkspaceHandleStore handles;
  late ProjectSnapshotLoader loader;
  late LocalMapAuthoringMutationApi mutations;
  late OpenedProject opened;
  late ResourcePackImportPreparer preparer;
  late AuthoringReadApi readApi;
  FileBackedPayloadLease? staged;
  int sequence = 0;
  static Future<NativeResourcePackImportFixture> create({
    ProjectManifest? sourceManifest,
    ResourcePackMetadata? metadata,
    NativeResourcePackAttribution? attribution,
    Iterable<String> smartTilePatternIds = const [],
    List<NativeResourcePackFile>? sourceFiles,
    Iterable<NativeResourcePackRef>? roots,
    ProjectManifest? target,
    DateTime Function()? clock,
    AuthoringTransactionFaultInjector? faultInjector,
    Directory? nativeRoot,
  }) async {
    final fixture = await ResourcePackImportFixture.create(
        sourceManifest: sourceManifest,
        attribution: attribution,
        metadata: metadata,
        smartTilePatternIds: smartTilePatternIds,
        sourceFiles: sourceFiles,
        roots: roots,
        target: target,
        clock: clock);
    final root =
        await (nativeRoot ?? Directory('${fixture.directory.path}/native'))
            .create();
    await File('${root.path}/project.json').writeAsString(jsonEncode({
      ...fixture.snapshot.manifest.toJson(),
      'unknownNativeMetadata': {
        'keep': ['verbatim', 7]
      },
    }));
    final native =
        NativeResourcePackImportFixture._(fixture, root, clock, faultInjector);
    await native.open();
    await native.stage();
    return native;
  }

  Future<void> open({AuthoringActor? actor}) async {
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path], fileReader: reader);
    handles = WorkspaceHandleStore(clock: clock);
    loader = ProjectSnapshotLoader(handles: handles);
    final service = ProjectOpenService(
        policy: policy, fileReader: reader, handles: handles);
    readApi = AuthoringReadApi(openService: service, snapshotLoader: loader);
    opened = await service.openProject(root.path);
    mutations = LocalMapAuthoringMutationApi(
        policy: policy,
        snapshotLoader: loader,
        clock: clock,
        faultInjector: faultInjector,
        actor: actor);
    await mutations.attachProject(
        projectRootPath: root.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle);
    preparer = mutations.resourcePackImports(opened.projectHandle);
  }

  Future<void> stage() async {
    final store = mutations.resourcePackPayloadStore(opened.projectHandle);
    staged = await source.archive.withSource((source) => store.stage(
        scope: preparer.scope,
        byteLength: source.length,
        chunks: sourceChunks(source)));
  }

  Future<ResourcePackImportSelection> select({List<ResourcePackRef>? roots}) =>
      preparer.select(
          archiveHandle: staged!.payload.handle,
          roots: roots ??
              [
                for (final kind in ResourcePackKind.values)
                  ResourcePackRef(kind: kind, id: source._portableRoot(kind))
              ]);
  Future<ResourcePackPreparedImport> prepare(
      {ResourcePackImportSelection? selection,
      ResourcePackConflictPolicy policy =
          ResourcePackConflictPolicy.preserveProject}) async {
    final selected = selection ?? await select();
    return preparer.prepare(
        selectionHandle: selected.handle,
        selectionRevision: selected.revision,
        expectedRevision: (await loader.load(opened.projectHandle)).revision,
        conflictPolicy: policy);
  }

  Future<AuthoringMutationPlanResult> plan(ResourcePackPreparedImport prepared,
      {bool dryRun = false, Map<String, Object?>? parameters}) async {
    final requestId = 'import-${sequence++}';
    return mutations.planMutation(
        opened.projectHandle,
        AuthoringRequest(
            requestId: requestId,
            actionId: 'resource_pack.import',
            actionVersion: 1,
            workspaceHandle: opened.workspaceHandle.value,
            expectedRevision:
                (await loader.load(opened.projectHandle)).revision,
            idempotencyKey: requestId,
            dryRun: dryRun,
            parameters: parameters ??
                {'preparedImportHandle': prepared.preparedImportHandle}));
  }

  Future<AuthoringMutationResult> apply(AuthoringMutationPlanResult plan,
      {String? operationId}) async {
    final confirmed = await mutations.confirmMutation(opened.projectHandle,
        planId: plan.planId);
    return mutations.applyMutation(opened.projectHandle,
        planId: plan.planId,
        operationId: operationId ?? 'operation-${sequence++}',
        confirmationToken: confirmed.confirmationToken);
  }

  Future<void> close() async {
    await mutations.detachWorkspace(opened.workspaceHandle);
    handles.closeWorkspace(opened.workspaceHandle);
    staged = null;
  }

  Future<void> dispose() async {
    await close();
    await source.dispose();
  }
}

Stream<List<int>> sourceChunks(RandomAccessPackageSource source) async* {
  for (var start = 0; start < source.length; start += 64 * 1024) {
    final length = source.length - start;
    yield source.readAtSync(start, length > 64 * 1024 ? 64 * 1024 : length);
  }
}

Future<AuthoringReceipt> redoNativeImport(
    NativeResourcePackImportFixture fixture, String entryId) async {
  final root = fixture.root.path;
  final history = await FileAuthoringHistoryStore.open(projectRoot: root);
  final blobs = await FileAuthoringContentBlobStore.open(projectRoot: root);
  final gateway = await LocalTransactionFileGateway.open(projectRoot: root);
  final plans = AuthoringPlanStore();
  final confirmations = AuthoringConfirmationStore(clock: DateTime.now);
  final policy = AuthoringAuthorizationPolicy(
      confirmations: confirmations, clock: DateTime.now);
  final ledger = AuthoringIdempotencyLedger(
      store: FileIdempotencyStore(
          filePath: '$root/.pokemap/authoring/idempotency.jsonl'));
  final transaction = JournaledAuthoringTransaction(
      plans: plans,
      gateway: gateway,
      idempotency: ledger,
      clock: DateTime.now,
      faultInjector: fixture.faultInjector,
      commitHook: AuthoringHistoryRecorder(store: history, blobs: blobs));
  final audit = await FileAuthoringAuditLog.open(projectRoot: root);
  var sequence = 0;
  final executor = SecureAuthoringMutationExecutor(
      transaction: transaction,
      policy: policy,
      auditLog: audit,
      clock: DateTime.now,
      auditIdFactory: () => 'redo-audit-${sequence++}');
  final undo = AuthoringUndoService(
      history: history,
      blobs: blobs,
      gateway: gateway,
      planner: AuthoringActionPlanner(store: plans),
      policy: policy,
      executor: executor,
      tokenFactory: (prefix) => '${prefix}p08-${sequence++}');
  try {
    final actor = AuthoringActor(
        actorId: 'local_cli', permissions: AuthoringPermissionScope.values);
    final prepared = await undo.planRedo(
        actor: actor,
        projectId: fixture.preparer.scope.projectId,
        entryId: entryId,
        snapshot: await fixture.loader.load(fixture.opened.projectHandle),
        workspaceHandle: fixture.opened.workspaceHandle.value,
        idempotencyKey: 'redo-native-import');
    final confirmation = confirmations.issue(
        AuthoringConfirmationBinding.forPlan(
            actorId: actor.actorId,
            projectId: fixture.preparer.scope.projectId,
            plan: prepared.plan));
    return await undo.apply(prepared, confirmationToken: confirmation);
  } finally {
    await plans.dispose();
  }
}

ResourcePackBuildSource fixtureLicense(String text) {
  final bytes = utf8.encode(text);
  final hash = sha256.convert(bytes).toString();
  return ResourcePackBuildSource(
      path: 'licenses/$hash.txt',
      byteLength: bytes.length,
      rawSha256: hash,
      mediaType: 'text/plain',
      openRead: () => Stream.value(bytes));
}
