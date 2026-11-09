part of 'playable_map_game.dart';

extension PlayableMapContextualItemUse on PlayableMapGame {
  Set<String> get contextualItemIds {
    final state = playerServiceGameStateSnapshot;
    final snapshot = _cachedNarrativeRuntimeSnapshot;
    final project = snapshot?.project ?? _bundle.manifest;
    return contextualItemUseIds(
      map: _bundle.map,
      project: project,
      state: state,
      conditionContext: PresentationConditionContext(
        project: project,
        map: _bundle.map,
        maps:
            snapshot?.mapsById.values.toList() ??
            _runtimeBundleByMapId.values.map((bundle) => bundle.map).toList(),
        lookupRewardScenes: _lookupRewardScenes,
      ),
    );
  }

  Future<RuntimeContextualItemUseDisposition> _reservePlayerContextualItemUse(
    ProjectItemDefinition item,
    GameState state,
  ) async {
    if (!_bundle.map.contextualItemUses.any((rule) => rule.itemId == item.id))
      return RuntimeContextualItemUseDisposition.noMatch;
    if (_isRemoved ||
        !isLoaded ||
        _hasCheckpointUnsafeRuntimeWorkForSave ||
        playerServiceGameStateSnapshot != state) {
      return RuntimeContextualItemUseDisposition.refused;
    }
    final revision = _gameStateRevision;
    final snapshot = await _narrativeRuntimeSnapshotFor(_bundle.manifest);
    if (_isRemoved ||
        _gameStateRevision != revision ||
        playerServiceGameStateSnapshot != state) {
      return RuntimeContextualItemUseDisposition.refused;
    }
    final selection = selectContextualItemUse(
      map: _bundle.map,
      project: snapshot.project,
      state: state,
      itemId: item.id,
      conditionContext: PresentationConditionContext(
        project: snapshot.project,
        map: _bundle.map,
        maps: snapshot.mapsById.values.toList(),
        lookupRewardScenes: snapshot.projectCatalog.rewardScenes,
      ),
    );
    if (selection is ContextualItemUseNoMatch)
      return RuntimeContextualItemUseDisposition.noMatch;
    if (selection is! ContextualItemUseMatched ||
        (overworldCheckpointWriter == null &&
            _saveRepo is! FileGameSaveRepository))
      return RuntimeContextualItemUseDisposition.refused;
    _pendingContextualItemUse = (
      rule: selection.rule,
      state: state,
      revision: revision,
      activation: _currentMapActivationId,
    );
    return RuntimeContextualItemUseDisposition.reserved;
  }

  void resumeContextualItemUse() {
    if (_isRemoved || isPaused) return;
    final pending = _pendingContextualItemUse;
    _pendingContextualItemUse = null;
    if (pending == null) return;
    final generation = _contextualItemUseGeneration;
    bool current() => !_isRemoved && generation == _contextualItemUseGeneration;
    final source = 'contextual-item:${pending.rule.id}';
    final serial = _beginBlockingInteraction(source: source);
    _runDetachedNarrativeTask(
      operation: source,
      task: () async {
        try {
          if (!current() ||
              _gameStateRevision != pending.revision ||
              _currentMapActivationId != pending.activation ||
              playerServiceGameStateSnapshot != pending.state ||
              inputAuthoritySnapshot.externalLocks.isNotEmpty) {
            throw StateError('The contextual item reservation is stale.');
          }
          final snapshot = await _narrativeRuntimeSnapshotFor(_bundle.manifest);
          final selection = selectContextualItemUse(
            map: _bundle.map,
            project: snapshot.project,
            state: pending.state,
            itemId: pending.rule.itemId,
            conditionContext: PresentationConditionContext(
              project: snapshot.project,
              map: _bundle.map,
              maps: snapshot.mapsById.values.toList(),
              lookupRewardScenes: snapshot.projectCatalog.rewardScenes,
            ),
          );
          if (!current() ||
              selection is! ContextualItemUseMatched ||
              selection.rule != pending.rule ||
              !pending.state.bag.entries.any(
                (entry) =>
                    entry.itemId == pending.rule.itemId && entry.quantity > 0,
              )) {
            throw StateError(
              'The contextual item rule is no longer applicable.',
            );
          }
          await _narrativeActivityGate.runWithActivity(
            NarrativeRuntimeActivity.sceneActive,
            () async {
              final result = await _narrativeStateTransactions
                  .transact<NarrativeSceneExecutionResult>((_) async {
                    final result = await _executeNarrativeScene(
                      NarrativeSceneExecutionRequest(
                        eventId: _nextNarrativeRuntimeId('evt'),
                        sceneId: pending.rule.sceneId,
                        executionId: _nextNarrativeRuntimeId('evx'),
                        gameState: pending.state,
                      ),
                      checkpointContextualUse: true,
                      contextualUseCurrent: current,
                    );
                    return result is NarrativeSceneExecutionCompleted
                        ? NarrativeEventStateTransaction.commit(
                            result.updatedGameState,
                            result,
                          )
                        : NarrativeEventStateTransaction.rollback(result);
                  });
              if (!current()) return;
              final committed = await _narrativeStateTransactions.read();
              if (!current()) return;
              _applyNarrativeGameState(committed);
              if (result is! NarrativeSceneExecutionCompleted)
                throw StateError(
                  'The contextual item Scene was cancelled or failed.',
                );
            },
          );
          if (current()) await _drainLiveNarrativeOutcomeOutbox();
        } finally {
          if (!_isRemoved)
            _releaseBlockingInteraction(
              serial: serial,
              source: source,
              reason: 'contextualItemFinished',
            );
        }
      },
    );
  }

  void cancelContextualItemUse() {
    _pendingContextualItemUse = null;
    _contextualItemUseGeneration++;
  }
}
