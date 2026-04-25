import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK recoil move families', () {
    test('s_recoil applies target damage then user recoil from damage dealt',
        () {
      final result = _runMove(
        playerMove: _move(
          id: 'take_down',
          power: 40,
          battleEngineMethod: 's_recoil',
        ),
      );

      final damage = _damageEvents(result, moveId: 'take_down');
      expect(damage, hasLength(2));
      expect(damage.first.target, psdkOpponentSlot);
      expect(damage.first.damage, 8);
      expect(damage.first.remainingHp, 92);
      expect(damage.last.target, psdkPlayerSlot);
      expect(damage.last.damage, 2);
      expect(damage.last.remainingHp, 98);
      expect(result.state.battlerAt(psdkOpponentSlot).currentHp, 92);
      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 98);
    });

    test('s_recoil uses the PSDK dbSymbol factor table', () {
      final result = _runMove(
        playerMove: _move(
          id: 'double_edge',
          power: 120,
          battleEngineMethod: 's_recoil',
        ),
      );

      final damage = _damageEvents(result, moveId: 'double_edge');
      expect(damage, hasLength(2));
      expect(damage.first.damage, 22);
      expect(damage.last.damage, 7);
      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 93);
    });

    test('s_recoil bases normal recoil on clamped target damage', () {
      final result = _runMove(
        opponentCurrentHp: 5,
        playerMove: _move(
          id: 'double_edge',
          power: 120,
          battleEngineMethod: 's_recoil',
        ),
      );

      final damage = _damageEvents(result, moveId: 'double_edge');
      expect(damage, hasLength(2));
      expect(damage.first.target, psdkOpponentSlot);
      expect(damage.first.damage, 5);
      expect(damage.last.target, psdkPlayerSlot);
      expect(damage.last.damage, 1);
      expect(result.outcome?.kind, PsdkBattleOutcomeKind.victory);
    });

    test('s_recoil clamps recoil to at least one HP and can KO the user', () {
      final result = _runMove(
        playerCurrentHp: 1,
        playerMove: _move(
          id: 'take_down',
          power: 1,
          battleEngineMethod: 's_recoil',
        ),
      );

      final damage = _damageEvents(result, moveId: 'take_down');
      expect(damage, hasLength(2));
      expect(damage.first.target, psdkOpponentSlot);
      expect(damage.first.damage, 1);
      expect(damage.last.target, psdkPlayerSlot);
      expect(damage.last.damage, 1);
      expect(damage.last.remainingHp, 0);
      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 0);
      expect(result.outcome?.kind, PsdkBattleOutcomeKind.defeat);
    });

    test('s_recoil emits no recoil damage when the move misses', () {
      final result = _runMove(
        playerMove: _move(
          id: 'take_down',
          power: 40,
          accuracy: 1,
          battleEngineMethod: 's_recoil',
        ),
        rngSeeds: const BattleRngSeeds(
          moveDamage: 1,
          moveCritical: 99999,
          moveAccuracy: 99,
          generic: 4,
        ),
      );

      final kinds =
          _eventsFor(result, moveId: 'take_down').map((event) => event.kind);
      expect(kinds, contains('miss'));
      expect(kinds, isNot(contains('damage')));
      expect(result.state.battlerAt(psdkOpponentSlot).currentHp, 100);
      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 100);
    });

    test('s_recoil keeps the shared immunity precheck before recoil', () {
      final result = _runMove(
        opponentTypes: const PsdkBattleTypes(primary: 'ghost'),
        playerMove: _move(
          id: 'take_down',
          power: 40,
          battleEngineMethod: 's_recoil',
        ),
      );

      final kinds =
          _eventsFor(result, moveId: 'take_down').map((event) => event.kind);
      expect(kinds, contains('move_immune'));
      expect(kinds, isNot(contains('damage')));
      expect(result.state.battlerAt(psdkOpponentSlot).currentHp, 100);
      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 100);
    });

    test('s_recoil keeps the shared Protect precheck before recoil', () {
      final result = _runMove(
        opponentEffects: PsdkBattleEffectStack(
          values: const <String>[PsdkBattleEffectIds.protect],
        ),
        playerMove: _move(
          id: 'take_down',
          power: 40,
          battleEngineMethod: 's_recoil',
        ),
      );

      final events = _eventsFor(result, moveId: 'take_down');
      expect(events.map((event) => event.kind), <String>[
        'move_pp_spent',
        'move_declared',
        'move_failed',
      ]);
      expect((events.last as PsdkBattleMoveFailedEvent).reason,
          BattleMoveFailureReason.protected.jsonName);
      expect(result.state.battlerAt(psdkOpponentSlot).currentHp, 100);
      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 100);
    });

    test('s_recoil applies secondary effects after recoil damage', () {
      final result = _runMove(
        playerMove: _move(
          id: 'flare_blitz',
          type: 'fire',
          power: 40,
          battleEngineMethod: 's_recoil',
          statuses: <PsdkBattleMoveStatus>[
            PsdkBattleMoveStatus(
              status: PsdkBattleMajorStatus.burn,
              chance: 100,
            ),
          ],
        ),
      );

      final events = _eventsFor(result, moveId: 'flare_blitz');
      expect(
        events.map((event) => event.kind),
        containsAllInOrder(<String>[
          'damage',
          'damage',
          'status',
        ]),
      );
      expect(result.state.battlerAt(psdkOpponentSlot).majorStatus,
          PsdkBattleMajorStatus.burn);
    });
  });
}

PsdkBattleTurnResult _runMove({
  required PsdkBattleMoveData playerMove,
  int playerCurrentHp = 100,
  int opponentCurrentHp = 100,
  PsdkBattleTypes opponentTypes = const PsdkBattleTypes(primary: 'fire'),
  PsdkBattleEffectStack? opponentEffects,
  BattleRngSeeds rngSeeds = const BattleRngSeeds(
    moveDamage: 1,
    moveCritical: 99999,
    moveAccuracy: 3,
    generic: 4,
  ),
}) {
  final engine = PsdkBattleEngine(
    setup: BattleEngineSetup.singles(
      player: _combatant(
        id: 'player',
        currentHp: playerCurrentHp,
        speed: 100,
        types: const PsdkBattleTypes(primary: 'fire'),
        move: playerMove,
      ),
      opponent: _combatant(
        id: 'opponent',
        currentHp: opponentCurrentHp,
        speed: 1,
        types: opponentTypes,
        effects: opponentEffects,
        move: _move(
          id: 'opponent_wait',
          power: 0,
          accuracy: 1,
        ),
      ),
      rngSeeds: rngSeeds.psdkSeeds,
    ).psdkSetup,
  );
  return engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  required int currentHp,
  required int speed,
  required PsdkBattleTypes types,
  required PsdkBattleMoveData move,
  PsdkBattleEffectStack? effects,
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
    effects: effects,
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
  List<PsdkBattleMoveStatus> statuses = const <PsdkBattleMoveStatus>[],
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
    target: PsdkBattleMoveTarget.adjacentFoe,
    statuses: statuses,
  );
}

List<PsdkBattleEvent> _eventsFor(
  PsdkBattleTurnResult result, {
  required String moveId,
}) {
  return result.timeline.events
      .where((event) => event.toJson()['moveId'] == moveId)
      .toList(growable: false);
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
