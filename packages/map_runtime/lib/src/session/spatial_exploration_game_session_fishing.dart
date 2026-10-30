part of 'spatial_exploration_game_session_runtime.dart';

extension _SpatialSessionFishing on SpatialExplorationGameSessionRuntime {
  bool get _isFishingBusy => _fishingPreparing || _fishingFlow != null;

  GameplayWorldState _fishingWorld(GameState state) {
    final cached = _fishingWorldState;
    if (cached != null &&
        identical(_fishingSourceMap, _session!.bundle.map) &&
        cached.player.pos == state.playerPosition &&
        cached.player.facing == state.playerFacing.asDirection &&
        cached.player.movementMode == state.playerMovementMode) {
      return cached;
    }
    _fishingSourceMap = _session!.bundle.map;
    return _fishingWorldState = _gameplay!.projectWorld();
  }

  ScriptEvaluationContext get _fishingConditions => ScriptEvaluationContext(
    narrativeFactResolver: NarrativeFactRuntimeResolver.fromFacts(
      _session!.bundle.manifest.facts,
    ),
  );

  FishingAttemptEvaluation _evaluateSpatialFishing(
    ProjectItemDefinition item,
    GameState state,
  ) => evaluateFishingAttempt(
    world: _fishingWorld(state),
    project: _session!.bundle.manifest,
    gameState: state,
    item: item,
    conditionContext: _fishingConditions,
    encounterContext: EncounterEvaluationContext.fromLocalTime(_worldNow()),
  );

  Future<FishingBlockReason?> _reserveSpatialFishing(
    ProjectItemDefinition item,
    GameState expected,
  ) async {
    final session = _session;
    if (_disposed ||
        _stopped ||
        session == null ||
        _isFishingBusy ||
        _locks.any((owner) => owner != RuntimeExternalInputLock.pauseMenu) ||
        _gameplay == null ||
        _battle == null ||
        _battle!.isActive ||
        _gameplayOperations > 0 ||
        _materializingState ||
        _activityGate.checkpointInProgress ||
        _activityGate.activity != NarrativeRuntimeActivity.idle ||
        (_gameplay?.isBusy ?? false) ||
        session.transitioning.value ||
        session.interactionActive.value ||
        session.storyInputLocked ||
        session.surfTransitionActive ||
        session.movement.isJumping ||
        !session.movement.isPositionTraversable ||
        (session.movement.groundY -
                    session.bundle.map.spatialScene!.worldHeightAt(
                      session.movement.x,
                      session.movement.z,
                    ))
                .abs() >
            1e-6 ||
        gameStateSnapshot != expected) {
      return FishingBlockReason.unavailableContext;
    }
    final evaluation = _evaluateSpatialFishing(item, expected);
    if (!evaluation.isReady) {
      _fishingWorldState = null;
      _fishingSourceMap = null;
      return evaluation.reason;
    }
    final sequence = ++_fishingSequence;
    final activation = _mapActivationId, pauseEpoch = _transferPauseEpoch;
    _fishingPreparing = true;
    _syncMovement();
    try {
      if (expected.playerMovementMode == MovementMode.bicycle) {
        final next = expected.copyWith(playerMovementMode: MovementMode.walk);
        try {
          final commit = _commitCheckpoint;
          if (commit == null) {
            throw StateError('Checkpoint persistence unavailable.');
          }
          await _activityGate.runCheckpoint(
            NarrativeRuntimeCheckpointOperation.save,
            () => commit(
              GameSessionCheckpointCommit(
                descriptor: descriptor.publicContext,
                checkpoint: _checkpointFromState(next),
                status: SaveStatus.active,
                trigger: GameSessionCheckpointTrigger.pauseMutation,
              ),
            ),
          );
          if (!_disposed &&
              !_stopped &&
              identical(session, _session) &&
              _gameState == expected) {
            _gameState = next;
            session.movement.movementMode = MovementMode.walk;
          }
        } on Object {
          return FishingBlockReason.checkpointFailed;
        }
      }
      if (_disposed ||
          _stopped ||
          sequence != _fishingSequence ||
          pauseEpoch != _transferPauseEpoch ||
          activation != _mapActivationId ||
          !identical(session, _session)) {
        return FishingBlockReason.staleAttempt;
      }
      final state = gameStateSnapshot;
      final refreshed = _evaluateSpatialFishing(item, state);
      if (!refreshed.isReady) return refreshed.reason;
      _fishingTicket = FishingActionTicket(
        attemptId: 'spatial-fishing:$sequence',
        map: _fishingWorld(state).map,
        project: session.bundle.manifest,
        gameState: state,
        item: item,
        issuedAtStateRevision: _loadGeneration,
        mapActivationId: activation,
      );
      _fishingFlow = FishingAttemptFlow();
      _showFishingFeedback('Lancer de la ligne…');
      return null;
    } finally {
      _fishingPreparing = false;
      if (_fishingFlow == null) {
        _fishingWorldState = null;
        _fishingSourceMap = null;
      }
      if (!_disposed) _syncMovement();
    }
  }

  bool _fishingTicketIsCurrent(FishingActionTicket ticket) =>
      !_disposed &&
      !_stopped &&
      identical(ticket, _fishingTicket) &&
      identical(_fishingSourceMap, _session!.bundle.map) &&
      ticket.gameState == gameStateSnapshot &&
      _playerServices?.currentItemDefinition(ticket.item.id) == ticket.item &&
      isFishingAttemptCurrent(
        ticket: ticket,
        world: _fishingWorld(gameStateSnapshot),
        project: _session!.bundle.manifest,
        gameState: gameStateSnapshot,
        item: ticket.item,
        currentStateRevision: _loadGeneration,
        mapActivationId: _mapActivationId,
      );

  void _advanceSpatialFishing(double dt) {
    final flow = _fishingFlow, ticket = _fishingTicket;
    if (flow == null ||
        ticket == null ||
        _fishingHandoffPending ||
        _disposed ||
        _stopped ||
        _paused ||
        _locks.isNotEmpty ||
        _session!.presentationPaused) {
      return;
    }
    try {
      if (!_fishingTicketIsCurrent(ticket) ||
          _session!.transitioning.value ||
          _session!.interactionActive.value ||
          _battle!.isActive) {
        _cancelSpatialFishing();
        return;
      }
      final previous = flow.phase;
      flow.advance(
        dt,
        resolve: () => resolveFishingAttempt(
          ticket: ticket,
          world: _fishingWorld(gameStateSnapshot),
          project: _session!.bundle.manifest,
          gameState: gameStateSnapshot,
          item: ticket.item,
          currentStateRevision: _loadGeneration,
          mapActivationId: _mapActivationId,
          conditionContext: _fishingConditions,
          encounterContext: EncounterEvaluationContext.fromLocalTime(
            _worldNow(),
          ),
          random: _fishingRandom,
        ),
      );
      if (previous != flow.phase) {
        switch (flow.phase) {
          case FishingAttemptPhase.waiting:
            _showFishingFeedback(
              'La ligne est dans l’eau… Retour pour annuler.',
            );
          case FishingAttemptPhase.bite:
            _showFishingFeedback('Ça mord !');
          case FishingAttemptPhase.noBite:
            _showFishingFeedback(
              flow.result?.reason == null
                  ? 'Pas de touche…'
                  : 'La pêche a été interrompue.',
            );
          default:
            break;
        }
      }
      if (flow.phase == FishingAttemptPhase.readyForBattle) {
        final encounter = flow.result?.encounterCheck?.encounter;
        if (encounter != null &&
            _fishingTicketIsCurrent(ticket) &&
            _evaluateSpatialFishing(ticket.item, gameStateSnapshot).isReady) {
          final request = buildBattleStartRequestFromEncounter(
            encounter: encounter,
            world: _fishingWorld(gameStateSnapshot),
          );
          final pauseEpoch = _transferPauseEpoch;
          _fishingHandoffPending = true;
          unawaited(
            _runGameplay(() async {
              try {
                await _startBattle(
                  request,
                  claimStart: () {
                    if (pauseEpoch != _transferPauseEpoch ||
                        _paused ||
                        _locks.isNotEmpty ||
                        !_fishingTicketIsCurrent(ticket) ||
                        _session!.transitioning.value ||
                        _session!.interactionActive.value ||
                        _battle!.isActive) {
                      return false;
                    }
                    _cancelSpatialFishing();
                    return true;
                  },
                );
              } finally {
                if (identical(_fishingTicket, ticket)) _cancelSpatialFishing();
              }
            }),
          );
        } else {
          _cancelSpatialFishing();
        }
      } else if (flow.phase == FishingAttemptPhase.finished ||
          flow.phase == FishingAttemptPhase.cancelled) {
        _cancelSpatialFishing();
      }
    } on Object catch (error) {
      _cancelSpatialFishing();
      if (!_disposed && !_stopped) _session?.interactionError.value = error;
    }
  }

  void _showFishingFeedback(String text) {
    final snapshot = DialoguePresentationSnapshot(
      revision: ++_fishingSequence,
      mode: DialoguePresentationMode.line,
      nodeTitle: null,
      speaker: null,
      text: text,
      fullText: text,
      isCurrentLineFullyRevealed: true,
      isLastContent: false,
      choices: const [],
      isAdvanceAvailable: false,
    );
    _fishingFeedback = snapshot;
    _session!.dialoguePresentation.value = snapshot;
  }

  void _cancelSpatialFishing() {
    _fishingSequence++;
    _fishingFlow?.cancel();
    _fishingFlow = null;
    _fishingHandoffPending = false;
    _fishingTicket = null;
    _fishingWorldState = null;
    _fishingSourceMap = null;
    if (identical(_session?.dialoguePresentation.value, _fishingFeedback)) {
      _session?.dialoguePresentation.value = null;
    }
    _fishingFeedback = null;
    if (!_disposed) _syncMovement();
  }
}
