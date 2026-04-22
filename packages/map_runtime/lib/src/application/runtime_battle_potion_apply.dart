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

// Lot 9-d reste volontairement borné :
// - aucun contrat générique d'items battle ;
// - aucune action map_battle nouvelle ;
// - juste l'application runtime immédiate de Potion sur la lineup battle
//   courante et sur le vrai GameState.
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

  final healedCombatant = targetCombatant.withHeal(_runtimeBattlePotionHealAmount);
  final healedAmount = healedCombatant.currentHp - targetCombatant.currentHp;
  if (healedAmount <= 0) {
    return null;
  }

  final updatedSession = session.withUpdatedPlayerCombatant(healedCombatant);
  final updatedGameState = _applyPotionToRuntimeState(
    gameState: gameState,
    context: context,
    healedCombatant: healedCombatant,
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

// Le write-back lot 9-d ne touche que :
// - le slot de party runtime exactement aligné sur le lineup battle ciblé ;
// - la consommation d'une seule Potion ;
// - rien d'autre dans le save runtime.
GameState _applyPotionToRuntimeState({
  required GameState gameState,
  required RuntimeActiveBattleContext context,
  required BattleCombatant healedCombatant,
}) {
  final partyIndex = _resolvePlayerPartySlotIndex(
    context: context,
    targetLineupIndex: healedCombatant.lineupIndex,
    partyLength: gameState.party.members.length,
  );
  final members = List<PlayerPokemon>.of(gameState.party.members, growable: false);
  final currentMember = members[partyIndex];
  members[partyIndex] = currentMember.copyWith(currentHp: healedCombatant.currentHp);

  return gameState.copyWith(
    party: gameState.party.copyWith(members: members),
    bag: _consumeOnePotionOrThrow(gameState.bag),
  );
}

int _resolvePlayerPartySlotIndex({
  required RuntimeActiveBattleContext context,
  required int targetLineupIndex,
  required int partyLength,
}) {
  if (context.playerPartySlotIndicesByLineupIndex.isEmpty) {
    if (targetLineupIndex != 0) {
      throw StateError(
        'Lot 9-d ne peut pas cibler honnêtement une réserve sans mapping lineup->party runtime.',
      );
    }
    if (context.playerPartyIndex < 0 || context.playerPartyIndex >= partyLength) {
      throw StateError(
        'Lot 9-d a reçu un playerPartyIndex runtime invalide: '
        'index=${context.playerPartyIndex}, partyLength=$partyLength',
      );
    }
    return context.playerPartyIndex;
  }

  if (targetLineupIndex < 0 ||
      targetLineupIndex >= context.playerPartySlotIndicesByLineupIndex.length) {
    throw StateError(
      'Lot 9-d a reçu un lineupIndex battle invalide pour Potion: '
      'lineupIndex=$targetLineupIndex, '
      'mappingLength=${context.playerPartySlotIndicesByLineupIndex.length}',
    );
  }

  final partyIndex =
      context.playerPartySlotIndicesByLineupIndex[targetLineupIndex];
  if (partyIndex < 0 || partyIndex >= partyLength) {
    throw StateError(
      'Lot 9-d a reçu un mapping lineup->party invalide pour Potion: '
      'lineupIndex=$targetLineupIndex, partyIndex=$partyIndex, '
      'partyLength=$partyLength',
    );
  }
  return partyIndex;
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
    throw StateError('Impossible de consommer Potion : aucune entrée potion disponible.');
  }

  return Bag(entries: nextEntries).normalized();
}
