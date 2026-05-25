import 'package:map_battle/map_battle.dart';
import 'package:map_battle/src/domain/effect/move/echoed_voice_effect.dart';
import 'package:map_battle/src/domain/effect/move/rollout_effect.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK consecutive-power move families', () {
    test('s_fury_cutter doubles after consecutive successful uses', () {
      final first = _runMove(
        playerMove: _move(
          id: 'fury_cutter',
          type: 'bug',
          power: 40,
          battleEngineMethod: 's_fury_cutter',
        ),
      );
      final third = _runMove(
        playerMoveHistory: _successes('fury_cutter', count: 2),
        playerMove: _move(
          id: 'fury_cutter',
          type: 'bug',
          power: 40,
          battleEngineMethod: 's_fury_cutter',
        ),
      );

      expect(
        _damage(third, moveId: 'fury_cutter'),
        greaterThan(_damage(first, moveId: 'fury_cutter')),
      );
    });

    test('s_fury_cutter resets when the previous successful move is different',
        () {
      final first = _runMove(
        playerMove: _move(
          id: 'fury_cutter',
          type: 'bug',
          power: 40,
          battleEngineMethod: 's_fury_cutter',
        ),
      );
      final reset = _runMove(
        playerMoveHistory: _history(
          successes: const <String>['fury_cutter', 'tackle'],
        ),
        playerMove: _move(
          id: 'fury_cutter',
          type: 'bug',
          power: 40,
          battleEngineMethod: 's_fury_cutter',
        ),
      );

      expect(
        _damage(reset, moveId: 'fury_cutter'),
        _damage(first, moveId: 'fury_cutter'),
      );
    });

    test('s_fury_cutter resets when the previous attempt failed', () {
      final first = _runMove(
        playerMove: _move(
          id: 'fury_cutter',
          type: 'bug',
          power: 40,
          battleEngineMethod: 's_fury_cutter',
        ),
      );
      final reset = _runMove(
        playerMoveHistory: _history(
          attempts: const <String>['fury_cutter', 'fury_cutter'],
          successes: const <String>['fury_cutter'],
        ),
        playerMove: _move(
          id: 'fury_cutter',
          type: 'bug',
          power: 40,
          battleEngineMethod: 's_fury_cutter',
        ),
      );

      expect(
        _damage(reset, moveId: 'fury_cutter'),
        _damage(first, moveId: 'fury_cutter'),
      );
    });

    test('s_fury_cutter caps at 160 base power', () {
      final capped = _runMove(
        playerMoveHistory: _successes('fury_cutter', count: 2),
        playerMove: _move(
          id: 'fury_cutter',
          type: 'bug',
          power: 40,
          battleEngineMethod: 's_fury_cutter',
        ),
      );
      final overCapped = _runMove(
        playerMoveHistory: _successes('fury_cutter', count: 5),
        playerMove: _move(
          id: 'fury_cutter',
          type: 'bug',
          power: 40,
          battleEngineMethod: 's_fury_cutter',
        ),
      );

      expect(
        _damage(overCapped, moveId: 'fury_cutter'),
        _damage(capped, moveId: 'fury_cutter'),
      );
    });

    for (final entry in <({String method, String moveId})>[
      (method: 's_rollout', moveId: 'rollout'),
      (method: 's_ice_ball', moveId: 'ice_ball'),
    ]) {
      test('${entry.method} installs a rollout lock after a hit', () {
        final result = _runMove(
          playerMove: _move(
            id: entry.moveId,
            type: entry.method == 's_rollout' ? 'rock' : 'ice',
            power: 30,
            battleEngineMethod: entry.method,
          ),
        );

        final effect = result.state
            .battlerAt(psdkPlayerSlot)
            .effects
            .effects
            .whereType<RolloutEffect>()
            .single;
        expect(effect.forcedMoveId, entry.moveId);
        expect(effect.remainingTurns, 4);
        expect(effect.successiveUses, 1);
      });

      test('${entry.method} blocks selecting another move while locked', () {
        final engine = _engine(
          playerMoves: <PsdkBattleMoveData>[
            _move(
              id: entry.moveId,
              type: entry.method == 's_rollout' ? 'rock' : 'ice',
              power: 30,
              battleEngineMethod: entry.method,
            ),
            _move(id: 'tackle', power: 40),
          ],
        );

        final first =
            engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
        final second =
            engine.submit(const PsdkBattleDecision.fight(moveSlot: 1));

        expect(_damage(first, moveId: entry.moveId), greaterThan(0));
        expect(_failed(second, moveId: 'tackle'), isTrue);
        expect(_damageEvents(second, moveId: 'tackle'), isEmpty);
      });

      test('${entry.method} doubles after consecutive successful uses', () {
        final first = _runMove(
          playerMove: _move(
            id: entry.moveId,
            type: entry.method == 's_rollout' ? 'rock' : 'ice',
            power: 30,
            battleEngineMethod: entry.method,
          ),
        );
        final second = _runMove(
          playerMoveHistory: _successes(entry.moveId, count: 1),
          playerMove: _move(
            id: entry.moveId,
            type: entry.method == 's_rollout' ? 'rock' : 'ice',
            power: 30,
            battleEngineMethod: entry.method,
          ),
        );

        expect(
          _damage(second, moveId: entry.moveId),
          greaterThan(_damage(first, moveId: entry.moveId)),
        );
      });

      test('${entry.method} advances the rollout counter after repeated hits',
          () {
        final engine = _engine(
          playerMoves: <PsdkBattleMoveData>[
            _move(
              id: entry.moveId,
              type: entry.method == 's_rollout' ? 'rock' : 'ice',
              power: 30,
              battleEngineMethod: entry.method,
            ),
          ],
        );

        final first =
            engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
        final second =
            engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
        final effect = second.state
            .battlerAt(psdkPlayerSlot)
            .effects
            .effects
            .whereType<RolloutEffect>()
            .single;

        expect(
          _damage(second, moveId: entry.moveId),
          greaterThan(_damage(first, moveId: entry.moveId)),
        );
        expect(effect.remainingTurns, 3);
        expect(effect.successiveUses, 2);
      });

      test('${entry.method} clears the rollout lock when the move misses', () {
        final result = _runMove(
          playerEffects: PsdkBattleEffectStack(
            effects: <BattleEffect>[
              RolloutEffect(
                scope: const BattlerBattleEffectScope(psdkPlayerSlot),
                forcedMoveId: entry.moveId,
                remainingTurns: 3,
                successiveUses: 2,
              ),
            ],
          ),
          moveAccuracySeed: 99,
          playerMove: _move(
            id: entry.moveId,
            type: entry.method == 's_rollout' ? 'rock' : 'ice',
            power: 30,
            accuracy: 1,
            battleEngineMethod: entry.method,
          ),
        );

        expect(_damageEvents(result, moveId: entry.moveId), isEmpty);
        expect(
          result.state.battlerAt(psdkPlayerSlot).effects.contains('rollout'),
          isFalse,
        );
      });

      test('${entry.method} doubles once after Defense Curl succeeded', () {
        final first = _runMove(
          playerMove: _move(
            id: entry.moveId,
            type: entry.method == 's_rollout' ? 'rock' : 'ice',
            power: 30,
            battleEngineMethod: entry.method,
          ),
        );
        final curled = _runMove(
          playerMoveHistory: _history(successes: const <String>[
            'defense_curl',
          ]),
          playerMove: _move(
            id: entry.moveId,
            type: entry.method == 's_rollout' ? 'rock' : 'ice',
            power: 30,
            battleEngineMethod: entry.method,
          ),
        );

        expect(
          _damage(curled, moveId: entry.moveId),
          greaterThan(_damage(first, moveId: entry.moveId)),
        );
      });
    }

    test('s_echo gains power from the field chain counter', () {
      final first = _runMove(
        playerMove: _echoedVoice(),
      );
      final boosted = _runMove(
        playerEffects: PsdkBattleEffectStack(
          effects: const <BattleEffect>[
            EchoedVoiceEffect(
              scope: FieldBattleEffectScope(),
              successiveTurns: 2,
              hasIncreased: false,
            ),
          ],
        ),
        playerMove: _echoedVoice(),
      );

      expect(
        _damage(boosted, moveId: 'echoed_voice'),
        greaterThan(_damage(first, moveId: 'echoed_voice')),
      );
    });

    test('s_echo gains power from any previous turn user on the field', () {
      final baseline = _runMove(
        playerMove: _echoedVoice(),
      );
      final engine = _engine(
        playerMoves: <PsdkBattleMoveData>[
          _move(
            id: 'splash',
            category: PsdkBattleMoveCategory.status,
            power: 0,
            battleEngineMethod: 's_splash',
          ),
          _echoedVoice(),
        ],
        opponentMove: _echoedVoice(id: 'opponent_echoed_voice'),
      );

      engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      final boosted =
          engine.submit(const PsdkBattleDecision.fight(moveSlot: 1));

      expect(
        _damage(boosted, moveId: 'echoed_voice'),
        greaterThan(_damage(baseline, moveId: 'echoed_voice')),
      );
    });

    test('s_echo resets after a turn without Echoed Voice', () {
      final baseline = _runMove(playerMove: _echoedVoice());
      final engine = _engine(
        playerMoves: <PsdkBattleMoveData>[
          _echoedVoice(),
          _move(
            id: 'splash',
            category: PsdkBattleMoveCategory.status,
            power: 0,
            battleEngineMethod: 's_splash',
          ),
        ],
      );

      engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      engine.submit(const PsdkBattleDecision.fight(moveSlot: 1));
      final reset = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));

      expect(
        reset.state.combatants.values.any(
          (battler) => battler.effects.contains('echoed_voice'),
        ),
        isTrue,
      );
      expect(
        _damage(reset, moveId: 'echoed_voice'),
        _damage(baseline, moveId: 'echoed_voice'),
      );
    });

    test('s_echo chain advances even when its field-effect owner faints', () {
      final state = PsdkBattleState(
        combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
          psdkPlayerSlot: PsdkBattleCombatant.fromSetup(
            _combatant(
              id: 'player',
              speed: 100,
              move: _echoedVoice(),
              currentHp: 0,
              effects: PsdkBattleEffectStack(
                effects: const <BattleEffect>[
                  EchoedVoiceEffect(
                    scope: FieldBattleEffectScope(),
                    hasIncreased: true,
                  ),
                ],
              ),
            ),
          ),
          psdkOpponentSlot: PsdkBattleCombatant.fromSetup(
            _combatant(id: 'opponent', speed: 1, move: _echoedVoice()),
          ),
        },
      );

      final result = const BattleEndTurnHandler().tickEndTurnEffects(
        BattleHandlerContext(
          state: state,
          rng: BattleRngStreams.fromSeeds(
            moveDamageSeed: 1,
            moveCriticalSeed: 99999,
            moveAccuracySeed: 3,
            genericSeed: 4,
          ),
          turn: 1,
          user: psdkPlayerSlot,
        ),
      );

      expect(state.battlerAt(psdkPlayerSlot).isFainted, isTrue);
      expect(_echoedVoiceEffectIn(result.state).successiveTurns, 1);
      expect(_echoedVoiceEffectIn(result.state).hasIncreased, isFalse);
    });

    test('s_echo caps field-chain power at 200', () {
      final capped = _runMove(
        playerEffects: PsdkBattleEffectStack(
          effects: const <BattleEffect>[
            EchoedVoiceEffect(
              scope: FieldBattleEffectScope(),
              successiveTurns: 4,
              hasIncreased: false,
            ),
          ],
        ),
        playerMove: _echoedVoice(),
      );
      final overCapped = _runMove(
        playerEffects: PsdkBattleEffectStack(
          effects: const <BattleEffect>[
            EchoedVoiceEffect(
              scope: FieldBattleEffectScope(),
              successiveTurns: 12,
              hasIncreased: false,
            ),
          ],
        ),
        playerMove: _echoedVoice(),
      );

      expect(
        _damage(overCapped, moveId: 'echoed_voice'),
        _damage(capped, moveId: 'echoed_voice'),
      );
    });

    test('s_round doubles power when an ally used Round this turn', () {
      final round = _move(
        id: 'round',
        category: PsdkBattleMoveCategory.special,
        power: 60,
        battleEngineMethod: 's_round',
      );
      final baseline = _resolveRound(
        move: round,
        allyMoveHistory: PsdkBattleMoveHistory.empty(),
      );
      final boosted = _resolveRound(
        move: round,
        allyMoveHistory: _historyAt(
          successes: const <String>['round'],
          turn: 7,
        ),
      );

      expect(
        _resolutionDamage(boosted, moveId: 'round'),
        greaterThan(_resolutionDamage(baseline, moveId: 'round')),
      );
    });

    test('s_pledge combines with an ally pledge and installs field effect', () {
      final firePledge = _move(
        id: 'fire_pledge',
        type: 'fire',
        category: PsdkBattleMoveCategory.special,
        power: 80,
        battleEngineMethod: 's_pledge',
      );
      final waterPledge = _move(
        id: 'water_pledge',
        type: 'water',
        category: PsdkBattleMoveCategory.special,
        power: 80,
        battleEngineMethod: 's_pledge',
      );
      final baseline = _resolvePledge(
        playerMove: firePledge,
        allyMove: waterPledge,
        allyMoveHistory: PsdkBattleMoveHistory.empty(),
      );
      final combined = _resolvePledge(
        playerMove: firePledge,
        allyMove: waterPledge,
        allyMoveHistory: _historyAt(
          successes: const <String>['water_pledge'],
          turn: 7,
        ),
      );

      expect(
        _resolutionDamage(combined, moveId: 'fire_pledge'),
        greaterThan(_resolutionDamage(baseline, moveId: 'fire_pledge')),
      );
      expect(
        combined.state
            .battlerAt(psdkPlayerSlot)
            .effects
            .contains('pledge_rainbow'),
        isTrue,
      );
    });

    test('s_pledge combo uses the PSDK 160 base power', () {
      final firePledge = _move(
        id: 'fire_pledge',
        type: 'fire',
        category: PsdkBattleMoveCategory.special,
        power: 80,
        battleEngineMethod: 's_pledge',
      );
      final waterPledge = _move(
        id: 'water_pledge',
        type: 'water',
        category: PsdkBattleMoveCategory.special,
        power: 80,
        battleEngineMethod: 's_pledge',
      );
      final combined = _resolvePledge(
        playerMove: firePledge,
        allyMove: waterPledge,
        allyMoveHistory: _historyAt(
          successes: const <String>['water_pledge'],
          turn: 7,
        ),
      );
      final power160 = _runMove(
        playerMove: _move(
          id: 'fire_pledge',
          type: 'fire',
          category: PsdkBattleMoveCategory.special,
          power: 160,
        ),
      );

      expect(
        _resolutionDamage(combined, moveId: 'fire_pledge'),
        _damage(power160, moveId: 'fire_pledge'),
      );
    });

    test('s_trump_card grows stronger as remaining PP gets lower', () {
      final highPp = _runMove(
        playerMove: _move(
          id: 'trump_card',
          category: PsdkBattleMoveCategory.special,
          power: 40,
          pp: 8,
          currentPp: 5,
          battleEngineMethod: 's_trump_card',
        ),
      );
      final lowPp = _runMove(
        playerMove: _move(
          id: 'trump_card',
          category: PsdkBattleMoveCategory.special,
          power: 40,
          pp: 8,
          currentPp: 2,
          battleEngineMethod: 's_trump_card',
        ),
      );

      expect(
        _damage(lowPp, moveId: 'trump_card'),
        greaterThan(_damage(highPp, moveId: 'trump_card')),
      );
    });

    test('s_trump_card bypasses accuracy against reachable targets', () {
      final result = _runMove(
        playerMove: _move(
          id: 'trump_card',
          category: PsdkBattleMoveCategory.special,
          power: 1,
          accuracy: 1,
          pp: 8,
          currentPp: 2,
          battleEngineMethod: 's_trump_card',
        ),
      );

      expect(_damageEvents(result, moveId: 'trump_card'), hasLength(1));
      expect(
        result.timeline.events.map((event) => event.kind),
        isNot(contains('move_missed')),
      );
    });
  });
}

PsdkBattleMoveHistory _successes(String moveId, {required int count}) {
  return _history(successes: <String>[
    for (var i = 0; i < count; i++) moveId,
  ]);
}

PsdkBattleMoveHistory _history({
  List<String>? attempts,
  required List<String> successes,
}) {
  final attemptIds = attempts ?? successes;
  return PsdkBattleMoveHistory(
    attempts: <PsdkBattleMoveHistoryEntry>[
      for (var i = 0; i < attemptIds.length; i++)
        PsdkBattleMoveHistoryEntry(
          moveId: attemptIds[i],
          turn: i + 1,
          targets: const <PsdkBattleSlotRef>[psdkOpponentSlot],
        ),
    ],
    successes: <PsdkBattleMoveHistoryEntry>[
      for (var i = 0; i < successes.length; i++)
        PsdkBattleMoveHistoryEntry(
          moveId: successes[i],
          turn: i + 1,
          targets: const <PsdkBattleSlotRef>[psdkOpponentSlot],
        ),
    ],
  );
}

PsdkBattleMoveHistory _historyAt({
  required List<String> successes,
  required int turn,
}) {
  return PsdkBattleMoveHistory(
    attempts: <PsdkBattleMoveHistoryEntry>[
      for (final moveId in successes)
        PsdkBattleMoveHistoryEntry(
          moveId: moveId,
          turn: turn,
          targets: const <PsdkBattleSlotRef>[psdkOpponentSlot],
        ),
    ],
    successes: <PsdkBattleMoveHistoryEntry>[
      for (final moveId in successes)
        PsdkBattleMoveHistoryEntry(
          moveId: moveId,
          turn: turn,
          targets: const <PsdkBattleSlotRef>[psdkOpponentSlot],
        ),
    ],
  );
}

BattleMoveBehaviorResolution _resolveRound({
  required PsdkBattleMoveData move,
  required PsdkBattleMoveHistory allyMoveHistory,
}) {
  const userSlot = psdkPlayerSlot;
  const allySlot = PsdkBattleSlotRef(bank: 0, position: 1);
  const targetSlot = psdkOpponentSlot;
  final state = PsdkBattleState(
    combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
      userSlot: PsdkBattleCombatant.fromSetup(
        _combatant(id: 'player', speed: 100, move: move),
      ),
      allySlot: PsdkBattleCombatant.fromSetup(
        _combatant(
          id: 'ally',
          speed: 50,
          move: move,
          moveHistory: allyMoveHistory,
        ),
      ),
      targetSlot: PsdkBattleCombatant.fromSetup(
        _combatant(
          id: 'opponent',
          speed: 1,
          move: _move(
            id: 'opponent_wait',
            power: 0,
            category: PsdkBattleMoveCategory.status,
            battleEngineMethod: 's_splash',
          ),
        ),
      ),
    },
  );

  return createStaticBasicMoveRegistry().resolve('s_round').resolve(
        BattleMoveBehaviorContext(
          state: state,
          rng: BattleRngStreams.fromSeeds(
            moveDamageSeed: 1,
            moveCriticalSeed: 99999,
            moveAccuracySeed: 3,
            genericSeed: 4,
          ),
          turn: 7,
          user: userSlot,
          target: targetSlot,
          move: BattleMoveDefinition.fromPsdk(move),
        ),
      );
}

BattleMoveBehaviorResolution _resolvePledge({
  required PsdkBattleMoveData playerMove,
  required PsdkBattleMoveData allyMove,
  required PsdkBattleMoveHistory allyMoveHistory,
}) {
  const userSlot = psdkPlayerSlot;
  const allySlot = PsdkBattleSlotRef(bank: 0, position: 1);
  const targetSlot = psdkOpponentSlot;
  final state = PsdkBattleState(
    combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
      userSlot: PsdkBattleCombatant.fromSetup(
        _combatant(id: 'player', speed: 100, move: playerMove),
      ),
      allySlot: PsdkBattleCombatant.fromSetup(
        _combatant(
          id: 'ally',
          speed: 50,
          move: allyMove,
          moveHistory: allyMoveHistory,
        ),
      ),
      targetSlot: PsdkBattleCombatant.fromSetup(
        _combatant(
          id: 'opponent',
          speed: 1,
          move: _move(
            id: 'opponent_wait',
            power: 0,
            category: PsdkBattleMoveCategory.status,
            battleEngineMethod: 's_splash',
          ),
        ),
      ),
    },
  );

  return createStaticBasicMoveRegistry().resolve('s_pledge').resolve(
        BattleMoveBehaviorContext(
          state: state,
          rng: BattleRngStreams.fromSeeds(
            moveDamageSeed: 1,
            moveCriticalSeed: 99999,
            moveAccuracySeed: 3,
            genericSeed: 4,
          ),
          turn: 7,
          user: userSlot,
          target: targetSlot,
          move: BattleMoveDefinition.fromPsdk(playerMove),
        ),
      );
}

PsdkBattleTurnResult _runMove({
  required PsdkBattleMoveData playerMove,
  PsdkBattleMoveHistory? playerMoveHistory,
  PsdkBattleEffectStack? playerEffects,
  int moveAccuracySeed = 3,
}) {
  final engine = PsdkBattleEngine(
    setup: PsdkBattleSetup.singles(
      player: _combatant(
        id: 'player',
        speed: 100,
        move: playerMove,
        moveHistory: playerMoveHistory,
        effects: playerEffects,
      ),
      opponent: _combatant(
        id: 'opponent',
        speed: 1,
        move: _move(
          id: 'opponent_wait',
          power: 0,
          accuracy: 0,
          category: PsdkBattleMoveCategory.status,
          battleEngineMethod: 's_splash',
        ),
      ),
      rngSeeds: PsdkBattleRngSeeds(
        moveDamage: 1,
        moveCritical: 99999,
        moveAccuracy: moveAccuracySeed,
        generic: 4,
      ),
    ),
  );
  return engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
}

PsdkBattleEngine _engine({
  required List<PsdkBattleMoveData> playerMoves,
  PsdkBattleMoveData? opponentMove,
}) {
  return PsdkBattleEngine(
    setup: PsdkBattleSetup.singles(
      player: _combatant(
        id: 'player',
        speed: 100,
        move: playerMoves.first,
        extraMoves: playerMoves.skip(1).toList(growable: false),
      ),
      opponent: _combatant(
        id: 'opponent',
        speed: 1,
        move: opponentMove ??
            _move(
              id: 'opponent_wait',
              power: 0,
              accuracy: 0,
              category: PsdkBattleMoveCategory.status,
              battleEngineMethod: 's_splash',
            ),
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
  required PsdkBattleMoveData move,
  List<PsdkBattleMoveData> extraMoves = const <PsdkBattleMoveData>[],
  PsdkBattleMoveHistory? moveHistory,
  PsdkBattleEffectStack? effects,
  int currentHp = 100,
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
    moveHistory: moveHistory,
    effects: effects,
    moves: <PsdkBattleMoveData>[move, ...extraMoves],
  );
}

EchoedVoiceEffect _echoedVoiceEffectIn(PsdkBattleState state) {
  return state.combatants.values
      .expand((battler) => battler.effects.effects)
      .whereType<EchoedVoiceEffect>()
      .single;
}

bool _failed(PsdkBattleTurnResult result, {required String moveId}) {
  return result.timeline.events.whereType<PsdkBattleMoveFailedEvent>().any(
        (event) => event.moveId == moveId,
      );
}

PsdkBattleMoveData _echoedVoice({String id = 'echoed_voice'}) {
  return _move(
    id: id,
    category: PsdkBattleMoveCategory.special,
    power: 40,
    battleEngineMethod: 's_echo',
  );
}

PsdkBattleMoveData _move({
  required String id,
  String type = 'normal',
  PsdkBattleMoveCategory category = PsdkBattleMoveCategory.physical,
  required int power,
  int accuracy = 100,
  int pp = 35,
  int? currentPp,
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
    pp: pp,
    currentPp: currentPp,
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
      .toList();
}

int _resolutionDamage(
  BattleMoveBehaviorResolution result, {
  required String moveId,
}) {
  return result.events
      .whereType<PsdkBattleDamageEvent>()
      .where((event) => event.moveId == moveId)
      .single
      .damage;
}
