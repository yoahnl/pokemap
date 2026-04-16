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
  BattleRng rng = const BattleSeededRng(),
}) {
  return createBattleSession(
    BattleSetup(
      playerPokemon: player,
      playerReservePokemon: playerReserve,
      enemyPokemon: enemy,
      enemyReservePokemon: enemyReserve,
      isTrainerBattle: isTrainerBattle,
      trainerId: isTrainerBattle ? 'trainer' : null,
    ),
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
      expect(switchEvent.actor, equals('enemy'));
      expect(switchEvent.kind, equals(BattleSwitchEventKind.switched));
      expect(switchEvent.wasForced, isTrue);
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
