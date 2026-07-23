import 'dart:collection';

import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';

/// Deterministic stand-in for the Flutter service routes used by the host.
///
/// The Scene still opens the production [PlayerServiceRuntimeController]. This
/// adapter only represents the explicit taps a player would make inside the
/// modal page; all state changes use the same gameplay operations as the real
/// Shop and PC widgets.
final class SelbrumePlayerServiceTestHost implements PlayerServiceOverlayHost {
  final Queue<String> _shopPurchases = Queue<String>();
  var _withdrawCapturedPokemonOnNextPcOpen = false;

  final List<String> openedServices = <String>[];
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
    if (_shopPurchases.isEmpty) {
      return const PlayerServiceHostResult.cancelled();
    }
    final itemId = _shopPurchases.removeFirst();
    final purchase = const GameStateMutations().purchaseFromShop(
      request.gameState,
      shop: request.shop,
      itemId: itemId,
      categoryId: _categoryFor(itemId),
      quantity: 1,
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

String _categoryFor(String itemId) => switch (itemId) {
      'potion' || 'antidote' => 'medicine',
      _ => 'items',
    };
