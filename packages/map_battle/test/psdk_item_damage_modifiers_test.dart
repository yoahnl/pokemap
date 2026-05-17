import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK held item damage and speed modifiers', () {
    test('type boosting items increase matching move damage and persist', () {
      final baseline = _runMove(
        playerMove: _move(id: 'ember', type: 'fire', power: 40),
      );
      final boosted = _runMove(
        playerHeldItemId: 'charcoal',
        playerMove: _move(id: 'ember', type: 'fire', power: 40),
      );
      final mismatched = _runMove(
        playerHeldItemId: 'charcoal',
        playerMove: _move(id: 'water_gun', type: 'water', power: 40),
      );

      expect(_damage(boosted, moveId: 'ember'),
          greaterThan(_damage(baseline, moveId: 'ember')));
      expect(
        _damage(mismatched, moveId: 'water_gun'),
        _damage(
            _runMove(
                playerMove: _move(id: 'water_gun', type: 'water', power: 40)),
            moveId: 'water_gun'),
      );
      expect(boosted.state.battlerAt(psdkPlayerSlot).heldItemId, 'charcoal');
      expect(boosted.state.battlerAt(psdkPlayerSlot).itemConsumed, isFalse);
    });

    test('Choice Band and Choice Specs boost the matching offensive stat', () {
      final physical = _runMove(
        playerHeldItemId: 'choice_band',
        playerMove: _move(id: 'slash', type: 'normal', power: 70),
      );
      final physicalBaseline = _runMove(
        playerMove: _move(id: 'slash', type: 'normal', power: 70),
      );
      final special = _runMove(
        playerHeldItemId: 'choice_specs',
        playerMove: _move(
          id: 'swift',
          type: 'normal',
          power: 60,
          category: PsdkBattleMoveCategory.special,
        ),
      );
      final specialBaseline = _runMove(
        playerMove: _move(
          id: 'swift',
          type: 'normal',
          power: 60,
          category: PsdkBattleMoveCategory.special,
        ),
      );

      expect(_damage(physical, moveId: 'slash'),
          greaterThan(_damage(physicalBaseline, moveId: 'slash')));
      expect(_damage(special, moveId: 'swift'),
          greaterThan(_damage(specialBaseline, moveId: 'swift')));
    });

    test('Normal Gem boosts a matching hit and is consumed once', () {
      final baseline = _runMove(
        playerMove: _move(id: 'tackle', type: 'normal', power: 40),
      );
      final gem = _runMove(
        playerHeldItemId: 'normal_gem',
        playerMove: _move(id: 'tackle', type: 'normal', power: 40),
      );
      final player = gem.state.battlerAt(psdkPlayerSlot);

      expect(_damage(gem, moveId: 'tackle'),
          greaterThan(_damage(baseline, moveId: 'tackle')));
      expect(player.heldItemId, isNull);
      expect(player.consumedItemId, 'normal_gem');
      expect(player.itemConsumed, isTrue);
      expect(_itemEvents(gem).single.itemId, 'normal_gem');
    });

    test('Life Orb boosts damage and applies recoil without consuming itself',
        () {
      final baseline = _runMove(
        playerMove: _move(id: 'tackle', type: 'normal', power: 40),
      );
      final boosted = _runMove(
        playerHeldItemId: 'life_orb',
        playerMove: _move(id: 'tackle', type: 'normal', power: 40),
      );
      final player = boosted.state.battlerAt(psdkPlayerSlot);

      expect(_damage(boosted, moveId: 'tackle'),
          greaterThan(_damage(baseline, moveId: 'tackle')));
      expect(_damage(boosted, moveId: 'item:life_orb'), 10);
      expect(player.currentHp, 90);
      expect(player.heldItemId, 'life_orb');
      expect(player.itemConsumed, isFalse);
    });

    test('Choice Scarf speed modifier affects action order', () {
      final state = _state(
        playerHeldItemId: 'choice_scarf',
        playerSpeed: 80,
        opponentSpeed: 100,
      );
      const mapper = PsdkBattleActionDecisionMapper();
      const ordering = PsdkBattleActionOrdering();
      final playerAction = mapper.map(
        state: state,
        user: psdkPlayerSlot,
        decision: const BattleFightDecision(moveSlot: 0),
      );
      final opponentAction = mapper.map(
        state: state,
        user: psdkOpponentSlot,
        decision: const BattleFightDecision(moveSlot: 0),
      );

      final ordered = ordering.order(
        actions: <PsdkBattleAction>[opponentAction, playerAction],
        rng: BattleRngStreams.fromSeedSnapshot(_seeds),
      );

      expect(ordered.first.user.toJson(), psdkPlayerSlot.toJson());
      expect((playerAction as PsdkBattleFightAction).speed, 120);
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
}) {
  final engine = PsdkBattleEngine(
    setup: BattleEngineSetup.singles(
      player: _combatant(
        id: 'player',
        heldItemId: playerHeldItemId,
        speed: 100,
        move: playerMove,
      ),
      opponent: _combatant(
        id: 'opponent',
        speed: 1,
        currentHp: 200,
        move: _move(
          id: 'opponent_wait',
          type: 'normal',
          power: 0,
          category: PsdkBattleMoveCategory.status,
          battleEngineMethod: 's_splash',
        ),
      ),
      rngSeeds: _seeds.psdkSeeds,
    ).psdkSetup,
  );
  return engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
}

PsdkBattleState _state({
  String? playerHeldItemId,
  int playerSpeed = 100,
  int opponentSpeed = 50,
}) {
  return PsdkBattleState.fromSetup(
    BattleEngineSetup.singles(
      player: _combatant(
        id: 'player',
        heldItemId: playerHeldItemId,
        speed: playerSpeed,
        move: _move(id: 'tackle', type: 'normal', power: 40),
      ),
      opponent: _combatant(
        id: 'opponent',
        speed: opponentSpeed,
        move: _move(id: 'scratch', type: 'normal', power: 40),
      ),
      rngSeeds: _seeds.psdkSeeds,
    ).psdkSetup,
  );
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  required PsdkBattleMoveData move,
  String? heldItemId,
  int currentHp = 100,
  int speed = 50,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 20,
    maxHp: 100,
    currentHp: currentHp,
    types: const PsdkBattleTypes(primary: 'normal'),
    stats: PsdkBattleStats(
      attack: 50,
      defense: 50,
      specialAttack: 50,
      specialDefense: 50,
      speed: speed,
    ),
    heldItemId: heldItemId,
    moves: <PsdkBattleMoveData>[move],
  );
}

PsdkBattleMoveData _move({
  required String id,
  required String type,
  required int power,
  PsdkBattleMoveCategory category = PsdkBattleMoveCategory.physical,
  String battleEngineMethod = 's_basic',
}) {
  return PsdkBattleMoveData(
    id: id,
    dbSymbol: id,
    name: id,
    type: type,
    category: category,
    power: power,
    accuracy: 100,
    pp: 35,
    priority: 0,
    criticalRate: 1,
    battleEngineMethod: battleEngineMethod,
    target: PsdkBattleMoveTarget.adjacentFoe,
  );
}

int _damage(PsdkBattleTurnResult result, {required String moveId}) {
  return result.timeline.events
      .whereType<PsdkBattleDamageEvent>()
      .where((event) => event.moveId == moveId)
      .fold<int>(0, (sum, event) => sum + event.damage);
}

List<PsdkBattleItemEvent> _itemEvents(PsdkBattleTurnResult result) {
  return result.timeline.events
      .whereType<PsdkBattleItemEvent>()
      .toList(growable: false);
}
