import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK forced-action move families', () {
    test('s_gigaton_hammer fails when it was the user previous move', () {
      final allowed = _runMove(
        playerMove: _move(
          id: 'gigaton_hammer',
          type: 'steel',
          power: 160,
          battleEngineMethod: 's_gigaton_hammer',
        ),
        playerMoveHistory: PsdkBattleMoveHistory(
          successes: <PsdkBattleMoveHistoryEntry>[
            PsdkBattleMoveHistoryEntry(
              moveId: 'tackle',
              turn: 1,
              targets: const <PsdkBattleSlotRef>[psdkOpponentSlot],
            ),
          ],
        ),
      );
      final blocked = _runMove(
        playerMove: _move(
          id: 'gigaton_hammer',
          type: 'steel',
          power: 160,
          battleEngineMethod: 's_gigaton_hammer',
        ),
        playerMoveHistory: PsdkBattleMoveHistory(
          successes: <PsdkBattleMoveHistoryEntry>[
            PsdkBattleMoveHistoryEntry(
              moveId: 'gigaton_hammer',
              turn: 1,
              targets: const <PsdkBattleSlotRef>[psdkOpponentSlot],
            ),
          ],
        ),
      );

      expect(_damage(allowed, moveId: 'gigaton_hammer'), greaterThan(0));
      expect(_failed(blocked, moveId: 'gigaton_hammer'), isTrue);
      expect(_damageEvents(blocked, moveId: 'gigaton_hammer'), isEmpty);
    });

    test('s_thrash locks the user into the same move after a hit', () {
      final result = _runMove(
        playerMove: _move(
          id: 'thrash',
          power: 120,
          battleEngineMethod: 's_thrash',
        ),
      );

      final player = result.state.battlerAt(psdkPlayerSlot);
      expect(_damage(result, moveId: 'thrash'), greaterThan(0));
      expect(player.effects.contains('force_next_move_base'), isTrue);
    });

    test('s_thrash blocks selecting another move while locked', () {
      final engine = _engine(
        playerMoves: <PsdkBattleMoveData>[
          _move(id: 'thrash', power: 120, battleEngineMethod: 's_thrash'),
          _move(id: 'tackle', power: 40),
        ],
      );

      final first = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      final second = engine.submit(const PsdkBattleDecision.fight(moveSlot: 1));

      expect(_damage(first, moveId: 'thrash'), greaterThan(0));
      expect(_failed(second, moveId: 'tackle'), isTrue);
      expect(_damageEvents(second, moveId: 'tackle'), isEmpty);
    });

    test('s_thrash releases the lock and confuses the user at the end', () {
      final engine = _engine(
        genericSeed: 4,
        playerMoves: <PsdkBattleMoveData>[
          _move(id: 'thrash', power: 120, battleEngineMethod: 's_thrash'),
        ],
      );

      engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      final second = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));

      final player = second.state.battlerAt(psdkPlayerSlot);
      expect(_damage(second, moveId: 'thrash'), greaterThan(0));
      expect(player.effects.contains('force_next_move_base'), isFalse);
      expect(player.effects.contains('confusion'), isTrue);
    });

    test('s_thrash respects Own Tempo when the lock ends', () {
      final engine = _engine(
        genericSeed: 4,
        playerAbilityId: 'own_tempo',
        playerMoves: <PsdkBattleMoveData>[
          _move(id: 'thrash', power: 120, battleEngineMethod: 's_thrash'),
        ],
      );

      engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      final second = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));

      final player = second.state.battlerAt(psdkPlayerSlot);
      expect(_damage(second, moveId: 'thrash'), greaterThan(0));
      expect(player.effects.contains('force_next_move_base'), isFalse);
      expect(player.effects.contains('confusion'), isFalse);
    });

    test('s_outrage uses the same repeated-action lock as Thrash', () {
      final result = _runMove(
        playerMove: _move(
          id: 'outrage',
          type: 'dragon',
          power: 120,
          battleEngineMethod: 's_outrage',
        ),
      );

      final player = result.state.battlerAt(psdkPlayerSlot);
      expect(_damage(result, moveId: 'outrage'), greaterThan(0));
      expect(player.effects.contains('force_next_move_base'), isTrue);
    });

    test('s_uproar installs an uproar marker after a successful hit', () {
      final result = _runMove(
        playerMove: _move(
          id: 'uproar',
          type: 'normal',
          category: PsdkBattleMoveCategory.special,
          power: 90,
          battleEngineMethod: 's_uproar',
        ),
      );

      final player = result.state.battlerAt(psdkPlayerSlot);
      expect(_damage(result, moveId: 'uproar'), greaterThan(0));
      expect(player.effects.contains('uproar'), isTrue);
    });

    test('s_reload spends the recharge turn without duplicating history', () {
      final engine = _engine(
        playerMoves: <PsdkBattleMoveData>[
          _move(
            id: 'hyper_beam',
            category: PsdkBattleMoveCategory.special,
            power: 150,
            battleEngineMethod: 's_reload',
          ),
        ],
      );

      final first = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      final second = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      final player = second.state.battlerAt(psdkPlayerSlot);

      expect(_damage(first, moveId: 'hyper_beam'), greaterThan(0));
      expect(_failed(second, moveId: 'hyper_beam'), isTrue);
      expect(player.effects.contains(PsdkBattleEffectIds.forceNextMoveBase),
          isFalse);
      expect(player.moveHistory.usedMoveIds, <String>['hyper_beam']);
      expect(player.moveHistory.successfulMoveIds, <String>['hyper_beam']);
    });

    test('s_reload does not require recharge when the attack misses', () {
      final result = _runMove(
        playerMove: _move(
          id: 'hyper_beam',
          category: PsdkBattleMoveCategory.special,
          power: 150,
          accuracy: 1,
          battleEngineMethod: 's_reload',
        ),
      );

      expect(_damageEvents(result, moveId: 'hyper_beam'), isEmpty);
      expect(
        result.state
            .battlerAt(psdkPlayerSlot)
            .effects
            .contains(PsdkBattleEffectIds.forceNextMoveBase),
        isFalse,
      );
      expect(result.state.battlerAt(psdkPlayerSlot).moveHistory.successes,
          isEmpty);
    });

    test('s_2turns forces the charged move on the next action', () {
      final engine = _engine(
        playerMoves: <PsdkBattleMoveData>[
          _move(
            id: 'fly',
            type: 'flying',
            power: 90,
            battleEngineMethod: 's_2turns',
          ),
          _move(id: 'tackle', power: 40),
        ],
      );

      final charge = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      final strike = engine.submit(const PsdkBattleDecision.fight(moveSlot: 1));

      expect(_damageEvents(charge, moveId: 'fly'), isEmpty);
      expect(
        charge.state
            .battlerAt(psdkPlayerSlot)
            .effects
            .contains(PsdkBattleEffectIds.twoTurnCharge),
        isTrue,
      );
      expect(_damageEvents(strike, moveId: 'tackle'), isEmpty);
      expect(_damage(strike, moveId: 'fly'), greaterThan(0));
      expect(
        strike.state
            .battlerAt(psdkPlayerSlot)
            .effects
            .contains(PsdkBattleEffectIds.twoTurnCharge),
        isFalse,
      );
    });

    test('s_2turns preserves the charge when sleep stops release', () {
      final engine = _engine(
        playerMajorStatus: PsdkBattleMajorStatus.sleep,
        playerSleepTurns: 0,
        playerEffects: PsdkBattleEffectStack(
          effects: const <BattleEffect>[
            TwoTurnChargeEffect(
              scope: BattlerBattleEffectScope(psdkPlayerSlot),
              chargedMoveId: 'fly',
              chargedTarget: psdkOpponentSlot,
            ),
          ],
        ),
        playerMoves: <PsdkBattleMoveData>[
          _move(
            id: 'fly',
            type: 'flying',
            power: 90,
            battleEngineMethod: 's_2turns',
          ),
          _move(id: 'tackle', power: 40),
        ],
      );

      final blocked =
          engine.submit(const PsdkBattleDecision.fight(moveSlot: 1));
      final player = blocked.state.battlerAt(psdkPlayerSlot);

      expect(_failed(blocked, moveId: 'fly'), isTrue);
      expect(_damageEvents(blocked, moveId: 'fly'), isEmpty);
      expect(_damageEvents(blocked, moveId: 'tackle'), isEmpty);
      expect(player.sleepTurns, 1);
      expect(
          player.effects.contains(PsdkBattleEffectIds.twoTurnCharge), isTrue);
    });
  });
}

PsdkBattleTurnResult _runMove({
  required PsdkBattleMoveData playerMove,
  PsdkBattleMoveHistory? playerMoveHistory,
  String? playerAbilityId,
}) {
  return _engine(
    playerMoves: <PsdkBattleMoveData>[playerMove],
    playerMoveHistory: playerMoveHistory,
    playerAbilityId: playerAbilityId,
  ).submit(const PsdkBattleDecision.fight(moveSlot: 0));
}

PsdkBattleEngine _engine({
  required List<PsdkBattleMoveData> playerMoves,
  PsdkBattleMoveHistory? playerMoveHistory,
  String? playerAbilityId,
  PsdkBattleMajorStatus? playerMajorStatus,
  int playerSleepTurns = 0,
  PsdkBattleEffectStack? playerEffects,
  int genericSeed = 4,
}) {
  return PsdkBattleEngine(
    setup: PsdkBattleSetup.singles(
      player: _combatant(
        id: 'player',
        speed: 100,
        abilityId: playerAbilityId,
        moveHistory: playerMoveHistory,
        majorStatus: playerMajorStatus,
        sleepTurns: playerSleepTurns,
        effects: playerEffects,
        moves: playerMoves,
      ),
      opponent: _combatant(
        id: 'opponent',
        speed: 1,
        moves: <PsdkBattleMoveData>[
          _move(
            id: 'opponent_wait',
            category: PsdkBattleMoveCategory.status,
            power: 0,
            accuracy: 0,
            battleEngineMethod: 's_splash',
          ),
        ],
      ),
      rngSeeds: PsdkBattleRngSeeds(
        moveDamage: 1,
        moveCritical: 99999,
        moveAccuracy: 3,
        generic: genericSeed,
      ),
    ),
  );
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  required int speed,
  required List<PsdkBattleMoveData> moves,
  String? abilityId,
  PsdkBattleMoveHistory? moveHistory,
  PsdkBattleMajorStatus? majorStatus,
  int sleepTurns = 0,
  PsdkBattleEffectStack? effects,
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
    stats: PsdkBattleStats(
      attack: 50,
      defense: 50,
      specialAttack: 50,
      specialDefense: 50,
      speed: speed,
    ),
    moves: moves,
    moveHistory: moveHistory,
    majorStatus: majorStatus,
    sleepTurns: sleepTurns,
    effects: effects,
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

int _damage(PsdkBattleTurnResult result, {required String moveId}) {
  return _damageEvents(result, moveId: moveId).single.damage;
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

bool _failed(PsdkBattleTurnResult result, {required String moveId}) {
  return result.timeline.events
      .whereType<PsdkBattleMoveFailedEvent>()
      .any((event) => event.moveId == moveId);
}
