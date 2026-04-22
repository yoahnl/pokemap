import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';

import 'runtime_battle_outcome_apply.dart';

const _runtimeBattleMedicineCategoryId = 'medicine';
const _runtimeBattlePotionHealAmount = 20;
const _runtimeBattleSuperPotionHealAmount = 50;

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

/// Lot 9-f garde le fichier historique pour minimiser le blast radius, mais le
/// seam réel n'est plus "Potion seulement" :
/// - on supporte exactement `Potion` + `Super Potion` ;
/// - on refuse tout autre item ;
/// - le moteur battle commit le vrai tour ;
/// - le runtime reste propriétaire du bag réel et du write-back party.
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

  final healedCombatant = targetCombatant.withHeal(itemSpec.healAmount);
  final healedAmount = healedCombatant.currentHp - targetCombatant.currentHp;
  if (healedAmount <= 0) {
    return null;
  }

  final updatedSession = switch (itemSpec.kind) {
    BattleBagHpHealItemKind.potion => session.applyPotionTurn(
        targetLineupIndex: targetLineupIndex,
        healAmount: itemSpec.healAmount,
      ),
    BattleBagHpHealItemKind.superPotion => session.applySuperPotionTurn(
        targetLineupIndex: targetLineupIndex,
        healAmount: itemSpec.healAmount,
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

// Lot 9-f reste runtime-owner pour la vérité hors moteur :
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
    if (entry.itemId == itemSpec.itemId &&
        entry.categoryId == _runtimeBattleMedicineCategoryId) {
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
    final isRequestedItem = entry.itemId == itemSpec.itemId &&
        entry.categoryId == _runtimeBattleMedicineCategoryId;
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

_RuntimeBattleBagHpHealItemSpec _runtimeItemSpec(
  BattleBagHpHealItemKind kind,
) {
  return switch (kind) {
    BattleBagHpHealItemKind.potion => const _RuntimeBattleBagHpHealItemSpec(
        kind: BattleBagHpHealItemKind.potion,
        itemId: 'potion',
        label: 'Potion',
        healAmount: _runtimeBattlePotionHealAmount,
      ),
    BattleBagHpHealItemKind.superPotion =>
      const _RuntimeBattleBagHpHealItemSpec(
        kind: BattleBagHpHealItemKind.superPotion,
        itemId: 'super-potion',
        label: 'Super Potion',
        healAmount: _runtimeBattleSuperPotionHealAmount,
      ),
  };
}

class _RuntimeBattleBagHpHealItemSpec {
  const _RuntimeBattleBagHpHealItemSpec({
    required this.kind,
    required this.itemId,
    required this.label,
    required this.healAmount,
  });

  final BattleBagHpHealItemKind kind;
  final String itemId;
  final String label;
  final int healAmount;
}
