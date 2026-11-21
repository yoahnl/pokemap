import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/presentations/data/local_presentation_connection.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:path/path.dart' as p;

final class StudioTransportSession {
  StudioTransportSession._(this._connection);

  static Future<StudioTransportSession> open(Directory project) async {
    final root = await project.resolveSymbolicLinks();
    final bytes = await const LocalProjectFileReader().readBytes(
      projectRoot: root,
      relativePath: 'project.json',
    );
    final descriptor = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    final storage = switch (descriptor['format']) {
      'avelune.working-catalog' => ProjectSessionStorage.workingCatalog,
      'avelune.portable-catalog' => ProjectSessionStorage.portableCatalog,
      _ => ProjectSessionStorage.manifest,
    };
    final connection = await LocalPresentationConnection.open(
      ProjectSession(
        sessionId: root,
        name: p.basename(root),
        directoryPath: root,
        storage: storage,
      ),
      LocalArtifactStore(
        allowedSourceRoots: [root],
        maximumArtifactBytes: maximumAuthoringArtifactBytesV1,
      ),
      null,
    );
    return StudioTransportSession._(connection);
  }

  final LocalPresentationConnection _connection;

  Future<ContentArtifactRef> stage(String path, String mediaType) async =>
      (await _connection.api.stageArtifactFile(
        sourcePath: path,
        declaredMediaType: mediaType,
      )).reference;

  Future<AuthoringReceipt> run({
    required String actionId,
    required int actionVersion,
    required Map<String, Object?> parameters,
    required String operationId,
    bool preferWorkshop = true,
    bool planOnly = false,
    bool confirm = false,
  }) async {
    final opened = _connection.opened;
    final api = _connection.api;
    final workshopRevision = preferWorkshop
        ? await _readWorkshopRevision(actionId, parameters)
        : null;
    final revision =
        workshopRevision ?? await _connection.readProjectRevision();
    final plan = await api.planMutation(
      opened.projectHandle,
      AuthoringRequest(
        requestId: operationId,
        actionId: actionId,
        actionVersion: actionVersion,
        workspaceHandle: opened.workspaceHandle.value,
        parameters: parameters,
        expectedRevision: revision,
        idempotencyKey: operationId,
        dryRun: planOnly,
        extensions: {if (workshopRevision != null) 'workshopScope': true},
      ),
    );
    if (planOnly) return plan.receipt;
    final confirmation = confirm
        ? await api.confirmMutation(opened.projectHandle, planId: plan.planId)
        : null;
    final applied = await api.applyMutation(
      opened.projectHandle,
      planId: plan.planId,
      operationId: operationId,
      confirmationToken: confirmation?.confirmationToken,
    );
    return applied.receipt;
  }

  Future<String?> _readWorkshopRevision(
    String actionId,
    Map<String, Object?> parameters,
  ) async {
    try {
      final snapshot = await _connection.api.readWorkshopSnapshot(
        _connection.opened.projectHandle,
        actionId: actionId,
        parameters: parameters,
      );
      return snapshot.revision;
    } on ProjectSnapshotException catch (error) {
      if (error.code == 'project.workshop_scope_required' ||
          error.code == 'project.field_traversal_scope_required') {
        return null;
      }
      rethrow;
    }
  }

  Future<void> close() => _connection.close();
}
