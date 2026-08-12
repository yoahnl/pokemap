import 'package:map_core/map_core.dart';

import 'battle_reward.dart';
import 'items/bag_operation_result.dart';
import 'items/bag_operations.dart';
import 'items/item_capability_resolver.dart';
import 'items/item_catalog_snapshot.dart';
import 'script_condition_evaluator.dart';
import 'shop_state_resolver.dart';

enum CaptureDestinationKind {
  none,
  party,
  storage,
}

enum CaptureDestinationFailure {
  invalidPokemon,
  invalidPartySize,
  storageFull,
}

class CaptureDestinationResult {
  const CaptureDestinationResult({
    required this.state,
    required this.destination,
    this.partyIndex,
    this.storageIndex,
    this.boxId,
    this.boxIndex,
    this.failure,
  });

  const CaptureDestinationResult.none(
    GameState state, {
    CaptureDestinationFailure? failure,
  }) : this(
          state: state,
          destination: CaptureDestinationKind.none,
          failure: failure,
        );

  const CaptureDestinationResult.party({
    required GameState state,
    required int partyIndex,
  }) : this(
          state: state,
          destination: CaptureDestinationKind.party,
          partyIndex: partyIndex,
        );

  const CaptureDestinationResult.storage({
    required GameState state,
    required int storageIndex,
    required String boxId,
    required int boxIndex,
  }) : this(
          state: state,
          destination: CaptureDestinationKind.storage,
          storageIndex: storageIndex,
          boxId: boxId,
          boxIndex: boxIndex,
        );

  final GameState state;
  final CaptureDestinationKind destination;
  final int? partyIndex;
  final int? storageIndex;
  final String? boxId;
  final int? boxIndex;
  final CaptureDestinationFailure? failure;
}

enum ShopPurchaseFailure {
  invalidRequest,
  unknownItem,
  insufficientFunds,
  outOfStock,
  shopClosed,
  shopStateChanged,
}

/// Result of one atomic shop purchase against [GameState].
final class ShopPurchaseResult {
  const ShopPurchaseResult._({
    required this.state,
    required this.totalCost,
    this.failure,
    this.remainingStock,
  });

  const ShopPurchaseResult.success({
    required GameState state,
    required int totalCost,
    int? remainingStock,
  }) : this._(
          state: state,
          totalCost: totalCost,
          remainingStock: remainingStock,
        );

  const ShopPurchaseResult.failed({
    required GameState state,
    required int totalCost,
    required ShopPurchaseFailure failure,
    int? remainingStock,
  }) : this._(
          state: state,
          totalCost: totalCost,
          failure: failure,
          remainingStock: remainingStock,
        );

  final GameState state;
  final int totalCost;
  final ShopPurchaseFailure? failure;
  final int? remainingStock;

  bool get isSuccess => failure == null;
}

enum ShopSaleFailure {
  invalidRequest,
  unknownItem,
  insufficientQuantity,
  unsellable,
  keyItem,
  shopClosed,
  shopStateChanged,
}

/// Result of one atomic shop sale against [GameState].
final class ShopSaleResult {
  const ShopSaleResult._({
    required this.state,
    required this.totalRevenue,
    this.failure,
    this.remainingQuantity,
  });

  const ShopSaleResult.success({
    required GameState state,
    required int totalRevenue,
    required int remainingQuantity,
  }) : this._(
          state: state,
          totalRevenue: totalRevenue,
          remainingQuantity: remainingQuantity,
        );

  const ShopSaleResult.failed({
    required GameState state,
    required int totalRevenue,
    required ShopSaleFailure failure,
    int? remainingQuantity,
  }) : this._(
          state: state,
          totalRevenue: totalRevenue,
          failure: failure,
          remainingQuantity: remainingQuantity,
        );

  final GameState state;
  final int totalRevenue;
  final ShopSaleFailure? failure;
  final int? remainingQuantity;

  bool get isSuccess => failure == null;
}

enum BattleRewardApplicationFailure {
  missingItemCatalog,
  unknownItem,
}

final class BattleRewardApplicationException implements Exception {
  const BattleRewardApplicationException({
    required this.failure,
    required this.itemId,
  });

  final BattleRewardApplicationFailure failure;
  final String itemId;

  @override
  String toString() =>
      'BattleRewardApplicationException(${failure.name}, itemId: $itemId)';
}

/// Mutations pures de l'état de partie.
///
/// Chaque fonction prend un [GameState] et retourne un nouveau [GameState]
/// avec la mutation appliquée.
///
/// Ne contient aucun effet de bord.
/// Totalement testable et déterministe.
class GameStateMutations {
  const GameStateMutations();

  static const _bagOperations = BagOperations();

  int itemQuantity(GameState state, String itemId) {
    return _bagOperations.quantityOf(state.bag, itemId);
  }

  /// Définit un flag narratif à true.
  GameState setFlag(GameState state, String flagName) {
    final normalized = flagName.trim();
    if (normalized.isEmpty) return state;

    final newFlags = Set<String>.from(state.storyFlags.activeFlags)
      ..add(normalized);

    return state.copyWith(
      storyFlags: state.storyFlags.copyWith(activeFlags: newFlags),
    );
  }

  /// Définit un flag narratif à false.
  GameState clearFlag(GameState state, String flagName) {
    final normalized = flagName.trim();
    if (normalized.isEmpty) return state;

    final newFlags = Set<String>.from(state.storyFlags.activeFlags)
      ..remove(normalized);

    return state.copyWith(
      storyFlags: state.storyFlags.copyWith(activeFlags: newFlags),
    );
  }

  /// Définit une variable de script.
  GameState setVariable(
    GameState state,
    String variableName,
    ScriptVariableValue value,
  ) {
    final normalized = variableName.trim();
    if (normalized.isEmpty) return state;

    final newValues = Map<String, ScriptVariableValue>.from(
      state.scriptVariables.values,
    )..[normalized] = value;

    return state.copyWith(
      scriptVariables: state.scriptVariables.copyWith(values: newValues),
    );
  }

  /// Incrémente une variable numérique.
  ///
  /// Si la variable n'existe pas, elle est créée avec la valeur 0.
  /// Si la variable n'est pas un int, elle est ignorée.
  GameState incrementVariable(GameState state, String variableName, int delta) {
    final normalized = variableName.trim();
    if (normalized.isEmpty) return state;

    final currentValue = state.scriptVariables.values[normalized];
    int newValue = 0;

    if (currentValue != null) {
      newValue = currentValue.map(
        bool: (_) => 0,
        int: (i) => i.value + delta,
        string: (_) => 0,
      );
    } else {
      newValue = delta;
    }

    return setVariable(
      state,
      normalized,
      ScriptVariableValue.int(newValue),
    );
  }

  /// Débloque une field ability.
  GameState unlockFieldAbility(GameState state, FieldAbility ability) {
    if (state.progression.unlockedFieldAbilities.contains(ability)) {
      return state;
    }

    final newAbilities = List<FieldAbility>.from(
      state.progression.unlockedFieldAbilities,
    )..add(ability);

    return state.copyWith(
      progression: state.progression.copyWith(
        unlockedFieldAbilities: newAbilities,
      ),
    );
  }

  /// Marque un événement comme consommé.
  GameState markEventConsumed(GameState state, String eventId) {
    final normalized = eventId.trim();
    if (normalized.isEmpty) return state;

    final newConsumed = Set<String>.from(state.consumedEventIds)
      ..add(normalized);

    return state.copyWith(consumedEventIds: newConsumed);
  }

  /// Téléporte le joueur.
  GameState warpPlayer(
    GameState state,
    String mapId,
    int x,
    int y, {
    EntityFacing? facing,
  }) {
    return state.copyWith(
      currentMapId: mapId.trim().isEmpty ? state.currentMapId : mapId.trim(),
      playerPosition: GridPos(x: x, y: y),
      playerFacing: facing ?? state.playerFacing,
    );
  }

  /// Définit le mode de déplacement du joueur.
  GameState setPlayerMovementMode(GameState state, MovementMode mode) {
    return state.copyWith(playerMovementMode: mode);
  }

  /// Donne un item au joueur.
  ///
  /// L'item est ajouté dans [GameState.bag]. Si l'item existe déjà,
  /// la quantité est additionnée.
  GameState giveItem(
    GameState state,
    String itemId,
    int quantity,
  ) {
    final result = _bagOperations.give(
      BagGiveRequest(bag: state.bag, itemId: itemId, quantity: quantity),
    );
    return result.isSuccess ? state.copyWith(bag: result.bag) : state;
  }

  /// Atomically buys an item with an explicit authoring-provided unit price.
  ///
  /// Price catalogs and presentation stay outside this pure mutation. Invalid
  /// requests and insufficient funds preserve the original [GameState].
  ShopPurchaseResult purchaseItem(
    GameState state, {
    required String itemId,
    required int quantity,
    required int unitPrice,
    required ItemCatalogSnapshot itemCatalog,
  }) {
    final normalizedItemId = itemId.trim();
    const maxSafeTotal = 0x7fffffffffffffff;
    if (normalizedItemId.isEmpty ||
        quantity <= 0 ||
        unitPrice <= 0 ||
        unitPrice > maxSafeTotal ~/ quantity) {
      return ShopPurchaseResult.failed(
        state: state,
        totalCost: 0,
        failure: ShopPurchaseFailure.invalidRequest,
      );
    }
    if (ItemCapabilityResolver(itemCatalog).definitionFor(normalizedItemId) ==
        null) {
      return ShopPurchaseResult.failed(
        state: state,
        totalCost: 0,
        failure: ShopPurchaseFailure.unknownItem,
      );
    }

    final totalCost = quantity * unitPrice;
    if (state.trainerProfile.money < totalCost) {
      return ShopPurchaseResult.failed(
        state: state,
        totalCost: totalCost,
        failure: ShopPurchaseFailure.insufficientFunds,
      );
    }

    final given = _bagOperations.give(
      BagGiveRequest(
        bag: state.bag,
        itemId: normalizedItemId,
        quantity: quantity,
      ),
    );
    if (!given.isSuccess) {
      return ShopPurchaseResult.failed(
        state: state,
        totalCost: totalCost,
        failure: ShopPurchaseFailure.invalidRequest,
      );
    }
    final nextState = state.copyWith(
      trainerProfile: state.trainerProfile.copyWith(
        money: state.trainerProfile.money - totalCost,
      ),
      bag: given.bag,
    );
    return ShopPurchaseResult.success(
      state: nextState,
      totalCost: totalCost,
    );
  }

  /// Buys an item from one authored shop definition.
  ///
  /// Finite stock consumption is persisted in [PlayerProgression] so loading
  /// a save cannot replenish a project-authored shop accidentally. Unlimited
  /// entries never create purchase counters. Every counter includes the exact
  /// resolved shop state id.
  ShopPurchaseResult purchaseFromShop(
    GameState state, {
    required ShopDefinition shop,
    required String itemId,
    required int quantity,
    required ItemCatalogSnapshot itemCatalog,
  }) {
    return _purchaseFromShopEntries(
      state,
      shopId: shop.id,
      stateId: ShopStateResolver.defaultStateId,
      entries: shop.entries,
      itemId: itemId,
      quantity: quantity,
      itemCatalog: itemCatalog,
    );
  }

  /// Buys from the shop profile that is still active at transaction time.
  ///
  /// The resolver runs again immediately before the mutation. This rejects
  /// stale screens after progression changes and prevents buying from a closed
  /// profile. Stock is isolated by the exact resolved state, including the
  /// default profile.
  ShopPurchaseResult purchaseFromResolvedShop(
    GameState state, {
    required ShopDefinition shop,
    required String expectedStateId,
    required String itemId,
    required int quantity,
    required ItemCatalogSnapshot itemCatalog,
    ScriptEvaluationContext? conditionContext,
  }) {
    final normalizedExpectedStateId = expectedStateId.trim();
    if (normalizedExpectedStateId.isEmpty) {
      return ShopPurchaseResult.failed(
        state: state,
        totalCost: 0,
        failure: ShopPurchaseFailure.invalidRequest,
      );
    }
    final resolved = const ShopStateResolver().resolve(
      shop: shop,
      gameState: state,
      conditionContext: conditionContext,
    );
    if (resolved.stateId != normalizedExpectedStateId) {
      return ShopPurchaseResult.failed(
        state: state,
        totalCost: 0,
        failure: ShopPurchaseFailure.shopStateChanged,
      );
    }
    if (!resolved.isOpen) {
      return ShopPurchaseResult.failed(
        state: state,
        totalCost: 0,
        failure: ShopPurchaseFailure.shopClosed,
      );
    }
    return _purchaseFromShopEntries(
      state,
      shopId: resolved.shopId,
      stateId: resolved.stateId,
      entries: resolved.entries,
      itemId: itemId,
      quantity: quantity,
      itemCatalog: itemCatalog,
    );
  }

  ShopPurchaseResult _purchaseFromShopEntries(
    GameState state, {
    required String shopId,
    required String stateId,
    required List<ShopEntryDefinition> entries,
    required String itemId,
    required int quantity,
    required ItemCatalogSnapshot itemCatalog,
  }) {
    final normalizedItemId = itemId.trim();
    final normalizedShopId = shopId.trim();
    final normalizedStateId = stateId.trim();
    if (normalizedShopId.isEmpty ||
        normalizedStateId.isEmpty ||
        normalizedItemId.isEmpty ||
        quantity <= 0) {
      return ShopPurchaseResult.failed(
        state: state,
        totalCost: 0,
        failure: ShopPurchaseFailure.invalidRequest,
      );
    }

    ShopEntryDefinition? entry;
    for (final candidate in entries) {
      if (candidate.itemId.trim() == normalizedItemId) {
        entry = candidate;
        break;
      }
    }
    if (entry == null) {
      return ShopPurchaseResult.failed(
        state: state,
        totalCost: 0,
        failure: ShopPurchaseFailure.unknownItem,
      );
    }
    if (ItemCapabilityResolver(itemCatalog).definitionFor(normalizedItemId) ==
        null) {
      return ShopPurchaseResult.failed(
        state: state,
        totalCost: 0,
        failure: ShopPurchaseFailure.unknownItem,
      );
    }

    final stock = entry.stock;
    final stockKey = '$normalizedShopId::$normalizedStateId::$normalizedItemId';
    final purchased = state.progression.shopPurchaseCounts[stockKey] ?? 0;
    final remainingStock = stock == null ? null : stock - purchased;
    if (remainingStock != null && quantity > remainingStock) {
      return ShopPurchaseResult.failed(
        state: state,
        totalCost: entry.price > 0 ? entry.price * quantity : 0,
        failure: ShopPurchaseFailure.outOfStock,
        remainingStock: remainingStock < 0 ? 0 : remainingStock,
      );
    }

    final purchase = purchaseItem(
      state,
      itemId: normalizedItemId,
      quantity: quantity,
      unitPrice: entry.price,
      itemCatalog: itemCatalog,
    );
    if (!purchase.isSuccess || stock == null) {
      return purchase;
    }

    final nextCount = purchased + quantity;
    final nextState = purchase.state.copyWith(
      progression: purchase.state.progression.copyWith(
        shopPurchaseCounts: <String, int>{
          ...purchase.state.progression.shopPurchaseCounts,
          stockKey: nextCount,
        },
      ).normalized(),
    );
    return ShopPurchaseResult.success(
      state: nextState,
      totalCost: purchase.totalCost,
      remainingStock: stock - nextCount,
    );
  }

  /// Atomically removes one sellable bag item and credits its authored value.
  ///
  /// The canonical item definition protects key items while the Bag remains
  /// authoritative for quantity. Invalid requests preserve the original state.
  ShopSaleResult sellItem(
    GameState state, {
    required String itemId,
    required int quantity,
    required int unitPrice,
    required ItemCatalogSnapshot itemCatalog,
  }) {
    final normalizedItemId = itemId.trim();
    const maxSafeTotal = 0x7fffffffffffffff;
    if (normalizedItemId.isEmpty ||
        quantity <= 0 ||
        unitPrice <= 0 ||
        unitPrice > maxSafeTotal ~/ quantity) {
      return ShopSaleResult.failed(
        state: state,
        totalRevenue: 0,
        failure: ShopSaleFailure.invalidRequest,
      );
    }

    final definition =
        ItemCapabilityResolver(itemCatalog).definitionFor(normalizedItemId);
    if (definition == null) {
      return ShopSaleResult.failed(
        state: state,
        totalRevenue: 0,
        failure: ShopSaleFailure.unknownItem,
      );
    }
    final entry = state.bag
        .normalized()
        .entries
        .where((candidate) => candidate.itemId == normalizedItemId)
        .firstOrNull;
    if (entry == null) {
      return ShopSaleResult.failed(
        state: state,
        totalRevenue: 0,
        failure: ShopSaleFailure.unknownItem,
      );
    }
    if (definition.tags.contains('key-item')) {
      return ShopSaleResult.failed(
        state: state,
        totalRevenue: 0,
        failure: ShopSaleFailure.keyItem,
        remainingQuantity: entry.quantity,
      );
    }
    if (quantity > entry.quantity) {
      return ShopSaleResult.failed(
        state: state,
        totalRevenue: unitPrice * quantity,
        failure: ShopSaleFailure.insufficientQuantity,
        remainingQuantity: entry.quantity,
      );
    }

    final totalRevenue = unitPrice * quantity;
    if (state.trainerProfile.money > maxSafeTotal - totalRevenue) {
      return ShopSaleResult.failed(
        state: state,
        totalRevenue: totalRevenue,
        failure: ShopSaleFailure.invalidRequest,
        remainingQuantity: entry.quantity,
      );
    }
    final taken = _bagOperations.take(
      BagTakeRequest(
        bag: state.bag,
        itemId: normalizedItemId,
        quantity: quantity,
      ),
    );
    if (!taken.isSuccess) {
      return ShopSaleResult.failed(
        state: state,
        totalRevenue: totalRevenue,
        failure: ShopSaleFailure.insufficientQuantity,
        remainingQuantity: entry.quantity,
      );
    }
    final withoutItems = state.copyWith(bag: taken.bag);
    final nextState = withoutItems.copyWith(
      trainerProfile: withoutItems.trainerProfile.copyWith(
        money: withoutItems.trainerProfile.money + totalRevenue,
      ),
    );
    return ShopSaleResult.success(
      state: nextState,
      totalRevenue: totalRevenue,
      remainingQuantity: entry.quantity - quantity,
    );
  }

  /// Sells to the shop profile that is still active at transaction time.
  ///
  /// A null authored [ShopEntryDefinition.sellPrice] makes the item explicitly
  /// unsellable. Key items remain protected even if a project mistakenly
  /// assigns them a sale price.
  ShopSaleResult sellToResolvedShop(
    GameState state, {
    required ShopDefinition shop,
    required String expectedStateId,
    required String itemId,
    required int quantity,
    required ItemCatalogSnapshot itemCatalog,
    ScriptEvaluationContext? conditionContext,
  }) {
    final normalizedExpectedStateId = expectedStateId.trim();
    final normalizedItemId = itemId.trim();
    if (normalizedExpectedStateId.isEmpty ||
        normalizedItemId.isEmpty ||
        quantity <= 0) {
      return ShopSaleResult.failed(
        state: state,
        totalRevenue: 0,
        failure: ShopSaleFailure.invalidRequest,
      );
    }
    final resolved = const ShopStateResolver().resolve(
      shop: shop,
      gameState: state,
      conditionContext: conditionContext,
    );
    if (resolved.stateId != normalizedExpectedStateId) {
      return ShopSaleResult.failed(
        state: state,
        totalRevenue: 0,
        failure: ShopSaleFailure.shopStateChanged,
      );
    }
    if (!resolved.isOpen) {
      return ShopSaleResult.failed(
        state: state,
        totalRevenue: 0,
        failure: ShopSaleFailure.shopClosed,
      );
    }
    final entry = resolved.entries
        .where((candidate) => candidate.itemId == normalizedItemId)
        .firstOrNull;
    if (entry == null) {
      return ShopSaleResult.failed(
        state: state,
        totalRevenue: 0,
        failure: ShopSaleFailure.unknownItem,
      );
    }
    final sellPrice = entry.sellPrice;
    if (sellPrice == null) {
      return ShopSaleResult.failed(
        state: state,
        totalRevenue: 0,
        failure: ShopSaleFailure.unsellable,
      );
    }
    return sellItem(
      state,
      itemId: normalizedItemId,
      quantity: quantity,
      unitPrice: sellPrice,
      itemCatalog: itemCatalog,
    );
  }

  /// Consomme une quantité d'item depuis le sac.
  ///
  /// No-op sûr si l'id est vide, la quantité invalide, l'item absent ou la
  /// quantité disponible insuffisante.
  GameState consumeItem(
    GameState state, {
    required String itemId,
    required int quantity,
    required ItemCatalogSnapshot itemCatalog,
    required ItemConsumptionReason reason,
    bool allowKeyItemConsumption = false,
  }) {
    final definition = itemCatalog.definitionFor(itemId);
    if (definition == null) return state;
    final result = _bagOperations.consume(
      BagConsumeRequest(
        bag: state.bag,
        itemId: definition.id,
        quantity: quantity,
        reason: reason,
        itemTags: definition.tags,
        allowKeyItemConsumption: allowKeyItemConsumption,
      ),
    );
    return result.isSuccess ? state.copyWith(bag: result.bag) : state;
  }

  GameState removeItemForNarrativeConsequence(
    GameState state, {
    required String itemId,
    required int quantity,
  }) {
    final result = _bagOperations.take(
      BagTakeRequest(bag: state.bag, itemId: itemId, quantity: quantity),
    );
    return result.isSuccess ? state.copyWith(bag: result.bag) : state;
  }

  /// Applique un soin HP hors combat à un membre de party.
  ///
  /// Le cap HP est fourni par l'appelant car [PlayerPokemon] ne persiste pas de
  /// maxHp. Cette mutation ne contient donc aucune table d'items ou de stats.
  GameState applyHpMedicineToPartyMember(
    GameState state, {
    required int partyIndex,
    required String itemId,
    required int healAmount,
    required int maxHp,
    required ItemCatalogSnapshot itemCatalog,
  }) {
    final normalizedItemId = itemId.trim();
    if (partyIndex < 0 ||
        partyIndex >= state.party.members.length ||
        normalizedItemId.isEmpty ||
        healAmount <= 0 ||
        maxHp <= 0) {
      return state;
    }

    final target = state.party.members[partyIndex];
    final currentHp = target.currentHp < 0 ? 0 : target.currentHp;
    if (currentHp >= maxHp) {
      return state;
    }

    final hasItem = state.bag.normalized().entries.any(
          (entry) =>
              entry.itemId.trim() == normalizedItemId && entry.quantity > 0,
        );
    if (!hasItem) {
      return state;
    }

    final consumedState = consumeItem(
      state,
      itemId: normalizedItemId,
      quantity: 1,
      itemCatalog: itemCatalog,
      reason: ItemConsumptionReason.appliedEffect,
    );
    if (identical(consumedState, state)) return state;
    final healedHp = currentHp + healAmount;
    final cappedHp = healedHp > maxHp ? maxHp : healedHp;
    final nextMembers = [...consumedState.party.members];
    nextMembers[partyIndex] = nextMembers[partyIndex].copyWith(
      currentHp: cappedHp,
    );

    return consumedState.copyWith(
      party: consumedState.party.copyWith(members: nextMembers),
    );
  }

  /// Restaure la party à partir de caps HP explicites par index.
  ///
  /// Représente un recovery point minimal sans UI ni Pokemon Center persistant.
  GameState recoverParty(
    GameState state, {
    required Map<int, int> maxHpByPartyIndex,
    Map<int, Map<String, int>> maxPpByPartyIndex = const {},
    bool clearStatus = true,
  }) {
    if (state.party.members.isEmpty ||
        (maxHpByPartyIndex.isEmpty && maxPpByPartyIndex.isEmpty)) {
      return state;
    }

    final nextMembers = <PlayerPokemon>[];
    var changed = false;

    for (var index = 0; index < state.party.members.length; index++) {
      final member = state.party.members[index];
      final maxHp = maxHpByPartyIndex[index];
      final maxPpByMoveId = maxPpByPartyIndex[index];
      if ((maxHp == null || maxHp <= 0) &&
          (maxPpByMoveId == null || maxPpByMoveId.isEmpty)) {
        nextMembers.add(member);
        continue;
      }

      final nextStatusId = clearStatus ? '' : member.statusId;
      Map<String, int>? nextPpByMoveId = member.currentPpByMoveId;
      if (maxPpByMoveId != null && maxPpByMoveId.isNotEmpty) {
        final restoredPp = <String, int>{
          ...?member.currentPpByMoveId,
        };
        for (final moveId in member.knownMoveIds) {
          final maxPp = maxPpByMoveId[moveId];
          if (maxPp != null && maxPp > 0) {
            restoredPp[moveId] = maxPp;
          }
        }
        nextPpByMoveId = restoredPp;
      }
      final nextMember = member.copyWith(
        currentHp: maxHp != null && maxHp > 0 ? maxHp : member.currentHp,
        currentPpByMoveId: nextPpByMoveId,
        statusId: nextStatusId,
      );
      changed = changed || nextMember != member;
      nextMembers.add(nextMember);
    }

    if (!changed) {
      return state;
    }

    return state.copyWith(
      party: state.party.copyWith(members: nextMembers),
    );
  }

  /// Ajoute de l'argent au profil joueur.
  ///
  /// No-op sûr si [amount] est nul ou négatif. Cette mutation reste un reward
  /// minimal : elle ne crée ni shop, ni moteur économique.
  GameState addMoney(GameState state, int amount) {
    if (amount <= 0) {
      return state;
    }

    return state.copyWith(
      trainerProfile: state.trainerProfile.copyWith(
        money: state.trainerProfile.money + amount,
      ),
    );
  }

  /// Applique l'enveloppe de récompense déjà résolue par la progression.
  ///
  /// L'XP et les niveaux ne sont jamais acceptés sous forme d'incréments
  /// arbitraires ici : [BattleProgressionService] calcule et applique les
  /// grants canoniques avant d'appeler cette mutation pour l'argent, les items
  /// et les marqueurs idempotents.
  GameState applyBattleRewards(
    GameState state, {
    required BattleReward reward,
    ItemCatalogSnapshot? itemCatalog,
  }) {
    validateBattleRewardItems(
      reward: reward,
      itemCatalog: itemCatalog,
    );
    var nextState = addMoney(state, reward.money);
    for (final grant in reward.itemGrants) {
      nextState = giveItem(nextState, grant.itemId, grant.quantity);
    }
    for (final flagId in reward.flagIds) {
      nextState = setFlag(nextState, flagId);
    }
    final badgeId = reward.badgeId;
    if (badgeId != null &&
        !nextState.trainerProfile.badgeIds.contains(badgeId)) {
      nextState = nextState.copyWith(
        trainerProfile: nextState.trainerProfile.copyWith(
          badgeIds: <String>[
            ...nextState.trainerProfile.badgeIds,
            badgeId,
          ],
        ),
      );
    }
    final fieldAbility = reward.fieldAbilityUnlock;
    if (fieldAbility != null) {
      nextState = unlockFieldAbility(nextState, fieldAbility);
    }
    return nextState;
  }

  void validateBattleRewardItems({
    required BattleReward reward,
    required ItemCatalogSnapshot? itemCatalog,
  }) {
    if (reward.itemGrants.isNotEmpty && itemCatalog == null) {
      throw BattleRewardApplicationException(
        failure: BattleRewardApplicationFailure.missingItemCatalog,
        itemId: reward.itemGrants.first.itemId,
      );
    }
    for (final grant in reward.itemGrants) {
      if (itemCatalog!.definitionFor(grant.itemId) == null) {
        throw BattleRewardApplicationException(
          failure: BattleRewardApplicationFailure.unknownItem,
          itemId: grant.itemId,
        );
      }
    }
  }

  /// Applique une capture réussie vers la party ou le storage minimal.
  ///
  /// Le storage est un simple état persistant de Pokémon capturés hors party :
  /// aucune UI PC, aucun nom de box et aucune règle de gestion avancée ne sont
  /// ouverts ici.
  CaptureDestinationResult applyCapturedPokemon(
    GameState state, {
    required PlayerPokemon pokemon,
    int maxPartySize = 6,
  }) {
    final normalizedSpeciesId = pokemon.speciesId.trim();
    if (normalizedSpeciesId.isEmpty) {
      return CaptureDestinationResult.none(
        state,
        failure: CaptureDestinationFailure.invalidPokemon,
      );
    }
    if (maxPartySize <= 0 || maxPartySize > maxPlayerPartySize) {
      return CaptureDestinationResult.none(
        state,
        failure: CaptureDestinationFailure.invalidPartySize,
      );
    }

    final normalizedPokemon = pokemon.copyWith(
      speciesId: normalizedSpeciesId,
    );

    if (state.party.members.length < maxPartySize) {
      final partyIndex = state.party.members.length;
      final nextMembers = [...state.party.members, normalizedPokemon];
      final nextState = normalizeLoadedGameState(
        state.copyWith(
          party: state.party.copyWith(members: nextMembers),
        ),
      );

      return CaptureDestinationResult.party(
        state: nextState,
        partyIndex: partyIndex,
      );
    }

    final storage = state.pokemonStorage.normalized();
    final targetBoxListIndex = storage.boxes.indexWhere(
      (box) => box.pokemon.length < box.capacity,
    );
    if (targetBoxListIndex < 0) {
      return CaptureDestinationResult.none(
        state,
        failure: CaptureDestinationFailure.storageFull,
      );
    }
    final targetBox = storage.boxes[targetBoxListIndex];
    final boxIndex = targetBox.pokemon.length;
    final storageIndex = storage.boxes
            .take(targetBoxListIndex)
            .fold<int>(0, (total, box) => total + box.pokemon.length) +
        boxIndex;
    final nextBoxes = [...storage.boxes];
    nextBoxes[targetBoxListIndex] = targetBox.copyWith(
      pokemon: <PlayerPokemon>[...targetBox.pokemon, normalizedPokemon],
    );
    final nextState = normalizeLoadedGameState(
      state.copyWith(
        pokemonStorage: PokemonStorage(boxes: nextBoxes).normalized(),
      ),
    );

    return CaptureDestinationResult.storage(
      state: nextState,
      storageIndex: storageIndex,
      boxId: targetBox.id,
      boxIndex: boxIndex,
    );
  }

  /// Donne un Pokémon au joueur.
  ///
  /// Le [PlayerPokemon] doit être construit par l'appelant (authoring, script,
  /// scénario). Cette mutation ne calcule pas les stats, moves ou HP : elle
  /// ajoute un Pokémon déjà valide à la party.
  ///
  /// Si [preventDuplicateSpecies] est `true`, la mutation est un no-op si la
  /// party contient déjà un Pokémon du même [PlayerPokemon.speciesId].
  ///
  /// Invariant mechanics-first : aucun speciesId n'est hardcodé ici.
  /// Le Pokémon est fourni par l'appelant, pas décidé par la mutation.
  GameState givePokemon(
    GameState state, {
    required PlayerPokemon pokemon,
    bool preventDuplicateSpecies = false,
  }) {
    final normalizedSpeciesId = pokemon.speciesId.trim();
    if (normalizedSpeciesId.isEmpty) {
      // speciesId vide/blank = Pokémon invalide, no-op sûr.
      return state;
    }

    if (preventDuplicateSpecies) {
      final alreadyOwned = state.party.members.any(
        (m) => m.speciesId.trim() == normalizedSpeciesId,
      );
      if (alreadyOwned) {
        return state;
      }
    }

    final normalizedPokemon = pokemon.copyWith(
      speciesId: normalizedSpeciesId,
    );

    final newMembers = [...state.party.members, normalizedPokemon];

    return state.copyWith(
      party: state.party.copyWith(members: newMembers),
    );
  }

  /// Marque une étape narrative comme complétée.
  ///
  /// L'opération est **idempotente** : compléter deux fois la même step
  /// ne crée pas de doublon dans [PlayerProgression.completedStepIds].
  ///
  /// Si [stepId] est vide ou blanc, retourne le state inchangé (no-op sûr).
  ///
  /// Invariant mechanics-first : aucun stepId n'est hardcodé ici.
  /// L'appelant (scénario, script, éditeur) choisit l'id.
  GameState completeStep(GameState state, String stepId) {
    final normalized = stepId.trim();
    if (normalized.isEmpty) return state;

    final existing = state.progression.completedStepIds;
    if (existing.contains(normalized)) {
      // Idempotent : step déjà complétée, pas de doublon.
      return state;
    }

    final newStepIds = [...existing, normalized];
    return state.copyWith(
      progression: state.progression.copyWith(
        completedStepIds: newStepIds,
      ),
    );
  }

  /// Applique un lot de mutations atomiquement.
  GameState applyAll(
    GameState state,
    List<GameState Function(GameState)> mutations,
  ) {
    var result = state;
    for (final mutation in mutations) {
      result = mutation(result);
    }
    return result;
  }
}
