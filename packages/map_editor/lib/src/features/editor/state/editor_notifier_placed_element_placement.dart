part of 'editor_notifier.dart';

/// Canonical semantic placement kept outside the already-large notifier body.
mixin _EditorNotifierPlacedElementPlacement on _$EditorNotifier {
  ProjectSessionController get _projectSessionController;
  EditorMapSessionCoordinator get _editorMapSessionCoordinator;
  Future<bool> saveProjectManifest();
  Future<ActiveMapSaveOutcome> saveActiveMap({
    bool confirmBulkPlacementLoss,
    PendingBorderSaveDecision? pendingBorderDecision,
  });
  void _rememberMapDocumentRevision(
    String mapPath, {
    required String? revision,
    required MapData sourceDocument,
  });
  void _clearCanonicalSmartTileHistory();
  void _coerceActiveToolIfIncompatibleWithLayer();

  bool _placedElementPlacementInProgress = false;

  Future<void> placeSelectedProjectElementAt(GridPos pos) async {
    if (_placedElementPlacementInProgress) return;
    final brush = state.activeBrush;
    final map = state.activeMap;
    final layerId = state.activeLayerId;
    final projectRootPath = state.projectRootPath;
    if (brush is! ProjectElementEditorBrush ||
        map == null ||
        layerId == null ||
        projectRootPath == null) {
      return;
    }
    _placedElementPlacementInProgress = true;
    try {
      if (!await _flushSessionForCanonicalPlacedElementMutation()) return;
      final currentMap = state.activeMap;
      if (currentMap == null || currentMap.id != map.id) return;
      final intent = const PlacedElementEditingService().buildPlaceIntent(
        map: currentMap,
        layerId: layerId,
        elementId: brush.elementId,
        pos: pos,
      );
      final queries = ref.read(authoringQueryAdapterProvider);
      final mutations = ref.read(authoringMutationAdapterProvider);
      final before = await queries.open(projectRootPath);
      final identity = _placedElementMutationIdentity(
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
      final applied = await mutations.apply(
        plan,
        operationId: '$identity-apply',
      );
      final after = await queries.open(projectRootPath);
      if (after.snapshotRevision != applied.snapshotRevision) {
        throw const EditorAuthoringMutationFailure(
          code: 'placed_element.snapshot_stale',
          message: 'Le snapshot canonique du placement est obsolète.',
        );
      }
      final canonicalMap = after.mapById(map.id);
      final mapRevision = after.resourceRevision('map:${map.id}');
      if (canonicalMap == null || mapRevision == null) {
        throw const EditorAuthoringMutationFailure(
          code: 'placed_element.snapshot_missing',
          message: 'La map active est absente du snapshot canonique.',
        );
      }
      _acceptCanonicalPlacedElementPublication(
        manifest: after.manifest,
        map: canonicalMap,
        mapRevision: mapRevision,
        preferredLayerId: layerId,
      );
    } on Object catch (error) {
      final failure = EditorAuthoringMutationFailure.capture(error);
      state = state.copyWith(
        errorMessage: const EditorReceiptPresenter().failure(failure).message,
      );
    } finally {
      _placedElementPlacementInProgress = false;
    }
  }

  Future<bool> _flushSessionForCanonicalPlacedElementMutation() async {
    if (state.isProjectDirty && !await saveProjectManifest()) {
      state = state.copyWith(
        errorMessage: 'Le projet doit être enregistré avant de placer cet '
            'élément.',
      );
      return false;
    }
    if (!state.isDirty) return true;
    final outcome = await saveActiveMap();
    if (outcome == ActiveMapSaveOutcome.saved) return true;
    if (state.errorMessage == null) {
      state = state.copyWith(
        errorMessage: 'La map doit être enregistrée avant de placer cet '
            'élément.',
      );
    }
    return false;
  }

  void _acceptCanonicalPlacedElementPublication({
    required ProjectManifest manifest,
    required MapData map,
    required String mapRevision,
    required String preferredLayerId,
  }) {
    final activeMap = state.activeMap;
    final activeMapPath = state.activeMapPath;
    if (activeMap == null || activeMap.id != map.id || activeMapPath == null) {
      throw const EditorAuthoringMutationFailure(
        code: 'placed_element.active_map_changed',
        message: 'La map active a changé pendant le placement.',
      );
    }
    state = _projectSessionController.openMapDocument(
      current: state.copyWith(project: manifest, isProjectDirty: false),
      document: MapDocumentLoadResult(
        map: map,
        activeMapPath: activeMapPath,
        selectedTilesetEditorId:
            _editorMapSessionCoordinator.resolveSelectedTilesetIdForMap(map),
      ),
      statusMessage: 'Élément placé.',
    );
    state = state.copyWith(
      activeLayerId: map.layers.any((layer) => layer.id == preferredLayerId)
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

String _placedElementMutationIdentity({
  required String snapshotRevision,
  required PlacedElementMutationIntent intent,
}) {
  final digest = sha256
      .convert(
        utf8.encode(
          '${intent.actionId}|$snapshotRevision|${jsonEncode(intent.parameters)}',
        ),
      )
      .toString();
  return 'placed-element-${digest.substring(0, 24)}';
}
