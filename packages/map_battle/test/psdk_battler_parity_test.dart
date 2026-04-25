import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK battler parity state', () {
    test('carries PokemonBattler ability item counters and flags from setup',
        () {
      final battler = PsdkBattleCombatant.fromSetup(
        _combatant(
          abilityId: 'levitate',
          heldItemId: 'air_balloon',
          consumedItemId: 'oran_berry',
          itemConsumed: true,
          sleepTurns: 2,
          battleTurnCount: 3,
          lastBattleTurn: 7,
          lastSentTurn: 4,
          lastHitByMoveId: 'tackle',
          koCount: 1,
          switching: true,
          hasJustShifted: true,
          type3: 'ghost',
          temporaryTypes: <String>['flying'],
          transformState: const PsdkBattleTransformState(
            transformedFromSpeciesId: 'ditto',
            illusionSpeciesId: 'zoroark',
            illusionDisplayName: 'Zoroark',
          ),
        ),
      );

      expect(battler.abilityId, 'levitate');
      expect(battler.heldItemId, 'air_balloon');
      expect(battler.consumedItemId, 'oran_berry');
      expect(battler.itemConsumed, isTrue);
      expect(battler.sleepTurns, 2);
      expect(battler.battleTurnCount, 3);
      expect(battler.lastBattleTurn, 7);
      expect(battler.lastSentTurn, 4);
      expect(battler.lastHitByMoveId, 'tackle');
      expect(battler.koCount, 1);
      expect(battler.switching, isTrue);
      expect(battler.hasJustShifted, isTrue);
      expect(battler.type3, 'ghost');
      expect(battler.temporaryTypes, <String>['flying']);
      expect(battler.transformState.isTransformed, isTrue);
      expect(battler.transformState.hasIllusion, isTrue);
      expect(() => battler.temporaryTypes.clear(), throwsUnsupportedError);
    });

    test('nullable turn markers can be cleared through copyWith', () {
      final battler = PsdkBattleCombatant.fromSetup(
        _combatant(
          lastBattleTurn: 8,
          lastSentTurn: 3,
        ),
      );

      final unchanged = battler.copyWith();
      final cleared = battler.copyWith(
        lastBattleTurn: null,
        lastSentTurn: null,
      );

      expect(unchanged.lastBattleTurn, 8);
      expect(unchanged.lastSentTurn, 3);
      expect(cleared.lastBattleTurn, isNull);
      expect(cleared.lastSentTurn, isNull);
    });

    test('records immutable damage and stat histories with PSDK turn context',
        () {
      final battler = PsdkBattleCombatant.fromSetup(_combatant());

      final changed = battler
          .recordDamage(
            turn: 5,
            source: psdkOpponentSlot,
            moveId: 'ember',
            damage: 12,
            remainingHp: 28,
          )
          .recordStatChange(
            turn: 5,
            stat: 'attack',
            delta: -1,
            currentStage: -1,
          );

      expect(changed.lastHitByMoveId, 'ember');
      expect(changed.damageHistory.entries.single.damage, 12);
      expect(changed.damageHistory.entries.single.source, psdkOpponentSlot);
      expect(changed.statHistory.entries.single.stat, 'attack');
      expect(changed.statHistory.entries.single.delta, -1);
      expect(
          () => changed.damageHistory.entries.clear(), throwsUnsupportedError);
      expect(() => changed.statHistory.entries.clear(), throwsUnsupportedError);
    });

    test('a real engine damage event records PSDK target history', () {
      final engine = BattleEngine(
        setup: BattleEngineSetup.singles(
          player: _combatant(
            id: 'player',
            speed: 120,
            movePower: 70,
          ),
          opponent: _combatant(
            id: 'opponent',
            speed: 1,
            currentHp: 40,
            movePower: 1,
          ),
          rngSeeds: const PsdkBattleRngSeeds(
            moveDamage: 1,
            moveCritical: 1,
            moveAccuracy: 1,
            generic: 1,
          ),
        ),
      );

      final result = engine.submit(const BattleDecision.fight(moveSlot: 0));
      final opponent = result.state.battlerAt(psdkOpponentSlot);
      final history = opponent.damageHistory.entries;

      expect(history, hasLength(1));
      expect(history.single.turn, 1);
      expect(history.single.source, psdkPlayerSlot);
      expect(history.single.moveId, 'tackle');
      expect(history.single.damage, greaterThan(0));
      expect(history.single.remainingHp, opponent.currentHp);
      expect(opponent.lastHitByMoveId, 'tackle');
    });

    test('grounding follows PSDK force-grounded precedence', () {
      const resolver = BattleGroundingResolver();
      final airborne = PsdkBattleCombatant.fromSetup(
        _combatant(
          abilityId: 'levitate',
          heldItemId: 'air_balloon',
          types: const PsdkBattleTypes(primary: 'electric'),
        ),
      );

      expect(resolver.isGrounded(airborne), isFalse);
      expect(
        resolver.isGrounded(airborne.copyWith(heldItemId: 'iron_ball')),
        isTrue,
      );
      expect(
        resolver.isGrounded(
          airborne.copyWith(effects: airborne.effects.add('gravity')),
        ),
        isTrue,
      );
    });
  });
}

PsdkBattleCombatantSetup _combatant({
  String id = 'player',
  String? abilityId,
  String? heldItemId,
  String? consumedItemId,
  bool itemConsumed = false,
  int sleepTurns = 0,
  int battleTurnCount = 0,
  int? lastBattleTurn,
  int? lastSentTurn,
  String? lastHitByMoveId,
  int koCount = 0,
  bool switching = false,
  bool hasJustShifted = false,
  String? type3,
  List<String> temporaryTypes = const <String>[],
  PsdkBattleTransformState transformState = const PsdkBattleTransformState(),
  PsdkBattleTypes types = const PsdkBattleTypes(primary: 'normal'),
  int currentHp = 40,
  int speed = 90,
  int movePower = 40,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: 'pikachu',
    displayName: 'Pikachu',
    level: 12,
    maxHp: 40,
    currentHp: currentHp,
    types: types,
    stats: PsdkBattleStats(
      attack: 55,
      defense: 40,
      specialAttack: 50,
      specialDefense: 50,
      speed: speed,
    ),
    moves: <PsdkBattleMoveData>[
      PsdkBattleMoveData(
        id: 'tackle',
        dbSymbol: 'tackle',
        name: 'Tackle',
        type: 'normal',
        category: PsdkBattleMoveCategory.physical,
        power: movePower,
        accuracy: 100,
        pp: 35,
        priority: 0,
        battleEngineMethod: 's_basic',
        target: PsdkBattleMoveTarget.adjacentFoe,
      ),
    ],
    abilityId: abilityId,
    heldItemId: heldItemId,
    consumedItemId: consumedItemId,
    itemConsumed: itemConsumed,
    sleepTurns: sleepTurns,
    battleTurnCount: battleTurnCount,
    lastBattleTurn: lastBattleTurn,
    lastSentTurn: lastSentTurn,
    lastHitByMoveId: lastHitByMoveId,
    koCount: koCount,
    switching: switching,
    hasJustShifted: hasJustShifted,
    type3: type3,
    temporaryTypes: temporaryTypes,
    transformState: transformState,
  );
}
