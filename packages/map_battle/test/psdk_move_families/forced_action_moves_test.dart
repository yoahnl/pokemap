import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK forced-action move families', () {
    test('s_gigaton_hammer fails when it was the user previous move', () {
      final allowed = _runMove(
        playerMove: _move(
          id: 'gigaton_hammer',
          type: 'steel',
          power: 160,
          battleEngineMethod: 's_gigaton_hammer',
        ),
        playerMoveHistory: PsdkBattleMoveHistory(
          successes: <PsdkBattleMoveHistoryEntry>[
            PsdkBattleMoveHistoryEntry(
              moveId: 'tackle',
              turn: 1,
              targets: const <PsdkBattleSlotRef>[psdkOpponentSlot],
            ),
          ],
        ),
      );
      final blocked = _runMove(
        playerMove: _move(
          id: 'gigaton_hammer',
          type: 'steel',
          power: 160,
          battleEngineMethod: 's_gigaton_hammer',
        ),
        playerMoveHistory: PsdkBattleMoveHistory(
          successes: <PsdkBattleMoveHistoryEntry>[
            PsdkBattleMoveHistoryEntry(
              moveId: 'gigaton_hammer',
              turn: 1,
              targets: const <PsdkBattleSlotRef>[psdkOpponentSlot],
            ),
          ],
        ),
      );

      expect(_damage(allowed, moveId: 'gigaton_hammer'), greaterThan(0));
      expect(_failed(blocked, moveId: 'gigaton_hammer'), isTrue);
      expect(_damageEvents(blocked, moveId: 'gigaton_hammer'), isEmpty);
    });

    test('s_thrash locks the user into the same move after a hit', () {
      final result = _runMove(
        playerMove: _move(
          id: 'thrash',
          power: 120,
          battleEngineMethod: 's_thrash',
        ),
      );

      final player = result.state.battlerAt(psdkPlayerSlot);
      expect(_damage(result, moveId: 'thrash'), greaterThan(0));
      expect(player.effects.contains('force_next_move_base'), isTrue);
    });

    test('s_thrash blocks selecting another move while locked', () {
      final engine = _engine(
        playerMoves: <PsdkBattleMoveData>[
          _move(id: 'thrash', power: 120, battleEngineMethod: 's_thrash'),
          _move(id: 'tackle', power: 40),
        ],
      );

      final first = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      final second = engine.submit(const PsdkBattleDecision.fight(moveSlot: 1));

      expect(_damage(first, moveId: 'thrash'), greaterThan(0));
      expect(_failed(second, moveId: 'tackle'), isTrue);
      expect(_damageEvents(second, moveId: 'tackle'), isEmpty);
    });

    test('s_thrash releases the lock and confuses the user at the end', () {
      final engine = _engine(
        genericSeed: 4,
        playerMoves: <PsdkBattleMoveData>[
          _move(id: 'thrash', power: 120, battleEngineMethod: 's_thrash'),
        ],
      );

      engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      final second = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));

      final player = second.state.battlerAt(psdkPlayerSlot);
      expect(_damage(second, moveId: 'thrash'), greaterThan(0));
      expect(player.effects.contains('force_next_move_base'), isFalse);
      expect(player.effects.contains('confusion'), isTrue);
    });

    test('s_thrash respects Own Tempo when the lock ends', () {
      final engine = _engine(
        genericSeed: 4,
        playerAbilityId: 'own_tempo',
        playerMoves: <PsdkBattleMoveData>[
          _move(id: 'thrash', power: 120, battleEngineMethod: 's_thrash'),
        ],
      );

      engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      final second = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));

      final player = second.state.battlerAt(psdkPlayerSlot);
      expect(_damage(second, moveId: 'thrash'), greaterThan(0));
      expect(player.effects.contains('force_next_move_base'), isFalse);
      expect(player.effects.contains('confusion'), isFalse);
    });

    test('s_outrage uses the same repeated-action lock as Thrash', () {
      final result = _runMove(
        playerMove: _move(
          id: 'outrage',
          type: 'dragon',
          power: 120,
          battleEngineMethod: 's_outrage',
        ),
      );

      final player = result.state.battlerAt(psdkPlayerSlot);
      expect(_damage(result, moveId: 'outrage'), greaterThan(0));
      expect(player.effects.contains('force_next_move_base'), isTrue);
    });

    test('s_uproar installs an uproar marker after a successful hit', () {
      final result = _runMove(
        playerMove: _move(
          id: 'uproar',
          type: 'normal',
          category: PsdkBattleMoveCategory.special,
          power: 90,
          battleEngineMethod: 's_uproar',
        ),
      );

      final player = result.state.battlerAt(psdkPlayerSlot);
      expect(_damage(result, moveId: 'uproar'), greaterThan(0));
      expect(player.effects.contains('uproar'), isTrue);
    });

    test('s_uproar wakes sleeping battlers when the effect starts', () {
      final result = _runMove(
        playerMove: _move(
          id: 'uproar',
          type: 'normal',
          category: PsdkBattleMoveCategory.special,
          power: 90,
          battleEngineMethod: 's_uproar',
        ),
        opponentMajorStatus: PsdkBattleMajorStatus.sleep,
        opponentSleepTurns: 1,
      );

      expect(_damage(result, moveId: 'uproar'), greaterThan(0));
      expect(result.state.battlerAt(psdkOpponentSlot).majorStatus, isNull);
      expect(
        result.timeline.events
            .whereType<PsdkBattleStatusCureEvent>()
            .where((event) => event.moveId == 'uproar'),
        hasLength(1),
      );
    });

    test('active Uproar prevents sleep from being applied', () {
      final state = PsdkBattleState(
        combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
          psdkPlayerSlot: PsdkBattleCombatant.fromSetup(
            _combatant(
              id: 'player',
              speed: 100,
              effects: PsdkBattleEffectStack(
                values: const <String>['uproar'],
              ),
              moves: <PsdkBattleMoveData>[
                _move(id: 'uproar', power: 90),
              ],
            ),
          ),
          psdkOpponentSlot: PsdkBattleCombatant.fromSetup(
            _combatant(
              id: 'opponent',
              speed: 1,
              moves: <PsdkBattleMoveData>[
                _move(id: 'opponent_wait', power: 0),
              ],
            ),
          ),
        },
      );

      final result = const BattleStatusChangeHandler().applyMajorStatus(
        context: BattleHandlerContext(
          state: state,
          rng: BattleRngStreams.fromSeeds(
            moveDamageSeed: 1,
            moveCriticalSeed: 2,
            moveAccuracySeed: 3,
            genericSeed: 7,
          ),
          turn: 1,
          user: psdkPlayerSlot,
        ),
        target: psdkOpponentSlot,
        moveId: 'spore',
        status: PsdkBattleMajorStatus.sleep,
      );

      expect(result.applied, isFalse);
      expect(result.reason, 'uproar_prevents_sleep');
      expect(result.state.battlerAt(psdkOpponentSlot).majorStatus, isNull);
    });

    test('s_reload spends the recharge turn without duplicating history', () {
      final engine = _engine(
        playerMoves: <PsdkBattleMoveData>[
          _move(
            id: 'hyper_beam',
            category: PsdkBattleMoveCategory.special,
            power: 150,
            battleEngineMethod: 's_reload',
          ),
        ],
      );

      final first = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      final second = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      final player = second.state.battlerAt(psdkPlayerSlot);

      expect(_damage(first, moveId: 'hyper_beam'), greaterThan(0));
      expect(_failed(second, moveId: 'hyper_beam'), isTrue);
      expect(player.effects.contains(PsdkBattleEffectIds.forceNextMoveBase),
          isFalse);
      expect(player.moveHistory.usedMoveIds, <String>['hyper_beam']);
      expect(player.moveHistory.successfulMoveIds, <String>['hyper_beam']);
    });

    test('s_reload does not require recharge when the attack misses', () {
      final result = _runMove(
        playerMove: _move(
          id: 'hyper_beam',
          category: PsdkBattleMoveCategory.special,
          power: 150,
          accuracy: 1,
          battleEngineMethod: 's_reload',
        ),
      );

      expect(_damageEvents(result, moveId: 'hyper_beam'), isEmpty);
      expect(
        result.state
            .battlerAt(psdkPlayerSlot)
            .effects
            .contains(PsdkBattleEffectIds.forceNextMoveBase),
        isFalse,
      );
      expect(result.state.battlerAt(psdkPlayerSlot).moveHistory.successes,
          isEmpty);
    });

    test('s_2turns forces the charged move on the next action', () {
      final engine = _engine(
        playerMoves: <PsdkBattleMoveData>[
          _move(
            id: 'fly',
            type: 'flying',
            power: 90,
            battleEngineMethod: 's_2turns',
          ),
          _move(id: 'tackle', power: 40),
        ],
      );

      final charge = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      final strike = engine.submit(const PsdkBattleDecision.fight(moveSlot: 1));

      expect(_damageEvents(charge, moveId: 'fly'), isEmpty);
      expect(
        charge.state
            .battlerAt(psdkPlayerSlot)
            .effects
            .contains(PsdkBattleEffectIds.twoTurnCharge),
        isTrue,
      );
      expect(_damageEvents(strike, moveId: 'tackle'), isEmpty);
      expect(_damage(strike, moveId: 'fly'), greaterThan(0));
      expect(
        strike.state
            .battlerAt(psdkPlayerSlot)
            .effects
            .contains(PsdkBattleEffectIds.twoTurnCharge),
        isFalse,
      );
    });

    test('Power Herb consumes itself and skips the s_2turns charge turn', () {
      final engine = _engine(
        playerHeldItemId: 'power_herb',
        playerMoves: <PsdkBattleMoveData>[
          _move(
            id: 'fly',
            type: 'flying',
            power: 90,
            battleEngineMethod: 's_2turns',
          ),
        ],
      );

      final result = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      final player = result.state.battlerAt(psdkPlayerSlot);

      expect(_damage(result, moveId: 'fly'), greaterThan(0));
      expect(player.heldItemId, isNull);
      expect(player.consumedItemId, 'power_herb');
      expect(
          player.effects.contains(PsdkBattleEffectIds.twoTurnCharge), isFalse);
      expect(
        result.timeline.events.whereType<PsdkBattleItemEvent>().single.itemId,
        'power_herb',
      );
    });

    test('s_2turns applies release-turn status riders after damage', () {
      final engine = _engine(
        playerMoves: <PsdkBattleMoveData>[
          _move(
            id: 'freeze_shock',
            type: 'ice',
            power: 140,
            accuracy: 90,
            battleEngineMethod: 's_2turns',
            effectChance: 100,
            statuses: <PsdkBattleMoveStatus>[
              PsdkBattleMoveStatus(
                status: PsdkBattleMajorStatus.paralysis,
                chance: 100,
              ),
            ],
          ),
        ],
      );

      final charge = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      final strike = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));

      expect(_damageEvents(charge, moveId: 'freeze_shock'), isEmpty);
      expect(
          charge.timeline.events.whereType<PsdkBattleStatusEvent>(), isEmpty);
      expect(_damage(strike, moveId: 'freeze_shock'), greaterThan(0));
      expect(
        strike.state.battlerAt(psdkOpponentSlot).majorStatus,
        PsdkBattleMajorStatus.paralysis,
      );
    });

    test('s_2turns applies Skull Bash defense boost before charging', () {
      final engine = _engine(
        playerMoves: <PsdkBattleMoveData>[
          _move(
            id: 'skull_bash',
            power: 130,
            battleEngineMethod: 's_2turns',
          ),
        ],
      );

      final charge = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      final player = charge.state.battlerAt(psdkPlayerSlot);

      expect(_damageEvents(charge, moveId: 'skull_bash'), isEmpty);
      expect(player.statStages.valueOf('defense'), 1);
      expect(
          player.effects.contains(PsdkBattleEffectIds.twoTurnCharge), isTrue);
      expect(
        charge.timeline.events
            .whereType<PsdkBattleStatStageEvent>()
            .single
            .stat,
        'defense',
      );
    });

    test('Power Herb keeps Skull Bash boost while skipping charge', () {
      final engine = _engine(
        playerHeldItemId: 'power_herb',
        playerMoves: <PsdkBattleMoveData>[
          _move(
            id: 'skull_bash',
            power: 130,
            battleEngineMethod: 's_2turns',
          ),
        ],
      );

      final result = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      final player = result.state.battlerAt(psdkPlayerSlot);

      expect(_damage(result, moveId: 'skull_bash'), greaterThan(0));
      expect(player.statStages.valueOf('defense'), 1);
      expect(player.heldItemId, isNull);
      expect(player.consumedItemId, 'power_herb');
    });

    test('s_2turns applies Geomancy boosts on release', () {
      final engine = _engine(
        playerMoves: <PsdkBattleMoveData>[
          _move(
            id: 'geomancy',
            type: 'fairy',
            category: PsdkBattleMoveCategory.status,
            power: 0,
            accuracy: 0,
            battleEngineMethod: 's_2turns',
            target: PsdkBattleMoveTarget.user,
            stageMods: const <PsdkBattleMoveStageMod>[
              PsdkBattleMoveStageMod(stat: 'specialAttack', stages: 2),
              PsdkBattleMoveStageMod(stat: 'specialDefense', stages: 2),
              PsdkBattleMoveStageMod(stat: 'speed', stages: 2),
            ],
          ),
        ],
      );

      final charge = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      final strike = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      final chargedPlayer = charge.state.battlerAt(psdkPlayerSlot);
      final player = strike.state.battlerAt(psdkPlayerSlot);

      expect(chargedPlayer.statStages.valueOf('specialAttack'), 0);
      expect(chargedPlayer.effects.contains(PsdkBattleEffectIds.twoTurnCharge),
          isTrue);
      expect(player.statStages.valueOf('specialAttack'), 2);
      expect(player.statStages.valueOf('specialDefense'), 2);
      expect(player.statStages.valueOf('speed'), 2);
      expect(
          player.effects.contains(PsdkBattleEffectIds.twoTurnCharge), isFalse);
    });

    test('s_2turns release can damage every adjacent foe target', () {
      final result = const PsdkBattleMoveExecutor().execute(
        PsdkBattleMoveRequest(
          state: PsdkBattleState(
            combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
              psdkPlayerSlot: PsdkBattleCombatant.fromSetup(
                _combatant(
                  id: 'player',
                  speed: 100,
                  moves: <PsdkBattleMoveData>[
                    _move(
                      id: 'razor_wind',
                      type: 'normal',
                      category: PsdkBattleMoveCategory.special,
                      power: 80,
                      battleEngineMethod: 's_2turns',
                      target: PsdkBattleMoveTarget.allAdjacentFoes,
                    ),
                  ],
                  effects: PsdkBattleEffectStack(
                    effects: const <BattleEffect>[
                      TwoTurnChargeEffect(
                        scope: BattlerBattleEffectScope(psdkPlayerSlot),
                        chargedMoveId: 'razor_wind',
                        chargedTarget: psdkOpponentSlot,
                      ),
                    ],
                  ),
                ),
              ),
              psdkOpponentSlot: PsdkBattleCombatant.fromSetup(
                _combatant(
                  id: 'opponent',
                  speed: 1,
                  moves: <PsdkBattleMoveData>[
                    _move(id: 'opponent_wait', power: 0),
                  ],
                ),
              ),
              _opponentRightSlot: PsdkBattleCombatant.fromSetup(
                _combatant(
                  id: 'opponent_ally',
                  speed: 1,
                  moves: <PsdkBattleMoveData>[
                    _move(id: 'opponent_ally_wait', power: 0),
                  ],
                ),
              ),
            },
          ),
          rng: BattleRngStreams.fromSeeds(
            moveDamageSeed: 1,
            moveCriticalSeed: 99999,
            moveAccuracySeed: 3,
            genericSeed: 4,
          ),
          turn: 2,
          user: psdkPlayerSlot,
          target: psdkOpponentSlot,
          moveId: 'razor_wind',
          battleEngineMethod: 's_2turns',
          studioMove: _move(
            id: 'razor_wind',
            type: 'normal',
            category: PsdkBattleMoveCategory.special,
            power: 80,
            battleEngineMethod: 's_2turns',
            target: PsdkBattleMoveTarget.allAdjacentFoes,
          ),
        ),
      );

      expect(
        result.events
            .whereType<PsdkBattleDamageEvent>()
            .map((event) => event.target),
        <PsdkBattleSlotRef>[psdkOpponentSlot, _opponentRightSlot],
      );
    });

    test('Power Herb does not shortcut Sky Drop', () {
      final engine = _engine(
        playerHeldItemId: 'power_herb',
        playerMoves: <PsdkBattleMoveData>[
          _move(
            id: 'sky_drop',
            type: 'flying',
            power: 60,
            battleEngineMethod: 's_2turns',
          ),
        ],
      );

      final result = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      final player = result.state.battlerAt(psdkPlayerSlot);

      expect(_damageEvents(result, moveId: 'sky_drop'), isEmpty);
      expect(player.heldItemId, 'power_herb');
      expect(
          player.effects.contains(PsdkBattleEffectIds.twoTurnCharge), isTrue);
    });

    test('s_sky_drop prevents the carried target same-turn action', () {
      final engine = PsdkBattleEngine(
        setup: PsdkBattleSetup.singles(
          player: _combatant(
            id: 'player',
            speed: 100,
            moves: <PsdkBattleMoveData>[
              _move(
                id: 'sky_drop',
                type: 'flying',
                power: 60,
                battleEngineMethod: 's_sky_drop',
              ),
            ],
          ),
          opponent: _combatant(
            id: 'opponent',
            speed: 1,
            moves: <PsdkBattleMoveData>[
              _move(id: 'tackle', power: 40),
            ],
          ),
          rngSeeds: const PsdkBattleRngSeeds(
            moveDamage: 1,
            moveCritical: 99999,
            moveAccuracy: 3,
            generic: 4,
          ),
        ),
      );

      final result = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));

      expect(_damageEvents(result, moveId: 'sky_drop'), isEmpty);
      expect(_damageEvents(result, moveId: 'tackle'), isEmpty);
      expect(_failed(result, moveId: 'tackle'), isTrue);
      expect(
        result.state
            .battlerAt(psdkOpponentSlot)
            .effects
            .contains(PsdkBattleEffectIds.preventTargetsMove),
        isTrue,
      );
    });

    test('s_sky_drop keeps a faster carried target from acting before release',
        () {
      final engine = PsdkBattleEngine(
        setup: PsdkBattleSetup.singles(
          player: _combatant(
            id: 'player',
            speed: 1,
            moves: <PsdkBattleMoveData>[
              _move(
                id: 'sky_drop',
                type: 'flying',
                power: 60,
                battleEngineMethod: 's_sky_drop',
              ),
            ],
          ),
          opponent: _combatant(
            id: 'opponent',
            speed: 100,
            moves: <PsdkBattleMoveData>[
              _move(id: 'tackle', power: 40),
            ],
          ),
          rngSeeds: const PsdkBattleRngSeeds(
            moveDamage: 1,
            moveCritical: 99999,
            moveAccuracy: 3,
            generic: 4,
          ),
        ),
      );

      final charge = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      final release =
          engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));

      expect(_damageEvents(charge, moveId: 'tackle'), hasLength(1));
      expect(_damageEvents(charge, moveId: 'sky_drop'), isEmpty);
      expect(_damageEvents(release, moveId: 'tackle'), isEmpty);
      expect(_failed(release, moveId: 'tackle'), isTrue);
      expect(_damageEvents(release, moveId: 'sky_drop'), hasLength(1));
    });

    test('s_2turns preserves the charge when sleep stops release', () {
      final engine = _engine(
        playerMajorStatus: PsdkBattleMajorStatus.sleep,
        playerSleepTurns: 0,
        playerEffects: PsdkBattleEffectStack(
          effects: const <BattleEffect>[
            TwoTurnChargeEffect(
              scope: BattlerBattleEffectScope(psdkPlayerSlot),
              chargedMoveId: 'fly',
              chargedTarget: psdkOpponentSlot,
            ),
          ],
        ),
        playerMoves: <PsdkBattleMoveData>[
          _move(
            id: 'fly',
            type: 'flying',
            power: 90,
            battleEngineMethod: 's_2turns',
          ),
          _move(id: 'tackle', power: 40),
        ],
      );

      final blocked =
          engine.submit(const PsdkBattleDecision.fight(moveSlot: 1));
      final player = blocked.state.battlerAt(psdkPlayerSlot);

      expect(_failed(blocked, moveId: 'fly'), isTrue);
      expect(_damageEvents(blocked, moveId: 'fly'), isEmpty);
      expect(_damageEvents(blocked, moveId: 'tackle'), isEmpty);
      expect(player.sleepTurns, 1);
      expect(
          player.effects.contains(PsdkBattleEffectIds.twoTurnCharge), isTrue);
    });
  });
}

PsdkBattleTurnResult _runMove({
  required PsdkBattleMoveData playerMove,
  PsdkBattleMoveHistory? playerMoveHistory,
  String? playerAbilityId,
  PsdkBattleMajorStatus? opponentMajorStatus,
  int opponentSleepTurns = 0,
}) {
  return _engine(
    playerMoves: <PsdkBattleMoveData>[playerMove],
    playerMoveHistory: playerMoveHistory,
    playerAbilityId: playerAbilityId,
    opponentMajorStatus: opponentMajorStatus,
    opponentSleepTurns: opponentSleepTurns,
  ).submit(const PsdkBattleDecision.fight(moveSlot: 0));
}

PsdkBattleEngine _engine({
  required List<PsdkBattleMoveData> playerMoves,
  PsdkBattleMoveHistory? playerMoveHistory,
  String? playerAbilityId,
  PsdkBattleMajorStatus? playerMajorStatus,
  PsdkBattleMajorStatus? opponentMajorStatus,
  int playerSleepTurns = 0,
  int opponentSleepTurns = 0,
  PsdkBattleEffectStack? playerEffects,
  String? playerHeldItemId,
  int genericSeed = 4,
}) {
  return PsdkBattleEngine(
    setup: PsdkBattleSetup.singles(
      player: _combatant(
        id: 'player',
        speed: 100,
        abilityId: playerAbilityId,
        moveHistory: playerMoveHistory,
        majorStatus: playerMajorStatus,
        sleepTurns: playerSleepTurns,
        effects: playerEffects,
        heldItemId: playerHeldItemId,
        moves: playerMoves,
      ),
      opponent: _combatant(
        id: 'opponent',
        speed: 1,
        majorStatus: opponentMajorStatus,
        sleepTurns: opponentSleepTurns,
        moves: <PsdkBattleMoveData>[
          _move(
            id: 'opponent_wait',
            category: PsdkBattleMoveCategory.status,
            power: 0,
            accuracy: 0,
            battleEngineMethod: 's_splash',
          ),
        ],
      ),
      rngSeeds: PsdkBattleRngSeeds(
        moveDamage: 1,
        moveCritical: 99999,
        moveAccuracy: 3,
        generic: genericSeed,
      ),
    ),
  );
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  required int speed,
  required List<PsdkBattleMoveData> moves,
  String? abilityId,
  PsdkBattleMoveHistory? moveHistory,
  PsdkBattleMajorStatus? majorStatus,
  int sleepTurns = 0,
  PsdkBattleEffectStack? effects,
  String? heldItemId,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 20,
    maxHp: 100,
    currentHp: 100,
    abilityId: abilityId,
    heldItemId: heldItemId,
    types: const PsdkBattleTypes(primary: 'normal'),
    stats: PsdkBattleStats(
      attack: 50,
      defense: 50,
      specialAttack: 50,
      specialDefense: 50,
      speed: speed,
    ),
    moves: moves,
    moveHistory: moveHistory,
    majorStatus: majorStatus,
    sleepTurns: sleepTurns,
    effects: effects,
  );
}

PsdkBattleMoveData _move({
  required String id,
  String type = 'normal',
  PsdkBattleMoveCategory category = PsdkBattleMoveCategory.physical,
  required int power,
  int accuracy = 100,
  String battleEngineMethod = 's_basic',
  PsdkBattleMoveTarget target = PsdkBattleMoveTarget.adjacentFoe,
  int? effectChance,
  List<PsdkBattleMoveStatus> statuses = const <PsdkBattleMoveStatus>[],
  List<PsdkBattleMoveStageMod> stageMods = const <PsdkBattleMoveStageMod>[],
}) {
  return PsdkBattleMoveData(
    id: id,
    dbSymbol: id,
    name: id,
    type: type,
    category: category,
    power: power,
    accuracy: accuracy,
    pp: 35,
    priority: 0,
    criticalRate: 1,
    battleEngineMethod: battleEngineMethod,
    target: target,
    effectChance: effectChance,
    statuses: statuses,
    stageMods: stageMods,
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
      .toList(growable: false);
}

bool _failed(PsdkBattleTurnResult result, {required String moveId}) {
  return result.timeline.events
      .whereType<PsdkBattleMoveFailedEvent>()
      .any((event) => event.moveId == moveId);
}

const _opponentRightSlot = PsdkBattleSlotRef(bank: 1, position: 1);
