import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK move prevention effects', () {
    test('Taunt prevents the affected battler from using a status move', () {
      final result = _runMove(
        playerEffects: PsdkBattleEffectStack(values: const <String>['taunt']),
        playerMove: _move(
          id: 'growl',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 100,
          battleEngineMethod: 's_stat',
          stageMods: const <PsdkBattleMoveStageMod>[
            PsdkBattleMoveStageMod(
              stat: 'attack',
              stages: -1,
              chance: 100,
            ),
          ],
        ),
      );

      final failures = result.timeline.events
          .whereType<PsdkBattleMoveFailedEvent>()
          .toList(growable: false);
      expect(failures, hasLength(1));
      expect(failures.single.moveId, 'growl');
      expect(failures.single.reason,
          BattleMoveFailureReason.unusableByUser.jsonName);
      expect(
        result.state.battlerAt(psdkOpponentSlot).statStages.valueOf('attack'),
        0,
      );
    });

    test('Taunt does not prevent the affected battler from using damage moves',
        () {
      final result = _runMove(
        playerEffects: PsdkBattleEffectStack(values: const <String>['taunt']),
        playerMove: _move(
          id: 'tackle',
          power: 40,
        ),
      );

      expect(
        result.timeline.events.whereType<PsdkBattleMoveFailedEvent>(),
        isEmpty,
      );
      expect(_damageEvents(result, moveId: 'tackle'), hasLength(1));
    });

    test('Torment prevents repeating the last successful non-Struggle move',
        () {
      final result = _runMove(
        playerEffects: PsdkBattleEffectStack(
          values: const <String>['torment'],
        ),
        playerMoveHistory: PsdkBattleMoveHistory(
          successes: <PsdkBattleMoveHistoryEntry>[
            PsdkBattleMoveHistoryEntry(
              moveId: 'tackle',
              turn: 1,
              targets: <PsdkBattleSlotRef>[psdkOpponentSlot],
            ),
          ],
        ),
        playerMove: _move(
          id: 'tackle',
          power: 40,
        ),
      );

      final failures = result.timeline.events
          .whereType<PsdkBattleMoveFailedEvent>()
          .toList(growable: false);
      expect(failures, hasLength(1));
      expect(failures.single.moveId, 'tackle');
      expect(failures.single.reason,
          BattleMoveFailureReason.unusableByUser.jsonName);
      expect(_damageEvents(result, moveId: 'tackle'), isEmpty);
    });

    test('Torment allows different moves and Struggle', () {
      final history = PsdkBattleMoveHistory(
        successes: <PsdkBattleMoveHistoryEntry>[
          PsdkBattleMoveHistoryEntry(
            moveId: 'tackle',
            turn: 1,
            targets: <PsdkBattleSlotRef>[psdkOpponentSlot],
          ),
        ],
      );
      final ember = _runMove(
        playerEffects: PsdkBattleEffectStack(
          values: const <String>['torment'],
        ),
        playerMoveHistory: history,
        playerMove: _move(
          id: 'ember',
          type: 'fire',
          category: PsdkBattleMoveCategory.special,
          power: 40,
        ),
      );
      final struggle = _runMove(
        playerEffects: PsdkBattleEffectStack(
          values: const <String>['torment'],
        ),
        playerMoveHistory: history,
        playerMove: _move(
          id: 'struggle',
          power: 50,
          accuracy: 0,
          battleEngineMethod: 's_struggle',
        ),
      );

      expect(ember.timeline.events.whereType<PsdkBattleMoveFailedEvent>(),
          isEmpty);
      expect(_damageEvents(ember, moveId: 'ember'), hasLength(1));
      expect(struggle.timeline.events.whereType<PsdkBattleMoveFailedEvent>(),
          isEmpty);
      expect(_damageEvents(struggle, moveId: 'struggle'), hasLength(2));
    });

    test('Disable blocks the target last successful move after setup', () {
      final result = _runMove(
        playerMove: _move(
          id: 'disable',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 100,
          battleEngineMethod: 's_disable',
        ),
        opponentMoveHistory: PsdkBattleMoveHistory(
          successes: <PsdkBattleMoveHistoryEntry>[
            PsdkBattleMoveHistoryEntry(
              moveId: 'tackle',
              turn: 1,
              targets: <PsdkBattleSlotRef>[psdkPlayerSlot],
            ),
          ],
        ),
        opponentMove: _move(
          id: 'tackle',
          power: 40,
        ),
      );

      final failures = result.timeline.events
          .whereType<PsdkBattleMoveFailedEvent>()
          .toList(growable: false);
      expect(failures, hasLength(1));
      expect(failures.single.user, psdkOpponentSlot);
      expect(failures.single.moveId, 'tackle');
      expect(failures.single.reason,
          BattleMoveFailureReason.unusableByUser.jsonName);
      expect(_damageEvents(result, moveId: 'tackle'), isEmpty);
    });

    test('Encore prevents choosing a different move than the encored one', () {
      final result = _runMove(
        playerMove: _move(
          id: 'encore',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 100,
          battleEngineMethod: 's_encore',
        ),
        opponentMoveHistory: PsdkBattleMoveHistory(
          successes: <PsdkBattleMoveHistoryEntry>[
            PsdkBattleMoveHistoryEntry(
              moveId: 'tackle',
              turn: 1,
              targets: <PsdkBattleSlotRef>[psdkPlayerSlot],
            ),
          ],
        ),
        opponentMove: _move(
          id: 'ember',
          type: 'fire',
          category: PsdkBattleMoveCategory.special,
          power: 40,
        ),
      );

      final failures = result.timeline.events
          .whereType<PsdkBattleMoveFailedEvent>()
          .toList(growable: false);
      expect(failures, hasLength(1));
      expect(failures.single.user, psdkOpponentSlot);
      expect(failures.single.moveId, 'ember');
      expect(failures.single.reason,
          BattleMoveFailureReason.unusableByUser.jsonName);
      expect(_damageEvents(result, moveId: 'ember'), isEmpty);
    });

    test('Heal Block prevents affected battlers from using healing moves', () {
      final result = _runMove(
        playerEffects: PsdkBattleEffectStack(
          values: const <String>['heal_block'],
        ),
        playerCurrentHp: 50,
        playerMove: _move(
          id: 'recover',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 0,
          battleEngineMethod: 's_heal',
          target: PsdkBattleMoveTarget.self,
        ),
      );

      final failures = result.timeline.events
          .whereType<PsdkBattleMoveFailedEvent>()
          .toList(growable: false);
      expect(failures, hasLength(1));
      expect(failures.single.user, psdkPlayerSlot);
      expect(failures.single.moveId, 'recover');
      expect(failures.single.reason,
          BattleMoveFailureReason.unusableByUser.jsonName);
      expect(_healEvents(result, moveId: 'recover'), isEmpty);
      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 50);
    });

    test('Attract can prevent moving against the attracting battler', () {
      final result = _runMove(
        playerMove: _move(
          id: 'attract',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 100,
          battleEngineMethod: 's_attract',
        ),
        opponentMove: _move(
          id: 'tackle',
          power: 40,
        ),
      );

      final failures = result.timeline.events
          .whereType<PsdkBattleMoveFailedEvent>()
          .toList(growable: false);
      expect(failures, hasLength(1));
      expect(failures.single.user, psdkOpponentSlot);
      expect(failures.single.moveId, 'tackle');
      expect(failures.single.reason,
          BattleMoveFailureReason.unusableByUser.jsonName);
      expect(_damageEvents(result, moveId: 'tackle'), isEmpty);
    });

    test('Imprison prevents foes from using a shared move', () {
      final result = _runMove(
        playerMove: _move(
          id: 'imprison',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 100,
          battleEngineMethod: 's_imprison',
        ),
        playerExtraMoves: <PsdkBattleMoveData>[
          _move(
            id: 'tackle',
            power: 40,
          ),
        ],
        opponentMove: _move(
          id: 'tackle',
          power: 40,
        ),
      );

      final failures = result.timeline.events
          .whereType<PsdkBattleMoveFailedEvent>()
          .toList(growable: false);
      expect(failures, hasLength(1));
      expect(failures.single.user, psdkOpponentSlot);
      expect(failures.single.moveId, 'tackle');
      expect(failures.single.reason,
          BattleMoveFailureReason.unusableByUser.jsonName);
      expect(_damageEvents(result, moveId: 'tackle'), isEmpty);
    });
  });
}

PsdkBattleTurnResult _runMove({
  required PsdkBattleMoveData playerMove,
  PsdkBattleEffectStack? playerEffects,
  int playerCurrentHp = 100,
  PsdkBattleMoveHistory? playerMoveHistory,
  List<PsdkBattleMoveData> playerExtraMoves = const <PsdkBattleMoveData>[],
  PsdkBattleMoveData? opponentMove,
  PsdkBattleMoveHistory? opponentMoveHistory,
}) {
  final engine = PsdkBattleEngine(
    setup: PsdkBattleSetup.singles(
      player: _combatant(
        id: 'player',
        speed: 100,
        currentHp: playerCurrentHp,
        move: playerMove,
        extraMoves: playerExtraMoves,
        effects: playerEffects,
        moveHistory: playerMoveHistory,
      ),
      opponent: _combatant(
        id: 'opponent',
        speed: 1,
        move: opponentMove ??
            _move(
              id: 'opponent_wait',
              power: 0,
              accuracy: 1,
            ),
        moveHistory: opponentMoveHistory,
      ),
      rngSeeds: const PsdkBattleRngSeeds(
        moveDamage: 1,
        moveCritical: 99999,
        moveAccuracy: 3,
        generic: 0,
      ),
    ),
  );
  return engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  required int speed,
  int currentHp = 100,
  required PsdkBattleMoveData move,
  List<PsdkBattleMoveData> extraMoves = const <PsdkBattleMoveData>[],
  PsdkBattleEffectStack? effects,
  PsdkBattleMoveHistory? moveHistory,
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
    effects: effects,
    moveHistory: moveHistory,
    moves: <PsdkBattleMoveData>[move, ...extraMoves],
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
