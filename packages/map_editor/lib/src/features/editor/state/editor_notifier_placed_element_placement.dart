part of 'editor_notifier.dart';

mixin _EditorNotifierPlacedElementPlacement on _$EditorNotifier {
  ProjectSessionController get _projectSessionController;
  EditorMapSessionCoordinator get _editorMapSessionCoordinator;
  Future<bool> saveProjectManifest();
  String? _mapDocumentRevisionFor(String path);
  Future<bool> _savePlacedElementPublicationBase(
    _PlacedElementPublicationBase base,
  );
  void _applyMapMutation({
    required MapData previousMap,
    required MapData updatedMap,
    required String? preferredActiveLayerId,
    String? statusMessage,
    Object? mapWriteLeaseToken,
  });
  void _rememberMapDocumentRevision(
    String mapPath, {
    required String? revision,
    required MapData sourceDocument,
  });
  void _coerceActiveToolIfIncompatibleWithLayer();
  void _validatePlacedElementDelta({
    required MapData before,
    required MapData after,
    required String instanceId,
  });
  void _recordCanonicalPlacedElementPlacement({
    required String projectRootPath,
    required String receiptId,
    required String mapId,
    required String layerId,
    required PlacedElementMutationIntent intent,
  });

  final List<_PendingPlacedElementPlacement> _pendingPlacedElementPlacements =
      <_PendingPlacedElementPlacement>[];
  final List<_PublishedPlacedElementBatch> _publishedPlacedElementBatches =
      <_PublishedPlacedElementBatch>[];
  Timer? _placedElementPublicationTimer;
  Future<bool>? _placedElementPublicationFuture;
  Object? _placedElementPublicationMapWriteLeaseToken;
  _PlacedElementPublicationBase? _placedElementPublicationBase;
  MapData? _placedElementOptimisticMap;
  bool _placedElementPublicationBaseFlushed = false;

  bool get hasPendingPlacedElementPublications =>
      _pendingPlacedElementPlacements.isNotEmpty ||
      _placedElementPublicationFuture != null;

  bool get _placedElementPublicationInProgress =>
      _placedElementPublicationFuture != null;

  MapToolPreview? resolveSelectedProjectElementPlacementPreview(GridPos pos) {
    final brush = state.activeBrush;
    final project = state.project;
    final map = state.activeMap;
    if (brush is! ProjectElementEditorBrush || project == null || map == null) {
      return null;
    }
    ProjectElementEntry? element;
    for (final candidate in project.elements) {
      if (candidate.id == brush.elementId) {
        element = candidate;
        break;
      }
    }
    if (element == null) return null;
    final source = element.frames.primarySource;
    final size = GridSize(width: source.width, height: source.height);
    final isInside =
        pos.x >= 0 &&
        pos.y >= 0 &&
        pos.x + size.width <= map.size.width &&
        pos.y + size.height <= map.size.height;
    return MapToolPreview.elementPlacement(
      origin: pos,
      size: size,
      elementId: element.id,
      validity: isInside
          ? MapToolPreviewValidity.valid
          : MapToolPreviewValidity.invalid,
      reason: isInside ? null : 'Le bâtiment dépasse des limites de la map.',
    );
  }

  Future<void> placeSelectedProjectElementAt(GridPos pos) {
    final brush = state.activeBrush;
    final map = state.activeMap;
    final layerId = state.activeLayerId;
    final projectRootPath = state.projectRootPath;
    final activeMapPath = state.activeMapPath;
    if (brush is! ProjectElementEditorBrush ||
        map == null ||
        layerId == null ||
        projectRootPath == null ||
        activeMapPath == null) {
      return Future<void>.value();
    }
    try {
      final intent = const PlacedElementEditingService().buildPlaceIntent(
        map: map,
        layerId: layerId,
        elementId: brush.elementId,
        pos: pos,
      );
      final updatedMap = upsertMapPlacedElement(map, instance: intent.instance);
      _validatePlacedElementDelta(
        before: map,
        after: updatedMap,
        instanceId: intent.instance.id,
      );
      if (_pendingPlacedElementPlacements.isEmpty &&
          _placedElementPublicationFuture == null) {
        _placedElementPublicationBase = _PlacedElementPublicationBase(
          projectRootPath: projectRootPath,
          map: map,
          mapPath: activeMapPath,
          mapRevision: _mapDocumentRevisionFor(activeMapPath),
          project: state.project,
          mapWasDirty: state.isDirty,
          projectWasDirty: state.isProjectDirty,
        );
        _placedElementPublicationBaseFlushed = false;
      }
      _applyMapMutation(
        previousMap: map,
        updatedMap: updatedMap,
        preferredActiveLayerId: layerId,
        statusMessage: 'Élément placé localement.',
        mapWriteLeaseToken: _placedElementPublicationMapWriteLeaseToken,
      );
      if (state.activeMap != updatedMap) {
        return Future<void>.value();
      }
      _placedElementOptimisticMap = updatedMap;
      _pendingPlacedElementPlacements.add(
        _PendingPlacedElementPlacement(
          projectRootPath: projectRootPath,
          mapId: map.id,
          layerId: layerId,
          intent: intent,
        ),
      );
      state = state.copyWith(
        selectedPlacedElementInstanceId: intent.instanceId,
      );
      _schedulePlacedElementPublication();
    } on Object catch (error) {
      final failure = EditorAuthoringMutationFailure.capture(error);
      state = state.copyWith(
        errorMessage: const EditorReceiptPresenter().failure(failure).message,
      );
    }
    return Future<void>.value();
  }

  void _schedulePlacedElementPublication() {
    if (_placedElementPublicationTimer != null ||
        _placedElementPublicationFuture != null) {
      return;
    }
    _placedElementPublicationTimer = Timer(
      const Duration(milliseconds: 20),
      () {
        _placedElementPublicationTimer = null;
        unawaited(drainPlacedElementPublications());
      },
    );
  }

  Future<bool> drainPlacedElementPublications() {
    _placedElementPublicationTimer?.cancel();
    _placedElementPublicationTimer = null;
    final active = _placedElementPublicationFuture;
    if (active != null) return active;
    if (_pendingPlacedElementPlacements.isEmpty) {
      return Future<bool>.value(true);
    }
    final future = _drainPlacedElementPublicationQueue();
    _placedElementPublicationFuture = future;
    return future.whenComplete(() {
      if (identical(_placedElementPublicationFuture, future)) {
        _placedElementPublicationFuture = null;
      }
    });
  }

  Future<bool> retryPlacedElementPublications() =>
      drainPlacedElementPublications();

  Future<bool> _drainPlacedElementPublicationQueue() async {
    final base = _placedElementPublicationBase;
    if (base == null) return false;
    if (!_placedElementPublicationBaseFlushed) {
      if (base.projectWasDirty && !await saveProjectManifest()) {
        state = state.copyWith(
          errorMessage:
              'Le projet doit être enregistré avant de publier les '
              'placements en attente.',
        );
        return false;
      }
      if (base.mapWasDirty && !await _savePlacedElementPublicationBase(base)) {
        return false;
      }
      _placedElementPublicationBaseFlushed = true;
    }
    while (_pendingPlacedElementPlacements.isNotEmpty) {
      final first = _pendingPlacedElementPlacements.first;
      final batch = _pendingPlacedElementPlacements
          .takeWhile(
            (entry) =>
                entry.projectRootPath == first.projectRootPath &&
                entry.mapId == first.mapId &&
                entry.layerId == first.layerId,
          )
          .toList(growable: false);
      try {
        final published = await _publishPlacedElementBatch(batch);
        _pendingPlacedElementPlacements.removeWhere(batch.contains);
        _publishedPlacedElementBatches.add(published);
        final hasMore = _pendingPlacedElementPlacements.isNotEmpty;
        if (hasMore) {
          state = state.copyWith(
            project: published.manifest,
            savedMapSnapshot: published.map,
            errorMessage: null,
          );
          _rememberMapDocumentRevision(
            state.activeMapPath!,
            revision: published.mapRevision,
            sourceDocument: published.map,
          );
          continue;
        }
        final currentMap = state.activeMap;
        if (currentMap == null ||
            !identical(currentMap, _placedElementOptimisticMap)) {
          state = state.copyWith(
            project: published.manifest,
            savedMapSnapshot: published.map,
            errorMessage: null,
          );
          _rememberMapDocumentRevision(
            state.activeMapPath!,
            revision: published.mapRevision,
            sourceDocument: published.map,
          );
          _clearPlacedElementPublicationState();
          return true;
        }
        _acceptCanonicalPlacedElementPublication(
          manifest: published.manifest,
          map: published.map,
          mapRevision: published.mapRevision,
          preferredLayerId: published.layerId,
        );
        _recordPublishedPlacedElementBatches();
        state = state.copyWith(
          selectedPlacedElementInstanceId: published.intent.instanceId,
        );
        _clearPlacedElementPublicationState();
        return true;
      } on Object catch (error) {
        final failure = EditorAuthoringMutationFailure.capture(error);
        state = state.copyWith(
          errorMessage: const EditorReceiptPresenter().failure(failure).message,
        );
        return false;
      }
    }
    _clearPlacedElementPublicationState();
    return true;
  }

  Future<_PublishedPlacedElementBatch> _publishPlacedElementBatch(
    List<_PendingPlacedElementPlacement> batch,
  ) async {
    final first = batch.first;
    if (batch.any(
      (entry) =>
          entry.projectRootPath != first.projectRootPath ||
          entry.mapId != first.mapId ||
          entry.layerId != first.layerId,
    )) {
      throw const EditorAuthoringMutationFailure(
        code: 'placed_element.queue_context_changed',
        message: 'La file de placements mélange plusieurs cartes ou calques.',
      );
    }
    final queries = ref.read(authoringQueryAdapterProvider);
    final mutations = ref.read(authoringMutationAdapterProvider);
    late EditorAuthoringMutationResult applied;
    late PlacedElementMutationIntent appliedIntent;
    late List<MapPlacedElement> appliedInstances;
    var attempt = 0;
    while (true) {
      if (attempt > 0) await queries.invalidate(first.projectRootPath);
      final before = await queries.open(first.projectRootPath);
      final canonicalMap = before.mapById(first.mapId);
      if (canonicalMap == null) {
        throw const EditorAuthoringMutationFailure(
          code: 'placed_element.snapshot_missing',
          message: 'La map active est absente du snapshot canonique.',
        );
      }
      var reservationMap = canonicalMap;
      final instances = <MapPlacedElement>[];
      for (final entry in batch) {
        var instance = entry.intent.instance;
        if (reservationMap.placedElements.any(
          (candidate) => candidate.id == instance.id,
        )) {
          final reserved = const PlacedElementEditingService().buildPlaceIntent(
            map: reservationMap,
            layerId: instance.layerId,
            elementId: instance.elementId,
            pos: instance.pos,
          );
          instance = instance.copyWith(id: reserved.instanceId);
        }
        instances.add(instance);
        reservationMap = upsertMapPlacedElement(
          reservationMap,
          instance: instance,
        );
      }
      final parameters = <String, Object?>{
        'mapId': first.mapId,
        'instances': <Map<String, dynamic>>[
          for (final instance in instances) instance.toJson(),
        ],
      };
      final intent = PlacedElementMutationIntent(
        actionId: 'placed_element.batch_place',
        parameters: Map<String, Object?>.unmodifiable(parameters),
        instanceId: instances.last.id,
        instance: instances.last,
      );
      final identity = _placedElementMutationIdentity(
        snapshotRevision: before.snapshotRevision,
        intent: intent,
      );
      final operationId = '$identity-apply';
      try {
        final plan = await mutations.plan(
          first.projectRootPath,
          actionId: intent.actionId,
          parameters: intent.parameters,
          expectedRevision: before.snapshotRevision,
          idempotencyKey: identity,
          requestId: identity,
        );
        try {
          applied = await mutations.apply(plan, operationId: operationId);
        } on Object catch (error) {
          final failure = EditorAuthoringMutationFailure.capture(error);
          if (failure.code != 'idempotency.recovery_required') rethrow;
          applied = await mutations.recover(
            first.projectRootPath,
            operationId: operationId,
          );
        }
        appliedIntent = intent;
        appliedInstances = List<MapPlacedElement>.unmodifiable(instances);
        break;
      } on Object catch (error) {
        final failure = EditorAuthoringMutationFailure.capture(error);
        if (!_isPlacedElementRevisionConflict(failure.code) ||
            attempt >= _canonicalStalePlanRetryBudget) {
          rethrow;
        }
        attempt++;
      }
    }
    final after = await queries.open(first.projectRootPath);
    final map = after.mapById(first.mapId);
    final mapRevision = after.resourceRevision('map:${first.mapId}');
    if (map == null || mapRevision == null) {
      throw const EditorAuthoringMutationFailure(
        code: 'placed_element.snapshot_missing',
        message: 'La map active est absente du snapshot canonique.',
      );
    }
    if (after.snapshotRevision != applied.snapshotRevision &&
        !appliedInstances.every(map.placedElements.contains)) {
      throw const EditorAuthoringMutationFailure(
        code: 'placed_element.snapshot_stale',
        message: 'Le snapshot canonique du placement est obsolète.',
      );
    }
    return _PublishedPlacedElementBatch(
      projectRootPath: first.projectRootPath,
      receiptId: applied.receipt.receiptId,
      layerId: first.layerId,
      intent: appliedIntent,
      manifest: after.manifest,
      map: map,
      mapRevision: mapRevision,
    );
  }

  bool _cancelLatestPendingPlacedElementPlacementBeforeUndo() {
    if (_placedElementPublicationFuture != null ||
        _pendingPlacedElementPlacements.isEmpty) {
      return false;
    }
    _pendingPlacedElementPlacements.removeLast();
    if (_pendingPlacedElementPlacements.isEmpty) {
      _placedElementPublicationTimer?.cancel();
      _placedElementPublicationTimer = null;
      _clearPlacedElementPublicationState();
    }
    return true;
  }

  void _recordPublishedPlacedElementBatches() {
    for (final entry in _publishedPlacedElementBatches) {
      _recordCanonicalPlacedElementPlacement(
        projectRootPath: entry.projectRootPath,
        receiptId: entry.receiptId,
        mapId: entry.map.id,
        layerId: entry.layerId,
        intent: entry.intent,
      );
    }
  }

  void _clearPlacedElementPublicationState() {
    _placedElementPublicationBase = null;
    _placedElementOptimisticMap = null;
    _placedElementPublicationBaseFlushed = false;
    _publishedPlacedElementBatches.clear();
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
    final activeBrush = state.activeBrush;
    final activeTool = state.activeTool;
    state = _projectSessionController.openMapDocument(
      current: state.copyWith(project: manifest, isProjectDirty: false),
      document: MapDocumentLoadResult(
        map: map,
        activeMapPath: activeMapPath,
        selectedTilesetEditorId: _editorMapSessionCoordinator
            .resolveSelectedTilesetIdForMap(map),
      ),
      statusMessage: 'Éléments publiés.',
    );
    state = state.copyWith(
      activeLayerId: map.layers.any((layer) => layer.id == preferredLayerId)
          ? preferredLayerId
          : state.activeLayerId,
      activeBrush: activeBrush,
      activeTool: activeTool,
      isDirty: false,
      isProjectDirty: false,
      errorMessage: null,
    );
    _rememberMapDocumentRevision(
      activeMapPath,
      revision: mapRevision,
      sourceDocument: map,
    );
    _coerceActiveToolIfIncompatibleWithLayer();
  }
}

final class _PendingPlacedElementPlacement {
  const _PendingPlacedElementPlacement({
    required this.projectRootPath,
    required this.mapId,
    required this.layerId,
    required this.intent,
  });

  final String projectRootPath;
  final String mapId;
  final String layerId;
  final PlacedElementMutationIntent intent;
}

final class _PlacedElementPublicationBase {
  const _PlacedElementPublicationBase({
    required this.projectRootPath,
    required this.map,
    required this.mapPath,
    required this.mapRevision,
    required this.project,
    required this.mapWasDirty,
    required this.projectWasDirty,
  });

  final String projectRootPath;
  final MapData map;
  final String mapPath;
  final String? mapRevision;
  final ProjectManifest? project;
  final bool mapWasDirty;
  final bool projectWasDirty;
}

final class _PublishedPlacedElementBatch {
  const _PublishedPlacedElementBatch({
    required this.projectRootPath,
    required this.receiptId,
    required this.layerId,
    required this.intent,
    required this.manifest,
    required this.map,
    required this.mapRevision,
  });

  final String projectRootPath;
  final String receiptId;
  final String layerId;
  final PlacedElementMutationIntent intent;
  final ProjectManifest manifest;
  final MapData map;
  final String mapRevision;
}

bool _isPlacedElementRevisionConflict(String code) =>
    code.contains('conflict') ||
    code.contains('stale') ||
    code.contains('revision');

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
