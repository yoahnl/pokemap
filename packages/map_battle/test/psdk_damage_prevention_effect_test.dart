import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK damage prevention effects', () {
    test('Protect prevents incoming damage through the damage handler hook',
        () {
      final state = PsdkBattleState.fromSetup(
        _setup(
          opponentEffects: const PsdkBattleEffectStack.empty().addEffect(
            ProtectEffect(scope: BattlerBattleEffectScope(psdkOpponentSlot)),
          ),
        ),
      );

      final result = const BattleDamageHandler().applyDamage(
        context: _context(state: state),
        target: psdkOpponentSlot,
        moveId: 'tackle',
        rawDamage: 30,
        move: _moveDefinition(id: 'tackle', protectable: true),
      );

      final target = result.state.battlerAt(psdkOpponentSlot);
      final failure = result.events.whereType<PsdkBattleMoveFailedEvent>();

      expect(result.applied, isFalse);
      expect(result.reason, BattleMoveFailureReason.protected.jsonName);
      expect(result.amount, 0);
      expect(target.currentHp, 100);
      expect(target.damageHistory.entries, isEmpty);
      expect(failure.single.user, psdkPlayerSlot);
      expect(failure.single.target, psdkOpponentSlot);
      expect(failure.single.moveId, 'tackle');
      expect(failure.single.reason, BattleMoveFailureReason.protected.jsonName);
    });

    test('Substitute absorbs opposing damage from its damage prevention hook',
        () {
      final state = PsdkBattleState.fromSetup(
        _setup(
          opponentEffects: const PsdkBattleEffectStack.empty().addEffect(
            SubstituteEffect(
              scope: BattlerBattleEffectScope(psdkOpponentSlot),
              remainingHp: 25,
            ),
          ),
        ),
      );

      final result = const SubstituteEffect(
        scope: BattlerBattleEffectScope(psdkOpponentSlot),
        remainingHp: 25,
      ).onDamagePrevention(
        BattleEffectDamagePreventionContext(
          state: state,
          rng: _rng(),
          turn: 3,
          owner: psdkOpponentSlot,
          user: psdkPlayerSlot,
          target: psdkOpponentSlot,
          move: _moveDefinition(id: 'tackle', protectable: true),
          damage: 10,
        ),
      );

      final target = result!.state.battlerAt(psdkOpponentSlot);
      final substitute = target.effects.effects.whereType<SubstituteEffect>();
      final damage = result.events.whereType<PsdkBattleDamageEvent>();

      expect(result.prevented, isTrue);
      expect(result.reason, BattleMoveFailureReason.protected);
      expect(target.currentHp, 100);
      expect(substitute.single.remainingHp, 15);
      expect(damage.single.damage, 10);
      expect(damage.single.remainingHp, 100);
    });
  });
}

BattleHandlerContext _context({
  PsdkBattleState? state,
  PsdkBattleSlotRef user = psdkPlayerSlot,
}) {
  return BattleHandlerContext(
    state: state ?? PsdkBattleState.fromSetup(_setup()),
    rng: _rng(),
    turn: 3,
    user: user,
  );
}

PsdkBattleSetup _setup({
  PsdkBattleEffectStack? opponentEffects,
}) {
  return PsdkBattleSetup.singles(
    player: _combatant(id: 'player'),
    opponent: _combatant(id: 'opponent', effects: opponentEffects),
    rngSeeds: const PsdkBattleRngSeeds(
      moveDamage: 1,
      moveCritical: 2,
      moveAccuracy: 3,
      generic: 4,
    ),
  );
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  PsdkBattleEffectStack? effects,
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
    effects: effects,
    moves: <PsdkBattleMoveData>[
      _move(id: 'tackle'),
    ],
  );
}

PsdkBattleMoveData _move({required String id}) {
  return PsdkBattleMoveData(
    id: id,
    dbSymbol: id,
    name: id,
    type: 'normal',
    category: PsdkBattleMoveCategory.physical,
    power: 40,
    accuracy: 100,
    pp: 35,
    priority: 0,
    criticalRate: 1,
    battleEngineMethod: 's_basic',
    target: PsdkBattleMoveTarget.adjacentFoe,
    protectable: true,
  );
}

BattleMoveDefinition _moveDefinition({
  required String id,
  required bool protectable,
}) {
  return BattleMoveDefinition.fromPsdk(
    _move(id: id).copyWith(protectable: protectable),
  );
}

BattleRngStreams _rng() {
  return BattleRngStreams.fromSeeds(
    moveDamageSeed: 1,
    moveCriticalSeed: 2,
    moveAccuracySeed: 3,
    genericSeed: 4,
  );
}
