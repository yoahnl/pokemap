import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK spread status/stat moves', () {
    test('s_status applies confusion to each adjacent target', () {
      final result = _execute(
        _move(
          id: 'teeter_dance',
          battleEngineMethod: 's_status',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          target: PsdkBattleMoveTarget.allAdjacent,
          statuses: <PsdkBattleMoveStatus>[
            PsdkBattleMoveStatus.volatile(
              status: PsdkBattleVolatileStatus.confusion,
              chance: 100,
            ),
          ],
        ),
      );

      for (final target in <PsdkBattleSlotRef>[
        _playerRightSlot,
        psdkOpponentSlot,
        _opponentRightSlot,
      ]) {
        expect(
          result.state
              .battlerAt(target)
              .effects
              .contains(PsdkBattleEffectIds.confusion),
          isTrue,
        );
      }
    });

    test('s_stat can boost an adjacent ally target', () {
      final result = _execute(
        _move(
          id: 'aromatic_mist',
          battleEngineMethod: 's_stat',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          target: PsdkBattleMoveTarget.adjacentAlly,
          stageMods: const <PsdkBattleMoveStageMod>[
            PsdkBattleMoveStageMod(
              stat: 'specialDefense',
              stages: 1,
              chance: 100,
            ),
          ],
        ),
        target: _playerRightSlot,
      );

      expect(
        result.state
            .battlerAt(_playerRightSlot)
            .statStages
            .valueOf('specialDefense'),
        1,
      );
      expect(
          result.state.battlerAt(psdkOpponentSlot).statStages.values, isEmpty);
    });
  });
}

BattleMoveBehaviorResolution _execute(
  PsdkBattleMoveData move, {
  PsdkBattleSlotRef target = psdkOpponentSlot,
}) {
  return const PsdkBattleMoveExecutor().execute(
    PsdkBattleMoveRequest(
      state: _doublesState(),
      rng: BattleRngStreams.fromSeeds(
        moveDamageSeed: 1,
        moveCriticalSeed: 99999,
        moveAccuracySeed: 3,
        genericSeed: 4,
      ),
      turn: 1,
      user: psdkPlayerSlot,
      target: target,
      moveId: move.id,
      battleEngineMethod: move.battleEngineMethod,
      studioMove: move,
    ),
  );
}

PsdkBattleState _doublesState() {
  return PsdkBattleState(
    combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
      psdkPlayerSlot: PsdkBattleCombatant.fromSetup(
        _combatant(id: 'player', move: _move(id: 'wait', power: 0)),
      ),
      _playerRightSlot: PsdkBattleCombatant.fromSetup(
        _combatant(id: 'player_ally', move: _move(id: 'ally_wait', power: 0)),
      ),
      psdkOpponentSlot: PsdkBattleCombatant.fromSetup(
        _combatant(id: 'opponent', move: _move(id: 'opponent_wait', power: 0)),
      ),
      _opponentRightSlot: PsdkBattleCombatant.fromSetup(
        _combatant(
          id: 'opponent_ally',
          move: _move(id: 'opponent_ally_wait', power: 0),
        ),
      ),
    },
  );
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  required PsdkBattleMoveData move,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 20,
    maxHp: 100,
    currentHp: 100,
    types: const PsdkBattleTypes(primary: 'normal'),
    stats: const PsdkBattleStats(
      attack: 50,
      defense: 50,
      specialAttack: 50,
      specialDefense: 50,
      speed: 50,
    ),
    moves: <PsdkBattleMoveData>[move],
  );
}

PsdkBattleMoveData _move({
  required String id,
  String type = 'normal',
  PsdkBattleMoveCategory category = PsdkBattleMoveCategory.physical,
  required int power,
  int accuracy = 100,
  String battleEngineMethod = 's_basic',
  PsdkBattleMoveTarget target = PsdkBattleMoveTarget.adjacentFoe,
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
    criticalRate: 1,
    battleEngineMethod: battleEngineMethod,
    target: target,
    statuses: statuses,
    stageMods: stageMods,
  );
}

const _playerRightSlot = PsdkBattleSlotRef(bank: 0, position: 1);
const _opponentRightSlot = PsdkBattleSlotRef(bank: 1, position: 1);
