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
  final ItemConsumptionReceipt consumptionReceipt;
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
  final ItemConsumptionReceipt consumptionReceipt;
}

enum RuntimeBattleItemEffectKind { healHp, cureStatus, revive, restorePp }

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

RuntimePsdkBattleItemApplyResult? tryApplyRuntimePsdkBattleItemUse({
  required RuntimePsdkBattleSessionAdapter psdkSession,
  required BattleSession displaySession,
  required GameState gameState,
  required RuntimeActiveBattleContext context,
  required String itemId,
  required int targetLineupIndex,
  required bool isTrainerBattle,
  required ItemCatalogSnapshot itemCatalog,
  String? trainerId,
  bool allowCapture = false,
}) {
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

  final party = psdkSession.state.psdkState.partyForBank(psdkPlayerSlot.bank);
  final targetPartyIndex = party.indexWhere(
    (candidate) =>
        _runtimeLineupIndexFromPsdkId(candidate.id) == targetLineupIndex,
  );
  if (targetPartyIndex < 0) {
    return null;
  }
  final targetBefore = party[targetPartyIndex];
  final battleEffect = _battleItemEffectFor(
    effect: effect,
    target: targetBefore,
  );
  if (battleEffect == null) {
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
    battleState: displaySession.state,
  );
  final itemUseResult = PlayerItemUseService(snapshot: itemCatalog).use(
    PlayerItemUseRequest(
      state: projectedGameState,
      itemId: itemId,
      context: ProjectItemUseContext.battle,
      partyIndex: runtimePartyIndex,
      maxHp: targetBefore.maxHp,
    ),
  );
  final consumptionReceipt = itemUseResult.consumptionReceipt;
  if (!itemUseResult.isSuccess || consumptionReceipt == null) {
    return null;
  }

  final turn = psdkSession.submitBattleItem(
    itemId: itemId,
    displayName: definition.displayName,
    targetPartyIndex: targetPartyIndex,
    effect: battleEffect,
  );
  final receipts = turn.timeline.events
      .whereType<BattleItemTimelineEvent>()
      .where(
        (event) =>
            event.kind == 'item_consumed' &&
            event.itemId == itemId &&
            event.partyIndex == targetPartyIndex,
      )
      .toList(growable: false);
  if (receipts.length != 1) {
    throw StateError(
      'Accepted battle item must emit one matching consumed receipt.',
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
  final withWriteBack = writePlayerBattleLineupBackToPartySlots(
    gameState: itemUseResult.state,
    context: context,
    battleState: updatedDisplaySession.state,
  );

  return RuntimePsdkBattleItemApplyResult(
    updatedDisplaySession: updatedDisplaySession,
    updatedGameState: withWriteBack,
    itemId: itemId,
    effectKind: _runtimeEffectKind(effect),
    targetSpeciesId: targetAfter.speciesId,
    targetLineupIndex: targetLineupIndex,
    appliedAmount: (targetAfter.currentHp - targetBefore.currentHp).clamp(
      0,
      targetAfter.maxHp,
    ),
    consumptionReceipt: consumptionReceipt,
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
  if (!itemUseResult.isSuccess || consumptionReceipt == null) {
    return null;
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
}) {
  return switch (effect) {
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
    ProjectItemRestorePpEffectDefinition() ||
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
      effect is ProjectItemCureStatusEffectDefinition ||
      effect is ProjectItemReviveEffectDefinition;
}

RuntimeBattleItemEffectKind _runtimeEffectKind(
  ProjectItemEffectDefinition effect,
) {
  return switch (effect) {
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

int _runtimeLineupIndexFromPsdkId(String id) {
  final separator = id.lastIndexOf('_');
  if (separator < 0 || separator == id.length - 1) {
    return 0;
  }
  return int.tryParse(id.substring(separator + 1)) ?? 0;
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
    required this.effect,
  });

  final ItemCatalogSnapshot catalog;
  final String itemId;
  final String displayName;
  final BattleBagHpHealEffect effect;
}
