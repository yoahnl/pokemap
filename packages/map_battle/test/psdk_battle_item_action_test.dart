import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK battle item actions', () {
    test('high priority HP item heals before the opposing regular move', () {
      final engine = BattleEngine(
        setup: _setup(
          player: _combatant(
            id: 'player-eevee',
            speciesId: 'eevee',
            hp: 100,
            currentHp: 30,
          ),
          opponentMoves: <PsdkBattleMoveData>[_move(id: 'wait', power: 0)],
        ),
      );

      final result = engine.submit(
        const BattleDecision.item(
          itemId: 'potion',
          target: psdkPlayerSlot,
          effect: PsdkBattleHpHealItemEffect.flat(20),
          highPriority: true,
        ),
      );

      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 50);
      expect(
        result.timeline.events.whereType<BattleHealTimelineEvent>().single,
        isA<BattleHealTimelineEvent>()
            .having((event) => event.moveId, 'moveId', 'item:potion')
            .having((event) => event.amount, 'amount', 20),
      );
      expect(
        result.timeline.events.whereType<BattleItemTimelineEvent>().single,
        isA<BattleItemTimelineEvent>()
            .having((event) => event.kind, 'kind', 'item_consumed')
            .having((event) => event.itemId, 'itemId', 'potion')
            .having(
              (event) => event.target,
              'target',
              const BattlePositionRef(bank: 0, position: 0),
            ),
      );

      final itemIndex = result.timeline.events.indexWhere(
        (event) => event is BattleItemTimelineEvent,
      );
      final moveIndex = result.timeline.events.indexWhere(
        (event) => event is BattleMovePpSpentTimelineEvent,
      );
      expect(itemIndex, lessThan(moveIndex));
    });

    test('status cure item clears a matching major status', () {
      final engine = BattleEngine(
        setup: _setup(
          player: _combatant(
            id: 'player-eevee',
            speciesId: 'eevee',
            hp: 100,
            majorStatus: PsdkBattleMajorStatus.burn,
          ),
          opponentMoves: <PsdkBattleMoveData>[_move(id: 'wait', power: 0)],
        ),
      );

      final result = engine.submit(
        const BattleDecision.item(
          itemId: 'burn_heal',
          target: psdkPlayerSlot,
          effect: PsdkBattleStatusCureItemEffect.only(
            <PsdkBattleMajorStatus>{PsdkBattleMajorStatus.burn},
          ),
          highPriority: true,
        ),
      );

      expect(result.state.battlerAt(psdkPlayerSlot).majorStatus, isNull);
      expect(
        result.timeline.events
            .whereType<BattleStatusCureTimelineEvent>()
            .single,
        isA<BattleStatusCureTimelineEvent>()
            .having((event) => event.moveId, 'moveId', 'item:burn_heal')
            .having(
                (event) => event.status, 'status', PsdkBattleMajorStatus.burn),
      );
      expect(
        result.timeline.events
            .whereType<BattleItemTimelineEvent>()
            .map((event) => event.itemId),
        contains('burn_heal'),
      );
    });

    test('illegal item target fails without mutating the turn', () {
      final engine = BattleEngine(
        setup: _setup(
          player: _combatant(
            id: 'player-eevee',
            speciesId: 'eevee',
            hp: 100,
            currentHp: 30,
          ),
        ),
      );

      expect(
        () => engine.submit(
          const BattleDecision.item(
            itemId: 'potion',
            target: psdkOpponentSlot,
            effect: PsdkBattleHpHealItemEffect.flat(20),
            highPriority: true,
          ),
        ),
        throwsArgumentError,
      );
      expect(engine.snapshot().turnNumber, 0);
      expect(engine.snapshot().battlerAt(psdkPlayerSlot).currentHp, 30);
    });
  });
}

BattleEngineSetup _setup({
  required PsdkBattleCombatantSetup player,
  PsdkBattleCombatantSetup? opponent,
  List<PsdkBattleMoveData>? opponentMoves,
}) {
  return BattleEngineSetup.singles(
    player: player,
    opponent: opponent ??
        _combatant(
          id: 'opponent-rattata',
          speciesId: 'rattata',
          hp: 70,
          moves: opponentMoves,
        ),
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
  required String speciesId,
  required int hp,
  int? currentHp,
  PsdkBattleMajorStatus? majorStatus,
  List<PsdkBattleMoveData>? moves,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: speciesId,
    displayName: speciesId,
    level: 20,
    maxHp: hp,
    currentHp: currentHp ?? hp,
    types: const PsdkBattleTypes(primary: 'normal'),
    stats: const PsdkBattleStats(
      attack: 50,
      defense: 50,
      specialAttack: 50,
      specialDefense: 50,
      speed: 50,
    ),
    majorStatus: majorStatus,
    moves: moves ?? <PsdkBattleMoveData>[_move(id: 'tackle', power: 40)],
  );
}

PsdkBattleMoveData _move({
  required String id,
  required int power,
}) {
  return PsdkBattleMoveData(
    id: id,
    dbSymbol: id,
    name: id,
    type: 'normal',
    category: PsdkBattleMoveCategory.physical,
    power: power,
    accuracy: 100,
    pp: 35,
    priority: 0,
    battleEngineMethod: 's_basic',
    target: PsdkBattleMoveTarget.adjacentFoe,
  );
}
