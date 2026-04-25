import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK SelfDestruct move family', () {
    test('s_explosion damages the target before self-KOing the user', () {
      final result = _runMove(
        playerCurrentHp: 37,
        playerMove: _move(
          id: 'explosion',
          power: 40,
          battleEngineMethod: 's_explosion',
        ),
      );

      final damage = _damageEvents(result, moveId: 'explosion');
      expect(damage, hasLength(2));
      expect(damage.first.target, psdkOpponentSlot);
      expect(damage.first.damage, 8);
      expect(damage.first.remainingHp, 92);
      expect(damage.last.target, psdkPlayerSlot);
      expect(damage.last.damage, 37);
      expect(damage.last.remainingHp, 0);
      expect(result.state.battlerAt(psdkOpponentSlot).currentHp, 92);
      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 0);
      expect(result.state.outcome?.kind, PsdkBattleOutcomeKind.defeat);
    });

    test('s_explosion does not self-KO when accuracy misses', () {
      final result = _runMove(
        playerMove: _move(
          id: 'explosion',
          power: 40,
          accuracy: 1,
          battleEngineMethod: 's_explosion',
        ),
        rngSeeds: const BattleRngSeeds(
          moveDamage: 1,
          moveCritical: 99999,
          moveAccuracy: 99,
          generic: 4,
        ),
      );

      final events = _eventsFor(result, moveId: 'explosion');
      expect(
          events.map((event) => event.kind),
          containsAllInOrder(<String>[
            'move_declared',
            'miss',
          ]));
      expect(_damageEvents(result, moveId: 'explosion'), isEmpty);
      expect(result.state.battlerAt(psdkOpponentSlot).currentHp, 100);
      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 100);
      expect(result.state.outcome, isNull);
    });

    test('s_explosion self-KOs when the target is type-immune', () {
      final result = _runMove(
        playerCurrentHp: 13,
        opponentTypes: const PsdkBattleTypes(primary: 'ghost'),
        playerMove: _move(
          id: 'explosion',
          power: 40,
          battleEngineMethod: 's_explosion',
        ),
      );

      final events = _eventsFor(result, moveId: 'explosion');
      expect(
          events.map((event) => event.kind),
          containsAllInOrder(<String>[
            'move_immune',
            'animation_cue',
            'damage',
          ]));
      final damage = _damageEvents(result, moveId: 'explosion');
      expect(damage, hasLength(1));
      expect(damage.single.target, psdkPlayerSlot);
      expect(damage.single.damage, 13);
      expect(damage.single.remainingHp, 0);
      expect(result.state.battlerAt(psdkOpponentSlot).currentHp, 100);
      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 0);
      expect(result.state.outcome?.kind, PsdkBattleOutcomeKind.defeat);
    });

    test('s_explosion self-KOs when blocked by Protect', () {
      final result = _runMove(
        opponentEffects: PsdkBattleEffectStack(
          values: const <String>[PsdkBattleEffectIds.protect],
        ),
        playerMove: _move(
          id: 'explosion',
          power: 40,
          battleEngineMethod: 's_explosion',
        ),
      );

      final events = _eventsFor(result, moveId: 'explosion');
      expect(events.map((event) => event.kind), <String>[
        'move_pp_spent',
        'move_declared',
        'move_failed',
        'animation_cue',
        'damage',
      ]);
      expect((events[2] as PsdkBattleMoveFailedEvent).reason,
          BattleMoveFailureReason.protected.jsonName);
      final damage = _damageEvents(result, moveId: 'explosion');
      expect(damage, hasLength(1));
      expect(damage.single.target, psdkPlayerSlot);
      expect(damage.single.damage, 100);
      expect(result.state.battlerAt(psdkOpponentSlot).currentHp, 100);
      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 0);
      expect(result.state.outcome?.kind, PsdkBattleOutcomeKind.defeat);
    });

    test('s_explosion does not self-KO when PP prevents execution', () {
      final result = _runMove(
        playerMove: _move(
          id: 'explosion',
          power: 40,
          currentPp: 0,
          battleEngineMethod: 's_explosion',
        ),
      );

      final events = _eventsFor(result, moveId: 'explosion');
      expect(events.map((event) => event.kind), <String>['move_failed']);
      expect((events.single as PsdkBattleMoveFailedEvent).reason,
          BattleMoveFailureReason.pp.jsonName);
      expect(_damageEvents(result, moveId: 'explosion'), isEmpty);
      expect(result.state.battlerAt(psdkOpponentSlot).currentHp, 100);
      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 100);
      expect(result.state.outcome, isNull);
    });

    test('s_explosion applies secondary effects before successful self-KO', () {
      final result = _runMove(
        playerMove: _move(
          id: 'explosion',
          power: 40,
          battleEngineMethod: 's_explosion',
          statuses: <PsdkBattleMoveStatus>[
            PsdkBattleMoveStatus(
              status: PsdkBattleMajorStatus.burn,
              chance: 100,
            ),
          ],
        ),
      );

      final events = _eventsFor(result, moveId: 'explosion');
      expect(
        events.map((event) => event.kind),
        containsAllInOrder(<String>[
          'damage',
          'status',
          'damage',
        ]),
      );
      expect(result.state.battlerAt(psdkOpponentSlot).majorStatus,
          PsdkBattleMajorStatus.burn);
      expect(_damageEvents(result, moveId: 'explosion').last.target,
          psdkPlayerSlot);
    });

    test('s_misty_explosion boosts target damage on Misty Terrain', () {
      final noTerrain = _runMove(
        playerMove: _move(
          id: 'misty_explosion',
          power: 40,
          battleEngineMethod: 's_misty_explosion',
        ),
      );
      final mistyTerrain = _runMove(
        field: const PsdkBattleFieldState(
          terrain: PsdkBattleTerrainState(
            id: PsdkBattleTerrainId.mistyTerrain,
            remainingTurns: 5,
          ),
        ),
        playerMove: _move(
          id: 'misty_explosion',
          power: 40,
          battleEngineMethod: 's_misty_explosion',
        ),
      );

      expect(
        _damageEvents(mistyTerrain, moveId: 'misty_explosion').first.damage,
        greaterThan(
          _damageEvents(noTerrain, moveId: 'misty_explosion').first.damage,
        ),
      );
      expect(_damageEvents(mistyTerrain, moveId: 'misty_explosion').last.target,
          psdkPlayerSlot);
      expect(mistyTerrain.state.battlerAt(psdkPlayerSlot).currentHp, 0);
    });
  });
}

PsdkBattleTurnResult _runMove({
  required PsdkBattleMoveData playerMove,
  PsdkBattleFieldState field = const PsdkBattleFieldState(),
  int playerCurrentHp = 100,
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
        maxHp: 100,
        currentHp: playerCurrentHp,
        speed: 100,
        types: const PsdkBattleTypes(primary: 'fire'),
        move: playerMove,
      ),
      opponent: _combatant(
        id: 'opponent',
        maxHp: 100,
        currentHp: 100,
        speed: 1,
        types: opponentTypes,
        effects: opponentEffects,
        move: _move(
          id: 'opponent_wait',
          power: 0,
          battleEngineMethod: 's_splash',
        ),
      ),
      rngSeeds: rngSeeds.psdkSeeds,
      field: field,
    ).psdkSetup,
  );
  return engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  required int maxHp,
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
    maxHp: maxHp,
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
  int pp = 35,
  int? currentPp,
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
    pp: pp,
    currentPp: currentPp,
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
