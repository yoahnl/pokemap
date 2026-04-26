import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK no-effect move families', () {
    test('s_splash consumes the common move pipeline without mutating HP', () {
      final result = _runMove(
        playerMove: _move(
          id: 'splash',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          battleEngineMethod: 's_splash',
        ),
      );

      final splashEvents = _eventsFor(result, moveId: 'splash');
      expect(
        splashEvents.map((event) => event.kind),
        containsAllInOrder(<String>[
          'move_pp_spent',
          'move_declared',
          'animation_cue',
        ]),
      );
      expect(_damageEvents(result, moveId: 'splash'), isEmpty);
      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 100);
      expect(result.state.battlerAt(psdkOpponentSlot).currentHp, 100);
    });

    test('s_do_nothing still respects the shared miss pipeline', () {
      final result = _runMove(
        playerMove: _move(
          id: 'hold_hands',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 1,
          battleEngineMethod: 's_do_nothing',
        ),
        rngSeeds: const BattleRngSeeds(
          moveDamage: 1,
          moveCritical: 99999,
          moveAccuracy: 99,
          generic: 4,
        ),
      );

      final holdHandsEvents = _eventsFor(result, moveId: 'hold_hands');
      expect(
        holdHandsEvents.map((event) => event.kind),
        containsAllInOrder(<String>[
          'move_pp_spent',
          'move_declared',
          'miss',
        ]),
      );
      expect(
        holdHandsEvents.map((event) => event.kind),
        isNot(contains('animation_cue')),
      );
      expect(_damageEvents(result, moveId: 'hold_hands'), isEmpty);
      expect(result.state.battlerAt(psdkOpponentSlot).currentHp, 100);
    });
  });

  group('PSDK direct-HP move families', () {
    test('s_endeavor lowers target HP to the user current HP', () {
      final result = _runMove(
        playerCurrentHp: 40,
        playerMove: _move(
          id: 'endeavor',
          power: 1,
          battleEngineMethod: 's_endeavor',
        ),
      );

      final damage = _damageEvents(result, moveId: 'endeavor');
      expect(damage, hasLength(1));
      expect(damage.single.damage, 60);
      expect(damage.single.remainingHp, 40);
      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 40);
      expect(result.state.battlerAt(psdkOpponentSlot).currentHp, 40);
    });

    test('s_endeavor fails before PP and declaration when it cannot lower HP',
        () {
      final result = _runMove(
        playerCurrentHp: 80,
        opponentCurrentHp: 40,
        playerMove: _move(
          id: 'endeavor',
          power: 1,
          battleEngineMethod: 's_endeavor',
        ),
      );

      final endeavorEvents = _eventsFor(result, moveId: 'endeavor');
      expect(endeavorEvents.map((event) => event.kind), <String>[
        'move_failed',
      ]);
      expect(
        (endeavorEvents.single as PsdkBattleMoveFailedEvent).reason,
        BattleMoveFailureReason.unusableByUser.jsonName,
      );
      expect(_damageEvents(result, moveId: 'endeavor'), isEmpty);
      expect(result.state.battlerAt(psdkPlayerSlot).moves.single.currentPp, 35);
      expect(result.state.battlerAt(psdkOpponentSlot).currentHp, 40);
    });

    test('s_final_gambit damages the user before damaging the target', () {
      final result = _runMove(
        playerCurrentHp: 40,
        playerMove: _move(
          id: 'final_gambit',
          type: 'fighting',
          category: PsdkBattleMoveCategory.special,
          power: 1,
          battleEngineMethod: 's_final_gambit',
        ),
      );

      final damage = _damageEvents(result, moveId: 'final_gambit');
      expect(damage, hasLength(2));
      expect(damage.first.target, psdkPlayerSlot);
      expect(damage.first.damage, 40);
      expect(damage.first.remainingHp, 0);
      expect(damage.last.target, psdkOpponentSlot);
      expect(damage.last.damage, 40);
      expect(damage.last.remainingHp, 60);
      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 0);
      expect(result.state.battlerAt(psdkOpponentSlot).currentHp, 60);
      expect(result.outcome?.kind, PsdkBattleOutcomeKind.defeat);
    });

    test('s_final_gambit keeps the shared immunity precheck before self-damage',
        () {
      final result = _runMove(
        playerCurrentHp: 40,
        opponentTypes: const PsdkBattleTypes(primary: 'ghost'),
        playerMove: _move(
          id: 'final_gambit',
          type: 'normal',
          category: PsdkBattleMoveCategory.physical,
          power: 1,
          battleEngineMethod: 's_final_gambit',
        ),
      );

      final kinds =
          _eventsFor(result, moveId: 'final_gambit').map((event) => event.kind);
      expect(kinds, contains('move_immune'));
      expect(kinds, isNot(contains('damage')));
      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 40);
      expect(result.state.battlerAt(psdkOpponentSlot).currentHp, 100);
    });

    test('s_pain_split shares current HP and bypasses accuracy', () {
      final result = _runMove(
        playerCurrentHp: 20,
        opponentCurrentHp: 90,
        playerMove: _move(
          id: 'pain_split',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 1,
          battleEngineMethod: 's_pain_split',
        ),
        rngSeeds: const BattleRngSeeds(
          moveDamage: 1,
          moveCritical: 99999,
          moveAccuracy: 99,
          generic: 4,
        ),
      );

      final heal = _healEvents(result, moveId: 'pain_split');
      final damage = _damageEvents(result, moveId: 'pain_split');
      expect(heal, hasLength(1));
      expect(heal.single.target, psdkPlayerSlot);
      expect(heal.single.amount, 35);
      expect(damage, hasLength(1));
      expect(damage.single.target, psdkOpponentSlot);
      expect(damage.single.damage, 35);
      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 55);
      expect(result.state.battlerAt(psdkOpponentSlot).currentHp, 55);
      expect(
        _eventsFor(result, moveId: 'pain_split').map((event) => event.kind),
        isNot(contains('miss')),
      );
    });
  });
}

PsdkBattleTurnResult _runMove({
  required PsdkBattleMoveData playerMove,
  int playerCurrentHp = 100,
  int opponentCurrentHp = 100,
  PsdkBattleTypes opponentTypes = const PsdkBattleTypes(primary: 'normal'),
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
        move: playerMove,
      ),
      opponent: _combatant(
        id: 'opponent',
        currentHp: opponentCurrentHp,
        speed: 1,
        types: opponentTypes,
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
  required PsdkBattleMoveData move,
  PsdkBattleTypes types = const PsdkBattleTypes(primary: 'normal'),
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

List<PsdkBattleHealEvent> _healEvents(
  PsdkBattleTurnResult result, {
  required String moveId,
}) {
  return result.timeline.events
      .whereType<PsdkBattleHealEvent>()
      .where((event) => event.moveId == moveId)
      .toList(growable: false);
}
