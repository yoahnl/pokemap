import 'package:map_battle/map_battle.dart';
import 'package:map_battle/src/domain/action/battle_item_action_handler.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK battle PP item actions', () {
    test('restores only the selected slot and its persistent PP', () {
      final context = _context();
      final result = const BattleItemActionHandler().useItem(
        context: context,
        action: _action(
          const PsdkBattlePpRestoreItemEffect.flat(10, moveSlot: 1),
        ),
      );
      final target = result.state.battlerAt(psdkPlayerSlot);

      expect(result.applied, isTrue);
      expect(result.amount, 10);
      expect(target.moves.map((move) => move.currentPp), <int>[3, 17]);
      expect(target.writeBackMoves.map((move) => move.currentPp), <int>[3, 17]);
      expect(target.currentHp, 80);
      expect(result.rng, same(context.rng));
      expect(
        context.state.battlerAt(psdkPlayerSlot).moves[1].currentPp,
        7,
      );
    });

    for (final entry in <(int, PsdkBattleItemActionEffect, int)>[
      (0, const PsdkBattlePpRestoreItemEffect.flat(10, moveSlot: 0), 10),
      (17, const PsdkBattlePpRestoreItemEffect.flat(10, moveSlot: 0), 20),
      (0, const PsdkBattlePpRestoreItemEffect.full(moveSlot: 0), 20),
    ]) {
      test('restores ${entry.$1} PP to ${entry.$3} with ${entry.$2}', () {
        final context = _context(
          player: _combatant(id: 'player', moves: [_move(pp: entry.$1)]),
        );
        final result = const BattleItemActionHandler().useItem(
          context: context,
          action: _action(entry.$2),
        );

        expect(result.applied, isTrue);
        expect(result.amount, entry.$3 - entry.$1);
        expect(result.state.battlerAt(psdkPlayerSlot).moves.single.currentPp,
            entry.$3);
        expect(result.rng, same(context.rng));
      });
    }

    test('emits exact restoration details and one consumption', () {
      final result = const BattleItemActionHandler().useItem(
        context: _context(),
        action: _action(
          const PsdkBattlePpRestoreItemEffect.flat(50, moveSlot: 1),
        ),
      );

      expect(result.events.map((event) => event.kind),
          ['item_consumed', 'move_pp_restored']);
      expect(result.events.last.toJson(), <String, Object?>{
        'kind': 'move_pp_restored',
        'turn': 1,
        'user': psdkPlayerSlot.toJson(),
        'target': psdkPlayerSlot.toJson(),
        'partyIndex': 0,
        'itemId': 'ether',
        'moveSlot': 1,
        'moveId': 'splash',
        'beforePp': 7,
        'remainingPp': 20,
        'amount': 13,
      });
      final cleanEvent = BattleTimelineEvent.fromPsdk(result.events.last);
      expect(cleanEvent, isA<BattleMovePpRestoredTimelineEvent>());
      expect(cleanEvent.toJson(), result.events.last.toJson());
      expect(cleanEvent.toPsdkEvent()!.toJson(), result.events.last.toJson());
    });

    for (final hp in [80, 0]) {
      test('restores an explicit reserve with $hp HP without reviving', () {
        final context = _context(
          reserves: [_combatant(id: 'reserve', currentHp: hp)],
        );
        final result = const BattleItemActionHandler().useItem(
          context: context,
          action: _action(
            const PsdkBattlePpRestoreItemEffect.full(moveSlot: 1),
            partyIndex: 1,
          ),
        );
        final reserve = result.state.partyForBank(psdkPlayerSlot.bank)[1];

        expect(result.applied, isTrue);
        expect(reserve.moves.map((move) => move.currentPp), [3, 20]);
        expect(reserve.writeBackMoves.map((move) => move.currentPp), [3, 20]);
        expect(reserve.currentHp, hp);
        expect(reserve.isFainted, hp == 0);
        expect(
            result.state
                .battlerAt(psdkPlayerSlot)
                .moves
                .map((m) => m.currentPp),
            [3, 7]);
        expect(result.events.last.toJson()['partyIndex'], 1);
        expect(result.rng, same(context.rng));
      });
    }

    test('restores a fainted active target without HP or status changes', () {
      final context = _context(
        player: _combatant(
          id: 'player',
          currentHp: 0,
          status: PsdkBattleMajorStatus.poison,
        ),
      );
      final result = const BattleItemActionHandler().useItem(
        context: context,
        action: _action(
          const PsdkBattlePpRestoreItemEffect.full(moveSlot: 0),
        ),
      );
      final target = result.state.battlerAt(psdkPlayerSlot);

      expect(target.moves.first.currentPp, 20);
      expect(target.currentHp, 0);
      expect(target.isFainted, isTrue);
      expect(target.majorStatus, PsdkBattleMajorStatus.poison);
    });

    for (final slot in [-1, 2]) {
      test('rejects invalid move slot $slot without state, RNG or events', () {
        final context = _context();
        final result = const BattleItemActionHandler().useItem(
          context: context,
          action: _action(PsdkBattlePpRestoreItemEffect.full(moveSlot: slot)),
        );

        expect(result.applied, isFalse);
        expect(result.reason, 'invalid_move_slot');
        expect(result.state, same(context.state));
        expect(result.rng, same(context.rng));
        expect(result.events, isEmpty);
      });
    }

    test('rejects a full slot even when another slot has missing PP', () {
      final context = _context(
        player: _combatant(id: 'player', moves: [_move(pp: 20), _move()]),
      );
      final result = const BattleItemActionHandler().useItem(
        context: context,
        action: _action(
          const PsdkBattlePpRestoreItemEffect.flat(10, moveSlot: 0),
        ),
      );

      expect(result.applied, isFalse);
      expect(result.reason, 'pp_full');
      expect(result.state, same(context.state));
      expect(result.rng, same(context.rng));
      expect(result.events, isEmpty);
    });

    test('reusable PP items emit usage and restoration without consumption',
        () {
      final result = const BattleItemActionHandler().useItem(
        context: _context(),
        action: _action(
          const PsdkBattlePpRestoreItemEffect.flat(10, moveSlot: 0),
          consumeItem: false,
        ),
      );

      expect(result.events.map((event) => event.kind),
          ['item_used', 'move_pp_restored']);
    });

    for (final amount in [0, -1]) {
      test('rejects flat amount $amount without state, RNG or consumption', () {
        final context = _context();
        final result = const BattleItemActionHandler().useItem(
          context: context,
          action: _action(
            PsdkBattlePpRestoreItemEffect.flat(amount, moveSlot: 0),
          ),
        );

        expect(result.applied, isFalse);
        expect(result.reason, 'invalid_pp_amount');
        expect(result.amount, 0);
        expect(result.state, same(context.state));
        expect(result.rng, same(context.rng));
        expect(result.events, isEmpty);
      });

      test('session rejects flat amount $amount without a turn or consumption',
          () {
        final session = BattleSessionFacade.fromSetup(setup: _setup());
        final before = session.state;

        expect(
          () => session.submit(
            BattleDecision.item(
              itemId: 'ether',
              target: psdkPlayerSlot,
              effect: PsdkBattlePpRestoreItemEffect.flat(amount, moveSlot: 0),
              highPriority: true,
            ),
          ),
          throwsA(isA<BattleDecisionRejectedError>()),
        );

        expect(session.state.turnNumber, 0);
        expect(session.state.psdkState, same(before.psdkState));
        expect(
            _seedValues(session.state.rngSeeds), _seedValues(before.rngSeeds));
      });
    }

    test(
        'preserves the original Mimic slot when a copied move duplicates an ID',
        () {
      final initial = _context(
        player: _combatant(
          id: 'player',
          moves: [_move(id: 'mimic', pp: 7), _move(pp: 3)],
        ),
      );
      final copied = initial.state.battlerAt(psdkPlayerSlot).replaceMoveAt(
            0,
            _move(pp: 1),
          );
      final context = BattleHandlerContext(
        state: initial.state.replacePartyBattler(
          bank: 0,
          partyIndex: 0,
          battler: copied,
        ),
        rng: initial.rng,
        turn: 1,
        user: psdkPlayerSlot,
      );
      final result = const BattleItemActionHandler().useItem(
        context: context,
        action: _action(
          const PsdkBattlePpRestoreItemEffect.flat(10, moveSlot: 0),
        ),
      );
      final target = result.state.battlerAt(psdkPlayerSlot);

      expect(target.moves.map((move) => move.id), ['splash', 'splash']);
      expect(target.moves.map((move) => move.currentPp), [11, 3]);
      expect(target.writeBackMoves.map((move) => move.id), ['mimic', 'splash']);
      expect(target.writeBackMoves.map((move) => move.currentPp), [7, 3]);
    });

    test('session restores PP before the opposing attack and consumes once',
        () {
      final session = BattleSessionFacade.fromSetup(setup: _setup());
      final result = session.submit(
        const BattleDecision.item(
          itemId: 'ether',
          target: psdkPlayerSlot,
          effect: PsdkBattlePpRestoreItemEffect.flat(10, moveSlot: 1),
          highPriority: true,
        ),
      );

      expect(result.state.turnNumber, 1);
      expect(
          result.state.battlerAt(psdkPlayerSlot).moves.map((m) => m.currentPp),
          [3, 17]);
      expect(result.timeline.events.whereType<BattleItemTimelineEvent>(),
          hasLength(1));
      final restorationIndex = result.timeline.events
          .indexWhere((event) => event.kind == 'move_pp_restored');
      final opposingMoveIndex = result.timeline.events
          .indexWhere((event) => event is BattleMovePpSpentTimelineEvent);
      expect(restorationIndex, greaterThanOrEqualTo(0));
      expect(restorationIndex, lessThan(opposingMoveIndex));
      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 80);
    });

    test('session targets a fainted reserve and keeps the active PP unchanged',
        () {
      final session = BattleSessionFacade.fromSetup(
        setup: _setup(reserves: [_combatant(id: 'reserve', currentHp: 0)]),
      );
      final result = session.submit(
        const BattleDecision.item(
          itemId: 'max_ether',
          target: psdkPlayerSlot,
          targetPartyIndex: 1,
          effect: PsdkBattlePpRestoreItemEffect.full(moveSlot: 1),
        ),
      );
      final reserve = result.state.psdkState.partyForBank(0)[1];

      expect(reserve.moves.map((move) => move.currentPp), [3, 20]);
      expect(reserve.currentHp, 0);
      expect(
          result.state.battlerAt(psdkPlayerSlot).moves.map((m) => m.currentPp),
          [3, 7]);
      expect(
          result.timeline.events
              .whereType<BattleItemTimelineEvent>()
              .single
              .partyIndex,
          1);
    });

    test('session restoration after Transform never alters original move PP',
        () {
      final session = BattleSessionFacade.fromSetup(
        setup: _setup(
          player: _combatant(
            id: 'player',
            moves: [_move(id: 'transform', pp: 20, method: 's_transform')],
          ),
        ),
      );
      session.submit(const BattleDecision.fight(moveSlot: 0));
      session.submit(const BattleDecision.fight(moveSlot: 0));
      final before = session.state.battlerAt(psdkPlayerSlot);
      expect(before.transformState.isTransformed, isTrue);
      expect(before.moves.first.currentPp, 4);
      final result = session.submit(
        const BattleDecision.item(
          itemId: 'max_ether',
          target: psdkPlayerSlot,
          effect: PsdkBattlePpRestoreItemEffect.full(moveSlot: 0),
        ),
      );
      final target = result.state.battlerAt(psdkPlayerSlot);

      expect(target.moves.first.currentPp, 5);
      expect(target.writeBackMoves.single.id, 'transform');
      expect(target.writeBackMoves.single.currentPp, 19);
      expect(target.moves[1].currentPp, before.moves[1].currentPp);
    });

    for (final slot in [-1, 2]) {
      test('session rejects slot $slot without advancing the turn or RNG', () {
        final session = BattleSessionFacade.fromSetup(setup: _setup());
        final before = session.state;

        expect(
          () => session.submit(
            BattleDecision.item(
              itemId: 'max_ether',
              target: psdkPlayerSlot,
              effect: PsdkBattlePpRestoreItemEffect.full(moveSlot: slot),
              highPriority: true,
            ),
          ),
          throwsA(isA<BattleDecisionRejectedError>()),
        );

        expect(session.state.turnNumber, 0);
        expect(session.state.psdkState, same(before.psdkState));
        expect(
            _seedValues(session.state.rngSeeds), _seedValues(before.rngSeeds));
      });
    }

    test('session rejects a full slot without advancing the turn or RNG', () {
      final session = BattleSessionFacade.fromSetup(
        setup: _setup(
          player: _combatant(id: 'player', moves: [_move(pp: 20), _move()]),
        ),
      );
      final before = session.state;

      expect(
        () => session.submit(
          const BattleDecision.item(
            itemId: 'ether',
            target: psdkPlayerSlot,
            effect: PsdkBattlePpRestoreItemEffect.flat(10, moveSlot: 0),
            highPriority: true,
          ),
        ),
        throwsA(isA<BattleDecisionRejectedError>()),
      );

      expect(session.state.turnNumber, 0);
      expect(session.state.psdkState, same(before.psdkState));
      expect(_seedValues(session.state.rngSeeds), _seedValues(before.rngSeeds));
    });

    test('session rejects an opposing target before restoration', () {
      final session = BattleSessionFacade.fromSetup(setup: _setup());
      final before = session.state;

      expect(
        () => session.submit(
          const BattleDecision.item(
            itemId: 'ether',
            target: psdkOpponentSlot,
            effect: PsdkBattlePpRestoreItemEffect.flat(10, moveSlot: 0),
            highPriority: true,
          ),
        ),
        throwsA(isA<BattleDecisionRejectedError>()),
      );

      expect(session.state.turnNumber, 0);
      expect(session.state.psdkState, same(before.psdkState));
      expect(_seedValues(session.state.rngSeeds), _seedValues(before.rngSeeds));
    });

    test('session rejects a missing party target before restoration', () {
      final session = BattleSessionFacade.fromSetup(setup: _setup());
      final before = session.state;

      expect(
        () => session.submit(
          const BattleDecision.item(
            itemId: 'ether',
            target: psdkPlayerSlot,
            targetPartyIndex: 1,
            effect: PsdkBattlePpRestoreItemEffect.flat(10, moveSlot: 0),
            highPriority: true,
          ),
        ),
        throwsA(isA<BattleDecisionRejectedError>()),
      );

      expect(session.state.turnNumber, 0);
      expect(session.state.psdkState, same(before.psdkState));
      expect(_seedValues(session.state.rngSeeds), _seedValues(before.rngSeeds));
    });
  });
}

List<int> _seedValues(BattleRngSeeds seeds) => [
      seeds.moveDamage,
      seeds.moveCritical,
      seeds.moveAccuracy,
      seeds.generic,
    ];

PsdkBattleItemAction _action(
  PsdkBattleItemActionEffect effect, {
  int? partyIndex,
  bool consumeItem = true,
}) {
  return PsdkBattleItemAction(
    user: psdkPlayerSlot,
    target: psdkPlayerSlot,
    targetPartyIndex: partyIndex,
    itemId: 'ether',
    effect: effect,
    consumeItem: consumeItem,
  );
}

BattleHandlerContext _context({
  PsdkBattleCombatantSetup? player,
  List<PsdkBattleCombatantSetup> reserves = const [],
}) {
  final setup = _setup(player: player, reserves: reserves);
  return BattleHandlerContext(
    state: PsdkBattleState.fromSetup(setup.psdkSetup),
    rng: BattleRngStreams.fromPsdkSeeds(setup.psdkSetup.rngSeeds),
    turn: 1,
    user: psdkPlayerSlot,
  );
}

BattleEngineSetup _setup({
  PsdkBattleCombatantSetup? player,
  List<PsdkBattleCombatantSetup> reserves = const [],
}) {
  return BattleEngineSetup.singlesPokeMapBetaV1ForTest(
    player: player ?? _combatant(id: 'player'),
    playerReserves: reserves,
    opponent: _combatant(id: 'opponent'),
    rngSeeds: const PsdkBattleRngSeeds(
      moveDamage: 1,
      moveCritical: 99999,
      moveAccuracy: 3,
      generic: 4,
    ),
  );
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  int currentHp = 80,
  PsdkBattleMajorStatus? status,
  List<PsdkBattleMoveData>? moves,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 20,
    maxHp: 80,
    currentHp: currentHp,
    majorStatus: status,
    types: const PsdkBattleTypes(primary: 'normal'),
    stats: const PsdkBattleStats(
      attack: 50,
      defense: 50,
      specialAttack: 50,
      specialDefense: 50,
      speed: 50,
    ),
    moves: moves ?? <PsdkBattleMoveData>[_move(pp: 3), _move(pp: 7)],
  );
}

PsdkBattleMoveData _move({
  String id = 'splash',
  int pp = 0,
  int maxPp = 20,
  String method = 's_splash',
}) {
  return PsdkBattleMoveData(
    id: id,
    dbSymbol: id,
    name: 'Splash',
    type: 'normal',
    category: PsdkBattleMoveCategory.status,
    power: 0,
    accuracy: 100,
    pp: maxPp,
    currentPp: pp,
    priority: 0,
    battleEngineMethod: method,
    target: method == 's_transform'
        ? PsdkBattleMoveTarget.adjacentFoe
        : PsdkBattleMoveTarget.none,
  );
}
