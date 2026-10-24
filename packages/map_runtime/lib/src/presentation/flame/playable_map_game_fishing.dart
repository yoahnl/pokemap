part of 'playable_map_game.dart';

extension _PlayableMapFishing on PlayableMapGame {
  bool get _isFishingBusy =>
      _fishingPreparationInFlight || _fishingFlow != null;

  ScriptEvaluationContext get _fishingConditionContext =>
      ScriptEvaluationContext(narrativeFactResolver: _narrativeFactResolver);

  Future<FishingBlockReason?> _reservePlayerFishing(
    ProjectItemDefinition item,
    GameState expectedState,
  ) async {
    if (_isRemoved ||
        !isLoaded ||
        _isFishingBusy ||
        _bicycleToggleInFlight ||
        _player.isStepping ||
        _flowPhase != _RuntimeFlowPhase.overworld ||
        _activeNarrativeSceneWorkingSession != null ||
        _hasCheckpointUnsafeRuntimeWorkForSave ||
        playerServiceGameStateSnapshot != expectedState ||
        _currentMapActivationId == null) {
      return FishingBlockReason.unavailableContext;
    }
    final evaluation = evaluateFishingAttempt(
      world: _world,
      project: _bundle.manifest,
      gameState: expectedState,
      item: item,
      conditionContext: _fishingConditionContext,
      encounterContext: _encounterEvaluationContext,
    );
    if (!evaluation.isReady) return evaluation.reason;
    final sequence = ++_fishingAttemptSequence;
    final sourceMap = _world.map;
    final activation = _currentMapActivationId;
    final token = _inputLocks.acquire(
      owner: RuntimeInputLockOwner.playerService,
      surface: RuntimeInputSurface.blocked,
    );
    _fishingInputLock = token;
    _fishingPreparationInFlight = true;
    _clearPressedMovementControls();
    _sprintPressed = false;
    var reserved = false;
    try {
      if (expectedState.playerMovementMode == MovementMode.bicycle) {
        try {
          await commitAndSavePlayerServiceState(
            expectedState.copyWith(playerMovementMode: MovementMode.walk),
            expectedState: expectedState,
          );
        } on Object {
          return FishingBlockReason.checkpointFailed;
        }
      }
      if (_isRemoved ||
          sequence != _fishingAttemptSequence ||
          sourceMap != _world.map ||
          activation != _currentMapActivationId) {
        return FishingBlockReason.staleAttempt;
      }
      final state = playerServiceGameStateSnapshot;
      final refreshed = evaluateFishingAttempt(
        world: _world,
        project: _bundle.manifest,
        gameState: state,
        item: item,
        conditionContext: _fishingConditionContext,
      encounterContext: _encounterEvaluationContext,
      );
      if (!refreshed.isReady) return refreshed.reason;
      _fishingTicket = FishingActionTicket(
        attemptId: 'fishing:$sequence',
        map: _world.map,
        project: _bundle.manifest,
        gameState: state,
        item: item,
        issuedAtStateRevision: _gameStateRevision,
        mapActivationId: activation!,
      );
      _fishingFlow = FishingAttemptFlow();
      _fishingFeedbackPhase = null;
      reserved = true;
      return null;
    } finally {
      _fishingPreparationInFlight = false;
      if (!reserved) {
        _inputLocks.release(
          owner: RuntimeInputLockOwner.playerService,
          token: token,
        );
        if (identical(_fishingInputLock, token)) _fishingInputLock = null;
      }
      if (!_isRemoved) _publishInputAuthoritySnapshot();
    }
  }

  bool _isCurrentFishingTicket(FishingActionTicket ticket) =>
      !_isRemoved &&
      _flowPhase == _RuntimeFlowPhase.overworld &&
      identical(_fishingTicket, ticket) &&
      _playerServiceRuntimeController?.currentItemDefinition(ticket.item.id) ==
          ticket.item &&
      isFishingAttemptCurrent(
        ticket: ticket,
        world: _world,
        project: _bundle.manifest,
        gameState: playerServiceGameStateSnapshot,
        item: ticket.item,
        currentStateRevision: _gameStateRevision,
        mapActivationId: _currentMapActivationId,
      );

  void _advancePlayerFishing(double dt) {
    final flow = _fishingFlow, ticket = _fishingTicket;
    if (flow == null ||
        ticket == null ||
        _fishingPreparationInFlight ||
        isPaused ||
        _externalInputLocks.isNotEmpty ||
        _isRemoved) {
      return;
    }
    try {
      _advanceFishingFlow(flow, ticket, dt);
    } on Object catch (error) {
      _finishPlayerFishing();
      _showNotification('La pêche a été interrompue.');
      debugPrint('[fishing] attempt interrupted: $error');
    }
  }

  void _advanceFishingFlow(
    FishingAttemptFlow flow,
    FishingActionTicket ticket,
    double dt,
  ) {
    if (_fishingFeedbackPhase == null) _showNotification('Lancer de la ligne…');
    flow.advance(
      dt,
      resolve: () {
        if (!_isCurrentFishingTicket(ticket)) {
          return const FishingAttemptResult(
            reason: FishingBlockReason.staleAttempt,
          );
        }
        if (_hasClaimedBattleHandoff) {
          return const FishingAttemptResult(
            reason: FishingBlockReason.handoffBusy,
          );
        }
        return resolveFishingAttempt(
          ticket: ticket,
          world: _world,
          project: _bundle.manifest,
          gameState: playerServiceGameStateSnapshot,
          item: _playerServiceRuntimeController!.currentItemDefinition(
            ticket.item.id,
          )!,
          currentStateRevision: _gameStateRevision,
          mapActivationId: _currentMapActivationId,
          conditionContext: _fishingConditionContext,
      encounterContext: _encounterEvaluationContext,
          random: _encounterRandom,
        );
      },
    );
    if (_fishingFeedbackPhase != flow.phase) {
      _fishingFeedbackPhase = flow.phase;
      switch (flow.phase) {
        case FishingAttemptPhase.waiting:
          _showNotification('La ligne est dans l’eau… Retour pour annuler.');
        case FishingAttemptPhase.bite:
          _showNotification('Ça mord !');
        case FishingAttemptPhase.noBite:
          _showNotification(
            flow.result?.reason == null
                ? 'Pas de touche…'
                : 'La pêche a été interrompue.',
          );
        default:
          break;
      }
    }
    if (flow.phase == FishingAttemptPhase.readyForBattle) {
      try {
        final encounter = flow.result?.encounterCheck?.encounter;
        if (encounter == null ||
            !_isCurrentFishingTicket(ticket) ||
            !evaluateFishingAttempt(
              world: _world,
              project: _bundle.manifest,
              gameState: playerServiceGameStateSnapshot,
              item: ticket.item,
              conditionContext: _fishingConditionContext,
      encounterContext: _encounterEvaluationContext,
            ).isReady ||
            !_tryEnqueueBattleRequest(
              buildBattleStartRequestFromEncounter(
                encounter: encounter,
                world: _world,
              ),
            )) {
          _showNotification('Le combat de pêche n’est plus disponible.');
        }
      } finally {
        _finishPlayerFishing();
      }
    } else if (flow.phase == FishingAttemptPhase.finished ||
        flow.phase == FishingAttemptPhase.cancelled) {
      _finishPlayerFishing();
    }
  }

  void _finishPlayerFishing() {
    final token = _fishingInputLock;
    _fishingInputLock = null;
    _fishingTicket = null;
    _fishingFlow = null;
    _fishingFeedbackPhase = null;
    if (token != null) {
      _inputLocks.release(
        owner: RuntimeInputLockOwner.playerService,
        token: token,
      );
    }
    if (!_isRemoved) _publishInputAuthoritySnapshot();
  }

  void _cancelPlayerFishing({bool notify = true}) {
    if (!_isFishingBusy) return;
    _fishingAttemptSequence++;
    _fishingFlow?.cancel();
    _finishPlayerFishing();
    if (notify && !_isRemoved) _showNotification('Pêche annulée.');
  }
}
