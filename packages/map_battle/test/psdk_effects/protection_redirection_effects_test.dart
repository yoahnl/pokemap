import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK protection and redirection effects', () {
    test('King Shield blocks contact damage and lowers attacker Attack', () {
      final result = const BattleDamageHandler().applyDamage(
        context: BattleHandlerContext(
          state: _state(
            playerEffects: PsdkBattleEffectStack(
              effects: <BattleEffect>[
                KingsShieldEffect(
                    scope: BattlerBattleEffectScope(psdkPlayerSlot)),
              ],
            ),
          ),
          rng: _rng(),
          turn: 1,
          user: psdkOpponentSlot,
        ),
        target: psdkPlayerSlot,
        moveId: 'contact_hit',
        rawDamage: 40,
        move: _move(id: 'contact_hit', contact: true),
      );

      expect(result.applied, isFalse);
      expect(result.reason, 'protected');
      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 40);
      expect(
        result.state.battlerAt(psdkOpponentSlot).statStages.valueOf('attack'),
        -1,
      );
      expect(
        result.events.map((event) => event.kind),
        containsAllInOrder(<String>['move_failed', 'stat_stage_change']),
      );
    });

    test('King Shield lets status moves through like Pokemon SDK', () {
      const effect = KingsShieldEffect(
        scope: BattlerBattleEffectScope(psdkPlayerSlot),
      );

      final reason = effect.onMovePreventionTarget(
        BattleEffectMoveContext(
          user: const BattlePositionRef(bank: 1, position: 0),
          target: const BattlePositionRef(bank: 0, position: 0),
          move: _move(
            id: 'growl',
            category: PsdkBattleMoveCategory.status,
            power: 0,
            contact: false,
          ),
        ),
      );

      expect(reason, isNull);
    });

    test('Spiky Shield damages a contact attacker for one eighth max HP', () {
      final result = const BattleDamageHandler().applyDamage(
        context: BattleHandlerContext(
          state: _state(
            playerEffects: PsdkBattleEffectStack(
              effects: <BattleEffect>[
                SpikyShieldEffect(
                    scope: BattlerBattleEffectScope(psdkPlayerSlot)),
              ],
            ),
          ),
          rng: _rng(),
          turn: 1,
          user: psdkOpponentSlot,
        ),
        target: psdkPlayerSlot,
        moveId: 'contact_hit',
        rawDamage: 40,
        move: _move(id: 'contact_hit', contact: true),
      );

      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 40);
      expect(result.state.battlerAt(psdkOpponentSlot).currentHp, 35);
      expect(
        result.events.map((event) => event.kind),
        containsAllInOrder(<String>['move_failed', 'damage']),
      );
    });

    test('Baneful Bunker poisons a contact attacker', () {
      final result = const BattleDamageHandler().applyDamage(
        context: BattleHandlerContext(
          state: _state(
            playerEffects: PsdkBattleEffectStack(
              effects: <BattleEffect>[
                BanefulBunkerEffect(
                  scope: BattlerBattleEffectScope(psdkPlayerSlot),
                ),
              ],
            ),
          ),
          rng: _rng(),
          turn: 1,
          user: psdkOpponentSlot,
        ),
        target: psdkPlayerSlot,
        moveId: 'contact_hit',
        rawDamage: 40,
        move: _move(id: 'contact_hit', contact: true),
      );

      expect(
        result.state.battlerAt(psdkOpponentSlot).majorStatus,
        PsdkBattleMajorStatus.poison,
      );
      expect(
        result.events.map((event) => event.kind),
        containsAllInOrder(<String>['move_failed', 'status']),
      );
    });
  });
}

PsdkBattleState _state({
  PsdkBattleEffectStack? playerEffects,
}) {
  return PsdkBattleState.fromSetup(
    BattleEngineSetup.singles(
      player: _combatant('player', effects: playerEffects),
      opponent: _combatant('opponent'),
      rngSeeds: const PsdkBattleRngSeeds(
        moveDamage: 1,
        moveCritical: 2,
        moveAccuracy: 3,
        generic: 4,
      ),
    ).psdkSetup,
  );
}

PsdkBattleCombatantSetup _combatant(
  String id, {
  PsdkBattleEffectStack? effects,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 10,
    maxHp: 40,
    currentHp: 40,
    types: const PsdkBattleTypes(primary: 'normal'),
    stats: const PsdkBattleStats(
      attack: 50,
      defense: 50,
      specialAttack: 50,
      specialDefense: 50,
      speed: 50,
    ),
    moves: <PsdkBattleMoveData>[_move(id: '${id}_move').psdkMove],
    effects: effects,
  );
}

BattleMoveDefinition _move({
  required String id,
  PsdkBattleMoveCategory category = PsdkBattleMoveCategory.physical,
  int power = 40,
  bool contact = false,
}) {
  return BattleMoveDefinition(
    id: id,
    dbSymbol: id,
    name: id,
    type: 'normal',
    category: category,
    power: power,
    accuracy: 100,
    pp: 10,
    priority: 0,
    battleEngineMethod: 's_basic',
    target: PsdkBattleMoveTarget.adjacentFoe,
    flags: BattleMoveFlags(contact: contact),
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
