import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK item effects', () {
    test('hydrates known held item ids into the battler effect stack', () {
      final state = PsdkBattleState.fromSetup(
        BattleEngineSetup.singles(
          player: _combatant(
            id: 'player',
            heldItemId: 'loaded_dice',
            move: _move(id: 'tackle', power: 40),
          ),
          opponent: _combatant(
            id: 'opponent',
            move: _move(id: 'tackle', power: 40),
          ),
          rngSeeds: _seeds.psdkSeeds,
        ).psdkSetup,
      );

      final battler = state.battlerAt(psdkPlayerSlot);
      expect(battler.heldItemId, 'loaded_dice');
      expect(battler.effects.contains('item:loaded_dice'), isTrue);
    });

    test('Air Balloon and Iron Ball affect grounding through item effects', () {
      const resolver = BattleGroundingResolver();
      final state = PsdkBattleState.fromSetup(
        BattleEngineSetup.singles(
          player: _combatant(
            id: 'player',
            heldItemId: 'air_balloon',
            move: _move(id: 'tackle', power: 40),
          ),
          opponent: _combatant(
            id: 'opponent',
            heldItemId: 'iron_ball',
            types: const PsdkBattleTypes(primary: 'flying'),
            move: _move(id: 'tackle', power: 40),
          ),
          rngSeeds: _seeds.psdkSeeds,
        ).psdkSetup,
      );

      expect(resolver.isGrounded(state.battlerAt(psdkPlayerSlot)), isFalse);
      expect(resolver.isGrounded(state.battlerAt(psdkOpponentSlot)), isTrue);
    });

    test('Air Balloon pops after move damage and removes grounding override',
        () {
      const resolver = BattleGroundingResolver();
      final state = PsdkBattleState.fromSetup(
        BattleEngineSetup.singles(
          player: _combatant(
            id: 'player',
            heldItemId: 'air_balloon',
            move: _move(id: 'tackle', power: 40),
          ),
          opponent: _combatant(
            id: 'opponent',
            move: _move(id: 'tackle', power: 40),
          ),
          rngSeeds: _seeds.psdkSeeds,
        ).psdkSetup,
      );

      final result = const BattleDamageHandler().applyDamage(
        context: BattleHandlerContext(
          state: state,
          rng: BattleRngStreams.fromSeedSnapshot(_seeds),
          turn: 1,
          user: psdkOpponentSlot,
        ),
        target: psdkPlayerSlot,
        moveId: 'tackle',
        rawDamage: 20,
        move: BattleMoveDefinition.fromPsdk(_move(id: 'tackle', power: 40)),
      );
      final player = result.state.battlerAt(psdkPlayerSlot);

      expect(player.heldItemId, isNull);
      expect(player.consumedItemId, 'air_balloon');
      expect(player.effects.contains('item:air_balloon'), isFalse);
      expect(resolver.isGrounded(player), isTrue);
      expect(
        result.events.whereType<PsdkBattleItemEvent>().single.itemId,
        'air_balloon',
      );
    });

    test('consumeHeldItem clears the held item and its active item effect', () {
      final state = PsdkBattleState.fromSetup(
        BattleEngineSetup.singles(
          player: _combatant(
            id: 'player',
            heldItemId: 'air_balloon',
            move: _move(id: 'tackle', power: 40),
          ),
          opponent: _combatant(
            id: 'opponent',
            move: _move(id: 'tackle', power: 40),
          ),
          rngSeeds: _seeds.psdkSeeds,
        ).psdkSetup,
      );

      final result = const BattleItemChangeHandler().consumeHeldItem(
        context: BattleHandlerContext(
          state: state,
          rng: BattleRngStreams.fromSeedSnapshot(_seeds),
          turn: 1,
          user: psdkPlayerSlot,
        ),
        target: psdkPlayerSlot,
      );
      final battler = result.state.battlerAt(psdkPlayerSlot);

      expect(result.applied, isTrue);
      expect(battler.heldItemId, isNull);
      expect(battler.consumedItemId, 'air_balloon');
      expect(battler.itemConsumed, isTrue);
      expect(battler.effects.contains('item:air_balloon'), isFalse);
      expect(result.events.whereType<PsdkBattleItemEvent>(), hasLength(1));
    });

    test('Loaded Dice raises random two-to-five multi-hit moves to four hits',
        () {
      final result = _runMove(
        playerHeldItemId: 'loaded_dice',
        opponentCurrentHp: 200,
        playerMove: _move(
          id: 'double_slap',
          power: 25,
          battleEngineMethod: 's_multi_hit',
        ),
        rngSeeds: const BattleRngSeeds(
          moveDamage: 1,
          moveCritical: 99999,
          moveAccuracy: 3,
          generic: 0,
        ),
      );

      expect(_damageEvents(result, moveId: 'double_slap'), hasLength(4));
    });

    test('Embargo and Magic Room suppress Loaded Dice hit-count effects', () {
      for (final effectId in const <String>['embargo', 'magic_room']) {
        final result = _runMove(
          playerHeldItemId: 'loaded_dice',
          playerEffects: PsdkBattleEffectStack(values: <String>[effectId]),
          opponentCurrentHp: 200,
          playerMove: _move(
            id: 'double_slap',
            power: 25,
            battleEngineMethod: 's_multi_hit',
          ),
          rngSeeds: const BattleRngSeeds(
            moveDamage: 1,
            moveCritical: 99999,
            moveAccuracy: 3,
            generic: 0,
          ),
        );

        expect(
          _damageEvents(result, moveId: 'double_slap'),
          hasLength(2),
          reason: effectId,
        );
      }
    });

    test('Loaded Dice raises Scale Shot to at least four hits', () {
      final result = _runMove(
        playerHeldItemId: 'loaded_dice',
        opponentCurrentHp: 200,
        playerMove: _move(
          id: 'scale_shot',
          power: 25,
          battleEngineMethod: 's_scale_shot',
        ),
        rngSeeds: const BattleRngSeeds(
          moveDamage: 1,
          moveCritical: 99999,
          moveAccuracy: 3,
          generic: 0,
        ),
      );

      expect(_damageEvents(result, moveId: 'scale_shot'), hasLength(4));
    });

    test('Leftovers heals at end turn and respects item suppression', () {
      final healed = _tickEndTurn(
        playerHeldItemId: 'leftovers',
        playerCurrentHp: 40,
      );

      expect(healed.state.battlerAt(psdkPlayerSlot).currentHp, 46);
      expect(_healEvents(healed, moveId: 'item:leftovers').single.amount, 6);

      final suppressed = _tickEndTurn(
        playerHeldItemId: 'leftovers',
        playerCurrentHp: 40,
        playerEffects: PsdkBattleEffectStack(
          values: const <String>['embargo'],
        ),
      );

      expect(suppressed.state.battlerAt(psdkPlayerSlot).currentHp, 40);
      expect(_healEvents(suppressed, moveId: 'item:leftovers'), isEmpty);
    });

    test('Black Sludge heals Poison types and damages other types', () {
      final poison = _tickEndTurn(
        playerHeldItemId: 'black_sludge',
        playerCurrentHp: 40,
        playerTypes: const PsdkBattleTypes(primary: 'poison'),
      );
      final regular = _tickEndTurn(
        playerHeldItemId: 'black_sludge',
        playerCurrentHp: 40,
      );

      expect(poison.state.battlerAt(psdkPlayerSlot).currentHp, 46);
      expect(_healEvents(poison, moveId: 'item:black_sludge').single.amount, 6);
      expect(regular.state.battlerAt(psdkPlayerSlot).currentHp, 28);
      expect(
        _damageEvents(regular, moveId: 'item:black_sludge').single.damage,
        12,
      );
    });
  });
}

const _seeds = BattleRngSeeds(
  moveDamage: 1,
  moveCritical: 99999,
  moveAccuracy: 3,
  generic: 4,
);

PsdkBattleTurnResult _runMove({
  required PsdkBattleMoveData playerMove,
  String? playerHeldItemId,
  PsdkBattleEffectStack? playerEffects,
  int opponentCurrentHp = 100,
  BattleRngSeeds rngSeeds = _seeds,
}) {
  final engine = PsdkBattleEngine(
    setup: BattleEngineSetup.singles(
      player: _combatant(
        id: 'player',
        heldItemId: playerHeldItemId,
        speed: 100,
        move: playerMove,
        effects: playerEffects,
      ),
      opponent: _combatant(
        id: 'opponent',
        currentHp: opponentCurrentHp,
        speed: 1,
        move: _move(
          id: 'opponent_wait',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 1,
          battleEngineMethod: 's_splash',
        ),
      ),
      rngSeeds: rngSeeds.psdkSeeds,
    ).psdkSetup,
  );
  return engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
}

BattleHandlerResult _tickEndTurn({
  required String playerHeldItemId,
  required int playerCurrentHp,
  PsdkBattleTypes playerTypes = const PsdkBattleTypes(primary: 'normal'),
  PsdkBattleEffectStack? playerEffects,
}) {
  final state = PsdkBattleState.fromSetup(
    BattleEngineSetup.singles(
      player: _combatant(
        id: 'player',
        heldItemId: playerHeldItemId,
        currentHp: playerCurrentHp,
        types: playerTypes,
        move: _move(id: 'tackle', power: 40),
        effects: playerEffects,
      ),
      opponent: _combatant(
        id: 'opponent',
        move: _move(id: 'tackle', power: 40),
      ),
      rngSeeds: _seeds.psdkSeeds,
    ).psdkSetup,
  );
  return const BattleEndTurnHandler().resolveEndTurn(
    BattleHandlerContext(
      state: state,
      rng: BattleRngStreams.fromSeedSnapshot(_seeds),
      turn: 2,
      user: psdkPlayerSlot,
    ),
  );
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  String? heldItemId,
  int currentHp = 100,
  int speed = 50,
  PsdkBattleTypes types = const PsdkBattleTypes(primary: 'normal'),
  PsdkBattleEffectStack? effects,
  required PsdkBattleMoveData move,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 20,
    maxHp: 100,
    currentHp: currentHp,
    types: types,
    stats: PsdkBattleStats(
      attack: 50,
      defense: 50,
      specialAttack: 50,
      specialDefense: 50,
      speed: speed,
    ),
    heldItemId: heldItemId,
    effects: effects,
    moves: <PsdkBattleMoveData>[move],
  );
}

PsdkBattleMoveData _move({
  required String id,
  PsdkBattleMoveCategory category = PsdkBattleMoveCategory.physical,
  required int power,
  int accuracy = 100,
  String battleEngineMethod = 's_basic',
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
    target: PsdkBattleMoveTarget.adjacentFoe,
  );
}

List<PsdkBattleDamageEvent> _damageEvents(
  Object result, {
  required String moveId,
}) {
  final events = switch (result) {
    PsdkBattleTurnResult result => result.timeline.events,
    BattleHandlerResult result => result.events,
    _ => throw ArgumentError.value(result, 'result'),
  };
  return events
      .whereType<PsdkBattleDamageEvent>()
      .where((event) => event.moveId == moveId)
      .toList(growable: false);
}

List<PsdkBattleHealEvent> _healEvents(
  BattleHandlerResult result, {
  required String moveId,
}) {
  return result.events
      .whereType<PsdkBattleHealEvent>()
      .where((event) => event.moveId == moveId)
      .toList(growable: false);
}
