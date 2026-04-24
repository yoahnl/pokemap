part of 'battle_session.dart';

/// Seams scheduler locaux consolidés en R2.
///
/// Ce fichier ne cherche pas à créer un framework battle générique :
/// - il reste privé à `battle_session.dart` via `part`;
/// - il ne publie aucun nouveau contrat runtime ou UI ;
/// - il se contente de rendre explicites les quatre niveaux déjà vivants
///   localement : action choisie, planification, consommation de queue,
///   suspension/reprise.
///
/// Ce qui reste volontairement hors de ce fichier :
/// - la frontière request/choice publique ;
/// - la sélection d'action adverse ;
/// - la résolution métier des moves, conditions et entry hazards ;
/// - toute ouverture vers R3/R4/H3.

BattleSession _applyForcedPlayerReplacement({
  required BattleSession session,
  required PlayerBattleChoiceSwitch choice,
}) {
  // R2 fait passer ce cas par le même seam scheduler que le reste sans mentir
  // sur sa nature :
  // - il s'agit bien d'une petite étape inter-tour ;
  // - il ne faut donc ni lui inventer une fin de tour, ni lui rattacher des
  //   checks post-résolution qui appartiennent au vrai tour d'origine.
  final replacementAction =
      BattleActionSwitch(reserveIndex: choice.reserveIndex);
  final turnPlan = _planForcedReplacementTurn(
    replacementAction: replacementAction,
  );
  final turn = _QueuedTurnContext(
    playerSide: session.state.playerSide,
    enemySide: session.state.enemySide,
    field: session.state.field,
    rng: session.rng,
    originalPlayerAction: turnPlan.reportedPlayerAction,
    originalEnemyAction: turnPlan.reportedEnemyAction,
  );
  _consumeTurnPlan(
    session: session,
    plan: turnPlan,
    turn: turn,
  );
  _recordFollowUpPlayerReplacementIfNeeded(
    session: session,
    turn: turn,
  );

  final outcome = session._determineOutcome(
    turn.playerSide,
    turn.enemySide,
    turn.field,
  );

  return BattleSession._(
    state: BattleState(
      phase: outcome != null ? BattlePhase.finished : BattlePhase.playerChoice,
      playerSide: turn.playerSide,
      enemySide: turn.enemySide,
      field: turn.field,
      currentTurn: _buildTurnResultFromContext(
        turn: turn,
        playerAction: turnPlan.reportedPlayerAction,
        enemyAction: turnPlan.reportedEnemyAction,
      ),
      outcome: outcome,
    ),
    setup: session.setup,
    rng: turn.rng,
    opponentPolicy: session.opponentPolicy,
    pendingTurn: null,
  );
}

BattleSession _resumePendingTurnWithReplacement({
  required BattleSession session,
  required PlayerBattleChoiceSwitch choice,
}) {
  final pending = session.pendingTurn;
  if (pending == null) {
    throw StateError(
      'Aucune continuation de tour n’est disponible pour reprendre un remplacement joueur.',
    );
  }

  // Le tour logique rapporté au runtime reste celui qui a déjà commencé :
  // - `reportedPlayerAction` / `reportedEnemyAction` restent donc les actions
  //   originales du tour suspendu ;
  // - la nouvelle étape de switch forcé ne vit que dans le plan de queue ;
  // - cela évite de réécrire l'histoire observable du tour au moment de la
  //   reprise.
  final turnPlan = _planPendingTurnResumption(
    pending: pending,
    replacementAction: BattleActionSwitch(reserveIndex: choice.reserveIndex),
  );
  final turn = _QueuedTurnContext.resume(pending);
  _consumeTurnPlan(
    session: session,
    plan: turnPlan,
    turn: turn,
  );

  final outcome = turn.pendingTurn != null
      ? null
      : session._determineOutcome(
          turn.playerSide,
          turn.enemySide,
          turn.field,
        );

  return BattleSession._(
    state: BattleState(
      phase: outcome != null ? BattlePhase.finished : BattlePhase.playerChoice,
      playerSide: turn.playerSide,
      enemySide: turn.enemySide,
      field: turn.field,
      currentTurn: _buildTurnResultFromContext(
        turn: turn,
        playerAction: turnPlan.reportedPlayerAction,
        enemyAction: turnPlan.reportedEnemyAction,
      ),
      outcome: outcome,
    ),
    setup: session.setup,
    rng: turn.rng,
    opponentPolicy: session.opponentPolicy,
    pendingTurn: turn.pendingTurn,
  );
}

/// Plan local d'un tour ou d'une étape de reprise déjà réellement supportée.
///
/// Le point important de R2 est ici :
/// - `reported*Action` décrit ce que `BattleTurnResult` devra raconter ;
/// - `initialSteps` décrit ce que la queue doit réellement exécuter ;
/// - ces deux axes coïncident pour un tour normal ;
/// - ils divergent volontairement lors d'une reprise après remplacement forcé,
///   où le switch de reprise n'est qu'une étape de queue et non la nouvelle
///   "vraie action choisie" du tour suspendu.
final class _BattleTurnPlan {
  const _BattleTurnPlan({
    required this.reportedPlayerAction,
    required this.reportedEnemyAction,
    required this.initialSteps,
    required this.allowTurnTailInsertion,
  });

  final BattleAction reportedPlayerAction;
  final BattleAction reportedEnemyAction;
  final List<BattleQueueStep> initialSteps;

  /// Indique si l'exécution de ce plan doit insérer la fin de tour canonique
  /// quand la phase d'actions se vide.
  ///
  /// R2 garde ce booléen volontairement local au seam scheduler :
  /// - un vrai tour complet l'active ;
  /// - une simple étape inter-tour de remplacement ne l'active pas ;
  /// - on évite ainsi de transformer la queue en mini-framework de phases.
  final bool allowTurnTailInsertion;
}

_BattleTurnPlan _planInitialTurn({
  required BattleSession session,
  required BattleAction playerAction,
  required BattleAction enemyAction,
  required BattleCombatant player,
  required BattleCombatant enemy,
  required BattleFieldState field,
}) {
  return _BattleTurnPlan(
    reportedPlayerAction: playerAction,
    reportedEnemyAction: enemyAction,
    initialSteps: List<BattleQueueStep>.unmodifiable(
      _buildInitialTurnQueue(
        session: session,
        playerAction: playerAction,
        enemyAction: enemyAction,
        player: player,
        enemy: enemy,
        field: field,
      ),
    ),
    allowTurnTailInsertion: true,
  );
}

_BattleTurnPlan _planForcedReplacementTurn({
  required BattleActionSwitch replacementAction,
}) {
  return _BattleTurnPlan(
    reportedPlayerAction: replacementAction,
    reportedEnemyAction: const BattleActionNone(),
    initialSteps: List<BattleQueueStep>.unmodifiable(<BattleQueueStep>[
      BattleQueueActionStep(
        side: BattleSideId.player,
        slot: const BattleSlotRef.active(BattleSideId.player),
        action: replacementAction,
        wasForced: true,
      ),
    ]),
    allowTurnTailInsertion: false,
  );
}

_BattleTurnPlan _planPendingTurnResumption({
  required _PendingTurnContinuation pending,
  required BattleActionSwitch replacementAction,
}) {
  return _BattleTurnPlan(
    reportedPlayerAction: pending.playerAction,
    reportedEnemyAction: pending.enemyAction,
    initialSteps: List<BattleQueueStep>.unmodifiable(<BattleQueueStep>[
      BattleQueueActionStep(
        side: BattleSideId.player,
        slot: const BattleSlotRef.active(BattleSideId.player),
        action: replacementAction,
        wasForced: true,
      ),
      ...pending.remainingSteps,
    ]),
    allowTurnTailInsertion: true,
  );
}

void _consumeTurnPlan({
  required BattleSession session,
  required _BattleTurnPlan plan,
  required _QueuedTurnContext turn,
}) {
  // R2 garde un seul moteur de consommation :
  // - même boucle pour un vrai tour, un remplacement inter-tour et une reprise ;
  // - seules changent les étapes initiales et le droit d'insérer un turn tail ;
  // - cela clarifie la responsabilité scheduler sans ouvrir de méta-système.
  final queue = BattleTurnQueue(plan.initialSteps);

  while (!queue.isEmpty) {
    final step = queue.takeNext();
    _executeQueueStep(
      session: session,
      queue: queue,
      turn: turn,
      step: step,
    );
    if (turn.pendingTurn != null) {
      break;
    }
    if (plan.allowTurnTailInsertion) {
      _appendTurnTailWhenActionPhaseDrains(
        queue: queue,
        turn: turn,
      );
    }
  }
}

BattleTurnResult _buildTurnResultFromContext({
  required _QueuedTurnContext turn,
  required BattleAction playerAction,
  required BattleAction enemyAction,
}) {
  return BattleTurnResult(
    playerAction: playerAction,
    enemyAction: enemyAction,
    executions: List<BattleMoveExecution>.unmodifiable(turn.executions),
    statusEvents: List<BattleStatusEvent>.unmodifiable(turn.statusEvents),
    volatileEvents: List<BattleVolatileEvent>.unmodifiable(turn.volatileEvents),
    fieldEvents: List<BattleFieldEvent>.unmodifiable(turn.fieldEvents),
    stealthRockEvents:
        List<BattleStealthRockEvent>.unmodifiable(turn.stealthRockEvents),
    spikesEvents: List<BattleSpikesEvent>.unmodifiable(turn.spikesEvents),
    bagHpHealItemEvents:
        List<BattleBagHpHealItemEvent>.unmodifiable(turn.bagHpHealItemEvents),
    switchEvents: List<BattleSwitchEvent>.unmodifiable(turn.switchEvents),
    timeline: List<BattleTurnEvent>.unmodifiable(turn.timeline),
  );
}

List<BattleQueueStep> _buildInitialTurnQueue({
  required BattleSession session,
  required BattleAction playerAction,
  required BattleAction enemyAction,
  required BattleCombatant player,
  required BattleCombatant enemy,
  required BattleFieldState field,
}) {
  final orderedActions = _resolveTurnOrder(
    session: session,
    playerAction: playerAction,
    enemyAction: enemyAction,
    player: player,
    enemy: enemy,
    field: field,
  );

  return <BattleQueueStep>[
    for (final orderedAction in orderedActions)
      if (isBattleQueueManagedAction(orderedAction.action))
        BattleQueueActionStep(
          side: orderedAction.side,
          slot: BattleSlotRef.active(orderedAction.side),
          action: orderedAction.action,
          wasForced: false,
        ),
  ];
}

void _appendTurnTailWhenActionPhaseDrains({
  required BattleTurnQueue queue,
  required _QueuedTurnContext turn,
}) {
  if (turn.turnTailScheduled || !queue.isEmpty) {
    return;
  }

  // Le "turn tail" reste volontairement minuscule et concret :
  // - fin de tour ;
  // - checks post-résolution ;
  // - rien d'autre.
  // R2 clarifie surtout le point exact où il s'insère, sans ouvrir de nouvelle
  // taxonomie de phases.
  queue.pushBack(const BattleQueueEndOfTurnStep());
  queue.pushBack(const BattleQueuePostTurnChecksStep());
  turn.turnTailScheduled = true;
}

void _executeQueueStep({
  required BattleSession session,
  required BattleTurnQueue queue,
  required _QueuedTurnContext turn,
  required BattleQueueStep step,
}) {
  switch (step) {
    case BattleQueueActionStep():
      _executeActionQueueStep(
        session: session,
        queue: queue,
        turn: turn,
        step: step,
      );
    case BattleQueueEndOfTurnStep():
      _executeEndOfTurnQueueStep(
        session: session,
        turn: turn,
      );
    case BattleQueuePostTurnChecksStep():
      _executePostTurnChecksQueueStep(
        session: session,
        queue: queue,
        turn: turn,
      );
    case BattleQueueAutoSwitchStep():
      _executeAutoSwitchQueueStep(
        session: session,
        queue: queue,
        turn: turn,
        step: step,
      );
    case BattleQueueReplacementRequiredStep():
      _executeReplacementRequiredQueueStep(
        turn: turn,
        step: step,
      );
  }
}

void _executeActionQueueStep({
  required BattleSession session,
  required BattleTurnQueue queue,
  required _QueuedTurnContext turn,
  required BattleQueueActionStep step,
}) {
  final actingSide = turn.side(step.side);
  final opposingSide = turn.side(_opposingSideId(step.side));

  if (step.action case BattleActionFight(:final move, :final moveIndex)) {
    if (actingSide.active.isFainted || opposingSide.active.isFainted) {
      return;
    }

    final resolution = session._resolveMoveExecution(
      attackerSlot: actingSide.activeSlotRef,
      move: move,
      moveIndex: moveIndex,
      attacker: actingSide.active,
      defender: opposingSide.active,
      field: turn.field,
      targetSlot: opposingSide.activeSlotRef,
      rng: turn.rng,
    );
    turn.updateActive(step.side, resolution.attacker);
    turn.updateActive(_opposingSideId(step.side), resolution.defender);
    turn.field = resolution.field;
    turn.rng = resolution.rng;
    if (resolution.execution != null) {
      turn.executions.add(resolution.execution!);
    }
    turn.statusEvents.addAll(resolution.statusEvents);
    turn.volatileEvents.addAll(resolution.volatileEvents);
    turn.fieldEvents.addAll(resolution.fieldEvents);
    turn.timeline.addAll(resolution.timeline);

    final sideConditionResolution =
        _conditionEngine.runSideConditionMoveResolved(
      move: move,
      didResolveHit: resolution.execution?.didHit == true,
      targetSide: turn.side(_opposingSideId(step.side)),
    );
    _recordSideConditionResolution(
      turn: turn,
      sideId: _opposingSideId(step.side),
      resolution: sideConditionResolution,
    );
    return;
  }

  if (step.action case BattleActionSwitch(:final reserveIndex)) {
    final resolution = session._resolveSwitchAction(
      side: actingSide,
      reserveIndex: reserveIndex,
      wasForced: step.wasForced,
    );
    turn.updateSide(step.side, resolution.side);
    turn.switchEvents.add(resolution.event);
    turn.timeline.add(BattleTurnSwitchEvent(resolution.event));

    final entryHazards = _conditionEngine.runEntryHazards(
      side: turn.side(step.side),
    );
    _recordSideConditionResolution(
      turn: turn,
      sideId: step.side,
      resolution: entryHazards,
    );

    final sideAfterEntry = turn.side(step.side);
    if (sideAfterEntry.active.isFainted &&
        step.side == BattleSideId.player &&
        session._firstUsableReserveIndex(sideAfterEntry.reserve) != null &&
        !queue.isEmpty) {
      _suspendTurnForImmediatePlayerReplacement(
        queue: queue,
        turn: turn,
      );
    }
    return;
  }

  if (step.action
      case BattleActionBagHpHealItemUse(
        :final itemKind,
        :final targetLineupIndex,
        :final resolvedEffect,
      )) {
    if (step.side != BattleSideId.player) {
      throw StateError(
        'BattleActionBagHpHealItemUse reste player-only dans le lot 9-h.',
      );
    }

    final resolution = session._resolveBagHpHealItemUseAction(
      itemKind: itemKind,
      side: actingSide,
      targetLineupIndex: targetLineupIndex,
      effect: resolvedEffect,
    );
    turn.updateSide(step.side, resolution.side);
    turn.bagHpHealItemEvents.add(resolution.event);
    turn.timeline.add(BattleTurnBagHpHealItemEvent(resolution.event));
    return;
  }

  if (step.action is BattleActionRecharge) {
    if (actingSide.active.isFainted || opposingSide.active.isFainted) {
      return;
    }

    final resolution = _conditionEngine.runForcedContinueTurn(
      combatantSlot: actingSide.activeSlotRef,
      combatant: actingSide.active,
    );
    turn.updateActive(step.side, resolution.combatant);
    turn.volatileEvents.addAll(resolution.volatileEvents);
    turn.timeline
        .addAll(session._turnEventsFromVolatile(resolution.volatileEvents));
  }
}

void _executeEndOfTurnQueueStep({
  required BattleSession session,
  required _QueuedTurnContext turn,
}) {
  final residualResolution = _conditionEngine.runEndOfTurn(
    player: turn.playerSide.active,
    enemy: turn.enemySide.active,
    field: turn.field,
  );
  turn.updateActive(BattleSideId.player, residualResolution.player);
  turn.updateActive(BattleSideId.enemy, residualResolution.enemy);
  turn.field = residualResolution.field;
  turn.statusEvents.addAll(residualResolution.statusEvents);
  turn.fieldEvents.addAll(residualResolution.fieldEvents);
  turn.timeline
      .addAll(session._turnEventsFromStatus(residualResolution.statusEvents));
  turn.timeline
      .addAll(session._turnEventsFromField(residualResolution.fieldEvents));
}

void _executePostTurnChecksQueueStep({
  required BattleSession session,
  required BattleTurnQueue queue,
  required _QueuedTurnContext turn,
}) {
  final enemyReplacementIndex = _chooseEnemyReplacementIndex(
    session: session,
    reserve: turn.enemySide.reserve,
  );
  if (turn.enemySide.active.isFainted && enemyReplacementIndex != null) {
    queue.pushBack(
      BattleQueueAutoSwitchStep(
        side: BattleSideId.enemy,
        slot: const BattleSlotRef.active(BattleSideId.enemy),
        reserveIndex: enemyReplacementIndex,
      ),
    );
  }

  if (turn.playerSide.active.isFainted &&
      !turn.enemySide.active.isFainted &&
      session._firstUsableReserveIndex(turn.playerSide.reserve) != null) {
    // Tant qu'une chaîne d'auto-switch ennemi reste possible, on refuse
    // d'annoncer le remplacement joueur trop tôt :
    // - sinon la timeline raconterait "le joueur doit remplacer" avant que
    //   l'ennemi ait fini d'entrer réellement ;
    // - en H1/H2, un premier remplaçant ennemi peut même mourir en entrant,
    //   ce qui doit rester visible avant la request joueur.
    queue.pushBack(
      BattleQueueReplacementRequiredStep(
        side: BattleSideId.player,
        slot: const BattleSlotRef.active(BattleSideId.player),
        faintedSpeciesId: turn.playerSide.active.speciesId,
      ),
    );
  }
}

void _executeAutoSwitchQueueStep({
  required BattleSession session,
  required BattleTurnQueue queue,
  required _QueuedTurnContext turn,
  required BattleQueueAutoSwitchStep step,
}) {
  final resolution = session._resolveSwitchAction(
    side: turn.side(step.side),
    reserveIndex: step.reserveIndex,
    wasForced: true,
  );
  turn.updateSide(step.side, resolution.side);
  turn.switchEvents.add(resolution.event);
  turn.timeline.add(BattleTurnSwitchEvent(resolution.event));

  final entryHazards = _conditionEngine.runEntryHazards(
    side: turn.side(step.side),
  );
  _recordSideConditionResolution(
    turn: turn,
    sideId: step.side,
    resolution: entryHazards,
  );

  if (turn.side(step.side).active.isFainted) {
    final nextReserveIndex = step.side == BattleSideId.enemy
        ? _chooseEnemyReplacementIndex(
            session: session,
            reserve: turn.side(step.side).reserve,
          )
        : session._firstUsableReserveIndex(turn.side(step.side).reserve);
    if (nextReserveIndex != null) {
      queue.pushBack(
        BattleQueueAutoSwitchStep(
          side: step.side,
          slot: step.slot,
          reserveIndex: nextReserveIndex,
        ),
      );
      return;
    }
  }

  if (step.side == BattleSideId.enemy &&
      turn.playerSide.active.isFainted &&
      !turn.enemySide.active.isFainted &&
      session._firstUsableReserveIndex(turn.playerSide.reserve) != null) {
    queue.pushBack(
      BattleQueueReplacementRequiredStep(
        side: BattleSideId.player,
        slot: const BattleSlotRef.active(BattleSideId.player),
        faintedSpeciesId: turn.playerSide.active.speciesId,
      ),
    );
  }
}

int? _chooseEnemyReplacementIndex({
  required BattleSession session,
  required List<BattleCombatant> reserve,
}) {
  final legalReplacementOptions = <BattleOpponentReplacementOption>[];
  for (var i = 0; i < reserve.length; i++) {
    final combatant = reserve[i];
    if (!combatant.isFainted) {
      legalReplacementOptions.add(
        BattleOpponentReplacementOption(
          reserveIndex: i,
          combatant: combatant,
        ),
      );
    }
  }
  if (legalReplacementOptions.isEmpty) {
    return null;
  }

  final selectedOption = session.opponentPolicy.chooseReplacement(
    legalReplacementOptions: List<BattleOpponentReplacementOption>.unmodifiable(
      legalReplacementOptions,
    ),
  );
  if (!legalReplacementOptions.contains(selectedOption)) {
    throw StateError(
      'BattleOpponentPolicy doit retourner une des options de replacement légales fournies par le scheduler.',
    );
  }
  return selectedOption.reserveIndex;
}

void _executeReplacementRequiredQueueStep({
  required _QueuedTurnContext turn,
  required BattleQueueReplacementRequiredStep step,
}) {
  final replacementRequiredEvent = BattleSwitchEvent.replacementRequired(
    side: step.side,
    fromSpeciesId: step.faintedSpeciesId,
  );
  turn.switchEvents.add(replacementRequiredEvent);
  turn.timeline.add(BattleTurnSwitchEvent(replacementRequiredEvent));
}

void _recordSideConditionResolution({
  required _QueuedTurnContext turn,
  required BattleSideId sideId,
  required BattleSideConditionResolution resolution,
}) {
  // Frontière R3 volontairement nette :
  // - l'engine conditionnel résout le "comment" des side conditions ;
  // - le scheduler garde l'ordre observable dans lequel ces effets entrent
  //   réellement dans la timeline du tour ;
  // - ce helper ne ré-invente donc aucune mécanique, il enregistre seulement
  //   la sortie déjà résolue par l'engine au bon endroit de la queue.
  turn.updateSide(sideId, resolution.side);
  turn.stealthRockEvents.addAll(resolution.stealthRockEvents);
  turn.timeline.addAll(
    resolution.stealthRockEvents.map(BattleTurnStealthRockEvent.new),
  );
  turn.spikesEvents.addAll(resolution.spikesEvents);
  turn.timeline.addAll(
    resolution.spikesEvents.map(BattleTurnSpikesEvent.new),
  );
}

void _recordFollowUpPlayerReplacementIfNeeded({
  required BattleSession session,
  required _QueuedTurnContext turn,
}) {
  final followUpReplacementIndex = turn.playerSide.active.isFainted
      ? session._firstUsableReserveIndex(turn.playerSide.reserve)
      : null;
  if (followUpReplacementIndex == null) {
    return;
  }

  final replacementRequiredEvent = BattleSwitchEvent.replacementRequired(
    side: BattleSideId.player,
    fromSpeciesId: turn.playerSide.active.speciesId,
  );
  turn.switchEvents.add(replacementRequiredEvent);
  turn.timeline.add(BattleTurnSwitchEvent(replacementRequiredEvent));
}

void _suspendTurnForImmediatePlayerReplacement({
  required BattleTurnQueue queue,
  required _QueuedTurnContext turn,
}) {
  // H1/H2 ont ouvert ici le plus petit vrai seam d'interruption ; R2 ne
  // l'élargit pas, il le rend seulement plus lisible :
  // - interruption uniquement pour un remplacement joueur devenu obligatoire en
  //   plein tour après un hazard d'entrée déjà réellement supporté ;
  // - aucune généralisation en scheduler d'interruptions arbitraires ;
  // - capture exacte du reste de queue afin que la reprise continue le tour
  //   logique existant au lieu d'en inventer un nouveau.
  final replacementRequiredEvent = BattleSwitchEvent.replacementRequired(
    side: BattleSideId.player,
    fromSpeciesId: turn.playerSide.active.speciesId,
  );
  turn.switchEvents.add(replacementRequiredEvent);
  turn.timeline.add(BattleTurnSwitchEvent(replacementRequiredEvent));
  turn.pendingTurn = _PendingTurnContinuation.capture(
    turn: turn,
    remainingSteps: queue.drainRemainingSteps(),
    playerAction: turn.originalPlayerAction ?? const BattleActionNone(),
    enemyAction: turn.originalEnemyAction ?? const BattleActionNone(),
  );
}

List<_OrderedBattleAction> _resolveTurnOrder({
  required BattleSession session,
  required BattleAction playerAction,
  required BattleAction enemyAction,
  required BattleCombatant player,
  required BattleCombatant enemy,
  required BattleFieldState field,
}) {
  // Le scheduler local n'a toujours besoin que d'un ordre honnête pour deux
  // actions supportées.
  if (!isBattleQueueManagedAction(playerAction) ||
      !isBattleQueueManagedAction(enemyAction)) {
    return <_OrderedBattleAction>[
      _OrderedBattleAction(
        side: BattleSideId.player,
        action: playerAction,
      ),
      _OrderedBattleAction(
        side: BattleSideId.enemy,
        action: enemyAction,
      ),
    ];
  }

  final playerPriority = _priorityForResolvedAction(playerAction);
  final enemyPriority = _priorityForResolvedAction(enemyAction);
  if (playerPriority != enemyPriority) {
    return playerPriority > enemyPriority
        ? <_OrderedBattleAction>[
            _OrderedBattleAction(
              side: BattleSideId.player,
              action: playerAction,
            ),
            _OrderedBattleAction(
              side: BattleSideId.enemy,
              action: enemyAction,
            ),
          ]
        : <_OrderedBattleAction>[
            _OrderedBattleAction(
              side: BattleSideId.enemy,
              action: enemyAction,
            ),
            _OrderedBattleAction(
              side: BattleSideId.player,
              action: playerAction,
            ),
          ];
  }

  final playerSpeed = session._resolveEffectiveSpeed(player);
  final enemySpeed = session._resolveEffectiveSpeed(enemy);
  final trickRoomActive = _conditionEngine.doesFieldInvertSpeedOrder(field);
  if (playerSpeed != enemySpeed) {
    final playerActsFirst =
        trickRoomActive ? playerSpeed < enemySpeed : playerSpeed > enemySpeed;
    return playerActsFirst
        ? <_OrderedBattleAction>[
            _OrderedBattleAction(
              side: BattleSideId.player,
              action: playerAction,
            ),
            _OrderedBattleAction(
              side: BattleSideId.enemy,
              action: enemyAction,
            ),
          ]
        : <_OrderedBattleAction>[
            _OrderedBattleAction(
              side: BattleSideId.enemy,
              action: enemyAction,
            ),
            _OrderedBattleAction(
              side: BattleSideId.player,
              action: playerAction,
            ),
          ];
  }

  // Tie-break toujours volontairement déterministe :
  // - R2 n'ajoute pas de PRNG d'ordre ;
  // - il garde seulement cette politique locale explicite ;
  // - cela reste une dette canoniquement documentée, pas une pseudo-parité
  //   Showdown.
  return <_OrderedBattleAction>[
    _OrderedBattleAction(
      side: BattleSideId.player,
      action: playerAction,
    ),
    _OrderedBattleAction(
      side: BattleSideId.enemy,
      action: enemyAction,
    ),
  ];
}

int _priorityForResolvedAction(BattleAction action) {
  return switch (action) {
    // Politique singles locale explicitement bornée :
    // - un switch volontaire ou forcé résout avant un `Fight` standard ;
    // - cela ne prétend toujours pas modéliser la taxonomie Showdown complète
    //   des priorités de switch.
    //
    // Lots 9-e à 9-h ajoutent un seul micro-slice d'objets :
    // - `Potion`, `Super Potion`, `Hyper Potion` et `Max Potion` deviennent de vraies
    //   actions de tour ;
    // - elles résolvent avant les moves actuellement supportés ;
    // - on refuse pourtant d'ouvrir une échelle générique de priorités items.
    BattleActionBagHpHealItemUse() => 7,
    BattleActionSwitch() => 6,
    BattleActionFight(:final move) => move.priority,
    BattleActionRecharge() => 0,
    _ => 0,
  };
}

final class _OrderedBattleAction {
  const _OrderedBattleAction({
    required this.side,
    required this.action,
  });

  final BattleSideId side;
  final BattleAction action;
}

final class _PendingTurnContinuation {
  const _PendingTurnContinuation({
    required this.playerSide,
    required this.enemySide,
    required this.field,
    required this.rng,
    required this.playerAction,
    required this.enemyAction,
    required this.turnTailScheduled,
    required this.remainingSteps,
    required this.executions,
    required this.statusEvents,
    required this.volatileEvents,
    required this.fieldEvents,
    required this.stealthRockEvents,
    required this.spikesEvents,
    required this.bagHpHealItemEvents,
    required this.switchEvents,
    required this.timeline,
  });

  factory _PendingTurnContinuation.capture({
    required _QueuedTurnContext turn,
    required List<BattleQueueStep> remainingSteps,
    required BattleAction playerAction,
    required BattleAction enemyAction,
  }) {
    return _PendingTurnContinuation(
      playerSide: turn.playerSide,
      enemySide: turn.enemySide,
      field: turn.field,
      rng: turn.rng,
      playerAction: playerAction,
      enemyAction: enemyAction,
      turnTailScheduled: turn.turnTailScheduled,
      remainingSteps: List<BattleQueueStep>.unmodifiable(remainingSteps),
      executions: List<BattleMoveExecution>.unmodifiable(turn.executions),
      statusEvents: List<BattleStatusEvent>.unmodifiable(turn.statusEvents),
      volatileEvents:
          List<BattleVolatileEvent>.unmodifiable(turn.volatileEvents),
      fieldEvents: List<BattleFieldEvent>.unmodifiable(turn.fieldEvents),
      stealthRockEvents:
          List<BattleStealthRockEvent>.unmodifiable(turn.stealthRockEvents),
      spikesEvents: List<BattleSpikesEvent>.unmodifiable(turn.spikesEvents),
      bagHpHealItemEvents: List<BattleBagHpHealItemEvent>.unmodifiable(
        turn.bagHpHealItemEvents,
      ),
      switchEvents: List<BattleSwitchEvent>.unmodifiable(turn.switchEvents),
      timeline: List<BattleTurnEvent>.unmodifiable(turn.timeline),
    );
  }

  final BattleSideState playerSide;
  final BattleSideState enemySide;
  final BattleFieldState field;
  final BattleRng rng;
  final BattleAction playerAction;
  final BattleAction enemyAction;
  final bool turnTailScheduled;
  final List<BattleQueueStep> remainingSteps;
  final List<BattleMoveExecution> executions;
  final List<BattleStatusEvent> statusEvents;
  final List<BattleVolatileEvent> volatileEvents;
  final List<BattleFieldEvent> fieldEvents;
  final List<BattleStealthRockEvent> stealthRockEvents;
  final List<BattleSpikesEvent> spikesEvents;
  final List<BattleBagHpHealItemEvent> bagHpHealItemEvents;
  final List<BattleSwitchEvent> switchEvents;
  final List<BattleTurnEvent> timeline;
}

/// Contexte mutable strictement local à la consommation d'une queue de tour.
///
/// R2 garde ce conteneur vivant mais le sort du gros fichier principal :
/// - la session publique reste immutable ;
/// - la mutabilité de résolution reste confinée à l'exécution de queue ;
/// - l'objet sert uniquement à agréger l'état courant et les traces observables
///   pendant un plan de scheduler.
final class _QueuedTurnContext {
  _QueuedTurnContext({
    required this.playerSide,
    required this.enemySide,
    required this.field,
    required this.rng,
    this.originalPlayerAction,
    this.originalEnemyAction,
  });

  factory _QueuedTurnContext.resume(_PendingTurnContinuation pending) {
    return _QueuedTurnContext(
      playerSide: pending.playerSide,
      enemySide: pending.enemySide,
      field: pending.field,
      rng: pending.rng,
      originalPlayerAction: pending.playerAction,
      originalEnemyAction: pending.enemyAction,
    )
      ..turnTailScheduled = pending.turnTailScheduled
      ..executions.addAll(pending.executions)
      ..statusEvents.addAll(pending.statusEvents)
      ..volatileEvents.addAll(pending.volatileEvents)
      ..fieldEvents.addAll(pending.fieldEvents)
      ..stealthRockEvents.addAll(pending.stealthRockEvents)
      ..spikesEvents.addAll(pending.spikesEvents)
      ..bagHpHealItemEvents.addAll(pending.bagHpHealItemEvents)
      ..switchEvents.addAll(pending.switchEvents)
      ..timeline.addAll(pending.timeline);
  }

  BattleSideState playerSide;
  BattleSideState enemySide;
  BattleFieldState field;
  BattleRng rng;
  BattleAction? originalPlayerAction;
  BattleAction? originalEnemyAction;
  bool turnTailScheduled = false;
  _PendingTurnContinuation? pendingTurn;

  final List<BattleMoveExecution> executions = <BattleMoveExecution>[];
  final List<BattleStatusEvent> statusEvents = <BattleStatusEvent>[];
  final List<BattleVolatileEvent> volatileEvents = <BattleVolatileEvent>[];
  final List<BattleFieldEvent> fieldEvents = <BattleFieldEvent>[];
  final List<BattleStealthRockEvent> stealthRockEvents =
      <BattleStealthRockEvent>[];
  final List<BattleSpikesEvent> spikesEvents = <BattleSpikesEvent>[];
  final List<BattleBagHpHealItemEvent> bagHpHealItemEvents =
      <BattleBagHpHealItemEvent>[];
  final List<BattleSwitchEvent> switchEvents = <BattleSwitchEvent>[];
  final List<BattleTurnEvent> timeline = <BattleTurnEvent>[];

  BattleSideState side(BattleSideId sideId) {
    return switch (sideId) {
      BattleSideId.player => playerSide,
      BattleSideId.enemy => enemySide,
    };
  }

  void updateSide(BattleSideId sideId, BattleSideState sideState) {
    switch (sideId) {
      case BattleSideId.player:
        playerSide = sideState;
      case BattleSideId.enemy:
        enemySide = sideState;
    }
  }

  void updateActive(BattleSideId sideId, BattleCombatant active) {
    final existingSide = side(sideId);
    updateSide(
      sideId,
      existingSide.withActiveAndReserve(
        active: active,
        reserve: existingSide.reserve,
      ),
    );
  }
}
