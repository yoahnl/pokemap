import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK Basic spread moves', () {
    test('s_basic damages each adjacent spread target', () {
      final result = _executeSpreadMove(
        _move(
          id: 'swift',
          power: 60,
          target: PsdkBattleMoveTarget.allAdjacent,
        ),
      );

      final damageEvents = _damageEvents(result, moveId: 'swift');

      expect(damageEvents.map((event) => event.target), <PsdkBattleSlotRef>[
        _playerRightSlot,
        psdkOpponentSlot,
        _opponentRightSlot,
      ]);
      for (final target in <PsdkBattleSlotRef>[
        _playerRightSlot,
        psdkOpponentSlot,
        _opponentRightSlot,
      ]) {
        expect(result.state.battlerAt(target).currentHp, lessThan(100));
      }
    });

    test('s_basic applies secondary status to each successful spread target',
        () {
      final result = _executeSpreadMove(
        _move(
          id: 'discharge',
          type: 'electric',
          category: PsdkBattleMoveCategory.special,
          power: 80,
          target: PsdkBattleMoveTarget.allAdjacent,
          effectChance: 100,
          statuses: <PsdkBattleMoveStatus>[
            PsdkBattleMoveStatus(
              status: PsdkBattleMajorStatus.paralysis,
              chance: 100,
            ),
          ],
        ),
      );

      final statusEvents = result.events
          .whereType<PsdkBattleStatusEvent>()
          .where((event) => event.moveId == 'discharge')
          .toList(growable: false);

      expect(statusEvents.map((event) => event.target), <PsdkBattleSlotRef>[
        _playerRightSlot,
        psdkOpponentSlot,
        _opponentRightSlot,
      ]);
      expect(
        _damageAndStatusKinds(result, moveId: 'discharge'),
        <String>['damage', 'damage', 'damage', 'status', 'status', 'status'],
      );
      for (final target in <PsdkBattleSlotRef>[
        _playerRightSlot,
        psdkOpponentSlot,
        _opponentRightSlot,
      ]) {
        expect(
          result.state.battlerAt(target).majorStatus,
          PsdkBattleMajorStatus.paralysis,
        );
      }
    });

    test('s_basic rolls spread secondary chance once for the whole move', () {
      final initialRng = BattleRngStreams.fromSeeds(
        moveDamageSeed: 1,
        moveCriticalSeed: 99999,
        moveAccuracySeed: 3,
        genericSeed: 99,
      );
      final result = _executeSpreadMove(
        _move(
          id: 'discharge',
          type: 'electric',
          category: PsdkBattleMoveCategory.special,
          power: 80,
          target: PsdkBattleMoveTarget.allAdjacent,
          effectChance: 1,
          statuses: <PsdkBattleMoveStatus>[
            PsdkBattleMoveStatus(
              status: PsdkBattleMajorStatus.paralysis,
              chance: 100,
            ),
          ],
        ),
        rng: initialRng,
      );

      final expectedGenericSeed = initialRng.generic.nextPercent().next.seed;

      expect(_damageEvents(result, moveId: 'discharge'), hasLength(3));
      expect(result.events.whereType<PsdkBattleStatusEvent>(), isEmpty);
      expect(result.rng.seeds.generic, expectedGenericSeed);
    });

    test('s_basic Sheer Force suppresses spread secondaries after chance RNG',
        () {
      final initialRng = BattleRngStreams.fromSeeds(
        moveDamageSeed: 1,
        moveCriticalSeed: 99999,
        moveAccuracySeed: 3,
        genericSeed: 99,
      );
      final result = _executeSpreadMove(
        _move(
          id: 'discharge',
          type: 'electric',
          category: PsdkBattleMoveCategory.special,
          power: 80,
          target: PsdkBattleMoveTarget.allAdjacent,
          effectChance: 1,
          statuses: <PsdkBattleMoveStatus>[
            PsdkBattleMoveStatus(
              status: PsdkBattleMajorStatus.paralysis,
              chance: 100,
            ),
          ],
        ),
        rng: initialRng,
        playerAbilityId: 'sheer_force',
      );

      final expectedGenericSeed = initialRng.generic.nextPercent().next.seed;

      expect(_damageEvents(result, moveId: 'discharge'), hasLength(3));
      expect(result.events.whereType<PsdkBattleStatusEvent>(), isEmpty);
      expect(result.rng.seeds.generic, expectedGenericSeed);
    });

    test('s_basic Serene Grace doubles spread secondary chance once', () {
      final initialRng = BattleRngStreams.fromSeeds(
        moveDamageSeed: 1,
        moveCriticalSeed: 99999,
        moveAccuracySeed: 3,
        genericSeed: 49,
      );
      final result = _executeSpreadMove(
        _move(
          id: 'discharge',
          type: 'electric',
          category: PsdkBattleMoveCategory.special,
          power: 80,
          target: PsdkBattleMoveTarget.allAdjacent,
          effectChance: 30,
          statuses: <PsdkBattleMoveStatus>[
            PsdkBattleMoveStatus(
              status: PsdkBattleMajorStatus.paralysis,
              chance: 100,
            ),
          ],
        ),
        rng: initialRng,
        playerAbilityId: 'serene_grace',
      );

      final expectedGenericSeed = initialRng.generic.nextPercent().next.seed;

      expect(_damageEvents(result, moveId: 'discharge'), hasLength(3));
      expect(
        result.events.whereType<PsdkBattleStatusEvent>().map((event) {
          return event.target;
        }),
        <PsdkBattleSlotRef>[
          _playerRightSlot,
          psdkOpponentSlot,
          _opponentRightSlot,
        ],
      );
      expect(result.rng.seeds.generic, expectedGenericSeed);
    });

    test('s_basic applies spread secondaries around Shield Dust targets', () {
      final result = _executeSpreadMove(
        _move(
          id: 'discharge',
          type: 'electric',
          category: PsdkBattleMoveCategory.special,
          power: 80,
          target: PsdkBattleMoveTarget.allAdjacent,
          effectChance: 100,
          statuses: <PsdkBattleMoveStatus>[
            PsdkBattleMoveStatus(
              status: PsdkBattleMajorStatus.paralysis,
              chance: 100,
            ),
          ],
        ),
        playerRightAbilityId: 'shield_dust',
      );

      final statusEvents = result.events
          .whereType<PsdkBattleStatusEvent>()
          .where((event) => event.moveId == 'discharge')
          .toList(growable: false);

      expect(_damageEvents(result, moveId: 'discharge'), hasLength(3));
      expect(statusEvents.map((event) => event.target), <PsdkBattleSlotRef>[
        psdkOpponentSlot,
        _opponentRightSlot,
      ]);
      expect(result.state.battlerAt(_playerRightSlot).majorStatus, isNull);
      expect(
        result.state.battlerAt(psdkOpponentSlot).majorStatus,
        PsdkBattleMajorStatus.paralysis,
      );
      expect(
        result.state.battlerAt(_opponentRightSlot).majorStatus,
        PsdkBattleMajorStatus.paralysis,
      );
    });

    test(
        's_basic applies secondary stat drops to each successful spread target',
        () {
      final result = _executeSpreadMove(
        _move(
          id: 'bulldoze',
          type: 'ground',
          power: 60,
          target: PsdkBattleMoveTarget.allAdjacent,
          effectChance: 100,
          stageMods: const <PsdkBattleMoveStageMod>[
            PsdkBattleMoveStageMod(
              stat: 'speed',
              stages: -1,
              chance: 100,
            ),
          ],
        ),
      );

      final statEvents = result.events
          .whereType<PsdkBattleStatStageEvent>()
          .where((event) => event.stat == 'speed')
          .toList(growable: false);

      expect(statEvents.map((event) => event.target), <PsdkBattleSlotRef>[
        _playerRightSlot,
        psdkOpponentSlot,
        _opponentRightSlot,
      ]);
      expect(
        _damageAndStatKinds(result, moveId: 'bulldoze'),
        <String>[
          'damage',
          'damage',
          'damage',
          'stat_stage_change',
          'stat_stage_change',
          'stat_stage_change',
        ],
      );
      for (final target in <PsdkBattleSlotRef>[
        _playerRightSlot,
        psdkOpponentSlot,
        _opponentRightSlot,
      ]) {
        expect(result.state.battlerAt(target).statStages.valueOf('speed'), -1);
      }
    });
  });
}

List<String> _damageAndStatusKinds(
  BattleMoveBehaviorResolution result, {
  required String moveId,
}) {
  return result.events
      .where((event) {
        final payload = event.toJson();
        return payload['moveId'] == moveId &&
            (event.kind == 'damage' || event.kind == 'status');
      })
      .map((event) => event.kind)
      .toList(growable: false);
}

List<String> _damageAndStatKinds(
  BattleMoveBehaviorResolution result, {
  required String moveId,
}) {
  return result.events
      .where((event) {
        final payload = event.toJson();
        return event.kind == 'stat_stage_change' ||
            (payload['moveId'] == moveId && event.kind == 'damage');
      })
      .map((event) => event.kind)
      .toList(growable: false);
}

BattleMoveBehaviorResolution _executeSpreadMove(
  PsdkBattleMoveData move, {
  BattleRngStreams? rng,
  String? playerAbilityId,
  String? playerRightAbilityId,
  String? opponentAbilityId,
  String? opponentRightAbilityId,
}) {
  return const PsdkBattleMoveExecutor().execute(
    PsdkBattleMoveRequest(
      state: _doublesState(
        playerAbilityId: playerAbilityId,
        playerRightAbilityId: playerRightAbilityId,
        opponentAbilityId: opponentAbilityId,
        opponentRightAbilityId: opponentRightAbilityId,
      ),
      rng: rng ??
          BattleRngStreams.fromSeeds(
            moveDamageSeed: 1,
            moveCriticalSeed: 99999,
            moveAccuracySeed: 3,
            genericSeed: 4,
          ),
      turn: 1,
      user: psdkPlayerSlot,
      target: psdkOpponentSlot,
      moveId: move.id,
      battleEngineMethod: move.battleEngineMethod,
      studioMove: move,
    ),
  );
}

List<PsdkBattleDamageEvent> _damageEvents(
  BattleMoveBehaviorResolution result, {
  required String moveId,
}) {
  return result.events
      .whereType<PsdkBattleDamageEvent>()
      .where((event) => event.moveId == moveId)
      .toList(growable: false);
}

PsdkBattleState _doublesState({
  String? playerAbilityId,
  String? playerRightAbilityId,
  String? opponentAbilityId,
  String? opponentRightAbilityId,
}) {
  return PsdkBattleState(
    combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
      psdkPlayerSlot: PsdkBattleCombatant.fromSetup(
        _combatant(
          id: 'player',
          move: _move(id: 'swift', power: 60),
          abilityId: playerAbilityId,
        ),
      ),
      _playerRightSlot: PsdkBattleCombatant.fromSetup(
        _combatant(
          id: 'player_ally',
          move: _move(id: 'ally_wait', power: 0),
          abilityId: playerRightAbilityId,
        ),
      ),
      psdkOpponentSlot: PsdkBattleCombatant.fromSetup(
        _combatant(
          id: 'opponent',
          move: _move(id: 'opponent_wait', power: 0),
          abilityId: opponentAbilityId,
        ),
      ),
      _opponentRightSlot: PsdkBattleCombatant.fromSetup(
        _combatant(
          id: 'opponent_ally',
          move: _move(id: 'opponent_ally_wait', power: 0),
          abilityId: opponentRightAbilityId,
        ),
      ),
    },
  );
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  required PsdkBattleMoveData move,
  String? abilityId,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 20,
    maxHp: 100,
    currentHp: 100,
    abilityId: abilityId,
    types: const PsdkBattleTypes(primary: 'normal'),
    stats: const PsdkBattleStats(
      attack: 50,
      defense: 50,
      specialAttack: 50,
      specialDefense: 50,
      speed: 50,
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
  PsdkBattleMoveTarget target = PsdkBattleMoveTarget.adjacentFoe,
  int? effectChance,
  List<PsdkBattleMoveStatus> statuses = const <PsdkBattleMoveStatus>[],
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
    battleEngineMethod: 's_basic',
    target: target,
    effectChance: effectChance,
    statuses: statuses,
    stageMods: stageMods,
  );
}

const _playerRightSlot = PsdkBattleSlotRef(bank: 0, position: 1);
const _opponentRightSlot = PsdkBattleSlotRef(bank: 1, position: 1);
