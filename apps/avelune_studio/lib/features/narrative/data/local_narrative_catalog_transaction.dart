import 'dart:convert';
import 'dart:math';

import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_authoring/map_authoring.dart'
    show AuthoringTransactionFaultInjector, ProjectSnapshot;
import 'package:map_core/map_core.dart';

import '../../map_workspace/data/local_map_workspace_adapter.dart';
import '../../map_workspace/domain/map_workspace_workshop.dart';
import '../../project_session/domain/project_session.dart';
import '../../resources/domain/resource_port.dart';

class LocalNarrativeCatalogTransaction {
  const LocalNarrativeCatalogTransaction({
    required this.session,
    required this.mapAdapter,
    this.faultInjector,
  });
  final ProjectSession session;
  final LocalMapWorkspaceAdapter mapAdapter;
  final AuthoringTransactionFaultInjector? faultInjector;

  Future<ResourceMutationReceipt> run({
    required String actionId,
    required Map<String, Object?> Function(ProjectManifest) parameters,
    void Function(ProjectManifest, List<MapData>)? validate,
    void Function(ProjectSnapshot)? validateSnapshot,
    bool refreshCatalog = false,
    Set<String> allowedStorageKeys = const {},
  }) => mapAdapter.withResourceMutation(() async {
    final baseline = await mapAdapter.resourceBaseline(
      session,
      refreshCatalog: refreshCatalog,
    );
    final fields = parameters(baseline.manifest);
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
      catalogMetadataFields:
          session.storage == ProjectSessionStorage.workingCatalog
          ? const {}
          : null,
    ).openProject(session.directoryPath);
    final snapshots = ProjectSnapshotLoader(handles: handles);
    final api = LocalMapAuthoringMutationApi(
      policy: policy,
      snapshotLoader: snapshots,
      faultInjector: faultInjector,
    );
    var attached = false;
    try {
      await api.attachProject(
        projectRootPath: session.directoryPath,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle,
      );
      attached = true;
      final scoped = session.storage == ProjectSessionStorage.workingCatalog;
      final snapshot = scoped
          ? await api.readWorkshopSnapshot(
              opened.projectHandle,
              actionId: actionId,
              parameters: fields,
            )
          : await snapshots.load(opened.projectHandle);
      validate?.call(snapshot.manifest, snapshot.maps);
      validateSnapshot?.call(snapshot);
      if ((scoped
              ? await mapAdapter.resourceRevision(session)
              : narrativeEventBytesFingerprint(
                  snapshot.resourceBytes('project'),
                )) !=
          baseline.revision) {
        throw const NarrativeCatalogFailure(
          'Le projet a changé sur le disque. Le brouillon reste ouvert.',
        );
      }
      final operation =
          'catalog_${DateTime.now().microsecondsSinceEpoch}_${Random.secure().nextInt(1 << 32)}';
      final planned = await api.planMutation(
        opened.projectHandle,
        AuthoringRequest(
          requestId: operation,
          actionId: actionId,
          actionVersion: 1,
          extensions: session.storage == ProjectSessionStorage.workingCatalog
              ? const {'workshopScope': true}
              : const {},
          workspaceHandle: opened.workspaceHandle.value,
          expectedRevision: snapshot.revision,
          idempotencyKey: operation,
          parameters: jsonDecode(jsonEncode(fields)) as Map<String, dynamic>,
        ),
      );
      final changes = planned.plan.changeSet.changes;
      if (changes.any(
        (change) =>
            change.storageKey != 'project.json' &&
            !allowedStorageKeys.contains(change.storageKey) &&
            !(scoped &&
                change.storageKey == CatalogStorageStore.headStorageKey),
      )) {
        throw const NarrativeCatalogFailure(
          'La publication narrative a une portée inattendue.',
        );
      }
      final projectBytes = scoped
          ? null
          : changes
                    .where((change) => change.storageKey == 'project.json')
                    .firstOrNull
                    ?.afterBytes ??
                snapshot.resourceBytes('project');
      final manifest = scoped
          ? mergeProjectMetadataSections(
              baseline.manifest,
              planned.projectedProject ?? snapshot.manifest,
              snapshot.availableProjectSections!,
            )
          : ProjectManifest.fromJson(
              jsonDecode(utf8.decode(projectBytes!)) as Map<String, dynamic>,
            );
      AuthoringMutationResult? committed;
      if (changes.isNotEmpty) {
        final confirmation =
            const {
              'regionalMap.region.delete',
              'regionalMap.poi.delete',
              'storyline.delete',
              'event_v2.delete',
              'cinematic.delete',
              'cinematicLibraryAsset.delete',
            }.contains(actionId)
            ? await api.confirmMutation(
                opened.projectHandle,
                planId: planned.planId,
              )
            : null;
        try {
          committed = await api.applyMutation(
            opened.projectHandle,
            planId: planned.planId,
            operationId: operation,
            confirmationToken: confirmation?.confirmationToken,
          );
        } on Object catch (failure) {
          try {
            committed = await api.recoverMutation(
              opened.projectHandle,
              operationId: operation,
            );
          } on Object {
            throw NarrativeCatalogFailure(
              'Publication interrompue. Journal $operation conservé, brouillon ouvert : $failure',
            );
          }
        }
      }
      final actualRevision = await mapAdapter.resourceRevision(session);
      if (scoped) {
        final reopened = await api.readWorkshopSnapshot(
          opened.projectHandle,
          actionId: actionId,
          parameters: fields,
        );
        if (reopened.revision !=
                (committed == null
                    ? snapshot.revision
                    : committed.snapshotRevision) ||
            await mapAdapter.resourceRevision(session) != actualRevision ||
            mergeProjectMetadataSections(
                  baseline.manifest,
                  reopened.manifest,
                  reopened.availableProjectSections!,
                ) !=
                manifest) {
          throw const NarrativeCatalogFailure(
            'La publication a changé pendant sa relecture. Le brouillon est conservé.',
          );
        }
      } else if (actualRevision !=
          narrativeEventBytesFingerprint(projectBytes!)) {
        throw const NarrativeCatalogFailure(
          'Le reçu ne correspond pas au projet écrit. Votre brouillon reste ouvert.',
        );
      }
      final receipt = ResourceMutationReceipt(
        before: baseline.manifest,
        manifest: manifest,
        beforeRevision: baseline.revision,
        revision: actualRevision,
        changedPaths: changes.map((change) => change.storageKey).toList(),
      );
      await mapAdapter.acceptResourceMutation(session, receipt);
      return receipt;
    } finally {
      if (attached) await api.detachWorkspace(opened.workspaceHandle);
      handles.closeWorkspace(opened.workspaceHandle);
    }
  });
}

class NarrativeCatalogFailure implements Exception {
  const NarrativeCatalogFailure(this.message);
  final String message;
  @override
  String toString() => message;
}
