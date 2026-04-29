import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK Flame Burst move family', () {
    test('s_flame_burst splashes adjacent allies of a damaged target', () {
      const splashSlot = PsdkBattleSlotRef(bank: 1, position: 1);
      final move = _move(
        id: 'flame_burst',
        type: 'fire',
        category: PsdkBattleMoveCategory.special,
        power: 70,
        battleEngineMethod: 's_flame_burst',
      );
      final state = PsdkBattleState(
        combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
          psdkPlayerSlot: _combatant(id: 'player', move: move),
          psdkOpponentSlot: _combatant(
            id: 'opponent',
            move: _move(id: 'opponent_wait', power: 0),
          ),
          splashSlot: _combatant(
            id: 'splash',
            move: _move(id: 'splash_wait', power: 0),
          ),
        },
      );

      final result =
          createStaticBasicMoveRegistry().resolve('s_flame_burst').resolve(
                BattleMoveBehaviorContext(
                  state: state,
                  rng: _rng(),
                  turn: 1,
                  user: psdkPlayerSlot,
                  target: psdkOpponentSlot,
                  move: BattleMoveDefinition.fromPsdk(move),
                ),
              );

      final damage = _damageEvents(result, moveId: 'flame_burst');
      expect(damage, hasLength(2));
      expect(damage.first.target, psdkOpponentSlot);
      expect(damage.last.target, splashSlot);
      expect(damage.last.damage, 6);
      expect(result.state.battlerAt(splashSlot).currentHp, 94);
    });

    test('s_flame_burst clamps splash damage to current HP', () {
      const splashSlot = PsdkBattleSlotRef(bank: 1, position: 1);
      final move = _move(
        id: 'flame_burst',
        type: 'fire',
        category: PsdkBattleMoveCategory.special,
        power: 70,
        battleEngineMethod: 's_flame_burst',
      );
      final state = PsdkBattleState(
        combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
          psdkPlayerSlot: _combatant(id: 'player', move: move),
          psdkOpponentSlot: _combatant(
            id: 'opponent',
            move: _move(id: 'opponent_wait', power: 0),
          ),
          splashSlot: _combatant(
            id: 'splash',
            currentHp: 3,
            move: _move(id: 'splash_wait', power: 0),
          ),
        },
      );

      final result =
          createStaticBasicMoveRegistry().resolve('s_flame_burst').resolve(
                BattleMoveBehaviorContext(
                  state: state,
                  rng: _rng(),
                  turn: 1,
                  user: psdkPlayerSlot,
                  target: psdkOpponentSlot,
                  move: BattleMoveDefinition.fromPsdk(move),
                ),
              );

      final splashDamage = _damageEvents(result, moveId: 'flame_burst')
          .singleWhere((event) => event.target == splashSlot);
      expect(splashDamage.damage, 3);
      expect(result.state.battlerAt(splashSlot).currentHp, 0);
    });

    test('s_flame_burst skips Magic Guard adjacent allies', () {
      const splashSlot = PsdkBattleSlotRef(bank: 1, position: 1);
      final move = _move(
        id: 'flame_burst',
        type: 'fire',
        category: PsdkBattleMoveCategory.special,
        power: 70,
        battleEngineMethod: 's_flame_burst',
      );
      final state = PsdkBattleState(
        combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
          psdkPlayerSlot: _combatant(id: 'player', move: move),
          psdkOpponentSlot: _combatant(
            id: 'opponent',
            move: _move(id: 'opponent_wait', power: 0),
          ),
          splashSlot: _combatant(
            id: 'splash',
            abilityId: 'magic_guard',
            move: _move(id: 'splash_wait', power: 0),
          ),
        },
      );

      final result =
          createStaticBasicMoveRegistry().resolve('s_flame_burst').resolve(
                BattleMoveBehaviorContext(
                  state: state,
                  rng: _rng(),
                  turn: 1,
                  user: psdkPlayerSlot,
                  target: psdkOpponentSlot,
                  move: BattleMoveDefinition.fromPsdk(move),
                ),
              );

      expect(
        _damageEvents(result, moveId: 'flame_burst')
            .where((event) => event.target == splashSlot),
        isEmpty,
      );
      expect(result.state.battlerAt(splashSlot).currentHp, 100);
    });
  });
}

PsdkBattleCombatant _combatant({
  required String id,
  int currentHp = 100,
  String? abilityId,
  required PsdkBattleMoveData move,
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
      abilityId: abilityId,
      stats: const PsdkBattleStats(
        attack: 50,
        defense: 50,
        specialAttack: 50,
        specialDefense: 50,
        speed: 50,
      ),
      moves: <PsdkBattleMoveData>[move],
    ),
  );
}

PsdkBattleMoveData _move({
  required String id,
  String type = 'normal',
  PsdkBattleMoveCategory category = PsdkBattleMoveCategory.physical,
  required int power,
  String battleEngineMethod = 's_basic',
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
    target: PsdkBattleMoveTarget.adjacentFoe,
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
  BattleMoveBehaviorResolution result, {
  required String moveId,
}) {
  return result.events
      .whereType<PsdkBattleDamageEvent>()
      .where((event) => event.moveId == moveId)
      .toList(growable: false);
}
