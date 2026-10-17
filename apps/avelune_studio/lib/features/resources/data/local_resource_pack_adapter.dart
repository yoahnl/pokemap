import 'dart:async';

import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_authoring/map_authoring.dart'
    show AuthoringTransactionFaultInjector;
import 'package:map_core/map_core.dart';

import '../../map_workspace/data/local_map_workspace_adapter.dart';
import '../../project_session/domain/project_session.dart';
import '../domain/resource_pack_port.dart';
import '../domain/resource_port.dart';
import 'local_resource_adapter.dart';

final class LocalResourcePackAdapter implements ResourcePackPort {
  LocalResourcePackAdapter({
    required this.session,
    required this.mapAdapter,
    required this.resources,
    this.faultInjector,
  });
  final ProjectSession session;
  final LocalMapWorkspaceAdapter mapAdapter;
  final LocalResourceAdapter resources;
  final AuthoringTransactionFaultInjector? faultInjector;
  Future<_PackSession>? _opening;
  bool _disposed = false;
  Future<void>? _disposing;
  ({ProjectManifest manifest, String revision})? _before;
  String? _operationId, _receiptId;
  @override
  String get sessionId => session.sessionId;
  void _requireActive() {
    if (_disposed) throw const ResourceFailure('Le projet a été fermé.');
  }

  Future<_PackSession> _session() {
    _requireActive();
    return _opening ??= _open();
  }

  Future<_PackSession> _open() async {
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [session.directoryPath],
      fileReader: reader,
    );
    final handles = WorkspaceHandleStore();
    final opened = await ProjectOpenService(
      policy: policy,
      fileReader: reader,
      handles: handles,
    ).openProject(session.directoryPath);
    final loader = ProjectSnapshotLoader(handles: handles);
    final mutations = LocalMapAuthoringMutationApi(
      policy: policy,
      snapshotLoader: loader,
      faultInjector: faultInjector,
    );
    try {
      await mutations.attachProject(
        projectRootPath: session.directoryPath,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle,
      );
      final result = _PackSession(
        handles,
        opened,
        loader,
        mutations,
        LocalResourcePackTransferApi(
          mutations: mutations,
          snapshotLoader: loader,
        ),
      );
      return result;
    } on Object {
      handles.closeWorkspace(opened.workspaceHandle);
      rethrow;
    }
  }

  @override
  Future<void> authorizeSource(String path) async {
    final active = await _session();
    _requireActive();
    await active.mutations
        .resourcePackPayloadStore(active.opened.projectHandle)
        .authorizeSourceFile(path);
  }

  @override
  Future<String> captureRevision() async {
    final active = await _session();
    _requireActive();
    return (await active.loader.load(
      active.opened.projectHandle,
      policy: ProjectSnapshotLoadPolicy.editorReadProjection,
    )).revision;
  }

  @override
  Future<Map<String, Object?>> transfer(
    String verb, [
    Map<String, Object?> input = const {},
  ]) async {
    final active = await _session();
    _requireActive();
    return active.transfers.transfer(
      active.opened.projectHandle,
      verb: verb,
      input: input,
    );
  }

  @override
  Future<Map<String, Object?>> query(AuthoringQueryRequest request) async {
    final active = await _session();
    _requireActive();
    return active.transfers.queryTransfer(active.opened.projectHandle, request);
  }

  @override
  Future<ResourceMutationReceipt> applyImport({
    required String preparedHandle,
    required String expectedRevision,
    required String operationId,
    required ResourcePackJobMonitor monitor,
  }) => mapAdapter.withResourceMutation(() async {
    final active = await _session();
    _requireActive();
    final before = await mapAdapter.resourceBaseline(session);
    if (await captureRevision() != expectedRevision) {
      throw const ResourceFailure(
        'Le projet a changé depuis la préparation. Reprenez la sélection.',
      );
    }
    final plan = await active.mutations.planMutation(
      active.opened.projectHandle,
      AuthoringRequest(
        requestId: operationId,
        actionId: 'resource_pack.import',
        actionVersion: 1,
        workspaceHandle: active.opened.workspaceHandle.value,
        expectedRevision: expectedRevision,
        idempotencyKey: operationId,
        parameters: {'preparedImportHandle': preparedHandle},
      ),
    );
    _before = before;
    _operationId = operationId;
    _receiptId = null;
    final result = await monitor(
      await active.transfers.transfer(
        active.opened.projectHandle,
        verb: 'start_apply',
        input: {'planId': plan.planId, 'operationId': operationId},
      ),
    );
    final receiptJson = Map<String, Object?>.from(result['receipt']! as Map);
    _receiptId = receiptJson['receiptId']! as String;
    try {
      return await _acceptApplied(active, result);
    } on ResourceFailure catch (failure) {
      if (failure.partialReceipt != null) rethrow;
      throw ResourcePackCommittedFailure(_receiptId!, failure);
    } on Object catch (failure) {
      throw ResourcePackCommittedFailure(_receiptId!, failure);
    }
  });

  Future<ResourceMutationReceipt> _acceptApplied(
    _PackSession active,
    Map<String, Object?> projection,
  ) async {
    final json = Map<String, Object?>.from(projection['receipt']! as Map);
    if (!const {'applied', 'recovered'}.contains(json['status']) ||
        json['actionId'] != 'resource_pack.import') {
      throw const ResourceFailure(
        'Le reçu ne confirme pas un import appliqué.',
      );
    }
    final snapshot = await active.loader.load(
      active.opened.projectHandle,
      policy: ProjectSnapshotLoadPolicy.editorReadProjection,
    );
    final paths = <String, String?>{}, revisions = <String, String?>{};
    Future<void> consume(List<dynamic> entries) async {
      for (final value in entries) {
        final row = Map<String, Object?>.from(value as Map);
        if (row['resource'] is! Map || row['after'] is! Map) {
          throw const ResourceFailure(
            'Le reçu de l’import ne peut pas être relu.',
          );
        }
        final ref = Map<String, Object?>.from(row['resource']! as Map);
        final kind = ref['kind']! as String, id = ref['id']! as String;
        final identity = switch (kind) {
          'project' => 'project',
          'assetCatalog' => 'assetCatalog',
          'asset'
              when snapshot.resourceStorageKeys.containsKey(
                'assetLogical:$id',
              ) =>
            'assetLogical:$id',
          'assetBlob' => 'assetBlob:$id',
          _ => '$kind:$id',
        };
        final revision = (row['after']! as Map)['revision'] as String?;
        final path = snapshot.resourceStorageKeys[identity];
        if (path == null ||
            revision == null ||
            snapshot.resourceFingerprints[identity] != revision) {
          throw const ResourceFailure(
            'Une ressource importée a changé avant la relecture.',
          );
        }
        paths[path] = revision;
        revisions['$kind:$id'] = revision;
      }
    }

    final diff = Map<String, Object?>.from(json['diff']! as Map);
    if (diff['entries'] is List) {
      await consume(diff['entries']! as List);
    } else {
      var cursor = null as String?;
      do {
        final page = await active.mutations.readMutationDiffPage(
          active.opened.projectHandle,
          diffRef: diff['diffRef']! as String,
          cursor: cursor,
          limit: 100,
        );
        await consume(page['entries']! as List);
        final next = page['nextCursor'] as String?;
        if (next != null && next == cursor) {
          throw const ResourceFailure('Le reçu de l’import ne progresse plus.');
        }
        cursor = next;
      } while (cursor != null);
    }
    _requireActive();
    final before = _before!;
    final receipt = ResourceMutationReceipt(
      before: before.manifest,
      manifest: snapshot.manifest,
      beforeRevision: before.revision,
      revision: narrativeEventBytesFingerprint(
        snapshot.resourceBytes('project'),
      ),
      changedPaths: List.unmodifiable(paths.keys),
      pathRevisions: Map.unmodifiable(paths),
      resourceRevisions: Map.unmodifiable(revisions),
      operationId: _operationId,
      actionId: 'resource_pack.import',
      snapshotBeforeRevision: json['beforeRevision'] as String?,
    );
    try {
      await resources.beforeReconciliation?.call();
      _requireActive();
      await mapAdapter.acceptResourceMutation(session, receipt);
    } on Object catch (failure) {
      throw ResourceFailure(
        'Import terminé — relire la bibliothèque. $failure',
        partialReceipt: receipt,
      );
    }
    return receipt;
  }

  @override
  Future<ResourceMutationReceipt> rereadApplied() =>
      mapAdapter.withResourceMutation(() async {
        final active = await _session();
        var receiptId = _receiptId;
        if (receiptId == null) {
          final recovered = await active.mutations.recoverMutation(
            active.opened.projectHandle,
            operationId: _operationId!,
          );
          receiptId = recovered.receipt.receiptId;
          _receiptId = receiptId;
        }
        return _acceptApplied(
          active,
          await active.mutations.reprojectMutationReceipt(
            active.opened.projectHandle,
            receiptId: receiptId,
          ),
        );
      });
  @override
  Future<void> reconcile(ResourceMutationReceipt receipt) =>
      resources.reconcileReceipt(receipt);
  @override
  Future<void> dispose() => _disposing ??= () async {
    _disposed = true;
    if (_opening != null) {
      final _PackSession active;
      try {
        active = await _opening!;
      } on Object {
        return;
      }
      await active.close();
    }
  }();
}

final class _PackSession {
  _PackSession(
    this.handles,
    this.opened,
    this.loader,
    this.mutations,
    this.transfers,
  );
  final WorkspaceHandleStore handles;
  final OpenedProject opened;
  final ProjectSnapshotLoader loader;
  final LocalMapAuthoringMutationApi mutations;
  final LocalResourcePackTransferApi transfers;
  Future<void> close() async {
    await transfers.closeTransferWorkspace(opened.workspaceHandle);
    await mutations.detachWorkspace(opened.workspaceHandle);
    handles.closeWorkspace(opened.workspaceHandle);
  }
}
