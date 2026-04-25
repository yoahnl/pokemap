import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

const _opponentSlot = PsdkBattleSlotRef(bank: 1, position: 0);

void main() {
  group('PSDK battle engine foundation', () {
    test('s_basic resolves a deterministic damaging turn and emits timeline',
        () {
      final engine = PsdkBattleEngine(
        setup: _setup(
          playerMoves: <PsdkBattleMoveData>[_tackle(power: 90)],
          opponentHp: 24,
          opponentMoves: <PsdkBattleMoveData>[_tackle(power: 20)],
        ),
      );

      final result = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      final opponent = result.state.battlerAt(_opponentSlot);

      expect(opponent.currentHp, lessThan(24));
      expect(opponent.currentHp, greaterThanOrEqualTo(0));
      expect(
          result.timeline.events.map((event) => event.kind),
          containsAllInOrder(<String>[
            'turn_started',
            'move_declared',
            'animation_cue',
            'damage',
          ]));
      expect(result.timeline.events.whereType<PsdkBattleDamageEvent>(),
          isNotEmpty);
    });

    test('engine finishes with victory when the opponent faints', () {
      final engine = PsdkBattleEngine(
        setup: _setup(
          playerMoves: <PsdkBattleMoveData>[_tackle(power: 250)],
          opponentHp: 8,
          opponentMoves: <PsdkBattleMoveData>[_tackle(power: 1)],
        ),
      );

      final result = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));

      expect(result.outcome?.kind, PsdkBattleOutcomeKind.victory);
      expect(result.state.battlerAt(_opponentSlot).isFainted, isTrue);
      expect(result.timeline.events.map((event) => event.kind),
          contains('battle_ended'));
    });

    test('engine exposes an initial outcome from an already-fainted setup', () {
      final engine = PsdkBattleEngine(
        setup: _setup(
          playerMoves: <PsdkBattleMoveData>[_tackle(power: 40)],
          opponentHp: 40,
          opponentCurrentHp: 0,
          opponentMoves: <PsdkBattleMoveData>[_tackle(power: 40)],
        ),
      );

      expect(engine.state.outcome?.kind, PsdkBattleOutcomeKind.victory);

      final result = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));

      expect(result.outcome?.kind, PsdkBattleOutcomeKind.victory);
      expect(result.timeline.events, isEmpty);
    });

    test('s_status applies a major status without dealing damage', () {
      final engine = PsdkBattleEngine(
        setup: _setup(
          playerMoves: <PsdkBattleMoveData>[_thunderWave()],
          opponentHp: 40,
          opponentMoves: <PsdkBattleMoveData>[_tackle(power: 1)],
        ),
      );

      final result = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      final opponent = result.state.battlerAt(_opponentSlot);

      expect(opponent.currentHp, 40);
      expect(opponent.majorStatus, PsdkBattleMajorStatus.paralysis);
      expect(result.timeline.events.whereType<PsdkBattleStatusEvent>(),
          hasLength(1));
    });

    test('s_status does not overwrite an existing major status', () {
      final engine = PsdkBattleEngine(
        setup: _setup(
          playerMoves: <PsdkBattleMoveData>[
            _thunderWave(),
            _thunderWave(
              statuses: <PsdkBattleMoveStatus>[
                PsdkBattleMoveStatus(
                  status: PsdkBattleMajorStatus.burn,
                  chance: 100,
                ),
              ],
            ),
          ],
          opponentMoves: <PsdkBattleMoveData>[_tackle(power: 0)],
        ),
      );

      engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      final second = engine.submit(const PsdkBattleDecision.fight(moveSlot: 1));

      expect(
        second.state.battlerAt(_opponentSlot).majorStatus,
        PsdkBattleMajorStatus.paralysis,
      );
      expect(
          second.timeline.events.whereType<PsdkBattleStatusEvent>(), isEmpty);
    });

    test('a missed move emits no animation cue and applies no status', () {
      final engine = PsdkBattleEngine(
        setup: _setup(
          playerMoves: <PsdkBattleMoveData>[_thunderWave(accuracy: 1)],
          opponentHp: 40,
          opponentMoves: <PsdkBattleMoveData>[_tackle(power: 1)],
        ),
      );

      final result = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      final opponent = result.state.battlerAt(_opponentSlot);
      final playerEvents = result.timeline.events.where(
        (event) =>
            event is PsdkBattleMoveDeclaredEvent &&
                event.moveId == 'thunder_wave' ||
            event is PsdkBattleAnimationCueEvent &&
                event.moveId == 'thunder_wave' ||
            event is PsdkBattleMissEvent && event.moveId == 'thunder_wave' ||
            event is PsdkBattleStatusEvent && event.moveId == 'thunder_wave',
      );

      expect(opponent.majorStatus, isNull);
      expect(playerEvents.whereType<PsdkBattleMissEvent>(), hasLength(1));
      expect(playerEvents.whereType<PsdkBattleAnimationCueEvent>(), isEmpty);
      expect(playerEvents.whereType<PsdkBattleStatusEvent>(), isEmpty);
    });

    test('a user-target status move applies to its user, not the foe', () {
      final engine = PsdkBattleEngine(
        setup: _setup(
          playerMoves: <PsdkBattleMoveData>[
            _thunderWave(target: PsdkBattleMoveTarget.user),
          ],
          opponentMoves: <PsdkBattleMoveData>[_tackle(power: 1)],
        ),
      );

      final result = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      const playerSlot = PsdkBattleSlotRef(bank: 0, position: 0);

      expect(
        result.state.battlerAt(playerSlot).majorStatus,
        PsdkBattleMajorStatus.paralysis,
      );
      expect(result.state.battlerAt(_opponentSlot).majorStatus, isNull);
    });

    test('public state snapshots cannot be mutated from outside the engine',
        () {
      final engine = PsdkBattleEngine(
        setup: _setup(
          playerMoves: <PsdkBattleMoveData>[_tackle(power: 90)],
        ),
      );

      expect(
        () => engine.state.combatants.clear(),
        throwsUnsupportedError,
      );
      expect(
        () => engine.state.battlerAt(_opponentSlot).moves.clear(),
        throwsUnsupportedError,
      );
    });

    test('setup and move data snapshot incoming mutable lists', () {
      final statuses = <PsdkBattleMoveStatus>[
        PsdkBattleMoveStatus(
          status: PsdkBattleMajorStatus.paralysis,
          chance: 100,
        ),
      ];
      final move = _thunderWave(statuses: statuses);
      statuses.clear();

      final setupMoves = <PsdkBattleMoveData>[move];
      final setup = _setup(playerMoves: setupMoves);
      setupMoves.clear();

      expect(move.statuses, hasLength(1));
      expect(setup.player.moves, hasLength(1));
    });

    test('move data validates public invariants at runtime', () {
      expect(
        () => PsdkBattleMoveStatus(
          status: PsdkBattleMajorStatus.paralysis,
          chance: 0,
        ),
        throwsRangeError,
      );
      expect(() => _tackle(power: -1), throwsRangeError);
      expect(
          () => _tackle(power: 40).copyWith(accuracy: 101), throwsRangeError);
      expect(() => _tackle(power: 40).copyWith(id: ' '), throwsArgumentError);
    });

    test('custom registry snapshots incoming behavior maps', () {
      final behaviors = <String, PsdkBattleMoveBehavior>{
        's_basic': (context) => PsdkBattleMoveResolution(
              state: context.state,
              rng: context.rng,
              events: const <PsdkBattleEvent>[],
            ),
      };
      final registry = PsdkBattleMoveBehaviorRegistry(behaviors);
      behaviors.clear();

      final engine = PsdkBattleEngine(
        setup: _setup(
          playerMoves: <PsdkBattleMoveData>[_tackle(power: 0)],
          opponentMoves: <PsdkBattleMoveData>[_tackle(power: 0)],
        ),
        registry: registry,
      );

      expect(
        () => engine.submit(const PsdkBattleDecision.fight(moveSlot: 0)),
        returnsNormally,
      );
    });

    test('accuracy 0 is accepted as the PSDK bypass-accuracy sentinel', () {
      final engine = PsdkBattleEngine(
        setup: _setup(
          playerMoves: <PsdkBattleMoveData>[_thunderWave(accuracy: 0)],
          opponentMoves: <PsdkBattleMoveData>[_tackle(power: 1)],
        ),
      );

      final result = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));

      expect(
        result.state.battlerAt(_opponentSlot).majorStatus,
        PsdkBattleMajorStatus.paralysis,
      );
      expect(result.timeline.events.whereType<PsdkBattleMissEvent>(), isEmpty);
    });

    test('s_basic with zero power does not invent chip damage', () {
      final engine = PsdkBattleEngine(
        setup: _setup(
          playerMoves: <PsdkBattleMoveData>[_tackle(power: 0)],
          opponentHp: 40,
          opponentMoves: <PsdkBattleMoveData>[_tackle(power: 0)],
        ),
      );

      final result = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      final opponent = result.state.battlerAt(_opponentSlot);

      expect(opponent.currentHp, 40);
      expect(
          result.timeline.events.whereType<PsdkBattleDamageEvent>(), isEmpty);
    });

    test('unsupported battleEngineMethod fails loudly instead of falling back',
        () {
      final engine = PsdkBattleEngine(
        setup: _setup(
          playerMoves: <PsdkBattleMoveData>[
            _tackle(power: 40).copyWith(battleEngineMethod: 's_missing'),
          ],
          opponentMoves: <PsdkBattleMoveData>[_tackle(power: 1)],
        ),
      );

      expect(
        () => engine.submit(const PsdkBattleDecision.fight(moveSlot: 0)),
        throwsA(isA<UnsupportedPsdkBattleMoveBehavior>()),
      );
    });

    test('legacy BattleSession still resolves a basic turn during coexistence',
        () {
      final legacySetup = BattleSetup(
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

      final next = createBattleSession(legacySetup)
          .applyChoice(const PlayerBattleChoiceFight(0));

      expect(next.state.currentTurn, isNotNull);
      expect(next.state.enemy.currentHp, lessThan(20));
    });
  });
}

PsdkBattleSetup _setup({
  required List<PsdkBattleMoveData> playerMoves,
  List<PsdkBattleMoveData>? opponentMoves,
  int playerHp = 40,
  int opponentHp = 40,
  int? opponentCurrentHp,
}) {
  return PsdkBattleSetup.singles(
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
      moves: playerMoves,
    ),
    opponent: PsdkBattleCombatantSetup(
      id: 'opponent-squirtle',
      speciesId: 'squirtle',
      displayName: 'Squirtle',
      level: 10,
      maxHp: opponentHp,
      currentHp: opponentCurrentHp ?? opponentHp,
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

PsdkBattleMoveData _thunderWave({
  int accuracy = 90,
  PsdkBattleMoveTarget target = PsdkBattleMoveTarget.adjacentFoe,
  List<PsdkBattleMoveStatus>? statuses,
}) {
  return PsdkBattleMoveData(
    id: 'thunder_wave',
    dbSymbol: 'thunder_wave',
    name: 'Thunder Wave',
    type: 'electric',
    category: PsdkBattleMoveCategory.status,
    power: 0,
    accuracy: accuracy,
    pp: 20,
    priority: 0,
    battleEngineMethod: 's_status',
    target: target,
    statuses: statuses ??
        <PsdkBattleMoveStatus>[
          PsdkBattleMoveStatus(
            status: PsdkBattleMajorStatus.paralysis,
            chance: 100,
          ),
        ],
  );
}
