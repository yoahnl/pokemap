import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';

import 'runtime_battle_status_bridge.dart';

/// Runtime adapter around the clean PSDK battle facade.
///
/// The playable runtime still talks in the legacy `PlayerBattleChoice` command
/// vocabulary. This adapter keeps that UI contract stable while routing the
/// actual turn execution through `BattleSessionFacade.fromPsdkSetup`.
final class RuntimePsdkBattleSessionAdapter {
  RuntimePsdkBattleSessionAdapter._(
    this._facade,
    this.opponentAi,
    this.ruleset,
  );

  factory RuntimePsdkBattleSessionAdapter.fromSetup(
    PsdkBattleSetup setup, {
    PsdkBattleAi opponentAi = const PsdkBattleAi(level: 2),
  }) {
    return RuntimePsdkBattleSessionAdapter._(
      BattleSessionFacade.fromPsdkSetup(
        setup: setup,
        opponentAi: opponentAi,
      ),
      opponentAi,
      setup.ruleset,
    );
  }

  final BattleSessionFacade _facade;

  /// Exact AI configuration injected by the runtime for this session.
  ///
  /// Keeping this observable avoids test-only access to the facade internals
  /// and proves that authored difficulty reached the PSDK path.
  final PsdkBattleAi opponentAi;
  final PokemonRulesetProfile ruleset;
  static const _statusBridge = RuntimeBattleStatusBridge();
  BattleDecision? _lastDecision;
  BattleEngineTurnResult? _lastTurnResult;
  final Map<String, String> _itemDisplayNames = <String, String>{};

  BattlePublicState get state => _facade.state;
  BattleEngineDecisionRequest get decisionRequest => _facade.decisionRequest;

  BattleSession createLegacyDisplaySession({
    required bool isTrainerBattle,
    String? trainerId,
    bool allowCapture = false,
    bool allowFlee = true,
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
        allowFlee: allowFlee,
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
      captureItemId: state.outcome?.kind == BattleEngineOutcomeKind.captured
          ? _capturedItemId()
          : null,
      captureAttemptId: state.outcome?.captureAttemptId,
    );
  }

  String _capturedItemId() {
    final attemptId = state.outcome?.captureAttemptId;
    final events = _lastTurnResult?.timeline.events
            .whereType<BattleCaptureAttemptTimelineEvent>()
            .where((event) => event.caught && event.attemptId == attemptId)
            .toList(growable: false) ??
        const <BattleCaptureAttemptTimelineEvent>[];
    if (attemptId == null || events.length != 1) {
      throw StateError('Captured outcome is missing its exact item event.');
    }
    return events.single.ballId;
  }

  BattleEngineTurnResult submitDecision(BattleDecision decision) {
    final result = _facade.submit(decision);
    _lastDecision = decision;
    _lastTurnResult = result;
    return result;
  }

  BattleEngineTurnResult submitPlayerChoice(PlayerBattleChoice choice) {
    return submitDecision(decisionForPlayerChoice(choice));
  }

  BattleEngineTurnResult submitBattleItem({
    required String itemId,
    required String displayName,
    required int? targetPartyIndex,
    required PsdkBattleItemActionEffect effect,
    required bool consumeItem,
  }) {
    _itemDisplayNames[itemId] = displayName;
    return submitDecision(
      BattleDecision.item(
        itemId: itemId,
        target: psdkPlayerSlot,
        targetPartyIndex: targetPartyIndex,
        effect: effect,
        consumeItem: consumeItem,
        highPriority: true,
      ),
    );
  }

  /// Canonical decision represented by the legacy presentation choice.
  BattleDecision decisionForPlayerChoice(PlayerBattleChoice choice) {
    return switch (choice) {
      PlayerBattleChoiceFight(:final moveIndex) =>
        _decisionForFightChoice(moveIndex),
      PlayerBattleChoiceSwitch(:final reserveIndex) =>
        BattleDecision.switchPokemon(
          partyIndex: _partyIndexForReserveChoice(reserveIndex),
        ),
      PlayerBattleChoiceRun() => const BattleDecision.flee(),
      PlayerBattleChoiceCapture(
        :final itemId,
        :final rateNumerator,
        :final rateDenominator,
      ) =>
        BattleDecision.capture(
          itemId: itemId,
          rateNumerator: rateNumerator,
          rateDenominator: rateDenominator,
        ),
      PlayerBattleChoiceContinue() => const BattleDecision.noAction(),
    };
  }

  /// Whether the canonical engine request accepts this presentation choice.
  bool allowsPlayerChoice(PlayerBattleChoice choice) {
    return decisionRequest.allows(decisionForPlayerChoice(choice));
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
    final captureAttemptEvents = <BattleCaptureAttemptEvent>[];
    for (final event in result.timeline.events) {
      if (event is BattleDamageTimelineEvent) {
        final execution = _toLegacyDamageExecution(event);
        executions.add(execution);
        timeline.add(BattleTurnExecutionEvent(execution));
      } else if (event is BattleHealTimelineEvent &&
          event.moveId?.startsWith('item:') == true) {
        final itemEvent = _toLegacyBagHpHealItemEvent(
          itemId: event.moveId!.substring('item:'.length),
          displayName:
              _itemDisplayNames[event.moveId!.substring('item:'.length)] ??
                  event.moveId!.substring('item:'.length),
          event: event,
          targetPartyIndex:
              decision is BattleItemDecision ? decision.targetPartyIndex : null,
        );
        bagHpHealItemEvents.add(itemEvent);
        timeline.add(BattleTurnBagHpHealItemEvent(itemEvent));
      } else if (event is BattleCaptureAttemptTimelineEvent) {
        final captureEvent = BattleCaptureAttemptEvent(
          attemptId: event.attemptId,
          targetSpeciesId:
              state.psdkState.battlerAt(psdkOpponentSlot).writeBackSpeciesId,
          ballId: event.ballId,
          caught: event.caught,
          shakes: event.shakes,
        );
        captureAttemptEvents.add(captureEvent);
        timeline.add(BattleTurnCaptureAttemptEvent(captureEvent));
      }
    }

    return BattleTurnResult(
      playerAction: _toLegacyPlayerAction(decision, result),
      enemyAction: _toLegacyOpponentAction(result),
      executions: List<BattleMoveExecution>.unmodifiable(executions),
      bagHpHealItemEvents:
          List<BattleBagHpHealItemEvent>.unmodifiable(bagHpHealItemEvents),
      captureAttemptEvents:
          List<BattleCaptureAttemptEvent>.unmodifiable(captureAttemptEvents),
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
    required String itemId,
    required String displayName,
    required BattleHealTimelineEvent event,
    required int? targetPartyIndex,
  }) {
    final side = _legacySideForPosition(event.target);
    final target = targetPartyIndex == null
        ? state.psdkState.battlerAt(
            PsdkBattleSlotRef(
              bank: event.target.bank,
              position: event.target.position,
            ),
          )
        : state.psdkState.partyForBank(event.target.bank)[targetPartyIndex];
    return BattleBagHpHealItemEvent(
      itemId: itemId,
      displayName: displayName,
      side: side,
      targetLineupIndex: _lineupIndexFromPsdkId(target.id),
      targetSpeciesId: target.speciesId,
      hpBefore: event.remainingHp - event.amount,
      hpAfter: event.remainingHp,
    );
  }

  BattleAction _toLegacyPlayerAction(
    BattleDecision decision,
    BattleEngineTurnResult result,
  ) {
    if (decision case BattleFightDecision(isStruggle: true)) {
      return BattleActionFight(
        canonicalLegacyStruggleMove,
        moveIndex: state.psdkState.battlerAt(psdkPlayerSlot).moves.length,
      );
    }
    return switch (decision) {
      BattleFightDecision(:final moveSlot) => BattleActionFight(
          _toLegacyMove(
            state.psdkState.battlerAt(psdkPlayerSlot).moves[moveSlot],
          ),
          moveIndex: moveSlot,
        ),
      BattleItemDecision(
        :final itemId,
        :final target,
        :final targetPartyIndex,
        :final effect,
      ) =>
        _toLegacyBattleItemAction(
          itemId: itemId,
          target: target,
          targetPartyIndex: targetPartyIndex,
          effect: effect,
        ),
      BattleFleeDecision() => const BattleActionRun(),
      BattleCaptureDecision(:final itemId) => BattleActionCapture(
          attemptId: _captureAttemptEvent(result).attemptId,
          itemId: itemId,
          caught: state.outcome?.kind == BattleEngineOutcomeKind.captured,
          shakes: _captureAttemptEvent(result).shakes,
        ),
      BattleSwitchDecision() ||
      BattleMegaDecision() ||
      BattleShiftDecision() ||
      BattleNoActionDecision() =>
        const BattleActionNone(),
    };
  }

  BattleCaptureAttemptTimelineEvent _captureAttemptEvent(
    BattleEngineTurnResult result,
  ) {
    final events = result.timeline.events
        .whereType<BattleCaptureAttemptTimelineEvent>()
        .toList(growable: false);
    if (events.length != 1) {
      throw StateError(
        'A PSDK capture decision must expose exactly one capture attempt event.',
      );
    }
    return events.single;
  }

  BattleAction _toLegacyBattleItemAction({
    required String itemId,
    required PsdkBattleSlotRef target,
    required int? targetPartyIndex,
    required PsdkBattleItemActionEffect effect,
  }) {
    return switch (effect) {
      final PsdkBattleHpHealItemEffect hpEffect => BattleActionBagHpHealItemUse(
          itemId: itemId,
          displayName: _itemDisplayNames[itemId] ?? itemId,
          targetLineupIndex: _lineupIndexFromPsdkId(
            targetPartyIndex == null
                ? state.psdkState.battlerAt(target).id
                : state.psdkState
                    .partyForBank(target.bank)[targetPartyIndex]
                    .id,
          ),
          effect: _toLegacyHpHealEffect(hpEffect),
        ),
      PsdkBattleStatusCureItemEffect() ||
      PsdkBattleReviveItemEffect() =>
        const BattleActionNone(),
    };
  }

  BattleBagHpHealEffect _toLegacyHpHealEffect(
    PsdkBattleItemActionEffect effect,
  ) {
    return switch (effect) {
      PsdkBattleHpHealItemEffect(:final restoreToFull, :final amount) =>
        restoreToFull
            ? const BattleBagRestoreToFullHpHealEffect()
            : BattleBagFlatHpHealEffect(amount!),
      PsdkBattleStatusCureItemEffect() ||
      PsdkBattleReviveItemEffect() =>
        throw UnsupportedError(
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

  BattleDecision _decisionForFightChoice(int moveIndex) {
    final realMoveCount =
        state.psdkState.battlerAt(psdkPlayerSlot).moves.length;
    if (decisionRequest.canStruggle && moveIndex == realMoveCount) {
      return const BattleDecision.struggle();
    }
    return BattleDecision.fight(moveSlot: moveIndex);
  }

  BattleSetup _toLegacyDisplaySetup({
    required bool isTrainerBattle,
    required String? trainerId,
    required bool allowCapture,
    required bool allowFlee,
  }) {
    final psdkState = state.psdkState;
    return BattleSetup(
      ruleset: ruleset,
      playerPokemon: _toLegacyCombatantData(
        psdkState.battlerAt(psdkPlayerSlot),
        includeStruggle: decisionRequest.canStruggle,
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
      allowFlee: allowFlee,
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
      playerParticipantLineupIndexes: psdkState.playerParticipantPartyIndexes,
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

  BattleCombatantData _toLegacyCombatantData(
    PsdkBattleCombatant combatant, {
    bool includeStruggle = false,
  }) {
    return BattleCombatantData(
      speciesId: combatant.speciesId,
      level: combatant.level,
      maxHp: combatant.maxHp,
      currentHp: combatant.currentHp,
      stats: _toLegacyStats(combatant.stats),
      lineupIndex: _lineupIndexFromPsdkId(combatant.id),
      typing: _toLegacyTyping(combatant.types),
      majorStatus:
          _statusBridge.legacyFromPsdkBattleStatus(combatant.majorStatus),
      abilityId: combatant.abilityId ?? 'unknown',
      catchRate: combatant.catchRate,
      moves: <BattleMoveData>[
        ...combatant.moves.map(_toLegacyMoveData),
        if (includeStruggle) canonicalLegacyStruggleMoveData,
      ],
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
      majorStatus:
          _statusBridge.legacyFromPsdkBattleStatus(combatant.majorStatus),
      abilityId: combatant.abilityId ?? 'unknown',
      catchRate: combatant.catchRate,
      moves: combatant.moves.map(_toLegacyMove).toList(growable: false),
      writeBackSpeciesId: combatant.writeBackSpeciesId,
      writeBackAbilityId: combatant.writeBackAbilityId ?? 'unknown',
      writeBackMoves:
          combatant.writeBackMoves.map(_toLegacyMove).toList(growable: false),
      writeBackMoveIdsAtBattleStart: combatant.writeBackMoveIdsAtBattleStart,
      hasTemporaryBattleMoves: combatant.transformState.isTransformed,
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
      BattleEngineOutcomeKind.captured => BattleOutcomeType.captured,
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
