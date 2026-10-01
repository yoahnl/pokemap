import 'dart:convert';
import 'dart:math';

import 'package:map_authoring/map_authoring.dart' show MapAuthoringException;
import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_authoring/map_authoring_documents.dart';
import 'package:map_core/map_core.dart';

import '../../project_session/domain/project_session.dart';
import '../domain/map_catalog_port.dart';
import '../domain/map_workspace_port.dart';
import 'local_map_workspace_adapter.dart';

final class LocalMapCatalogAdapter implements MapCatalogPort {
  LocalMapCatalogAdapter(this.mapAdapter, {this.profileSink});

  final LocalMapWorkspaceAdapter mapAdapter;
  final ProjectSnapshotLoadProfileSink? profileSink;
  final snapshotCache = ProjectSnapshotCache();
  final _fingerprintCache = ProjectSnapshotFingerprintCache();
  static const _actions = {
    'map.create',
    'map.update_metadata',
    'map.library.reorganize',
    'map.delete_apply',
  };

  @override
  Future<MapCatalogReceipt> mutate(
    ProjectSession session,
    String actionId,
    Map<String, Object?> parameters, {
    Map<String, String> expectedMapRevisions = const {},
    bool confirmDestructive = false,
    ProjectManifest? expectedManifest,
  }) => mapAdapter.withResourceMutation(() async {
    if (!_actions.contains(actionId)) {
      throw const MapWorkspaceFailure(
        MapWorkspaceProblem.unavailable,
        'Cette opération de catalogue n’est pas disponible.',
      );
    }
    final before = await mapAdapter.resourceBaseline(session);
    if (expectedManifest != null && before.manifest != expectedManifest) {
      throw const MapWorkspaceFailure(
        MapWorkspaceProblem.conflict,
        'Le catalogue a changé depuis son ouverture. Rien n’a été publié.',
      );
    }
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
    final snapshots = ProjectSnapshotLoader(
      handles: handles,
      snapshotCache: snapshotCache,
      fingerprintCache: _fingerprintCache,
      profileSink: profileSink,
    );
    final api = LocalMapAuthoringMutationApi(
      policy: policy,
      snapshotLoader: snapshots,
    );
    var attached = false;
    try {
      await api.attachProject(
        projectRootPath: session.directoryPath,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle,
      );
      attached = true;
      final snapshot = await snapshots.load(
        opened.projectHandle,
        policy: ProjectSnapshotLoadPolicy.editorReadProjection,
      );
      if (narrativeEventBytesFingerprint(snapshot.resourceBytes('project')) !=
          before.revision) {
        throw const MapWorkspaceFailure(
          MapWorkspaceProblem.conflict,
          'Le projet a changé. Aucune modification n’a été publiée.',
        );
      }
      for (final entry in expectedMapRevisions.entries) {
        if (narrativeEventBytesFingerprint(
              snapshot.resourceBytes('map:${entry.key}'),
            ) !=
            entry.value) {
          throw const MapWorkspaceFailure(
            MapWorkspaceProblem.conflict,
            'La carte a changé sur le disque. Votre travail reste ouvert.',
          );
        }
      }
      final id =
          'catalog_${DateTime.now().microsecondsSinceEpoch}_${Random.secure().nextInt(1 << 32)}';
      final planned = await api.planMutation(
        opened.projectHandle,
        AuthoringRequest(
          requestId: id,
          actionId: actionId,
          actionVersion: 1,
          workspaceHandle: opened.workspaceHandle.value,
          parameters: parameters,
          expectedRevision: snapshot.revision,
          idempotencyKey: id,
        ),
      );
      final changes = planned.plan.changeSet.changes;
      final manifestBytes = changes
          .where((change) => change.storageKey == 'project.json')
          .firstOrNull
          ?.afterBytes;
      final manifest = manifestBytes == null
          ? before.manifest
          : ProjectManifest.fromJson(
              jsonDecode(utf8.decode(manifestBytes)) as Map<String, dynamic>,
            );
      final documents = <String, MapWorkspaceDocument>{};
      for (final change in changes.where((c) => c.resource.kind == 'map')) {
        final bytes = change.afterBytes;
        if (bytes == null) continue;
        final map = decodeValidatedMapDocument(
          bytes,
          change.storageKey,
          validateMap: (map) =>
              MapValidator.validate(map, projectDialogueContext: manifest),
        );
        documents[map.id] = MapWorkspaceDocument(
          map: map,
          mapId: map.id,
          revision: narrativeEventBytesFingerprint(bytes),
        );
      }
      final receipt = MapCatalogReceipt(
        before: before.manifest,
        manifest: manifest,
        beforeRevision: before.revision,
        revision: manifestBytes == null
            ? before.revision
            : narrativeEventBytesFingerprint(manifestBytes),
        changedPaths: List.unmodifiable(changes.map((c) => c.storageKey)),
        documents: Map.unmodifiable(documents),
        createdMapId: actionId == 'map.create'
            ? parameters['mapId'] as String?
            : null,
      );
      try {
        final confirmation = confirmDestructive
            ? await api.confirmMutation(
                opened.projectHandle,
                planId: planned.planId,
              )
            : null;
        await api.applyMutation(
          opened.projectHandle,
          planId: planned.planId,
          operationId: id,
          confirmationToken: confirmation?.confirmationToken,
        );
      } on Object catch (failure, stack) {
        late final AuthoringMutationResult recovered;
        try {
          recovered = await api.recoverMutation(
            opened.projectHandle,
            operationId: id,
          );
        } on Object {
          Error.throwWithStackTrace(failure, stack);
        }
        if (recovered.receipt.status.name != 'applied' &&
            recovered.receipt.extensions['recoveryOutcome'] != 'resumed') {
          rethrow;
        }
      }
      return receipt;
    } on MapAuthoringException catch (failure) {
      if (failure.code != 'map.no_change') rethrow;
      await mapAdapter.resourceBaseline(session);
      return MapCatalogReceipt(
        before: before.manifest,
        manifest: before.manifest,
        beforeRevision: before.revision,
        revision: before.revision,
        changedPaths: const [],
      );
    } finally {
      if (attached) await api.detachWorkspace(opened.workspaceHandle);
      handles.closeWorkspace(opened.workspaceHandle);
    }
  });

  @override
  Future<void> reconcile(ProjectSession session, MapCatalogReceipt receipt) =>
      mapAdapter.withResourceMutation(
        () => mapAdapter.acceptCatalogMutation(session, receipt),
      );
}
