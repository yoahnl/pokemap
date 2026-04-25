import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

const _playerSlot = PsdkBattleSlotRef(bank: 0, position: 0);
const _opponentSlot = PsdkBattleSlotRef(bank: 1, position: 0);

void main() {
  group('clean architecture BattleEngine foundation', () {
    test('exposes a player decision request and an immutable public snapshot',
        () {
      final engine = BattleEngine(setup: _cleanSetup());

      final request = engine.currentRequest;
      final snapshot = engine.snapshot();

      expect(request.kind, BattleEngineDecisionRequestKind.turnChoice);
      expect(request.actor, _playerSlot);
      expect(request.fightChoices.map((choice) => choice.moveId),
          containsAllInOrder(<String>['tackle', 'thunder_wave']));
      expect(request.allowedDecisions, hasLength(2));
      expect(snapshot.turnNumber, 0);
      expect(snapshot.outcome, isNull);
      expect(snapshot.battlerAt(_playerSlot).speciesId, 'bulbasaur');
      expect(
        () => snapshot.combatants.clear(),
        throwsUnsupportedError,
      );
    });

    test('submit resolves through the turn runner and returns timeline output',
        () {
      final engine = BattleEngine(
        setup: _cleanSetup(
          playerMoves: <PsdkBattleMoveData>[_tackle(power: 90)],
          opponentHp: 24,
        ),
      );

      final result = engine.submit(const BattleDecision.fight(moveSlot: 0));

      expect(result.state.turnNumber, 1);
      expect(result.state.battlerAt(_opponentSlot).currentHp, lessThan(24));
      expect(
          result.timeline.events.map((event) => event.kind),
          containsAllInOrder(<String>[
            'turn_started',
            'move_declared',
            'animation_cue',
            'damage',
          ]));
      expect(result.outcome, isNull);
      expect(
          result.nextRequest?.kind, BattleEngineDecisionRequestKind.turnChoice);
    });

    test('terminal outcome produces no next request and no extra turn events',
        () {
      final engine = BattleEngine(
        setup: _cleanSetup(
          playerMoves: <PsdkBattleMoveData>[_tackle(power: 250)],
          opponentHp: 8,
          opponentMoves: <PsdkBattleMoveData>[_tackle(power: 1)],
        ),
      );

      final first = engine.submit(const BattleDecision.fight(moveSlot: 0));
      final second = engine.submit(const BattleDecision.fight(moveSlot: 0));

      expect(first.outcome?.kind, BattleEngineOutcomeKind.victory);
      expect(first.nextRequest, isNull);
      expect(first.timeline.events.map((event) => event.kind),
          contains('battle_ended'));
      expect(second.outcome?.kind, BattleEngineOutcomeKind.victory);
      expect(second.timeline.events, isEmpty);
      expect(
          engine.currentRequest.kind, BattleEngineDecisionRequestKind.finished);
    });

    test('invalid fight slot fails before the state is mutated', () {
      final engine = BattleEngine(setup: _cleanSetup());

      expect(
        () => engine.submit(const BattleDecision.fight(moveSlot: 99)),
        throwsRangeError,
      );
      expect(engine.snapshot().turnNumber, 0);
      expect(engine.snapshot().battlerAt(_opponentSlot).currentHp, 40);
    });

    test('unsupported PSDK battleEngineMethod bubbles through the facade', () {
      final engine = BattleEngine(
        setup: _cleanSetup(
          playerMoves: <PsdkBattleMoveData>[
            _tackle(power: 40).copyWith(battleEngineMethod: 's_missing'),
          ],
          opponentMoves: <PsdkBattleMoveData>[_tackle(power: 1)],
        ),
      );

      expect(
        () => engine.submit(const BattleDecision.fight(moveSlot: 0)),
        throwsA(isA<UnsupportedPsdkBattleMoveBehavior>()),
      );
      expect(engine.snapshot().turnNumber, 0);
      expect(engine.snapshot().battlerAt(_opponentSlot).currentHp, 40);
    });

    test('second action failure restores a partially resolved turn', () {
      final engine = BattleEngine(
        setup: _cleanSetup(
          playerMoves: <PsdkBattleMoveData>[_tackle(power: 90)],
          opponentHp: 40,
          opponentMoves: <PsdkBattleMoveData>[
            _tackle(power: 1).copyWith(battleEngineMethod: 's_missing'),
          ],
        ),
      );

      expect(
        () => engine.submit(const BattleDecision.fight(moveSlot: 0)),
        throwsA(isA<UnsupportedPsdkBattleMoveBehavior>()),
      );
      expect(engine.snapshot().turnNumber, 0);
      expect(engine.snapshot().battlerAt(_playerSlot).currentHp, 40);
      expect(engine.snapshot().battlerAt(_opponentSlot).currentHp, 40);
    });

    test('clean engine contracts do not shadow legacy public contracts', () {
      final cleanSetup = _cleanSetup();
      final legacySetup = _legacySetup();
      final legacySession = createBattleSession(legacySetup);

      expect(cleanSetup, isA<BattleEngineSetup>());
      expect(legacySetup, isA<BattleSetup>());
      expect(legacySession.decisionRequest, isA<BattleDecisionRequest>());
      expect(
          legacySession
              .applyChoice(const PlayerBattleChoiceFight(0))
              .state
              .currentTurn,
          isA<BattleTurnResult>());
    });

    test('legacy BattleSession still works while the new engine coexists', () {
      final next = createBattleSession(_legacySetup())
          .applyChoice(const PlayerBattleChoiceFight(0));

      expect(next.state.currentTurn, isNotNull);
      expect(next.state.enemy.currentHp, lessThan(20));
    });
  });
}

BattleEngineSetup _cleanSetup({
  List<PsdkBattleMoveData>? playerMoves,
  List<PsdkBattleMoveData>? opponentMoves,
  int playerHp = 40,
  int opponentHp = 40,
}) {
  return BattleEngineSetup.singles(
    player: PsdkBattleCombatantSetup(
      id: 'player-bulbasaur',
      speciesId: 'bulbasaur',
      displayName: 'Bulbasaur',
      level: 10,
      maxHp: playerHp,
      currentHp: playerHp,
      types: const PsdkBattleTypes(primary: 'grass', secondary: 'poison'),
      stats: const PsdkBattleStats(
        attack: 49,
        defense: 49,
        specialAttack: 65,
        specialDefense: 65,
        speed: 45,
      ),
      moves: playerMoves ??
          <PsdkBattleMoveData>[
            _tackle(power: 40),
            _thunderWave(),
          ],
    ),
    opponent: PsdkBattleCombatantSetup(
      id: 'opponent-squirtle',
      speciesId: 'squirtle',
      displayName: 'Squirtle',
      level: 10,
      maxHp: opponentHp,
      currentHp: opponentHp,
      types: const PsdkBattleTypes(primary: 'water'),
      stats: const PsdkBattleStats(
        attack: 48,
        defense: 65,
        specialAttack: 50,
        specialDefense: 64,
        speed: 43,
      ),
      moves: opponentMoves ?? <PsdkBattleMoveData>[_tackle(power: 40)],
    ),
    rngSeeds: const PsdkBattleRngSeeds(
      moveDamage: 1,
      moveCritical: 2,
      moveAccuracy: 3,
      generic: 4,
    ),
  );
}

PsdkBattleMoveData _tackle({required int power}) {
  return PsdkBattleMoveData(
    id: 'tackle',
    dbSymbol: 'tackle',
    name: 'Tackle',
    type: 'normal',
    category: PsdkBattleMoveCategory.physical,
    power: power,
    accuracy: 100,
    pp: 35,
    priority: 0,
    battleEngineMethod: 's_basic',
    target: PsdkBattleMoveTarget.adjacentFoe,
  );
}

PsdkBattleMoveData _thunderWave() {
  return PsdkBattleMoveData(
    id: 'thunder_wave',
    dbSymbol: 'thunder_wave',
    name: 'Thunder Wave',
    type: 'electric',
    category: PsdkBattleMoveCategory.status,
    power: 0,
    accuracy: 90,
    pp: 20,
    priority: 0,
    battleEngineMethod: 's_status',
    target: PsdkBattleMoveTarget.adjacentFoe,
    statuses: <PsdkBattleMoveStatus>[
      PsdkBattleMoveStatus(
        status: PsdkBattleMajorStatus.paralysis,
        chance: 100,
      ),
    ],
  );
}

BattleSetup _legacySetup() {
  return BattleSetup(
    playerPokemon: BattleCombatantData(
      speciesId: 'pikachu',
      level: 5,
      maxHp: 20,
      stats: const BattleStatsSnapshot(
        attack: 50,
        defense: 50,
        specialAttack: 50,
        specialDefense: 50,
        speed: 50,
      ),
      moves: const <BattleMoveData>[
        BattleMoveData(id: 'tackle', name: 'Charge', power: 5),
      ],
    ),
    enemyPokemon: BattleCombatantData(
      speciesId: 'lapras',
      level: 5,
      maxHp: 20,
      stats: const BattleStatsSnapshot(
        attack: 50,
        defense: 50,
        specialAttack: 50,
        specialDefense: 50,
        speed: 40,
      ),
      moves: const <BattleMoveData>[
        BattleMoveData(id: 'tackle', name: 'Charge', power: 5),
      ],
    ),
    isTrainerBattle: false,
    trainerId: null,
  );
}
