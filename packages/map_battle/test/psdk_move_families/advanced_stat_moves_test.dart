import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK advanced stat move families', () {
    test('s_growth raises attack and special attack by two in sun', () {
      final result = _runMove(
        field: const PsdkBattleFieldState(
          weather: PsdkBattleWeatherState(
            id: PsdkBattleWeatherId.sunny,
            remainingTurns: 5,
          ),
        ),
        playerMove: _move(
          id: 'growth',
          battleEngineMethod: 's_growth',
          power: 0,
          category: PsdkBattleMoveCategory.status,
          target: PsdkBattleMoveTarget.user,
          stageMods: const <PsdkBattleMoveStageMod>[
            PsdkBattleMoveStageMod(
              stat: 'attack',
              stages: 1,
              chance: 100,
            ),
            PsdkBattleMoveStageMod(
              stat: 'specialAttack',
              stages: 1,
              chance: 100,
            ),
          ],
        ),
      );
      final player = result.state.battlerAt(psdkPlayerSlot);

      expect(player.statStages.valueOf('attack'), 2);
      expect(player.statStages.valueOf('specialAttack'), 2);
      expect(_statEvents(result), hasLength(2));
      expect(_eventKinds(result), isNot(contains('damage')));
    });

    test('s_fillet_away spends half max HP and raises offensive stats', () {
      final result = _runMove(
        playerMove: _move(
          id: 'fillet_away',
          battleEngineMethod: 's_fillet_away',
          power: 0,
          category: PsdkBattleMoveCategory.status,
          target: PsdkBattleMoveTarget.user,
        ),
      );
      final player = result.state.battlerAt(psdkPlayerSlot);

      expect(player.currentHp, 50);
      expect(player.statStages.valueOf('attack'), 2);
      expect(player.statStages.valueOf('specialAttack'), 2);
      expect(player.statStages.valueOf('speed'), 2);
      expect(_damage(result, moveId: 'fillet_away'), 50);
      expect(_statEvents(result), hasLength(3));
    });

    test('s_haze resets non-neutral stat stages on every battler', () {
      final result = _runMove(
        playerStatStages: PsdkBattleStatStages(
          values: const <String, int>{'attack': 3, 'speed': -2},
        ),
        opponentStatStages: PsdkBattleStatStages(
          values: const <String, int>{'defense': -4},
        ),
        playerMove: _move(
          id: 'haze',
          battleEngineMethod: 's_haze',
          power: 0,
          category: PsdkBattleMoveCategory.status,
        ),
      );
      final player = result.state.battlerAt(psdkPlayerSlot);
      final opponent = result.state.battlerAt(psdkOpponentSlot);

      expect(player.statStages.values, isEmpty);
      expect(opponent.statStages.values, isEmpty);
      expect(_statEvents(result), hasLength(3));
      expect(_eventKinds(result), isNot(contains('damage')));
    });

    test('s_psych_up copies target stat stages onto the user', () {
      final result = _runMove(
        playerStatStages: PsdkBattleStatStages(
          values: const <String, int>{'speed': 2},
        ),
        opponentStatStages: PsdkBattleStatStages(
          values: const <String, int>{'attack': 3, 'defense': -1},
        ),
        playerMove: _move(
          id: 'psych_up',
          battleEngineMethod: 's_psych_up',
          power: 0,
          category: PsdkBattleMoveCategory.status,
        ),
      );
      final player = result.state.battlerAt(psdkPlayerSlot);
      final opponent = result.state.battlerAt(psdkOpponentSlot);

      expect(player.statStages.valueOf('attack'), 3);
      expect(player.statStages.valueOf('defense'), -1);
      expect(player.statStages.valueOf('speed'), 0);
      expect(opponent.statStages.valueOf('attack'), 3);
      expect(_statEvents(result), hasLength(3));
    });

    test('s_topsy_turvy inverts target stat stages', () {
      final result = _runMove(
        opponentStatStages: PsdkBattleStatStages(
          values: const <String, int>{'attack': 2, 'defense': -3},
        ),
        playerMove: _move(
          id: 'topsy_turvy',
          battleEngineMethod: 's_topsy_turvy',
          power: 0,
          category: PsdkBattleMoveCategory.status,
        ),
      );
      final opponent = result.state.battlerAt(psdkOpponentSlot);

      expect(opponent.statStages.valueOf('attack'), -2);
      expect(opponent.statStages.valueOf('defense'), 3);
      expect(_statEvents(result), hasLength(2));
    });
  });
}

PsdkBattleTurnResult _runMove({
  required PsdkBattleMoveData playerMove,
  PsdkBattleFieldState field = const PsdkBattleFieldState(),
  PsdkBattleStatStages? playerStatStages,
  PsdkBattleStatStages? opponentStatStages,
}) {
  final engine = PsdkBattleEngine(
    setup: PsdkBattleSetup.singles(
      player: _combatant(
        id: 'player',
        speed: 100,
        move: playerMove,
        statStages: playerStatStages,
      ),
      opponent: _combatant(
        id: 'opponent',
        speed: 1,
        move: _move(
          id: 'opponent_wait',
          power: 0,
          accuracy: 1,
        ),
        statStages: opponentStatStages,
      ),
      rngSeeds: const PsdkBattleRngSeeds(
        moveDamage: 1,
        moveCritical: 99999,
        moveAccuracy: 3,
        generic: 4,
      ),
      field: field,
    ),
  );
  return engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  required int speed,
  required PsdkBattleMoveData move,
  PsdkBattleStatStages? statStages,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 20,
    maxHp: 100,
    currentHp: 100,
    types: const PsdkBattleTypes(primary: 'normal'),
    stats: PsdkBattleStats(
      attack: 50,
      defense: 50,
      specialAttack: 50,
      specialDefense: 50,
      speed: speed,
    ),
    moves: <PsdkBattleMoveData>[move],
    statStages: statStages,
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
  List<PsdkBattleMoveStageMod> stageMods = const <PsdkBattleMoveStageMod>[],
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
    stageMods: stageMods,
  );
}

List<String> _eventKinds(PsdkBattleTurnResult result) {
  return result.timeline.events.map((event) => event.kind).toList();
}

List<PsdkBattleStatStageEvent> _statEvents(PsdkBattleTurnResult result) {
  return result.timeline.events
      .whereType<PsdkBattleStatStageEvent>()
      .toList(growable: false);
}

int _damage(
  PsdkBattleTurnResult result, {
  required String moveId,
}) {
  return result.timeline.events
      .whereType<PsdkBattleDamageEvent>()
      .singleWhere((event) => event.moveId == moveId)
      .damage;
}
