import 'package:map_core/map_core.dart';

import '../player_item_effects.dart';
import 'bag_operation_result.dart';
import 'bag_operations.dart';
import 'item_capability_resolver.dart';
import 'item_catalog_snapshot.dart';

final class PlayerItemUseRequest {
  const PlayerItemUseRequest({
    required this.state,
    required this.itemId,
    required this.context,
    required this.partyIndex,
    required this.maxHp,
    this.moveId,
    this.maxPpByMoveId = const <String, int>{},
  });

  final GameState state;
  final String itemId;
  final ProjectItemUseContext context;
  final int partyIndex;
  final int maxHp;
  final String? moveId;
  final Map<String, int> maxPpByMoveId;
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
    if (itemId.isEmpty || request.maxHp <= 0) {
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

    final application = applyPlayerItemEffect(
      request.state.party.members[request.partyIndex],
      use: use,
      maxHp: request.maxHp,
      moveId: request.moveId,
      maxPpByMoveId: request.maxPpByMoveId,
    );
    if (!application.isApplied) {
      return PlayerItemUseResult.failed(
        request.state,
        application.failure!,
      );
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
    members[request.partyIndex] = application.pokemon!;
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
    BagOperationFailure.quantityOverflow =>
      PlayerItemUseFailure.invalidRequest,
  };
}
