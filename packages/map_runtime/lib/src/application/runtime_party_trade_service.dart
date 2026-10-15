part of 'player_service_runtime_controller.dart';

extension RuntimePartyTradeService on PlayerServiceRuntimeController {
  Future<PlayerServiceRuntimeResult> openPartyTrade({
    required OpenPartyTradeService request,
  }) async {
    if (_disposed) {
      return PlayerServiceRuntimeResult.failed(
        StateError('Player service disposed.'),
      );
    }
    if (_active) return const PlayerServiceRuntimeResult.busy();
    final initial = _currentGameState();
    final denied = _worldRequestUnavailableReason(request, initial);
    if (denied != null) return PlayerServiceRuntimeResult.unavailable(denied);
    final root = _projectRootDirectory;
    final config = _pokemonConfig;
    final ids = initial.party.members
        .map((pokemon) => pokemon.individualId)
        .toList();
    if (root == null ||
        config == null ||
        ids.isEmpty ||
        ids.any((id) => id.isEmpty) ||
        ids.toSet().length != ids.length) {
      return const PlayerServiceRuntimeResult.unavailable(
        'L’équipe et son catalogue doivent être disponibles pour cet échange.',
      );
    }
    final session = _ContextualPartyTradeSession(
      request: request,
      initialState: initial,
    );
    _partyTradeSession = session;
    _active = true;
    var locked = false;
    try {
      _setInputLocked(true);
      locked = true;
      for (final pokemon in initial.party.members) {
        final species = await _pokemonSpeciesLoader.loadById(
          projectRootDirectory: root,
          pokemonConfig: config,
          speciesId: pokemon.speciesId,
        );
        if (!_tradeContinues(session)) return await session.result.future;
        session.speciesById[pokemon.speciesId] = species;
        session.members.add(
          RuntimePartyTradePokemonSnapshot(
            individualId: pokemon.individualId,
            speciesId: pokemon.speciesId,
            label: pokemon.nickname.isEmpty
                ? species.displayName(_locale)
                : pokemon.nickname,
            level: pokemon.level,
          ),
        );
      }
      if (_currentGameState() != initial) {
        throw StateError('The party changed while opening the trade.');
      }
      _publishPartyTrade(session);
      return await session.result.future;
    } catch (error) {
      return PlayerServiceRuntimeResult.failed(error);
    } finally {
      if (identical(_partyTradeSession, session)) {
        _partyTradeSession = null;
        _publishWorldService(null);
      }
      if (locked) _setInputLocked(false);
      _active = false;
    }
  }

  bool _tradeContinues(_ContextualPartyTradeSession session) =>
      !_disposed &&
      identical(_partyTradeSession, session) &&
      !session.result.isCompleted;

  Future<RuntimeWorldServiceCommandResult> _dispatchPartyTrade(
    _ContextualPartyTradeSession session,
    RuntimeWorldServiceCommand command,
  ) async {
    if (session.result.isCompleted) {
      return const RuntimeWorldServiceCommandResult(
        status: RuntimeWorldServiceCommandStatus.stale,
      );
    }
    if (command.action == RuntimeWorldServiceAction.cancel ||
        command.action == RuntimeWorldServiceAction.close) {
      session.result.complete(
        session.phase == RuntimePartyTradePhase.completed
            ? PlayerServiceRuntimeResult.completed(session.completedState!)
            : session.failure != null
            ? PlayerServiceRuntimeResult.failed(session.failure!)
            : const PlayerServiceRuntimeResult.cancelled(),
      );
      return const RuntimeWorldServiceCommandResult(
        status: RuntimeWorldServiceCommandStatus.accepted,
      );
    }
    if (_currentGameState() != session.initialState) {
      session.failure = StateError('The party changed before the trade.');
      _publishPartyTrade(session);
      return const RuntimeWorldServiceCommandResult(
        status: RuntimeWorldServiceCommandStatus.stale,
      );
    }
    if (command.action == RuntimeWorldServiceAction.select) {
      final id = command.targetId;
      switch (session.phase) {
        case RuntimePartyTradePhase.selectFirst:
          if (!session.members.any((member) => member.individualId == id)) {
            return const RuntimeWorldServiceCommandResult(
              status: RuntimeWorldServiceCommandStatus.unavailable,
            );
          }
          session.firstIndividualId = id;
          session.phase = RuntimePartyTradePhase.choosePartner;
        case RuntimePartyTradePhase.choosePartner:
          if (id == RuntimePartyTradeServiceContent.samePartnerTarget) {
            session.partnerIndividualId = session.firstIndividualId;
            session.phase = RuntimePartyTradePhase.review;
          } else if (id == RuntimePartyTradeServiceContent.otherPartnerTarget) {
            session.phase = RuntimePartyTradePhase.selectPartner;
          } else {
            return const RuntimeWorldServiceCommandResult(
              status: RuntimeWorldServiceCommandStatus.unavailable,
            );
          }
        case RuntimePartyTradePhase.selectPartner:
          if (!session.members.any((member) => member.individualId == id)) {
            return const RuntimeWorldServiceCommandResult(
              status: RuntimeWorldServiceCommandStatus.unavailable,
            );
          }
          session.partnerIndividualId = id;
          session.phase = RuntimePartyTradePhase.review;
        case RuntimePartyTradePhase.review:
        case RuntimePartyTradePhase.completed:
          return const RuntimeWorldServiceCommandResult(
            status: RuntimeWorldServiceCommandStatus.unavailable,
          );
      }
      _publishPartyTrade(session);
      return const RuntimeWorldServiceCommandResult(
        status: RuntimeWorldServiceCommandStatus.accepted,
      );
    }
    if (command.action != RuntimeWorldServiceAction.confirm ||
        session.phase != RuntimePartyTradePhase.review ||
        session.failure != null) {
      return const RuntimeWorldServiceCommandResult(
        status: RuntimeWorldServiceCommandStatus.unavailable,
      );
    }
    _publishPartyTrade(session, applying: true);
    try {
      final first = session.initialState.party.members.singleWhere(
        (pokemon) => pokemon.individualId == session.firstIndividualId,
      );
      final candidates = await _evolutionLoader.loadTradeCandidates(
        projectRootDirectory: _projectRootDirectory!,
        pokemonConfig: _pokemonConfig!,
        sourceSpeciesId: first.speciesId,
      );
      if (!_tradeContinues(session)) {
        return const RuntimeWorldServiceCommandResult(
          status: RuntimeWorldServiceCommandStatus.cancelled,
        );
      }
      final catalog = await _resolveItemCatalog();
      if (!_tradeContinues(session)) {
        return const RuntimeWorldServiceCommandResult(
          status: RuntimeWorldServiceCommandStatus.cancelled,
        );
      }
      if (_currentGameState() != session.initialState) {
        throw StateError('The party changed while resolving trade data.');
      }
      final stats = _calculatedStatsFor(
        session.speciesById[first.speciesId],
        first,
      );
      if (stats == null) throw StateError('Invalid native stats for trade.');
      final result = const PokemonPartyTradeOperations().trade(
        session.initialState,
        ruleset: _pokemonConfig.ruleset,
        firstIndividualId: session.firstIndividualId!,
        partnerIndividualId: session.partnerIndividualId!,
        candidates: candidates,
        sourceMaxHp: stats.maxHp,
        heldItemPolicy: resolveRuntimeEvolutionHeldItemPolicy(catalog),
      );
      if (!result.isSuccess) {
        throw StateError('Native trade refused: ${result.failure}');
      }
      session.completionMessage = 'Échange terminé.';
      final evolved = result.evolution;
      if (evolved != null) {
        final target = await _pokemonSpeciesLoader.loadById(
          projectRootDirectory: _projectRootDirectory,
          pokemonConfig: _pokemonConfig,
          speciesId: evolved.pokemon.speciesId,
        );
        if (!_tradeContinues(session)) {
          return const RuntimeWorldServiceCommandResult(
            status: RuntimeWorldServiceCommandStatus.cancelled,
          );
        }
        if (_currentGameState() != session.initialState) {
          throw StateError('The party changed before saving the trade.');
        }
        session.completionMessage =
            '${session.members.singleWhere((member) => member.individualId == first.individualId).label} est devenu ${target.displayName(_locale)}.';
      }
      session.pendingState = result.state;
      session.pendingCommit = Future<void>.sync(
        () => _commitAndSave(result.state),
      );
      await session.pendingCommit;
      session.completedState = result.state;
      session.phase = RuntimePartyTradePhase.completed;
      if (_disposed) {
        if (!session.result.isCompleted) {
          session.result.complete(
            PlayerServiceRuntimeResult.completed(result.state),
          );
        }
      } else {
        _publishPartyTrade(session);
      }
      return const RuntimeWorldServiceCommandResult(
        status: RuntimeWorldServiceCommandStatus.accepted,
      );
    } catch (error) {
      session.failure = error;
      if (_disposed) {
        if (!session.result.isCompleted) {
          session.result.complete(PlayerServiceRuntimeResult.failed(error));
        }
      } else {
        _publishPartyTrade(session);
      }
      return const RuntimeWorldServiceCommandResult(
        status: RuntimeWorldServiceCommandStatus.failed,
        safeMessage: 'L’échange n’a pas pu être enregistré.',
      );
    }
  }

  void _publishPartyTrade(
    _ContextualPartyTradeSession session, {
    bool applying = false,
  }) {
    final previous = _worldServiceSnapshot?.revision ?? -1;
    _partyTradeRevision =
        (_partyTradeRevision > previous ? _partyTradeRevision : previous) + 1;
    final failed = session.failure != null;
    final completed = session.phase == RuntimePartyTradePhase.completed;
    _publishWorldService(
      RuntimeWorldServiceSnapshot(
        revision: _partyTradeRevision,
        request: session.request,
        stage: applying
            ? RuntimeWorldServiceStage.applying
            : failed
            ? RuntimeWorldServiceStage.failed
            : completed
            ? RuntimeWorldServiceStage.completed
            : RuntimeWorldServiceStage.active,
        content: RuntimePartyTradeServiceContent(
          phase: session.phase,
          members: session.members,
          firstIndividualId: session.firstIndividualId,
          partnerIndividualId: session.partnerIndividualId,
          completionMessage: session.completionMessage,
        ),
        safeMessage: failed ? 'L’échange n’a pas pu être enregistré.' : null,
        actions: [
          if (!applying) ...[
            if (!failed && !completed) ...[
              RuntimeWorldServiceActionAvailability.enabled(
                session.phase == RuntimePartyTradePhase.review
                    ? RuntimeWorldServiceAction.confirm
                    : RuntimeWorldServiceAction.select,
              ),
              const RuntimeWorldServiceActionAvailability.enabled(
                RuntimeWorldServiceAction.cancel,
              ),
            ],
            const RuntimeWorldServiceActionAvailability.enabled(
              RuntimeWorldServiceAction.close,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _disposePartyTrade() async {
    final trade = _partyTradeSession;
    if (trade == null || trade.result.isCompleted) return;
    final pending = trade.pendingCommit;
    if (pending == null) {
      trade.result.complete(const PlayerServiceRuntimeResult.cancelled());
    } else {
      try {
        await pending;
        if (!trade.result.isCompleted) {
          trade.result.complete(
            PlayerServiceRuntimeResult.completed(trade.pendingState!),
          );
        }
      } catch (error) {
        if (!trade.result.isCompleted) {
          trade.result.complete(PlayerServiceRuntimeResult.failed(error));
        }
      }
    }
  }
}

final class _ContextualPartyTradeSession {
  _ContextualPartyTradeSession({
    required this.request,
    required this.initialState,
  });
  final OpenPartyTradeService request;
  final GameState initialState;
  final result = Completer<PlayerServiceRuntimeResult>();
  final speciesById = <String, RuntimePokemonSpecies>{};
  final members = <RuntimePartyTradePokemonSnapshot>[];
  RuntimePartyTradePhase phase = RuntimePartyTradePhase.selectFirst;
  String? firstIndividualId, partnerIndividualId;
  String? completionMessage;
  Object? failure;
  Future<void>? pendingCommit;
  GameState? pendingState, completedState;
}
