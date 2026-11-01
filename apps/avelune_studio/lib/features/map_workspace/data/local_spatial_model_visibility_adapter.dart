part of 'local_map_workspace_adapter.dart';

extension _LocalSpatialModelVisibilityAdapter on LocalMapWorkspaceAdapter {
  Future<SpatialModelVisibilityReceipt> _configureSpatialModelVisibility(
    ProjectSession session,
    MapWorkspaceDocument base,
    String instanceId,
    NarrativeEventConditionExpression? condition,
  ) => _mutateSpatialModelVisibility(
    session,
    base,
    instanceId: instanceId,
    condition: condition,
  );

  Future<SpatialModelVisibilityReceipt> _mutateSpatialModelVisibility(
    ProjectSession session,
    MapWorkspaceDocument base, {
    String? instanceId,
    NarrativeEventConditionExpression? condition,
    SpatialModelVisibilityReceipt? undo,
    bool redo = false,
  }) => _observeAuthoringPhase('studio.visibility.backend', () async {
    _requireEditorWritable(session);
    return _withSurfAuthoring(session, (opener, opened, api, _) async {
      final project = _project(session);
      final expectedProjectRevision = project.revision;
      await _observeAuthoringPhase(
        'studio.visibility.requireRevision',
        () => _requireProjectRevision(session, project),
      );
      await _observeAuthoringPhase(
        'studio.visibility.attach',
        () => api.attachProject(
          projectRootPath: session.directoryPath,
          workspaceHandle: opened.workspaceHandle,
          projectHandle: opened.projectHandle,
        ),
      );
      const action = 'map3d.instance.visibility.set';
      final parameters = <String, Object?>{
        'mapId': base.mapId,
        'instanceId': instanceId ?? undo!.instanceId,
        'visibilityCondition': (redo ? undo?.condition : condition)?.toJson(),
      };
      final snapshot = await _observeAuthoringPhase(
        'studio.visibility.workshop',
        () => api.readWorkshopSnapshot(
          opened.projectHandle,
          actionId: action,
          parameters: parameters,
        ),
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
          'studio_visibility_${DateTime.now().microsecondsSinceEpoch}_${_editorOperations++}';
      late final AuthoringMutationResult result;
      if (undo != null && !redo) {
        result = await _observeAuthoringPhase(
          'studio.visibility.undo',
          () => api.undoMutation(
            opened.projectHandle,
            entryId: undo.receiptId,
            idempotencyKey: id,
          ),
        );
      } else {
        final planned = await _observeAuthoringPhase(
          'studio.visibility.plan',
          () => api.planMutation(
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
          ),
        );
        result = await _observeAuthoringPhase(
          'studio.visibility.apply',
          () => api.applyMutation(
            opened.projectHandle,
            planId: planned.planId,
            operationId: id,
            precondition: () async {
              if (await _observeAuthoringPhase(
                    'studio.visibility.preconditionRevision',
                    () => resourceRevision(session),
                  ) !=
                  expectedProjectRevision) {
                throw const MapWorkspaceFailure(
                  MapWorkspaceProblem.conflict,
                  'Le projet a changé pendant l’enregistrement.',
                );
              }
            },
          ),
        );
      }
      final revision = await _observeAuthoringPhase(
        'studio.visibility.postRevision',
        () => resourceRevision(session),
      );
      final latest = _project(session);
      _projects[session.sessionId] = _ProjectDocument(
        latest.root,
        latest.manifest,
        revision,
        complete: latest.complete,
        metadataFields: latest.metadataFields,
      );
      final bytes = await _observeAuthoringPhase(
        'studio.visibility.readback',
        () => _reader.readBytes(
          projectRoot: session.directoryPath,
          relativePath: _editorMapPath(session, base.mapId),
        ),
      );
      return _observeAuthoringPhaseSync(
        'studio.visibility.decodeReceipt',
        () => SpatialModelVisibilityReceipt(
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
          condition: undo?.condition ?? condition,
        ),
      );
    });
  });
}
