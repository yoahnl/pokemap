import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import 'runtime_battle_outcome_apply.dart';
import 'runtime_psdk_battle_session_adapter.dart';

class RuntimeBattleItemApplyResult {
  const RuntimeBattleItemApplyResult({
    required this.updatedSession,
    required this.updatedGameState,
    required this.itemId,
    required this.targetSpeciesId,
    required this.targetLineupIndex,
    required this.appliedAmount,
    required this.consumptionReceipt,
  });

  final BattleSession updatedSession;
  final GameState updatedGameState;
  final String itemId;
  final String targetSpeciesId;
  final int targetLineupIndex;
  final int appliedAmount;
  final ItemConsumptionReceipt? consumptionReceipt;
}

class RuntimePsdkBattleItemApplyResult {
  const RuntimePsdkBattleItemApplyResult({
    required this.updatedDisplaySession,
    required this.updatedGameState,
    required this.itemId,
    required this.effectKind,
    required this.targetSpeciesId,
    required this.targetLineupIndex,
    required this.appliedAmount,
    required this.consumptionReceipt,
  });

  final BattleSession updatedDisplaySession;
  final GameState updatedGameState;
  final String itemId;
  final RuntimeBattleItemEffectKind effectKind;
  final String targetSpeciesId;
  final int targetLineupIndex;
  final int appliedAmount;
  final ItemConsumptionReceipt? consumptionReceipt;
}

enum RuntimeBattleItemEffectKind {
  healHp,
  fullRestore,
  cureStatus,
  revive,
  restorePp,
}

RuntimeBattleItemApplyResult? tryApplyRuntimeBattleItemUse({
  required BattleSession session,
  required GameState gameState,
  required RuntimeActiveBattleContext context,
  required String itemId,
  required int targetLineupIndex,
  required ItemCatalogSnapshot itemCatalog,
}) {
  final itemSpec = _runtimeHpHealItemSpecForItemId(itemId, itemCatalog);
  if (itemSpec == null) {
    return null;
  }
  return _tryApplyRuntimeBattleHpHealItemUse(
    session: session,
    gameState: gameState,
    context: context,
    itemSpec: itemSpec,
    targetLineupIndex: targetLineupIndex,
  );
}

GameState runtimeBattleStateWithAvailableItems({
  required RuntimePsdkBattleSessionAdapter session,
  required GameState gameState,
}) {
  var bag = gameState.bag;
  for (final entry in session.pendingItemQuantities.entries) {
    final result = const BagOperations().take(BagTakeRequest(
      bag: bag, itemId: entry.key, quantity: entry.value,
    ));
    if (!result.isSuccess) {
      throw StateError('Reserved battle items are absent from the bag.');
    }
    bag = result.bag;
  }
  return gameState.copyWith(bag: bag);
}

({GameState state, Map<BattlePositionRef, ItemConsumptionReceipt> receipts})
    commitRuntimeResolvedBattleItems({
  required RuntimePsdkBattleSessionAdapter session,
  required GameState gameState,
  required ItemCatalogSnapshot itemCatalog,
}) {
  final events = session.resolvedItemEvents;
  var bag = gameState.bag;
  final receipts = <BattlePositionRef, ItemConsumptionReceipt>{};
  for (final event in events) {
    final definition = itemCatalog.definitionFor(event.itemId);
    if (definition == null) {
      throw StateError('Resolved battle item is missing from the catalog.');
    }
    final result = const BagOperations().consume(BagConsumeRequest(
      bag: bag,
      itemId: event.itemId,
      quantity: 1,
      reason: ItemConsumptionReason.appliedEffect,
      itemTags: definition.tags,
    ));
    if (!result.isSuccess || result.consumptionReceipt == null) {
      throw StateError('Resolved battle item cannot be consumed from the bag.');
    }
    bag = result.bag;
    receipts[event.user] = result.consumptionReceipt!;
  }
  session.acknowledgeResolvedItemEvents(events);
  return (state: gameState.copyWith(bag: bag), receipts: Map.unmodifiable(receipts));
}

RuntimePsdkBattleItemApplyResult? tryApplyRuntimePsdkBattleItemUse({
  required RuntimePsdkBattleSessionAdapter psdkSession,
  required BattleSession displaySession,
  required GameState gameState,
  required RuntimeActiveBattleContext context,
  required String itemId,
  required int targetLineupIndex,
  required bool isTrainerBattle,
  required ItemCatalogSnapshot itemCatalog,
  int? targetMoveIndex,
  BattleEngineDecisionRequest? request,
  String? trainerId,
  bool allowCapture = false,
}) {
  if (psdkSession.isDoubles && !identical(request, psdkSession.decisionRequest)) {
    return null;
  }
  if (psdkSession.decisionRequest.kind !=
      BattleEngineDecisionRequestKind.turnChoice) {
    return null;
  }
  final capability = ItemCapabilityResolver(itemCatalog).resolveUse(
    itemId: itemId,
    context: ProjectItemUseContext.battle,
  );
  if (!capability.isAvailable ||
      !_isSupportedBattleMedicineEffect(capability.use!.effect)) {
    return null;
  }
  final definition = itemCatalog.definitionFor(itemId);
  if (definition == null) {
    return null;
  }
  final effect = capability.use!.effect;
  final shouldConsume =
      capability.use!.consumption == ProjectItemConsumptionPolicy.onApplied;

  final party = psdkSession.state.psdkState.partyForBank(psdkPlayerSlot.bank);
  final targetPartyIndex = party.indexWhere(
    (candidate) =>
        psdkSession.lineupIndexForCombatantId(candidate.id) == targetLineupIndex,
  );
  if (targetPartyIndex < 0) {
    return null;
  }
  final targetBefore = party[targetPartyIndex];
  final battleEffect = _battleItemEffectFor(
    effect: effect,
    target: targetBefore,
    targetMoveIndex: targetMoveIndex,
  );
  if (battleEffect == null) {
    return null;
  }
  final runtimePartyIndex = _runtimePartyIndexForLineup(
    context: context,
    targetLineupIndex: targetLineupIndex,
  );
  if (runtimePartyIndex == null ||
      runtimePartyIndex < 0 ||
      runtimePartyIndex >= gameState.party.members.length) {
    return null;
  }
  final projectedGameState = writePlayerBattleLineupBackToPartySlots(
    gameState: gameState,
    context: context,
    battleState: psdkSession.createLegacyWriteBackState(),
  );
  final selectedMove = effect is ProjectItemRestorePpEffectDefinition
      ? targetBefore.moves[targetMoveIndex!]
      : null;
  var itemRequestState = runtimeBattleStateWithAvailableItems(
    session: psdkSession, gameState: projectedGameState,
  );
  if (selectedMove != null) {
    final members = [...projectedGameState.party.members];
    members[runtimePartyIndex] = members[runtimePartyIndex].copyWith(
      knownMoveIds: [selectedMove.id],
      currentPpByMoveId: {selectedMove.id: selectedMove.currentPp},
    );
    itemRequestState = itemRequestState.copyWith(
      party: projectedGameState.party.copyWith(members: members),
    );
  }
  final itemUseResult = PlayerItemUseService(snapshot: itemCatalog).use(
    PlayerItemUseRequest(
      state: itemRequestState,
      itemId: itemId,
      context: ProjectItemUseContext.battle,
      partyIndex: runtimePartyIndex,
      maxHp: targetBefore.maxHp,
      targetHasBattleConfusion:
          targetBefore.effects.contains(PsdkBattleEffectIds.confusion),
      moveId: selectedMove?.id,
      maxPpByMoveId: selectedMove == null
          ? const {}
          : {selectedMove.id: selectedMove.pp},
    ),
  );
  final consumptionReceipt = itemUseResult.consumptionReceipt;
  if (!itemUseResult.isSuccess) {
    return null;
  }
  if (shouldConsume != (consumptionReceipt != null)) {
    throw StateError('Item consumption does not match its canonical policy.');
  }

  final actor = psdkSession.decisionRequest.actor;
  final turn = psdkSession.submitBattleItem(
    itemId: itemId,
    displayName: definition.displayName,
    targetPartyIndex: targetPartyIndex,
    effect: battleEffect,
    consumeItem: shouldConsume,
    request: request,
  );
  final itemEvents = turn.timeline.events
      .whereType<BattleItemTimelineEvent>()
      .where(
        (event) =>
            event.itemId == itemId &&
            event.user.bank == actor.bank &&
            event.user.position == actor.position &&
            event.partyIndex == targetPartyIndex,
      )
      .toList(growable: false);
  final expectedItemEventKind = shouldConsume ? 'item_consumed' : 'item_used';
  if (!psdkSession.isDoubles && (itemEvents.length != 1 ||
      itemEvents.single.kind != expectedItemEventKind)) {
    throw StateError(
      'Accepted battle item must emit one event matching its consumption '
      'policy.',
    );
  }

  final targetAfter = psdkSession.state.psdkState
      .partyForBank(psdkPlayerSlot.bank)[targetPartyIndex];
  final updatedDisplaySession = psdkSession.createLegacyDisplaySession(
    isTrainerBattle: isTrainerBattle,
    trainerId: trainerId,
    allowCapture: allowCapture,
    allowFlee: displaySession.setup.allowFlee,
  );
  final committed = psdkSession.isDoubles
      ? commitRuntimeResolvedBattleItems(
          session: psdkSession, gameState: gameState, itemCatalog: itemCatalog,
        ) : null;
  final withWriteBack = turn.timeline.events.isEmpty ? gameState : writePlayerBattleLineupBackToPartySlots(
    gameState: committed?.state ?? projectedGameState.copyWith(bag: itemUseResult.state.bag),
    context: context,
    battleState: psdkSession.createLegacyWriteBackState(),
  );

  return RuntimePsdkBattleItemApplyResult(
    updatedDisplaySession: updatedDisplaySession,
    updatedGameState: withWriteBack,
    itemId: itemId,
    effectKind: _runtimeEffectKind(effect),
    targetSpeciesId: targetAfter.speciesId,
    targetLineupIndex: targetLineupIndex,
    appliedAmount: itemEvents.isEmpty ? 0 : selectedMove == null
        ? (targetAfter.currentHp - targetBefore.currentHp).clamp(
            0,
            targetAfter.maxHp,
          )
        : turn.timeline.events
            .whereType<BattleMovePpRestoredTimelineEvent>()
            .singleWhere((event) =>
                event.itemId == itemId &&
                event.user.bank == actor.bank &&
                event.user.position == actor.position &&
                event.target.bank == psdkPlayerSlot.bank &&
                event.partyIndex == targetPartyIndex &&
                event.moveSlot == targetMoveIndex)
            .amount,
    consumptionReceipt: psdkSession.isDoubles
        ? committed?.receipts[BattlePositionRef(bank: actor.bank, position: actor.position)]
        : consumptionReceipt,
  );
}

int? _runtimePartyIndexForLineup({
  required RuntimeActiveBattleContext context,
  required int targetLineupIndex,
}) {
  final mapping = context.playerPartySlotIndicesByLineupIndex;
  if (mapping.isEmpty) {
    return targetLineupIndex == 0 ? context.playerPartyIndex : null;
  }
  if (targetLineupIndex < 0 || targetLineupIndex >= mapping.length) {
    return null;
  }
  return mapping[targetLineupIndex];
}

RuntimeBattleItemApplyResult? _tryApplyRuntimeBattleHpHealItemUse({
  required BattleSession session,
  required GameState gameState,
  required RuntimeActiveBattleContext context,
  required _RuntimeBattleHpHealItemSpec itemSpec,
  required int targetLineupIndex,
}) {
  if (session.decisionRequest is! BattleTurnChoiceRequest) {
    return null;
  }

  final targetCombatant = _findPlayerCombatantByLineupIndex(
    session: session,
    targetLineupIndex: targetLineupIndex,
  );
  if (targetCombatant == null ||
      targetCombatant.isFainted ||
      targetCombatant.currentHp >= targetCombatant.maxHp) {
    return null;
  }

  final runtimePartyIndex = _runtimePartyIndexForLineup(
    context: context,
    targetLineupIndex: targetLineupIndex,
  );
  if (runtimePartyIndex == null) {
    return null;
  }
  final projectedGameState = writePlayerBattleLineupBackToPartySlots(
    gameState: gameState,
    context: context,
    battleState: session.state,
  );
  final itemUseResult = PlayerItemUseService(snapshot: itemSpec.catalog).use(
    PlayerItemUseRequest(
      state: projectedGameState,
      itemId: itemSpec.itemId,
      context: ProjectItemUseContext.battle,
      partyIndex: runtimePartyIndex,
      maxHp: targetCombatant.maxHp,
    ),
  );
  final consumptionReceipt = itemUseResult.consumptionReceipt;
  if (!itemUseResult.isSuccess) {
    return null;
  }
  final shouldConsume =
      itemSpec.consumption == ProjectItemConsumptionPolicy.onApplied;
  if (shouldConsume != (consumptionReceipt != null)) {
    throw StateError('Item consumption does not match its canonical policy.');
  }

  final updatedSession = session.applyBagHpHealItemTurn(
    itemId: itemSpec.itemId,
    displayName: itemSpec.displayName,
    targetLineupIndex: targetLineupIndex,
    effect: itemSpec.effect,
  );
  final updatedGameState = writePlayerBattleLineupBackToPartySlots(
    gameState: itemUseResult.state,
    context: context,
    battleState: updatedSession.state,
  );
  final targetAfter = _findPlayerCombatantByLineupIndex(
    session: updatedSession,
    targetLineupIndex: targetLineupIndex,
  )!;

  return RuntimeBattleItemApplyResult(
    updatedSession: updatedSession,
    updatedGameState: updatedGameState,
    itemId: itemSpec.itemId,
    targetSpeciesId: targetAfter.speciesId,
    targetLineupIndex: targetAfter.lineupIndex,
    appliedAmount: targetAfter.currentHp - targetCombatant.currentHp,
    consumptionReceipt: consumptionReceipt,
  );
}

BattleCombatant? _findPlayerCombatantByLineupIndex({
  required BattleSession session,
  required int targetLineupIndex,
}) {
  final active = session.state.player;
  if (active.lineupIndex == targetLineupIndex) {
    return active;
  }
  for (final combatant in session.state.playerReserve) {
    if (combatant.lineupIndex == targetLineupIndex) {
      return combatant;
    }
  }
  return null;
}

PsdkBattleItemActionEffect? _battleItemEffectFor({
  required ProjectItemEffectDefinition effect,
  required PsdkBattleCombatant target,
  int? targetMoveIndex,
}) {
  return switch (effect) {
    ProjectItemFullRestoreEffectDefinition() =>
      target.isFainted ||
              (target.currentHp >= target.maxHp &&
                  target.majorStatus == null &&
                  !target.effects.contains(PsdkBattleEffectIds.confusion))
          ? null
          : const PsdkBattleFullRestoreItemEffect(),
    ProjectItemHealHpEffectDefinition() =>
      target.isFainted || target.currentHp >= target.maxHp
          ? null
          : effect.mode == ProjectItemAmountMode.full
              ? const PsdkBattleHpHealItemEffect.full()
              : PsdkBattleHpHealItemEffect.flat(effect.amount!),
    ProjectItemCureStatusEffectDefinition() => _statusCureEffectFor(
        effect: effect,
        target: target,
      ),
    ProjectItemReviveEffectDefinition() => target.isFainted
        ? PsdkBattleReviveItemEffect(
            percent: (100 * effect.rateNumerator ~/ effect.rateDenominator)
                .clamp(1, 100),
          )
        : null,
    ProjectItemRestorePpEffectDefinition() =>
      targetMoveIndex == null ||
              targetMoveIndex < 0 ||
              targetMoveIndex >= target.moves.length ||
              target.moves[targetMoveIndex].currentPp >=
                  target.moves[targetMoveIndex].pp
          ? null
          : effect.mode == ProjectItemAmountMode.full
              ? PsdkBattlePpRestoreItemEffect.full(moveSlot: targetMoveIndex)
              : PsdkBattlePpRestoreItemEffect.flat(
                  effect.amount!,
                  moveSlot: targetMoveIndex,
                ),
    ProjectItemRepelEffectDefinition() ||
    ProjectItemSemanticActionEffectDefinition() =>
      null,
    _ => null,
  };
}

PsdkBattleStatusCureItemEffect? _statusCureEffectFor({
  required ProjectItemCureStatusEffectDefinition effect,
  required PsdkBattleCombatant target,
}) {
  final status = target.majorStatus;
  if (status == null || target.isFainted) {
    return null;
  }
  if (effect.mode == ProjectItemStatusCureMode.all) {
    return const PsdkBattleStatusCureItemEffect.any();
  }
  final statuses = effect.statusIds
      .map(_psdkStatusForGameplayItemStatus)
      .whereType<PsdkBattleMajorStatus>()
      .toSet();
  if (!statuses.contains(status)) {
    return null;
  }
  return PsdkBattleStatusCureItemEffect.only(statuses);
}

bool _isSupportedBattleMedicineEffect(ProjectItemEffectDefinition effect) {
  return effect is ProjectItemHealHpEffectDefinition ||
      effect is ProjectItemFullRestoreEffectDefinition ||
      effect is ProjectItemCureStatusEffectDefinition ||
      effect is ProjectItemReviveEffectDefinition ||
      effect is ProjectItemRestorePpEffectDefinition;
}

RuntimeBattleItemEffectKind _runtimeEffectKind(
  ProjectItemEffectDefinition effect,
) {
  return switch (effect) {
    ProjectItemFullRestoreEffectDefinition() =>
      RuntimeBattleItemEffectKind.fullRestore,
    ProjectItemHealHpEffectDefinition() => RuntimeBattleItemEffectKind.healHp,
    ProjectItemCureStatusEffectDefinition() =>
      RuntimeBattleItemEffectKind.cureStatus,
    ProjectItemReviveEffectDefinition() => RuntimeBattleItemEffectKind.revive,
    ProjectItemRestorePpEffectDefinition() =>
      RuntimeBattleItemEffectKind.restorePp,
    ProjectItemRepelEffectDefinition() ||
    ProjectItemSemanticActionEffectDefinition() =>
      throw StateError('Unsupported battle item effect.'),
    _ => throw StateError('Unsupported battle item effect.'),
  };
}

PsdkBattleMajorStatus? _psdkStatusForGameplayItemStatus(String statusId) {
  return switch (statusId.trim()) {
    'paralysis' || 'paralyzed' => PsdkBattleMajorStatus.paralysis,
    'burn' => PsdkBattleMajorStatus.burn,
    'poison' => PsdkBattleMajorStatus.poison,
    'badly-poisoned' => PsdkBattleMajorStatus.toxic,
    'sleep' => PsdkBattleMajorStatus.sleep,
    'freeze' || 'frozen' => PsdkBattleMajorStatus.freeze,
    _ => null,
  };
}

_RuntimeBattleHpHealItemSpec? _runtimeHpHealItemSpecForItemId(
  String itemId,
  ItemCatalogSnapshot itemCatalog,
) {
  final definition = itemCatalog.definitionFor(itemId);
  final use = ItemCapabilityResolver(itemCatalog).resolveUse(
    itemId: itemId,
    context: ProjectItemUseContext.battle,
  );
  final effect = use.use?.effect;
  if (definition == null || effect is! ProjectItemHealHpEffectDefinition) {
    return null;
  }
  return _RuntimeBattleHpHealItemSpec(
    catalog: itemCatalog,
    itemId: itemId,
    displayName: definition.displayName,
    consumption: use.use!.consumption,
    effect: effect.mode == ProjectItemAmountMode.full
        ? const BattleBagRestoreToFullHpHealEffect()
        : BattleBagFlatHpHealEffect(effect.amount!),
  );
}

class _RuntimeBattleHpHealItemSpec {
  const _RuntimeBattleHpHealItemSpec({
    required this.catalog,
    required this.itemId,
    required this.displayName,
    required this.consumption,
    required this.effect,
  });

  final ItemCatalogSnapshot catalog;
  final String itemId;
  final String displayName;
  final ProjectItemConsumptionPolicy consumption;
  final BattleBagHpHealEffect effect;
}
