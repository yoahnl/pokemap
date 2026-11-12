import 'dart:math';

import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_core/map_core_domain.dart';

import '../../project_session/domain/project_session.dart';
import '../domain/map_connection_port.dart';
import '../domain/map_dive_pair_port.dart';
import '../domain/map_workspace_port.dart';
import 'local_map_workspace_adapter.dart';

final class LocalMapConnectionAdapter
    implements MapConnectionPort, MapDivePairPort {
  const LocalMapConnectionAdapter(this.mapAdapter);

  final LocalMapWorkspaceAdapter mapAdapter;

  @override
  Future<List<MapWorkspaceDocument>> link({
    required ProjectSession session,
    required MapData source,
    required MapConnectionDirection direction,
    required String targetMapId,
    required int offset,
    MapData? expectedTarget,
  }) => _linkBorders(
    session: session,
    source: source,
    expectedTarget: expectedTarget,
    action: 'connection.create_bidirectional_apply',
    parameters: {
      'mapId': source.id,
      'direction': direction.name,
      'targetMapId': targetMapId,
      'offset': offset,
    },
  );

  @override
  Future<List<MapWorkspaceDocument>> unlink({
    required ProjectSession session,
    required MapData source,
    required MapConnectionDirection direction,
    MapData? expectedTarget,
  }) => _linkBorders(
    session: session,
    source: source,
    expectedTarget: expectedTarget,
    action: 'connection.delete_bidirectional_apply',
    parameters: {
      'mapId': source.id,
      'direction': direction.name,
      if (source.connections
              .where((entry) => entry.direction == direction)
              .firstOrNull
          case final existing?)
        'targetMapId': existing.targetMapId,
    },
  );

  @override
  Future<void> publishDivePair({
    required ProjectSession session,
    required MapData source,
    required MapData expectedTarget,
    required String zoneId,
    required String targetZoneId,
    required bool unlink,
  }) => _run(
    session: session,
    source: source,
    expectedTarget: expectedTarget,
    action: unlink
        ? 'gameplay_zone.dive.unlink_pair_apply'
        : 'gameplay_zone.dive.link_pair_apply',
    parameters: {
      'mapId': source.id,
      'zoneId': zoneId,
      if (!unlink) 'targetMapId': expectedTarget.id,
      if (!unlink) 'targetZoneId': targetZoneId,
    },
  );

  Future<List<MapWorkspaceDocument>> _linkBorders({
    required ProjectSession session,
    required MapData source,
    required MapData? expectedTarget,
    required String action,
    required Map<String, Object?> parameters,
  }) async {
    await _run(
      session: session,
      source: source,
      expectedTarget: expectedTarget,
      action: action,
      parameters: parameters,
      scoped: true,
    );
    final mapIds = {
      source.id,
      if (parameters['targetMapId'] case final String target) target,
    };
    await mapAdapter.refreshExternalBaseline(
      session,
      resources: {for (final id in mapIds) (kind: 'map', id: id)},
    );
    return [
      for (final id in mapIds)
        if (await mapAdapter.readSavedMap(session, id) case final document?)
          document,
    ];
  }

  Future<void> _run({
    required ProjectSession session,
    required MapData source,
    required MapData? expectedTarget,
    required String action,
    required Map<String, Object?> parameters,
    bool scoped = false,
  }) => mapAdapter.withResourceMutation(() async {
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
      catalogMetadataFields: scoped ? const {} : null,
      workshopScope: scoped,
    ).openProject(session.directoryPath);
    final loader = ProjectSnapshotLoader(handles: handles);
    final api = LocalMapAuthoringMutationApi(
      policy: policy,
      snapshotLoader: loader,
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
      final snapshot = scoped && api.isCatalogProject(opened.projectHandle)
          ? await api.readWorkshopSnapshot(
              opened.projectHandle,
              actionId: action,
              parameters: parameters,
            )
          : await loader.load(opened.projectHandle);
      final currentSource = snapshot.maps
          .where((map) => map.id == source.id)
          .firstOrNull;
      final currentTarget = expectedTarget == null
          ? null
          : snapshot.maps
                .where((map) => map.id == expectedTarget.id)
                .firstOrNull;
      if (currentSource != source ||
          (expectedTarget != null && currentTarget != expectedTarget)) {
        throw const MapWorkspaceFailure(
          MapWorkspaceProblem.conflict,
          'Une carte a changé sur le disque. Rechargez-la avant de relier les cartes.',
        );
      }
      var effectiveAction = action;
      if (action == 'connection.create_bidirectional_apply') {
        final existing = source.connections
            .where(
              (entry) =>
                  entry.direction.name == parameters['direction'] &&
                  entry.targetMapId == parameters['targetMapId'],
            )
            .firstOrNull;
        if (existing != null) {
          final target = snapshot.maps
              .where((map) => map.id == existing.targetMapId)
              .firstOrNull;
          final paired =
              target?.connections.any(
                (entry) =>
                    entry.direction == existing.direction.opposite &&
                    entry.targetMapId == source.id,
              ) ??
              false;
          effectiveAction = paired
              ? 'connection.update_bidirectional_apply'
              : 'connection.upsert';
        }
      }
      if (action == 'connection.delete_bidirectional_apply') {
        final existing = source.connections
            .where((entry) => entry.direction.name == parameters['direction'])
            .firstOrNull;
        final target = snapshot.maps
            .where((map) => map.id == existing?.targetMapId)
            .firstOrNull;
        final reciprocal = target?.connections
            .where((entry) => entry.direction == existing?.direction.opposite)
            .firstOrNull;
        if (reciprocal?.targetMapId != source.id ||
            reciprocal?.offset != -(existing?.offset ?? 0)) {
          effectiveAction = 'connection.delete';
        }
      }
      final id =
          'studio_connection_${DateTime.now().microsecondsSinceEpoch}_${Random.secure().nextInt(1 << 32)}';
      final planned = await api.planMutation(
        opened.projectHandle,
        AuthoringRequest(
          requestId: id,
          actionId: effectiveAction,
          actionVersion: 1,
          workspaceHandle: opened.workspaceHandle.value,
          expectedRevision: snapshot.revision,
          idempotencyKey: id,
          parameters: parameters,
        ),
      );
      try {
        await api.applyMutation(
          opened.projectHandle,
          planId: planned.planId,
          operationId: id,
        );
      } on Object catch (failure) {
        try {
          await api.recoverMutation(opened.projectHandle, operationId: id);
        } on Object {
          throw StateError(
            'Écriture interrompue ; journal $id conservé : $failure',
          );
        }
        rethrow;
      }
    } finally {
      if (attached) await api.detachWorkspace(opened.workspaceHandle);
      handles.closeWorkspace(opened.workspaceHandle);
    }
  });
}
