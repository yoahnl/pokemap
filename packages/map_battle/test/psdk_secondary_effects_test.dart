import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK clean secondary effects', () {
    test('a damaging move can apply a major status after damage', () {
      final result = _runPlayerMove(
        _move(
          id: 'ember',
          type: 'fire',
          category: PsdkBattleMoveCategory.special,
          power: 40,
          statuses: <PsdkBattleMoveStatus>[
            PsdkBattleMoveStatus(
              status: PsdkBattleMajorStatus.burn,
              chance: 100,
            ),
          ],
        ),
      );

      final opponent = result.state.battlerAt(psdkOpponentSlot);
      expect(opponent.currentHp, lessThan(100));
      expect(opponent.majorStatus, PsdkBattleMajorStatus.burn);
      expect(
        result.timeline.events.map((event) => event.kind),
        containsAllInOrder(<String>[
          'damage',
          'status',
        ]),
      );
    });

    test('a failed secondary effect consumes generic but keeps damage', () {
      const seeds = BattleRngSeeds(
        moveDamage: 1,
        moveCritical: 99999,
        moveAccuracy: 3,
        generic: 99,
      );
      final result = _runPlayerMove(
        _move(
          id: 'poison_sting',
          type: 'poison',
          power: 40,
          effectChance: 1,
          statuses: <PsdkBattleMoveStatus>[
            PsdkBattleMoveStatus(
              status: PsdkBattleMajorStatus.poison,
              chance: 100,
            ),
          ],
        ),
        seeds: seeds,
      );

      final opponent = result.state.battlerAt(psdkOpponentSlot);
      expect(opponent.currentHp, lessThan(100));
      expect(opponent.majorStatus, isNull);
      expect(result.state.rngSeeds.generic, isNot(seeds.generic));
      expect(result.state.rngSeeds.moveDamage, isNot(seeds.moveDamage));
      expect(
        result.timeline.events.whereType<BattleStatusChangeTimelineEvent>(),
        isEmpty,
      );
    });

    test('a damaging move can apply target stat stage changes after damage',
        () {
      final result = _runPlayerMove(
        _move(
          id: 'crunch',
          type: 'dark',
          power: 40,
          stageMods: const <PsdkBattleMoveStageMod>[
            PsdkBattleMoveStageMod(
              stat: 'defense',
              stages: -1,
              chance: 100,
            ),
          ],
        ),
      );

      final opponent = result.state.battlerAt(psdkOpponentSlot);
      expect(opponent.statStages.valueOf('defense'), -1);
      expect(opponent.statHistory.entries, hasLength(1));
      expect(opponent.statHistory.entries.single.turn, 1);
      expect(opponent.statHistory.entries.single.stat, 'defense');
      expect(opponent.statHistory.entries.single.delta, -1);
      expect(opponent.statHistory.entries.single.currentStage, -1);
      expect(
        result.timeline.events
            .whereType<BattleStatStageChangeTimelineEvent>()
            .map((event) => event.toJson()),
        contains(
          containsPair('currentStage', -1),
        ),
      );
    });
  });
}

BattleEngineTurnResult _runPlayerMove(
  PsdkBattleMoveData move, {
  BattleRngSeeds seeds = const BattleRngSeeds(
    moveDamage: 1,
    moveCritical: 99999,
    moveAccuracy: 3,
    generic: 4,
  ),
}) {
  final engine = BattleEngine(
    setup: BattleEngineSetup.singles(
      player: _combatant(
        id: 'player',
        speed: 100,
        types: const PsdkBattleTypes(primary: 'fire'),
        moves: <PsdkBattleMoveData>[move],
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
            accuracy: 1,
          ),
        ],
      ),
      rngSeeds: seeds.psdkSeeds,
    ),
  );
  return engine.submit(const BattleDecision.fight(moveSlot: 0));
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
  PsdkBattleMoveCategory category = PsdkBattleMoveCategory.physical,
  required int power,
  int accuracy = 100,
  int? effectChance,
  List<PsdkBattleMoveStatus> statuses = const <PsdkBattleMoveStatus>[],
  List<PsdkBattleMoveStageMod> stageMods = const <PsdkBattleMoveStageMod>[],
}) {
  return PsdkBattleMoveData(
    id: id,
    dbSymbol: id,
    name: id,
    type: type,
    category: category,
    power: power,
    accuracy: accuracy,
    pp: 35,
    priority: 0,
    battleEngineMethod: 's_basic',
    target: PsdkBattleMoveTarget.adjacentFoe,
    effectChance: effectChance,
    statuses: statuses,
    stageMods: stageMods,
  );
}
