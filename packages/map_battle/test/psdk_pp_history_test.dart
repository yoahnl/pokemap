import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK clean PP and move history', () {
    test('a successful move spends PP and records successful history', () {
      final engine = BattleEngine(
        setup: _setup(
          playerMove: _move(id: 'ember', type: 'fire', pp: 1),
        ),
      );

      final result = engine.submit(const BattleDecision.fight(moveSlot: 0));
      final player = result.state.battlerAt(psdkPlayerSlot);

      expect(player.moves.single.currentPp, 0);
      expect(player.moveHistory.lastMoveId, 'ember');
      expect(player.moveHistory.lastSuccessfulMoveId, 'ember');
      expect(engine.currentRequest.kind,
          BattleEngineDecisionRequestKind.noLegalChoice);
      expect(
        result.timeline.events.map((event) => event.kind),
        containsAllInOrder(<String>[
          'move_pp_spent',
          'move_declared',
          'animation_cue',
          'damage',
        ]),
      );
    });

    test('a missed move spends PP and records only attempted history', () {
      const seeds = BattleRngSeeds(
        moveDamage: 1,
        moveCritical: 99999,
        moveAccuracy: 99,
        generic: 4,
      );
      final engine = BattleEngine(
        setup: _setup(
          playerMove: _move(
            id: 'sand_attack',
            type: 'ground',
            pp: 2,
            accuracy: 1,
          ),
          rngSeeds: seeds.psdkSeeds,
        ),
      );

      final result = engine.submit(const BattleDecision.fight(moveSlot: 0));
      final player = result.state.battlerAt(psdkPlayerSlot);

      expect(player.moves.single.currentPp, 1);
      expect(player.moveHistory.lastMoveId, 'sand_attack');
      expect(player.moveHistory.lastSuccessfulMoveId, isNull);
      expect(result.state.rngSeeds.moveAccuracy, isNot(seeds.moveAccuracy));
      expect(
        result.timeline.events.map((event) => event.kind),
        containsAllInOrder(<String>[
          'move_pp_spent',
          'move_declared',
          'miss',
        ]),
      );
      expect(
        result.timeline.events.map((event) => event.kind),
        isNot(contains('damage')),
      );
    });

    test('a zero PP move fails before declaration and keeps RNG untouched', () {
      const seeds = BattleRngSeeds(
        moveDamage: 1,
        moveCritical: 99999,
        moveAccuracy: 3,
        generic: 4,
      );
      final engine = BattleEngine(
        setup: _setup(
          playerMove: _move(
            id: 'empty_ember',
            type: 'fire',
            pp: 1,
            currentPp: 0,
          ),
          rngSeeds: seeds.psdkSeeds,
        ),
      );

      final result = engine.submit(const BattleDecision.fight(moveSlot: 0));
      final player = result.state.battlerAt(psdkPlayerSlot);
      final playerEvents = result.timeline.events
          .where((event) => event.toJson()['moveId'] == 'empty_ember')
          .toList(growable: false);

      expect(player.moves.single.currentPp, 0);
      expect(player.moveHistory.lastMoveId, 'empty_ember');
      expect(player.moveHistory.lastSuccessfulMoveId, isNull);
      expect(result.state.rngSeeds.moveAccuracy, seeds.moveAccuracy);
      expect(
        playerEvents.map((event) => event.kind),
        <String>['move_failed'],
      );
      expect(playerEvents.single.toJson()['reason'], 'pp');
    });
  });
}

BattleEngineSetup _setup({
  required PsdkBattleMoveData playerMove,
  PsdkBattleRngSeeds rngSeeds = const PsdkBattleRngSeeds(
    moveDamage: 1,
    moveCritical: 99999,
    moveAccuracy: 3,
    generic: 4,
  ),
}) {
  return BattleEngineSetup.singles(
    player: _combatant(
      id: 'player',
      speed: 100,
      types: const PsdkBattleTypes(primary: 'fire'),
      moves: <PsdkBattleMoveData>[playerMove],
    ),
    opponent: _combatant(
      id: 'opponent',
      speed: 1,
      types: const PsdkBattleTypes(primary: 'grass'),
      moves: <PsdkBattleMoveData>[
        _move(
          id: 'opponent_wait',
          type: 'normal',
          power: 0,
          accuracy: 0,
        ),
      ],
    ),
    rngSeeds: rngSeeds,
  );
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  required int speed,
  required PsdkBattleTypes types,
  required List<PsdkBattleMoveData> moves,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 20,
    maxHp: 100,
    currentHp: 100,
    types: types,
    stats: PsdkBattleStats(
      attack: 50,
      defense: 50,
      specialAttack: 50,
      specialDefense: 50,
      speed: speed,
    ),
    moves: moves,
  );
}

PsdkBattleMoveData _move({
  required String id,
  required String type,
  int power = 40,
  int accuracy = 100,
  int pp = 35,
  int? currentPp,
}) {
  return PsdkBattleMoveData(
    id: id,
    dbSymbol: id,
    name: id,
    type: type,
    category: power == 0
        ? PsdkBattleMoveCategory.status
        : PsdkBattleMoveCategory.special,
    power: power,
    accuracy: accuracy,
    pp: pp,
    currentPp: currentPp,
    priority: 0,
    battleEngineMethod: power == 0 ? 's_status' : 's_basic',
    target: PsdkBattleMoveTarget.adjacentFoe,
  );
}
