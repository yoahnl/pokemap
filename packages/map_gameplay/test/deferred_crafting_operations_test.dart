import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  const operations = DeferredCraftingOperations();
  final catalog = ItemCatalogSnapshot.fromCatalog(const ProjectItemCatalog(
    schemaVersion: 1,
    entries: [
      ProjectItemDefinition(
          id: 'fruit', displayName: 'Fruit', pocketId: 'materials'),
      ProjectItemDefinition(id: 'ball', displayName: 'Ball', pocketId: 'balls'),
      ProjectItemDefinition(
          id: 'other', displayName: 'Other', pocketId: 'balls'),
    ],
  ));
  DeferredCraftingDefinition definition(
          {int input = 1, int output = 1, int delay = 1}) =>
      DeferredCraftingDefinition(
          serviceId: 'artisan',
          label: 'Artisan',
          requiredDayChanges: delay,
          recipes: [
            DeferredCraftingRecipe(
                recipeId: 'fruit-ball',
                label: 'Ball',
                inputItemId: 'fruit',
                inputQuantity: input,
                outputItemId: 'ball',
                outputQuantity: output)
          ]);
  GameState initial({int quantity = 10}) => observeGameplayCalendar(
      GameState(
          saveId: 'craft-save',
          metadata: const {'unchanged': 'value'},
          bag: Bag(entries: [BagEntry(itemId: 'fruit', quantity: quantity)])),
      localDay: '2026-10-30');
  DeferredCraftingResult deposit(GameState state,
          {int quantity = 3,
          int revision = 0,
          int expectedInputQuantity = 10,
          DeferredCraftingDefinition? config}) =>
      operations.deposit(state,
          definition: config ?? definition(),
          recipeId: 'fruit-ball',
          batchQuantity: quantity,
          expectedServiceRevision: revision,
          expectedInputQuantity: expectedInputQuantity,
          itemCatalog: catalog);
  DeferredCraftingResult collect(GameState state,
          {int revision = 1,
          String orderId = 'artisan:1',
          ProjectBagCapacity capacity =
              const ProjectBagCapacity.unlimited()}) =>
      operations.collect(state,
          serviceId: 'artisan',
          expectedServiceRevision: revision,
          expectedOrderId: orderId,
          itemCatalog: catalog,
          bagCapacity: capacity);
  int owned(GameState state, String item) =>
      const BagOperations().quantityOf(state.bag, item);

  test(
      'deposit atomically removes inputs and creates a snapshot without outputs',
      () {
    final state = initial();
    final result = deposit(state);
    expect(result.isSuccess, isTrue);
    expect(owned(result.state, 'fruit'), 7);
    expect(owned(result.state, 'ball'), 0);
    final order =
        result.state.deferredCraftingState.serviceFor('artisan').pendingOrder!;
    expect(order.orderId, 'artisan:1');
    expect(order.inputQuantity, 3);
    expect(order.outputQuantity, 3);
    expect(order.submittedDayRevision, 0);
    expect(owned(state, 'fruit'), 10);
    expect(result.state.metadata, state.metadata);
    expect(operations.inspect(result.state, serviceId: 'artisan').status,
        DeferredCraftingStatus.working);
  });

  for (final quantity in [0, -1, 100, 9007199254740992]) {
    test('invalid batch $quantity leaves the same GameState', () {
      final state = initial();
      final result = deposit(state, quantity: quantity);
      expect(result.failure, DeferredCraftingFailure.invalidQuantity);
      expect(result.state, same(state));
    });
  }

  test('insufficient ingredients and stale inventory never create an order',
      () {
    final state = initial();
    expect(deposit(state, quantity: 11).failure,
        DeferredCraftingFailure.insufficientIngredients);
    final stale = deposit(state, expectedInputQuantity: 11);
    expect(stale.failure, DeferredCraftingFailure.inventoryChanged);
    expect(stale.state, same(state));
  });

  test('overflow is rejected before multiplying ingredient quantities', () {
    final state = initial();
    for (final config in [
      definition(input: maximumDeferredCraftingQuantity),
      definition(output: maximumDeferredCraftingQuantity)
    ]) {
      final result = deposit(state, quantity: 2, config: config);
      expect(result.failure, DeferredCraftingFailure.quantityOverflow);
      expect(result.state, same(state));
    }
  });

  test(
      'concurrent and replayed deposits refuse changed revision or pending order',
      () {
    final state = deposit(initial()).state;
    expect(deposit(state, expectedInputQuantity: 7).failure,
        DeferredCraftingFailure.revisionConflict);
    expect(deposit(state, revision: 1, expectedInputQuantity: 7).failure,
        DeferredCraftingFailure.orderAlreadyPending);
    expect(owned(state, 'fruit'), 7);
  });

  test('next observed day makes the exact snapshotted outputs collectible once',
      () {
    final submitted = deposit(initial()).state;
    final sameDay = observeGameplayCalendar(submitted, localDay: '2026-10-30');
    expect(collect(sameDay).failure, DeferredCraftingFailure.orderNotReady);
    final tomorrow = observeGameplayCalendar(sameDay, localDay: '2026-10-31');
    expect(operations.inspect(tomorrow, serviceId: 'artisan').status,
        DeferredCraftingStatus.ready);
    final result = collect(tomorrow);
    expect(result.isSuccess, isTrue);
    expect(owned(result.state, 'fruit'), 7);
    expect(owned(result.state, 'ball'), 3);
    expect(
        result.state.deferredCraftingState.serviceFor('artisan').pendingOrder,
        isNull);
    expect(
        result.state.deferredCraftingState.serviceFor('artisan').revision, 2);
    expect(collect(result.state).failure,
        DeferredCraftingFailure.revisionConflict);
    expect(collect(result.state, revision: 2).failure,
        DeferredCraftingFailure.noPendingOrder);
    final next = deposit(result.state, revision: 2, expectedInputQuantity: 7);
    expect(next.order!.orderId, 'artisan:3');
    expect(collect(next.state, revision: 3).failure,
        DeferredCraftingFailure.orderMismatch);
  });

  test('full bag keeps the entire order for a later exact retry', () {
    final state = observeGameplayCalendar(deposit(initial()).state,
            localDay: '2026-10-31')
        .copyWith(
            bag: const Bag(entries: [BagEntry(itemId: 'other', quantity: 1)]));
    const capacity = ProjectBagCapacity(pockets: {
      'balls': BagPocketCapacity(maxDistinctItems: 1),
    });
    final refused = collect(state, capacity: capacity);
    expect(refused.failure, DeferredCraftingFailure.bagFull);
    expect(refused.state, same(state));
    final freed = state.copyWith(bag: const Bag());
    final result = collect(freed, capacity: capacity);
    expect(result.isSuccess, isTrue);
    expect(owned(result.state, 'ball'), 3);
  });

  test('stack capacity failure grants no partial output and is retryable', () {
    final state = observeGameplayCalendar(deposit(initial()).state,
            localDay: '2026-10-31')
        .copyWith(
            bag: const Bag(entries: [BagEntry(itemId: 'ball', quantity: 4)]));
    const capacity = ProjectBagCapacity(pockets: {
      'balls': BagPocketCapacity(maxQuantityPerItem: 5),
    });
    final result = collect(state, capacity: capacity);
    expect(result.failure, DeferredCraftingFailure.bagFull);
    expect(result.state, same(state));
    expect(owned(result.state, 'ball'), 4);
  });

  test(
      'save reload preserves the order regardless of later recipe configuration',
      () {
    final state =
        deposit(initial(), config: definition(output: 2, delay: 2)).state;
    final oldOutput = state.deferredCraftingState
        .serviceFor('artisan')
        .pendingOrder!
        .outputQuantity;
    final newerRecipe = definition(output: 5);
    expect(newerRecipe.recipes.single.outputQuantity, 5);
    final reloaded = gameStateFromSaveData(SaveData.fromJson(
        jsonDecode(jsonEncode(saveDataFromGameState(state).toJson()))
            as Map<String, dynamic>));
    final tomorrow = observeGameplayCalendar(reloaded, localDay: '2026-10-31');
    expect(collect(tomorrow).failure, DeferredCraftingFailure.orderNotReady);
    final result =
        collect(observeGameplayCalendar(tomorrow, localDay: '2026-11-01'));
    expect(result.isSuccess, isTrue);
    expect(oldOutput, 6);
    expect(owned(result.state, 'ball'), oldOutput);
  });

  test('uninitialized calendar refuses deposit without inventory loss', () {
    final state = initial()
        .copyWith(gameplayCalendarState: const GameplayCalendarState.empty());
    final result = deposit(state);
    expect(result.failure, DeferredCraftingFailure.calendarUninitialized);
    expect(result.state, same(state));
  });

  test('unknown recipe or missing item catalog definition refuses mutation',
      () {
    final state = initial();
    expect(
        operations
            .deposit(state,
                definition: definition(),
                recipeId: 'missing',
                batchQuantity: 1,
                expectedServiceRevision: 0,
                expectedInputQuantity: 10,
                itemCatalog: catalog)
            .failure,
        DeferredCraftingFailure.unknownRecipe);
    expect(
        operations
            .deposit(state,
                definition: definition(),
                recipeId: 'fruit-ball',
                batchQuantity: 1,
                expectedServiceRevision: 0,
                expectedInputQuantity: 10,
                itemCatalog: ItemCatalogSnapshot.fromCatalog(
                    const ProjectItemCatalog(schemaVersion: 1, entries: [])))
            .failure,
        DeferredCraftingFailure.unknownItem);
  });
  test(
      'independent services preserve each other and can produce orders concurrently',
      () {
    final first = deposit(initial()).state;
    final other = DeferredCraftingDefinition(
        serviceId: 'other-artisan',
        label: 'Other',
        recipes: definition().recipes);
    final result = operations.deposit(first,
        definition: other,
        recipeId: 'fruit-ball',
        batchQuantity: 2,
        expectedServiceRevision: 0,
        expectedInputQuantity: 7,
        itemCatalog: catalog);
    expect(result.isSuccess, isTrue);
    expect(result.state.deferredCraftingState.servicesById, hasLength(2));
    expect(result.state.deferredCraftingState.serviceFor('artisan'),
        first.deferredCraftingState.serviceFor('artisan'));
    expect(owned(result.state, 'fruit'), 5);
  });

  test('serial transactions permit exactly one competing deposit', () async {
    final transactions = NarrativeEventStateTransactions(initial());
    Future<DeferredCraftingResult> submit() => transactions.transact((state) {
          final result = deposit(state);
          return result.isSuccess
              ? NarrativeEventStateTransaction.commit(result.state, result)
              : NarrativeEventStateTransaction.rollback(result);
        });
    final results = await Future.wait([submit(), submit()]);
    expect(results.where((result) => result.isSuccess), hasLength(1));
    expect(results.last.failure, DeferredCraftingFailure.revisionConflict);
    final committed = await transactions.read();
    expect(owned(committed, 'fruit'), 7);
    expect(committed.deferredCraftingState.servicesById, hasLength(1));
  });

  test('failed persistence callback restores inputs and pending collection',
      () async {
    final original = initial();
    final transactions = NarrativeEventStateTransactions(original);
    Future<void> rejectedDeposit() => transactions.transact((state) {
          final result = deposit(state);
          expect(result.isSuccess, isTrue);
          transactions.deferAfterCurrentCommit(
              (_) => throw StateError('storage rejected'));
          return NarrativeEventStateTransaction.commit(result.state, null);
        });
    await expectLater(rejectedDeposit(), throwsStateError);
    expect(await transactions.read(), original);
    final ready = observeGameplayCalendar(deposit(original).state,
        localDay: '2026-10-31');
    final collectionTransactions = NarrativeEventStateTransactions(ready);
    await expectLater(collectionTransactions.transact((state) {
      final result = collect(state);
      expect(result.isSuccess, isTrue);
      collectionTransactions
          .deferAfterCurrentCommit((_) => throw StateError('storage rejected'));
      return NarrativeEventStateTransaction.commit(result.state, null);
    }), throwsStateError);
    final preserved = await collectionTransactions.read();
    expect(preserved, ready);
    expect(collect(preserved).isSuccess, isTrue);
  });

  test(
      'calendar or service exhaustion refuses deposit without losing ingredients',
      () {
    final state = initial().copyWith(
        gameplayCalendarState: GameplayCalendarState(
            observedLocalDay: '2026-10-30',
            dayRevision: GameplayCalendarState.maximumRevision));
    expect(deposit(state).failure, DeferredCraftingFailure.quantityOverflow);
    final exhaustedService = initial().copyWith(
        deferredCraftingState: DeferredCraftingState(servicesById: {
      'artisan': DeferredCraftingServiceState(
          revision: GameplayCalendarState.maximumRevision - 1),
    }));
    expect(
        deposit(exhaustedService,
                revision: GameplayCalendarState.maximumRevision - 1)
            .failure,
        DeferredCraftingFailure.quantityOverflow);
    expect(owned(exhaustedService, 'fruit'), 10);
  });
  test('collect overflow or removed output item preserves the pending order',
      () {
    final state = observeGameplayCalendar(deposit(initial()).state,
            localDay: '2026-10-31')
        .copyWith(
            bag: const Bag(entries: [
      BagEntry(itemId: 'ball', quantity: maximumBagEntryQuantity)
    ]));
    final overflow = collect(state);
    expect(overflow.failure, DeferredCraftingFailure.quantityOverflow);
    expect(overflow.state, same(state));
    final unknown = operations.collect(state,
        serviceId: 'artisan',
        expectedServiceRevision: 1,
        expectedOrderId: 'artisan:1',
        itemCatalog: ItemCatalogSnapshot.fromCatalog(
            const ProjectItemCatalog(schemaVersion: 1, entries: [])));
    expect(unknown.failure, DeferredCraftingFailure.unknownItem);
    expect(unknown.state, same(state));
  });

  test(
      'rollback then observed day advance releases an order without a 24-hour timer',
      () {
    final state = deposit(initial()).state;
    final backwards = observeGameplayCalendar(state, localDay: '2026-10-29');
    expect(operations.inspect(backwards, serviceId: 'artisan').status,
        DeferredCraftingStatus.working);
    final nextObservedDay =
        observeGameplayCalendar(backwards, localDay: '2026-10-30');
    expect(collect(nextObservedDay).isSuccess, isTrue);
  });
  test('protected key-item ingredients cannot be consumed by crafting', () {
    final protectedCatalog =
        ItemCatalogSnapshot.fromCatalog(const ProjectItemCatalog(
      schemaVersion: 1,
      entries: [
        ProjectItemDefinition(
            id: 'lab-key',
            displayName: 'Lab key',
            pocketId: 'key-items',
            tags: {'key-item', 'passive'}),
        ProjectItemDefinition(
            id: 'ball', displayName: 'Ball', pocketId: 'balls'),
      ],
    ));
    final state = initial().copyWith(
        bag: const Bag(entries: [
      BagEntry(itemId: 'lab-key', quantity: 1),
    ]));
    final result = operations.deposit(state,
        definition: DeferredCraftingDefinition(
            serviceId: 'artisan',
            label: 'Artisan',
            recipes: [
              DeferredCraftingRecipe(
                  recipeId: 'key-ball',
                  label: 'Ball',
                  inputItemId: 'lab-key',
                  inputQuantity: 1,
                  outputItemId: 'ball',
                  outputQuantity: 1),
            ]),
        recipeId: 'key-ball',
        batchQuantity: 1,
        expectedServiceRevision: 0,
        expectedInputQuantity: 1,
        itemCatalog: protectedCatalog);
    expect(result.isSuccess, isFalse);
    expect(result.failure?.name, 'protectedIngredient');
    expect(result.state, same(state));
    expect(owned(result.state, 'lab-key'), 1);
    expect(
        result.state.deferredCraftingState.serviceFor('artisan').revision, 0);
    expect(
        result.state.deferredCraftingState.serviceFor('artisan').pendingOrder,
        isNull);
  });

  test('crafted key-item outputs retain the existing item-grant semantics', () {
    final outputCatalog =
        ItemCatalogSnapshot.fromCatalog(const ProjectItemCatalog(
      schemaVersion: 1,
      entries: [
        ProjectItemDefinition(
            id: 'fruit', displayName: 'Fruit', pocketId: 'materials'),
        ProjectItemDefinition(
            id: 'ball',
            displayName: 'Key result',
            pocketId: 'key-items',
            tags: {'key-item', 'passive'}),
      ],
    ));
    final ready = observeGameplayCalendar(deposit(initial()).state,
        localDay: '2026-10-31');
    final result = operations.collect(ready,
        serviceId: 'artisan',
        expectedServiceRevision: 1,
        expectedOrderId: 'artisan:1',
        itemCatalog: outputCatalog);
    expect(result.isSuccess, isTrue);
    expect(owned(result.state, 'ball'), 3);
    expect(
        result.state.deferredCraftingState.serviceFor('artisan').pendingOrder,
        isNull);
  });
}
