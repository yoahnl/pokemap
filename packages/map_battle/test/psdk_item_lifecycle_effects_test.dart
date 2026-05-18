import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK held item lifecycle effects', () {
    test('Focus Sash leaves a full-HP holder at 1 HP and consumes itself', () {
      final result = _damageOpponent(
        opponentHeldItemId: 'focus_sash',
        rawDamage: 120,
      );
      final opponent = result.state.battlerAt(psdkOpponentSlot);

      expect(result.amount, 99);
      expect(opponent.currentHp, 1);
      expect(opponent.heldItemId, isNull);
      expect(opponent.consumedItemId, 'focus_sash');
      expect(opponent.itemConsumed, isTrue);
      expect(_itemEvents(result).single.itemId, 'focus_sash');
    });

    test('Focus Sash does not trigger away from full HP', () {
      final result = _damageOpponent(
        opponentHeldItemId: 'focus_sash',
        opponentCurrentHp: 80,
        rawDamage: 120,
      );
      final opponent = result.state.battlerAt(psdkOpponentSlot);

      expect(result.amount, 80);
      expect(opponent.currentHp, 0);
      expect(opponent.heldItemId, 'focus_sash');
      expect(opponent.consumedItemId, isNull);
      expect(_itemEvents(result), isEmpty);
    });

    test('Focus Band can leave the holder at 1 HP without consuming itself',
        () {
      final result = _damageOpponent(
        opponentHeldItemId: 'focus_band',
        rawDamage: 120,
        genericSeed: 0,
      );
      final opponent = result.state.battlerAt(psdkOpponentSlot);

      expect(result.amount, 99);
      expect(opponent.currentHp, 1);
      expect(opponent.heldItemId, 'focus_band');
      expect(opponent.consumedItemId, isNull);
      expect(_itemEvents(result), isEmpty);
    });

    test('Focus Band does not trigger when its 10 percent roll fails', () {
      final result = _damageOpponent(
        opponentHeldItemId: 'focus_band',
        rawDamage: 120,
        genericSeed: 9,
      );
      final opponent = result.state.battlerAt(psdkOpponentSlot);

      expect(result.amount, 100);
      expect(opponent.currentHp, 0);
      expect(opponent.heldItemId, 'focus_band');
      expect(opponent.consumedItemId, isNull);
    });

    test('Flame Orb and Toxic Orb apply their status at end turn', () {
      final flame = _tickOpponentEndTurn(opponentHeldItemId: 'flame_orb');
      final toxic = _tickOpponentEndTurn(opponentHeldItemId: 'toxic_orb');

      expect(
        flame.state.battlerAt(psdkOpponentSlot).majorStatus,
        PsdkBattleMajorStatus.burn,
      );
      expect(flame.state.battlerAt(psdkOpponentSlot).heldItemId, 'flame_orb');
      expect(_statusEvents(flame).single.moveId, 'item:flame_orb');
      expect(
        toxic.state.battlerAt(psdkOpponentSlot).majorStatus,
        PsdkBattleMajorStatus.toxic,
      );
      expect(toxic.state.battlerAt(psdkOpponentSlot).heldItemId, 'toxic_orb');
      expect(_statusEvents(toxic).single.moveId, 'item:toxic_orb');
    });

    test('Flame Orb and Toxic Orb skip Magic Guard holders', () {
      final flame = _tickOpponentEndTurn(
        opponentHeldItemId: 'flame_orb',
        opponentAbilityId: 'magic_guard',
      );
      final toxic = _tickOpponentEndTurn(
        opponentHeldItemId: 'toxic_orb',
        opponentAbilityId: 'magic_guard',
      );

      expect(flame.state.battlerAt(psdkOpponentSlot).majorStatus, isNull);
      expect(toxic.state.battlerAt(psdkOpponentSlot).majorStatus, isNull);
      expect(_statusEvents(flame), isEmpty);
      expect(_statusEvents(toxic), isEmpty);
    });

    test('terrain seeds consume after matching terrain is set', () {
      final electric = _changeTerrain(
        opponentHeldItemId: 'electric_seed',
        terrain: PsdkBattleTerrainId.electricTerrain,
      );
      final misty = _changeTerrain(
        opponentHeldItemId: 'misty_seed',
        terrain: PsdkBattleTerrainId.mistyTerrain,
      );

      expect(
        electric.state
            .battlerAt(psdkOpponentSlot)
            .statStages
            .valueOf('defense'),
        1,
      );
      expect(
        electric.state.battlerAt(psdkOpponentSlot).heldItemId,
        isNull,
      );
      expect(_itemEvents(electric).single.itemId, 'electric_seed');
      expect(_statEvents(electric).single.stat, 'defense');
      expect(
        misty.state
            .battlerAt(psdkOpponentSlot)
            .statStages
            .valueOf('specialDefense'),
        1,
      );
      expect(misty.state.battlerAt(psdkOpponentSlot).heldItemId, isNull);
      expect(_itemEvents(misty).single.itemId, 'misty_seed');
      expect(_statEvents(misty).single.stat, 'specialDefense');
    });

    test('terrain seeds trigger when switching into matching terrain', () {
      final grassy = _dispatchSwitchIntoTerrain(
        opponentHeldItemId: 'grassy_seed',
        terrain: PsdkBattleTerrainId.grassyTerrain,
      );
      final psychic = _dispatchSwitchIntoTerrain(
        opponentHeldItemId: 'psychic_seed',
        terrain: PsdkBattleTerrainId.psychicTerrain,
      );

      expect(
        grassy.state.battlerAt(psdkOpponentSlot).statStages.valueOf('defense'),
        1,
      );
      expect(grassy.state.battlerAt(psdkOpponentSlot).heldItemId, isNull);
      expect(_itemEvents(grassy).single.itemId, 'grassy_seed');
      expect(_statEvents(grassy).single.stat, 'defense');
      expect(
        psychic.state
            .battlerAt(psdkOpponentSlot)
            .statStages
            .valueOf('specialDefense'),
        1,
      );
      expect(psychic.state.battlerAt(psdkOpponentSlot).heldItemId, isNull);
      expect(_itemEvents(psychic).single.itemId, 'psychic_seed');
      expect(_statEvents(psychic).single.stat, 'specialDefense');
    });

    test('terrain seeds ignore non-matching terrain', () {
      final result = _changeTerrain(
        opponentHeldItemId: 'electric_seed',
        terrain: PsdkBattleTerrainId.mistyTerrain,
      );
      final opponent = result.state.battlerAt(psdkOpponentSlot);

      expect(opponent.statStages.valueOf('defense'), 0);
      expect(opponent.heldItemId, 'electric_seed');
      expect(opponent.consumedItemId, isNull);
      expect(_itemEvents(result), isEmpty);
      expect(_statEvents(result), isEmpty);
    });
  });
}

BattleHandlerResult _damageOpponent({
  required String opponentHeldItemId,
  required int rawDamage,
  int opponentCurrentHp = 100,
  int genericSeed = 4,
}) {
  return const BattleDamageHandler().applyDamage(
    context: BattleHandlerContext(
      state: _state(
        opponentHeldItemId: opponentHeldItemId,
        opponentCurrentHp: opponentCurrentHp,
      ),
      rng: BattleRngStreams.fromSeedSnapshot(
        BattleRngSeeds(
          moveDamage: 1,
          moveCritical: 99999,
          moveAccuracy: 3,
          generic: genericSeed,
        ),
      ),
      turn: 1,
      user: psdkPlayerSlot,
    ),
    target: psdkOpponentSlot,
    moveId: 'tackle',
    rawDamage: rawDamage,
    move: BattleMoveDefinition.fromPsdk(_move(id: 'tackle', power: 80)),
  );
}

BattleHandlerResult _tickOpponentEndTurn({
  required String opponentHeldItemId,
  String? opponentAbilityId,
}) {
  return const BattleEndTurnHandler().resolveEndTurn(
    BattleHandlerContext(
      state: _state(
        opponentHeldItemId: opponentHeldItemId,
        opponentCurrentHp: 100,
        opponentAbilityId: opponentAbilityId,
      ),
      rng: BattleRngStreams.fromSeedSnapshot(
        const BattleRngSeeds(
          moveDamage: 1,
          moveCritical: 99999,
          moveAccuracy: 3,
          generic: 4,
        ),
      ),
      turn: 2,
      user: psdkOpponentSlot,
    ),
  );
}

BattleHandlerResult _changeTerrain({
  required String opponentHeldItemId,
  required PsdkBattleTerrainId terrain,
}) {
  return const BattleTerrainChangeHandler().changeTerrain(
    context: BattleHandlerContext(
      state: _state(
        opponentHeldItemId: opponentHeldItemId,
        opponentCurrentHp: 100,
      ),
      rng: BattleRngStreams.fromSeedSnapshot(
        const BattleRngSeeds(
          moveDamage: 1,
          moveCritical: 99999,
          moveAccuracy: 3,
          generic: 4,
        ),
      ),
      turn: 3,
      user: psdkPlayerSlot,
    ),
    terrain: terrain,
  );
}

BattleHandlerResult _dispatchSwitchIntoTerrain({
  required String opponentHeldItemId,
  required PsdkBattleTerrainId terrain,
}) {
  final state = _state(
    opponentHeldItemId: opponentHeldItemId,
    opponentCurrentHp: 100,
  ).copyWith(
    field: const PsdkBattleFieldState().withTerrain(terrain),
  );
  return const BattleSwitchHandler().dispatchSwitchEvents(
    context: BattleHandlerContext(
      state: state,
      rng: BattleRngStreams.fromSeedSnapshot(
        const BattleRngSeeds(
          moveDamage: 1,
          moveCritical: 99999,
          moveAccuracy: 3,
          generic: 4,
        ),
      ),
      turn: 4,
      user: psdkOpponentSlot,
    ),
    who: psdkOpponentSlot,
    replacement: psdkOpponentSlot,
  );
}

PsdkBattleState _state({
  required String opponentHeldItemId,
  required int opponentCurrentHp,
  String? opponentAbilityId,
}) {
  return PsdkBattleState.fromSetup(
    BattleEngineSetup.singles(
      player: _combatant(
        id: 'player',
        move: _move(id: 'tackle', power: 80),
      ),
      opponent: _combatant(
        id: 'opponent',
        heldItemId: opponentHeldItemId,
        abilityId: opponentAbilityId,
        currentHp: opponentCurrentHp,
        move: _move(id: 'splash', power: 0),
      ),
      rngSeeds: const BattleRngSeeds(
        moveDamage: 1,
        moveCritical: 99999,
        moveAccuracy: 3,
        generic: 4,
      ).psdkSeeds,
    ).psdkSetup,
  );
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  required PsdkBattleMoveData move,
  String? heldItemId,
  String? abilityId,
  int currentHp = 100,
}) {
  return PsdkBattleCombatantSetup(
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
    abilityId: abilityId,
    heldItemId: heldItemId,
    moves: <PsdkBattleMoveData>[move],
  );
}

PsdkBattleMoveData _move({
  required String id,
  required int power,
}) {
  return PsdkBattleMoveData(
    id: id,
    dbSymbol: id,
    name: id,
    type: 'normal',
    category: power > 0
        ? PsdkBattleMoveCategory.physical
        : PsdkBattleMoveCategory.status,
    power: power,
    accuracy: 100,
    pp: 35,
    priority: 0,
    criticalRate: 1,
    battleEngineMethod: power > 0 ? 's_basic' : 's_splash',
    target: PsdkBattleMoveTarget.adjacentFoe,
  );
}

List<PsdkBattleItemEvent> _itemEvents(BattleHandlerResult result) {
  return result.events.whereType<PsdkBattleItemEvent>().toList(growable: false);
}

List<PsdkBattleStatusEvent> _statusEvents(BattleHandlerResult result) {
  return result.events
      .whereType<PsdkBattleStatusEvent>()
      .toList(growable: false);
}

List<PsdkBattleStatStageEvent> _statEvents(BattleHandlerResult result) {
  return result.events
      .whereType<PsdkBattleStatStageEvent>()
      .toList(growable: false);
}
