part of 'local_map_workspace_adapter.dart';

extension _LocalSpatialFieldObstacleAdapter on LocalMapWorkspaceAdapter {
  Future<SpatialFieldObstacleReceipt> _configureSpatialFieldObstacle(
    ProjectSession session,
    MapWorkspaceDocument base,
    String instanceId,
    MapEntityFieldObstacleData? fieldObstacle,
  ) => _mutateSpatialFieldObstacle(
    session,
    base,
    instanceId: instanceId,
    fieldObstacle: fieldObstacle,
  );

  Future<SpatialFieldObstacleReceipt> _mutateSpatialFieldObstacle(
    ProjectSession session,
    MapWorkspaceDocument base, {
    String? instanceId,
    MapEntityFieldObstacleData? fieldObstacle,
    SpatialFieldObstacleReceipt? undo,
    bool redo = false,
  }) async {
    _requireEditorWritable(session);
    return _withSurfAuthoring(session, (opener, opened, api, _) async {
      final project = _project(session);
      final expectedProjectRevision = project.revision;
      await _requireProjectRevision(session, project);
      await api.attachProject(
        projectRootPath: session.directoryPath,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle,
      );
      const action = 'map3d.instance.configure_field_obstacle';
      final parameters = <String, Object?>{
        'mapId': base.mapId,
        'instanceId': instanceId ?? undo!.instanceId,
        'fieldObstacle': (redo ? undo?.fieldObstacle : fieldObstacle)?.toJson(),
      };
      final snapshot = await api.readWorkshopSnapshot(
        opened.projectHandle,
        actionId: action,
        parameters: parameters,
      );
      if (narrativeEventBytesFingerprint(
            snapshot.resourceBytes('map:${base.mapId}'),
          ) !=
          base.revision) {
        throw const MapWorkspaceFailure(
          MapWorkspaceProblem.conflict,
          'La carte a changé sur le disque. Votre brouillon reste ouvert.',
        );
      }
      final id =
          'studio_obstacle_${DateTime.now().microsecondsSinceEpoch}_${_editorOperations++}';
      late final AuthoringMutationResult result;
      if (undo != null && !redo) {
        result = await api.undoMutation(
          opened.projectHandle,
          entryId: undo.receiptId,
          idempotencyKey: id,
        );
      } else {
        final planned = await api.planMutation(
          opened.projectHandle,
          AuthoringRequest(
            requestId: id,
            actionId: action,
            actionVersion: 1,
            workspaceHandle: opened.workspaceHandle.value,
            parameters: parameters,
            expectedRevision: snapshot.revision,
            idempotencyKey: id,
          ),
        );
        result = await api.applyMutation(
          opened.projectHandle,
          planId: planned.planId,
          operationId: id,
          precondition: () async {
            if (await resourceRevision(session) != expectedProjectRevision) {
              throw const MapWorkspaceFailure(
                MapWorkspaceProblem.conflict,
                'Le projet a changé pendant l’enregistrement.',
              );
            }
          },
        );
      }
      final revision = await resourceRevision(session);
      final latest = _project(session);
      _projects[session.sessionId] = _ProjectDocument(
        latest.root,
        latest.manifest,
        revision,
        complete: latest.complete,
        metadataFields: latest.metadataFields,
      );
      final bytes = await _reader.readBytes(
        projectRoot: session.directoryPath,
        relativePath: _editorMapPath(session, base.mapId),
      );
      return SpatialFieldObstacleReceipt(
        document: MapWorkspaceDocument(
          map: MapData.fromJson(
            Map<String, dynamic>.from(jsonDecode(utf8.decode(bytes)) as Map),
          ),
          revision: narrativeEventBytesFingerprint(bytes),
          mapId: base.mapId,
        ),
        receiptId: redo
            ? result.receipt.receiptId
            : undo?.receiptId ?? result.receipt.receiptId,
        instanceId: instanceId ?? undo!.instanceId,
        fieldObstacle: undo?.fieldObstacle ?? fieldObstacle,
      );
    });
  }
}
