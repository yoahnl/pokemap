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

BattleCombatant _battleCombatant({
  required String speciesId,
  required int maxHp,
  required BattleTypingSnapshot typing,
}) {
  return BattleCombatant(
    speciesId: speciesId,
    level: 40,
    currentHp: maxHp,
    maxHp: maxHp,
    stats: _stats(),
    typing: typing,
    moves: const <BattleMove>[],
  );
}

void main() {
  group('BattleSession H1 Stealth Rock', () {
    test('sets Stealth Rock on the opposing side with a visible event', () {
      final session = _session(
        player: _combatantData(
          speciesId: 'lead_player',
          lineupIndex: 0,
          moves: <BattleMoveData>[_stealthRock()],
        ),
        enemy: _combatantData(
          speciesId: 'lead_enemy',
          lineupIndex: 0,
          moves: <BattleMoveData>[_waitingMove()],
        ),
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(afterTurn.state.enemySide.hasStealthRock, isTrue);
      expect(
        afterTurn.state.currentTurn!.stealthRockEvents
            .map((event) => event.kind)
            .toList(growable: false),
        equals(<BattleStealthRockEventKind>[
          BattleStealthRockEventKind.set,
        ]),
      );
      expect(
        afterTurn.state.currentTurn!.timeline
            .whereType<BattleTurnStealthRockEvent>(),
        hasLength(1),
      );
    });

    test('does not stack Stealth Rock when it is already present', () {
      final session = _session(
        player: _combatantData(
          speciesId: 'lead_player',
          lineupIndex: 0,
          moves: <BattleMoveData>[_stealthRock()],
        ),
        enemy: _combatantData(
          speciesId: 'lead_enemy',
          lineupIndex: 0,
          moves: <BattleMoveData>[_waitingMove()],
        ),
      );

      final afterFirstSet =
          session.applyChoice(const PlayerBattleChoiceFight(0));
      final afterSecondSet =
          afterFirstSet.applyChoice(const PlayerBattleChoiceFight(0));

      expect(afterSecondSet.state.enemySide.hasStealthRock, isTrue);
      expect(
        afterSecondSet.state.currentTurn!.stealthRockEvents
            .map((event) => event.kind)
            .toList(growable: false),
        equals(<BattleStealthRockEventKind>[
          BattleStealthRockEventKind.alreadyPresent,
        ]),
      );
    });

    test('damages a voluntary switch-in on an affected side', () {
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
            _stealthRock(pp: 1, currentPp: 1),
            _waitingMove(),
          ],
        ),
      );

      final afterHazard = session.applyChoice(const PlayerBattleChoiceFight(0));
      final afterSwitch =
          afterHazard.applyChoice(const PlayerBattleChoiceSwitch(0));

      final damageEvent =
          afterSwitch.state.currentTurn!.stealthRockEvents.singleWhere(
        (event) => event.kind == BattleStealthRockEventKind.damagedOnEntry,
      );
      final timeline = afterSwitch.state.currentTurn!.timeline;
      final switchIndex = timeline.indexWhere(
        (event) =>
            event is BattleTurnSwitchEvent &&
            event.event.kind == BattleSwitchEventKind.switched,
      );
      final damageIndex = timeline.indexWhere(
        (event) =>
            event is BattleTurnStealthRockEvent &&
            event.event.kind == BattleStealthRockEventKind.damagedOnEntry,
      );

      expect(afterSwitch.state.player.speciesId, equals('bench_player'));
      expect(afterSwitch.state.player.currentHp, equals(70));
      expect(damageEvent.side, equals(BattleSideId.player));
      expect(damageEvent.damage, equals(10));
      expect(switchIndex, greaterThanOrEqualTo(0));
      expect(damageIndex, greaterThan(switchIndex));
    });

    test(
      'a switch-in KO from Stealth Rock keeps the pending enemy move alive '
      'after the forced replacement',
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
              currentHp: 5,
              typing: const BattleTypingSnapshot(
                primaryType: 'fire',
                secondaryType: 'flying',
              ),
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
              _stealthRock(pp: 1, currentPp: 1),
              _tackle(power: 40),
            ],
          ),
        );

        final afterHazard =
            session.applyChoice(const PlayerBattleChoiceFight(0));
        final afterFailedEntry =
            afterHazard.applyChoice(const PlayerBattleChoiceSwitch(0));

        expect(
          afterFailedEntry.decisionRequest,
          isA<BattleForcedReplacementRequest>(),
        );
        expect(afterFailedEntry.state.player.isFainted, isTrue);
        expect(
          afterFailedEntry.state.currentTurn!.switchEvents.last.kind,
          equals(BattleSwitchEventKind.replacementRequired),
        );

        final resumedTurn =
            afterFailedEntry.applyChoice(const PlayerBattleChoiceSwitch(1));
        final switchEvents = resumedTurn.state.currentTurn!.timeline
            .whereType<BattleTurnSwitchEvent>()
            .toList(growable: false);
        final damageIndex = resumedTurn.state.currentTurn!.timeline.indexWhere(
          (event) =>
              event is BattleTurnStealthRockEvent &&
              event.event.kind == BattleStealthRockEventKind.damagedOnEntry,
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
        expect(resumedTurn.state.currentTurn!.executions, isNotEmpty);
        expect(
          switchEvents.map((event) => event.event.kind),
          containsAllInOrder(<BattleSwitchEventKind>[
            BattleSwitchEventKind.switched,
            BattleSwitchEventKind.replacementRequired,
            BattleSwitchEventKind.switched,
          ]),
        );
        expect(damageIndex, greaterThanOrEqualTo(0));
        expect(replacementSwitchIndex, greaterThan(damageIndex));
        expect(attackIndex, greaterThan(replacementSwitchIndex));
      },
    );

    test('damages an enemy auto-switch after a KO', () {
      final session = _session(
        isTrainerBattle: true,
        player: _combatantData(
          speciesId: 'lead_player',
          lineupIndex: 0,
          stats: _stats(speed: 90, attack: 100),
          moves: <BattleMoveData>[
            _stealthRock(),
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
            typing: const BattleTypingSnapshot(
              primaryType: 'fire',
              secondaryType: 'flying',
            ),
            moves: <BattleMoveData>[_waitingMove()],
          ),
        ],
      );

      final afterHazard = session.applyChoice(const PlayerBattleChoiceFight(0));
      final afterKo = afterHazard.applyChoice(const PlayerBattleChoiceFight(1));

      final damageEvent =
          afterKo.state.currentTurn!.stealthRockEvents.singleWhere(
        (event) => event.kind == BattleStealthRockEventKind.damagedOnEntry,
      );
      final timeline = afterKo.state.currentTurn!.timeline;
      final switchIndex = timeline.indexWhere(
        (event) =>
            event is BattleTurnSwitchEvent &&
            event.event.side == BattleSideId.enemy,
      );
      final damageIndex = timeline.indexWhere(
        (event) =>
            event is BattleTurnStealthRockEvent &&
            event.event.kind == BattleStealthRockEventKind.damagedOnEntry,
      );

      expect(afterKo.state.enemy.speciesId, equals('bench_enemy'));
      expect(afterKo.state.enemy.currentHp, equals(40));
      expect(damageEvent.side, equals(BattleSideId.enemy));
      expect(damageEvent.damage, equals(40));
      expect(switchIndex, greaterThanOrEqualTo(0));
      expect(damageIndex, greaterThan(switchIndex));
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
          moves: <BattleMoveData>[_stealthRock()],
        ),
      );

      final afterHazard = session.applyChoice(const PlayerBattleChoiceFight(0));
      final afterKo = afterHazard.applyChoice(const PlayerBattleChoiceFight(0));

      expect(afterKo.decisionRequest, isA<BattleForcedReplacementRequest>());

      final afterReplacement =
          afterKo.applyChoice(const PlayerBattleChoiceSwitch(0));

      final damageEvent =
          afterReplacement.state.currentTurn!.stealthRockEvents.singleWhere(
        (event) => event.kind == BattleStealthRockEventKind.damagedOnEntry,
      );
      final timeline = afterReplacement.state.currentTurn!.timeline;
      final switchIndex = timeline.indexWhere(
        (event) =>
            event is BattleTurnSwitchEvent &&
            event.event.side == BattleSideId.player,
      );
      final damageIndex = timeline.indexWhere(
        (event) =>
            event is BattleTurnStealthRockEvent &&
            event.event.kind == BattleStealthRockEventKind.damagedOnEntry,
      );

      expect(afterReplacement.state.player.speciesId, equals('bench_player'));
      expect(afterReplacement.state.player.currentHp, equals(70));
      expect(afterReplacement.state.currentTurn!.enemyAction,
          isA<BattleActionNone>());
      expect(damageEvent.side, equals(BattleSideId.player));
      expect(damageEvent.damage, equals(10));
      expect(switchIndex, greaterThanOrEqualTo(0));
      expect(damageIndex, greaterThan(switchIndex));
    });

    test(
      'waits until the enemy auto-switch chain settles before asking the '
      'player to replace after a double KO',
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
              _stealthRock(pp: 1, currentPp: 1),
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
              currentHp: 5,
              typing: const BattleTypingSnapshot(
                primaryType: 'fire',
                secondaryType: 'flying',
              ),
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

        expect(
          afterDoubleKo.decisionRequest,
          isA<BattleForcedReplacementRequest>(),
        );
        expect(
          switchEvents.map((event) => event.event.kind).toList(growable: false),
          equals(<BattleSwitchEventKind>[
            BattleSwitchEventKind.switched,
            BattleSwitchEventKind.switched,
            BattleSwitchEventKind.replacementRequired,
          ]),
        );
        expect(
          switchEvents[0].event.toSpeciesId,
          equals('fragile_enemy_backup'),
        );
        expect(
          switchEvents[1].event.toSpeciesId,
          equals('stable_enemy_backup'),
        );
        expect(
          switchEvents.last.event.side,
          equals(BattleSideId.player),
        );
      },
    );

    test(
      'does not emit a bogus player replacement when the last enemy reserve '
      'dies to Stealth Rock after a double KO',
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
              _stealthRock(pp: 1, currentPp: 1),
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
              currentHp: 5,
              typing: const BattleTypingSnapshot(
                primaryType: 'fire',
                secondaryType: 'flying',
              ),
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

    test(
        'resolves Stealth Rock damage from Rock effectiveness with a minimum of one',
        () {
      final quadrupleWeak = _battleCombatant(
        speciesId: 'charizard_like',
        maxHp: 80,
        typing: const BattleTypingSnapshot(
          primaryType: 'fire',
          secondaryType: 'flying',
        ),
      );
      final quarterResist = _battleCombatant(
        speciesId: 'resist_like',
        maxHp: 20,
        typing: const BattleTypingSnapshot(
          primaryType: 'fighting',
          secondaryType: 'ground',
        ),
      );

      expect(resolveStealthRockEntryDamage(quadrupleWeak), equals(40));
      expect(resolveStealthRockEntryDamage(quarterResist), equals(1));
    });
  });
}
