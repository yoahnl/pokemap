import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK action queue', () {
    test('orders switch actions before regular fight actions', () {
      final ordered = PsdkBattleActionQueue(
        actions: <PsdkBattleAction>[
          _fight(
            user: psdkPlayerSlot,
            moveId: 'quick_attack',
            priority: 1,
            speed: 200,
          ),
          const PsdkBattleSwitchAction(
            user: psdkOpponentSlot,
            partyIndex: 1,
          ),
        ],
      ).ordered(rng: _rng());

      expect(ordered.first.kind, PsdkBattleActionKind.switchPokemon);
      expect(ordered.last.kind, PsdkBattleActionKind.fight);
    });

    test('orders fight actions by move priority then speed', () {
      final ordered = PsdkBattleActionQueue(
        actions: <PsdkBattleAction>[
          _fight(
            user: psdkPlayerSlot,
            moveId: 'tackle',
            priority: 0,
            speed: 200,
          ),
          _fight(
            user: psdkOpponentSlot,
            moveId: 'quick_attack',
            priority: 1,
            speed: 1,
          ),
        ],
      ).ordered(rng: _rng());

      expect((ordered.first as PsdkBattleFightAction).move.id, 'quick_attack');
      expect((ordered.last as PsdkBattleFightAction).move.id, 'tackle');
    });

    test('reverses speed only under Trick Room', () {
      final ordered = PsdkBattleActionQueue(
        actions: <PsdkBattleAction>[
          _fight(user: psdkPlayerSlot, moveId: 'fast', speed: 100),
          _fight(user: psdkOpponentSlot, moveId: 'slow', speed: 1),
        ],
      ).ordered(rng: _rng(), trickRoom: true);

      expect((ordered.first as PsdkBattleFightAction).move.id, 'slow');
      expect((ordered.last as PsdkBattleFightAction).move.id, 'fast');
    });

    test('keeps bank order for exact fight ties', () {
      final ordered = PsdkBattleActionQueue(
        actions: <PsdkBattleAction>[
          _fight(user: psdkOpponentSlot, moveId: 'opponent_tackle', speed: 50),
          _fight(user: psdkPlayerSlot, moveId: 'player_tackle', speed: 50),
        ],
      ).ordered(rng: _rng());

      expect(ordered.first.user, psdkPlayerSlot);
      expect(ordered.last.user, psdkOpponentSlot);
    });

    test('decision mapper builds a fight action from PSDK state', () {
      final state = PsdkBattleState.fromSetup(_setup());

      final action = const PsdkBattleActionDecisionMapper().map(
        state: state,
        user: psdkPlayerSlot,
        decision: const BattleDecision.fight(moveSlot: 0),
      );

      expect(action, isA<PsdkBattleFightAction>());
      final fight = action as PsdkBattleFightAction;
      expect(fight.user, psdkPlayerSlot);
      expect(fight.target, psdkOpponentSlot);
      expect(fight.move.id, 'tackle');
      expect(fight.speed, 50);
    });
  });
}

PsdkBattleFightAction _fight({
  required PsdkBattleSlotRef user,
  required String moveId,
  int priority = 0,
  int speed = 50,
}) {
  return PsdkBattleFightAction(
    user: user,
    target: user == psdkPlayerSlot ? psdkOpponentSlot : psdkPlayerSlot,
    moveSlot: 0,
    move: _move(id: moveId, priority: priority),
    speed: speed,
  );
}

BattleRngStreams _rng() {
  return BattleRngStreams.fromSeeds(
    moveDamageSeed: 1,
    moveCriticalSeed: 1,
    moveAccuracySeed: 1,
    genericSeed: 1,
  );
}

PsdkBattleSetup _setup() {
  return PsdkBattleSetup.singles(
    player: _combatant(id: 'player', speed: 50),
    opponent: _combatant(id: 'opponent', speed: 20),
    rngSeeds: const PsdkBattleRngSeeds(
      moveDamage: 1,
      moveCritical: 1,
      moveAccuracy: 1,
      generic: 1,
    ),
  );
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  required int speed,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 10,
    maxHp: 40,
    currentHp: 40,
    types: const PsdkBattleTypes(primary: 'normal'),
    stats: PsdkBattleStats(
      attack: 20,
      defense: 20,
      specialAttack: 20,
      specialDefense: 20,
      speed: speed,
    ),
    moves: <PsdkBattleMoveData>[_move(id: 'tackle')],
  );
}

PsdkBattleMoveData _move({
  required String id,
  int priority = 0,
}) {
  return PsdkBattleMoveData(
    id: id,
    dbSymbol: id,
    name: id,
    type: 'normal',
    category: PsdkBattleMoveCategory.physical,
    power: 40,
    accuracy: 100,
    pp: 35,
    priority: priority,
    battleEngineMethod: 's_basic',
    target: PsdkBattleMoveTarget.adjacentFoe,
  );
}
