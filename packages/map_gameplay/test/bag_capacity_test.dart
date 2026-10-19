import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  const operations = BagOperations();
  const mutations = GameStateMutations();
  const capacity = ProjectBagCapacity(pockets: {
    'supplies': BagPocketCapacity(maxDistinctItems: 2, maxQuantityPerItem: 99),
  });
  final catalog = ItemCatalogSnapshot.fromCatalog(const ProjectItemCatalog(
    schemaVersion: 1,
    entries: [
      ProjectItemDefinition(
          id: 'tonic', displayName: 'Tonic', pocketId: 'supplies'),
      ProjectItemDefinition(
          id: 'herb', displayName: 'Herb', pocketId: 'supplies'),
      ProjectItemDefinition(
          id: 'salve', displayName: 'Salve', pocketId: 'supplies'),
      ProjectItemDefinition(
          id: 'pass', displayName: 'Pass', pocketId: 'documents'),
    ],
  ));

  BagOperationResult give(Bag bag, String itemId, int quantity,
          {ProjectBagCapacity limits = capacity}) =>
      operations.give(BagGiveRequest(
        bag: bag,
        itemId: itemId,
        quantity: quantity,
        capacity: limits,
        itemCatalog: catalog,
      ));

  const full = Bag(entries: [
    BagEntry(itemId: 'tonic', quantity: 98),
    BagEntry(itemId: 'herb', quantity: 1),
  ]);

  test('default remains unlimited and preserves one stack per item', () {
    final result = operations
        .give(const BagGiveRequest(bag: full, itemId: 'tonic', quantity: 1000));
    expect(result.isSuccess, isTrue);
    expect(operations.quantityOf(result.bag, 'tonic'), 1098);
    expect(result.bag.entries, hasLength(2));
  });

  test('full pocket permits existing stacks but rejects a new type', () {
    expect(give(full, 'tonic', 1).isSuccess, isTrue);
    final refused = give(full, 'salve', 1);
    expect(refused.failure, BagOperationFailure.pocketFull);
    expect(refused.bag, same(full));
    expect(give(full, 'pass', 1000).isSuccess, isTrue);
  });

  test('quantity cap refuses the entire receipt instead of splitting stacks',
      () {
    final refused = give(full, 'tonic', 5);
    expect(refused.failure, BagOperationFailure.stackFull);
    expect(refused.quantityAfter, 98);
    expect(refused.bag, same(full));
  });

  test('duplicate raw stacks count once and quantities are merged', () {
    const bag = Bag(entries: [
      BagEntry(itemId: 'tonic', quantity: 30),
      BagEntry(itemId: ' tonic ', quantity: 68),
    ]);
    final result = give(bag, 'herb', 1);
    expect(result.isSuccess, isTrue);
    expect(result.bag.entries, hasLength(2));
    expect(give(bag, 'tonic', 2).failure, BagOperationFailure.stackFull);
  });

  test('removing last unit frees its type slot', () {
    final freed = operations
        .take(const BagTakeRequest(bag: full, itemId: 'herb', quantity: 1));
    expect(give(freed.bag, 'salve', 1).isSuccess, isTrue);
  });

  test('capacity dimensions operate independently', () {
    const slots = ProjectBagCapacity(pockets: {
      'supplies': BagPocketCapacity(maxDistinctItems: 2),
    });
    const quantities = ProjectBagCapacity(pockets: {
      'supplies': BagPocketCapacity(maxQuantityPerItem: 99),
    });
    expect(give(full, 'tonic', 1000, limits: slots).isSuccess, isTrue);
    expect(give(full, 'salve', 1, limits: slots).isSuccess, isFalse);
    expect(give(full, 'salve', 1, limits: quantities).isSuccess, isTrue);
    expect(give(full, 'tonic', 2, limits: quantities).isSuccess, isFalse);
  });

  test('configured capacity cannot silently bypass missing catalog data', () {
    final missing = operations.give(const BagGiveRequest(
        bag: full, itemId: 'tonic', quantity: 1, capacity: capacity));
    expect(missing.failure, BagOperationFailure.missingItemCatalog);
    expect(missing.bag, same(full));
    expect(give(full, 'unknown', 1).failure, BagOperationFailure.unknownItem);
    const unknown = Bag(entries: [BagEntry(itemId: 'unknown', quantity: 1)]);
    expect(give(unknown, 'salve', 1).failure, BagOperationFailure.unknownItem);
  });

  test('gift remains available and succeeds after space is freed', () {
    const initial = GameState(saveId: 'capacity-gift', bag: full);
    final command =
        SceneGiveItemInteractiveCommand(itemId: 'salve', quantity: 1);
    final refused = executeSceneItemGift(
        command: command,
        gameState: initial,
        bagCapacity: capacity,
        itemCatalog: catalog);
    expect(refused.outcome, SceneItemGiftOutcome.bagFull);
    expect(refused.gameState, same(initial));
    final freed = initial.copyWith(
        bag: operations
            .take(const BagTakeRequest(bag: full, itemId: 'herb', quantity: 1))
            .bag);
    final received = executeSceneItemGift(
        command: command,
        gameState: freed,
        bagCapacity: capacity,
        itemCatalog: catalog);
    expect(received.outcome, SceneItemGiftOutcome.received);
    expect(operations.quantityOf(received.gameState.bag, 'salve'), 1);
  });

  test('shop refuses purchase without charging money or consuming stock', () {
    const initial = GameState(
        saveId: 'capacity-shop',
        bag: full,
        trainerProfile: TrainerProfile(name: 'Player', money: 500));
    const shop = ShopDefinition(id: 'shop', label: 'Shop', entries: [
      ShopEntryDefinition(itemId: 'salve', price: 10, stock: 5),
    ]);
    final result = mutations.purchaseFromShop(initial,
        shop: shop,
        itemId: 'salve',
        quantity: 1,
        itemCatalog: catalog,
        bagCapacity: capacity);
    expect(result.failure, ShopPurchaseFailure.bagFull);
    expect(result.state, same(initial));
    expect(result.state.trainerProfile.money, 500);
    expect(result.state.progression.shopPurchaseCounts, isEmpty);
  });

  test('held-item return refuses without removing the held item', () {
    final initial = _partyState(full, 'salve');
    final result = const HeldItemOperations().unequip(initial,
        partyIndex: 0, bagCapacity: capacity, itemCatalog: catalog);
    expect(result.failure, HeldItemTransferFailure.bagFull);
    expect(result.state, same(initial));
    expect(initial.party.members.single.heldItemId, 'salve');
  });

  test('swap evaluates capacity after removing the newly equipped item', () {
    final initial = _partyState(
        const Bag(entries: [
          BagEntry(itemId: 'tonic', quantity: 1),
          BagEntry(itemId: 'herb', quantity: 1),
        ]),
        'salve');
    final result = const HeldItemOperations().equipByIndividualId(initial,
        individualId: 'member',
        itemId: 'herb',
        bagCapacity: capacity,
        itemCatalog: catalog);
    expect(result.status, HeldItemTransferStatus.swapped);
    expect(result.state.party.members.single.heldItemId, 'herb');
    expect(operations.quantityOf(result.state.bag, 'salve'), 1);
    expect(operations.quantityOf(result.state.bag, 'herb'), 0);
  });

  test('failed swap preserves both item locations atomically', () {
    final initial = _partyState(full, 'salve');
    final result = const HeldItemOperations().equip(initial,
        partyIndex: 0,
        itemId: 'tonic',
        bagCapacity: capacity,
        itemCatalog: catalog);
    expect(result.failure, HeldItemTransferFailure.bagFull);
    expect(result.state, same(initial));
  });

  test('reward envelope refuses all grants, money and flags atomically', () {
    const initial = GameState(saveId: 'capacity-reward', bag: full);
    final reward = BattleReward(
        sourceKind: BattleRewardSourceKind.trainer,
        trainerId: 'trainer',
        money: 100,
        badgeId: 'badge',
        flagIds: {
          'reward-done'
        },
        itemGrants: const [
          BattleRewardItemGrant(itemId: 'tonic', quantity: 1),
          BattleRewardItemGrant(itemId: 'salve', quantity: 1),
        ]);
    expect(
        () => mutations.applyBattleRewards(initial,
            reward: reward, itemCatalog: catalog, bagCapacity: capacity),
        throwsA(isA<BattleRewardApplicationException>().having((e) => e.failure,
            'failure', BattleRewardApplicationFailure.bagCapacityExceeded)));
    expect(initial.bag, full);
    expect(initial.trainerProfile.money, 0);
    expect(initial.trainerProfile.badgeIds, isEmpty);
    expect(initial.storyFlags.activeFlags, isEmpty);
  });

  test('purchase and allocated bonus form one capacity transaction', () {
    const initial = GameState(
        saveId: 'capacity-bonus',
        bag: Bag(entries: [BagEntry(itemId: 'herb', quantity: 1)]),
        trainerProfile: TrainerProfile(name: 'Player', money: 500));
    const shop = ShopDefinition(id: 'shop', label: 'Shop', entries: [
      ShopEntryDefinition(
          itemId: 'tonic',
          price: 10,
          stock: 5,
          purchaseBonus: ShopPurchaseBonus(
              itemId: 'salve', everyQuantity: 1, quantity: 1)),
    ]);
    final result = mutations.purchaseFromResolvedShop(initial,
        shop: shop,
        expectedStateId: ShopStateResolver.defaultStateId,
        itemId: 'tonic',
        quantity: 1,
        itemCatalog: catalog,
        bagCapacity: capacity);
    expect(result.failure, ShopPurchaseFailure.bagFull);
    expect(result.state, same(initial));
    expect(result.state.progression.shopPurchaseCounts, isEmpty);
    expect(result.bonusQuantity, 0);
  });

  test('reward quantity cap is enforced before applying money', () {
    const initial = GameState(saveId: 'capacity-repeated-reward', bag: full);
    final reward = BattleReward(
        sourceKind: BattleRewardSourceKind.wild,
        money: 10,
        itemGrants: const [
          BattleRewardItemGrant(itemId: 'tonic', quantity: 2),
        ]);
    expect(
        () => mutations.applyBattleRewards(initial,
            reward: reward, itemCatalog: catalog, bagCapacity: capacity),
        throwsA(isA<BattleRewardApplicationException>()));
    expect(initial.bag, same(full));
  });

  test('existing overcapacity bag is preserved and cannot receive more', () {
    const over = Bag(entries: [BagEntry(itemId: 'tonic', quantity: 100)]);
    final refused = give(over, 'tonic', 1);
    expect(refused.failure, BagOperationFailure.stackFull);
    expect(refused.bag, same(over));
    expect(give(over, 'herb', 1).isSuccess, isTrue);
  });

  test('unlimited bag technical overflow has a distinct atomic reward refusal', () {
    const initial = GameState(saveId: 'overflow-reward', bag: Bag(entries: [
      BagEntry(itemId: 'tonic', quantity: maximumBagEntryQuantity),
    ]), trainerProfile: TrainerProfile(name: 'Player', money: 25));
    final reward = BattleReward(sourceKind: BattleRewardSourceKind.wild,
        money: 100, flagIds: {'reward-applied'}, itemGrants: const [
      BattleRewardItemGrant(itemId: 'tonic', quantity: 1),
    ]);
    expect(() => mutations.applyBattleRewards(initial, reward: reward,
        itemCatalog: catalog), throwsA(
      isA<BattleRewardApplicationException>().having((e) => e.failure,
          'failure', BattleRewardApplicationFailure.quantityOverflow)));
    expect(initial.trainerProfile.money, 25);
    expect(initial.storyFlags.activeFlags, isEmpty);
    expect(initial.bag.entries.single.quantity, maximumBagEntryQuantity);
  });
}

GameState _partyState(Bag bag, String heldItemId) => GameState(
    saveId: 'capacity-held',
    bag: bag,
    party: PlayerParty(members: [
      PlayerPokemon(
          individualId: 'member',
          speciesId: 'species',
          natureId: 'hardy',
          abilityId: 'ability',
          currentHp: 20,
          heldItemId: heldItemId),
    ]));
