import 'package:map_core/map_core.dart';

import 'items/bag_operation_result.dart';

import 'project_item_effect_support.dart';

enum PlayerItemUseFailure {
  invalidRequest,
  unknownDefinition,
  invalidTarget,
  insufficientQuantity,
  wrongTarget,
  unavailableInContext,
  noEffect,
  unsupportedCapability,
  protectedKeyItem,
}

final class PlayerItemUseResult {
  const PlayerItemUseResult._({
    required this.state,
    required this.failure,
    required this.consumptionReceipt,
  });

  const PlayerItemUseResult.success({
    required GameState state,
    ItemConsumptionReceipt? consumptionReceipt,
  }) : this._(
          state: state,
          failure: null,
          consumptionReceipt: consumptionReceipt,
        );

  const PlayerItemUseResult.failed(
    GameState state,
    PlayerItemUseFailure failure,
  ) : this._(
          state: state,
          failure: failure,
          consumptionReceipt: null,
        );

  final GameState state;
  final PlayerItemUseFailure? failure;
  final ItemConsumptionReceipt? consumptionReceipt;

  bool get isSuccess => failure == null;
}

final class PlayerItemEffectApplication {
  const PlayerItemEffectApplication._({
    required this.pokemon,
    required this.failure,
  });

  const PlayerItemEffectApplication.applied(PlayerPokemon pokemon)
      : this._(pokemon: pokemon, failure: null);

  const PlayerItemEffectApplication.failed(PlayerItemUseFailure failure)
      : this._(pokemon: null, failure: failure);

  final PlayerPokemon? pokemon;
  final PlayerItemUseFailure? failure;

  bool get isApplied => failure == null;
}

PlayerItemEffectApplication applyPlayerItemEffect(
  PlayerPokemon target, {
  required ProjectItemUseDefinition use,
  required int maxHp,
  required String? moveId,
  required Map<String, int> maxPpByMoveId,
}) {
  // BETA-ITM-007 : le support vient de la source unique, pour que l'Item Studio
  // et le runtime ne puissent pas se contredire. Refuser ICI plutôt que dans une
  // branche du switch rend le prédicat porteur : s'il déclare un effet
  // inexécutable, aucun chemin ne peut plus l'appliquer.
  if (projectItemEffectRuntimeSupport(use.effect) ==
      ProjectItemEffectRuntimeSupport.unsupported) {
    return const PlayerItemEffectApplication.failed(
      PlayerItemUseFailure.unsupportedCapability,
    );
  }
  return switch (use.effect) {
    ProjectItemHealHpEffectDefinition(:final mode, :final amount) =>
      _applyHpHealing(target, mode: mode, amount: amount, maxHp: maxHp),
    ProjectItemCureStatusEffectDefinition(:final mode, :final statusIds) =>
      _applyStatusCure(
        target,
        mode: mode,
        statusIds: statusIds,
      ),
    ProjectItemReviveEffectDefinition(
      :final rateNumerator,
      :final rateDenominator,
    ) =>
      _applyRevive(
        target,
        maxHp: maxHp,
        rateNumerator: rateNumerator,
        rateDenominator: rateDenominator,
      ),
    ProjectItemRestorePpEffectDefinition(:final mode, :final amount) =>
      _applyPpRestore(
        target,
        mode: mode,
        amount: amount,
        moveId: moveId,
        maxPpByMoveId: maxPpByMoveId,
      ),
    // BETA-ITM-007 : le verdict de support vient de la source unique, pour que
    // l'Item Studio et le runtime ne puissent pas se contredire.
    _ => const PlayerItemEffectApplication.failed(
        PlayerItemUseFailure.unsupportedCapability,
      ),
  };
}

PlayerItemEffectApplication _applyHpHealing(
  PlayerPokemon target, {
  required ProjectItemAmountMode mode,
  required int? amount,
  required int maxHp,
}) {
  if (target.isFainted) {
    return const PlayerItemEffectApplication.failed(
      PlayerItemUseFailure.wrongTarget,
    );
  }
  if (target.currentHp >= maxHp) {
    return const PlayerItemEffectApplication.failed(
      PlayerItemUseFailure.noEffect,
    );
  }
  final healedHp =
      mode == ProjectItemAmountMode.full ? maxHp : target.currentHp + amount!;
  return PlayerItemEffectApplication.applied(
    target.copyWith(currentHp: healedHp > maxHp ? maxHp : healedHp),
  );
}

PlayerItemEffectApplication _applyStatusCure(
  PlayerPokemon target, {
  required ProjectItemStatusCureMode mode,
  required Set<String> statusIds,
}) {
  final statusId = target.statusId.trim();
  if (statusId.isEmpty) {
    return const PlayerItemEffectApplication.failed(
      PlayerItemUseFailure.noEffect,
    );
  }
  final canonicalStatusId = _canonicalItemStatusId(statusId);
  if (mode == ProjectItemStatusCureMode.listed &&
      !statusIds.map(_canonicalItemStatusId).contains(canonicalStatusId)) {
    return const PlayerItemEffectApplication.failed(
      PlayerItemUseFailure.wrongTarget,
    );
  }
  return PlayerItemEffectApplication.applied(target.copyWith(statusId: ''));
}

String _canonicalItemStatusId(String statusId) {
  return switch (statusId.trim()) {
    'par' || 'paralyzed' => 'paralysis',
    'brn' => 'burn',
    'psn' => 'poison',
    'tox' => 'badly-poisoned',
    'slp' => 'sleep',
    'frz' || 'frozen' => 'freeze',
    final normalized => normalized,
  };
}

PlayerItemEffectApplication _applyRevive(
  PlayerPokemon target, {
  required int maxHp,
  required int rateNumerator,
  required int rateDenominator,
}) {
  if (!target.isFainted) {
    return const PlayerItemEffectApplication.failed(
      PlayerItemUseFailure.wrongTarget,
    );
  }
  final revivedHp =
      (maxHp * rateNumerator + rateDenominator - 1) ~/ rateDenominator;
  return PlayerItemEffectApplication.applied(
    target.copyWith(currentHp: revivedHp < 1 ? 1 : revivedHp),
  );
}

PlayerItemEffectApplication _applyPpRestore(
  PlayerPokemon target, {
  required ProjectItemAmountMode mode,
  required int? amount,
  required String? moveId,
  required Map<String, int> maxPpByMoveId,
}) {
  final normalizedMoveId = moveId?.trim() ?? '';
  final currentPpByMoveId = target.currentPpByMoveId;
  final maxPp = maxPpByMoveId[normalizedMoveId];
  if (normalizedMoveId.isEmpty ||
      currentPpByMoveId == null ||
      !target.knownMoveIds.contains(normalizedMoveId) ||
      !currentPpByMoveId.containsKey(normalizedMoveId) ||
      maxPp == null ||
      maxPp <= 0) {
    return const PlayerItemEffectApplication.failed(
      PlayerItemUseFailure.wrongTarget,
    );
  }
  final currentPp = currentPpByMoveId[normalizedMoveId]!;
  if (currentPp >= maxPp) {
    return const PlayerItemEffectApplication.failed(
      PlayerItemUseFailure.noEffect,
    );
  }
  final restored =
      mode == ProjectItemAmountMode.full ? maxPp : currentPp + amount!;
  return PlayerItemEffectApplication.applied(
    target.copyWith(
      currentPpByMoveId: <String, int>{
        ...currentPpByMoveId,
        normalizedMoveId: restored > maxPp ? maxPp : restored,
      },
    ),
  );
}
