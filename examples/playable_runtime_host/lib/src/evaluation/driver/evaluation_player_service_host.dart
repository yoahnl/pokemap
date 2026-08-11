import 'dart:collection';

import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';

/// Deterministic adapter for the player actions performed in service overlays.
///
/// The production [PlayerServiceRuntimeController] still resolves the request
/// and owns the commit transaction. This host only records the explicit action
/// selected by an evaluation scenario.
final class EvaluationPlayerServiceHost implements PlayerServiceOverlayHost {
  final Queue<String> _shopPurchases = Queue<String>();
  var _withdrawCapturedPokemonOnNextPcOpen = false;

  final List<String> openedServices = <String>[];
  final List<PlayerServiceShopRequest> shopRequests =
      <PlayerServiceShopRequest>[];
  final List<String> purchasedItemIds = <String>[];
  String? withdrawnSpeciesId;

  void queueShopPurchase(String itemId) => _shopPurchases.add(itemId);

  void queueCapturedPokemonWithdrawal() {
    _withdrawCapturedPokemonOnNextPcOpen = true;
  }

  @override
  Future<PlayerServiceHostResult> openShop(
    PlayerServiceShopRequest request,
  ) async {
    openedServices.add('shop:${request.shop.id}');
    shopRequests.add(request);
    if (_shopPurchases.isEmpty) {
      return const PlayerServiceHostResult.cancelled();
    }
    final itemId = _shopPurchases.removeFirst();
    final purchase = const GameStateMutations().purchaseFromResolvedShop(
      request.gameState,
      shop: request.shop,
      expectedStateId: request.resolvedState.stateId,
      itemId: itemId,
      quantity: 1,
      itemCatalog: request.itemCatalog,
      conditionContext: request.conditionContext,
    );
    if (!purchase.isSuccess) {
      throw StateError('Selbrume shop purchase failed: ${purchase.failure}.');
    }
    purchasedItemIds.add(itemId);
    return PlayerServiceHostResult.completed(purchase.state);
  }

  @override
  Future<PlayerServiceHostResult> openPc(PlayerServicePcRequest request) async {
    openedServices.add('pc');
    if (!_withdrawCapturedPokemonOnNextPcOpen) {
      return const PlayerServiceHostResult.cancelled();
    }
    _withdrawCapturedPokemonOnNextPcOpen = false;
    final storage = request.gameState.pokemonStorage.normalized();
    final box =
        storage.boxes.firstWhere((candidate) => candidate.pokemon.isNotEmpty);
    final capturedSpeciesId = box.pokemon.first.speciesId;
    const operations = PlayerStorageOperations();
    final deposit = operations.deposit(
      state: request.gameState.copyWith(pokemonStorage: storage),
      partyIndex: 1,
      boxId: box.id,
    );
    if (!deposit.isSuccess) {
      throw StateError('Selbrume PC deposit failed: ${deposit.failure}.');
    }
    final withdrawal = operations.withdraw(
      state: deposit.state,
      boxId: box.id,
      boxIndex: 0,
    );
    if (!withdrawal.isSuccess) {
      throw StateError('Selbrume PC withdrawal failed: ${withdrawal.failure}.');
    }
    withdrawnSpeciesId = capturedSpeciesId;
    return PlayerServiceHostResult.completed(withdrawal.state);
  }

  @override
  Future<PlayerServiceHostResult> openHealCenter(
    PlayerServiceHealRequest request,
  ) async {
    openedServices.add('heal');
    return const PlayerServiceHostResult.cancelled();
  }
}
