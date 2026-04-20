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

BattleMoveData _waitingMove() {
  return const BattleMoveData(
    id: 'wait',
    name: 'Wait',
    power: 0,
    category: BattleMoveCategory.status,
    target: BattleMoveTarget.self,
    accuracy: BattleMoveAccuracy.alwaysHits(),
  );
}

BattleMoveData _tackle({
  int power = 40,
}) {
  return BattleMoveData(
    id: 'tackle',
    name: 'Tackle',
    power: power,
    type: 'normal',
    category: BattleMoveCategory.physical,
    target: BattleMoveTarget.opponent,
  );
}

BattleCombatantData _combatant({
  required String speciesId,
  required int lineupIndex,
  int maxHp = 40,
  int? currentHp,
  BattleStatsSnapshot? stats,
  BattleMajorStatusState? majorStatus,
  BattleVolatileState volatileState = const BattleVolatileState(),
  required List<BattleMoveData> moves,
}) {
  return BattleCombatantData(
    speciesId: speciesId,
    lineupIndex: lineupIndex,
    level: 30,
    maxHp: maxHp,
    currentHp: currentHp,
    stats: stats ?? _stats(),
    majorStatus: majorStatus,
    volatileState: volatileState,
    moves: moves,
  );
}

BattleSession _session({
  required BattleCombatantData player,
  List<BattleCombatantData> playerReserve = const <BattleCombatantData>[],
  required BattleCombatantData enemy,
  List<BattleCombatantData> enemyReserve = const <BattleCombatantData>[],
  bool isTrainerBattle = false,
  bool allowCapture = false,
  BattleFieldState fieldState = const BattleFieldState(),
  BattleRng rng = const BattleSeededRng(),
  BattleOpponentPolicy opponentPolicy = const BattleFirstLegalOpponentPolicy(),
}) {
  return createBattleSession(
    BattleSetup(
      playerPokemon: player,
      playerReservePokemon: playerReserve,
      enemyPokemon: enemy,
      enemyReservePokemon: enemyReserve,
      isTrainerBattle: isTrainerBattle,
      trainerId: isTrainerBattle ? 'trainer' : null,
      allowCapture: allowCapture,
      fieldState: fieldState,
    ),
    opponentPolicy: opponentPolicy,
    rng: rng,
  );
}

void main() {
  group('BattleSession BE10 switches and reserves', () {
    test('trainer enemy auto-replaces instead of ending the battle on first KO',
        () {
      final session = _session(
        isTrainerBattle: true,
        player: _combatant(
          speciesId: 'lead_player',
          lineupIndex: 0,
          stats: _stats(speed: 90, attack: 100),
          moves: <BattleMoveData>[
            _tackle(power: 200),
          ],
        ),
        enemy: _combatant(
          speciesId: 'lead_enemy',
          lineupIndex: 0,
          stats: _stats(speed: 20),
          moves: <BattleMoveData>[_waitingMove()],
        ),
        enemyReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'bench_enemy',
            lineupIndex: 1,
            moves: <BattleMoveData>[_waitingMove()],
          ),
        ],
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(afterTurn.state.isFinished, isFalse);
      expect(afterTurn.state.enemy.speciesId, equals('bench_enemy'));
      expect(
          afterTurn.state.enemyReserve.single.speciesId, equals('lead_enemy'));
      final switchEvent = afterTurn.state.currentTurn!.switchEvents.single;
      expect(switchEvent.side, equals(BattleSideId.enemy));
      expect(
        switchEvent.slot,
        equals(const BattleSlotRef.active(BattleSideId.enemy)),
      );
      expect(switchEvent.actor, equals('enemy'));
      expect(switchEvent.kind, equals(BattleSwitchEventKind.switched));
      expect(switchEvent.wasForced, isTrue);
      expect(
        afterTurn.state.currentTurn!.timeline
            .whereType<BattleTurnSwitchEvent>(),
        hasLength(1),
      );
    });

    test(
        'trainer battles without explicit difficulty keep the historical first-usable enemy replacement fallback',
        () {
      final session = _session(
        isTrainerBattle: true,
        opponentPolicy: battleOpponentPolicyForDifficulty(null),
        player: _combatant(
          speciesId: 'lead_player',
          lineupIndex: 0,
          stats: _stats(speed: 90, attack: 100),
          moves: <BattleMoveData>[
            _tackle(power: 200),
          ],
        ),
        enemy: _combatant(
          speciesId: 'lead_enemy',
          lineupIndex: 0,
          stats: _stats(speed: 20),
          moves: <BattleMoveData>[_waitingMove()],
        ),
        enemyReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'status_wall',
            lineupIndex: 1,
            stats: _stats(speed: 20),
            moves: <BattleMoveData>[_waitingMove()],
          ),
          _combatant(
            speciesId: 'slow_nuke',
            lineupIndex: 2,
            stats: _stats(speed: 25),
            moves: <BattleMoveData>[_tackle(power: 120)],
          ),
          _combatant(
            speciesId: 'fast_striker',
            lineupIndex: 3,
            stats: _stats(speed: 95),
            moves: <BattleMoveData>[_tackle(power: 85)],
          ),
        ],
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(afterTurn.state.enemy.speciesId, equals('status_wall'));
      expect(afterTurn.state.currentTurn!.switchEvents.single.wasForced, isTrue);
    });

    test(
        'mid difficulty trainer auto-replaces with the stronger offensive reserve after KO',
        () {
      final session = _session(
        isTrainerBattle: true,
        opponentPolicy: battleOpponentPolicyForDifficulty(5),
        player: _combatant(
          speciesId: 'lead_player',
          lineupIndex: 0,
          stats: _stats(speed: 90, attack: 100),
          moves: <BattleMoveData>[
            _tackle(power: 200),
          ],
        ),
        enemy: _combatant(
          speciesId: 'lead_enemy',
          lineupIndex: 0,
          stats: _stats(speed: 20),
          moves: <BattleMoveData>[_waitingMove()],
        ),
        enemyReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'status_wall',
            lineupIndex: 1,
            stats: _stats(speed: 20),
            moves: <BattleMoveData>[_waitingMove()],
          ),
          _combatant(
            speciesId: 'slow_nuke',
            lineupIndex: 2,
            currentHp: 14,
            stats: _stats(speed: 25, attack: 110, specialAttack: 110),
            moves: <BattleMoveData>[_tackle(power: 120)],
          ),
          _combatant(
            speciesId: 'fast_striker',
            lineupIndex: 3,
            currentHp: 36,
            stats: _stats(speed: 95, attack: 95, specialAttack: 95),
            moves: <BattleMoveData>[_tackle(power: 85)],
          ),
        ],
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(afterTurn.state.enemy.speciesId, equals('slow_nuke'));
      expect(afterTurn.state.currentTurn!.switchEvents.single.wasForced, isTrue);
    });

    test(
        'high difficulty trainer auto-replaces with the healthier faster attacker after KO',
        () {
      final session = _session(
        isTrainerBattle: true,
        opponentPolicy: battleOpponentPolicyForDifficulty(9),
        player: _combatant(
          speciesId: 'lead_player',
          lineupIndex: 0,
          stats: _stats(speed: 90, attack: 100),
          moves: <BattleMoveData>[
            _tackle(power: 200),
          ],
        ),
        enemy: _combatant(
          speciesId: 'lead_enemy',
          lineupIndex: 0,
          stats: _stats(speed: 20),
          moves: <BattleMoveData>[_waitingMove()],
        ),
        enemyReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'status_wall',
            lineupIndex: 1,
            stats: _stats(speed: 20),
            moves: <BattleMoveData>[_waitingMove()],
          ),
          _combatant(
            speciesId: 'slow_nuke',
            lineupIndex: 2,
            currentHp: 14,
            stats: _stats(speed: 25, attack: 110, specialAttack: 110),
            moves: <BattleMoveData>[_tackle(power: 120)],
          ),
          _combatant(
            speciesId: 'fast_striker',
            lineupIndex: 3,
            currentHp: 36,
            stats: _stats(speed: 95, attack: 95, specialAttack: 95),
            moves: <BattleMoveData>[_tackle(power: 85)],
          ),
        ],
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(afterTurn.state.enemy.speciesId, equals('fast_striker'));
      expect(afterTurn.state.currentTurn!.switchEvents.single.wasForced, isTrue);
    });

    test(
        'wild battles keep the historical first-usable enemy replacement fallback',
        () {
      final session = _session(
        isTrainerBattle: false,
        player: _combatant(
          speciesId: 'lead_player',
          lineupIndex: 0,
          stats: _stats(speed: 90, attack: 100),
          moves: <BattleMoveData>[
            _tackle(power: 200),
          ],
        ),
        enemy: _combatant(
          speciesId: 'lead_enemy',
          lineupIndex: 0,
          stats: _stats(speed: 20),
          moves: <BattleMoveData>[_waitingMove()],
        ),
        enemyReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'status_wall',
            lineupIndex: 1,
            stats: _stats(speed: 20),
            moves: <BattleMoveData>[_waitingMove()],
          ),
          _combatant(
            speciesId: 'slow_nuke',
            lineupIndex: 2,
            currentHp: 14,
            stats: _stats(speed: 25, attack: 110, specialAttack: 110),
            moves: <BattleMoveData>[_tackle(power: 120)],
          ),
        ],
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(afterTurn.state.enemy.speciesId, equals('status_wall'));
      expect(afterTurn.state.currentTurn!.switchEvents.single.wasForced, isTrue);
    });

    test(
        'enemy auto-replacement ignores fainted reserves before consulting the trainer policy',
        () {
      final session = _session(
        isTrainerBattle: true,
        opponentPolicy: battleOpponentPolicyForDifficulty(5),
        player: _combatant(
          speciesId: 'lead_player',
          lineupIndex: 0,
          stats: _stats(speed: 90, attack: 100),
          moves: <BattleMoveData>[
            _tackle(power: 200),
          ],
        ),
        enemy: _combatant(
          speciesId: 'lead_enemy',
          lineupIndex: 0,
          stats: _stats(speed: 20),
          moves: <BattleMoveData>[_waitingMove()],
        ),
        enemyReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'fainted_wall',
            lineupIndex: 1,
            currentHp: 0,
            stats: _stats(speed: 20),
            moves: <BattleMoveData>[_waitingMove()],
          ),
          _combatant(
            speciesId: 'slow_nuke',
            lineupIndex: 2,
            currentHp: 14,
            stats: _stats(speed: 25, attack: 110, specialAttack: 110),
            moves: <BattleMoveData>[_tackle(power: 120)],
          ),
          _combatant(
            speciesId: 'fast_striker',
            lineupIndex: 3,
            currentHp: 36,
            stats: _stats(speed: 95, attack: 95, specialAttack: 95),
            moves: <BattleMoveData>[_tackle(power: 85)],
          ),
        ],
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(afterTurn.state.enemy.speciesId, equals('slow_nuke'));
      expect(afterTurn.state.currentTurn!.switchEvents.single.wasForced, isTrue);
    });

    test(
        'enemy auto-replacement ignores offensive reserves whose big move is out of PP',
        () {
      final session = _session(
        isTrainerBattle: true,
        opponentPolicy: battleOpponentPolicyForDifficulty(5),
        player: _combatant(
          speciesId: 'lead_player',
          lineupIndex: 0,
          stats: _stats(speed: 90, attack: 100),
          moves: <BattleMoveData>[
            _tackle(power: 200),
          ],
        ),
        enemy: _combatant(
          speciesId: 'lead_enemy',
          lineupIndex: 0,
          stats: _stats(speed: 20),
          moves: <BattleMoveData>[_waitingMove()],
        ),
        enemyReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'spent_nuke',
            lineupIndex: 1,
            stats: _stats(speed: 25, attack: 110, specialAttack: 110),
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'hyper_beam',
                name: 'Hyper Beam',
                power: 160,
                category: BattleMoveCategory.special,
                target: BattleMoveTarget.opponent,
                pp: 5,
                currentPp: 0,
              ),
            ],
          ),
          _combatant(
            speciesId: 'usable_striker',
            lineupIndex: 2,
            stats: _stats(speed: 70, attack: 90, specialAttack: 90),
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'slash',
                name: 'Slash',
                power: 75,
                category: BattleMoveCategory.physical,
                target: BattleMoveTarget.opponent,
              ),
            ],
          ),
        ],
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(afterTurn.state.enemy.speciesId, equals('usable_striker'));
      expect(afterTurn.state.currentTurn!.switchEvents.single.wasForced, isTrue);
    });

    test(
        'forced replacement choices override stale recharge/charge state on a KO active',
        () {
      final session = _session(
        player: _combatant(
          speciesId: 'fainted_player',
          lineupIndex: 0,
          currentHp: 0,
          volatileState: const BattleVolatileState(
            pendingCharge: BattlePendingChargeState(
              moveIndex: 0,
              moveId: 'beam',
              chargeStateId: 'charge',
            ),
          ),
          moves: <BattleMoveData>[
            const BattleMoveData(
              id: 'beam',
              name: 'Beam',
              power: 80,
              category: BattleMoveCategory.special,
              chargeThenStrikeEffect: BattleChargeThenStrikeEffect(
                chargeStateId: 'charge',
              ),
            ),
          ],
        ),
        playerReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'bench_player',
            lineupIndex: 1,
            moves: <BattleMoveData>[_waitingMove()],
          ),
        ],
        enemy: _combatant(
          speciesId: 'enemy',
          lineupIndex: 0,
          moves: <BattleMoveData>[_waitingMove()],
        ),
      );

      final choices = session.getAvailableChoices();

      expect(choices.whereType<PlayerBattleChoiceContinue>(), isEmpty);
      expect(choices.whereType<PlayerBattleChoiceFight>(), isEmpty);
      expect(choices.whereType<PlayerBattleChoiceSwitch>().single.reserveIndex,
          equals(0));

      final afterReplacement =
          session.applyChoice(const PlayerBattleChoiceSwitch(0));

      expect(afterReplacement.state.player.speciesId, equals('bench_player'));
      expect(afterReplacement.state.playerReserve.single.speciesId,
          equals('fainted_player'));
      expect(
        afterReplacement.state.playerReserve.single.volatileState.hasAny,
        isFalse,
      );
      expect(
        afterReplacement.state.currentTurn!.enemyAction,
        isA<BattleActionNone>(),
      );
      expect(
        afterReplacement.state.currentTurn!.switchEvents.single.wasForced,
        isTrue,
      );
      expect(
        afterReplacement.state.currentTurn!.switchEvents.single.side,
        equals(BattleSideId.player),
      );
      expect(
        afterReplacement.state.currentTurn!.timeline
            .whereType<BattleTurnSwitchEvent>(),
        hasLength(1),
      );
      expect(afterReplacement.state.currentTurn!.executions, isEmpty);
      expect(afterReplacement.state.currentTurn!.statusEvents, isEmpty);
      expect(afterReplacement.state.currentTurn!.fieldEvents, isEmpty);
    });

    test(
        'forced replacement choices expose only valid switches even when wild capture and run would normally be allowed',
        () {
      final session = _session(
        allowCapture: true,
        player: _combatant(
          speciesId: 'fainted_player',
          lineupIndex: 0,
          currentHp: 0,
          moves: <BattleMoveData>[_waitingMove()],
        ),
        playerReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'bench_player',
            lineupIndex: 1,
            moves: <BattleMoveData>[_waitingMove()],
          ),
        ],
        enemy: _combatant(
          speciesId: 'enemy',
          lineupIndex: 0,
          moves: <BattleMoveData>[_waitingMove()],
        ),
      );

      final choices = session.getAvailableChoices();

      expect(choices.whereType<PlayerBattleChoiceSwitch>(), hasLength(1));
      expect(choices.whereType<PlayerBattleChoiceFight>(), isEmpty);
      expect(choices.whereType<PlayerBattleChoiceContinue>(), isEmpty);
      expect(choices.whereType<PlayerBattleChoiceRun>(), isEmpty);
      expect(choices.whereType<PlayerBattleChoiceCapture>(), isEmpty);
    });

    test('voluntary switch resolves before an opposing attack and redirects it',
        () {
      final session = _session(
        player: _combatant(
          speciesId: 'lead_player',
          lineupIndex: 0,
          maxHp: 35,
          currentHp: 35,
          stats: _stats(speed: 20),
          moves: <BattleMoveData>[_waitingMove()],
        ),
        playerReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'bench_player',
            lineupIndex: 1,
            maxHp: 50,
            currentHp: 50,
            moves: <BattleMoveData>[_waitingMove()],
          ),
        ],
        enemy: _combatant(
          speciesId: 'enemy',
          lineupIndex: 0,
          stats: _stats(speed: 100, attack: 80),
          moves: <BattleMoveData>[_tackle(power: 35)],
        ),
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceSwitch(0));

      expect(afterTurn.state.player.speciesId, equals('bench_player'));
      expect(afterTurn.state.player.currentHp, lessThan(50));
      expect(
        afterTurn.state.playerReserve.single.speciesId,
        equals('lead_player'),
      );
      expect(
        afterTurn.state.playerReserve.single.currentHp,
        equals(35),
      );
      expect(
        afterTurn.state.currentTurn!.switchEvents.single.wasForced,
        isFalse,
      );
      final timeline = afterTurn.state.currentTurn!.timeline;
      final firstSwitchEvent =
          timeline.whereType<BattleTurnSwitchEvent>().first;
      final enemyExecution =
          timeline.whereType<BattleTurnExecutionEvent>().single;
      expect(firstSwitchEvent.event.side, equals(BattleSideId.player));
      expect(enemyExecution.execution.attacker, equals('enemy'));
      expect(
        timeline.indexOf(firstSwitchEvent),
        lessThan(timeline.indexOf(enemyExecution)),
      );
    });

    test('field state survives a voluntary switch turn', () {
      final session = _session(
        fieldState: const BattleFieldState(
          weather: BattleWeatherState(
            id: BattleWeatherId.rain,
            remainingTurns: 3,
          ),
          pseudoWeather: BattlePseudoWeatherState(
            id: BattlePseudoWeatherId.trickRoom,
            remainingTurns: 3,
          ),
        ),
        player: _combatant(
          speciesId: 'lead_player',
          lineupIndex: 0,
          moves: <BattleMoveData>[_waitingMove()],
        ),
        playerReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'bench_player',
            lineupIndex: 1,
            moves: <BattleMoveData>[_waitingMove()],
          ),
        ],
        enemy: _combatant(
          speciesId: 'enemy',
          lineupIndex: 0,
          moves: <BattleMoveData>[_waitingMove()],
        ),
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceSwitch(0));

      expect(afterTurn.state.player.speciesId, equals('bench_player'));
      expect(afterTurn.state.field.weather?.id, equals(BattleWeatherId.rain));
      expect(
        afterTurn.state.field.weather?.remainingTurns,
        equals(2),
      );
      expect(
        afterTurn.state.field.pseudoWeather?.id,
        equals(BattlePseudoWeatherId.trickRoom),
      );
      expect(
        afterTurn.state.field.pseudoWeather?.remainingTurns,
        equals(2),
      );
    });

    test(
        'switching out resets stages and volatile baggage but keeps hp, pp, and major status while tox counter restarts at 1',
        () {
      final session = _session(
        player: _combatant(
          speciesId: 'lead_player',
          lineupIndex: 0,
          currentHp: 27,
          majorStatus: const BattleMajorStatusState.tox(toxicCounter: 4),
          stats: _stats(speed: 80),
          moves: <BattleMoveData>[
            const BattleMoveData(
              id: 'swords_dance',
              name: 'Swords Dance',
              power: 0,
              category: BattleMoveCategory.status,
              target: BattleMoveTarget.self,
              selfStatStageChanges: <BattleStatStageChange>[
                BattleStatStageChange(stat: BattleStatId.attack, stages: 2),
              ],
            ),
            const BattleMoveData(
              id: 'tackle',
              name: 'Tackle',
              power: 40,
              category: BattleMoveCategory.physical,
              currentPp: 7,
              pp: 35,
            ),
          ],
        ),
        playerReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'bench_player',
            lineupIndex: 1,
            moves: <BattleMoveData>[_waitingMove()],
          ),
        ],
        enemy: _combatant(
          speciesId: 'enemy',
          lineupIndex: 0,
          moves: <BattleMoveData>[_waitingMove()],
        ),
      );

      final afterBoost = session.applyChoice(const PlayerBattleChoiceFight(0));
      expect(afterBoost.state.player.statStages.attack, equals(2));

      final afterSwitchOut =
          afterBoost.applyChoice(const PlayerBattleChoiceSwitch(0));
      final benchedLead = afterSwitchOut.state.playerReserve.singleWhere(
        (combatant) => combatant.speciesId == 'lead_player',
      );
      expect(benchedLead.statStages.attack, equals(0));
      expect(
        benchedLead.currentHp,
        equals(afterBoost.state.player.currentHp),
      );
      expect(benchedLead.moves[1].currentPp, equals(7));
      expect(benchedLead.majorStatus!.id, equals(BattleMajorStatusId.tox));
      expect(benchedLead.majorStatus!.toxicCounter, equals(1));

      final afterSwitchBack =
          afterSwitchOut.applyChoice(const PlayerBattleChoiceSwitch(0));

      expect(afterSwitchBack.state.player.speciesId, equals('lead_player'));
      expect(afterSwitchBack.state.player.statStages.attack, equals(0));
      expect(afterSwitchBack.state.player.moves[1].currentPp, equals(7));
      expect(
        afterSwitchBack.state.currentTurn!.statusEvents
            .where(
              (event) =>
                  event.kind == BattleStatusEventKind.residualDamage &&
                  event.target == 'player',
            )
            .single
            .toxicCounter,
        equals(1),
      );
    });

    test(
        'double KO with reserves on both sides auto-replaces enemy and forces the player to switch',
        () {
      final session = _session(
        isTrainerBattle: true,
        player: _combatant(
          speciesId: 'lead_player',
          lineupIndex: 0,
          currentHp: 1,
          majorStatus: const BattleMajorStatusState.psn(),
          moves: <BattleMoveData>[_waitingMove()],
        ),
        playerReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'bench_player',
            lineupIndex: 1,
            moves: <BattleMoveData>[_waitingMove()],
          ),
        ],
        enemy: _combatant(
          speciesId: 'lead_enemy',
          lineupIndex: 0,
          currentHp: 1,
          majorStatus: const BattleMajorStatusState.psn(),
          moves: <BattleMoveData>[_waitingMove()],
        ),
        enemyReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'bench_enemy',
            lineupIndex: 1,
            moves: <BattleMoveData>[_waitingMove()],
          ),
        ],
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(afterTurn.state.isFinished, isFalse);
      expect(afterTurn.state.player.isFainted, isTrue);
      expect(afterTurn.state.enemy.speciesId, equals('bench_enemy'));
      expect(
        afterTurn.state.currentTurn!.switchEvents
            .map((event) => event.kind)
            .toList(growable: false),
        equals(<BattleSwitchEventKind>[
          BattleSwitchEventKind.switched,
          BattleSwitchEventKind.replacementRequired,
        ]),
      );
      expect(
        afterTurn.getAvailableChoices().whereType<PlayerBattleChoiceSwitch>(),
        hasLength(1),
      );
      final switchTimeline = afterTurn.state.currentTurn!.timeline
          .whereType<BattleTurnSwitchEvent>()
          .toList(growable: false);
      expect(
        switchTimeline.map((event) => event.event.kind).toList(growable: false),
        equals(<BattleSwitchEventKind>[
          BattleSwitchEventKind.switched,
          BattleSwitchEventKind.replacementRequired,
        ]),
      );
    });

    test('double KO with only an enemy reserve remains a defeat for the player',
        () {
      final session = _session(
        isTrainerBattle: true,
        player: _combatant(
          speciesId: 'lead_player',
          lineupIndex: 0,
          currentHp: 1,
          majorStatus: const BattleMajorStatusState.psn(),
          moves: <BattleMoveData>[_waitingMove()],
        ),
        enemy: _combatant(
          speciesId: 'lead_enemy',
          lineupIndex: 0,
          currentHp: 1,
          majorStatus: const BattleMajorStatusState.psn(),
          moves: <BattleMoveData>[_waitingMove()],
        ),
        enemyReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'bench_enemy',
            lineupIndex: 1,
            moves: <BattleMoveData>[_waitingMove()],
          ),
        ],
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(afterTurn.state.isFinished, isTrue);
      expect(afterTurn.state.outcome!.isDefeat, isTrue);
      expect(afterTurn.state.enemy.speciesId, equals('bench_enemy'));
    });
  });
}
