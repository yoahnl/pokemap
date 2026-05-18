import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

const _mindBlownMethods = <String, String>{
  's_mind_blown': 'mind_blown',
  's_steel_beam': 'steel_beam',
  's_chloroblast': 'chloroblast',
};

void main() {
  group('PSDK MindBlown move families', () {
    for (final entry in _mindBlownMethods.entries) {
      test('${entry.key} applies target damage and half max HP crash', () {
        final result = _runMove(
          playerMove: _move(
            id: entry.value,
            power: 40,
            battleEngineMethod: entry.key,
          ),
        );

        final damage = _damageEvents(result, moveId: entry.value);
        expect(damage, hasLength(2));
        expect(damage.first.target, psdkOpponentSlot);
        expect(damage.first.damage, 8);
        expect(damage.first.remainingHp, 92);
        expect(damage.last.target, psdkPlayerSlot);
        expect(damage.last.damage, 50);
        expect(damage.last.remainingHp, 50);
        expect(result.state.battlerAt(psdkOpponentSlot).currentHp, 92);
        expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 50);
      });
    }

    for (final entry in _mindBlownMethods.entries) {
      test('${entry.key} skips the crash when the user has Wonder Guard', () {
        final result = _runMove(
          playerAbilityId: 'wonder_guard',
          playerMove: _move(
            id: entry.value,
            power: 40,
            battleEngineMethod: entry.key,
          ),
        );

        final damage = _damageEvents(result, moveId: entry.value);
        expect(damage, hasLength(1));
        expect(damage.single.target, psdkOpponentSlot);
        expect(damage.single.damage, 8);
        expect(result.state.battlerAt(psdkOpponentSlot).currentHp, 92);
        expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 100);
      });
    }

    test('s_mind_blown also skips the miss crash with Wonder Guard', () {
      final result = _runMove(
        playerAbilityId: 'wonder_guard',
        playerMove: _move(
          id: 'mind_blown',
          power: 40,
          accuracy: 90,
          battleEngineMethod: 's_mind_blown',
        ),
        rngSeeds: const BattleRngSeeds(
          moveDamage: 1,
          moveCritical: 99999,
          moveAccuracy: 99,
          generic: 4,
        ),
      );

      expect(
          _eventsFor(result, moveId: 'mind_blown').map((event) => event.kind),
          contains('miss'));
      expect(_damageEvents(result, moveId: 'mind_blown'), isEmpty);
      expect(result.state.battlerAt(psdkOpponentSlot).currentHp, 100);
      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 100);
    });

    test('s_chloroblast uses half max HP instead of recoil from damage dealt',
        () {
      final result = _runMove(
        playerCurrentHp: 80,
        playerMove: _move(
          id: 'chloroblast',
          power: 40,
          battleEngineMethod: 's_chloroblast',
        ),
      );

      final damage = _damageEvents(result, moveId: 'chloroblast');
      expect(damage, hasLength(2));
      expect(damage.first.damage, 8);
      expect(damage.last.damage, 50);
      expect(damage.last.remainingHp, 30);
      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 30);
    });

    for (final entry in _mindBlownMethods.entries) {
      test('${entry.key} crashes the user when the move misses', () {
        final result = _runMove(
          playerMove: _move(
            id: entry.value,
            power: 40,
            accuracy: 1,
            battleEngineMethod: entry.key,
          ),
          rngSeeds: const BattleRngSeeds(
            moveDamage: 1,
            moveCritical: 99999,
            moveAccuracy: 99,
            generic: 4,
          ),
        );

        final events = _eventsFor(result, moveId: entry.value);
        expect(
            events.map((event) => event.kind),
            containsAllInOrder(<String>[
              'miss',
              'damage',
            ]));
        final damage = _damageEvents(result, moveId: entry.value);
        expect(damage, hasLength(1));
        expect(damage.single.target, psdkPlayerSlot);
        expect(damage.single.damage, 50);
        expect(result.state.battlerAt(psdkOpponentSlot).currentHp, 100);
        expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 50);
      });
    }

    for (final entry in _mindBlownMethods.entries) {
      test('${entry.key} crashes the user when the target is type-immune', () {
        final result = _runMove(
          opponentTypes: const PsdkBattleTypes(primary: 'ghost'),
          playerMove: _move(
            id: entry.value,
            power: 40,
            battleEngineMethod: entry.key,
          ),
        );

        final events = _eventsFor(result, moveId: entry.value);
        expect(
            events.map((event) => event.kind),
            containsAllInOrder(<String>[
              'move_immune',
              'damage',
            ]));
        final damage = _damageEvents(result, moveId: entry.value);
        expect(damage, hasLength(1));
        expect(damage.single.target, psdkPlayerSlot);
        expect(damage.single.damage, 50);
        expect(result.state.battlerAt(psdkOpponentSlot).currentHp, 100);
        expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 50);
      });
    }

    for (final entry in _mindBlownMethods.entries) {
      test('${entry.key} crashes the user when blocked by Protect', () {
        final result = _runMove(
          opponentEffects: PsdkBattleEffectStack(
            values: const <String>[PsdkBattleEffectIds.protect],
          ),
          playerMove: _move(
            id: entry.value,
            power: 40,
            battleEngineMethod: entry.key,
          ),
        );

        final events = _eventsFor(result, moveId: entry.value);
        expect(events.map((event) => event.kind), <String>[
          'move_pp_spent',
          'move_declared',
          'move_failed',
          'damage',
        ]);
        expect((events[2] as PsdkBattleMoveFailedEvent).reason,
            BattleMoveFailureReason.protected.jsonName);
        final damage = _damageEvents(result, moveId: entry.value);
        expect(damage.single.target, psdkPlayerSlot);
        expect(damage.single.damage, 50);
        expect(result.state.battlerAt(psdkOpponentSlot).currentHp, 100);
        expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 50);
      });
    }

    test('s_mind_blown does not crash when PP prevents move execution', () {
      final result = _runMove(
        opponentTypes: const PsdkBattleTypes(primary: 'normal'),
        playerMove: _move(
          id: 'mind_blown',
          power: 40,
          currentPp: 0,
          battleEngineMethod: 's_mind_blown',
        ),
      );

      final events = _eventsFor(result, moveId: 'mind_blown');
      expect(events.map((event) => event.kind), <String>['move_failed']);
      expect((events.single as PsdkBattleMoveFailedEvent).reason,
          BattleMoveFailureReason.pp.jsonName);
      expect(_damageEvents(result, moveId: 'mind_blown'), isEmpty);
      expect(result.state.battlerAt(psdkOpponentSlot).currentHp, 100);
      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 100);
    });

    test('s_mind_blown applies secondary effects before successful crash', () {
      final result = _runMove(
        opponentTypes: const PsdkBattleTypes(primary: 'normal'),
        playerMove: _move(
          id: 'mind_blown',
          power: 40,
          battleEngineMethod: 's_mind_blown',
          statuses: <PsdkBattleMoveStatus>[
            PsdkBattleMoveStatus(
              status: PsdkBattleMajorStatus.burn,
              chance: 100,
            ),
          ],
        ),
      );

      final events = _eventsFor(result, moveId: 'mind_blown');
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
      expect(_damageEvents(result, moveId: 'mind_blown').last.target,
          psdkPlayerSlot);
    });
  });
}

PsdkBattleTurnResult _runMove({
  required PsdkBattleMoveData playerMove,
  String? playerAbilityId,
  int playerMaxHp = 100,
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
        maxHp: playerMaxHp,
        currentHp: playerCurrentHp,
        speed: 100,
        types: const PsdkBattleTypes(primary: 'fire'),
        abilityId: playerAbilityId,
        move: playerMove,
      ),
      opponent: _combatant(
        id: 'opponent',
        maxHp: 100,
        currentHp: opponentCurrentHp,
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
  String? abilityId,
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
    abilityId: abilityId,
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
