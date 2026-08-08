part of 'editor_notifier.dart';

/// Canonical connection editing kept outside the already-large notifier body.
mixin _EditorNotifierMapConnections on _$EditorNotifier {
  MapConnectionEditingService get _mapConnectionEditingService;
  ProjectSessionController get _projectSessionController;
  EditorMapSessionCoordinator get _editorMapSessionCoordinator;
  Future<bool> saveProjectManifest();
  Future<ActiveMapSaveOutcome> saveActiveMap({
    bool confirmBulkPlacementLoss,
    PendingBorderSaveDecision? pendingBorderDecision,
  });
  Future<MapData?> loadMapSnapshotById(String mapId);
  void _rememberMapDocumentRevision(
    String mapPath, {
    required String? revision,
    required MapData sourceDocument,
  });
  void _clearCanonicalSmartTileHistory();
  void _coerceActiveToolIfIncompatibleWithLayer();

  Future<void> saveMapConnection({
    required MapConnectionDirection direction,
    required String targetMapId,
    required int offset,
    bool reciprocal = false,
    bool exactReciprocalPairExists = false,
  }) async {
    if (!await _flushSessionForCanonicalMapConnectionMutation()) return;
    final projectRootPath = state.projectRootPath;
    final project = state.project;
    final map = state.activeMap;
    if (projectRootPath == null || project == null || map == null) return;
    try {
      final detectedExactPair = await _hasExactReciprocalMapConnectionPair(
        sourceMap: map,
        direction: direction,
        targetMapId: targetMapId,
      );
      final intent = _mapConnectionEditingService.buildUpsertIntent(
        sourceMap: map,
        direction: direction,
        targetMapId: targetMapId,
        offset: offset,
        reciprocal: reciprocal,
        exactReciprocalPairExists:
            exactReciprocalPairExists || detectedExactPair,
      );
      final targetEntry = _mapConnectionEditingService.resolveTargetMapEntry(
        project,
        targetMapId,
      );
      await _applyCanonicalMapConnectionIntent(
        projectRootPath: projectRootPath,
        map: map,
        intent: intent,
        statusMessage:
            'Connexion ${direction.name} enregistrée vers « ${targetEntry.name} ».',
      );
    } on Object catch (error) {
      final failure = EditorAuthoringMutationFailure.capture(error);
      state = state.copyWith(
        errorMessage: const EditorReceiptPresenter().failure(failure).message,
      );
    }
  }

  Future<void> deleteMapConnection(
    MapConnectionDirection direction, {
    bool exactReciprocalPairExists = false,
  }) async {
    if (!await _flushSessionForCanonicalMapConnectionMutation()) return;
    final projectRootPath = state.projectRootPath;
    final map = state.activeMap;
    if (projectRootPath == null || map == null) return;
    try {
      final connection = _mapConnectionEditingService.findConnection(
        map,
        direction,
      );
      final detectedExactPair = connection == null
          ? false
          : await _hasExactReciprocalMapConnectionPair(
              sourceMap: map,
              direction: direction,
              targetMapId: connection.targetMapId,
            );
      final intent = _mapConnectionEditingService.buildDeleteIntent(
        sourceMap: map,
        direction: direction,
        exactReciprocalPairExists:
            exactReciprocalPairExists || detectedExactPair,
      );
      await _applyCanonicalMapConnectionIntent(
        projectRootPath: projectRootPath,
        map: map,
        intent: intent,
        statusMessage: 'Connexion ${direction.name} supprimée.',
      );
    } on Object catch (error) {
      final failure = EditorAuthoringMutationFailure.capture(error);
      state = state.copyWith(
        errorMessage: const EditorReceiptPresenter().failure(failure).message,
      );
    }
  }

  Future<bool> _flushSessionForCanonicalMapConnectionMutation() async {
    if (state.isProjectDirty && !await saveProjectManifest()) {
      state = state.copyWith(
        errorMessage: 'Le projet doit être enregistré avant de modifier une '
            'connexion entre maps.',
      );
      return false;
    }
    if (!state.isDirty) return true;
    final outcome = await saveActiveMap();
    if (outcome == ActiveMapSaveOutcome.saved) return true;
    if (state.errorMessage == null) {
      state = state.copyWith(
        errorMessage: 'La map doit être enregistrée avant de modifier une '
            'connexion.',
      );
    }
    return false;
  }

  Future<bool> _hasExactReciprocalMapConnectionPair({
    required MapData sourceMap,
    required MapConnectionDirection direction,
    required String targetMapId,
  }) async {
    final targetMap = await loadMapSnapshotById(targetMapId);
    if (targetMap == null) return false;
    return _mapConnectionEditingService.hasExactReciprocalPair(
      sourceMap: sourceMap,
      targetMap: targetMap,
      direction: direction,
    );
  }

  Future<void> _applyCanonicalMapConnectionIntent({
    required String projectRootPath,
    required MapData map,
    required MapConnectionMutationIntent intent,
    required String statusMessage,
  }) async {
    final queries = ref.read(authoringQueryAdapterProvider);
    final mutations = ref.read(authoringMutationAdapterProvider);
    final before = await queries.open(projectRootPath);
    final identity = _mapConnectionMutationIdentity(
      snapshotRevision: before.snapshotRevision,
      intent: intent,
    );
    final plan = await mutations.plan(
      projectRootPath,
      actionId: intent.actionId,
      parameters: intent.parameters,
      expectedRevision: before.snapshotRevision,
      idempotencyKey: identity,
      requestId: identity,
    );
    final confirmationToken = intent.actionId.contains('.delete')
        ? await mutations.confirm(plan)
        : null;
    final applied = await mutations.apply(
      plan,
      operationId: '$identity-apply',
      confirmationToken: confirmationToken,
    );
    final after = await queries.open(projectRootPath);
    if (after.snapshotRevision != applied.snapshotRevision) {
      throw const EditorAuthoringMutationFailure(
        code: 'connection.snapshot_stale',
        message: 'Le snapshot canonique des connexions est obsolète.',
      );
    }
    final canonicalMap = after.mapById(map.id);
    final mapRevision = after.resourceRevision('map:${map.id}');
    if (canonicalMap == null || mapRevision == null) {
      throw const EditorAuthoringMutationFailure(
        code: 'connection.snapshot_missing',
        message: 'La map active est absente du snapshot canonique.',
      );
    }
    _acceptCanonicalMapConnectionPublication(
      manifest: after.manifest,
      map: canonicalMap,
      mapRevision: mapRevision,
      statusMessage: statusMessage,
    );
  }

  void _acceptCanonicalMapConnectionPublication({
    required ProjectManifest manifest,
    required MapData map,
    required String mapRevision,
    required String statusMessage,
  }) {
    final activeMap = state.activeMap;
    final activeMapPath = state.activeMapPath;
    if (activeMap == null || activeMap.id != map.id || activeMapPath == null) {
      throw const EditorAuthoringMutationFailure(
        code: 'connection.active_map_changed',
        message: 'La map active a changé pendant la modification.',
      );
    }
    final preferredLayerId = state.activeLayerId;
    state = _projectSessionController.openMapDocument(
      current: state.copyWith(project: manifest, isProjectDirty: false),
      document: MapDocumentLoadResult(
        map: map,
        activeMapPath: activeMapPath,
        selectedTilesetEditorId:
            _editorMapSessionCoordinator.resolveSelectedTilesetIdForMap(map),
      ),
      statusMessage: statusMessage,
    );
    state = state.copyWith(
      activeLayerId: preferredLayerId != null &&
              map.layers.any((layer) => layer.id == preferredLayerId)
          ? preferredLayerId
          : state.activeLayerId,
      isDirty: false,
      isProjectDirty: false,
      errorMessage: null,
    );
    _rememberMapDocumentRevision(
      activeMapPath,
      revision: mapRevision,
      sourceDocument: map,
    );
    _clearCanonicalSmartTileHistory();
    _coerceActiveToolIfIncompatibleWithLayer();
  }
}

String _mapConnectionMutationIdentity({
  required String snapshotRevision,
  required MapConnectionMutationIntent intent,
}) {
  final digest = sha256
      .convert(
        utf8.encode(
          '${intent.actionId}|$snapshotRevision|${jsonEncode(intent.parameters)}',
        ),
      )
      .toString();
  return 'map-connection-${digest.substring(0, 24)}';
}
