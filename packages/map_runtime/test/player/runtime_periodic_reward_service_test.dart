import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';

final reward = PeriodicItemRewardDefinition(
  rewardId: 'tree',
  label: 'Fruit',
  itemId: 'fruit',
  quantity: 2,
);
final catalog = ItemCatalogSnapshot.fromCatalog(
  const ProjectItemCatalog(
    schemaVersion: 1,
    entries: [
      ProjectItemDefinition(
        id: 'fruit',
        displayName: 'Fruit',
        pocketId: 'items',
      ),
    ],
  ),
);

void main() {
  test('command strict roundtrip and four immediate outcomes', () {
    final command = SceneInteractiveCommand.claimPeriodicReward(
      definition: reward,
    );
    expect(SceneInteractiveCommand.fromJson(command.toJson()), command);
    expect(command.outputPortIds, [
      'received',
      'alreadyClaimed',
      'bagFull',
      'blocked',
    ]);
    expect(
      () => SceneInteractiveCommand.fromJson({
        ...command.toJson(),
        'extra': true,
      }),
      throwsFormatException,
    );
    expect(
      () => SceneInteractiveCommand.fromJson({
        'kind': 'claimPeriodicReward',
        'definition': {},
      }),
      throwsFormatException,
    );
  });
  test('executor dispatches immediate result without opening an overlay and fails closed without writer', () async {
    final command = SceneInteractiveCommand.claimPeriodicReward(
      definition: reward,
    );
    final intent = SceneRuntimePlanIntent.executeInteractiveCommand(
      command: command,
    );
    Future<String> unexpected(_) async =>
        throw StateError('Unexpected overlay or warp');
    final missing = SceneInteractiveCommandRuntimeExecutor(
      warp: unexpected,
      openWorldService: unexpected,
    );
    expect(await missing.execute(intent), 'blocked');
    for (final port in command.outputPortIds) {
      final executor = SceneInteractiveCommandRuntimeExecutor(
        warp: unexpected,
        openWorldService: unexpected,
        claimPeriodicReward: (_) async => port,
      );
      expect(await executor.execute(intent), port);
    }
    final invalid = SceneInteractiveCommandRuntimeExecutor(
      warp: unexpected,
      claimPeriodicReward: (_) async => 'completed',
    );
    await expectLater(invalid.execute(intent), throwsStateError);
  });
  test(
    'dispose waits for a rejected write and does not consume claim',
    () async {
      final fixture = _Fixture()..fail = true;
      final gate = Completer<void>();
      fixture.gate = gate.future;
      final claiming = fixture.claim();
      await Future<void>.delayed(Duration.zero);
      final disposal = fixture.controller.dispose();
      gate.complete();
      expect(await claiming, 'blocked');
      await disposal;
      expect(fixture.writes, 0);
      expect(fixture.state.periodicRewardState.claimsById, isEmpty);
      expect(fixture.locks, [true, false]);
    },
  );
  test('without dedicated durable writer refuses without mutations', () async {
    final fixture = _Fixture(durable: false);
    addTearDown(fixture.controller.dispose);
    expect(await fixture.claim(), 'blocked');
    expect(fixture.writes, 0);
    expect(fixture.locks, isEmpty);
  });
  test(
    'ack waits for persistence, rejects duplicate and disposal waits',
    () async {
      final fixture = _Fixture();
      final gate = Completer<void>();
      fixture.gate = gate.future;
      var completed = false;
      final claim = fixture.claim().then((value) {
        completed = true;
        return value;
      });
      await Future<void>.delayed(Duration.zero);
      expect(completed, isFalse);
      expect(await fixture.claim(), 'blocked');
      var disposed = false;
      final disposal = fixture.controller.dispose().then(
        (_) => disposed = true,
      );
      await Future<void>.delayed(Duration.zero);
      expect(disposed, isFalse);
      gate.complete();
      expect(await claim, 'received');
      await disposal;
      expect(fixture.writes, 1);
      expect(fixture.owned, 2);
      expect(await fixture.claim(), 'blocked');
      expect(fixture.locks, [true, false]);
    },
  );
  test(
    'failed persistence preserves state and retry grants exactly once',
    () async {
      final fixture = _Fixture()..fail = true;
      addTearDown(fixture.controller.dispose);
      final before = fixture.state;
      expect(await fixture.claim(), 'blocked');
      expect(fixture.state, same(before));
      fixture.fail = false;
      expect(await fixture.claim(), 'received');
      expect(await fixture.claim(), 'alreadyClaimed');
      fixture.state = gameStateFromStrictSaveJson(
        strictGameStateSaveJson(fixture.state),
      );
      expect(await fixture.claim(), 'alreadyClaimed');
      fixture.now = DateTime(2026, 10, 31, 0, 1);
      expect(await fixture.claim(), 'received');
      fixture.now = DateTime(2026, 10, 30);
      expect(await fixture.claim(), 'alreadyClaimed');
      expect(fixture.owned, 4);
      expect(fixture.writes, 2);
    },
  );
  test('full bag does not consume eligibility or observed calendar', () async {
    final fixture = _Fixture(
      capacity: const ProjectBagCapacity(
        pockets: {
          'items': BagPocketCapacity(
            maxDistinctItems: 1,
            maxQuantityPerItem: 1,
          ),
        },
      ),
    );
    addTearDown(fixture.controller.dispose);
    final before = fixture.state;
    expect(await fixture.claim(), 'bagFull');
    expect(fixture.state, same(before));
    expect(fixture.writes, 0);
  });
  test('disposed controller prevents write and returns blocked', () async {
    final fixture = _Fixture();
    await fixture.controller.dispose();
    expect(await fixture.claim(), 'blocked');
    expect(fixture.writes, 0);
  });
}

class _Fixture {
  _Fixture({
    this.durable = true,
    this.capacity = const ProjectBagCapacity.unlimited(),
  });
  final bool durable;
  final ProjectBagCapacity capacity;
  GameState state = const GameState(saveId: 'reward');
  DateTime now = DateTime(2026, 10, 30, 23, 59);
  bool fail = false;
  int writes = 0;
  Future<void>? gate;
  final locks = <bool>[];
  late final controller = PlayerServiceRuntimeController.contextual(
    currentGameState: () => state,
    commitAndSave: (_) async => throw StateError('Wrong writer'),
    commitPeriodicRewardAndSave: durable
        ? (next) async {
            await gate;
            if (fail) throw StateError('disk full');
            state = next;
            writes++;
          }
        : null,
    setInputLocked: locks.add,
    loadRecoveryCaps: (_) async =>
        const RuntimePlayerServiceRecoveryCaps(maxHpByPartyIndex: {}),
    itemCatalog: catalog,
    bagCapacity: capacity,
    civilNow: () => now,
  );
  Future<String> claim() => controller.claimPeriodicReward(definition: reward);
  int get owned => const BagOperations().quantityOf(state.bag, 'fruit');
}
