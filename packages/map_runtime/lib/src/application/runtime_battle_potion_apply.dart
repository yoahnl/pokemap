import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';

import 'runtime_battle_outcome_apply.dart';

const _runtimeBattlePotionItemId = 'potion';
const _runtimeBattlePotionCategoryId = 'medicine';
const _runtimeBattlePotionHealAmount = 20;

class RuntimeBattlePotionApplyResult {
  const RuntimeBattlePotionApplyResult({
    required this.updatedSession,
    required this.updatedGameState,
    required this.targetSpeciesId,
    required this.targetLineupIndex,
    required this.healedAmount,
  });

  final BattleSession updatedSession;
  final GameState updatedGameState;
  final String targetSpeciesId;
  final int targetLineupIndex;
  final int healedAmount;
}

// Lot 9-e absorbe l'ancien apply local 9-d dans un vrai commit de tour :
// - `map_battle` résout maintenant un vrai `currentTurn` spécifique à Potion ;
// - ce helper reste pourtant runtime-only pour le bag et le write-back party ;
// - on n'ouvre toujours aucun système générique d'items battle ;
// - on ne fabrique jamais de `PlayerBattleChoiceUseItem`.
RuntimeBattlePotionApplyResult? tryApplyRuntimeBattlePotionUse({
  required BattleSession session,
  required GameState gameState,
  required RuntimeActiveBattleContext context,
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

  if (!_hasPotionAvailable(gameState.bag)) {
    return null;
  }

  final healedCombatant =
      targetCombatant.withHeal(_runtimeBattlePotionHealAmount);
  final healedAmount = healedCombatant.currentHp - targetCombatant.currentHp;
  if (healedAmount <= 0) {
    return null;
  }

  final updatedSession = session.applyPotionTurn(
    targetLineupIndex: targetLineupIndex,
    healAmount: _runtimeBattlePotionHealAmount,
  );
  final updatedGameState = _applyCommittedPotionTurnToRuntimeState(
    gameState: gameState,
    context: context,
    updatedSession: updatedSession,
  );

  return RuntimeBattlePotionApplyResult(
    updatedSession: updatedSession,
    updatedGameState: updatedGameState,
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

// Lot 9-e écrit désormais la vraie vérité runtime après un tour committé :
// - toute la lineup battle joueur engagée est réécrite sur la vraie party ;
// - la Potion est consommée exactement une fois après un commit battle réussi ;
// - aucun faux "state overlay only" ne survit.
GameState _applyCommittedPotionTurnToRuntimeState({
  required GameState gameState,
  required RuntimeActiveBattleContext context,
  required BattleSession updatedSession,
}) {
  final withCommittedHp = writePlayerBattleLineupBackToPartySlots(
    gameState: gameState,
    context: context,
    battleState: updatedSession.state,
  );
  return withCommittedHp.copyWith(
    bag: _consumeOnePotionOrThrow(withCommittedHp.bag),
  );
}

bool _hasPotionAvailable(Bag bag) {
  for (final entry in bag.normalized().entries) {
    if (entry.itemId == _runtimeBattlePotionItemId &&
        entry.categoryId == _runtimeBattlePotionCategoryId) {
      return true;
    }
  }
  return false;
}

Bag _consumeOnePotionOrThrow(Bag bag) {
  final nextEntries = <BagEntry>[];
  var consumed = false;

  for (final entry in bag.normalized().entries) {
    final isPotion = entry.itemId == _runtimeBattlePotionItemId &&
        entry.categoryId == _runtimeBattlePotionCategoryId;
    if (!isPotion) {
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
        'Impossible de consommer Potion : aucune entrée potion disponible.');
  }

  return Bag(entries: nextEntries).normalized();
}
