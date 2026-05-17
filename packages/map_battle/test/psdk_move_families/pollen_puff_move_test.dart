import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK Pollen Puff move family', () {
    test('s_pollen_puff heals an allied target instead of damaging it', () {
      final allySlot = const PsdkBattleSlotRef(bank: 0, position: 1);
      final move = _move(
        id: 'pollen_puff',
        type: 'bug',
        category: PsdkBattleMoveCategory.special,
        power: 90,
        battleEngineMethod: 's_pollen_puff',
        target: PsdkBattleMoveTarget.adjacentAlly,
      );
      final state = PsdkBattleState(
        combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
          psdkPlayerSlot: _combatant(
            id: 'player',
            move: move,
          ),
          allySlot: _combatant(
            id: 'ally',
            currentHp: 25,
            move: _move(id: 'ally_wait', power: 0),
          ),
          psdkOpponentSlot: _combatant(
            id: 'opponent',
            move: _move(id: 'opponent_wait', power: 0),
          ),
        },
      );

      final result =
          createStaticBasicMoveRegistry().resolve('s_pollen_puff').resolve(
                BattleMoveBehaviorContext(
                  state: state,
                  rng: _rng(),
                  turn: 1,
                  user: psdkPlayerSlot,
                  target: allySlot,
                  move: BattleMoveDefinition.fromPsdk(move),
                ),
              );

      expect(result.state.battlerAt(allySlot).currentHp, 75);
      expect(result.events.whereType<PsdkBattleDamageEvent>(), isEmpty);
      expect(_healEvents(result), hasLength(1));
      expect(_healEvents(result).single.amount, 50);
      expect(_healEvents(result).single.target, allySlot);
    });

    test('s_pollen_puff damages opposing targets normally', () {
      final move = _move(
        id: 'pollen_puff',
        type: 'bug',
        category: PsdkBattleMoveCategory.special,
        power: 90,
        battleEngineMethod: 's_pollen_puff',
      );
      final state = PsdkBattleState(
        combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
          psdkPlayerSlot: _combatant(id: 'player', move: move),
          psdkOpponentSlot: _combatant(
            id: 'opponent',
            move: _move(id: 'opponent_wait', power: 0),
          ),
        },
      );

      final result =
          createStaticBasicMoveRegistry().resolve('s_pollen_puff').resolve(
                BattleMoveBehaviorContext(
                  state: state,
                  rng: _rng(),
                  turn: 1,
                  user: psdkPlayerSlot,
                  target: psdkOpponentSlot,
                  move: BattleMoveDefinition.fromPsdk(move),
                ),
              );

      expect(_damageEvents(result), hasLength(1));
      expect(_healEvents(result), isEmpty);
      expect(result.state.battlerAt(psdkOpponentSlot).currentHp, lessThan(100));
    });

    test('s_pollen_puff does not heal allies while the user is Heal Blocked',
        () {
      final allySlot = const PsdkBattleSlotRef(bank: 0, position: 1);
      final move = _move(
        id: 'pollen_puff',
        type: 'bug',
        category: PsdkBattleMoveCategory.special,
        power: 90,
        battleEngineMethod: 's_pollen_puff',
        target: PsdkBattleMoveTarget.adjacentAlly,
      );
      final state = PsdkBattleState(
        combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
          psdkPlayerSlot: _combatant(
            id: 'player',
            move: move,
            effects: PsdkBattleEffectStack(
              values: const <String>['heal_block'],
            ),
          ),
          allySlot: _combatant(
            id: 'ally',
            currentHp: 25,
            move: _move(id: 'ally_wait', power: 0),
          ),
        },
      );

      final result =
          createStaticBasicMoveRegistry().resolve('s_pollen_puff').resolve(
                BattleMoveBehaviorContext(
                  state: state,
                  rng: _rng(),
                  turn: 1,
                  user: psdkPlayerSlot,
                  target: allySlot,
                  move: BattleMoveDefinition.fromPsdk(move),
                ),
              );

      expect(result.state.battlerAt(allySlot).currentHp, 25);
      expect(_damageEvents(result), isEmpty);
      expect(_healEvents(result), isEmpty);
    });

    test('s_pollen_puff does not heal Heal Blocked allies', () {
      final allySlot = const PsdkBattleSlotRef(bank: 0, position: 1);
      final move = _move(
        id: 'pollen_puff',
        type: 'bug',
        category: PsdkBattleMoveCategory.special,
        power: 90,
        battleEngineMethod: 's_pollen_puff',
        target: PsdkBattleMoveTarget.adjacentAlly,
      );
      final state = PsdkBattleState(
        combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
          psdkPlayerSlot: _combatant(
            id: 'player',
            move: move,
          ),
          allySlot: _combatant(
            id: 'ally',
            currentHp: 25,
            move: _move(id: 'ally_wait', power: 0),
            effects: PsdkBattleEffectStack(
              values: const <String>['heal_block'],
            ),
          ),
        },
      );

      final result =
          createStaticBasicMoveRegistry().resolve('s_pollen_puff').resolve(
                BattleMoveBehaviorContext(
                  state: state,
                  rng: _rng(),
                  turn: 1,
                  user: psdkPlayerSlot,
                  target: allySlot,
                  move: BattleMoveDefinition.fromPsdk(move),
                ),
              );

      expect(result.state.battlerAt(allySlot).currentHp, 25);
      expect(_damageEvents(result), isEmpty);
      expect(_healEvents(result), isEmpty);
    });
  });
}

PsdkBattleCombatant _combatant({
  required String id,
  required PsdkBattleMoveData move,
  int currentHp = 100,
  PsdkBattleEffectStack effects = const PsdkBattleEffectStack.empty(),
}) {
  return PsdkBattleCombatant.fromSetup(
    PsdkBattleCombatantSetup(
      id: id,
      speciesId: id,
      displayName: id,
      level: 20,
      maxHp: 100,
      currentHp: currentHp,
      types: const PsdkBattleTypes(primary: 'normal'),
      stats: const PsdkBattleStats(
        attack: 50,
        defense: 50,
        specialAttack: 50,
        specialDefense: 50,
        speed: 50,
      ),
      moves: <PsdkBattleMoveData>[move],
      effects: effects,
    ),
  );
}

PsdkBattleMoveData _move({
  required String id,
  String type = 'normal',
  PsdkBattleMoveCategory category = PsdkBattleMoveCategory.physical,
  required int power,
  String battleEngineMethod = 's_basic',
  PsdkBattleMoveTarget target = PsdkBattleMoveTarget.adjacentFoe,
}) {
  return PsdkBattleMoveData(
    id: id,
    dbSymbol: id,
    name: id,
    type: type,
    category: category,
    power: power,
    accuracy: 100,
    pp: 35,
    priority: 0,
    criticalRate: 1,
    battleEngineMethod: battleEngineMethod,
    target: target,
  );
}

BattleRngStreams _rng() {
  return BattleRngStreams.fromPsdkSeeds(
    const PsdkBattleRngSeeds(
      moveDamage: 1,
      moveCritical: 99999,
      moveAccuracy: 3,
      generic: 4,
    ),
  );
}

List<PsdkBattleDamageEvent> _damageEvents(
  BattleMoveBehaviorResolution result,
) {
  return result.events.whereType<PsdkBattleDamageEvent>().toList();
}

List<PsdkBattleHealEvent> _healEvents(
  BattleMoveBehaviorResolution result,
) {
  return result.events.whereType<PsdkBattleHealEvent>().toList();
}
