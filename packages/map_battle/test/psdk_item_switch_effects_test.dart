import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK switch-trigger item effects', () {
    test('Eject Button consumes itself and queues the damaged holder', () {
      final move = _move(id: 'tackle', power: 40);
      final state = _state(
        player: _combatant(id: 'player', move: move),
        opponent: _combatant(
          id: 'opponent',
          heldItemId: 'eject_button',
          move: _move(id: 'opponent_wait', power: 0),
        ),
        opponentReserves: <PsdkBattleCombatantSetup>[
          _combatant(id: 'opponent-reserve', move: _move(id: 'wait', power: 0)),
        ],
      );

      final result = const BattleDamageHandler().applyDamage(
        context: BattleHandlerContext(
          state: state,
          rng: _rng(),
          turn: 1,
          user: psdkPlayerSlot,
        ),
        target: psdkOpponentSlot,
        moveId: move.id,
        rawDamage: 30,
        move: BattleMoveDefinition.fromPsdk(move),
      );
      final holder = result.state.battlerAt(psdkOpponentSlot);

      expect(holder.currentHp, 70);
      expect(holder.switching, isTrue);
      expect(holder.heldItemId, isNull);
      expect(holder.itemConsumed, isTrue);
      expect(holder.consumedItemId, 'eject_button');
      expect(
        result.events.whereType<PsdkBattleItemEvent>().single.itemId,
        'eject_button',
      );
    });

    test('Eject Button stays held when the damaged holder has no replacement',
        () {
      final move = _move(id: 'tackle', power: 40);
      final state = _state(
        player: _combatant(id: 'player', move: move),
        opponent: _combatant(
          id: 'opponent',
          heldItemId: 'eject_button',
          move: _move(id: 'opponent_wait', power: 0),
        ),
      );

      final result = const BattleDamageHandler().applyDamage(
        context: BattleHandlerContext(
          state: state,
          rng: _rng(),
          turn: 1,
          user: psdkPlayerSlot,
        ),
        target: psdkOpponentSlot,
        moveId: move.id,
        rawDamage: 30,
        move: BattleMoveDefinition.fromPsdk(move),
      );
      final holder = result.state.battlerAt(psdkOpponentSlot);

      expect(holder.switching, isFalse);
      expect(holder.heldItemId, 'eject_button');
      expect(holder.itemConsumed, isFalse);
      expect(result.events.whereType<PsdkBattleItemEvent>(), isEmpty);
    });

    test('Eject Button cancels the holder pending attack for the turn', () {
      final engine = BattleEngine(
        setup: BattleEngineSetup.singles(
          player: _combatant(
            id: 'player',
            speed: 120,
            move: _move(id: 'tackle', power: 40),
          ),
          opponent: _combatant(
            id: 'opponent',
            speed: 40,
            heldItemId: 'eject_button',
            move: _move(id: 'opponent_tackle', power: 40),
          ),
          opponentReserves: <PsdkBattleCombatantSetup>[
            _combatant(
              id: 'opponent-reserve',
              move: _move(id: 'wait', power: 0),
            ),
          ],
          rngSeeds: const BattleRngSeeds(
            moveDamage: 1,
            moveCritical: 99999,
            moveAccuracy: 3,
            generic: 4,
          ).psdkSeeds,
        ),
      );

      final result = engine.submit(const BattleDecision.fight(moveSlot: 0));

      expect(result.state.battlerAt(psdkOpponentSlot).switching, isTrue);
      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 100);
      expect(
        result.timeline.events
            .whereType<BattleDamageTimelineEvent>()
            .map((event) => event.moveId),
        <String>['tackle'],
      );
    });

    test('Red Card consumes itself and queues the attacker switch', () {
      final move = _move(id: 'tackle', power: 40);
      final state = _state(
        player: _combatant(id: 'player', move: move),
        playerReserves: <PsdkBattleCombatantSetup>[
          _combatant(id: 'player-reserve', move: _move(id: 'wait', power: 0)),
        ],
        opponent: _combatant(
          id: 'opponent',
          heldItemId: 'red_card',
          move: _move(id: 'opponent_wait', power: 0),
        ),
      );

      final result = const BattleDamageHandler().applyDamage(
        context: BattleHandlerContext(
          state: state,
          rng: _rng(),
          turn: 1,
          user: psdkPlayerSlot,
        ),
        target: psdkOpponentSlot,
        moveId: move.id,
        rawDamage: 30,
        move: BattleMoveDefinition.fromPsdk(move),
      );
      final attacker = result.state.battlerAt(psdkPlayerSlot);
      final holder = result.state.battlerAt(psdkOpponentSlot);

      expect(attacker.switching, isTrue);
      expect(holder.heldItemId, isNull);
      expect(holder.itemConsumed, isTrue);
      expect(holder.consumedItemId, 'red_card');
      expect(
        result.events.whereType<PsdkBattleItemEvent>().single.itemId,
        'red_card',
      );
    });

    test('Red Card stays held when the attacker has no replacement', () {
      final move = _move(id: 'tackle', power: 40);
      final state = _state(
        player: _combatant(id: 'player', move: move),
        opponent: _combatant(
          id: 'opponent',
          heldItemId: 'red_card',
          move: _move(id: 'opponent_wait', power: 0),
        ),
      );

      final result = const BattleDamageHandler().applyDamage(
        context: BattleHandlerContext(
          state: state,
          rng: _rng(),
          turn: 1,
          user: psdkPlayerSlot,
        ),
        target: psdkOpponentSlot,
        moveId: move.id,
        rawDamage: 30,
        move: BattleMoveDefinition.fromPsdk(move),
      );
      final attacker = result.state.battlerAt(psdkPlayerSlot);
      final holder = result.state.battlerAt(psdkOpponentSlot);

      expect(attacker.switching, isFalse);
      expect(holder.heldItemId, 'red_card');
      expect(holder.itemConsumed, isFalse);
      expect(result.events.whereType<PsdkBattleItemEvent>(), isEmpty);
    });

    test('Primal Orbs revert Groudon and Kyogre on switch-in', () {
      final groudon = const BattleSwitchHandler().dispatchSwitchEvents(
        context: BattleHandlerContext(
          state: _state(
            player: _combatant(
              id: 'groudon',
              speciesId: 'groudon',
              displayName: 'Groudon',
              types: const PsdkBattleTypes(primary: 'ground'),
              abilityId: 'drought',
              heldItemId: 'red_orb',
              move: _move(id: 'tackle', power: 40),
            ),
            opponent: _combatant(
              id: 'opponent',
              move: _move(id: 'opponent_wait', power: 0),
            ),
          ),
          rng: _rng(),
          turn: 1,
          user: psdkPlayerSlot,
        ),
        who: psdkPlayerSlot,
        replacement: psdkPlayerSlot,
      );
      final primalGroudon = groudon.state.battlerAt(psdkPlayerSlot);

      expect(primalGroudon.form, 1);
      expect(primalGroudon.types.primary, 'ground');
      expect(primalGroudon.types.secondary, 'fire');
      expect(primalGroudon.abilityId, 'desolate_land');
      expect(groudon.state.field.weather?.id, PsdkBattleWeatherId.hardsun);
      expect(primalGroudon.heldItemId, 'red_orb');

      final kyogre = const BattleSwitchHandler().dispatchSwitchEvents(
        context: BattleHandlerContext(
          state: _state(
            player: _combatant(
              id: 'kyogre',
              speciesId: 'kyogre',
              displayName: 'Kyogre',
              types: const PsdkBattleTypes(primary: 'water'),
              abilityId: 'drizzle',
              heldItemId: 'blue_orb',
              move: _move(id: 'tackle', power: 40),
            ),
            opponent: _combatant(
              id: 'opponent',
              move: _move(id: 'opponent_wait', power: 0),
            ),
          ),
          rng: _rng(),
          turn: 1,
          user: psdkPlayerSlot,
        ),
        who: psdkPlayerSlot,
        replacement: psdkPlayerSlot,
      );
      final primalKyogre = kyogre.state.battlerAt(psdkPlayerSlot);

      expect(primalKyogre.form, 1);
      expect(primalKyogre.types.primary, 'water');
      expect(primalKyogre.types.secondary, isNull);
      expect(primalKyogre.abilityId, 'primordial_sea');
      expect(kyogre.state.field.weather?.id, PsdkBattleWeatherId.hardrain);
      expect(primalKyogre.heldItemId, 'blue_orb');
    });
  });
}

PsdkBattleState _state({
  required PsdkBattleCombatantSetup player,
  required PsdkBattleCombatantSetup opponent,
  List<PsdkBattleCombatantSetup> playerReserves =
      const <PsdkBattleCombatantSetup>[],
  List<PsdkBattleCombatantSetup> opponentReserves =
      const <PsdkBattleCombatantSetup>[],
}) {
  return PsdkBattleState.fromSetup(
    BattleEngineSetup.singles(
      player: player,
      opponent: opponent,
      playerReserves: playerReserves,
      opponentReserves: opponentReserves,
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
  String? speciesId,
  String? displayName,
  PsdkBattleTypes types = const PsdkBattleTypes(primary: 'normal'),
  String? abilityId,
  String? heldItemId,
  int speed = 100,
  required PsdkBattleMoveData move,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: speciesId ?? id,
    displayName: displayName ?? id,
    level: 50,
    maxHp: 100,
    currentHp: 100,
    types: types,
    abilityId: abilityId,
    heldItemId: heldItemId,
    stats: PsdkBattleStats(
      attack: 100,
      defense: 100,
      specialAttack: 100,
      specialDefense: 100,
      speed: speed,
    ),
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
    category: PsdkBattleMoveCategory.physical,
    power: power,
    accuracy: 100,
    pp: 35,
    priority: 0,
    criticalRate: 1,
    battleEngineMethod: 's_basic',
    target: PsdkBattleMoveTarget.adjacentFoe,
  );
}

BattleRngStreams _rng() {
  return BattleRngStreams.fromSeeds(
    moveDamageSeed: 1,
    moveCriticalSeed: 99999,
    moveAccuracySeed: 3,
    genericSeed: 4,
  );
}
