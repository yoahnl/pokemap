import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK item-dependent move families', () {
    test('s_belch fails unless the user has consumed a berry', () {
      final blocked = _runMove(
        playerMove: _move(
          id: 'belch',
          type: 'poison',
          power: 120,
          battleEngineMethod: 's_belch',
        ),
      );
      final allowed = _runMove(
        playerConsumedItemId: 'oran_berry',
        playerItemConsumed: true,
        playerMove: _move(
          id: 'belch',
          type: 'poison',
          power: 120,
          battleEngineMethod: 's_belch',
        ),
      );

      expect(_failed(blocked, moveId: 'belch'), isTrue);
      expect(_damage(allowed, moveId: 'belch'), greaterThan(0));
    });

    test('s_recycle restores the consumed item', () {
      final result = _runMove(
        playerConsumedItemId: 'oran_berry',
        playerItemConsumed: true,
        playerMove: _move(
          id: 'recycle',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          battleEngineMethod: 's_recycle',
          target: PsdkBattleMoveTarget.user,
        ),
      );

      final player = result.state.battlerAt(psdkPlayerSlot);
      expect(player.heldItemId, 'oran_berry');
      expect(player.consumedItemId, isNull);
      expect(player.itemConsumed, isFalse);
    });

    test('s_bestow gives the user held item to an empty target', () {
      final result = _runMove(
        playerHeldItemId: 'choice_scarf',
        playerMove: _move(
          id: 'bestow',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          battleEngineMethod: 's_bestow',
        ),
      );

      expect(result.state.battlerAt(psdkPlayerSlot).heldItemId, isNull);
      expect(
          result.state.battlerAt(psdkOpponentSlot).heldItemId, 'choice_scarf');
    });

    test('s_bestow dispatches item-change hooks for the giver', () {
      final result = _runMove(
        playerAbilityId: 'unburden',
        playerHeldItemId: 'choice_scarf',
        playerMove: _move(
          id: 'bestow',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          battleEngineMethod: 's_bestow',
        ),
      );

      final player = result.state.battlerAt(psdkPlayerSlot);
      expect(player.heldItemId, isNull);
      expect(player.effects.contains('unburden_active'), isTrue);
    });

    test('s_bestow fails when the user cannot lose a protected held item', () {
      final result = _runMove(
        playerSpeciesId: 'giratina',
        playerHeldItemId: 'griseous_orb',
        playerMove: _move(
          id: 'bestow',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          battleEngineMethod: 's_bestow',
        ),
      );

      expect(_failed(result, moveId: 'bestow'), isTrue);
      expect(result.state.battlerAt(psdkPlayerSlot).heldItemId, 'griseous_orb');
      expect(result.state.battlerAt(psdkOpponentSlot).heldItemId, isNull);
    });

    test('s_bestow restores the transferred item at trainer battle end', () {
      final result = _runMove(
        playerHeldItemId: 'choice_scarf',
        playerMove: _move(
          id: 'bestow',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          battleEngineMethod: 's_bestow',
        ),
      );
      final ended = const BattleBattleEndHandler().finish(
        context: BattleHandlerContext(
          state: result.state,
          rng: _rng(),
          turn: 2,
          user: psdkPlayerSlot,
        ),
        outcome: const PsdkBattleOutcome(kind: PsdkBattleOutcomeKind.victory),
      );

      expect(ended.state.battlerAt(psdkPlayerSlot).heldItemId, 'choice_scarf');
      expect(ended.state.battlerAt(psdkOpponentSlot).heldItemId, isNull);
    });

    test('s_thief steals the target item after a successful hit', () {
      final result = _runMove(
        opponentHeldItemId: 'leftovers',
        playerMove: _move(
          id: 'thief',
          type: 'dark',
          power: 60,
          battleEngineMethod: 's_thief',
        ),
      );

      expect(_damage(result, moveId: 'thief'), greaterThan(0));
      expect(result.state.battlerAt(psdkPlayerSlot).heldItemId, 'leftovers');
      expect(result.state.battlerAt(psdkOpponentSlot).heldItemId, isNull);
    });

    test('s_knock_off boosts damage and removes the target item', () {
      final normal = _runMove(
        playerMove: _move(
          id: 'knock_off',
          type: 'dark',
          power: 65,
          battleEngineMethod: 's_knock_off',
        ),
      );
      final boosted = _runMove(
        opponentHeldItemId: 'leftovers',
        playerMove: _move(
          id: 'knock_off',
          type: 'dark',
          power: 65,
          battleEngineMethod: 's_knock_off',
        ),
      );

      expect(
        _damage(boosted, moveId: 'knock_off'),
        greaterThan(_damage(normal, moveId: 'knock_off')),
      );
      expect(boosted.state.battlerAt(psdkOpponentSlot).heldItemId, isNull);
    });

    test('s_corrosive_gas removes a target held item without damage', () {
      final result = _runMove(
        opponentHeldItemId: 'leftovers',
        playerMove: _move(
          id: 'corrosive_gas',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          battleEngineMethod: 's_corrosive_gas',
        ),
      );

      expect(_failed(result, moveId: 'corrosive_gas'), isFalse);
      expect(_damageEvents(result, moveId: 'corrosive_gas'), isEmpty);
      expect(result.state.battlerAt(psdkOpponentSlot).heldItemId, isNull);
    });

    test('s_corrosive_gas fails when no target can lose an item', () {
      final result = _runMove(
        playerMove: _move(
          id: 'corrosive_gas',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          battleEngineMethod: 's_corrosive_gas',
        ),
      );

      expect(_failed(result, moveId: 'corrosive_gas'), isTrue);
      expect(
        result.state.battlerAt(psdkOpponentSlot).effects.contains(
              'corrosive_gas',
            ),
        isFalse,
      );
    });

    test('s_pluck removes a target berry after a successful hit', () {
      final result = _runMove(
        opponentHeldItemId: 'oran_berry',
        playerMove: _move(
          id: 'pluck',
          type: 'flying',
          power: 60,
          battleEngineMethod: 's_pluck',
        ),
      );

      expect(_damage(result, moveId: 'pluck'), greaterThan(0));
      expect(result.state.battlerAt(psdkOpponentSlot).heldItemId, isNull);
      expect(result.state.battlerAt(psdkOpponentSlot).consumedItemId,
          'oran_berry');
    });

    test('s_pluck forces the stolen Oran Berry heal on the user', () {
      final result = _runMove(
        playerCurrentHp: 55,
        opponentHeldItemId: 'oran_berry',
        playerMove: _move(
          id: 'pluck',
          type: 'flying',
          power: 60,
          battleEngineMethod: 's_pluck',
        ),
      );

      expect(_damage(result, moveId: 'pluck'), greaterThan(0));
      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 65);
      expect(result.state.battlerAt(psdkOpponentSlot).heldItemId, isNull);
      expect(result.timeline.events.whereType<PsdkBattleHealEvent>().single,
          isA<PsdkBattleHealEvent>());
    });

    test('s_pluck forces the stolen Sitrus Berry quarter heal on the user', () {
      final result = _runMove(
        playerCurrentHp: 50,
        opponentHeldItemId: 'sitrus_berry',
        playerMove: _move(
          id: 'pluck',
          type: 'flying',
          power: 60,
          battleEngineMethod: 's_pluck',
        ),
      );

      expect(_damage(result, moveId: 'pluck'), greaterThan(0));
      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 75);
      expect(result.state.battlerAt(psdkOpponentSlot).heldItemId, isNull);
      expect(
          result.timeline.events.whereType<PsdkBattleHealEvent>().single.amount,
          25);
    });

    test('s_natural_gift consumes a berry and uses its item power/type', () {
      final normal = _runMove(
        opponentTypes: const PsdkBattleTypes(primary: 'grass'),
        playerMove: _move(
          id: 'natural_gift',
          type: 'normal',
          power: 1,
          battleEngineMethod: 's_natural_gift',
        ),
      );
      final gifted = _runMove(
        playerHeldItemId: 'liechi_berry',
        opponentTypes: const PsdkBattleTypes(primary: 'grass'),
        playerMove: _move(
          id: 'natural_gift',
          type: 'normal',
          power: 1,
          battleEngineMethod: 's_natural_gift',
        ),
      );

      expect(_failed(normal, moveId: 'natural_gift'), isTrue);
      expect(
        _damage(gifted, moveId: 'natural_gift'),
        greaterThan(0),
      );
      expect(gifted.state.battlerAt(psdkPlayerSlot).heldItemId, isNull);
      expect(gifted.state.battlerAt(psdkPlayerSlot).consumedItemId,
          'liechi_berry');
    });

    test('s_natural_gift accepts every PSDK Studio berry table entry', () {
      final gifted = _runMove(
        playerHeldItemId: 'magost_berry',
        opponentTypes: const PsdkBattleTypes(primary: 'flying'),
        playerMove: _move(
          id: 'natural_gift',
          type: 'normal',
          power: 1,
          battleEngineMethod: 's_natural_gift',
        ),
      );

      expect(_failed(gifted, moveId: 'natural_gift'), isFalse);
      expect(_damage(gifted, moveId: 'natural_gift'), greaterThan(0));
      expect(gifted.state.battlerAt(psdkPlayerSlot).heldItemId, isNull);
      expect(gifted.state.battlerAt(psdkPlayerSlot).consumedItemId,
          'magost_berry');
    });

    test('s_fling consumes the held item and uses item fling power', () {
      final light = _runMove(
        playerHeldItemId: 'choice_scarf',
        playerMove: _move(
          id: 'fling',
          type: 'dark',
          power: 1,
          battleEngineMethod: 's_fling',
        ),
      );
      final heavy = _runMove(
        playerHeldItemId: 'iron_ball',
        playerMove: _move(
          id: 'fling',
          type: 'dark',
          power: 1,
          battleEngineMethod: 's_fling',
        ),
      );

      expect(
        _damage(heavy, moveId: 'fling'),
        greaterThan(_damage(light, moveId: 'fling')),
      );
      expect(heavy.state.battlerAt(psdkPlayerSlot).heldItemId, isNull);
      expect(heavy.state.battlerAt(psdkPlayerSlot).consumedItemId, 'iron_ball');
    });

    test('s_fling applies Toxic Orb and Flame Orb status effects', () {
      final toxic = _runMove(
        playerHeldItemId: 'toxic_orb',
        playerMove: _move(
          id: 'fling',
          type: 'dark',
          power: 1,
          battleEngineMethod: 's_fling',
        ),
      );
      final burn = _runMove(
        playerHeldItemId: 'flame_orb',
        playerMove: _move(
          id: 'fling',
          type: 'dark',
          power: 1,
          battleEngineMethod: 's_fling',
        ),
      );

      expect(_damage(toxic, moveId: 'fling'), greaterThan(0));
      expect(toxic.state.battlerAt(psdkOpponentSlot).majorStatus,
          PsdkBattleMajorStatus.toxic);
      expect(toxic.state.battlerAt(psdkPlayerSlot).heldItemId, isNull);
      expect(
          toxic.timeline.events
              .whereType<PsdkBattleStatusEvent>()
              .single
              .status,
          PsdkBattleMajorStatus.toxic);
      expect(burn.state.battlerAt(psdkOpponentSlot).majorStatus,
          PsdkBattleMajorStatus.burn);
      expect(
          burn.timeline.events.whereType<PsdkBattleStatusEvent>().single.status,
          PsdkBattleMajorStatus.burn);
    });

    test('s_fling applies Light Ball and Poison Barb status effects', () {
      final paralysis = _runMove(
        playerHeldItemId: 'light_ball',
        playerMove: _move(
          id: 'fling',
          type: 'dark',
          power: 1,
          battleEngineMethod: 's_fling',
        ),
      );
      final poison = _runMove(
        playerHeldItemId: 'poison_barb',
        playerMove: _move(
          id: 'fling',
          type: 'dark',
          power: 1,
          battleEngineMethod: 's_fling',
        ),
      );

      expect(_failed(paralysis, moveId: 'fling'), isFalse);
      expect(paralysis.state.battlerAt(psdkOpponentSlot).majorStatus,
          PsdkBattleMajorStatus.paralysis);
      expect(_failed(poison, moveId: 'fling'), isFalse);
      expect(poison.state.battlerAt(psdkOpponentSlot).majorStatus,
          PsdkBattleMajorStatus.poison);
    });

    test('s_techno_blast is gated to Genesect', () {
      final blocked = _runMove(
        playerSpeciesId: 'ditto',
        playerMove: _move(
          id: 'techno_blast',
          type: 'normal',
          category: PsdkBattleMoveCategory.special,
          power: 120,
          battleEngineMethod: 's_techno_blast',
        ),
      );
      final allowed = _runMove(
        playerSpeciesId: 'genesect',
        playerHeldItemId: 'burn_drive',
        opponentTypes: const PsdkBattleTypes(primary: 'grass'),
        playerMove: _move(
          id: 'techno_blast',
          type: 'normal',
          category: PsdkBattleMoveCategory.special,
          power: 120,
          battleEngineMethod: 's_techno_blast',
        ),
      );

      expect(_failed(blocked, moveId: 'techno_blast'), isTrue);
      expect(_damage(allowed, moveId: 'techno_blast'), greaterThan(0));
    });
  });
}

PsdkBattleTurnResult _runMove({
  required PsdkBattleMoveData playerMove,
  String playerSpeciesId = 'player',
  String? playerAbilityId,
  String? playerHeldItemId,
  String? opponentHeldItemId,
  String? playerConsumedItemId,
  bool playerItemConsumed = false,
  int playerCurrentHp = 100,
  PsdkBattleTypes playerTypes = const PsdkBattleTypes(primary: 'normal'),
  PsdkBattleTypes opponentTypes = const PsdkBattleTypes(primary: 'normal'),
}) {
  final engine = PsdkBattleEngine(
    setup: PsdkBattleSetup.singles(
      player: _combatant(
        id: 'player',
        speciesId: playerSpeciesId,
        types: playerTypes,
        move: playerMove,
        currentHp: playerCurrentHp,
        abilityId: playerAbilityId,
        heldItemId: playerHeldItemId,
        consumedItemId: playerConsumedItemId,
        itemConsumed: playerItemConsumed,
      ),
      opponent: _combatant(
        id: 'opponent',
        types: opponentTypes,
        speed: 1,
        move: _move(
          id: 'opponent_wait',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 0,
          battleEngineMethod: 's_splash',
        ),
        heldItemId: opponentHeldItemId,
      ),
      rngSeeds: const PsdkBattleRngSeeds(
        moveDamage: 1,
        moveCritical: 99999,
        moveAccuracy: 3,
        generic: 4,
      ),
    ),
  );
  return engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  String? speciesId,
  required PsdkBattleTypes types,
  required PsdkBattleMoveData move,
  int speed = 100,
  int currentHp = 100,
  String? abilityId,
  String? heldItemId,
  String? consumedItemId,
  bool itemConsumed = false,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: speciesId ?? id,
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
    abilityId: abilityId,
    heldItemId: heldItemId,
    consumedItemId: consumedItemId,
    itemConsumed: itemConsumed,
    moves: <PsdkBattleMoveData>[move],
  );
}

PsdkBattleMoveData _move({
  required String id,
  String type = 'normal',
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
    type: type,
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

int _damage(PsdkBattleTurnResult result, {required String moveId}) {
  return _damageEvents(result, moveId: moveId).single.damage;
}

List<PsdkBattleDamageEvent> _damageEvents(
  PsdkBattleTurnResult result, {
  required String moveId,
}) {
  return result.timeline.events
      .whereType<PsdkBattleDamageEvent>()
      .where((event) => event.moveId == moveId)
      .toList(growable: false);
}

bool _failed(PsdkBattleTurnResult result, {required String moveId}) {
  return result.timeline.events
      .whereType<PsdkBattleMoveFailedEvent>()
      .any((event) => event.moveId == moveId);
}

BattleRngStreams _rng() {
  return BattleRngStreams.fromSeeds(
    moveDamageSeed: 1,
    moveCriticalSeed: 99999,
    moveAccuracySeed: 3,
    genericSeed: 4,
  );
}
