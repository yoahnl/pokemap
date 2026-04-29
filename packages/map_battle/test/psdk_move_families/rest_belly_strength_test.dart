import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK rest belly drum and strength sap move families', () {
    test('s_rest replaces the user status with sleep and fully heals', () {
      final result = _runMove(
        playerCurrentHp: 30,
        playerMajorStatus: PsdkBattleMajorStatus.burn,
        playerMove: _move(
          id: 'rest',
          battleEngineMethod: 's_rest',
          power: 0,
          category: PsdkBattleMoveCategory.status,
          target: PsdkBattleMoveTarget.user,
        ),
      );
      final player = result.state.battlerAt(psdkPlayerSlot);

      expect(player.currentHp, 100);
      expect(player.majorStatus, PsdkBattleMajorStatus.sleep);
      expect(
        _moveKinds(result, moveId: 'rest'),
        containsAllInOrder(<String>[
          'status_cure',
          'status',
          'heal',
        ]),
      );
      expect(_healJson(result, moveId: 'rest')['amount'], 70);
    });

    test('s_rest fails before PP spending when the user is already full HP',
        () {
      final result = _runMove(
        playerMove: _move(
          id: 'rest',
          battleEngineMethod: 's_rest',
          power: 0,
          category: PsdkBattleMoveCategory.status,
          target: PsdkBattleMoveTarget.user,
        ),
      );
      final player = result.state.battlerAt(psdkPlayerSlot);
      final restEvents = _moveJsonEvents(result, moveId: 'rest');

      expect(player.currentHp, 100);
      expect(player.majorStatus, isNull);
      expect(restEvents.map((event) => event['kind']), <String>[
        'move_failed',
      ]);
      expect(restEvents.single['reason'], 'unusable_by_user');
    });

    for (final terrainId in <PsdkBattleTerrainId>[
      PsdkBattleTerrainId.electricTerrain,
      PsdkBattleTerrainId.mistyTerrain,
    ]) {
      test('s_rest fails for grounded users under ${terrainId.jsonName}', () {
        final result = _runMove(
          playerCurrentHp: 30,
          field: PsdkBattleFieldState(
            terrain: PsdkBattleTerrainState(
              id: terrainId,
              remainingTurns: 5,
            ),
          ),
          playerMove: _move(
            id: 'rest',
            battleEngineMethod: 's_rest',
            power: 0,
            category: PsdkBattleMoveCategory.status,
            target: PsdkBattleMoveTarget.user,
          ),
        );
        final player = result.state.battlerAt(psdkPlayerSlot);
        final restEvents = _moveJsonEvents(result, moveId: 'rest');

        expect(player.currentHp, 30);
        expect(player.majorStatus, isNull);
        expect(player.moves.single.currentPp, 35);
        expect(restEvents.map((event) => event['kind']), <String>[
          'move_failed',
        ]);
        expect(restEvents.single['reason'], 'unusable_by_user');
      });
    }

    for (final berryId in <String>['chesto_berry', 'lum_berry']) {
      test('s_rest consumes $berryId to cure its own sleep immediately', () {
        final result = _runMove(
          playerCurrentHp: 30,
          playerHeldItemId: berryId,
          playerMove: _move(
            id: 'rest',
            battleEngineMethod: 's_rest',
            power: 0,
            category: PsdkBattleMoveCategory.status,
            target: PsdkBattleMoveTarget.user,
          ),
        );
        final player = result.state.battlerAt(psdkPlayerSlot);

        expect(player.currentHp, 100);
        expect(player.majorStatus, isNull);
        expect(player.heldItemId, isNull);
        expect(player.consumedItemId, berryId);
        expect(player.itemConsumed, isTrue);
        expect(
          _moveKinds(result, moveId: 'rest'),
          containsAllInOrder(<String>[
            'status',
            'heal',
            'status_cure',
          ]),
        );
      });
    }

    test('s_bellydrum spends half max HP and maximizes attack stage', () {
      final result = _runMove(
        playerMove: _move(
          id: 'belly_drum',
          battleEngineMethod: 's_bellydrum',
          power: 0,
          category: PsdkBattleMoveCategory.status,
          target: PsdkBattleMoveTarget.user,
        ),
      );
      final player = result.state.battlerAt(psdkPlayerSlot);

      expect(player.currentHp, 50);
      expect(player.statStages.valueOf('attack'), 6);
      expect(_damage(result, moveId: 'belly_drum'), 50);
      expect(
        result.timeline.events
            .whereType<PsdkBattleStatStageEvent>()
            .single
            .stat,
        'attack',
      );
    });

    test('s_bellydrum fails when the user cannot pay the HP cost', () {
      final result = _runMove(
        playerCurrentHp: 50,
        playerMove: _move(
          id: 'belly_drum',
          battleEngineMethod: 's_bellydrum',
          power: 0,
          category: PsdkBattleMoveCategory.status,
          target: PsdkBattleMoveTarget.user,
        ),
      );
      final player = result.state.battlerAt(psdkPlayerSlot);
      final bellyDrumEvents = _moveJsonEvents(result, moveId: 'belly_drum');

      expect(player.currentHp, 50);
      expect(player.statStages.valueOf('attack'), 0);
      expect(bellyDrumEvents.map((event) => event['kind']), <String>[
        'move_failed',
      ]);
      expect(bellyDrumEvents.single['reason'], 'unusable_by_user');
    });

    test('s_bellydrum fails when attack is already maximized', () {
      final result = _runMove(
        playerStatStages: PsdkBattleStatStages(
          values: const <String, int>{'attack': 6},
        ),
        playerMove: _move(
          id: 'belly_drum',
          battleEngineMethod: 's_bellydrum',
          power: 0,
          category: PsdkBattleMoveCategory.status,
          target: PsdkBattleMoveTarget.user,
        ),
      );
      final player = result.state.battlerAt(psdkPlayerSlot);
      final bellyDrumEvents = _moveJsonEvents(result, moveId: 'belly_drum');

      expect(player.currentHp, 100);
      expect(player.statStages.valueOf('attack'), 6);
      expect(bellyDrumEvents.map((event) => event['kind']), <String>[
        'move_failed',
      ]);
      expect(bellyDrumEvents.single['reason'], 'unusable_by_user');
    });

    test('s_strength_sap heals from target attack and lowers attack', () {
      final result = _runMove(
        playerCurrentHp: 10,
        opponentStats: const PsdkBattleStats(
          attack: 70,
          defense: 50,
          specialAttack: 50,
          specialDefense: 50,
          speed: 1,
        ),
        playerMove: _move(
          id: 'strength_sap',
          battleEngineMethod: 's_strength_sap',
          power: 0,
          category: PsdkBattleMoveCategory.status,
          stageMods: const <PsdkBattleMoveStageMod>[
            PsdkBattleMoveStageMod(
              stat: 'attack',
              stages: -1,
              chance: 100,
            ),
          ],
        ),
      );

      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 80);
      expect(
          result.state.battlerAt(psdkOpponentSlot).statStages.valueOf('attack'),
          -1);
      expect(_healJson(result, moveId: 'strength_sap')['amount'], 70);
      expect(
        result.timeline.events.map((event) => event.kind),
        containsAllInOrder(<String>['heal', 'stat_stage_change']),
      );
    });

    test('s_strength_sap fails when target attack cannot drop', () {
      final result = _runMove(
        playerCurrentHp: 10,
        opponentStatStages: PsdkBattleStatStages(
          values: const <String, int>{'attack': -6},
        ),
        playerMove: _move(
          id: 'strength_sap',
          battleEngineMethod: 's_strength_sap',
          power: 0,
          category: PsdkBattleMoveCategory.status,
          stageMods: const <PsdkBattleMoveStageMod>[
            PsdkBattleMoveStageMod(
              stat: 'attack',
              stages: -1,
              chance: 100,
            ),
          ],
        ),
      );
      final player = result.state.battlerAt(psdkPlayerSlot);
      final opponent = result.state.battlerAt(psdkOpponentSlot);
      final strengthSapEvents = _moveJsonEvents(result, moveId: 'strength_sap');

      expect(player.currentHp, 10);
      expect(opponent.statStages.valueOf('attack'), -6);
      expect(strengthSapEvents.map((event) => event['kind']), <String>[
        'move_failed',
      ]);
      expect(strengthSapEvents.single['reason'], 'unusable_by_user');
    });
  });
}

PsdkBattleTurnResult _runMove({
  required PsdkBattleMoveData playerMove,
  int playerCurrentHp = 100,
  PsdkBattleMajorStatus? playerMajorStatus,
  String? playerHeldItemId,
  PsdkBattleStatStages? playerStatStages,
  PsdkBattleFieldState field = const PsdkBattleFieldState(),
  PsdkBattleStats opponentStats = const PsdkBattleStats(
    attack: 50,
    defense: 50,
    specialAttack: 50,
    specialDefense: 50,
    speed: 1,
  ),
  PsdkBattleStatStages? opponentStatStages,
}) {
  final engine = PsdkBattleEngine(
    setup: PsdkBattleSetup.singles(
      player: _combatant(
        id: 'player',
        currentHp: playerCurrentHp,
        speed: 100,
        move: playerMove,
        majorStatus: playerMajorStatus,
        heldItemId: playerHeldItemId,
        statStages: playerStatStages,
      ),
      opponent: _combatant(
        id: 'opponent',
        currentHp: 100,
        speed: 1,
        stats: opponentStats,
        statStages: opponentStatStages,
        move: _move(
          id: 'opponent_wait',
          power: 0,
          accuracy: 1,
        ),
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
  required int currentHp,
  required int speed,
  required PsdkBattleMoveData move,
  PsdkBattleMajorStatus? majorStatus,
  String? heldItemId,
  PsdkBattleStats? stats,
  PsdkBattleStatStages? statStages,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 20,
    maxHp: 100,
    currentHp: currentHp,
    heldItemId: heldItemId,
    types: const PsdkBattleTypes(primary: 'normal'),
    stats: stats ??
        PsdkBattleStats(
          attack: 50,
          defense: 50,
          specialAttack: 50,
          specialDefense: 50,
          speed: speed,
        ),
    moves: <PsdkBattleMoveData>[move],
    majorStatus: majorStatus,
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

List<String> _moveKinds(
  PsdkBattleTurnResult result, {
  required String moveId,
}) {
  return result.timeline.events
      .where((event) => event.toJson()['moveId'] == moveId)
      .map((event) => event.kind)
      .toList(growable: false);
}

Map<String, Object?> _healJson(
  PsdkBattleTurnResult result, {
  required String moveId,
}) {
  return result.timeline.events
      .where((event) => event.kind == 'heal')
      .map((event) => event.toJson())
      .singleWhere((json) => json['moveId'] == moveId);
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

List<Map<String, Object?>> _moveJsonEvents(
  PsdkBattleTurnResult result, {
  required String moveId,
}) {
  return result.timeline.events
      .map((event) => event.toJson())
      .where((event) => event['moveId'] == moveId)
      .toList(growable: false);
}
