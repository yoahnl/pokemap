import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK status utility move families', () {
    test('s_purify cures target major status and heals the user by half max HP',
        () {
      final result = _runMove(
        playerCurrentHp: 40,
        opponentMajorStatus: PsdkBattleMajorStatus.burn,
        playerMove: _move(
          id: 'purify',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          battleEngineMethod: 's_purify',
        ),
      );

      final cure = _cureEvents(result, moveId: 'purify');
      final heal = _healEvents(result, moveId: 'purify');
      expect(cure, hasLength(1));
      expect(cure.single.target, psdkOpponentSlot);
      expect(cure.single.status, PsdkBattleMajorStatus.burn);
      expect(heal, hasLength(1));
      expect(heal.single.target, psdkPlayerSlot);
      expect(heal.single.amount, 50);
      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 90);
      expect(result.state.battlerAt(psdkOpponentSlot).majorStatus, isNull);
      expect(
        _eventsFor(result, moveId: 'purify').map((event) => event.kind),
        containsAllInOrder(<String>[
          'move_pp_spent',
          'move_declared',
          'animation_cue',
          'status_cure',
          'heal',
        ]),
      );
    });

    test('s_purify fails before PP and declaration when target has no status',
        () {
      final result = _runMove(
        playerCurrentHp: 40,
        playerMove: _move(
          id: 'purify',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          battleEngineMethod: 's_purify',
        ),
      );

      final events = _eventsFor(result, moveId: 'purify');
      expect(events.map((event) => event.kind), <String>['move_failed']);
      expect(
        (events.single as PsdkBattleMoveFailedEvent).reason,
        BattleMoveFailureReason.unusableByUser.jsonName,
      );
      expect(_healEvents(result, moveId: 'purify'), isEmpty);
      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 40);
      expect(result.state.battlerAt(psdkPlayerSlot).moves.single.currentPp, 35);
    });

    test('s_psycho_shift transfers user major status and cures the user', () {
      final result = _runMove(
        playerMajorStatus: PsdkBattleMajorStatus.burn,
        playerMove: _move(
          id: 'psycho_shift',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          battleEngineMethod: 's_psycho_shift',
        ),
      );

      final status = _statusEvents(result, moveId: 'psycho_shift');
      final cure = _cureEvents(result, moveId: 'psycho_shift');
      expect(status, hasLength(1));
      expect(status.single.target, psdkOpponentSlot);
      expect(status.single.status, PsdkBattleMajorStatus.burn);
      expect(cure, hasLength(1));
      expect(cure.single.target, psdkPlayerSlot);
      expect(cure.single.status, PsdkBattleMajorStatus.burn);
      expect(result.state.battlerAt(psdkPlayerSlot).majorStatus, isNull);
      expect(
        result.state.battlerAt(psdkOpponentSlot).majorStatus,
        PsdkBattleMajorStatus.burn,
      );
      expect(
        _eventsFor(result, moveId: 'psycho_shift').map((event) => event.kind),
        containsAllInOrder(<String>[
          'move_pp_spent',
          'move_declared',
          'animation_cue',
          'status',
          'status_cure',
        ]),
      );
    });

    test('s_psycho_shift fails before PP when the user has no major status',
        () {
      final result = _runMove(
        playerMove: _move(
          id: 'psycho_shift',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          battleEngineMethod: 's_psycho_shift',
        ),
      );

      final events = _eventsFor(result, moveId: 'psycho_shift');
      expect(events.map((event) => event.kind), <String>['move_failed']);
      expect(
        (events.single as PsdkBattleMoveFailedEvent).reason,
        BattleMoveFailureReason.unusableByUser.jsonName,
      );
      expect(result.state.battlerAt(psdkPlayerSlot).moves.single.currentPp, 35);
    });
  });
}

PsdkBattleTurnResult _runMove({
  required PsdkBattleMoveData playerMove,
  int playerCurrentHp = 100,
  PsdkBattleMajorStatus? playerMajorStatus,
  PsdkBattleMajorStatus? opponentMajorStatus,
}) {
  final engine = PsdkBattleEngine(
    setup: BattleEngineSetup.singles(
      player: _combatant(
        id: 'player',
        currentHp: playerCurrentHp,
        speed: 100,
        move: playerMove,
        majorStatus: playerMajorStatus,
      ),
      opponent: _combatant(
        id: 'opponent',
        currentHp: 100,
        speed: 1,
        move: _move(
          id: 'opponent_wait',
          power: 0,
          accuracy: 1,
        ),
        majorStatus: opponentMajorStatus,
      ),
      rngSeeds: const BattleRngSeeds(
        moveDamage: 1,
        moveCritical: 99999,
        moveAccuracy: 3,
        generic: 4,
      ).psdkSeeds,
    ).psdkSetup,
  );
  return engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  required int currentHp,
  required int speed,
  required PsdkBattleMoveData move,
  PsdkBattleMajorStatus? majorStatus,
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
    moves: <PsdkBattleMoveData>[move],
    majorStatus: majorStatus,
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

List<PsdkBattleEvent> _eventsFor(
  PsdkBattleTurnResult result, {
  required String moveId,
}) {
  return result.timeline.events
      .where((event) => event.toJson()['moveId'] == moveId)
      .toList(growable: false);
}

List<PsdkBattleStatusCureEvent> _cureEvents(
  PsdkBattleTurnResult result, {
  required String moveId,
}) {
  return result.timeline.events
      .whereType<PsdkBattleStatusCureEvent>()
      .where((event) => event.moveId == moveId)
      .toList(growable: false);
}

List<PsdkBattleStatusEvent> _statusEvents(
  PsdkBattleTurnResult result, {
  required String moveId,
}) {
  return result.timeline.events
      .whereType<PsdkBattleStatusEvent>()
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
