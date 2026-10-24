part of 'playable_map_game.dart';

final class _PendingInteractiveEncounter {
  const _PendingInteractiveEncounter(this.request, this.ticket, this.lock);
  final WildBattleStartRequest request;
  final InteractiveEncounterTicket ticket;
  final RuntimeInputLockToken lock;
}

extension _PlayableMapInteractiveEncounters on PlayableMapGame {
  ScriptEvaluationContext get _interactiveEncounterConditionContext =>
      ScriptEvaluationContext(narrativeFactResolver: _narrativeFactResolver);

  void _beginHeadbuttInteraction(MapEntity entity) {
    final evaluation = evaluateInteractiveEncounter(
      world: _world,
      project: _bundle.manifest,
      gameState: _gameState,
      entity: entity,
      conditionContext: _interactiveEncounterConditionContext,
      encounterContext: _encounterEvaluationContext,
    );
    if (!evaluation.isReady) {
      _showNotification(switch (evaluation.reason) {
        InteractiveEncounterBlockReason.missingMove =>
          'Un Pokémon apte à utiliser Coud’Boule est nécessaire.',
        InteractiveEncounterBlockReason.alreadyConsumed =>
          'Cet arbre ne cache plus de Pokémon pour le moment.',
        InteractiveEncounterBlockReason.unavailableContext =>
          'Placez-vous à pied devant cet arbre pour utiliser Coud’Boule.',
        InteractiveEncounterBlockReason.unsupportedMap =>
          'Les rencontres sur un objet sont disponibles sur les cartes 2D.',
        _ => 'Cet arbre ne permet pas de rencontre pour le moment.',
      });
      return;
    }
    final ticket = _interactiveEncounterTicket(entity);
    if (ticket == null) return;
    final session = DialogueSession.start([
      YarnNode(
        title: 'Headbutt',
        steps: [
          YarnStepLine('Voulez-vous utiliser Coud’Boule sur cet arbre ?'),
          YarnStepChoiceBlock(
            [
              YarnChoice(
                text: 'Oui',
                steps: [],
                outcomeId: 'headbutt-confirmed',
              ),
              YarnChoice(
                text: 'Non',
                steps: [],
                outcomeId: 'headbutt-declined',
              ),
            ],
            policy: const SceneDialogueChoicePolicy(
              nodeName: 'Headbutt',
              cancellation: SceneDialogueChoiceCancellation.choice(
                'headbutt-declined',
              ),
            ),
          ),
        ],
      ),
    ], 'Headbutt');
    if (session == null) {
      _activeInteractiveEncounterAttemptId = null;
      return;
    }
    _openDialogue(
      session,
      onDialogueFinished: (outcome) {
        if (outcome == 'headbutt-confirmed') {
          _resolveInteractiveEncounter(ticket);
        } else if (_activeInteractiveEncounterAttemptId == ticket.attemptId) {
          _activeInteractiveEncounterAttemptId = null;
        }
      },
      onDialogueFailed: (_) {
        if (_activeInteractiveEncounterAttemptId == ticket.attemptId) {
          _activeInteractiveEncounterAttemptId = null;
        }
      },
    );
  }

  InteractiveEncounterTicket? _interactiveEncounterTicket(MapEntity entity) {
    final activation = _currentMapActivationId;
    if (activation == null ||
        _pendingInteractiveEncounter != null ||
        _hasClaimedBattleHandoff ||
        _isRemoved) {
      return null;
    }
    final ticket = InteractiveEncounterTicket(
      attemptId: 'interactive:${++_interactiveEncounterSequence}',
      map: _world.map,
      project: _bundle.manifest,
      gameState: _gameState,
      entity: entity,
      playerPixelPosition: PixelOffset(
        x: _world.player.playerPositionPx.leftPx,
        y: _world.player.playerPositionPx.topPx,
      ),
      issuedAtStateRevision: _gameStateRevision,
      mapActivationId: activation,
    );
    _activeInteractiveEncounterAttemptId = ticket.attemptId;
    return ticket;
  }

  void _resolveInteractiveEncounter(InteractiveEncounterTicket ticket) {
    if (_activeInteractiveEncounterAttemptId != ticket.attemptId) return;
    _activeInteractiveEncounterAttemptId = null;
    if (_pendingInteractiveEncounter != null ||
        _hasClaimedBattleHandoff ||
        _isRemoved ||
        _flowPhase != _RuntimeFlowPhase.overworld) {
      return;
    }
    final result = resolveInteractiveEncounter(
      ticket: ticket,
      world: _world,
      project: _bundle.manifest,
      gameState: _gameState,
      currentStateRevision: _gameStateRevision,
      mapActivationId: _currentMapActivationId,
      conditionContext: _interactiveEncounterConditionContext,
      encounterContext: _encounterEvaluationContext,
      random: _encounterRandom,
    );
    final encounter = result.encounterCheck?.encounter;
    if (encounter == null) {
      _showNotification(
        result.reason == null
            ? 'Aucun Pokémon ne se manifeste…'
            : 'Cette rencontre n’est plus disponible.',
      );
      return;
    }
    final request = buildBattleStartRequestFromEncounter(
      encounter: encounter,
      world: _world,
      encounterSourceSnapshot: ticket.entity.interactiveEncounter!.presentation,
      requestId: 'interactive:${ticket.mapActivationId}:${ticket.attemptId}',
    );
    final lock = _inputLocks.acquire(
      owner: RuntimeInputLockOwner.blockingInteraction,
      surface: RuntimeInputSurface.blocked,
    );
    _pendingInteractiveEncounter = _PendingInteractiveEncounter(
      request,
      ticket,
      lock,
    );
    _clearPressedMovementControls();
    if (!_tryEnqueueBattleRequest(request)) {
      _releaseInteractiveEncounter(request.requestId);
    }
    _publishInputAuthoritySnapshot();
  }

  bool _canContinueInteractiveBattle(BattleStartRequest request) {
    if (request is! WildBattleStartRequest ||
        request.encounterSourceKind != EncounterSourceKind.interactiveObject) {
      return true;
    }
    final pending = _pendingInteractiveEncounter;
    if (pending == null ||
        pending.request.requestId != request.requestId ||
        _isRemoved) {
      return false;
    }
    final expected = pending.ticket.gameState.progression;
    final comparable = _gameState.copyWith(
      progression: _gameState.progression.copyWith(
        seenSpeciesIds: expected.seenSpeciesIds,
        caughtSpeciesIds: expected.caughtSpeciesIds,
      ),
    );
    final current = isInteractiveEncounterCurrent(
      ticket: pending.ticket,
      world: _world,
      project: _bundle.manifest,
      gameState: comparable,
      currentStateRevision: _gameStateRevision,
      mapActivationId: _currentMapActivationId,
    );
    if (!current) _cancelInteractiveEncounter();
    return current;
  }

  void _commitPreparedInteractiveEncounter(BattleStartRequest request) {
    final pending = _pendingInteractiveEncounter;
    if (pending == null || pending.request.requestId != request.requestId) {
      return;
    }
    if (!_canContinueInteractiveBattle(request)) {
      throw StateError(
        'Interactive encounter owner became stale before battle readiness.',
      );
    }
    final payload = pending.ticket.entity.interactiveEncounter!;
    if (payload.reusePolicy ==
        InteractiveEncounterReusePolicy.oncePerMapInstance) {
      final scope = _gameState.mapInstanceWorldState.instanceRef(_activeMapId)!;
      _replaceLogicalMapInstances(
        _gameState.mapInstanceWorldState.consumeInteractiveEncounter(
          scope,
          pending.ticket.entity.id,
        ),
      );
      _gameStateRevision++;
    }
    _releaseInteractiveEncounter(request.requestId);
  }

  void _releaseInteractiveEncounter(String requestId) {
    final pending = _pendingInteractiveEncounter;
    if (pending == null || pending.request.requestId != requestId) return;
    _pendingInteractiveEncounter = null;
    _inputLocks.release(
      owner: RuntimeInputLockOwner.blockingInteraction,
      token: pending.lock,
    );
    if (!_isRemoved) _publishInputAuthoritySnapshot();
  }

  void _cancelInteractiveEncounter() {
    _activeInteractiveEncounterAttemptId = null;
    final pending = _pendingInteractiveEncounter;
    if (pending == null) return;
    if (_pendingBattleRequest?.requestId == pending.request.requestId) {
      _pendingBattleRequest = null;
    }
    _releaseInteractiveEncounter(pending.request.requestId);
    if (!_isRemoved &&
        (_flowPhase == _RuntimeFlowPhase.battleTransition ||
            _activeBattleContext?.request.requestId ==
                pending.request.requestId)) {
      _cancelBattleHandoff(
        request: pending.request,
        userMessage: 'La rencontre a été interrompue.',
      );
    }
  }
}
