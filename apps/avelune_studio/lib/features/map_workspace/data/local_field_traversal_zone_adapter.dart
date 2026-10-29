part of 'local_map_workspace_adapter.dart';

extension _LocalFieldTraversalZoneAdapter on LocalMapWorkspaceAdapter {
  Future<FieldTraversalZoneReceipt> _publishFieldTraversalZone(
    ProjectSession session,
    MapWorkspaceDocument base,
    String actionId,
    Map<String, Object?> parameters, {
    FieldTraversalZoneReceipt? undo,
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
      final snapshot = await api.readWorkshopSnapshot(
        opened.projectHandle,
        actionId: undo != null && !redo ? 'gameplay_zone.create' : actionId,
        parameters: undo != null && !redo
            ? {'mapId': base.mapId, 'zone': undo.selectionZone.toJson()}
            : parameters,
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
          'studio_route_${DateTime.now().microsecondsSinceEpoch}_${_editorOperations++}';
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
            actionId: actionId,
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
      return FieldTraversalZoneReceipt(
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
        actionId: actionId,
        parameters: parameters,
        selectionZone:
            undo?.selectionZone ??
            (parameters['zone'] is Map
                ? MapGameplayZone.fromJson(
                    Map<String, dynamic>.from(parameters['zone'] as Map),
                  )
                : base.map.gameplayZones.singleWhere(
                    (zone) => zone.id == parameters['zoneId'],
                  )),
      );
    });
  }
}
