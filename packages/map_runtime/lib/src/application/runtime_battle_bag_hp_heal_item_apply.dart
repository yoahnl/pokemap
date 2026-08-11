import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import 'runtime_battle_outcome_apply.dart';
import 'runtime_psdk_battle_session_adapter.dart';

const _runtimeBattlePotionHealAmount = 20;
const _runtimeBattleSuperPotionHealAmount = 50;
const _runtimeBattleHyperPotionHealAmount = 200;

class RuntimeBattleBagHpHealItemApplyResult {
  const RuntimeBattleBagHpHealItemApplyResult({
    required this.updatedSession,
    required this.updatedGameState,
    required this.itemKind,
    required this.targetSpeciesId,
    required this.targetLineupIndex,
    required this.healedAmount,
  });

  final BattleSession updatedSession;
  final GameState updatedGameState;
  final BattleBagHpHealItemKind itemKind;
  final String targetSpeciesId;
  final int targetLineupIndex;
  final int healedAmount;
}

class RuntimePsdkBattleBagHpHealItemApplyResult {
  const RuntimePsdkBattleBagHpHealItemApplyResult({
    required this.updatedDisplaySession,
    required this.updatedGameState,
    required this.itemKind,
    required this.targetSpeciesId,
    required this.targetLineupIndex,
    required this.healedAmount,
  });

  final BattleSession updatedDisplaySession;
  final GameState updatedGameState;
  final BattleBagHpHealItemKind itemKind;
  final String targetSpeciesId;
  final int targetLineupIndex;
  final int healedAmount;
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
  });

  final BattleSession updatedDisplaySession;
  final GameState updatedGameState;
  final String itemId;
  final RuntimeBattleItemEffectKind effectKind;
  final String targetSpeciesId;
  final int targetLineupIndex;
  final int appliedAmount;
}

enum RuntimeBattleItemEffectKind { healHp, cureStatus, revive, restorePp }

/// Runtime owner du mini-slice BAG HP-heal battle.
///
/// Le renommage reste utile au lot 9-h :
/// - avec `Potion` + `Super Potion` + `Hyper Potion` + `Max Potion`, le nom
///   historique `runtime_battle_potion_apply.dart` serait trop mensonger ;
/// - le blast radius reste raisonnable car ce seam n'est importé qu'en
///   interne par le runtime et ses tests ;
/// - on reste malgré tout strictement borné à quatre objets, pas à une famille
///   ouverte de medicines.
RuntimeBattleBagHpHealItemApplyResult? tryApplyRuntimeBattlePotionUse({
  required BattleSession session,
  required GameState gameState,
  required RuntimeActiveBattleContext context,
  required int targetLineupIndex,
}) {
  return _tryApplyRuntimeBattleBagHpHealItemUse(
    session: session,
    gameState: gameState,
    context: context,
    itemSpec: _runtimeItemSpec(BattleBagHpHealItemKind.potion),
    targetLineupIndex: targetLineupIndex,
  );
}

/// Support explicite ajouté par le lot 9-f.
///
/// On garde une façade par objet pour ne pas vendre une API runtime "tous
/// items", même si l'implémentation partage le cœur avec `Potion`.
RuntimeBattleBagHpHealItemApplyResult? tryApplyRuntimeBattleSuperPotionUse({
  required BattleSession session,
  required GameState gameState,
  required RuntimeActiveBattleContext context,
  required int targetLineupIndex,
}) {
  return _tryApplyRuntimeBattleBagHpHealItemUse(
    session: session,
    gameState: gameState,
    context: context,
    itemSpec: _runtimeItemSpec(BattleBagHpHealItemKind.superPotion),
    targetLineupIndex: targetLineupIndex,
  );
}

/// Support explicite ajouté par le lot 9-g.
///
/// Le runtime expose toujours une façade par objet pour éviter toute ambiguïté
/// produit :
/// - pas de registre d'items ;
/// - pas de `itemId` arbitraire côté API publique ;
/// - seulement le troisième objet explicitement demandé.
RuntimeBattleBagHpHealItemApplyResult? tryApplyRuntimeBattleHyperPotionUse({
  required BattleSession session,
  required GameState gameState,
  required RuntimeActiveBattleContext context,
  required int targetLineupIndex,
}) {
  return _tryApplyRuntimeBattleBagHpHealItemUse(
    session: session,
    gameState: gameState,
    context: context,
    itemSpec: _runtimeItemSpec(BattleBagHpHealItemKind.hyperPotion),
    targetLineupIndex: targetLineupIndex,
  );
}

/// Support explicite ajouté par le lot 9-h.
///
/// `Max Potion` partage le même mini-slice BAG HP-heal, mais son effet reste
/// "restore-to-full" et non un montant plat codé côté runtime.
RuntimeBattleBagHpHealItemApplyResult? tryApplyRuntimeBattleMaxPotionUse({
  required BattleSession session,
  required GameState gameState,
  required RuntimeActiveBattleContext context,
  required int targetLineupIndex,
}) {
  return _tryApplyRuntimeBattleBagHpHealItemUse(
    session: session,
    gameState: gameState,
    context: context,
    itemSpec: _runtimeItemSpec(BattleBagHpHealItemKind.maxPotion),
    targetLineupIndex: targetLineupIndex,
  );
}

RuntimePsdkBattleBagHpHealItemApplyResult?
    tryApplyRuntimePsdkBattleBagHpHealItemUse({
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
  final itemSpec = _runtimeItemSpecForItemId(itemId);
  if (itemSpec == null) {
    return null;
  }
  final generic = tryApplyRuntimePsdkBattleItemUse(
    psdkSession: psdkSession,
    displaySession: displaySession,
    gameState: gameState,
    context: context,
    itemId: itemId,
    targetLineupIndex: targetLineupIndex,
    isTrainerBattle: isTrainerBattle,
    trainerId: trainerId,
    allowCapture: allowCapture,
    itemCatalog: itemCatalog,
  );
  if (generic == null ||
      generic.effectKind != RuntimeBattleItemEffectKind.healHp) {
    return null;
  }

  return RuntimePsdkBattleBagHpHealItemApplyResult(
    updatedDisplaySession: generic.updatedDisplaySession,
    updatedGameState: generic.updatedGameState,
    itemKind: itemSpec.kind,
    targetSpeciesId: generic.targetSpeciesId,
    targetLineupIndex: generic.targetLineupIndex,
    healedAmount: generic.appliedAmount,
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
  final effect = capability.use!.effect;
  if (!_hasMedicineAvailable(bag: gameState.bag, itemId: itemId)) {
    return null;
  }

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

  final turn = psdkSession.submitBattleItem(
    itemId: itemId,
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
    gameState: gameState,
    context: context,
    battleState: updatedDisplaySession.state,
  );
  final updatedGameState = withWriteBack.copyWith(
    bag: _consumeOneMedicineOrThrow(
      bag: withWriteBack.bag,
      itemId: itemId,
    ),
  );

  return RuntimePsdkBattleItemApplyResult(
    updatedDisplaySession: updatedDisplaySession,
    updatedGameState: updatedGameState,
    itemId: itemId,
    effectKind: _runtimeEffectKind(effect),
    targetSpeciesId: targetAfter.speciesId,
    targetLineupIndex: targetLineupIndex,
    appliedAmount: (targetAfter.currentHp - targetBefore.currentHp).clamp(
      0,
      targetAfter.maxHp,
    ),
  );
}

RuntimeBattleBagHpHealItemApplyResult? _tryApplyRuntimeBattleBagHpHealItemUse({
  required BattleSession session,
  required GameState gameState,
  required RuntimeActiveBattleContext context,
  required _RuntimeBattleBagHpHealItemSpec itemSpec,
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

  if (!_hasBagHpHealItemAvailable(
    bag: gameState.bag,
    itemSpec: itemSpec,
  )) {
    return null;
  }

  final healedCombatant = switch (itemSpec.effect) {
    BattleBagFlatHpHealEffect(:final amount) => targetCombatant.withHeal(
        amount,
      ),
    BattleBagRestoreToFullHpHealEffect() => targetCombatant.withHeal(
        targetCombatant.maxHp - targetCombatant.currentHp,
      ),
  };
  final healedAmount = healedCombatant.currentHp - targetCombatant.currentHp;
  if (healedAmount <= 0) {
    return null;
  }

  final updatedSession = switch (itemSpec.kind) {
    BattleBagHpHealItemKind.potion => session.applyPotionTurn(
        targetLineupIndex: targetLineupIndex,
        healAmount: (itemSpec.effect as BattleBagFlatHpHealEffect).amount,
      ),
    BattleBagHpHealItemKind.superPotion => session.applySuperPotionTurn(
        targetLineupIndex: targetLineupIndex,
        healAmount: (itemSpec.effect as BattleBagFlatHpHealEffect).amount,
      ),
    BattleBagHpHealItemKind.hyperPotion => session.applyHyperPotionTurn(
        targetLineupIndex: targetLineupIndex,
        healAmount: (itemSpec.effect as BattleBagFlatHpHealEffect).amount,
      ),
    BattleBagHpHealItemKind.maxPotion => session.applyMaxPotionTurn(
        targetLineupIndex: targetLineupIndex,
      ),
  };
  final updatedGameState = _applyCommittedBagHpHealItemTurnToRuntimeState(
    gameState: gameState,
    context: context,
    updatedSession: updatedSession,
    itemSpec: itemSpec,
  );

  return RuntimeBattleBagHpHealItemApplyResult(
    updatedSession: updatedSession,
    updatedGameState: updatedGameState,
    itemKind: itemSpec.kind,
    targetSpeciesId: healedCombatant.speciesId,
    targetLineupIndex: healedCombatant.lineupIndex,
    healedAmount: healedAmount,
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

// Le fil 9-d -> 9-h garde le runtime propriétaire de la vérité hors moteur :
// - write-back réel de toute la lineup engagée ;
// - consommation réelle du bon item de bag ;
// - aucune divergence overlay-only.
GameState _applyCommittedBagHpHealItemTurnToRuntimeState({
  required GameState gameState,
  required RuntimeActiveBattleContext context,
  required BattleSession updatedSession,
  required _RuntimeBattleBagHpHealItemSpec itemSpec,
}) {
  final withCommittedHp = writePlayerBattleLineupBackToPartySlots(
    gameState: gameState,
    context: context,
    battleState: updatedSession.state,
  );
  return withCommittedHp.copyWith(
    bag: _consumeOneBagHpHealItemOrThrow(
      bag: withCommittedHp.bag,
      itemSpec: itemSpec,
    ),
  );
}

bool _hasBagHpHealItemAvailable({
  required Bag bag,
  required _RuntimeBattleBagHpHealItemSpec itemSpec,
}) {
  for (final entry in bag.normalized().entries) {
    if (entry.itemId == itemSpec.itemId && entry.quantity > 0) {
      return true;
    }
  }
  return false;
}

Bag _consumeOneBagHpHealItemOrThrow({
  required Bag bag,
  required _RuntimeBattleBagHpHealItemSpec itemSpec,
}) {
  final nextEntries = <BagEntry>[];
  var consumed = false;

  for (final entry in bag.normalized().entries) {
    final isRequestedItem = entry.itemId == itemSpec.itemId;
    if (!isRequestedItem) {
      nextEntries.add(entry);
      continue;
    }
    if (consumed) {
      nextEntries.add(entry);
      continue;
    }

    consumed = true;
    final nextQuantity = entry.quantity - 1;
    if (nextQuantity > 0) {
      nextEntries.add(entry.copyWith(quantity: nextQuantity));
    }
  }

  if (!consumed) {
    throw StateError(
      'Impossible de consommer ${itemSpec.label} : aucune entrée '
      '${itemSpec.itemId} disponible.',
    );
  }

  return Bag(entries: nextEntries).normalized();
}

bool _hasMedicineAvailable({
  required Bag bag,
  required String itemId,
}) {
  return bag.normalized().entries.any(
        (entry) => entry.itemId == itemId && entry.quantity > 0,
      );
}

Bag _consumeOneMedicineOrThrow({
  required Bag bag,
  required String itemId,
}) {
  final nextEntries = <BagEntry>[];
  var consumed = false;
  for (final entry in bag.normalized().entries) {
    if (!consumed && entry.itemId == itemId) {
      consumed = true;
      if (entry.quantity > 1) {
        nextEntries.add(entry.copyWith(quantity: entry.quantity - 1));
      }
    } else {
      nextEntries.add(entry);
    }
  }
  if (!consumed) {
    throw StateError(
      'Accepted battle item $itemId is absent from the medicine bag.',
    );
  }
  return Bag(entries: nextEntries).normalized();
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
      effect is ProjectItemReviveEffectDefinition ||
      effect is ProjectItemRestorePpEffectDefinition;
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

_RuntimeBattleBagHpHealItemSpec _runtimeItemSpec(
  BattleBagHpHealItemKind kind,
) {
  return switch (kind) {
    BattleBagHpHealItemKind.potion => const _RuntimeBattleBagHpHealItemSpec(
        kind: BattleBagHpHealItemKind.potion,
        itemId: 'potion',
        label: 'Potion',
        effect: BattleBagFlatHpHealEffect(_runtimeBattlePotionHealAmount),
      ),
    BattleBagHpHealItemKind.superPotion =>
      const _RuntimeBattleBagHpHealItemSpec(
        kind: BattleBagHpHealItemKind.superPotion,
        itemId: 'super-potion',
        label: 'Super Potion',
        effect: BattleBagFlatHpHealEffect(_runtimeBattleSuperPotionHealAmount),
      ),
    BattleBagHpHealItemKind.hyperPotion =>
      const _RuntimeBattleBagHpHealItemSpec(
        kind: BattleBagHpHealItemKind.hyperPotion,
        itemId: 'hyper-potion',
        label: 'Hyper Potion',
        effect: BattleBagFlatHpHealEffect(_runtimeBattleHyperPotionHealAmount),
      ),
    BattleBagHpHealItemKind.maxPotion => const _RuntimeBattleBagHpHealItemSpec(
        kind: BattleBagHpHealItemKind.maxPotion,
        itemId: 'max-potion',
        label: 'Max Potion',
        effect: BattleBagRestoreToFullHpHealEffect(),
      ),
  };
}

_RuntimeBattleBagHpHealItemSpec? _runtimeItemSpecForItemId(String itemId) {
  return switch (itemId) {
    'potion' => _runtimeItemSpec(BattleBagHpHealItemKind.potion),
    'super-potion' => _runtimeItemSpec(BattleBagHpHealItemKind.superPotion),
    'hyper-potion' => _runtimeItemSpec(BattleBagHpHealItemKind.hyperPotion),
    'max-potion' => _runtimeItemSpec(BattleBagHpHealItemKind.maxPotion),
    _ => null,
  };
}

class _RuntimeBattleBagHpHealItemSpec {
  const _RuntimeBattleBagHpHealItemSpec({
    required this.kind,
    required this.itemId,
    required this.label,
    required this.effect,
  });

  final BattleBagHpHealItemKind kind;
  final String itemId;
  final String label;
  final BattleBagHpHealEffect effect;
}
