import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK screen move families', () {
    test('Reflect reduces incoming physical damage on the protected bank', () {
      final baseline = _runTurn(
        playerMove: _move(
          id: 'player_wait',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 0,
          battleEngineMethod: 's_splash',
          target: PsdkBattleMoveTarget.self,
        ),
        opponentMove: _move(
          id: 'opponent_tackle',
          power: 80,
        ),
      );
      final reflected = _runTurn(
        playerMove: _move(
          id: 'reflect',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 0,
          battleEngineMethod: 's_reflect',
          target: PsdkBattleMoveTarget.allAllies,
        ),
        opponentMove: _move(
          id: 'opponent_tackle',
          power: 80,
        ),
      );

      final baselineDamage = _damage(baseline, moveId: 'opponent_tackle');
      final reflectedDamage = _damage(reflected, moveId: 'opponent_tackle');

      expect(reflectedDamage, baselineDamage ~/ 2);
    });

    test('Light Clay extends screen duration', () {
      final result = _runTurn(
        playerHeldItemId: 'light_clay',
        playerMove: _move(
          id: 'reflect',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 0,
          battleEngineMethod: 's_reflect',
          target: PsdkBattleMoveTarget.allAllies,
        ),
        opponentMove: _move(
          id: 'opponent_wait',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 0,
        ),
      );

      final reflect = result.state
          .battlerAt(psdkPlayerSlot)
          .effects
          .effects
          .singleWhere((effect) => effect.id == 'reflect');

      expect(reflect.remainingTurns, 7);
    });

    test('Infiltrator bypasses screen damage reduction', () {
      final baseline = _runTurn(
        playerMove: _move(
          id: 'player_wait',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 0,
          battleEngineMethod: 's_splash',
          target: PsdkBattleMoveTarget.self,
        ),
        opponentAbilityId: 'infiltrator',
        opponentMove: _move(
          id: 'opponent_tackle',
          power: 80,
        ),
      );
      final reflected = _runTurn(
        playerMove: _move(
          id: 'reflect',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 0,
          battleEngineMethod: 's_reflect',
          target: PsdkBattleMoveTarget.allAllies,
        ),
        opponentAbilityId: 'infiltrator',
        opponentMove: _move(
          id: 'opponent_tackle',
          power: 80,
        ),
      );

      expect(
        _damage(reflected, moveId: 'opponent_tackle'),
        _damage(baseline, moveId: 'opponent_tackle'),
      );
    });

    test('s_baddy_bad damages then installs Reflect on the user bank', () {
      final result = _runTurn(
        playerMove: _move(
          id: 'baddy_bad',
          category: PsdkBattleMoveCategory.special,
          power: 80,
          battleEngineMethod: 's_baddy_bad',
        ),
        opponentMove: _move(
          id: 'opponent_wait',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 0,
        ),
      );

      expect(_damage(result, moveId: 'baddy_bad'), greaterThan(0));
      expect(
        result.state.battlerAt(psdkPlayerSlot).effects.contains('reflect'),
        isTrue,
      );
    });

    test('s_glitzy_glow damages then installs Light Screen with Light Clay',
        () {
      final result = _runTurn(
        playerHeldItemId: 'light_clay',
        playerMove: _move(
          id: 'glitzy_glow',
          category: PsdkBattleMoveCategory.special,
          power: 80,
          battleEngineMethod: 's_glitzy_glow',
        ),
        opponentMove: _move(
          id: 'opponent_wait',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 0,
        ),
      );

      final lightScreen = result.state
          .battlerAt(psdkPlayerSlot)
          .effects
          .effects
          .singleWhere((effect) => effect.id == 'light_screen');

      expect(_damage(result, moveId: 'glitzy_glow'), greaterThan(0));
      expect(lightScreen.remainingTurns, 7);
    });

    test('Aurora Veil fails without active snow or hail', () {
      final result = _runTurn(
        playerMove: _move(
          id: 'aurora_veil',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 0,
          battleEngineMethod: 's_reflect',
          target: PsdkBattleMoveTarget.allAllies,
        ),
        opponentMove: _move(
          id: 'opponent_wait',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 0,
        ),
      );

      expect(
        result.timeline.events.whereType<PsdkBattleMoveFailedEvent>().single,
        isA<PsdkBattleMoveFailedEvent>()
            .having((event) => event.moveId, 'moveId', 'aurora_veil'),
      );
      expect(
        result.state.battlerAt(psdkPlayerSlot).effects.contains('aurora_veil'),
        isFalse,
      );
    });

    test('screen moves fail when the same screen is already active', () {
      final result = _runTurn(
        playerEffects: const PsdkBattleEffectStack.empty().addEffect(
          GenericBattleEffect(
            id: 'reflect',
            scope: BattlerBattleEffectScope(psdkPlayerSlot),
            remainingTurns: 3,
          ),
        ),
        playerMove: _move(
          id: 'reflect',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 0,
          battleEngineMethod: 's_reflect',
          target: PsdkBattleMoveTarget.allAllies,
        ),
        opponentMove: _move(
          id: 'opponent_wait',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 0,
        ),
      );

      expect(
        result.timeline.events.whereType<PsdkBattleMoveFailedEvent>().single,
        isA<PsdkBattleMoveFailedEvent>()
            .having((event) => event.moveId, 'moveId', 'reflect'),
      );
      final reflect = result.state
          .battlerAt(psdkPlayerSlot)
          .effects
          .effects
          .singleWhere((effect) => effect.id == 'reflect');
      expect(reflect.remainingTurns, 2);
    });
  });
}

PsdkBattleTurnResult _runTurn({
  required PsdkBattleMoveData playerMove,
  required PsdkBattleMoveData opponentMove,
  String? playerHeldItemId,
  String? opponentAbilityId,
  PsdkBattleEffectStack playerEffects = const PsdkBattleEffectStack.empty(),
}) {
  final engine = PsdkBattleEngine(
    setup: PsdkBattleSetup.singles(
      player: _combatant(
        id: 'player',
        speed: 100,
        move: playerMove,
        heldItemId: playerHeldItemId,
        effects: playerEffects,
      ),
      opponent: _combatant(
        id: 'opponent',
        speed: 1,
        move: opponentMove,
        abilityId: opponentAbilityId,
      ),
      rngSeeds: const PsdkBattleRngSeeds(
        moveDamage: 1,
        moveCritical: 99999,
        moveAccuracy: 3,
        generic: 0,
      ),
    ),
  );
  return engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  required int speed,
  required PsdkBattleMoveData move,
  String? heldItemId,
  String? abilityId,
  PsdkBattleEffectStack effects = const PsdkBattleEffectStack.empty(),
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 20,
    maxHp: 100,
    currentHp: 100,
    types: const PsdkBattleTypes(primary: 'normal'),
    stats: PsdkBattleStats(
      attack: 50,
      defense: 50,
      specialAttack: 50,
      specialDefense: 50,
      speed: speed,
    ),
    heldItemId: heldItemId,
    abilityId: abilityId,
    moves: <PsdkBattleMoveData>[move],
    effects: effects,
  );
}

PsdkBattleMoveData _move({
  required String id,
  PsdkBattleMoveCategory category = PsdkBattleMoveCategory.physical,
  required int power,
  int accuracy = 100,
  String battleEngineMethod = 's_basic',
  PsdkBattleMoveTarget target = PsdkBattleMoveTarget.adjacentFoe,
}) {
  return PsdkBattleMoveData(
    id: id,
    dbSymbol: id,
    name: id,
    type: 'normal',
    category: category,
    power: power,
    accuracy: accuracy,
    pp: 35,
    priority: 0,
    criticalRate: 1,
    battleEngineMethod: battleEngineMethod,
    target: target,
  );
}

int _damage(
  PsdkBattleTurnResult result, {
  required String moveId,
}) {
  return result.timeline.events
      .whereType<PsdkBattleDamageEvent>()
      .where((event) => event.moveId == moveId)
      .single
      .damage;
}
