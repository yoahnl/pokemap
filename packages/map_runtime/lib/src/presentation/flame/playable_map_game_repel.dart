part of 'playable_map_game.dart';

extension _PlayableMapRepel on PlayableMapGame {
  Future<bool> _saveRepelExpirationCheckpoint() async {
    if (_hasCheckpointUnsafeRuntimeWorkForSave) return false;
    _syncGameStateFromWorld(mapIdOverride: _activeMapId);
    await repelExpirationCheckpointWriter!(_gameState);
    return true;
  }

  void _advanceRepelForCommittedMovement(CommittedMovement movement) {
    final units = const CommittedMovementStepPolicy(
      forcedMovement: ForcedMovementStepPolicy.include,
    ).unitsFor(movement);
    final previous = _gameState.repelState;
    final next = previous.advance(units);
    if (identical(previous, next)) return;
    _gameState = _gameState.copyWith(repelState: next);
    _syncGameStateFromWorld();
    unawaited(
      _narrativeStateTransactions.transact<void>((state) {
        if (_isRemoved || !identical(_gameState.repelState, next)) {
          return NarrativeEventStateTransaction.rollback(null);
        }
        return NarrativeEventStateTransaction.commit(
          state.copyWith(repelState: next),
          null,
        );
      }),
    );
  }

  void _maybePromptRepelExpiration() {
    if (_repelPromptInFlight ||
        identical(_repelPresentedExpiration, _gameState.repelState) ||
        !_gameState.repelState.expirationPending ||
        _isRemoved ||
        !isLoaded ||
        _player.isStepping ||
        !_canResolveOverworldInteraction() ||
        _hasCheckpointUnsafeRuntimeWorkForSave ||
        _pendingBattleRequest != null ||
        _activeNarrativeSceneWorkingSession != null ||
        _pendingDirectedJump != null ||
        _pendingWarp != null ||
        _pendingTrainerSpot != null ||
        _dialogueOverlay != null) {
      return;
    }
    final expired = _gameState.repelState;
    final canRenew = _gameState.bag.entries.any(
      (entry) => entry.itemId == expired.itemId && entry.quantity > 0,
    );
    final session = DialogueSession.start([
      YarnNode(
        title: 'repel_expired',
        steps: [
          YarnStepLine('L’effet de la Repousse s’est dissipé.'),
          if (canRenew) ...[
            YarnStepLine('Voulez-vous utiliser une autre Repousse identique ?'),
            YarnStepChoiceBlock(
              [
                YarnChoice(text: 'Oui', steps: [], outcomeId: 'repel.renew'),
                YarnChoice(text: 'Non', steps: [], outcomeId: 'repel.decline'),
              ],
              policy: const SceneDialogueChoicePolicy(
                nodeName: 'repel_expired',
                defaultOutcomeId: 'repel.decline',
                cancellation: SceneDialogueChoiceCancellation.choice(
                  'repel.decline',
                ),
              ),
            ),
          ],
        ],
      ),
    ], 'repel_expired');
    if (session == null) return;
    _repelPromptInFlight = true;
    _repelPresentedExpiration = expired;
    unawaited(
      _openDialogue(
        session,
        onDialogueFinished: (outcome) {
          unawaited(
            _finishRepelExpiration(expired, renew: outcome == 'repel.renew'),
          );
        },
        onDialogueFailed: (_) => _repelPromptInFlight = false,
      ).catchError((Object error) {
        _repelPromptInFlight = false;
        debugPrint('[repel] expiration dialogue failed: $error');
      }),
    );
  }

  Future<void> _finishRepelExpiration(
    RepelState expired, {
    required bool renew,
  }) async {
    RuntimeInputLockToken? lock;
    try {
      if (_isRemoved ||
          !identical(_gameState.repelState, expired) ||
          !_canResolveOverworldInteraction()) {
        return;
      }
      final expectedState = _gameState;
      lock = _inputLocks.acquire(
        owner: RuntimeInputLockOwner.playerService,
        surface: RuntimeInputSurface.blocked,
      );
      _clearPressedMovementControls();
      var next = expectedState.copyWith(repelState: const RepelState.empty());
      String? message;
      if (renew) {
        final result = PlayerItemUseService(snapshot: _itemCatalogSnapshot).use(
          PlayerItemUseRequest(
            state: _gameState,
            itemId: expired.itemId,
            context: ProjectItemUseContext.overworld,
          ),
        );
        if (result.isSuccess) {
          next = result.state;
          message = 'La Repousse est de nouveau active.';
        } else {
          message = 'Cette Repousse n’est plus disponible.';
        }
      }
      await commitAndSavePlayerServiceState(next, expectedState: expectedState);
      if (message != null && !_isRemoved) _showNotification(message);
    } catch (error) {
      if (!_isRemoved) {
        _showNotification('La progression n’a pas pu être sauvegardée.');
      }
    } finally {
      if (lock != null) {
        _inputLocks.release(
          owner: RuntimeInputLockOwner.playerService,
          token: lock,
        );
      }
      _repelPromptInFlight = false;
    }
  }
}
