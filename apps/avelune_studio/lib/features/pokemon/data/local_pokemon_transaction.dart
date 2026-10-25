import 'dart:convert';
import 'dart:math';

import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_authoring/map_authoring.dart'
    show AuthoringTransactionFaultInjector, ProjectSnapshot;
import 'package:map_core/map_core.dart';

import '../../map_workspace/data/local_map_workspace_adapter.dart';
import '../../map_workspace/domain/map_workspace_port.dart';
import '../../project_session/data/studio_project_document_revision.dart';
import '../../project_session/domain/project_session.dart';
import '../../resources/domain/resource_port.dart';

final class LocalPokemonTransaction {
  const LocalPokemonTransaction({
    required this.session,
    required this.mapAdapter,
    required this.reader,
    this.faultInjector,
  });

  final ProjectSession session;
  final LocalMapWorkspaceAdapter mapAdapter;
  final ProjectFileReader reader;
  final AuthoringTransactionFaultInjector? faultInjector;

  Future<String?> run({
    required String actionId,
    required Map<String, Object?> parameters,
    required void Function(ProjectSnapshot) validateBefore,
    required void Function(ProjectSnapshot) validateAfter,
    required Set<String> Function(ProjectSnapshot) allowedStorageKeys,
  }) => mapAdapter.withResourceMutation(() async {
    ({ProjectManifest manifest, String revision})? baseline;
    String? baselineWarning;
    try {
      baseline = await mapAdapter.resourceBaseline(session);
    } on MapWorkspaceFailure catch (failure) {
      if (failure.problem == MapWorkspaceProblem.conflict) {
        baselineWarning = failure.message;
      } else if (failure.problem != MapWorkspaceProblem.unavailable) {
        rethrow;
      }
    }
    final fields = jsonDecode(jsonEncode(parameters)) as Map<String, dynamic>;
    final scoped = session.storage == ProjectSessionStorage.workingCatalog;
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [session.directoryPath],
      fileReader: reader,
    );
    final handles = WorkspaceHandleStore();
    final opened = await ProjectOpenService(
      policy: policy,
      fileReader: reader,
      handles: handles,
      catalogMetadataFields: const {},
      workshopScope: true,
    ).openProject(session.directoryPath);
    final snapshots = ProjectSnapshotLoader(handles: handles);
    final api = LocalMapAuthoringMutationApi(
      policy: policy,
      snapshotLoader: snapshots,
      faultInjector: faultInjector,
      catalogFileReader: reader,
    );
    var attached = false;
    try {
      await api.attachProject(
        projectRootPath: session.directoryPath,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle,
      );
      attached = true;
      Future<ProjectSnapshot> read() => api.readWorkshopSnapshot(
          opened.projectHandle, actionId: actionId, parameters: fields);
      final snapshot = await read();
      validateBefore(snapshot);
      if (baseline != null && await _revision() != baseline.revision) {
        throw StateError(
          'Le projet a changé sur le disque. Votre brouillon est conservé.',
        );
      }
      final operation =
          'studio_pokemon_${DateTime.now().microsecondsSinceEpoch}_${Random.secure().nextInt(1 << 32)}';
      final planned = await api.planMutation(
        opened.projectHandle,
        AuthoringRequest(
          requestId: operation,
          actionId: actionId,
          actionVersion: 1,
          extensions: const {'workshopScope': true},
          workspaceHandle: opened.workspaceHandle.value,
          expectedRevision: snapshot.revision,
          idempotencyKey: operation,
          parameters: fields,
        ),
      );
      final allowed = allowedStorageKeys(snapshot);
      final changes = planned.plan.changeSet.changes;
      if (changes.any(
        (change) =>
            !allowed.contains(change.storageKey) &&
            !(scoped &&
                change.storageKey == CatalogStorageStore.headStorageKey),
      )) {
        throw StateError('La mutation vise une ressource inattendue.');
      }
      final confirmation = actionId.endsWith('.delete')
          ? await api.confirmMutation(
              opened.projectHandle,
              planId: planned.planId,
            )
          : null;
      AuthoringMutationResult? committed;
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
          throw StateError(
            'Écriture interrompue ; journal $operation conservé : $failure',
          );
        }
      }
      final revisionBeforeReopen = await _revision();
      final reopened = await read();
      if (reopened.revision != committed.snapshotRevision) {
        throw StateError(
          'Le reçu ne correspond pas à la version enregistrée. Votre brouillon est conservé.',
        );
      }
      validateAfter(reopened);
      final revision = await _revision();
      if (revision != revisionBeforeReopen) {
        return 'Enregistrement confirmé ; le projet a changé avant l’actualisation de l’atelier.';
      }
      if (baseline != null) {
        final manifest = mergeProjectMetadataSections(
                baseline.manifest,
                reopened.manifest,
                reopened.availableProjectSections!,
                documentIds: reopened.availableProjectDocuments,
              );
        try {
          await mapAdapter.acceptResourceMutation(
            session,
            ResourceMutationReceipt(
              before: baseline.manifest,
              manifest: manifest,
              beforeRevision: baseline.revision,
              revision: revision,
              changedPaths: [for (final change in changes) change.storageKey],
              operationId: operation,
              actionId: actionId,
            ),
          );
        } on Object catch (failure) {
          return 'Enregistrement confirmé ; actualisation de l’atelier impossible : $failure';
        }
      }
      return baselineWarning == null
          ? null
          : 'Enregistrement confirmé ; actualisation de l’atelier impossible : $baselineWarning';
    } finally {
      if (attached) await api.detachWorkspace(opened.workspaceHandle);
      handles.closeWorkspace(opened.workspaceHandle);
    }
  });

  Future<T> analyze<T>(Future<T> Function(ProjectSnapshot) operation) async {
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
    try {
      return await operation(
        await ProjectSnapshotLoader(handles: handles).load(
          opened.projectHandle,
          policy: ProjectSnapshotLoadPolicy.editorReadProjection,
        ),
      );
    } finally {
      handles.closeWorkspace(opened.workspaceHandle);
    }
  }

  Future<String> _revision() async => studioProjectDocumentRevision(
    descriptorBytes: await reader.readBytes(
      projectRoot: session.directoryPath,
      relativePath: 'project.json',
    ),
    headBytes: session.storage == ProjectSessionStorage.workingCatalog
        ? await reader.readBytes(
            projectRoot: session.directoryPath,
            relativePath: CatalogStorageStore.headStorageKey,
          )
        : null,
  );
}
