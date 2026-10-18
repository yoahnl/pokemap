import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('Sniper with the current critical ruleset', () {
    for (final vector in [
      (power: 15, ordinary: 6, sniper: 9),
      (power: 20, ordinary: 7, sniper: 11),
    ]) {
      test('power ${vector.power} applies the combined multiplier before roll',
          () {
        final ordinary = _calculate(power: vector.power);
        final sniper = _calculate(power: vector.power, userAbility: 'sniper');
        expect(ordinary.isCritical, isTrue);
        expect(ordinary.criticalMultiplier, 1.5);
        expect(ordinary.damage, vector.ordinary);
        expect(sniper.isCritical, isTrue);
        expect(sniper.criticalMultiplier, 2.25);
        expect(sniper.damage, vector.sniper);
      });
    }

    test('does not change a noncritical hit', () {
      final ordinary = _calculate(criticalRate: 0);
      final sniper = _calculate(criticalRate: 0, userAbility: 'sniper');
      expect(ordinary.isCritical, isFalse);
      expect(sniper.isCritical, isFalse);
      expect(ordinary.damage, 4);
      expect(sniper.damage, ordinary.damage);
      expect(sniper.criticalMultiplier, 1);
      expect(_seeds(sniper), _seeds(ordinary));
    });

    test('ability suppression removes only the Sniper bonus', () {
      final suppressed = _calculate(userAbility: 'sniper', suppressed: true);
      final ordinary = _calculate();
      expect(suppressed.isCritical, isTrue);
      expect(suppressed.criticalMultiplier, 1.5);
      expect(suppressed.damage, ordinary.damage);
      expect(_seeds(suppressed), _seeds(ordinary));
    });

    test('a target with Sniper does not boost the attacker', () {
      final ordinary = _calculate();
      final targetSniper = _calculate(targetAbility: 'sniper');
      expect(targetSniper.criticalMultiplier, 1.5);
      expect(targetSniper.damage, ordinary.damage);
    });

    test('a target with Mold Breaker does not suppress attacking Sniper', () {
      final result = _calculate(
        userAbility: 'sniper',
        targetAbility: 'mold_breaker',
      );
      expect(result.criticalMultiplier, 2.25);
      expect(result.damage, 9);
    });

    test('the bonus consumes no additional random values', () {
      final ordinary = _calculate();
      final sniper = _calculate(userAbility: 'sniper');
      expect(sniper.damage, 9);
      expect(_seeds(sniper), _seeds(ordinary));
      expect(sniper.rng.seeds.moveCritical, 99999);
      expect(sniper.rng.seeds.moveAccuracy, 3);
      expect(sniper.rng.seeds.generic, 4);
      expect(sniper.rng.seeds.moveDamage, isNot(1));
    });

    test('the production battle engine applies and suppresses Sniper', () {
      for (final entry in [
        (ability: null, suppressed: false, damage: 6),
        (ability: 'sniper', suppressed: false, damage: 9),
        (ability: 'sniper', suppressed: true, damage: 6),
      ]) {
        final engine = BattleEngine(
          setup: _setup(
            userAbility: entry.ability,
            suppressed: entry.suppressed,
          ),
        );
        final result = engine.submit(const BattleDecision.fight(moveSlot: 0));
        expect(result.state.battlerAt(psdkOpponentSlot).currentHp,
            200 - entry.damage);
        expect(
            result.state.battlerAt(psdkPlayerSlot).moves.single.currentPp, 19);
        final hit = result.timeline.psdkTimeline.events
            .whereType<PsdkBattleDamageEvent>()
            .where((event) =>
                event.moveId == 'sniper_probe' &&
                event.target == psdkOpponentSlot)
            .single;
        expect(hit.damage, entry.damage);
      }
    });
  });
}

BattleMoveDamageResult _calculate({
  int power = 15,
  int criticalRate = 4,
  String? userAbility,
  String? targetAbility,
  bool suppressed = false,
}) {
  final setup = _setup(
    power: power,
    criticalRate: criticalRate,
    userAbility: userAbility,
    targetAbility: targetAbility,
    suppressed: suppressed,
  ).psdkSetup;
  final state = PsdkBattleState.fromSetup(setup);
  return const BattleMoveDamageCalculator().calculate(
    BattleMoveDamageContext(
      state: state,
      user: state.battlerAt(psdkPlayerSlot),
      target: state.battlerAt(psdkOpponentSlot),
      userSlot: psdkPlayerSlot,
      targetSlot: psdkOpponentSlot,
      move: BattleMoveDefinition.fromPsdk(
          setup.combatants[psdkPlayerSlot]!.moves.single),
      rng: BattleRngStreams.fromPsdkSeeds(setup.rngSeeds),
    ),
  );
}

BattleEngineSetup _setup({
  int power = 15,
  int criticalRate = 4,
  String? userAbility,
  String? targetAbility,
  bool suppressed = false,
}) {
  final move = PsdkBattleMoveData(
    id: 'sniper_probe',
    dbSymbol: 'sniper_probe',
    name: 'Sniper probe',
    type: 'normal',
    category: PsdkBattleMoveCategory.physical,
    power: power,
    accuracy: 100,
    pp: 20,
    priority: 0,
    criticalRate: criticalRate,
    battleEngineMethod: 's_basic',
    target: PsdkBattleMoveTarget.adjacentFoe,
  );
  return BattleEngineSetup.singlesPokeMapBetaV1ForTest(
    player: _combatant(
      'player',
      move,
      speed: 100,
      ability: userAbility,
      effects: suppressed
          ? PsdkBattleEffectStack(values: ['ability_suppressed'])
          : const PsdkBattleEffectStack.empty(),
    ),
    opponent: _combatant(
      'opponent',
      move,
      speed: 1,
      ability: targetAbility,
    ),
    rngSeeds: const PsdkBattleRngSeeds(
      moveDamage: 1,
      moveCritical: 99999,
      moveAccuracy: 3,
      generic: 4,
    ),
  );
}

PsdkBattleCombatantSetup _combatant(
  String id,
  PsdkBattleMoveData move, {
  required int speed,
  String? ability,
  PsdkBattleEffectStack effects = const PsdkBattleEffectStack.empty(),
}) =>
    PsdkBattleCombatantSetup(
      id: id,
      speciesId: id,
      displayName: id,
      level: 20,
      maxHp: 200,
      currentHp: 200,
      types: const PsdkBattleTypes(primary: 'water'),
      stats: PsdkBattleStats(
        attack: 50,
        defense: 50,
        specialAttack: 50,
        specialDefense: 50,
        speed: speed,
      ),
      abilityId: ability,
      effects: effects,
      moves: [move],
    );

List<int> _seeds(BattleMoveDamageResult result) {
  final seeds = result.rng.seeds;
  return [
    seeds.moveDamage,
    seeds.moveCritical,
    seeds.moveAccuracy,
    seeds.generic
  ];
}
