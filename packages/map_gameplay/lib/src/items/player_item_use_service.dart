import 'package:map_core/map_core.dart';

import '../player_item_effects.dart';
import '../pokemon_stat_calculator.dart';
import 'bag_operation_result.dart';
import 'bag_operations.dart';
import 'item_capability_resolver.dart';
import 'item_catalog_snapshot.dart';

final class PlayerItemUseRequest {
  const PlayerItemUseRequest({
    required this.state,
    required this.itemId,
    required this.context,
    this.partyIndex = -1,
    this.maxHp = 0,
    this.moveId,
    this.maxPpByMoveId = const <String, int>{},
    this.targetHasBattleConfusion = false,
    this.baseStats,
    this.targetIsActiveBattler = false,
    this.targetBattleStages = const {},
    this.targetHasFocusEnergy = false,
    this.targetHasDragonCheer = false,
    this.targetBankHasMist = false,
  });

  final GameState state;
  final String itemId;
  final ProjectItemUseContext context;
  final int partyIndex;
  final int maxHp;
  final String? moveId;
  final Map<String, int> maxPpByMoveId;
  final bool targetHasBattleConfusion;
  final PokemonBaseStats? baseStats;
  final bool targetIsActiveBattler;
  final Map<ProjectItemBattleStat, int> targetBattleStages;
  final bool targetHasFocusEnergy;
  final bool targetHasDragonCheer;
  final bool targetBankHasMist;
}

final class PlayerItemUseService {
  PlayerItemUseService({
    required ItemCatalogSnapshot snapshot,
    BagOperations bagOperations = const BagOperations(),
  })  : resolver = ItemCapabilityResolver(snapshot),
        _bagOperations = bagOperations;

  final ItemCapabilityResolver resolver;
  final BagOperations _bagOperations;

  PlayerItemUseResult use(PlayerItemUseRequest request) {
    final itemId = request.itemId.trim();
    if (itemId.isEmpty ||
        request.targetBattleStages.values
            .any((stage) => stage < -6 || stage > 6) ||
        ((request.targetHasBattleConfusion ||
                request.targetIsActiveBattler ||
                request.targetBattleStages.isNotEmpty ||
                request.targetHasFocusEnergy ||
                request.targetHasDragonCheer ||
                request.targetBankHasMist) &&
            request.context != ProjectItemUseContext.battle)) {
      return PlayerItemUseResult.failed(
        request.state,
        PlayerItemUseFailure.invalidRequest,
      );
    }

    final capability = resolver.resolveUse(
      itemId: itemId,
      context: request.context,
    );
    if (capability.failure == ItemUseCapabilityFailure.unknownDefinition) {
      return PlayerItemUseResult.failed(
        request.state,
        PlayerItemUseFailure.unknownDefinition,
      );
    }
    if (capability.failure ==
        ItemUseCapabilityFailure.unavailableInContext) {
      return PlayerItemUseResult.failed(
        request.state,
        PlayerItemUseFailure.unavailableInContext,
      );
    }

    final use = capability.use!;
    if (use.effect is ProjectItemRepelEffectDefinition && use.target != ProjectItemTargetKind.world) {
      return PlayerItemUseResult.failed(request.state, PlayerItemUseFailure.wrongTarget);
    }
    if (use.target == ProjectItemTargetKind.world &&
        use.effect is ProjectItemRepelEffectDefinition) {
      if (request.context != ProjectItemUseContext.overworld) {
        return PlayerItemUseResult.failed(
            request.state, PlayerItemUseFailure.unavailableInContext);
      }
      if (request.state.repelState.isActive) {
        return PlayerItemUseResult.failed(
            request.state, PlayerItemUseFailure.noEffect);
      }
      if (_bagOperations.quantityOf(request.state.bag, itemId) < 1) {
        return PlayerItemUseResult.failed(
            request.state, PlayerItemUseFailure.insufficientQuantity);
      }
      final effect = use.effect as ProjectItemRepelEffectDefinition;
      if (effect.steps <= 0) {
        return PlayerItemUseResult.failed(
            request.state, PlayerItemUseFailure.invalidRequest);
      }
      final application = request.state.copyWith(
        repelState: RepelState.active(itemId: itemId, steps: effect.steps),
      );
      if (use.consumption != ProjectItemConsumptionPolicy.onApplied) {
        return PlayerItemUseResult.success(state: application);
      }
      final consumption = _bagOperations.consume(BagConsumeRequest(
        bag: request.state.bag,
        itemId: itemId,
        quantity: 1,
        itemTags: capability.item!.tags,
        reason: ItemConsumptionReason.appliedEffect,
      ));
      if (!consumption.isSuccess) {
        return PlayerItemUseResult.failed(
            request.state, _mapBagFailure(consumption.failure!));
      }
      return PlayerItemUseResult.success(
        state: application.copyWith(bag: consumption.bag),
        consumptionReceipt: consumption.consumptionReceipt,
      );
    }
    if (request.maxHp <= 0) {
      return PlayerItemUseResult.failed(
          request.state, PlayerItemUseFailure.invalidRequest);
    }
    if (use.target != ProjectItemTargetKind.partyMember &&
        use.target != ProjectItemTargetKind.partyMove) {
      return PlayerItemUseResult.failed(
        request.state,
        PlayerItemUseFailure.wrongTarget,
      );
    }
    if (request.partyIndex < 0 ||
        request.partyIndex >= request.state.party.members.length) {
      return PlayerItemUseResult.failed(
        request.state,
        PlayerItemUseFailure.invalidTarget,
      );
    }
    if (_bagOperations.quantityOf(request.state.bag, itemId) < 1) {
      return PlayerItemUseResult.failed(
        request.state,
        PlayerItemUseFailure.insufficientQuantity,
      );
    }

    final vitamin = use.effect;
    if (vitamin is ProjectItemVitaminEffectDefinition &&
        vitamin.stat == ProjectItemVitaminStat.hp &&
        request.baseStats == null) {
      return PlayerItemUseResult.failed(
          request.state, PlayerItemUseFailure.invalidRequest);
    }
    if (vitamin is ProjectItemVitaminEffectDefinition &&
        vitamin.stat == ProjectItemVitaminStat.hp &&
        request.maxHp == 1) {
      return PlayerItemUseResult.failed(
          request.state, PlayerItemUseFailure.noEffect);
    }
    final application = applyPlayerItemEffect(
      request.state.party.members[request.partyIndex],
      use: use,
      maxHp: request.maxHp,
      moveId: request.moveId,
      maxPpByMoveId: request.maxPpByMoveId,
      targetHasBattleConfusion: request.targetHasBattleConfusion,
      targetIsActiveBattler: request.targetIsActiveBattler,
      targetBattleStages: request.targetBattleStages,
      targetHasFocusEnergy: request.targetHasFocusEnergy,
      targetHasDragonCheer: request.targetHasDragonCheer,
      targetBankHasMist: request.targetBankHasMist,
    );
    if (!application.isApplied) {
      return PlayerItemUseResult.failed(
        request.state,
        application.failure!,
      );
    }

    var pokemon = application.pokemon!;
    if (vitamin is ProjectItemVitaminEffectDefinition &&
        vitamin.stat == ProjectItemVitaminStat.hp) {
      try {
        final stats = const PokemonStatCalculator().calculate(
            baseStats: request.baseStats!,
            ivs: pokemon.ivs,
            evs: pokemon.evs,
            level: pokemon.level,
            naturePolicy: PokemonNatureStatPolicy.canonical,
            natureId: pokemon.natureId);
        pokemon = pokemon.copyWith(
            currentHp: pokemon.isFainted
                ? 0
                : (pokemon.currentHp + stats.maxHp - request.maxHp)
                    .clamp(1, stats.maxHp));
      } on ArgumentError {
        return PlayerItemUseResult.failed(
            request.state, PlayerItemUseFailure.invalidRequest);
      }
    }

    Bag nextBag = request.state.bag;
    ItemConsumptionReceipt? receipt;
    if (use.consumption == ProjectItemConsumptionPolicy.onApplied) {
      final consumption = _bagOperations.consume(
        BagConsumeRequest(
          bag: request.state.bag,
          itemId: itemId,
          quantity: 1,
          itemTags: capability.item!.tags,
          reason: ItemConsumptionReason.appliedEffect,
        ),
      );
      if (!consumption.isSuccess) {
        return PlayerItemUseResult.failed(
          request.state,
          _mapBagFailure(consumption.failure!),
        );
      }
      nextBag = consumption.bag;
      receipt = consumption.consumptionReceipt;
    }

    final members = [...request.state.party.members];
    members[request.partyIndex] = pokemon;
    return PlayerItemUseResult.success(
      state: request.state.copyWith(
        party: PlayerParty(members: members).normalized(),
        bag: nextBag,
      ),
      consumptionReceipt: receipt,
    );
  }
}

PlayerItemUseFailure _mapBagFailure(BagOperationFailure failure) {
  return switch (failure) {
    BagOperationFailure.protectedKeyItem =>
      PlayerItemUseFailure.protectedKeyItem,
    BagOperationFailure.itemMissing ||
    BagOperationFailure.insufficientQuantity =>
      PlayerItemUseFailure.insufficientQuantity,
    BagOperationFailure.invalidItemId ||
    BagOperationFailure.invalidQuantity ||
    BagOperationFailure.missingItemCatalog ||
    BagOperationFailure.unknownItem ||
    BagOperationFailure.pocketFull ||
    BagOperationFailure.stackFull ||
    BagOperationFailure.quantityOverflow =>
      PlayerItemUseFailure.invalidRequest,
  };
}
