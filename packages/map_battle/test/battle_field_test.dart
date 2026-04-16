import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

BattleStatsSnapshot _stats({
  int attack = 60,
  int defense = 60,
  int specialAttack = 60,
  int specialDefense = 60,
  int speed = 50,
}) {
  return BattleStatsSnapshot(
    attack: attack,
    defense: defense,
    specialAttack: specialAttack,
    specialDefense: specialDefense,
    speed: speed,
  );
}

BattleSession _session({
  required List<BattleMoveData> playerMoves,
  required List<BattleMoveData> enemyMoves,
  BattleFieldState fieldState = const BattleFieldState(),
  BattleTypingSnapshot? playerTyping,
  BattleTypingSnapshot? enemyTyping,
  BattleMajorStatusState? playerStatus,
  BattleMajorStatusState? enemyStatus,
  BattleRng rng = const BattleSeededRng(),
  int playerSpeed = 70,
  int enemySpeed = 40,
  int playerHp = 100,
  int enemyHp = 100,
}) {
  return createBattleSession(
    BattleSetup(
      playerPokemon: BattleCombatantData(
        speciesId: 'playermon',
        level: 40,
        maxHp: playerHp,
        stats: _stats(speed: playerSpeed),
        typing: playerTyping,
        majorStatus: playerStatus,
        moves: playerMoves,
      ),
      enemyPokemon: BattleCombatantData(
        speciesId: 'enemymon',
        level: 40,
        maxHp: enemyHp,
        stats: _stats(speed: enemySpeed),
        typing: enemyTyping,
        majorStatus: enemyStatus,
        moves: enemyMoves,
      ),
      isTrainerBattle: false,
      trainerId: null,
      fieldState: fieldState,
    ),
    rng: rng,
  );
}

int _damageTaken(BattleSession session, String target) {
  final execution = session.state.currentTurn!.executions.firstWhere(
    (execution) => execution.target == target && execution.damage > 0,
  );
  return execution.damage;
}

void main() {
  group('BattleSession BE9 field state', () {
    test('a rain move activates a real weather state with a visible trace', () {
      final session = _session(
        playerMoves: const <BattleMoveData>[
          BattleMoveData(
            id: 'rain_dance',
            name: 'Rain Dance',
            power: 0,
            type: 'water',
            category: BattleMoveCategory.status,
            target: BattleMoveTarget.field,
            accuracy: BattleMoveAccuracy.alwaysHits(),
            weatherEffect: BattleWeatherId.rain,
          ),
        ],
        enemyMoves: const <BattleMoveData>[
          BattleMoveData(
            id: 'growl',
            name: 'Growl',
            power: 0,
            type: 'normal',
            category: BattleMoveCategory.status,
            target: BattleMoveTarget.opponent,
          ),
        ],
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(afterTurn.state.field.weather?.id, equals(BattleWeatherId.rain));
      expect(afterTurn.state.field.weather?.remainingTurns, equals(4));
      expect(
        afterTurn.state.currentTurn!.fieldEvents
            .map((event) => event.kind)
            .toList(growable: false),
        equals(<BattleFieldEventKind>[
          BattleFieldEventKind.weatherSet,
        ]),
      );
    });

    test('rain really boosts water damage and reduces fire damage', () {
      final neutralWater = _session(
        playerMoves: const <BattleMoveData>[
          BattleMoveData(
            id: 'water_gun',
            name: 'Water Gun',
            power: 40,
            type: 'water',
            category: BattleMoveCategory.special,
            target: BattleMoveTarget.opponent,
          ),
        ],
        enemyMoves: const <BattleMoveData>[
          BattleMoveData(
            id: 'growl',
            name: 'Growl',
            power: 0,
            type: 'normal',
            category: BattleMoveCategory.status,
            target: BattleMoveTarget.opponent,
          ),
        ],
      ).applyChoice(const PlayerBattleChoiceFight(0));

      final rainyWater = _session(
        playerMoves: const <BattleMoveData>[
          BattleMoveData(
            id: 'water_gun',
            name: 'Water Gun',
            power: 40,
            type: 'water',
            category: BattleMoveCategory.special,
            target: BattleMoveTarget.opponent,
          ),
        ],
        enemyMoves: const <BattleMoveData>[
          BattleMoveData(
            id: 'growl',
            name: 'Growl',
            power: 0,
            type: 'normal',
            category: BattleMoveCategory.status,
            target: BattleMoveTarget.opponent,
          ),
        ],
        fieldState: const BattleFieldState(
          weather: BattleWeatherState(
            id: BattleWeatherId.rain,
            remainingTurns: 3,
          ),
        ),
      ).applyChoice(const PlayerBattleChoiceFight(0));

      final neutralFire = _session(
        playerMoves: const <BattleMoveData>[
          BattleMoveData(
            id: 'ember',
            name: 'Ember',
            power: 40,
            type: 'fire',
            category: BattleMoveCategory.special,
            target: BattleMoveTarget.opponent,
          ),
        ],
        enemyMoves: const <BattleMoveData>[
          BattleMoveData(
            id: 'growl',
            name: 'Growl',
            power: 0,
            type: 'normal',
            category: BattleMoveCategory.status,
            target: BattleMoveTarget.opponent,
          ),
        ],
      ).applyChoice(const PlayerBattleChoiceFight(0));

      final rainyFire = _session(
        playerMoves: const <BattleMoveData>[
          BattleMoveData(
            id: 'ember',
            name: 'Ember',
            power: 40,
            type: 'fire',
            category: BattleMoveCategory.special,
            target: BattleMoveTarget.opponent,
          ),
        ],
        enemyMoves: const <BattleMoveData>[
          BattleMoveData(
            id: 'growl',
            name: 'Growl',
            power: 0,
            type: 'normal',
            category: BattleMoveCategory.status,
            target: BattleMoveTarget.opponent,
          ),
        ],
        fieldState: const BattleFieldState(
          weather: BattleWeatherState(
            id: BattleWeatherId.rain,
            remainingTurns: 3,
          ),
        ),
      ).applyChoice(const PlayerBattleChoiceFight(0));

      expect(
        _damageTaken(rainyWater, 'enemy'),
        greaterThan(_damageTaken(neutralWater, 'enemy')),
      );
      expect(
        _damageTaken(rainyFire, 'enemy'),
        lessThan(_damageTaken(neutralFire, 'enemy')),
      );
    });

    test(
        'a sandstorm move activates a real weather state and deals residual only to non-immune typings',
        () {
      final session = _session(
        playerMoves: const <BattleMoveData>[
          BattleMoveData(
            id: 'sandstorm',
            name: 'Sandstorm',
            power: 0,
            type: 'rock',
            category: BattleMoveCategory.status,
            target: BattleMoveTarget.field,
            accuracy: BattleMoveAccuracy.alwaysHits(),
            weatherEffect: BattleWeatherId.sandstorm,
          ),
        ],
        enemyMoves: const <BattleMoveData>[
          BattleMoveData(
            id: 'growl',
            name: 'Growl',
            power: 0,
            type: 'normal',
            category: BattleMoveCategory.status,
            target: BattleMoveTarget.opponent,
          ),
        ],
        playerTyping: const BattleTypingSnapshot(primaryType: 'rock'),
        enemyTyping: const BattleTypingSnapshot(primaryType: 'grass'),
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceFight(0));
      final residualEvent = afterTurn.state.currentTurn!.fieldEvents
          .where(
            (event) => event.kind == BattleFieldEventKind.weatherResidualDamage,
          )
          .single;

      expect(
          afterTurn.state.field.weather?.id, equals(BattleWeatherId.sandstorm));
      expect(afterTurn.state.field.weather?.remainingTurns, equals(4));
      expect(afterTurn.state.player.currentHp, equals(100));
      expect(afterTurn.state.enemy.currentHp, equals(94));
      expect(residualEvent.target, equals('enemy'));
      expect(residualEvent.damage, equals(6));
    });

    test('Trick Room inverts speed order at equal priority only', () {
      final session = _session(
        playerMoves: const <BattleMoveData>[
          BattleMoveData(
            id: 'tackle',
            name: 'Tackle',
            power: 40,
            type: 'normal',
            category: BattleMoveCategory.physical,
            target: BattleMoveTarget.opponent,
          ),
          BattleMoveData(
            id: 'quick_attack',
            name: 'Quick Attack',
            power: 40,
            type: 'normal',
            category: BattleMoveCategory.physical,
            target: BattleMoveTarget.opponent,
            priority: 1,
          ),
        ],
        enemyMoves: const <BattleMoveData>[
          BattleMoveData(
            id: 'tackle',
            name: 'Tackle',
            power: 40,
            type: 'normal',
            category: BattleMoveCategory.physical,
            target: BattleMoveTarget.opponent,
          ),
        ],
        playerSpeed: 30,
        enemySpeed: 80,
        fieldState: const BattleFieldState(
          pseudoWeather: BattlePseudoWeatherState(
            id: BattlePseudoWeatherId.trickRoom,
            remainingTurns: 3,
          ),
        ),
      );

      final invertedTurn =
          session.applyChoice(const PlayerBattleChoiceFight(0));
      expect(
        invertedTurn.state.currentTurn!.executions.first.attacker,
        equals('player'),
      );

      final priorityTurn =
          session.applyChoice(const PlayerBattleChoiceFight(1));
      expect(
        priorityTurn.state.currentTurn!.executions.first.attacker,
        equals('player'),
      );
    });

    test('a trick room move activates a real pseudoWeather state', () {
      final session = _session(
        playerMoves: const <BattleMoveData>[
          BattleMoveData(
            id: 'trick_room',
            name: 'Trick Room',
            power: 0,
            type: 'psychic',
            category: BattleMoveCategory.status,
            target: BattleMoveTarget.field,
            accuracy: BattleMoveAccuracy.alwaysHits(),
            priority: -7,
            pseudoWeatherEffect: BattlePseudoWeatherId.trickRoom,
          ),
        ],
        enemyMoves: const <BattleMoveData>[
          BattleMoveData(
            id: 'growl',
            name: 'Growl',
            power: 0,
            type: 'normal',
            category: BattleMoveCategory.status,
            target: BattleMoveTarget.opponent,
          ),
        ],
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(
        afterTurn.state.field.pseudoWeather?.id,
        equals(BattlePseudoWeatherId.trickRoom),
      );
      expect(afterTurn.state.field.pseudoWeather?.remainingTurns, equals(4));
      expect(
        afterTurn.state.currentTurn!.fieldEvents.single.kind,
        equals(BattleFieldEventKind.pseudoWeatherSet),
      );
    });

    test(
        'recasting Trick Room clears the active pseudoWeather instead of silently stacking it',
        () {
      final session = _session(
        playerMoves: const <BattleMoveData>[
          BattleMoveData(
            id: 'trick_room',
            name: 'Trick Room',
            power: 0,
            type: 'psychic',
            category: BattleMoveCategory.status,
            target: BattleMoveTarget.field,
            accuracy: BattleMoveAccuracy.alwaysHits(),
            priority: -7,
            pseudoWeatherEffect: BattlePseudoWeatherId.trickRoom,
          ),
        ],
        enemyMoves: const <BattleMoveData>[
          BattleMoveData(
            id: 'growl',
            name: 'Growl',
            power: 0,
            type: 'normal',
            category: BattleMoveCategory.status,
            target: BattleMoveTarget.opponent,
          ),
        ],
        fieldState: const BattleFieldState(
          pseudoWeather: BattlePseudoWeatherState(
            id: BattlePseudoWeatherId.trickRoom,
            remainingTurns: 3,
          ),
        ),
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(afterTurn.state.field.pseudoWeather, isNull);
      expect(
        afterTurn.state.currentTurn!.fieldEvents.single.kind,
        equals(BattleFieldEventKind.pseudoWeatherCleared),
      );
    });

    test('weather and Trick Room expire honestly at end of turn', () {
      final session = _session(
        playerMoves: const <BattleMoveData>[
          BattleMoveData(
            id: 'growl',
            name: 'Growl',
            power: 0,
            type: 'normal',
            category: BattleMoveCategory.status,
            target: BattleMoveTarget.opponent,
          ),
        ],
        enemyMoves: const <BattleMoveData>[
          BattleMoveData(
            id: 'tail_whip',
            name: 'Tail Whip',
            power: 0,
            type: 'normal',
            category: BattleMoveCategory.status,
            target: BattleMoveTarget.opponent,
          ),
        ],
        fieldState: const BattleFieldState(
          weather: BattleWeatherState(
            id: BattleWeatherId.rain,
            remainingTurns: 1,
          ),
          pseudoWeather: BattlePseudoWeatherState(
            id: BattlePseudoWeatherId.trickRoom,
            remainingTurns: 1,
          ),
        ),
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceFight(0));
      final kinds = afterTurn.state.currentTurn!.fieldEvents
          .map((event) => event.kind)
          .toList(growable: false);

      expect(afterTurn.state.field.weather, isNull);
      expect(afterTurn.state.field.pseudoWeather, isNull);
      expect(
        kinds,
        equals(<BattleFieldEventKind>[
          BattleFieldEventKind.weatherExpired,
          BattleFieldEventKind.pseudoWeatherExpired,
        ]),
      );
    });

    test(
        'major-status residuals and sandstorm coexist in the structured end-of-turn phase',
        () {
      final session = _session(
        playerMoves: const <BattleMoveData>[
          BattleMoveData(
            id: 'growl',
            name: 'Growl',
            power: 0,
            type: 'normal',
            category: BattleMoveCategory.status,
            target: BattleMoveTarget.opponent,
          ),
        ],
        enemyMoves: const <BattleMoveData>[
          BattleMoveData(
            id: 'growl',
            name: 'Growl',
            power: 0,
            type: 'normal',
            category: BattleMoveCategory.status,
            target: BattleMoveTarget.opponent,
          ),
        ],
        playerStatus: const BattleMajorStatusState.psn(),
        fieldState: const BattleFieldState(
          weather: BattleWeatherState(
            id: BattleWeatherId.sandstorm,
            remainingTurns: 2,
          ),
        ),
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(afterTurn.state.player.currentHp, equals(82));
      expect(
        afterTurn.state.currentTurn!.statusEvents.where(
            (event) => event.kind == BattleStatusEventKind.residualDamage),
        isNotEmpty,
      );
      expect(
        afterTurn.state.currentTurn!.fieldEvents.where(
          (event) => event.kind == BattleFieldEventKind.weatherResidualDamage,
        ),
        isNotEmpty,
      );
    });
  });
}
