import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK action order control move families', () {
    test('s_trick_room reverses speed order while active', () {
      final engine = _engine(
        playerSpeed: 100,
        opponentSpeed: 20,
        playerMoves: <PsdkBattleMoveData>[
          _statusMove(
            id: 'trick_room',
            battleEngineMethod: 's_trick_room',
            target: PsdkBattleMoveTarget.none,
          ),
          _damageMove(id: 'player_tackle'),
        ],
        opponentMoves: <PsdkBattleMoveData>[
          _damageMove(id: 'opponent_tackle'),
        ],
      );

      engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      final result = engine.submit(const PsdkBattleDecision.fight(moveSlot: 1));

      expect(
        _damageMoveIds(result),
        equals(<String>['opponent_tackle', 'player_tackle']),
      );
    });

    test('s_trick_room removes the room if it is used while active', () {
      final engine = _engine(
        playerSpeed: 100,
        opponentSpeed: 20,
        playerMoves: <PsdkBattleMoveData>[
          _statusMove(
            id: 'trick_room',
            battleEngineMethod: 's_trick_room',
            target: PsdkBattleMoveTarget.none,
          ),
        ],
        opponentMoves: <PsdkBattleMoveData>[
          _statusMove(id: 'opponent_wait', battleEngineMethod: 's_splash'),
        ],
      );

      engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      final result = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));

      expect(_hasEffect(result.state, 'trick_room'), isFalse);
      expect(
        result.timeline.events
            .whereType<PsdkBattleEffectEvent>()
            .where((event) => event.effectId == 'trick_room')
            .map((event) => event.reason),
        contains('trick_room_toggle'),
      );
    });

    test('s_tailwind doubles the action speed of the user bank while active',
        () {
      final engine = _engine(
        playerSpeed: 40,
        opponentSpeed: 70,
        playerMoves: <PsdkBattleMoveData>[
          _statusMove(
            id: 'tailwind',
            battleEngineMethod: 's_tailwind',
            target: PsdkBattleMoveTarget.userSide,
          ),
          _damageMove(id: 'player_tackle'),
        ],
        opponentMoves: <PsdkBattleMoveData>[
          _damageMove(id: 'opponent_tackle'),
        ],
      );

      engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      final result = engine.submit(const PsdkBattleDecision.fight(moveSlot: 1));

      expect(
        _damageMoveIds(result),
        equals(<String>['player_tackle', 'opponent_tackle']),
      );
    });

    test('s_tailwind fails if the user bank already has tailwind', () {
      final engine = _engine(
        playerSpeed: 40,
        opponentSpeed: 70,
        playerMoves: <PsdkBattleMoveData>[
          _statusMove(
            id: 'tailwind',
            battleEngineMethod: 's_tailwind',
            target: PsdkBattleMoveTarget.userSide,
          ),
        ],
        opponentMoves: <PsdkBattleMoveData>[
          _statusMove(id: 'opponent_wait', battleEngineMethod: 's_splash'),
        ],
      );

      engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      final result = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));

      expect(
        result.timeline.events
            .whereType<PsdkBattleMoveFailedEvent>()
            .where((event) => event.moveId == 'tailwind')
            .map((event) => event.reason),
        contains('tailwind_already_active'),
      );
    });
  });
}

PsdkBattleEngine _engine({
  required int playerSpeed,
  required int opponentSpeed,
  required List<PsdkBattleMoveData> playerMoves,
  required List<PsdkBattleMoveData> opponentMoves,
}) {
  return PsdkBattleEngine(
    setup: PsdkBattleSetup.singles(
      player: _combatant(
        id: 'player',
        speed: playerSpeed,
        moves: playerMoves,
      ),
      opponent: _combatant(
        id: 'opponent',
        speed: opponentSpeed,
        moves: opponentMoves,
      ),
      rngSeeds: const PsdkBattleRngSeeds(
        moveDamage: 1,
        moveCritical: 99999,
        moveAccuracy: 3,
        generic: 4,
      ),
    ),
  );
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  required int speed,
  required List<PsdkBattleMoveData> moves,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 20,
    maxHp: 300,
    currentHp: 300,
    types: const PsdkBattleTypes(primary: 'normal'),
    stats: PsdkBattleStats(
      attack: 50,
      defense: 50,
      specialAttack: 50,
      specialDefense: 50,
      speed: speed,
    ),
    moves: moves,
  );
}

PsdkBattleMoveData _damageMove({
  required String id,
}) {
  return _move(
    id: id,
    power: 20,
    category: PsdkBattleMoveCategory.physical,
    battleEngineMethod: 's_basic',
    target: PsdkBattleMoveTarget.adjacentFoe,
  );
}

PsdkBattleMoveData _statusMove({
  required String id,
  required String battleEngineMethod,
  PsdkBattleMoveTarget target = PsdkBattleMoveTarget.none,
}) {
  return _move(
    id: id,
    power: 0,
    category: PsdkBattleMoveCategory.status,
    battleEngineMethod: battleEngineMethod,
    target: target,
  );
}

PsdkBattleMoveData _move({
  required String id,
  required int power,
  required PsdkBattleMoveCategory category,
  required String battleEngineMethod,
  required PsdkBattleMoveTarget target,
}) {
  return PsdkBattleMoveData(
    id: id,
    dbSymbol: id,
    name: id,
    type: 'normal',
    category: category,
    power: power,
    accuracy: 100,
    pp: 35,
    priority: 0,
    criticalRate: 1,
    battleEngineMethod: battleEngineMethod,
    target: target,
  );
}

List<String> _damageMoveIds(PsdkBattleTurnResult result) {
  return result.timeline.events
      .whereType<PsdkBattleDamageEvent>()
      .map((event) => event.moveId)
      .toList(growable: false);
}

bool _hasEffect(PsdkBattleState state, String effectId) {
  return state.combatants.values.any(
    (combatant) => combatant.effects.effects.any(
      (effect) => effect.id == effectId,
    ),
  );
}
