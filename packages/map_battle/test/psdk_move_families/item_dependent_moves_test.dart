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
  String? playerHeldItemId,
  String? opponentHeldItemId,
  String? playerConsumedItemId,
  bool playerItemConsumed = false,
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
    currentHp: 100,
    types: types,
    stats: PsdkBattleStats(
      attack: 50,
      defense: 50,
      specialAttack: 50,
      specialDefense: 50,
      speed: speed,
    ),
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
  return result.timeline.events
      .whereType<PsdkBattleDamageEvent>()
      .singleWhere((event) => event.moveId == moveId)
      .damage;
}

bool _failed(PsdkBattleTurnResult result, {required String moveId}) {
  return result.timeline.events
      .whereType<PsdkBattleMoveFailedEvent>()
      .any((event) => event.moveId == moveId);
}
