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

BattleMoveData _stealthRock({
  int pp = 20,
  int currentPp = 20,
}) {
  return BattleMoveData(
    id: 'stealth_rock',
    name: 'Stealth Rock',
    power: 0,
    type: 'rock',
    category: BattleMoveCategory.status,
    target: BattleMoveTarget.opponentSide,
    accuracy: BattleMoveAccuracy.alwaysHits(),
    pp: pp,
    currentPp: currentPp,
    setsStealthRock: true,
  );
}

BattleMoveData _spikes({
  int pp = 20,
  int currentPp = 20,
}) {
  return BattleMoveData(
    id: 'spikes',
    name: 'Spikes',
    power: 0,
    type: 'ground',
    category: BattleMoveCategory.status,
    target: BattleMoveTarget.opponentSide,
    accuracy: BattleMoveAccuracy.alwaysHits(),
    pp: pp,
    currentPp: currentPp,
    setsSpikes: true,
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

BattleCombatantData _combatantData({
  required String speciesId,
  required int lineupIndex,
  int maxHp = 80,
  int? currentHp,
  BattleTypingSnapshot? typing,
  BattleStatsSnapshot? stats,
  BattleMajorStatusState? majorStatus,
  required List<BattleMoveData> moves,
}) {
  return BattleCombatantData(
    speciesId: speciesId,
    lineupIndex: lineupIndex,
    level: 40,
    maxHp: maxHp,
    currentHp: currentHp,
    stats: stats ?? _stats(),
    typing: typing,
    majorStatus: majorStatus,
    moves: moves,
  );
}

BattleSession _session({
  required BattleCombatantData player,
  List<BattleCombatantData> playerReserve = const <BattleCombatantData>[],
  required BattleCombatantData enemy,
  List<BattleCombatantData> enemyReserve = const <BattleCombatantData>[],
  bool isTrainerBattle = false,
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
  );
}

void main() {
  group('BattleSession H2 Spikes', () {
    test('sets the first Spikes layer on the opposing side', () {
      final session = _session(
        player: _combatantData(
          speciesId: 'lead_player',
          lineupIndex: 0,
          moves: <BattleMoveData>[_spikes()],
        ),
        enemy: _combatantData(
          speciesId: 'lead_enemy',
          lineupIndex: 0,
          moves: <BattleMoveData>[_waitingMove()],
        ),
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(afterTurn.state.enemySide.spikesLayers, equals(1));
      expect(
        afterTurn.state.currentTurn!.spikesEvents
            .map((event) => event.kind)
            .toList(growable: false),
        equals(<BattleSpikesEventKind>[BattleSpikesEventKind.setLayer]),
      );
      expect(
          afterTurn.state.currentTurn!.spikesEvents.single.layers, equals(1));
    });

    test('raises Spikes from one layer to two layers', () {
      final session = _session(
        player: _combatantData(
          speciesId: 'lead_player',
          lineupIndex: 0,
          moves: <BattleMoveData>[_spikes()],
        ),
        enemy: _combatantData(
          speciesId: 'lead_enemy',
          lineupIndex: 0,
          moves: <BattleMoveData>[_waitingMove()],
        ),
      );

      final afterFirst = session.applyChoice(const PlayerBattleChoiceFight(0));
      final afterSecond =
          afterFirst.applyChoice(const PlayerBattleChoiceFight(0));

      expect(afterSecond.state.enemySide.spikesLayers, equals(2));
      expect(
        afterSecond.state.currentTurn!.spikesEvents.single.layers,
        equals(2),
      );
    });

    test('raises Spikes from two layers to three layers', () {
      final session = _session(
        player: _combatantData(
          speciesId: 'lead_player',
          lineupIndex: 0,
          moves: <BattleMoveData>[_spikes()],
        ),
        enemy: _combatantData(
          speciesId: 'lead_enemy',
          lineupIndex: 0,
          moves: <BattleMoveData>[_waitingMove()],
        ),
      );

      final afterFirst = session.applyChoice(const PlayerBattleChoiceFight(0));
      final afterSecond =
          afterFirst.applyChoice(const PlayerBattleChoiceFight(0));
      final afterThird =
          afterSecond.applyChoice(const PlayerBattleChoiceFight(0));

      expect(afterThird.state.enemySide.spikesLayers, equals(3));
      expect(
          afterThird.state.currentTurn!.spikesEvents.single.layers, equals(3));
    });

    test('does not stack Spikes past three layers', () {
      final session = _session(
        player: _combatantData(
          speciesId: 'lead_player',
          lineupIndex: 0,
          moves: <BattleMoveData>[_spikes()],
        ),
        enemy: _combatantData(
          speciesId: 'lead_enemy',
          lineupIndex: 0,
          moves: <BattleMoveData>[_waitingMove()],
        ),
      );

      final afterFirst = session.applyChoice(const PlayerBattleChoiceFight(0));
      final afterSecond =
          afterFirst.applyChoice(const PlayerBattleChoiceFight(0));
      final afterThird =
          afterSecond.applyChoice(const PlayerBattleChoiceFight(0));
      final afterFourth =
          afterThird.applyChoice(const PlayerBattleChoiceFight(0));

      expect(afterFourth.state.enemySide.spikesLayers, equals(3));
      expect(
        afterFourth.state.currentTurn!.spikesEvents.single.kind,
        equals(BattleSpikesEventKind.alreadyAtMaxLayers),
      );
      expect(
        afterFourth.state.currentTurn!.spikesEvents.single.layers,
        equals(3),
      );
    });

    test('damages a grounded voluntary switch-in with one layer', () {
      final session = _session(
        player: _combatantData(
          speciesId: 'lead_player',
          lineupIndex: 0,
          maxHp: 60,
          moves: <BattleMoveData>[_waitingMove()],
        ),
        playerReserve: <BattleCombatantData>[
          _combatantData(
            speciesId: 'bench_player',
            lineupIndex: 1,
            maxHp: 80,
            typing: const BattleTypingSnapshot(primaryType: 'water'),
            moves: <BattleMoveData>[_waitingMove()],
          ),
        ],
        enemy: _combatantData(
          speciesId: 'lead_enemy',
          lineupIndex: 0,
          moves: <BattleMoveData>[
            _spikes(pp: 1, currentPp: 1),
            _waitingMove(),
          ],
        ),
      );

      final afterHazard = session.applyChoice(const PlayerBattleChoiceFight(0));
      final afterSwitch =
          afterHazard.applyChoice(const PlayerBattleChoiceSwitch(0));

      final damageEvent =
          afterSwitch.state.currentTurn!.spikesEvents.singleWhere(
        (event) => event.kind == BattleSpikesEventKind.damagedOnEntry,
      );

      expect(afterSwitch.state.player.currentHp, equals(70));
      expect(damageEvent.damage, equals(10));
      expect(damageEvent.layers, equals(1));
    });

    test('damages a grounded voluntary switch-in with two layers', () {
      final session = _session(
        player: _combatantData(
          speciesId: 'lead_player',
          lineupIndex: 0,
          maxHp: 60,
          moves: <BattleMoveData>[_waitingMove()],
        ),
        playerReserve: <BattleCombatantData>[
          _combatantData(
            speciesId: 'bench_player',
            lineupIndex: 1,
            maxHp: 80,
            typing: const BattleTypingSnapshot(primaryType: 'water'),
            moves: <BattleMoveData>[_waitingMove()],
          ),
        ],
        enemy: _combatantData(
          speciesId: 'lead_enemy',
          lineupIndex: 0,
          moves: <BattleMoveData>[
            _spikes(pp: 2, currentPp: 2),
            _waitingMove(),
          ],
        ),
      );

      final afterFirst = session.applyChoice(const PlayerBattleChoiceFight(0));
      final afterSecond =
          afterFirst.applyChoice(const PlayerBattleChoiceFight(0));
      final afterSwitch =
          afterSecond.applyChoice(const PlayerBattleChoiceSwitch(0));

      final damageEvent =
          afterSwitch.state.currentTurn!.spikesEvents.singleWhere(
        (event) => event.kind == BattleSpikesEventKind.damagedOnEntry,
      );

      expect(afterSwitch.state.player.currentHp, equals(67));
      expect(damageEvent.damage, equals(13));
      expect(damageEvent.layers, equals(2));
    });

    test('damages a grounded voluntary switch-in with three layers', () {
      final session = _session(
        player: _combatantData(
          speciesId: 'lead_player',
          lineupIndex: 0,
          maxHp: 60,
          moves: <BattleMoveData>[_waitingMove()],
        ),
        playerReserve: <BattleCombatantData>[
          _combatantData(
            speciesId: 'bench_player',
            lineupIndex: 1,
            maxHp: 80,
            typing: const BattleTypingSnapshot(primaryType: 'water'),
            moves: <BattleMoveData>[_waitingMove()],
          ),
        ],
        enemy: _combatantData(
          speciesId: 'lead_enemy',
          lineupIndex: 0,
          moves: <BattleMoveData>[
            _spikes(pp: 3, currentPp: 3),
            _waitingMove(),
          ],
        ),
      );

      final afterFirst = session.applyChoice(const PlayerBattleChoiceFight(0));
      final afterSecond =
          afterFirst.applyChoice(const PlayerBattleChoiceFight(0));
      final afterThird =
          afterSecond.applyChoice(const PlayerBattleChoiceFight(0));
      final afterSwitch =
          afterThird.applyChoice(const PlayerBattleChoiceSwitch(0));

      final damageEvent =
          afterSwitch.state.currentTurn!.spikesEvents.singleWhere(
        (event) => event.kind == BattleSpikesEventKind.damagedOnEntry,
      );

      expect(afterSwitch.state.player.currentHp, equals(60));
      expect(damageEvent.damage, equals(20));
      expect(damageEvent.layers, equals(3));
    });

    test('does not damage a Flying-type switch-in', () {
      final session = _session(
        player: _combatantData(
          speciesId: 'lead_player',
          lineupIndex: 0,
          maxHp: 60,
          moves: <BattleMoveData>[_waitingMove()],
        ),
        playerReserve: <BattleCombatantData>[
          _combatantData(
            speciesId: 'flying_bench',
            lineupIndex: 1,
            maxHp: 80,
            typing: const BattleTypingSnapshot(
              primaryType: 'water',
              secondaryType: 'flying',
            ),
            moves: <BattleMoveData>[_waitingMove()],
          ),
        ],
        enemy: _combatantData(
          speciesId: 'lead_enemy',
          lineupIndex: 0,
          moves: <BattleMoveData>[
            _spikes(pp: 1, currentPp: 1),
            _waitingMove(),
          ],
        ),
      );

      final afterHazard = session.applyChoice(const PlayerBattleChoiceFight(0));
      final afterSwitch =
          afterHazard.applyChoice(const PlayerBattleChoiceSwitch(0));

      expect(afterSwitch.state.player.currentHp, equals(80));
      expect(afterSwitch.state.currentTurn!.spikesEvents, isEmpty);
    });

    test('damages an enemy auto-switch after a KO', () {
      final session = _session(
        isTrainerBattle: true,
        player: _combatantData(
          speciesId: 'lead_player',
          lineupIndex: 0,
          stats: _stats(speed: 90, attack: 100),
          moves: <BattleMoveData>[
            _spikes(),
            _tackle(power: 250),
          ],
        ),
        enemy: _combatantData(
          speciesId: 'lead_enemy',
          lineupIndex: 0,
          maxHp: 40,
          stats: _stats(speed: 20),
          moves: <BattleMoveData>[_waitingMove()],
        ),
        enemyReserve: <BattleCombatantData>[
          _combatantData(
            speciesId: 'bench_enemy',
            lineupIndex: 1,
            maxHp: 80,
            typing: const BattleTypingSnapshot(primaryType: 'water'),
            moves: <BattleMoveData>[_waitingMove()],
          ),
        ],
      );

      final afterHazard = session.applyChoice(const PlayerBattleChoiceFight(0));
      final afterKo = afterHazard.applyChoice(const PlayerBattleChoiceFight(1));

      final damageEvent = afterKo.state.currentTurn!.spikesEvents.singleWhere(
        (event) => event.kind == BattleSpikesEventKind.damagedOnEntry,
      );

      expect(afterKo.state.enemy.speciesId, equals('bench_enemy'));
      expect(afterKo.state.enemy.currentHp, equals(70));
      expect(damageEvent.side, equals(BattleSideId.enemy));
      expect(damageEvent.damage, equals(10));
    });

    test('damages a forced player replacement when the new active enters', () {
      final session = _session(
        player: _combatantData(
          speciesId: 'lead_player',
          lineupIndex: 0,
          maxHp: 80,
          currentHp: 15,
          majorStatus: const BattleMajorStatusState.tox(toxicCounter: 1),
          stats: _stats(speed: 20),
          moves: <BattleMoveData>[_waitingMove()],
        ),
        playerReserve: <BattleCombatantData>[
          _combatantData(
            speciesId: 'bench_player',
            lineupIndex: 1,
            maxHp: 80,
            typing: const BattleTypingSnapshot(primaryType: 'water'),
            moves: <BattleMoveData>[_waitingMove()],
          ),
        ],
        enemy: _combatantData(
          speciesId: 'lead_enemy',
          lineupIndex: 0,
          stats: _stats(speed: 90),
          moves: <BattleMoveData>[
            _spikes(pp: 1, currentPp: 1),
            _waitingMove(),
          ],
        ),
      );

      final afterHazard = session.applyChoice(const PlayerBattleChoiceFight(0));
      final afterKo = afterHazard.applyChoice(const PlayerBattleChoiceFight(0));

      expect(afterKo.decisionRequest, isA<BattleForcedReplacementRequest>());

      final afterReplacement =
          afterKo.applyChoice(const PlayerBattleChoiceSwitch(0));

      final damageEvent =
          afterReplacement.state.currentTurn!.spikesEvents.singleWhere(
        (event) => event.kind == BattleSpikesEventKind.damagedOnEntry,
      );

      expect(afterReplacement.state.player.currentHp, equals(70));
      expect(damageEvent.side, equals(BattleSideId.player));
      expect(damageEvent.damage, equals(10));
      expect(afterReplacement.state.currentTurn!.enemyAction,
          isA<BattleActionNone>());
    });

    test(
      'resolves Stealth Rock before Spikes on entry and stops on Stealth Rock KO',
      () {
        final session = _session(
          player: _combatantData(
            speciesId: 'lead_player',
            lineupIndex: 0,
            maxHp: 60,
            moves: <BattleMoveData>[_waitingMove()],
          ),
          playerReserve: <BattleCombatantData>[
            _combatantData(
              speciesId: 'fragile_grounded_bench',
              lineupIndex: 1,
              maxHp: 80,
              currentHp: 10,
              typing: const BattleTypingSnapshot(primaryType: 'water'),
              moves: <BattleMoveData>[_waitingMove()],
            ),
            _combatantData(
              speciesId: 'healthy_grounded_bench',
              lineupIndex: 2,
              maxHp: 80,
              typing: const BattleTypingSnapshot(primaryType: 'water'),
              moves: <BattleMoveData>[_waitingMove()],
            ),
          ],
          enemy: _combatantData(
            speciesId: 'lead_enemy',
            lineupIndex: 0,
            moves: <BattleMoveData>[
              _stealthRock(pp: 1, currentPp: 1),
              _spikes(pp: 1, currentPp: 1),
              _waitingMove(),
            ],
          ),
        );

        final afterStealthRock =
            session.applyChoice(const PlayerBattleChoiceFight(0));
        final afterSpikes =
            afterStealthRock.applyChoice(const PlayerBattleChoiceFight(0));
        final afterSwitch =
            afterSpikes.applyChoice(const PlayerBattleChoiceSwitch(0));

        expect(afterSwitch.state.player.isFainted, isTrue);
        expect(
          afterSwitch.state.currentTurn!.spikesEvents
              .where(
                  (event) => event.kind == BattleSpikesEventKind.damagedOnEntry)
              .toList(growable: false),
          isEmpty,
        );

        final resumedTurn =
            afterSwitch.applyChoice(const PlayerBattleChoiceSwitch(1));
        final srDamageIndex =
            resumedTurn.state.currentTurn!.timeline.indexWhere(
          (event) =>
              event is BattleTurnStealthRockEvent &&
              event.event.kind == BattleStealthRockEventKind.damagedOnEntry,
        );
        final spikesDamageIndex =
            resumedTurn.state.currentTurn!.timeline.indexWhere(
          (event) =>
              event is BattleTurnSpikesEvent &&
              event.event.kind == BattleSpikesEventKind.damagedOnEntry,
        );

        expect(resumedTurn.state.player.currentHp, equals(60));
        expect(srDamageIndex, greaterThanOrEqualTo(0));
        expect(spikesDamageIndex, greaterThan(srDamageIndex));
      },
    );

    test(
      'a switch-in KO from Spikes keeps the pending enemy move alive after '
      'the forced replacement',
      () {
        final session = _session(
          player: _combatantData(
            speciesId: 'lead_player',
            lineupIndex: 0,
            maxHp: 80,
            moves: <BattleMoveData>[_waitingMove()],
          ),
          playerReserve: <BattleCombatantData>[
            _combatantData(
              speciesId: 'fragile_switch',
              lineupIndex: 1,
              maxHp: 10,
              currentHp: 1,
              typing: const BattleTypingSnapshot(primaryType: 'water'),
              moves: <BattleMoveData>[_waitingMove()],
            ),
            _combatantData(
              speciesId: 'follow_up_switch',
              lineupIndex: 2,
              maxHp: 80,
              currentHp: 80,
              typing: const BattleTypingSnapshot(primaryType: 'water'),
              moves: <BattleMoveData>[_waitingMove()],
            ),
          ],
          enemy: _combatantData(
            speciesId: 'lead_enemy',
            lineupIndex: 0,
            stats: _stats(speed: 30, attack: 90),
            moves: <BattleMoveData>[
              _spikes(pp: 1, currentPp: 1),
              _tackle(power: 40),
            ],
          ),
        );

        final afterHazard =
            session.applyChoice(const PlayerBattleChoiceFight(0));
        final afterFailedEntry =
            afterHazard.applyChoice(const PlayerBattleChoiceSwitch(0));

        expect(afterFailedEntry.decisionRequest,
            isA<BattleForcedReplacementRequest>());
        expect(afterFailedEntry.state.player.isFainted, isTrue);

        final resumedTurn =
            afterFailedEntry.applyChoice(const PlayerBattleChoiceSwitch(1));
        final damageIndex = resumedTurn.state.currentTurn!.timeline.indexWhere(
          (event) =>
              event is BattleTurnSpikesEvent &&
              event.event.kind == BattleSpikesEventKind.damagedOnEntry,
        );
        final replacementSwitchIndex =
            resumedTurn.state.currentTurn!.timeline.indexWhere(
          (event) =>
              event is BattleTurnSwitchEvent &&
              event.event.kind == BattleSwitchEventKind.switched &&
              event.event.toSpeciesId == 'follow_up_switch',
        );
        final attackIndex = resumedTurn.state.currentTurn!.timeline.indexWhere(
          (event) => event is BattleTurnExecutionEvent,
        );

        expect(resumedTurn.state.player.speciesId, equals('follow_up_switch'));
        expect(replacementSwitchIndex, greaterThan(damageIndex));
        expect(attackIndex, greaterThan(replacementSwitchIndex));
      },
    );

    test(
      'waits until the enemy auto-switch chain settles before asking the '
      'player to replace after a double KO on a Spikes side',
      () {
        final session = _session(
          isTrainerBattle: true,
          player: _combatantData(
            speciesId: 'lead_player',
            lineupIndex: 0,
            maxHp: 10,
            currentHp: 2,
            majorStatus: const BattleMajorStatusState.psn(),
            moves: <BattleMoveData>[
              _spikes(pp: 1, currentPp: 1),
              _waitingMove(),
            ],
          ),
          playerReserve: <BattleCombatantData>[
            _combatantData(
              speciesId: 'player_backup',
              lineupIndex: 1,
              maxHp: 80,
              currentHp: 80,
              typing: const BattleTypingSnapshot(primaryType: 'water'),
              moves: <BattleMoveData>[_waitingMove()],
            ),
          ],
          enemy: _combatantData(
            speciesId: 'lead_enemy',
            lineupIndex: 0,
            maxHp: 10,
            currentHp: 2,
            majorStatus: const BattleMajorStatusState.psn(),
            moves: <BattleMoveData>[_waitingMove()],
          ),
          enemyReserve: <BattleCombatantData>[
            _combatantData(
              speciesId: 'fragile_enemy_backup',
              lineupIndex: 1,
              maxHp: 10,
              currentHp: 1,
              typing: const BattleTypingSnapshot(primaryType: 'water'),
              moves: <BattleMoveData>[_waitingMove()],
            ),
            _combatantData(
              speciesId: 'stable_enemy_backup',
              lineupIndex: 2,
              maxHp: 80,
              currentHp: 80,
              typing: const BattleTypingSnapshot(primaryType: 'water'),
              moves: <BattleMoveData>[_waitingMove()],
            ),
          ],
        );

        final afterHazard =
            session.applyChoice(const PlayerBattleChoiceFight(0));
        final afterDoubleKo =
            afterHazard.applyChoice(const PlayerBattleChoiceFight(1));

        final switchEvents = afterDoubleKo.state.currentTurn!.timeline
            .whereType<BattleTurnSwitchEvent>()
            .toList(growable: false);

        expect(afterDoubleKo.decisionRequest,
            isA<BattleForcedReplacementRequest>());
        expect(
          switchEvents.map((event) => event.event.kind).toList(growable: false),
          equals(<BattleSwitchEventKind>[
            BattleSwitchEventKind.switched,
            BattleSwitchEventKind.switched,
            BattleSwitchEventKind.replacementRequired,
          ]),
        );
        expect(
            switchEvents[0].event.toSpeciesId, equals('fragile_enemy_backup'));
        expect(
            switchEvents[1].event.toSpeciesId, equals('stable_enemy_backup'));
        expect(switchEvents.last.event.side, equals(BattleSideId.player));
      },
    );

    test(
      'does not emit a bogus player replacement when the last enemy reserve '
      'dies to Spikes after a double KO',
      () {
        final session = _session(
          isTrainerBattle: true,
          player: _combatantData(
            speciesId: 'lead_player',
            lineupIndex: 0,
            maxHp: 10,
            currentHp: 2,
            majorStatus: const BattleMajorStatusState.psn(),
            moves: <BattleMoveData>[
              _spikes(pp: 1, currentPp: 1),
              _waitingMove(),
            ],
          ),
          playerReserve: <BattleCombatantData>[
            _combatantData(
              speciesId: 'player_backup',
              lineupIndex: 1,
              maxHp: 80,
              currentHp: 80,
              typing: const BattleTypingSnapshot(primaryType: 'water'),
              moves: <BattleMoveData>[_waitingMove()],
            ),
          ],
          enemy: _combatantData(
            speciesId: 'lead_enemy',
            lineupIndex: 0,
            maxHp: 10,
            currentHp: 2,
            majorStatus: const BattleMajorStatusState.psn(),
            moves: <BattleMoveData>[_waitingMove()],
          ),
          enemyReserve: <BattleCombatantData>[
            _combatantData(
              speciesId: 'fragile_enemy_backup',
              lineupIndex: 1,
              maxHp: 10,
              currentHp: 1,
              typing: const BattleTypingSnapshot(primaryType: 'water'),
              moves: <BattleMoveData>[_waitingMove()],
            ),
          ],
        );

        final afterHazard =
            session.applyChoice(const PlayerBattleChoiceFight(0));
        final afterDoubleKo =
            afterHazard.applyChoice(const PlayerBattleChoiceFight(1));

        expect(afterDoubleKo.state.isFinished, isTrue);
        expect(
          afterDoubleKo.state.outcome?.type,
          equals(BattleOutcomeType.victory),
        );
        expect(
          afterDoubleKo.state.currentTurn!.switchEvents
              .where(
                (event) =>
                    event.kind == BattleSwitchEventKind.replacementRequired,
              )
              .toList(growable: false),
          isEmpty,
        );
      },
    );
  });
}
