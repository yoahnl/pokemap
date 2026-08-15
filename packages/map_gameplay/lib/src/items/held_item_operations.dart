import 'package:map_core/map_core.dart';

import 'bag_operations.dart';

enum HeldItemTransferStatus { equipped, swapped, unequipped, failed }

enum HeldItemTransferFailure {
  invalidRequest,
  invalidTarget,
  itemMissing,
  noHeldItem,
  alreadyEquipped,
  quantityOverflow,
}

final class HeldItemTransferResult {
  const HeldItemTransferResult({
    required this.state,
    required this.status,
    this.failure,
    this.previousHeldItemId,
  });

  final GameState state;
  final HeldItemTransferStatus status;
  final HeldItemTransferFailure? failure;
  final String? previousHeldItemId;

  bool get isSuccess => failure == null;
}

final class HeldItemOperations {
  const HeldItemOperations();

  static const _bagOperations = BagOperations();

  HeldItemTransferResult equip(
    GameState state, {
    required int partyIndex,
    required String itemId,
  }) {
    final normalizedItemId = itemId.trim();
    if (normalizedItemId.isEmpty) {
      return _failed(state, HeldItemTransferFailure.invalidRequest);
    }
    if (!_isValidTarget(state, partyIndex)) {
      return _failed(state, HeldItemTransferFailure.invalidTarget);
    }
    final pokemon = state.party.members[partyIndex];
    final currentItemId = pokemon.heldItemId.trim();
    if (currentItemId == normalizedItemId) {
      return _failed(state, HeldItemTransferFailure.alreadyEquipped);
    }

    final taken = _bagOperations.take(
      BagTakeRequest(
        bag: state.bag,
        itemId: normalizedItemId,
        quantity: 1,
      ),
    );
    if (!taken.isSuccess) {
      return _failed(state, HeldItemTransferFailure.itemMissing);
    }

    var nextBag = taken.bag;
    if (currentItemId.isNotEmpty) {
      final returned = _bagOperations.give(
        BagGiveRequest(
          bag: nextBag,
          itemId: currentItemId,
          quantity: 1,
        ),
      );
      if (!returned.isSuccess) {
        return _failed(state, HeldItemTransferFailure.quantityOverflow);
      }
      nextBag = returned.bag;
    }

    final members = [...state.party.members];
    members[partyIndex] = pokemon.copyWith(heldItemId: normalizedItemId);
    return HeldItemTransferResult(
      state: state.copyWith(
        bag: nextBag,
        party: PlayerParty(members: members).normalized(),
      ),
      status: currentItemId.isEmpty
          ? HeldItemTransferStatus.equipped
          : HeldItemTransferStatus.swapped,
      previousHeldItemId: currentItemId.isEmpty ? null : currentItemId,
    );
  }

  HeldItemTransferResult equipByIndividualId(
    GameState state, {
    required String individualId,
    required String itemId,
  }) {
    final partyIndex = _partyIndexByIndividualId(state, individualId);
    if (partyIndex == null) {
      return _failed(state, HeldItemTransferFailure.invalidTarget);
    }
    return equip(state, partyIndex: partyIndex, itemId: itemId);
  }

  HeldItemTransferResult unequip(
    GameState state, {
    required int partyIndex,
  }) {
    if (!_isValidTarget(state, partyIndex)) {
      return _failed(state, HeldItemTransferFailure.invalidTarget);
    }
    final pokemon = state.party.members[partyIndex];
    final currentItemId = pokemon.heldItemId.trim();
    if (currentItemId.isEmpty) {
      return _failed(state, HeldItemTransferFailure.noHeldItem);
    }
    final returned = _bagOperations.give(
      BagGiveRequest(
        bag: state.bag,
        itemId: currentItemId,
        quantity: 1,
      ),
    );
    if (!returned.isSuccess) {
      return _failed(state, HeldItemTransferFailure.quantityOverflow);
    }

    final members = [...state.party.members];
    members[partyIndex] = pokemon.copyWith(heldItemId: '');
    return HeldItemTransferResult(
      state: state.copyWith(
        bag: returned.bag,
        party: PlayerParty(members: members).normalized(),
      ),
      status: HeldItemTransferStatus.unequipped,
      previousHeldItemId: currentItemId,
    );
  }

  HeldItemTransferResult unequipByIndividualId(
    GameState state, {
    required String individualId,
  }) {
    final partyIndex = _partyIndexByIndividualId(state, individualId);
    if (partyIndex == null) {
      return _failed(state, HeldItemTransferFailure.invalidTarget);
    }
    return unequip(state, partyIndex: partyIndex);
  }

  bool _isValidTarget(GameState state, int partyIndex) {
    return partyIndex >= 0 && partyIndex < state.party.members.length;
  }

  int? _partyIndexByIndividualId(GameState state, String individualId) {
    final normalizedId = individualId.trim();
    if (normalizedId.isEmpty) return null;
    final matches = state.party.members
        .asMap()
        .entries
        .where((entry) => entry.value.individualId == normalizedId)
        .toList(growable: false);
    return matches.length == 1 ? matches.single.key : null;
  }

  HeldItemTransferResult _failed(
    GameState state,
    HeldItemTransferFailure failure,
  ) {
    return HeldItemTransferResult(
      state: state,
      status: HeldItemTransferStatus.failed,
      failure: failure,
    );
  }
}
