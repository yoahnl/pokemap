import 'package:map_authoring/map_authoring.dart'
    show AuthoringHistoryException, CatalogStorageException;
import 'package:map_authoring/map_authoring_local.dart';

import '../domain/project_history_maintenance.dart';
import '../domain/project_session.dart';

final class LocalProjectHistoryMaintenanceAdapter
    implements ProjectHistoryMaintenancePort {
  @override
  Future<ProjectHistoryMaintenancePreview> preview(
    ProjectSession session,
  ) async {
    final result = await _run(session);
    return ProjectHistoryMaintenancePreview(
      revision: 'sha256:${result['currentRootSha256']}',
      fingerprint: result['fingerprint'] as String,
      retainedOperations: (result['retainedEntryIds'] as List).length,
      expiredOperations: (result['expiredEntryIds'] as List).length,
      retainedBytes: result['retainedLogicalBytes'] as int,
      hasLegacyBarrier: result['legacyBarrierEntryId'] != null,
      blocked: result['blockedReason'] != null,
    );
  }

  @override
  Future<ProjectHistoryMaintenanceResult> apply(
    ProjectSession session,
    ProjectHistoryMaintenancePreview preview,
  ) async {
    final result = await _run(session, preview: preview);
    return ProjectHistoryMaintenanceResult(
      deletedObjects:
          (result['deletedCatalogObjects'] as int) +
          (result['deletedHistoryBlobs'] as int),
      deletedBytes:
          (result['deletedCatalogBytes'] as int) +
          (result['deletedHistoryBlobBytes'] as int),
    );
  }

  Future<Map<String, Object?>> _run(
    ProjectSession session, {
    ProjectHistoryMaintenancePreview? preview,
  }) async {
    if (session.storage != ProjectSessionStorage.workingCatalog) {
      throw const ProjectHistoryMaintenanceFailure(
        'L’entretien est disponible pour les projets à catalogue local.',
      );
    }
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [session.directoryPath],
      fileReader: reader,
    );
    final handles = WorkspaceHandleStore();
    final service = ProjectOpenService(
      policy: policy,
      fileReader: reader,
      handles: handles,
      catalogMetadataFields: const {},
    );
    final opened = await service.openProject(session.directoryPath);
    final mutations = LocalMapAuthoringMutationApi(
      policy: policy,
      snapshotLoader: ProjectSnapshotLoader(handles: handles),
    );
    var attached = false;
    try {
      await mutations.attachProject(
        projectRootPath: session.directoryPath,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle,
      );
      attached = true;
      return await mutations.maintainHistory(
        opened.projectHandle,
        expectedRevision: preview?.revision ?? opened.fingerprint,
        apply: preview != null,
        expectedFingerprint: preview?.fingerprint,
      );
    } on AuthoringHistoryException catch (error) {
      throw ProjectHistoryMaintenanceFailure(switch (error.code) {
        'history.retention_stale' => 'Le projet ou son historique a changé. Relancez l’analyse avant de poursuivre.',
        'history.recovery_required' =>
          'Une écriture interrompue doit être récupérée avant l’entretien.',
        'history.operation_exceeds_budget' => 'Une opération dépasse le budget de l’historique. Aucun entretien n’a été appliqué.',
        'history.branch_unavailable' => 'Cet historique contient des annulations anciennes à analyser avant de pouvoir appliquer l’entretien.',
        _ => 'L’entretien de l’historique n’a pas pu aboutir. Relancez l’analyse ou vérifiez les données du projet.',
      });
    } on CatalogStorageException catch (error) {
      throw ProjectHistoryMaintenanceFailure(switch (error.code) {
        'catalog.preparation_required' =>
          'Le catalogue a changé depuis l’ouverture. Fermez puis rouvrez le projet avant l’entretien.',
        'catalog.preparation_active' => 'Une modification est encore préparée dans une autre session. Terminez-la ou abandonnez-la avant l’entretien.',
        'catalog.recovery_required' =>
          'Une écriture interrompue doit être récupérée avant l’entretien.',
        _ => 'Le catalogue n’a pas pu être préparé pour l’entretien.',
      });
    } finally {
      if (attached) await mutations.detachWorkspace(opened.workspaceHandle);
      service.closeWorkspace(opened.workspaceHandle);
    }
  }
}
