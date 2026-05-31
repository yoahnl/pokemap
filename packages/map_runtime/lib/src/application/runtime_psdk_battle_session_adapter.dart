import 'package:map_battle/map_battle.dart';

/// Runtime adapter around the clean PSDK battle facade.
///
/// The playable runtime still talks in the legacy `PlayerBattleChoice` command
/// vocabulary. This adapter keeps that UI contract stable while routing the
/// actual turn execution through `BattleSessionFacade.fromPsdkSetup`.
final class RuntimePsdkBattleSessionAdapter {
  RuntimePsdkBattleSessionAdapter._(this._facade);

  factory RuntimePsdkBattleSessionAdapter.fromSetup(
    PsdkBattleSetup setup, {
    PsdkBattleAi opponentAi = const PsdkBattleAi(level: 2),
  }) {
    return RuntimePsdkBattleSessionAdapter._(
      BattleSessionFacade.fromPsdkSetup(
        setup: setup,
        opponentAi: opponentAi,
      ),
    );
  }

  final BattleSessionFacade _facade;
  BattleDecision? _lastDecision;
  BattleEngineTurnResult? _lastTurnResult;

  BattlePublicState get state => _facade.state;
  BattleEngineDecisionRequest get decisionRequest => _facade.decisionRequest;

  BattleSession createLegacyDisplaySession({
    required bool isTrainerBattle,
    String? trainerId,
    bool allowCapture = false,
  }) {
    final outcome = state.isFinished
        ? createLegacyOutcome(
            isTrainerBattle: isTrainerBattle,
            trainerId: trainerId,
            allowCapture: allowCapture,
          )
        : null;
    return createBattleSession(
      _toLegacyDisplaySetup(
        isTrainerBattle: isTrainerBattle,
        trainerId: trainerId,
        allowCapture: allowCapture,
      ),
    ).withRuntimeDisplayState(
      phase: state.isFinished ? BattlePhase.finished : BattlePhase.playerChoice,
      currentTurn: _toLegacyDisplayTurnResult(),
      outcome: outcome,
    );
  }

  BattleOutcome createLegacyOutcome({
    required bool isTrainerBattle,
    String? trainerId,
    bool allowCapture = false,
  }) {
    final finalState = _toLegacyDisplayState(phase: BattlePhase.finished);
    return BattleOutcome(
      type: _legacyOutcomeType(),
      finalState: finalState,
    );
  }

  BattleEngineTurnResult submitDecision(BattleDecision decision) {
    final result = _facade.submit(decision);
    _lastDecision = decision;
    _lastTurnResult = result;
    return result;
  }

  BattleEngineTurnResult submitPlayerChoice(PlayerBattleChoice choice) {
    return submitDecision(_decisionForChoice(choice));
  }

  BattleEngineTurnResult submitHpHealItem({
    required String itemId,
    required PsdkBattleItemActionEffect effect,
  }) {
    return submitDecision(
      BattleDecision.item(
        itemId: itemId,
        target: psdkPlayerSlot,
        effect: effect,
        highPriority: true,
      ),
    );
  }

  BattleDecision _decisionForChoice(PlayerBattleChoice choice) {
    return switch (choice) {
      PlayerBattleChoiceFight(:final moveIndex) =>
        BattleDecision.fight(moveSlot: moveIndex),
      PlayerBattleChoiceSwitch(:final reserveIndex) =>
        BattleDecision.switchPokemon(
          partyIndex: _partyIndexForReserveChoice(reserveIndex),
        ),
      PlayerBattleChoiceRun() => const BattleDecision.flee(),
      PlayerBattleChoiceCapture() => throw UnsupportedError(
          'PSDK battle runtime capture choice is not wired yet.',
        ),
      PlayerBattleChoiceContinue() => const BattleDecision.noAction(),
    };
  }

  BattleTurnResult? _toLegacyDisplayTurnResult() {
    final decision = _lastDecision;
    final result = _lastTurnResult;
    if (decision == null || result == null) {
      return null;
    }

    final timeline = <BattleTurnEvent>[];
    final executions = <BattleMoveExecution>[];
    final bagHpHealItemEvents = <BattleBagHpHealItemEvent>[];
    for (final event in result.timeline.events) {
      if (event is BattleDamageTimelineEvent) {
        final execution = _toLegacyDamageExecution(event);
        executions.add(execution);
        timeline.add(BattleTurnExecutionEvent(execution));
      } else if (event is BattleHealTimelineEvent &&
          event.moveId?.startsWith('item:') == true) {
        final itemKind = _legacyHpHealItemKind(
          event.moveId!.substring('item:'.length),
        );
        if (itemKind == null) {
          continue;
        }
        final itemEvent = _toLegacyBagHpHealItemEvent(
          itemKind: itemKind,
          event: event,
        );
        bagHpHealItemEvents.add(itemEvent);
        timeline.add(BattleTurnBagHpHealItemEvent(itemEvent));
      }
    }

    return BattleTurnResult(
      playerAction: _toLegacyPlayerAction(decision),
      enemyAction: _toLegacyOpponentAction(result),
      executions: List<BattleMoveExecution>.unmodifiable(executions),
      bagHpHealItemEvents:
          List<BattleBagHpHealItemEvent>.unmodifiable(bagHpHealItemEvents),
      timeline: List<BattleTurnEvent>.unmodifiable(timeline),
    );
  }

  BattleAction _toLegacyOpponentAction(BattleEngineTurnResult result) {
    for (final event in result.timeline.events) {
      if (event is BattleMoveDeclaredTimelineEvent &&
          _samePosition(event.user, psdkOpponentSlot)) {
        return BattleActionFight(
          _legacyMoveForTimelineMove(
            user: event.user,
            moveId: event.moveId,
            moveName: event.moveName,
          ),
          moveIndex: _moveIndexForTimelineMove(
            user: event.user,
            moveId: event.moveId,
          ),
        );
      }
    }
    return const BattleActionNone();
  }

  BattleMoveExecution _toLegacyDamageExecution(
      BattleDamageTimelineEvent event) {
    final attackerSide = _legacySideForPosition(event.user);
    final targetSide = _legacySideForPosition(event.target);
    final move = _legacyMoveForTimelineDamage(event);
    return BattleMoveExecution(
      attackerSlot: BattleSlotRef.active(attackerSide),
      move: move,
      targetKind: BattleMoveExecutionTargetKind.combatant,
      targetSlot: BattleSlotRef.active(targetSide),
      damage: event.damage,
      didHit: true,
      didCrit: event.critical ?? false,
      typeEffectivenessMultiplier: event.effectiveness ?? 1.0,
    );
  }

  BattleBagHpHealItemEvent _toLegacyBagHpHealItemEvent({
    required BattleBagHpHealItemKind itemKind,
    required BattleHealTimelineEvent event,
  }) {
    final side = _legacySideForPosition(event.target);
    final target = state.psdkState.battlerAt(
      PsdkBattleSlotRef(
          bank: event.target.bank, position: event.target.position),
    );
    return BattleBagHpHealItemEvent(
      itemKind: itemKind,
      side: side,
      targetLineupIndex: _lineupIndexFromPsdkId(target.id),
      targetSpeciesId: target.speciesId,
      hpBefore: event.remainingHp - event.amount,
      hpAfter: event.remainingHp,
    );
  }

  BattleAction _toLegacyPlayerAction(BattleDecision decision) {
    return switch (decision) {
      BattleFightDecision(:final moveSlot) => BattleActionFight(
          _toLegacyMove(
            state.psdkState.battlerAt(psdkPlayerSlot).moves[moveSlot],
          ),
          moveIndex: moveSlot,
        ),
      BattleItemDecision(:final itemId, :final target, :final effect) =>
        _toLegacyBattleItemAction(
          itemId: itemId,
          target: target,
          effect: effect,
        ),
      BattleFleeDecision() => const BattleActionRun(),
      BattleSwitchDecision() ||
      BattleMegaDecision() ||
      BattleShiftDecision() ||
      BattleNoActionDecision() =>
        const BattleActionNone(),
    };
  }

  BattleActionBagHpHealItemUse _toLegacyBattleItemAction({
    required String itemId,
    required PsdkBattleSlotRef target,
    required PsdkBattleItemActionEffect effect,
  }) {
    final itemKind = _legacyHpHealItemKind(itemId);
    if (itemKind == null) {
      throw UnsupportedError(
        'PSDK battle runtime display only supports HP-heal item narration for now (itemId=$itemId).',
      );
    }
    return BattleActionBagHpHealItemUse(
      itemKind: itemKind,
      targetLineupIndex: _lineupIndexFromPsdkId(
        state.psdkState.battlerAt(target).id,
      ),
      effect: _toLegacyHpHealEffect(effect),
    );
  }

  BattleBagHpHealEffect _toLegacyHpHealEffect(
    PsdkBattleItemActionEffect effect,
  ) {
    return switch (effect) {
      PsdkBattleHpHealItemEffect(:final restoreToFull, :final amount) =>
        restoreToFull
            ? const BattleBagRestoreToFullHpHealEffect()
            : BattleBagFlatHpHealEffect(amount!),
      PsdkBattleStatusCureItemEffect() => throw UnsupportedError(
          'PSDK battle runtime display only supports HP-heal item narration for now.',
        ),
    };
  }

  BattleMove _legacyMoveForTimelineDamage(BattleDamageTimelineEvent event) {
    final attacker = state.psdkState.battlerAt(
      PsdkBattleSlotRef(bank: event.user.bank, position: event.user.position),
    );
    for (final move in attacker.moves) {
      if (move.id == event.moveId) {
        return _toLegacyMove(move);
      }
    }
    return BattleMove(
      id: event.moveId,
      name: event.moveId,
      power: event.damage,
    );
  }

  BattleMove _legacyMoveForTimelineMove({
    required BattlePositionRef user,
    required String moveId,
    required String moveName,
  }) {
    final attacker = state.psdkState.battlerAt(
      PsdkBattleSlotRef(bank: user.bank, position: user.position),
    );
    for (final move in attacker.moves) {
      if (move.id == moveId) {
        return _toLegacyMove(move);
      }
    }
    return BattleMove(
      id: moveId,
      name: moveName,
      power: 0,
    );
  }

  int _moveIndexForTimelineMove({
    required BattlePositionRef user,
    required String moveId,
  }) {
    final attacker = state.psdkState.battlerAt(
      PsdkBattleSlotRef(bank: user.bank, position: user.position),
    );
    for (var index = 0; index < attacker.moves.length; index += 1) {
      if (attacker.moves[index].id == moveId) {
        return index;
      }
    }
    return 0;
  }

  BattleSideId _legacySideForPosition(BattlePositionRef position) {
    return position.bank == psdkPlayerSlot.bank
        ? BattleSideId.player
        : BattleSideId.enemy;
  }

  bool _samePosition(BattlePositionRef position, PsdkBattleSlotRef slot) {
    return position.bank == slot.bank && position.position == slot.position;
  }

  BattleBagHpHealItemKind? _legacyHpHealItemKind(String itemId) {
    return switch (itemId) {
      'potion' => BattleBagHpHealItemKind.potion,
      'super-potion' => BattleBagHpHealItemKind.superPotion,
      'hyper-potion' => BattleBagHpHealItemKind.hyperPotion,
      'max-potion' => BattleBagHpHealItemKind.maxPotion,
      _ => null,
    };
  }

  int _partyIndexForReserveChoice(int reserveIndex) {
    final switchChoices = decisionRequest.switchChoices;
    if (reserveIndex < 0 || reserveIndex >= switchChoices.length) {
      throw RangeError.index(
        reserveIndex,
        switchChoices,
        'reserveIndex',
      );
    }
    return switchChoices[reserveIndex].partyIndex;
  }

  BattleSetup _toLegacyDisplaySetup({
    required bool isTrainerBattle,
    required String? trainerId,
    required bool allowCapture,
  }) {
    final psdkState = state.psdkState;
    return BattleSetup(
      playerPokemon: _toLegacyCombatantData(
        psdkState.battlerAt(psdkPlayerSlot),
      ),
      playerReservePokemon: _legacyReserveForBank(
        bank: psdkPlayerSlot.bank,
        activeId: psdkState.battlerAt(psdkPlayerSlot).id,
      ),
      enemyPokemon: _toLegacyCombatantData(
        psdkState.battlerAt(psdkOpponentSlot),
      ),
      enemyReservePokemon: _legacyReserveForBank(
        bank: psdkOpponentSlot.bank,
        activeId: psdkState.battlerAt(psdkOpponentSlot).id,
      ),
      isTrainerBattle: isTrainerBattle,
      trainerId: trainerId,
      allowCapture: allowCapture,
      fieldState: _toLegacyFieldState(psdkState.field),
    );
  }

  BattleState _toLegacyDisplayState({required BattlePhase phase}) {
    final psdkState = state.psdkState;
    return BattleState(
      phase: phase,
      player: _toLegacyCombatant(psdkState.battlerAt(psdkPlayerSlot)),
      playerReserve: _legacyReserveCombatantsForBank(
        bank: psdkPlayerSlot.bank,
        activeId: psdkState.battlerAt(psdkPlayerSlot).id,
      ),
      enemy: _toLegacyCombatant(psdkState.battlerAt(psdkOpponentSlot)),
      enemyReserve: _legacyReserveCombatantsForBank(
        bank: psdkOpponentSlot.bank,
        activeId: psdkState.battlerAt(psdkOpponentSlot).id,
      ),
      field: _toLegacyFieldState(psdkState.field),
      currentTurn: null,
      outcome: null,
    );
  }

  List<BattleCombatantData> _legacyReserveForBank({
    required int bank,
    required String activeId,
  }) {
    return <BattleCombatantData>[
      for (final combatant in state.psdkState.partyForBank(bank))
        if (combatant.id != activeId) _toLegacyCombatantData(combatant),
    ];
  }

  List<BattleCombatant> _legacyReserveCombatantsForBank({
    required int bank,
    required String activeId,
  }) {
    return <BattleCombatant>[
      for (final combatant in state.psdkState.partyForBank(bank))
        if (combatant.id != activeId) _toLegacyCombatant(combatant),
    ];
  }

  BattleCombatantData _toLegacyCombatantData(PsdkBattleCombatant combatant) {
    return BattleCombatantData(
      speciesId: combatant.speciesId,
      level: combatant.level,
      maxHp: combatant.maxHp,
      currentHp: combatant.currentHp,
      stats: _toLegacyStats(combatant.stats),
      lineupIndex: _lineupIndexFromPsdkId(combatant.id),
      typing: _toLegacyTyping(combatant.types),
      majorStatus: _toLegacyMajorStatus(combatant.majorStatus),
      abilityId: combatant.abilityId ?? 'unknown',
      moves: combatant.moves.map(_toLegacyMoveData).toList(growable: false),
    );
  }

  BattleCombatant _toLegacyCombatant(PsdkBattleCombatant combatant) {
    return BattleCombatant(
      speciesId: combatant.speciesId,
      lineupIndex: _lineupIndexFromPsdkId(combatant.id),
      level: combatant.level,
      currentHp: combatant.currentHp,
      maxHp: combatant.maxHp,
      stats: _toLegacyStats(combatant.stats),
      typing: _toLegacyTyping(combatant.types),
      majorStatus: _toLegacyMajorStatus(combatant.majorStatus),
      abilityId: combatant.abilityId ?? 'unknown',
      moves: combatant.moves.map(_toLegacyMove).toList(growable: false),
      statStages: _toLegacyStatStages(combatant.statStages),
    );
  }

  BattleMoveData _toLegacyMoveData(PsdkBattleMoveData move) {
    return BattleMoveData(
      id: move.id,
      name: move.name,
      power: move.power,
      type: move.type,
      category: _toLegacyMoveCategory(move.category),
      target: _toLegacyMoveTarget(move.target),
      accuracy: _toLegacyMoveAccuracy(move.accuracy),
      pp: move.pp,
      currentPp: move.currentPp,
      priority: move.priority,
      critRatio: move.criticalRate <= 0 ? 1 : move.criticalRate,
    );
  }

  BattleMove _toLegacyMove(PsdkBattleMoveData move) {
    return BattleMove(
      id: move.id,
      name: move.name,
      power: move.power,
      type: move.type,
      category: _toLegacyMoveCategory(move.category),
      target: _toLegacyMoveTarget(move.target),
      accuracy: _toLegacyMoveAccuracy(move.accuracy),
      pp: move.pp,
      currentPp: move.currentPp,
      priority: move.priority,
      critRatio: move.criticalRate <= 0 ? 1 : move.criticalRate,
    );
  }

  BattleStatsSnapshot _toLegacyStats(PsdkBattleStats stats) {
    return BattleStatsSnapshot(
      attack: stats.attack,
      defense: stats.defense,
      specialAttack: stats.specialAttack,
      specialDefense: stats.specialDefense,
      speed: stats.speed,
    );
  }

  BattleTypingSnapshot _toLegacyTyping(PsdkBattleTypes types) {
    return BattleTypingSnapshot(
      primaryType: types.primary,
      secondaryType: types.secondary,
    );
  }

  BattleStatStages _toLegacyStatStages(PsdkBattleStatStages stages) {
    return BattleStatStages(
      attack: stages.valueOf('attack'),
      defense: stages.valueOf('defense'),
      specialAttack: stages.valueOf('specialAttack'),
      specialDefense: stages.valueOf('specialDefense'),
      speed: stages.valueOf('speed'),
    );
  }

  BattleMajorStatusState? _toLegacyMajorStatus(PsdkBattleMajorStatus? status) {
    return switch (status) {
      PsdkBattleMajorStatus.paralysis => const BattleMajorStatusState.par(),
      PsdkBattleMajorStatus.burn => const BattleMajorStatusState.brn(),
      PsdkBattleMajorStatus.poison => const BattleMajorStatusState.psn(),
      PsdkBattleMajorStatus.toxic => const BattleMajorStatusState.tox(),
      PsdkBattleMajorStatus.sleep ||
      PsdkBattleMajorStatus.freeze ||
      null =>
        null,
    };
  }

  BattleMoveCategory _toLegacyMoveCategory(PsdkBattleMoveCategory category) {
    return switch (category) {
      PsdkBattleMoveCategory.physical => BattleMoveCategory.physical,
      PsdkBattleMoveCategory.special => BattleMoveCategory.special,
      PsdkBattleMoveCategory.status => BattleMoveCategory.status,
    };
  }

  BattleMoveTarget _toLegacyMoveTarget(PsdkBattleMoveTarget target) {
    return switch (target) {
      PsdkBattleMoveTarget.self ||
      PsdkBattleMoveTarget.user =>
        BattleMoveTarget.self,
      PsdkBattleMoveTarget.bank ||
      PsdkBattleMoveTarget.userSide ||
      PsdkBattleMoveTarget.foeSide =>
        BattleMoveTarget.opponentSide,
      PsdkBattleMoveTarget.none => BattleMoveTarget.field,
      _ => BattleMoveTarget.opponent,
    };
  }

  BattleMoveAccuracy _toLegacyMoveAccuracy(int accuracy) {
    if (accuracy <= 0) {
      return const BattleMoveAccuracy.alwaysHits();
    }
    return BattleMoveAccuracy.percent(value: accuracy.clamp(1, 100).toInt());
  }

  BattleFieldState _toLegacyFieldState(PsdkBattleFieldState field) {
    return BattleFieldState(
      weather: _toLegacyWeather(field.weather),
    );
  }

  BattleWeatherState? _toLegacyWeather(PsdkBattleWeatherState? weather) {
    if (weather == null) {
      return null;
    }
    final legacyId = switch (weather.id) {
      PsdkBattleWeatherId.rain => BattleWeatherId.rain,
      PsdkBattleWeatherId.sandstorm => BattleWeatherId.sandstorm,
      _ => null,
    };
    if (legacyId == null) {
      return null;
    }
    return BattleWeatherState(
      id: legacyId,
      remainingTurns: weather.remainingTurns ?? 999,
    );
  }

  BattleOutcomeType _legacyOutcomeType() {
    return switch (state.outcome?.kind) {
      BattleEngineOutcomeKind.victory => BattleOutcomeType.victory,
      BattleEngineOutcomeKind.defeat => BattleOutcomeType.defeat,
      BattleEngineOutcomeKind.fled => BattleOutcomeType.runaway,
      null => throw StateError('PSDK battle has no final outcome yet.'),
    };
  }

  int _lineupIndexFromPsdkId(String id) {
    final separator = id.lastIndexOf('_');
    if (separator < 0 || separator == id.length - 1) {
      return 0;
    }
    return int.tryParse(id.substring(separator + 1)) ?? 0;
  }
}
