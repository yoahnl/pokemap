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

    test('Safety Goggles blocks powder moves targeting the holder', () {
      final effect = ItemEffectRegistry()
          .create('safety_goggles', owner: psdkOpponentSlot);

      final blocked = effect!.onMovePreventionTarget(
        BattleEffectMoveContext(
          user: const BattlePositionRef(bank: 0, position: 0),
          target: const BattlePositionRef(bank: 1, position: 0),
          move: _moveDefinition(
            id: 'sleep_powder',
            type: 'grass',
            power: 0,
            flags: const BattleMoveFlags(powder: true),
          ),
        ),
      );
      final nonPowder = effect.onMovePreventionTarget(
        BattleEffectMoveContext(
          user: const BattlePositionRef(bank: 0, position: 0),
          target: const BattlePositionRef(bank: 1, position: 0),
          move: _moveDefinition(id: 'growl', power: 0),
        ),
      );
      final wrongTarget = effect.onMovePreventionTarget(
        BattleEffectMoveContext(
          user: const BattlePositionRef(bank: 1, position: 0),
          target: const BattlePositionRef(bank: 0, position: 0),
          move: _moveDefinition(
            id: 'stun_spore',
            type: 'grass',
            power: 0,
            flags: const BattleMoveFlags(powder: true),
          ),
        ),
      );

      expect(blocked, BattleMoveFailureReason.immunity);
      expect(nonPowder, isNull);
      expect(wrongTarget, isNull);
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

    test('Berserk Gene raises Attack, consumes, and confuses on switch-in', () {
      final result = _dispatchSwitchIn(opponentHeldItemId: 'berserk_gene');
      final opponent = result.state.battlerAt(psdkOpponentSlot);
      final confusion =
          opponent.effects.effects.whereType<ConfusionEffect>().single;

      expect(opponent.statStages.valueOf('attack'), 2);
      expect(opponent.heldItemId, isNull);
      expect(opponent.consumedItemId, 'berserk_gene');
      expect(confusion.remainingConfusionTurns, 256);
      expect(_itemEvents(result).single.itemId, 'berserk_gene');
      expect(_statEvents(result).single.stat, 'attack');
      expect(_effectEvents(result).single.effectId, 'confusion');
    });

    test('Berserk Gene keeps existing confusion duration on switch-in', () {
      final result = _dispatchSwitchIn(
        opponentHeldItemId: 'berserk_gene',
        opponentEffects: PsdkBattleEffectStack(
          effects: <BattleEffect>[
            ConfusionEffect(
              scope: BattlerBattleEffectScope(psdkOpponentSlot),
              remainingConfusionTurns: 3,
            ),
          ],
        ),
      );
      final opponent = result.state.battlerAt(psdkOpponentSlot);
      final confusion =
          opponent.effects.effects.whereType<ConfusionEffect>().single;

      expect(opponent.statStages.valueOf('attack'), 2);
      expect(opponent.consumedItemId, 'berserk_gene');
      expect(confusion.remainingConfusionTurns, 3);
    });

    test('type-reactive stat items consume after matching damage', () {
      final cases = <({
        String itemId,
        String moveId,
        String moveType,
        String stat,
      })>[
        (
          itemId: 'absorb_bulb',
          moveId: 'water_gun',
          moveType: 'water',
          stat: 'specialAttack',
        ),
        (
          itemId: 'cell_battery',
          moveId: 'thunder_shock',
          moveType: 'electric',
          stat: 'attack',
        ),
        (
          itemId: 'luminous_moss',
          moveId: 'water_pulse',
          moveType: 'water',
          stat: 'specialDefense',
        ),
        (
          itemId: 'snowball',
          moveId: 'ice_shard',
          moveType: 'ice',
          stat: 'attack',
        ),
      ];

      for (final current in cases) {
        final result = _damageOpponent(
          opponentHeldItemId: current.itemId,
          rawDamage: 20,
          move: _move(
            id: current.moveId,
            type: current.moveType,
            power: 40,
          ),
        );
        final opponent = result.state.battlerAt(psdkOpponentSlot);

        expect(opponent.heldItemId, isNull, reason: current.itemId);
        expect(opponent.consumedItemId, current.itemId, reason: current.itemId);
        expect(opponent.statStages.valueOf(current.stat), 1,
            reason: current.itemId);
        expect(_itemEvents(result).single.itemId, current.itemId,
            reason: current.itemId);
        expect(_statEvents(result).single.stat, current.stat,
            reason: current.itemId);
      }
    });

    test('type-reactive stat items ignore wrong type and suppressed item', () {
      final wrongType = _damageOpponent(
        opponentHeldItemId: 'absorb_bulb',
        rawDamage: 20,
        move: _move(id: 'ember', type: 'fire', power: 40),
      );
      final suppressed = _damageOpponent(
        opponentHeldItemId: 'absorb_bulb',
        opponentEffects: PsdkBattleEffectStack(
          values: const <String>['magic_room'],
        ),
        rawDamage: 20,
        move: _move(id: 'water_gun', type: 'water', power: 40),
      );

      expect(wrongType.state.battlerAt(psdkOpponentSlot).heldItemId,
          'absorb_bulb');
      expect(
        wrongType.state
            .battlerAt(psdkOpponentSlot)
            .statStages
            .valueOf('specialAttack'),
        0,
      );
      expect(_itemEvents(wrongType), isEmpty);
      expect(suppressed.state.battlerAt(psdkOpponentSlot).heldItemId,
          'absorb_bulb');
      expect(
        suppressed.state
            .battlerAt(psdkOpponentSlot)
            .statStages
            .valueOf('specialAttack'),
        0,
      );
      expect(_itemEvents(suppressed), isEmpty);
    });

    test('type-reactive stat items require the holder to survive', () {
      final result = _damageOpponent(
        opponentHeldItemId: 'snowball',
        rawDamage: 120,
        move: _move(id: 'ice_shard', type: 'ice', power: 40),
      );
      final opponent = result.state.battlerAt(psdkOpponentSlot);

      expect(opponent.currentHp, 0);
      expect(opponent.heldItemId, 'snowball');
      expect(opponent.statStages.valueOf('attack'), 0);
      expect(_itemEvents(result), isEmpty);
    });

    test('Weakness Policy consumes after super-effective damage', () {
      final result = _damageOpponent(
        opponentHeldItemId: 'weakness_policy',
        opponentTypes: const PsdkBattleTypes(primary: 'grass'),
        rawDamage: 20,
        move: _move(id: 'ember', type: 'fire', power: 40),
      );
      final opponent = result.state.battlerAt(psdkOpponentSlot);
      final stats = _statEvents(result);

      expect(opponent.heldItemId, isNull);
      expect(opponent.consumedItemId, 'weakness_policy');
      expect(opponent.statStages.valueOf('attack'), 2);
      expect(opponent.statStages.valueOf('specialAttack'), 2);
      expect(_itemEvents(result).single.itemId, 'weakness_policy');
      expect(stats.map((event) => event.stat), <String>[
        'attack',
        'specialAttack',
      ]);
      expect(stats.map((event) => event.amount), <int>[2, 2]);
    });

    test('Weakness Policy ignores neutral damage', () {
      final result = _damageOpponent(
        opponentHeldItemId: 'weakness_policy',
        rawDamage: 20,
        move: _move(id: 'tackle', type: 'normal', power: 40),
      );
      final opponent = result.state.battlerAt(psdkOpponentSlot);

      expect(opponent.heldItemId, 'weakness_policy');
      expect(opponent.statStages.valueOf('attack'), 0);
      expect(opponent.statStages.valueOf('specialAttack'), 0);
      expect(_itemEvents(result), isEmpty);
      expect(_statEvents(result), isEmpty);
    });

    test('Rocky Helmet damages a contact attacker without consuming itself',
        () {
      final result = _damageOpponent(
        opponentHeldItemId: 'rocky_helmet',
        rawDamage: 20,
        moveDefinition: _moveDefinition(
          id: 'scratch',
          type: 'normal',
          power: 40,
          flags: const BattleMoveFlags(contact: true),
        ),
      );
      final player = result.state.battlerAt(psdkPlayerSlot);
      final opponent = result.state.battlerAt(psdkOpponentSlot);
      final damages = _damageEvents(result);

      expect(player.currentHp, 84);
      expect(opponent.heldItemId, 'rocky_helmet');
      expect(opponent.itemConsumed, isFalse);
      expect(damages.map((event) => event.moveId), <String>[
        'scratch',
        'item:rocky_helmet',
      ]);
      expect(damages.last.damage, 16);
    });

    test('Rocky Helmet can trigger after fatal contact damage', () {
      final result = _damageOpponent(
        opponentHeldItemId: 'rocky_helmet',
        rawDamage: 120,
        moveDefinition: _moveDefinition(
          id: 'scratch',
          type: 'normal',
          power: 40,
          flags: const BattleMoveFlags(contact: true),
        ),
      );

      expect(result.state.battlerAt(psdkOpponentSlot).currentHp, 0);
      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 84);
      expect(_damageEvents(result).last.moveId, 'item:rocky_helmet');
    });

    test('Rocky Helmet ignores non-contact moves', () {
      final result = _damageOpponent(
        opponentHeldItemId: 'rocky_helmet',
        rawDamage: 20,
        move: _move(id: 'swift', type: 'normal', power: 40),
      );

      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 100);
      expect(_damageEvents(result).map((event) => event.moveId),
          <String>['swift']);
    });

    test('Sticky Barb transfers to an itemless contact attacker', () {
      final result = _damageOpponent(
        opponentHeldItemId: 'sticky_barb',
        rawDamage: 20,
        moveDefinition: _moveDefinition(
          id: 'scratch',
          type: 'normal',
          power: 40,
          flags: const BattleMoveFlags(contact: true),
        ),
      );
      final player = result.state.battlerAt(psdkPlayerSlot);
      final opponent = result.state.battlerAt(psdkOpponentSlot);

      expect(player.heldItemId, 'sticky_barb');
      expect(player.itemConsumed, isFalse);
      expect(opponent.heldItemId, isNull);
      expect(opponent.itemConsumed, isFalse);
      expect(_damageEvents(result).map((event) => event.moveId),
          <String>['scratch']);
    });

    test('Sticky Barb does not transfer to an attacker already holding an item',
        () {
      final result = _damageOpponent(
        playerHeldItemId: 'leftovers',
        opponentHeldItemId: 'sticky_barb',
        rawDamage: 20,
        moveDefinition: _moveDefinition(
          id: 'scratch',
          type: 'normal',
          power: 40,
          flags: const BattleMoveFlags(contact: true),
        ),
      );

      expect(result.state.battlerAt(psdkPlayerSlot).heldItemId, 'leftovers');
      expect(
          result.state.battlerAt(psdkOpponentSlot).heldItemId, 'sticky_barb');
    });

    test('Sticky Barb can transfer after fatal contact damage', () {
      final result = _damageOpponent(
        opponentHeldItemId: 'sticky_barb',
        rawDamage: 120,
        moveDefinition: _moveDefinition(
          id: 'scratch',
          type: 'normal',
          power: 40,
          flags: const BattleMoveFlags(contact: true),
        ),
      );

      expect(result.state.battlerAt(psdkOpponentSlot).currentHp, 0);
      expect(result.state.battlerAt(psdkOpponentSlot).heldItemId, isNull);
      expect(result.state.battlerAt(psdkPlayerSlot).heldItemId, 'sticky_barb');
    });

    test('Sticky Barb damages holders at end turn and respects Magic Guard',
        () {
      final damaged = _tickOpponentEndTurn(opponentHeldItemId: 'sticky_barb');
      final guarded = _tickOpponentEndTurn(
        opponentHeldItemId: 'sticky_barb',
        opponentAbilityId: 'magic_guard',
      );

      expect(damaged.state.battlerAt(psdkOpponentSlot).currentHp, 88);
      expect(_damageEvents(damaged).single.moveId, 'item:sticky_barb');
      expect(_damageEvents(damaged).single.damage, 12);
      expect(guarded.state.battlerAt(psdkOpponentSlot).currentHp, 100);
      expect(_damageEvents(guarded), isEmpty);
    });

    test('White Herb clears negative stat stages after a stat drop', () {
      final setup = _state(
        opponentHeldItemId: 'white_herb',
        opponentCurrentHp: 100,
        opponentStatStages: PsdkBattleStatStages(
          values: const <String, int>{
            'attack': 2,
            'defense': -2,
            'specialDefense': -1,
          },
        ),
      );

      final result = const BattleStatChangeHandler().applyStatChange(
        context: BattleHandlerContext(
          state: setup,
          rng: BattleRngStreams.fromSeedSnapshot(
            const BattleRngSeeds(
              moveDamage: 1,
              moveCritical: 99999,
              moveAccuracy: 3,
              generic: 4,
            ),
          ),
          turn: 4,
          user: psdkPlayerSlot,
        ),
        target: psdkOpponentSlot,
        stat: 'speed',
        stages: -1,
      );
      final opponent = result.state.battlerAt(psdkOpponentSlot);

      expect(opponent.statStages.valueOf('attack'), 2);
      expect(opponent.statStages.valueOf('defense'), 0);
      expect(opponent.statStages.valueOf('specialDefense'), 0);
      expect(opponent.statStages.valueOf('speed'), 0);
      expect(opponent.heldItemId, isNull);
      expect(opponent.consumedItemId, 'white_herb');
      expect(_itemEvents(result).single.itemId, 'white_herb');
    });

    test('King Rock and Razor Fang can flinch after qualifying damage', () {
      final kingRock = _damageOpponent(
        playerHeldItemId: 'king_s_rock',
        opponentHeldItemId: 'leftovers',
        rawDamage: 20,
        genericSeed: 0,
        moveDefinition: _moveDefinition(
          id: 'rock_slide',
          power: 75,
          flags: const BattleMoveFlags(kingRockUtility: true),
        ),
      );
      final razorFang = _damageOpponent(
        playerHeldItemId: 'razor_fang',
        opponentHeldItemId: 'leftovers',
        rawDamage: 20,
        genericSeed: 0,
        moveDefinition: _moveDefinition(
          id: 'bite',
          power: 60,
          flags: const BattleMoveFlags(kingRockUtility: true),
        ),
      );

      expect(
        kingRock.state.battlerAt(psdkOpponentSlot).effects.contains('flinch'),
        isTrue,
      );
      expect(
        razorFang.state.battlerAt(psdkOpponentSlot).effects.contains('flinch'),
        isTrue,
      );
      expect(_effectEvents(kingRock).single.reason, 'item:king_s_rock');
      expect(_effectEvents(razorFang).single.reason, 'item:razor_fang');
      expect(
          kingRock.state.battlerAt(psdkPlayerSlot).heldItemId, 'king_s_rock');
      expect(
          razorFang.state.battlerAt(psdkPlayerSlot).heldItemId, 'razor_fang');
    });

    test('King Rock requires utility flag, chance, and flinchable target', () {
      final noUtility = _damageOpponent(
        playerHeldItemId: 'king_s_rock',
        opponentHeldItemId: 'leftovers',
        rawDamage: 20,
        genericSeed: 0,
        moveDefinition: _moveDefinition(id: 'tackle', power: 40),
      );
      final missedRoll = _damageOpponent(
        playerHeldItemId: 'king_s_rock',
        opponentHeldItemId: 'leftovers',
        rawDamage: 20,
        genericSeed: 9,
        moveDefinition: _moveDefinition(
          id: 'rock_slide',
          power: 75,
          flags: const BattleMoveFlags(kingRockUtility: true),
        ),
      );
      final innerFocus = _damageOpponent(
        playerHeldItemId: 'king_s_rock',
        opponentHeldItemId: 'leftovers',
        opponentAbilityId: 'inner_focus',
        rawDamage: 20,
        genericSeed: 0,
        moveDefinition: _moveDefinition(
          id: 'rock_slide',
          power: 75,
          flags: const BattleMoveFlags(kingRockUtility: true),
        ),
      );

      expect(
        noUtility.state.battlerAt(psdkOpponentSlot).effects.contains('flinch'),
        isFalse,
      );
      expect(
        missedRoll.state.battlerAt(psdkOpponentSlot).effects.contains('flinch'),
        isFalse,
      );
      expect(
        innerFocus.state.battlerAt(psdkOpponentSlot).effects.contains('flinch'),
        isFalse,
      );
      expect(_effectEvents(noUtility), isEmpty);
      expect(_effectEvents(missedRoll), isEmpty);
      expect(_effectEvents(innerFocus), isEmpty);
    });

    test('Shell Bell heals the damaging holder for one eighth of damage', () {
      final result = _damageOpponent(
        playerHeldItemId: 'shell_bell',
        playerCurrentHp: 50,
        opponentHeldItemId: 'leftovers',
        rawDamage: 40,
        move: _move(id: 'scratch', type: 'normal', power: 40),
      );
      final player = result.state.battlerAt(psdkPlayerSlot);
      final heals = _healEvents(result);

      expect(player.currentHp, 55);
      expect(player.heldItemId, 'shell_bell');
      expect(player.itemConsumed, isFalse);
      expect(heals.single.moveId, 'item:shell_bell');
      expect(heals.single.amount, 5);
      expect(heals.single.remainingHp, 55);
    });

    test('Shell Bell ignores chip damage below eight HP', () {
      final result = _damageOpponent(
        playerHeldItemId: 'shell_bell',
        playerCurrentHp: 50,
        opponentHeldItemId: 'leftovers',
        rawDamage: 7,
        move: _move(id: 'scratch', type: 'normal', power: 40),
      );

      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 50);
      expect(_healEvents(result), isEmpty);
    });
  });
}

BattleHandlerResult _damageOpponent({
  required String opponentHeldItemId,
  required int rawDamage,
  String? playerHeldItemId,
  int playerCurrentHp = 100,
  int opponentCurrentHp = 100,
  PsdkBattleTypes opponentTypes = const PsdkBattleTypes(primary: 'normal'),
  PsdkBattleEffectStack? opponentEffects,
  String? opponentAbilityId,
  PsdkBattleMoveData? move,
  BattleMoveDefinition? moveDefinition,
  int genericSeed = 4,
}) {
  final resolvedMove = moveDefinition ??
      BattleMoveDefinition.fromPsdk(
        move ?? _move(id: 'tackle', power: 80),
      );
  return const BattleDamageHandler().applyDamage(
    context: BattleHandlerContext(
      state: _state(
        playerHeldItemId: playerHeldItemId,
        playerCurrentHp: playerCurrentHp,
        opponentHeldItemId: opponentHeldItemId,
        opponentCurrentHp: opponentCurrentHp,
        opponentAbilityId: opponentAbilityId,
        opponentTypes: opponentTypes,
        opponentEffects: opponentEffects,
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
    moveId: resolvedMove.id,
    rawDamage: rawDamage,
    move: resolvedMove,
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

BattleHandlerResult _dispatchSwitchIn({
  required String opponentHeldItemId,
  PsdkBattleEffectStack? opponentEffects,
}) {
  return const BattleSwitchHandler().dispatchSwitchEvents(
    context: BattleHandlerContext(
      state: _state(
        opponentHeldItemId: opponentHeldItemId,
        opponentCurrentHp: 100,
        opponentEffects: opponentEffects,
      ),
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
    who: psdkPlayerSlot,
    replacement: psdkOpponentSlot,
  );
}

PsdkBattleState _state({
  required String opponentHeldItemId,
  String? playerHeldItemId,
  int playerCurrentHp = 100,
  required int opponentCurrentHp,
  String? opponentAbilityId,
  PsdkBattleTypes opponentTypes = const PsdkBattleTypes(primary: 'normal'),
  PsdkBattleEffectStack? opponentEffects,
  PsdkBattleStatStages? opponentStatStages,
}) {
  return PsdkBattleState.fromSetup(
    BattleEngineSetup.singles(
      player: _combatant(
        id: 'player',
        heldItemId: playerHeldItemId,
        currentHp: playerCurrentHp,
        move: _move(id: 'tackle', power: 80),
      ),
      opponent: _combatant(
        id: 'opponent',
        heldItemId: opponentHeldItemId,
        abilityId: opponentAbilityId,
        currentHp: opponentCurrentHp,
        types: opponentTypes,
        effects: opponentEffects,
        statStages: opponentStatStages,
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
  PsdkBattleTypes types = const PsdkBattleTypes(primary: 'normal'),
  PsdkBattleEffectStack? effects,
  PsdkBattleStatStages? statStages,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 20,
    maxHp: 100,
    currentHp: currentHp,
    types: types,
    stats: const PsdkBattleStats(
      attack: 50,
      defense: 50,
      specialAttack: 50,
      specialDefense: 50,
      speed: 50,
    ),
    abilityId: abilityId,
    heldItemId: heldItemId,
    effects: effects,
    statStages: statStages,
    moves: <PsdkBattleMoveData>[move],
  );
}

PsdkBattleMoveData _move({
  required String id,
  String type = 'normal',
  required int power,
}) {
  return PsdkBattleMoveData(
    id: id,
    dbSymbol: id,
    name: id,
    type: type,
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
    sound: false,
  );
}

BattleMoveDefinition _moveDefinition({
  required String id,
  String type = 'normal',
  required int power,
  BattleMoveFlags flags = const BattleMoveFlags(),
}) {
  return BattleMoveDefinition(
    id: id,
    dbSymbol: id,
    name: id,
    type: type,
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
    flags: flags,
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

List<PsdkBattleEffectEvent> _effectEvents(BattleHandlerResult result) {
  return result.events
      .whereType<PsdkBattleEffectEvent>()
      .toList(growable: false);
}

List<PsdkBattleDamageEvent> _damageEvents(BattleHandlerResult result) {
  return result.events
      .whereType<PsdkBattleDamageEvent>()
      .toList(growable: false);
}

List<PsdkBattleHealEvent> _healEvents(BattleHandlerResult result) {
  return result.events.whereType<PsdkBattleHealEvent>().toList(growable: false);
}
