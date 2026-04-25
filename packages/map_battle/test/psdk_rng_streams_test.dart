import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

const _initialSeeds = BattleRngSeeds(
  moveDamage: 1,
  moveCritical: 2,
  moveAccuracy: 99,
  generic: 99,
);

void main() {
  group('PSDK clean RNG streams', () {
    test('advance one stream without moving the other streams', () {
      final streams = BattleRngStreams.fromSeedSnapshot(_initialSeeds);

      final accuracyRoll = streams.moveAccuracy.nextPercent();
      final afterAccuracy = streams.copyWith(moveAccuracy: accuracyRoll.next);

      expect(accuracyRoll.value, 100);
      expect(
          afterAccuracy.seeds.moveAccuracy, isNot(_initialSeeds.moveAccuracy));
      expect(afterAccuracy.seeds.moveDamage, _initialSeeds.moveDamage);
      expect(afterAccuracy.seeds.moveCritical, _initialSeeds.moveCritical);
      expect(afterAccuracy.seeds.generic, _initialSeeds.generic);
    });

    test('reject invalid chance contracts explicitly', () {
      const stream = BattleRngStream(seed: 1);

      expect(
        () => stream.nextChance(numerator: -1, denominator: 100),
        throwsRangeError,
      );
      expect(
        () => stream.nextChance(numerator: 101, denominator: 100),
        throwsRangeError,
      );
      expect(
        () => stream.nextChance(numerator: 1, denominator: 0),
        throwsRangeError,
      );
    });

    test('engine miss consumes accuracy but not damage or generic streams', () {
      final engine = BattleEngine(
        setup: _setup(
          playerMoves: <PsdkBattleMoveData>[
            _statusMove(accuracy: 1, chance: 100),
          ],
          opponentMoves: <PsdkBattleMoveData>[_damagingMove(power: 0)],
          seeds: _initialSeeds,
        ),
      );

      final result = engine.submit(const BattleDecision.fight(moveSlot: 0));

      expect(result.state.rngSeeds.moveAccuracy,
          isNot(_initialSeeds.moveAccuracy));
      expect(result.state.rngSeeds.moveDamage, _initialSeeds.moveDamage);
      expect(result.state.rngSeeds.moveCritical, _initialSeeds.moveCritical);
      expect(result.state.rngSeeds.generic, _initialSeeds.generic);
      expect(
        result.timeline.events
            .whereType<BattleMoveMissedTimelineEvent>()
            .map((event) => event.moveId),
        contains('thunder_wave'),
      );
      expect(
        result.timeline.events.where(
          (event) =>
              event is BattleAnimationCueTimelineEvent &&
              event.moveId == 'thunder_wave',
        ),
        isEmpty,
      );
    });

    test('probabilistic status consumes generic but not damage stream', () {
      final engine = BattleEngine(
        setup: _setup(
          playerMoves: <PsdkBattleMoveData>[
            _statusMove(accuracy: 100, chance: 1),
          ],
          opponentMoves: <PsdkBattleMoveData>[_damagingMove(power: 0)],
          seeds: _initialSeeds,
        ),
      );

      final result = engine.submit(const BattleDecision.fight(moveSlot: 0));

      expect(result.state.rngSeeds.generic, isNot(_initialSeeds.generic));
      expect(result.state.rngSeeds.moveAccuracy, _initialSeeds.moveAccuracy);
      expect(result.state.rngSeeds.moveDamage, _initialSeeds.moveDamage);
      expect(
        result.timeline.events.whereType<BattleStatusChangeTimelineEvent>(),
        isEmpty,
      );
    });
  });
}

BattleEngineSetup _setup({
  required List<PsdkBattleMoveData> playerMoves,
  required List<PsdkBattleMoveData> opponentMoves,
  required BattleRngSeeds seeds,
}) {
  return BattleEngineSetup.singles(
    player: _combatant(
      id: 'player-bulbasaur',
      speciesId: 'bulbasaur',
      speed: 100,
      moves: playerMoves,
    ),
    opponent: _combatant(
      id: 'opponent-squirtle',
      speciesId: 'squirtle',
      speed: 1,
      moves: opponentMoves,
    ),
    rngSeeds: seeds.psdkSeeds,
  );
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  required String speciesId,
  required int speed,
  required List<PsdkBattleMoveData> moves,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: speciesId,
    displayName: speciesId,
    level: 10,
    maxHp: 40,
    currentHp: 40,
    types: const PsdkBattleTypes(primary: 'normal'),
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

PsdkBattleMoveData _damagingMove({required int power}) {
  return PsdkBattleMoveData(
    id: 'tackle',
    dbSymbol: 'tackle',
    name: 'Tackle',
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

PsdkBattleMoveData _statusMove({
  required int accuracy,
  required int chance,
}) {
  return PsdkBattleMoveData(
    id: 'thunder_wave',
    dbSymbol: 'thunder_wave',
    name: 'Thunder Wave',
    type: 'electric',
    category: PsdkBattleMoveCategory.status,
    power: 0,
    accuracy: accuracy,
    pp: 20,
    priority: 0,
    battleEngineMethod: 's_status',
    target: PsdkBattleMoveTarget.adjacentFoe,
    statuses: <PsdkBattleMoveStatus>[
      PsdkBattleMoveStatus(
        status: PsdkBattleMajorStatus.paralysis,
        chance: chance,
      ),
    ],
  );
}
