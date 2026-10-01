import 'dart:math';

import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_core/map_core_domain.dart';

import '../../project_session/domain/project_session.dart';
import '../domain/map_catalog_preparation.dart';
import '../domain/map_workspace_port.dart';
import 'local_map_catalog_adapter.dart';
import 'local_map_catalog_diagnostics.dart';

Future<void> Function() mapCatalogTransactionPrecondition(
  Future<void> Function()? before,
  String? Function()? validate,
) => () async {
  await before?.call();
  final problem = validate?.call();
  if (problem != null) {
    throw MapWorkspaceFailure(MapWorkspaceProblem.conflict, problem);
  }
};

Future<MapCatalogPreparation> prepareLocalMapCatalog(
  LocalMapCatalogAdapter adapter,
  ProjectSession session,
  String actionId,
  Map<String, Object?> parameters, {
  Map<String, String> expectedMapRevisions = const {},
  ProjectManifest? expectedManifest,
}) => adapter.mapAdapter.withResourceMutation(() async {
  final before = await adapter.mapAdapter.resourceBaseline(session);
  if (expectedManifest != null && before.manifest != expectedManifest) {
    throw const MapWorkspaceFailure(
      MapWorkspaceProblem.conflict,
      'Le catalogue a changé depuis son ouverture. Relancez l’analyse.',
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
  try {
    final snapshot =
        await ProjectSnapshotLoader(
          handles: handles,
          snapshotCache: adapter.snapshotCache,
          fingerprintCache: adapter.fingerprintCache,
          profileSink: adapter.profileSink,
        ).load(
          opened.projectHandle,
          policy: ProjectSnapshotLoadPolicy.editorReadProjection,
        );
    if (narrativeEventBytesFingerprint(snapshot.resourceBytes('project')) !=
        before.revision) {
      throw const MapWorkspaceFailure(
        MapWorkspaceProblem.conflict,
        'Le projet a changé pendant sa lecture. Relancez l’analyse.',
      );
    }
    for (final entry in expectedMapRevisions.entries) {
      if (narrativeEventBytesFingerprint(
            snapshot.resourceBytes('map:${entry.key}'),
          ) !=
          entry.value) {
        throw const MapWorkspaceFailure(
          MapWorkspaceProblem.conflict,
          'Une carte a changé sur le disque. Votre travail reste ouvert.',
        );
      }
    }
    final targetId =
        parameters[actionId == 'map.duplicate' ? 'sourceMapId' : 'mapId'];
    final source = snapshot.maps.where((map) => map.id == targetId).firstOrNull;
    if (targetId is! String || source == null) {
      throw const MapWorkspaceFailure(
        MapWorkspaceProblem.unavailable,
        'Cette carte ne figure plus dans le projet.',
      );
    }
    final id =
        'analysis_${DateTime.now().microsecondsSinceEpoch}_${Random.secure().nextInt(1 << 32)}';
    final analysis = const MapLifecycleActions().analyze(
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
    return MapCatalogPreparation(
      sessionId: session.sessionId,
      actionId: actionId,
      parameters: parameters,
      targetMapId: targetId,
      snapshotRevision: snapshot.revision,
      sourceMap: source,
      canApply: analysis.canApply,
      noChange: analysis.noChange,
      issues: analysis.noChange
          ? const []
          : mapCatalogIssues(
              analysis.errorCode,
              analysis.details,
              snapshot.manifest,
            ),
      details: {
        ...analysis.details,
        'preview': analysis.preview,
        'referenceImpact': analysis.referenceImpact,
      },
    );
  } finally {
    handles.closeWorkspace(opened.workspaceHandle);
  }
});
