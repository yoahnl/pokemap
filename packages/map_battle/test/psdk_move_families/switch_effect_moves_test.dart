import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK switch-effect move families', () {
    test('s_baton_pass marks the user for a Baton Pass switch request', () {
      final engine = PsdkBattleEngine(
        setup: _setup(
          playerMoves: <PsdkBattleMoveData>[
            _move(
              id: 'baton_pass',
              battleEngineMethod: 's_baton_pass',
              target: PsdkBattleMoveTarget.user,
            ),
          ],
        ),
      );

      final result = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      final player = result.state.battlerAt(psdkPlayerSlot);

      expect(player.switching, isTrue);
      expect(player.effects.contains('baton_pass'), isTrue);
      expect(
        player.effects.effects.singleWhere(
          (effect) => effect.id == 'baton_pass',
        ),
        isA<BatonPassEffect>(),
      );
    });

    test('s_baton_pass fails when the user has no replacement', () {
      final engine = PsdkBattleEngine(
        setup: _setup(
          includePlayerReserve: false,
          playerMoves: <PsdkBattleMoveData>[
            _move(
              id: 'baton_pass',
              battleEngineMethod: 's_baton_pass',
              target: PsdkBattleMoveTarget.user,
            ),
          ],
        ),
      );

      final result = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      final player = result.state.battlerAt(psdkPlayerSlot);

      expect(player.switching, isFalse);
      expect(player.effects.contains('baton_pass'), isFalse);
      expect(
        result.timeline.events
            .whereType<PsdkBattleMoveFailedEvent>()
            .where((event) => event.moveId == 'baton_pass'),
        hasLength(1),
      );
    });

    test('s_shed_tail pays half HP and marks the user for switch', () {
      final engine = PsdkBattleEngine(
        setup: _setup(
          playerMoves: <PsdkBattleMoveData>[
            _move(
              id: 'shed_tail',
              battleEngineMethod: 's_shed_tail',
              target: PsdkBattleMoveTarget.user,
            ),
          ],
        ),
      );

      final result = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      final player = result.state.battlerAt(psdkPlayerSlot);

      expect(player.currentHp, 50);
      expect(player.switching, isTrue);
      expect(player.effects.contains('substitute'), isTrue);
      expect(player.effects.contains('shed_tail'), isTrue);
      expect(
        result.timeline.events.whereType<PsdkBattleDamageEvent>(),
        hasLength(1),
      );
    });

    test('s_shed_tail fails when the user has no replacement', () {
      final engine = PsdkBattleEngine(
        setup: _setup(
          includePlayerReserve: false,
          playerMoves: <PsdkBattleMoveData>[
            _move(
              id: 'shed_tail',
              battleEngineMethod: 's_shed_tail',
              target: PsdkBattleMoveTarget.user,
            ),
          ],
        ),
      );

      final result = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      final player = result.state.battlerAt(psdkPlayerSlot);

      expect(player.currentHp, 100);
      expect(player.switching, isFalse);
      expect(player.effects.contains('substitute'), isFalse);
      expect(player.effects.contains('shed_tail'), isFalse);
      expect(
        result.timeline.events
            .whereType<PsdkBattleMoveFailedEvent>()
            .where((event) => event.moveId == 'shed_tail'),
        hasLength(1),
      );
    });

    test('s_shed_tail transfers its substitute to the incoming battler', () {
      final engine = PsdkBattleEngine(
        setup: _setup(
          playerMoves: <PsdkBattleMoveData>[
            _move(
              id: 'shed_tail',
              battleEngineMethod: 's_shed_tail',
              target: PsdkBattleMoveTarget.user,
            ),
          ],
        ),
      );

      final turn = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      final switched = const BattleSwitchHandler().switchCombatant(
        context: BattleHandlerContext(
          state: turn.state,
          rng: BattleRngStreams.fromSeeds(
            moveDamageSeed: 1,
            moveCriticalSeed: 99999,
            moveAccuracySeed: 3,
            genericSeed: 4,
          ),
          turn: 1,
          user: psdkPlayerSlot,
        ),
        target: psdkPlayerSlot,
        partyIndex: 1,
      );
      final incoming = switched.state.battlerAt(psdkPlayerSlot);
      final outgoing = switched.state.partyForBank(0).first;
      final substitute =
          incoming.effects.effects.whereType<SubstituteEffect>().single;

      expect(incoming.speciesId, 'player-reserve');
      expect(incoming.effects.contains('substitute'), isTrue);
      expect(incoming.effects.contains('shed_tail'), isFalse);
      expect(substitute.remainingHp, 50);
      expect(outgoing.currentHp, 50);
      expect(outgoing.effects.contains('substitute'), isFalse);
    });

    test('s_u_turn damages the target then marks the user for switch', () {
      final engine = PsdkBattleEngine(
        setup: _setup(
          playerMoves: <PsdkBattleMoveData>[
            _move(
              id: 'u_turn',
              battleEngineMethod: 's_u_turn',
              target: PsdkBattleMoveTarget.adjacentFoe,
              category: PsdkBattleMoveCategory.physical,
              power: 70,
              accuracy: 100,
            ),
          ],
        ),
      );

      final result = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      final damage =
          result.timeline.events.whereType<PsdkBattleDamageEvent>().toList();

      expect(damage, hasLength(1));
      expect(damage.single.target, psdkOpponentSlot);
      expect(result.state.battlerAt(psdkOpponentSlot).currentHp, lessThan(100));
      expect(result.state.battlerAt(psdkPlayerSlot).switching, isTrue);
    });

    test('s_u_turn does not mark the user for switch when it misses', () {
      final engine = PsdkBattleEngine(
        setup: _setup(
          playerMoves: <PsdkBattleMoveData>[
            _move(
              id: 'u_turn',
              battleEngineMethod: 's_u_turn',
              target: PsdkBattleMoveTarget.adjacentFoe,
              category: PsdkBattleMoveCategory.physical,
              power: 70,
              accuracy: 1,
            ),
          ],
        ),
      );

      final result = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));

      expect(
        result.timeline.events.whereType<PsdkBattleDamageEvent>(),
        isEmpty,
      );
      expect(result.state.battlerAt(psdkPlayerSlot).switching, isFalse);
    });

    test('s_u_turn damages but does not switch without a replacement', () {
      final engine = PsdkBattleEngine(
        setup: _setup(
          includePlayerReserve: false,
          playerMoves: <PsdkBattleMoveData>[
            _move(
              id: 'u_turn',
              battleEngineMethod: 's_u_turn',
              target: PsdkBattleMoveTarget.adjacentFoe,
              category: PsdkBattleMoveCategory.physical,
              power: 70,
              accuracy: 100,
            ),
          ],
        ),
      );

      final result = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));

      expect(
        result.timeline.events.whereType<PsdkBattleDamageEvent>(),
        hasLength(1),
      );
      expect(result.state.battlerAt(psdkPlayerSlot).switching, isFalse);
    });

    test('s_u_turn damages but does not switch when the user is trapped', () {
      final engine = PsdkBattleEngine(
        setup: _setup(
          opponentAbilityId: 'shadow_tag',
          playerMoves: <PsdkBattleMoveData>[
            _move(
              id: 'u_turn',
              battleEngineMethod: 's_u_turn',
              target: PsdkBattleMoveTarget.adjacentFoe,
              category: PsdkBattleMoveCategory.physical,
              power: 70,
              accuracy: 100,
            ),
          ],
        ),
      );

      final result = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      final damage =
          result.timeline.events.whereType<PsdkBattleDamageEvent>().toList();

      expect(damage, hasLength(1));
      expect(result.state.battlerAt(psdkOpponentSlot).currentHp, lessThan(100));
      expect(result.state.battlerAt(psdkPlayerSlot).switching, isFalse);
    });

    test('s_volt_switch and s_flip_turn damage then mark the user for switch',
        () {
      for (final entry in const <({String method, String moveId})>[
        (method: 's_volt_switch', moveId: 'volt_switch'),
        (method: 's_flip_turn', moveId: 'flip_turn'),
      ]) {
        final engine = PsdkBattleEngine(
          setup: _setup(
            playerMoves: <PsdkBattleMoveData>[
              _move(
                id: entry.moveId,
                battleEngineMethod: entry.method,
                target: PsdkBattleMoveTarget.adjacentFoe,
                category: PsdkBattleMoveCategory.special,
                power: 70,
                accuracy: 100,
              ),
            ],
          ),
        );

        final result =
            engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
        final damage =
            result.timeline.events.whereType<PsdkBattleDamageEvent>().toList();

        expect(damage, hasLength(1), reason: entry.method);
        expect(damage.single.target, psdkOpponentSlot, reason: entry.method);
        expect(result.state.battlerAt(psdkPlayerSlot).switching, isTrue,
            reason: entry.method);
      }
    });

    test('s_volt_switch and s_flip_turn do not switch when they miss', () {
      for (final entry in const <({String method, String moveId})>[
        (method: 's_volt_switch', moveId: 'volt_switch'),
        (method: 's_flip_turn', moveId: 'flip_turn'),
      ]) {
        final engine = PsdkBattleEngine(
          setup: _setup(
            playerMoves: <PsdkBattleMoveData>[
              _move(
                id: entry.moveId,
                battleEngineMethod: entry.method,
                target: PsdkBattleMoveTarget.adjacentFoe,
                category: PsdkBattleMoveCategory.special,
                power: 70,
                accuracy: 1,
              ),
            ],
          ),
        );

        final result =
            engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));

        expect(
            result.timeline.events.whereType<PsdkBattleDamageEvent>(), isEmpty,
            reason: entry.method);
        expect(result.state.battlerAt(psdkPlayerSlot).switching, isFalse,
            reason: entry.method);
      }
    });

    test('s_chilly_reception applies hail and marks the user for switch', () {
      final engine = PsdkBattleEngine(
        setup: _setup(
          playerHeldItemId: 'icy_rock',
          playerMoves: <PsdkBattleMoveData>[
            _move(
              id: 'chilly_reception',
              battleEngineMethod: 's_chilly_reception',
              target: PsdkBattleMoveTarget.none,
            ),
          ],
        ),
      );

      final result = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));

      expect(result.state.field.weather?.id, PsdkBattleWeatherId.hail);
      expect(result.state.field.weather?.remainingTurns, 7);
      expect(
        result.timeline.events.whereType<PsdkBattleWeatherChangedEvent>().single
            .remainingTurns,
        8,
      );
      expect(result.state.battlerAt(psdkPlayerSlot).switching, isTrue);
    });

    test(
        's_chilly_reception still applies hail when no replacement is available',
        () {
      final engine = PsdkBattleEngine(
        setup: _setup(
          includePlayerReserve: false,
          playerMoves: <PsdkBattleMoveData>[
            _move(
              id: 'chilly_reception',
              battleEngineMethod: 's_chilly_reception',
              target: PsdkBattleMoveTarget.none,
            ),
          ],
        ),
      );

      final result = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));

      expect(result.state.field.weather?.id, PsdkBattleWeatherId.hail);
      expect(result.state.field.weather?.remainingTurns, 4);
      expect(result.state.battlerAt(psdkPlayerSlot).switching, isFalse);
      expect(
        result.timeline.events.whereType<PsdkBattleWeatherChangedEvent>(),
        hasLength(1),
      );
    });

    test('s_teleport marks the user for switch in trainer-style battles', () {
      final engine = PsdkBattleEngine(
        setup: _setup(
          playerMoves: <PsdkBattleMoveData>[
            _move(
              id: 'teleport',
              battleEngineMethod: 's_teleport',
              target: PsdkBattleMoveTarget.none,
            ),
          ],
        ),
      );

      final result = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));

      expect(result.state.battlerAt(psdkPlayerSlot).switching, isTrue);
      expect(result.outcome, isNull);
      expect(
        result.timeline.events.whereType<PsdkBattleMoveFailedEvent>(),
        isEmpty,
      );
    });

    test('s_teleport fails in trainer-style battles without replacement', () {
      final engine = PsdkBattleEngine(
        setup: _setup(
          includePlayerReserve: false,
          playerMoves: <PsdkBattleMoveData>[
            _move(
              id: 'teleport',
              battleEngineMethod: 's_teleport',
              target: PsdkBattleMoveTarget.none,
            ),
          ],
        ),
      );

      final result = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));

      expect(result.state.battlerAt(psdkPlayerSlot).switching, isFalse);
      expect(
        result.timeline.events
            .whereType<PsdkBattleMoveFailedEvent>()
            .where((event) => event.moveId == 'teleport')
            .single
            .reason,
        'no_replacement',
      );
    });

    test('s_teleport fails in trainer-style battles when the user is trapped',
        () {
      final engine = PsdkBattleEngine(
        setup: _setup(
          opponentAbilityId: 'shadow_tag',
          playerMoves: <PsdkBattleMoveData>[
            _move(
              id: 'teleport',
              battleEngineMethod: 's_teleport',
              target: PsdkBattleMoveTarget.none,
            ),
          ],
        ),
      );

      final result = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));

      expect(result.state.battlerAt(psdkPlayerSlot).switching, isFalse);
      expect(
        result.timeline.events
            .whereType<PsdkBattleMoveFailedEvent>()
            .where((event) => event.moveId == 'teleport'),
        hasLength(1),
      );
    });

    test('s_teleport ends flee-enabled battles with a fled outcome', () {
      final engine = PsdkBattleEngine(
        setup: _setup(
          canFlee: true,
          includePlayerReserve: false,
          playerMoves: <PsdkBattleMoveData>[
            _move(
              id: 'teleport',
              battleEngineMethod: 's_teleport',
              target: PsdkBattleMoveTarget.none,
            ),
          ],
        ),
      );

      final result = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));

      expect(result.outcome?.kind, PsdkBattleOutcomeKind.fled);
      expect(result.state.outcome?.kind, PsdkBattleOutcomeKind.fled);
      expect(result.state.battlerAt(psdkPlayerSlot).switching, isFalse);
      expect(
        result.timeline.events.whereType<PsdkBattleEndedEvent>().single.outcome,
        const PsdkBattleOutcome(kind: PsdkBattleOutcomeKind.fled),
      );
    });

    test('s_parting_shot marks the user for switch after offensive drops', () {
      final engine = PsdkBattleEngine(
        setup: _setup(
          playerMoves: <PsdkBattleMoveData>[
            _move(
              id: 'parting_shot',
              battleEngineMethod: 's_parting_shot',
              target: PsdkBattleMoveTarget.adjacentFoe,
              stageMods: const <PsdkBattleMoveStageMod>[
                PsdkBattleMoveStageMod(
                  stat: 'attack',
                  stages: -1,
                  chance: 100,
                ),
                PsdkBattleMoveStageMod(
                  stat: 'specialAttack',
                  stages: -1,
                  chance: 100,
                ),
              ],
            ),
          ],
        ),
      );

      final result = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      final opponent = result.state.battlerAt(psdkOpponentSlot);

      expect(opponent.statStages.valueOf('attack'), -1);
      expect(opponent.statStages.valueOf('specialAttack'), -1);
      expect(result.state.battlerAt(psdkPlayerSlot).switching, isTrue);
    });

    test('s_parting_shot does not mark the user when drops cannot apply', () {
      final engine = PsdkBattleEngine(
        setup: _setup(
          opponentStatStages: PsdkBattleStatStages(
            values: const <String, int>{
              'attack': -6,
              'specialAttack': -6,
            },
          ),
          playerMoves: <PsdkBattleMoveData>[
            _move(
              id: 'parting_shot',
              battleEngineMethod: 's_parting_shot',
              target: PsdkBattleMoveTarget.adjacentFoe,
              stageMods: const <PsdkBattleMoveStageMod>[
                PsdkBattleMoveStageMod(
                  stat: 'attack',
                  stages: -1,
                  chance: 100,
                ),
                PsdkBattleMoveStageMod(
                  stat: 'specialAttack',
                  stages: -1,
                  chance: 100,
                ),
              ],
            ),
          ],
        ),
      );

      final result = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      final opponent = result.state.battlerAt(psdkOpponentSlot);

      expect(opponent.statStages.valueOf('attack'), -6);
      expect(opponent.statStages.valueOf('specialAttack'), -6);
      expect(result.state.battlerAt(psdkPlayerSlot).switching, isFalse);
    });

    test('s_parting_shot drops stats but does not switch when user is trapped',
        () {
      final engine = PsdkBattleEngine(
        setup: _setup(
          opponentAbilityId: 'shadow_tag',
          playerMoves: <PsdkBattleMoveData>[
            _move(
              id: 'parting_shot',
              battleEngineMethod: 's_parting_shot',
              target: PsdkBattleMoveTarget.adjacentFoe,
              stageMods: const <PsdkBattleMoveStageMod>[
                PsdkBattleMoveStageMod(
                  stat: 'attack',
                  stages: -1,
                  chance: 100,
                ),
                PsdkBattleMoveStageMod(
                  stat: 'specialAttack',
                  stages: -1,
                  chance: 100,
                ),
              ],
            ),
          ],
        ),
      );

      final result = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      final opponent = result.state.battlerAt(psdkOpponentSlot);

      expect(opponent.statStages.valueOf('attack'), -1);
      expect(opponent.statStages.valueOf('specialAttack'), -1);
      expect(result.state.battlerAt(psdkPlayerSlot).switching, isFalse);
    });

    test('s_roar does not force switch when the target is trapped', () {
      final engine = PsdkBattleEngine(
        setup: _setup(
          playerAbilityId: 'shadow_tag',
          playerMoves: <PsdkBattleMoveData>[
            _move(
              id: 'roar',
              battleEngineMethod: 's_roar',
              target: PsdkBattleMoveTarget.adjacentFoe,
            ),
          ],
        ),
      );

      final result = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));

      expect(result.state.battlerAt(psdkOpponentSlot).switching, isFalse);
    });
  });
}

PsdkBattleSetup _setup({
  required List<PsdkBattleMoveData> playerMoves,
  PsdkBattleStatStages? opponentStatStages,
  String? playerAbilityId,
  String? opponentAbilityId,
  String? playerHeldItemId,
  bool canFlee = false,
  bool includePlayerReserve = true,
  bool includeOpponentReserve = true,
}) {
  return PsdkBattleSetup.singles(
    player: _combatant(
      id: 'player',
      speed: 100,
      moves: playerMoves,
      abilityId: playerAbilityId,
      heldItemId: playerHeldItemId,
    ),
    opponent: _combatant(
      id: 'opponent',
      speed: 1,
      abilityId: opponentAbilityId,
      statStages: opponentStatStages,
      moves: <PsdkBattleMoveData>[
        _move(
          id: 'splash',
          battleEngineMethod: 's_splash',
          target: PsdkBattleMoveTarget.none,
        ),
      ],
    ),
    playerReserves: includePlayerReserve
        ? <PsdkBattleCombatantSetup>[
            _combatant(
              id: 'player-reserve',
              speed: 50,
              moves: <PsdkBattleMoveData>[
                _move(
                  id: 'splash',
                  battleEngineMethod: 's_splash',
                  target: PsdkBattleMoveTarget.none,
                ),
              ],
            ),
          ]
        : const <PsdkBattleCombatantSetup>[],
    opponentReserves: includeOpponentReserve
        ? <PsdkBattleCombatantSetup>[
            _combatant(
              id: 'opponent-reserve',
              speed: 50,
              moves: <PsdkBattleMoveData>[
                _move(
                  id: 'splash',
                  battleEngineMethod: 's_splash',
                  target: PsdkBattleMoveTarget.none,
                ),
              ],
            ),
          ]
        : const <PsdkBattleCombatantSetup>[],
    rngSeeds: const PsdkBattleRngSeeds(
      moveDamage: 1,
      moveCritical: 99999,
      moveAccuracy: 3,
      generic: 4,
    ),
    canFlee: canFlee,
  );
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  required int speed,
  required List<PsdkBattleMoveData> moves,
  PsdkBattleStatStages? statStages,
  String? abilityId,
  String? heldItemId,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 20,
    maxHp: 100,
    currentHp: 100,
    types: const PsdkBattleTypes(primary: 'normal'),
    stats: PsdkBattleStats(
      attack: 50,
      defense: 50,
      specialAttack: 50,
      specialDefense: 50,
      speed: speed,
    ),
    statStages: statStages ?? PsdkBattleStatStages.neutral(),
    abilityId: abilityId,
    heldItemId: heldItemId,
    moves: moves,
  );
}

PsdkBattleMoveData _move({
  required String id,
  required String battleEngineMethod,
  required PsdkBattleMoveTarget target,
  PsdkBattleMoveCategory category = PsdkBattleMoveCategory.status,
  int power = 0,
  int accuracy = 0,
  List<PsdkBattleMoveStageMod> stageMods = const <PsdkBattleMoveStageMod>[],
}) {
  return PsdkBattleMoveData(
    id: id,
    dbSymbol: id,
    name: id,
    type: 'normal',
    category: category,
    power: power,
    accuracy: accuracy,
    pp: 35,
    priority: 0,
    criticalRate: 1,
    battleEngineMethod: battleEngineMethod,
    target: target,
    stageMods: stageMods,
  );
}
