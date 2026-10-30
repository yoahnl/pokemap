import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';

final definition = DeferredCraftingDefinition(
  serviceId: 'artisan',
  label: 'Artisan',
  recipes: [
    DeferredCraftingRecipe(
      recipeId: 'fruit-ball',
      label: 'Ball',
      inputItemId: 'fruit',
      inputQuantity: 2,
      outputItemId: 'ball',
      outputQuantity: 1,
    ),
  ],
);
final catalog = ItemCatalogSnapshot.fromCatalog(
  const ProjectItemCatalog(
    schemaVersion: 1,
    entries: [
      ProjectItemDefinition(
        id: 'fruit',
        displayName: 'Fruit',
        pocketId: 'materials',
      ),
      ProjectItemDefinition(id: 'ball', displayName: 'Ball', pocketId: 'balls'),
    ],
  ),
);

void main() {
  test('typed crafting snapshots cross companion JSON transport', () async {
    final fixture = _Fixture();
    addTearDown(fixture.controller.dispose);
    final opening = fixture.open();
    await fixture.untilActive();
    await fixture.send(RuntimeWorldServiceAction.select, target: 'fruit-ball');
    final original = fixture.controller.worldServiceSnapshot!;
    final wire = RuntimeCompanionPresentationCodec.encodeWorldService(original);
    final decoded = RuntimeCompanionPresentationCodec.decodeWorldService(
      jsonDecode(jsonEncode(wire)) as Map<String, dynamic>,
    );
    expect((decoded.request as OpenCraftingService).definition, definition);
    final content = decoded.content as RuntimeCraftingServiceContent;
    expect(content.selectedRecipeId, 'fruit-ball');
    expect(content.recipes.single.inputLabel, 'Fruit');
    expect(content.recipes.single.ownedQuantity, 10);
    expect(decoded.revision, original.revision);
    await fixture.send(RuntimeWorldServiceAction.cancel);
    await opening;
  });
  test(
    'host without explicit durable crafting transaction fails closed',
    () async {
      var writes = 0;
      final locks = <bool>[];
      final controller = PlayerServiceRuntimeController.contextual(
        currentGameState: () => const GameState(saveId: 'safe'),
        commitAndSave: (_) async {
          writes++;
        },
        setInputLocked: locks.add,
        loadRecoveryCaps: (_) async =>
            const RuntimePlayerServiceRecoveryCaps(maxHpByPartyIndex: {}),
        itemCatalog: catalog,
      );
      addTearDown(controller.dispose);
      final result = await controller.openCrafting(
        request: OpenCraftingService(
          interactionId: 'craft',
          definition: definition,
        ),
      );
      expect(result.status, PlayerServiceRuntimeStatus.unavailable);
      expect(writes, 0);
      expect(locks, isEmpty);
      expect(controller.worldServiceSnapshot, isNull);
    },
  );
  test(
    'cancel before confirmation preserves inventory and does not persist',
    () async {
      final fixture = _Fixture();
      addTearDown(fixture.controller.dispose);
      final opening = fixture.open();
      await fixture.untilActive();
      await fixture.send(RuntimeWorldServiceAction.cancel);
      expect((await opening).status, PlayerServiceRuntimeStatus.cancelled);
      expect(fixture.writes, 0);
      expect(fixture.owned('fruit'), 10);
      expect(fixture.locks, [true, false]);
    },
  );
  test(
    'confirmation persists atomic deposit once and rejects stale replay',
    () async {
      final fixture = _Fixture();
      addTearDown(fixture.controller.dispose);
      final opening = fixture.open();
      await fixture.untilActive();
      await fixture.send(
        RuntimeWorldServiceAction.select,
        target: 'fruit-ball',
      );
      await fixture.send(RuntimeWorldServiceAction.increaseQuantity);
      await fixture.send(RuntimeWorldServiceAction.confirm);
      final revision = fixture.controller.worldServiceSnapshot!.revision;
      await fixture.send(RuntimeWorldServiceAction.confirm);
      expect(fixture.owned('fruit'), 6);
      expect(fixture.owned('ball'), 0);
      expect(fixture.writes, 1);
      expect(
        (await fixture.controller.dispatchWorldService(
          RuntimeWorldServiceCommand(
            action: RuntimeWorldServiceAction.confirm,
            snapshotRevision: revision,
          ),
        )).status,
        RuntimeWorldServiceCommandStatus.stale,
      );
      await fixture.send(RuntimeWorldServiceAction.close);
      expect((await opening).status, PlayerServiceRuntimeStatus.completed);
    },
  );
  test(
    'durable failure retains ingredients and order absence then permits retry',
    () async {
      final fixture = _Fixture()..failSave = true;
      addTearDown(fixture.controller.dispose);
      final opening = fixture.open();
      await fixture.untilActive();
      await fixture.send(
        RuntimeWorldServiceAction.select,
        target: 'fruit-ball',
      );
      await fixture.send(RuntimeWorldServiceAction.confirm);
      expect(
        (await fixture.send(RuntimeWorldServiceAction.confirm)).status,
        RuntimeWorldServiceCommandStatus.failed,
      );
      expect(fixture.owned('fruit'), 10);
      expect(
        fixture.state.deferredCraftingState.serviceFor('artisan').pendingOrder,
        isNull,
      );
      fixture.failSave = false;
      await fixture.send(RuntimeWorldServiceAction.confirm);
      expect(fixture.owned('fruit'), 8);
      await fixture.send(RuntimeWorldServiceAction.close);
      expect((await opening).status, PlayerServiceRuntimeStatus.completed);
    },
  );
  test(
    'next civil day across reload collects once without waiting 24 hours',
    () async {
      final fixture = _Fixture();
      addTearDown(fixture.controller.dispose);
      final opening = fixture.open();
      await fixture.untilActive();
      await fixture.send(
        RuntimeWorldServiceAction.select,
        target: 'fruit-ball',
      );
      await fixture.send(RuntimeWorldServiceAction.confirm);
      await fixture.send(RuntimeWorldServiceAction.confirm);
      await fixture.send(RuntimeWorldServiceAction.close);
      await opening;
      fixture.state = GameState.fromJson(
        strictGameStateSaveJson(fixture.state),
      );
      fixture.now = DateTime(2026, 10, 31, 0, 1);
      final collection = fixture.open();
      await fixture.untilActive();
      expect(
        (fixture.controller.worldServiceSnapshot!.content
                as RuntimeCraftingServiceContent)
            .status,
        RuntimeCraftingStatus.ready,
      );
      await fixture.send(RuntimeWorldServiceAction.confirm);
      expect(fixture.owned('ball'), 1);
      expect(
        fixture.state.deferredCraftingState.serviceFor('artisan').pendingOrder,
        isNull,
      );
      await fixture.send(RuntimeWorldServiceAction.close);
      await collection;
      final reopened = fixture.open();
      await fixture.untilActive();
      expect(
        (fixture.controller.worldServiceSnapshot!.content
                as RuntimeCraftingServiceContent)
            .status,
        RuntimeCraftingStatus.idle,
      );
      await fixture.send(RuntimeWorldServiceAction.cancel);
      await reopened;
      expect(fixture.owned('ball'), 1);
      expect(fixture.writes, 2);
    },
  );
  test(
    'bag full retains ready order and failed collection saves nothing',
    () async {
      final fixture = _Fixture(
        capacity: const ProjectBagCapacity(
          pockets: {
            'balls': BagPocketCapacity(
              maxDistinctItems: 1,
              maxQuantityPerItem: 1,
            ),
          },
        ),
      );
      addTearDown(fixture.controller.dispose);
      fixture.state = observeGameplayCalendar(
        fixture.state,
        localDay: '2026-10-30',
      );
      fixture.state = const DeferredCraftingOperations()
          .deposit(
            fixture.state,
            definition: definition,
            recipeId: 'fruit-ball',
            batchQuantity: 1,
            expectedServiceRevision: 0,
            expectedInputQuantity: 10,
            itemCatalog: catalog,
          )
          .state;
      fixture.state = fixture.state.copyWith(
        bag: Bag(
          entries: [
            ...fixture.state.bag.entries,
            const BagEntry(itemId: 'ball', quantity: 1),
          ],
        ),
      );
      fixture.now = DateTime(2026, 10, 31);
      final original = fixture.state;
      final opening = fixture.open();
      await fixture.untilActive();
      expect(
        (await fixture.send(RuntimeWorldServiceAction.confirm)).status,
        RuntimeWorldServiceCommandStatus.unavailable,
      );
      expect(fixture.state, same(original));
      expect(fixture.writes, 0);
      expect(
        fixture.controller.worldServiceSnapshot!.content,
        isA<RuntimeCraftingServiceContent>().having(
          (content) => content.status,
          'status',
          RuntimeCraftingStatus.ready,
        ),
      );
      await fixture.send(RuntimeWorldServiceAction.cancel);
      await opening;
    },
  );
  test('dispose while persistence is pending waits and cannot accept a second deposit', () async {
    final fixture = _Fixture();
    final gate = Completer<void>();
    fixture.saveGate = gate.future;
    final opening = fixture.open();
    await fixture.untilActive();
    await fixture.send(RuntimeWorldServiceAction.select, target: 'fruit-ball');
    await fixture.send(RuntimeWorldServiceAction.confirm);
    final applying = fixture.send(RuntimeWorldServiceAction.confirm);
    await Future<void>.delayed(Duration.zero);
    expect(
      fixture.controller.worldServiceSnapshot!.stage,
      RuntimeWorldServiceStage.applying,
    );
    expect(
      (await fixture.send(RuntimeWorldServiceAction.confirm)).status,
      RuntimeWorldServiceCommandStatus.unavailable,
    );
    var disposed = false;
    final disposing = fixture.controller.dispose().then((_) => disposed = true);
    await Future<void>.delayed(Duration.zero);
    expect(disposed, isFalse);
    gate.complete();
    await applying;
    await disposing;
    expect((await opening).status, PlayerServiceRuntimeStatus.completed);
    expect(fixture.writes, 1);
    expect(fixture.owned('fruit'), 8);
    expect(fixture.locks, [true, false]);
  });
}

class _Fixture {
  _Fixture({this.capacity = const ProjectBagCapacity.unlimited()});
  final ProjectBagCapacity capacity;
  GameState state = GameState(
    saveId: 'craft',
    bag: Bag(entries: [BagEntry(itemId: 'fruit', quantity: 10)]),
  );
  DateTime now = DateTime(2026, 10, 30, 23, 59);
  int writes = 0;
  bool failSave = false;
  Future<void>? saveGate;
  final locks = <bool>[];
  late final controller = PlayerServiceRuntimeController.contextual(
    currentGameState: () => state,
    commitAndSave: (_) async =>
        throw StateError('Crafting must use its durable transaction'),
    commitCraftingAndSave: (next) async {
      await saveGate;
      if (failSave) throw StateError('disk full');
      state = next;
      writes++;
    },
    setInputLocked: locks.add,
    loadRecoveryCaps: (_) async =>
        const RuntimePlayerServiceRecoveryCaps(maxHpByPartyIndex: {}),
    itemCatalog: catalog,
    bagCapacity: capacity,
    civilNow: () => now,
  );
  Future<PlayerServiceRuntimeResult> open() => controller.openCrafting(
    request: OpenCraftingService(
      interactionId: 'craft',
      definition: definition,
    ),
  );
  int owned(String item) => const BagOperations().quantityOf(state.bag, item);
  Future<void> untilActive() async {
    for (var i = 0; i < 20 && controller.worldServiceSnapshot == null; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(controller.worldServiceSnapshot, isNotNull);
  }

  Future<RuntimeWorldServiceCommandResult> send(
    RuntimeWorldServiceAction action, {
    String? target,
  }) => controller.dispatchWorldService(
    RuntimeWorldServiceCommand(
      action: action,
      snapshotRevision: controller.worldServiceSnapshot!.revision,
      targetId: target,
    ),
  );
}
