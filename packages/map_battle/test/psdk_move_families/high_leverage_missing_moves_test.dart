import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK high-leverage missing move families', () {
    test('s_a_fang deals damage and applies the imported fang status rider',
        () {
      final result = _runMove(
        playerMove: _move(
          id: 'fire_fang',
          type: 'fire',
          power: 65,
          battleEngineMethod: 's_a_fang',
          effectChance: 100,
          statuses: <PsdkBattleMoveStatus>[
            PsdkBattleMoveStatus(
              status: PsdkBattleMajorStatus.burn,
              chance: 100,
            ),
          ],
        ),
      );

      expect(_damageEvents(result, moveId: 'fire_fang'), hasLength(1));
      expect(
        result.state.battlerAt(psdkOpponentSlot).majorStatus,
        PsdkBattleMajorStatus.burn,
      );
      expect(_statusEvents(result, moveId: 'fire_fang'), hasLength(1));
    });

    test('s_ohko directly removes the target current HP on hit', () {
      final result = _runMove(
        playerMove: _move(
          id: 'guillotine',
          power: 0,
          accuracy: 100,
          battleEngineMethod: 's_ohko',
        ),
      );

      final damage = _damageEvents(result, moveId: 'guillotine');
      expect(damage, hasLength(1));
      expect(damage.single.damage, 100);
      expect(damage.single.remainingHp, 0);
      expect(result.state.battlerAt(psdkOpponentSlot).currentHp, 0);
      expect(result.outcome?.kind, PsdkBattleOutcomeKind.victory);
    });

    test('s_sacred_sword ignores target defensive stages for damage', () {
      final neutral = _runMove(
        playerMove: _move(
          id: 'sacred_sword',
          type: 'fighting',
          power: 90,
          battleEngineMethod: 's_sacred_sword',
        ),
        opponentTypes: const PsdkBattleTypes(primary: 'fire'),
      );
      final boostedDefense = _runMove(
        playerMove: _move(
          id: 'sacred_sword',
          type: 'fighting',
          power: 90,
          battleEngineMethod: 's_sacred_sword',
        ),
        opponentTypes: const PsdkBattleTypes(primary: 'fire'),
        opponentStages: PsdkBattleStatStages(values: const <String, int>{
          'defense': 6,
        }),
      );

      expect(
        _damage(boostedDefense, moveId: 'sacred_sword'),
        _damage(neutral, moveId: 'sacred_sword'),
      );
      expect(_damage(neutral, moveId: 'sacred_sword'), 17);
    });

    test('s_heal_bell cures active same-bank statuses in singles', () {
      final result = _runMove(
        playerMajorStatus: PsdkBattleMajorStatus.poison,
        playerMove: _move(
          id: 'heal_bell',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 0,
          battleEngineMethod: 's_heal_bell',
          target: PsdkBattleMoveTarget.allAllies,
        ),
      );

      expect(result.state.battlerAt(psdkPlayerSlot).majorStatus, isNull);
      expect(_cureEvents(result, moveId: 'heal_bell'), hasLength(1));
      expect(
        _cureEvents(result, moveId: 'heal_bell').single.target,
        psdkPlayerSlot,
      );
    });

    test('s_take_heart cures major status on its actual target', () {
      final result = _runMove(
        playerMajorStatus: PsdkBattleMajorStatus.burn,
        playerMove: _move(
          id: 'take_heart',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 0,
          battleEngineMethod: 's_take_heart',
          target: PsdkBattleMoveTarget.self,
        ),
      );

      expect(result.state.battlerAt(psdkPlayerSlot).majorStatus, isNull);
      expect(_cureEvents(result, moveId: 'take_heart'), hasLength(1));
    });

    test('s_sparkly_swirl damages the target then cures active allies', () {
      final result = _runMove(
        playerMajorStatus: PsdkBattleMajorStatus.poison,
        playerMove: _move(
          id: 'sparkly_swirl',
          type: 'fairy',
          category: PsdkBattleMoveCategory.special,
          power: 90,
          battleEngineMethod: 's_sparkly_swirl',
        ),
      );

      expect(_damageEvents(result, moveId: 'sparkly_swirl'), hasLength(1));
      expect(result.state.battlerAt(psdkPlayerSlot).majorStatus, isNull);
      expect(_cureEvents(result, moveId: 'sparkly_swirl'), hasLength(1));
      expect(
        _eventsFor(result, moveId: 'sparkly_swirl').map((event) => event.kind),
        containsAllInOrder(<String>[
          'damage',
          'status_cure',
        ]),
      );
    });

    test('s_reload deals damage then prevents the user next turn', () {
      final engine = PsdkBattleEngine(
        setup: PsdkBattleSetup.singles(
          player: _combatant(
            id: 'player',
            types: const PsdkBattleTypes(primary: 'normal'),
            speed: 100,
            move: _move(
              id: 'hyper_beam',
              category: PsdkBattleMoveCategory.special,
              power: 150,
              battleEngineMethod: 's_reload',
            ),
          ),
          opponent: _combatant(
            id: 'opponent',
            types: const PsdkBattleTypes(primary: 'normal'),
            speed: 1,
            move: _move(
              id: 'opponent_wait',
              power: 0,
              accuracy: 1,
            ),
          ),
          rngSeeds: const PsdkBattleRngSeeds(
            moveDamage: 1,
            moveCritical: 99999,
            moveAccuracy: 3,
            generic: 0,
          ),
        ),
      );

      final first = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      expect(_damageEvents(first, moveId: 'hyper_beam'), hasLength(1));
      expect(
        first.state
            .battlerAt(psdkPlayerSlot)
            .effects
            .contains(PsdkBattleEffectIds.forceNextMoveBase),
        isTrue,
      );

      final second = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      expect(_damageEvents(second, moveId: 'hyper_beam'), isEmpty);
      expect(
        second.state
            .battlerAt(psdkPlayerSlot)
            .effects
            .contains(PsdkBattleEffectIds.forceNextMoveBase),
        isFalse,
      );
      expect(
        second.timeline.events.whereType<PsdkBattleMoveFailedEvent>().single,
        isA<PsdkBattleMoveFailedEvent>()
            .having((event) => event.moveId, 'moveId', 'hyper_beam')
            .having((event) => event.reason, 'reason', 'unusable_by_user'),
      );
    });

    test('s_reflect installs a temporary screen marker on the user bank', () {
      final result = _runMove(
        playerMove: _move(
          id: 'reflect',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 0,
          battleEngineMethod: 's_reflect',
          target: PsdkBattleMoveTarget.allAllies,
        ),
      );

      final effects = result.state.battlerAt(psdkPlayerSlot).effects.effects;
      final reflect = effects.singleWhere((effect) => effect.id == 'reflect');
      expect(reflect.remainingTurns, 4);
    });

    test('s_follow_me is executable as a turn-scoped attention marker', () {
      final result = _runMove(
        playerMove: _move(
          id: 'follow_me',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 0,
          battleEngineMethod: 's_follow_me',
          target: PsdkBattleMoveTarget.self,
        ),
      );

      expect(
        result.timeline.events.whereType<PsdkBattleMoveFailedEvent>(),
        isEmpty,
      );
      expect(
        result.state
            .battlerAt(psdkPlayerSlot)
            .effects
            .contains(PsdkBattleEffectIds.centerOfAttention),
        isFalse,
      );
    });

    test('s_2turns charges first then strikes on the next submission', () {
      final engine = PsdkBattleEngine(
        setup: PsdkBattleSetup.singles(
          player: _combatant(
            id: 'player',
            types: const PsdkBattleTypes(primary: 'flying'),
            speed: 100,
            move: _move(
              id: 'fly',
              type: 'flying',
              category: PsdkBattleMoveCategory.physical,
              power: 90,
              battleEngineMethod: 's_2turns',
            ),
          ),
          opponent: _combatant(
            id: 'opponent',
            types: const PsdkBattleTypes(primary: 'grass'),
            speed: 1,
            move: _move(
              id: 'opponent_wait',
              power: 0,
              accuracy: 1,
            ),
          ),
          rngSeeds: const PsdkBattleRngSeeds(
            moveDamage: 1,
            moveCritical: 99999,
            moveAccuracy: 3,
            generic: 0,
          ),
        ),
      );

      final charge = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      expect(_damageEvents(charge, moveId: 'fly'), isEmpty);
      expect(
        charge.state
            .battlerAt(psdkPlayerSlot)
            .effects
            .contains(PsdkBattleEffectIds.twoTurnCharge),
        isTrue,
      );

      final strike = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      expect(_damageEvents(strike, moveId: 'fly'), hasLength(1));
      expect(
        strike.state
            .battlerAt(psdkPlayerSlot)
            .effects
            .contains(PsdkBattleEffectIds.twoTurnCharge),
        isFalse,
      );
    });

    test('s_electro_shot boosts Sp. Atk while charging then strikes', () {
      final engine = PsdkBattleEngine(
        setup: PsdkBattleSetup.singles(
          player: _combatant(
            id: 'player',
            types: const PsdkBattleTypes(primary: 'electric'),
            speed: 100,
            move: _move(
              id: 'electro_shot',
              type: 'electric',
              category: PsdkBattleMoveCategory.special,
              power: 130,
              battleEngineMethod: 's_electro_shot',
            ),
          ),
          opponent: _combatant(
            id: 'opponent',
            types: const PsdkBattleTypes(primary: 'water'),
            speed: 1,
            move: _move(
              id: 'opponent_wait',
              power: 0,
              accuracy: 1,
            ),
          ),
          rngSeeds: const PsdkBattleRngSeeds(
            moveDamage: 1,
            moveCritical: 99999,
            moveAccuracy: 3,
            generic: 0,
          ),
        ),
      );

      final charge = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      final chargingPlayer = charge.state.battlerAt(psdkPlayerSlot);
      expect(_damageEvents(charge, moveId: 'electro_shot'), isEmpty);
      expect(chargingPlayer.statStages.valueOf('specialAttack'), 1);
      expect(
        chargingPlayer.effects.contains(PsdkBattleEffectIds.twoTurnCharge),
        isTrue,
      );

      final strike = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      expect(_damageEvents(strike, moveId: 'electro_shot'), hasLength(1));
      expect(
        strike.state
            .battlerAt(psdkPlayerSlot)
            .effects
            .contains(PsdkBattleEffectIds.twoTurnCharge),
        isFalse,
      );
    });

    test('s_electro_shot skips charge under rain but still boosts Sp. Atk', () {
      final result = _runMove(
        playerMove: _move(
          id: 'electro_shot',
          type: 'electric',
          category: PsdkBattleMoveCategory.special,
          power: 130,
          battleEngineMethod: 's_electro_shot',
        ),
        opponentTypes: const PsdkBattleTypes(primary: 'water'),
        field: const PsdkBattleFieldState(
          weather: PsdkBattleWeatherState(
            id: PsdkBattleWeatherId.rain,
            remainingTurns: 5,
          ),
        ),
      );

      final player = result.state.battlerAt(psdkPlayerSlot);
      expect(_damageEvents(result, moveId: 'electro_shot'), hasLength(1));
      expect(player.statStages.valueOf('specialAttack'), 1);
      expect(
          player.effects.contains(PsdkBattleEffectIds.twoTurnCharge), isFalse);
    });

    test('s_foresight installs a target marker through the status pipeline',
        () {
      final result = _runMove(
        playerMove: _move(
          id: 'foresight',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 0,
          battleEngineMethod: 's_foresight',
        ),
        opponentTypes: const PsdkBattleTypes(primary: 'ghost'),
      );

      expect(
        result.timeline.events.whereType<PsdkBattleMoveFailedEvent>(),
        isEmpty,
      );
      expect(
        result.state
            .battlerAt(psdkOpponentSlot)
            .effects
            .contains(PsdkBattleEffectIds.foresight),
        isTrue,
      );
    });

    test('s_add_type writes the PSDK third-type slot on the target', () {
      final result = _runMove(
        playerMove: _move(
          id: 'trick_or_treat',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 100,
          battleEngineMethod: 's_add_type',
        ),
      );

      final opponent = result.state.battlerAt(psdkOpponentSlot);
      expect(opponent.type3, 'ghost');
      expect(opponent.hasType('ghost'), isTrue);
    });

    test('s_thing_sport installs a five-turn sport marker', () {
      final result = _runMove(
        playerMove: _move(
          id: 'mud_sport',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 0,
          battleEngineMethod: 's_thing_sport',
          target: PsdkBattleMoveTarget.self,
        ),
      );

      final effect = result.state
          .battlerAt(psdkPlayerSlot)
          .effects
          .effects
          .singleWhere((effect) => effect.id == PsdkBattleEffectIds.mudSport);
      expect(effect.remainingTurns, 4);
      expect(effect.scope, isA<FieldBattleEffectScope>());
    });

    test('s_trick swaps user and target held items', () {
      final result = _runMove(
        playerHeldItemId: 'choice_scarf',
        opponentHeldItemId: 'leftovers',
        playerMove: _move(
          id: 'trick',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 100,
          battleEngineMethod: 's_trick',
        ),
      );

      expect(result.state.battlerAt(psdkPlayerSlot).heldItemId, 'leftovers');
      expect(
        result.state.battlerAt(psdkOpponentSlot).heldItemId,
        'choice_scarf',
      );
    });

    test('s_z_move executes its offensive Studio Z-Move hit', () {
      final result = _runMove(
        playerSpeciesId: 'pikachu',
        playerHeldItemId: 'pikanium_z',
        playerMove: _move(
          id: 'catastropika',
          type: 'electric',
          category: PsdkBattleMoveCategory.physical,
          power: 210,
          accuracy: 0,
          battleEngineMethod: 's_z_move',
        ),
        playerExtraMoves: <PsdkBattleMoveData>[
          _move(
            id: 'volt_tackle',
            type: 'electric',
            category: PsdkBattleMoveCategory.physical,
            power: 120,
            battleEngineMethod: 's_basic',
          ),
        ],
        opponentTypes: const PsdkBattleTypes(primary: 'water'),
      );

      expect(_damageEvents(result, moveId: 'catastropika'), hasLength(1));
      expect(
        result.state.battlerAt(psdkOpponentSlot).currentHp,
        lessThan(100),
      );
    });

    test('s_yawn installs a drowsiness marker on the target', () {
      final result = _runMove(
        playerMove: _move(
          id: 'yawn',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 0,
          battleEngineMethod: 's_yawn',
        ),
      );

      final effect = _effect(
        result.state.battlerAt(psdkOpponentSlot),
        'drowsiness',
      );
      expect(effect.scope, isA<BattlerBattleEffectScope>());
      expect(effect.remainingTurns, 1);
    });

    for (final entry in <({String method, String moveId, String effectId})>[
      (method: 's_taunt', moveId: 'taunt', effectId: 'taunt'),
      (method: 's_torment', moveId: 'torment', effectId: 'torment'),
      (
        method: 's_miracle_eye',
        moveId: 'miracle_eye',
        effectId: 'miracle_eye',
      ),
      (
        method: 's_telekinesis',
        moveId: 'telekinesis',
        effectId: 'telekinesis',
      ),
    ]) {
      test('${entry.method} installs a target marker', () {
        final result = _runMove(
          playerMove: _move(
            id: entry.moveId,
            category: PsdkBattleMoveCategory.status,
            power: 0,
            accuracy: 100,
            battleEngineMethod: entry.method,
          ),
        );

        expect(
          result.state.battlerAt(psdkOpponentSlot).effects.contains(
                entry.effectId,
              ),
          isTrue,
        );
      });
    }

    test('s_minimize installs its self marker on the user', () {
      final result = _runMove(
        playerMove: _move(
          id: 'minimize',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 0,
          battleEngineMethod: 's_minimize',
          target: PsdkBattleMoveTarget.self,
          stageMods: const <PsdkBattleMoveStageMod>[
            PsdkBattleMoveStageMod(
              stat: 'evasion',
              stages: 2,
              chance: 100,
            ),
          ],
        ),
      );

      expect(
        result.state.battlerAt(psdkPlayerSlot).effects.contains('minimize'),
        isTrue,
      );
      expect(
        result.state.battlerAt(psdkPlayerSlot).statStages.valueOf('evasion'),
        2,
      );
    });

    test('s_future_sight installs a delayed position marker', () {
      final result = _runMove(
        playerMove: _move(
          id: 'future_sight',
          type: 'psychic',
          category: PsdkBattleMoveCategory.special,
          power: 120,
          accuracy: 100,
          battleEngineMethod: 's_future_sight',
        ),
      );

      final effect = _effect(
        result.state.battlerAt(psdkOpponentSlot),
        'future_sight',
      );
      expect(effect.remainingTurns, 2);
      expect(effect.scope, isA<BattlerBattleEffectScope>());
      expect(_damageEvents(result, moveId: 'future_sight'), isEmpty);
    });

    test('s_perish_song installs a countdown marker on all battlers', () {
      final result = _runMove(
        playerMove: _move(
          id: 'perish_song',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 0,
          battleEngineMethod: 's_perish_song',
          target: PsdkBattleMoveTarget.allBattlers,
        ),
      );

      final playerEffect = _effect(
        result.state.battlerAt(psdkPlayerSlot),
        'perish_song',
      );
      final opponentEffect = _effect(
        result.state.battlerAt(psdkOpponentSlot),
        'perish_song',
      );
      expect(playerEffect.remainingTurns, 3);
      expect(opponentEffect.remainingTurns, 3);
    });

    for (final entry in <({String method, String moveId, String effectId})>[
      (method: 's_tailwind', moveId: 'tailwind', effectId: 'tailwind'),
      (method: 's_safe_guard', moveId: 'safeguard', effectId: 'safeguard'),
      (method: 's_mist', moveId: 'mist', effectId: 'mist'),
    ]) {
      test('${entry.method} installs a user-bank marker', () {
        final result = _runMove(
          playerMove: _move(
            id: entry.moveId,
            category: PsdkBattleMoveCategory.status,
            power: 0,
            accuracy: 0,
            battleEngineMethod: entry.method,
            target: PsdkBattleMoveTarget.userSide,
          ),
        );

        final effect = _effect(
          result.state.battlerAt(psdkPlayerSlot),
          entry.effectId,
        );
        expect(effect.scope, isA<BankBattleEffectScope>());
      });
    }

    test('s_wish installs a delayed slot heal marker', () {
      final result = _runMove(
        playerMove: _move(
          id: 'wish',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 0,
          battleEngineMethod: 's_wish',
          target: PsdkBattleMoveTarget.user,
        ),
      );

      final effect = _effect(
        result.state.battlerAt(psdkPlayerSlot),
        'wish',
      );
      expect(effect, isA<WishEffect>());
      expect(effect.scope, isA<BattlerBattleEffectScope>());
      expect(effect.remainingTurns, 1);
    });

    test('s_toxic_thread applies poison and speed drop without damage', () {
      final result = _runMove(
        playerMove: _move(
          id: 'toxic_thread',
          type: 'poison',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 100,
          battleEngineMethod: 's_toxic_thread',
          statuses: <PsdkBattleMoveStatus>[
            PsdkBattleMoveStatus(
              status: PsdkBattleMajorStatus.poison,
              chance: 100,
            ),
          ],
          stageMods: const <PsdkBattleMoveStageMod>[
            PsdkBattleMoveStageMod(
              stat: 'speed',
              stages: -1,
              chance: 100,
            ),
          ],
        ),
      );

      final opponent = result.state.battlerAt(psdkOpponentSlot);
      expect(opponent.majorStatus, PsdkBattleMajorStatus.poison);
      expect(opponent.statStages.valueOf('speed'), -1);
      expect(_statusEvents(result, moveId: 'toxic_thread'), hasLength(1));
      expect(_damageEvents(result, moveId: 'toxic_thread'), isEmpty);
    });

    test('s_plasma_fists deals damage and installs an Ion Deluge marker', () {
      final result = _runMove(
        playerMove: _move(
          id: 'plasma_fists',
          type: 'electric',
          power: 100,
          battleEngineMethod: 's_plasma_fists',
        ),
        opponentTypes: const PsdkBattleTypes(primary: 'water'),
      );

      expect(_damageEvents(result, moveId: 'plasma_fists'), hasLength(1));
      final effect = _effect(
        result.state.battlerAt(psdkPlayerSlot),
        'ion_deluge',
      );
      expect(effect.scope, isA<FieldBattleEffectScope>());
    });

    for (final entry
        in <({String method, String moveId, String effectId, int turns})>[
      (
        method: 's_disable',
        moveId: 'disable',
        effectId: 'disable',
        turns: 3,
      ),
      (
        method: 's_encore',
        moveId: 'encore',
        effectId: 'encore',
        turns: 2,
      ),
      (
        method: 's_embargo',
        moveId: 'embargo',
        effectId: 'embargo',
        turns: 4,
      ),
      (
        method: 's_heal_block',
        moveId: 'heal_block',
        effectId: 'heal_block',
        turns: 4,
      ),
    ]) {
      test('${entry.method} installs a timed target marker', () {
        final result = _runMove(
          playerMove: _move(
            id: entry.moveId,
            category: PsdkBattleMoveCategory.status,
            power: 0,
            accuracy: 100,
            battleEngineMethod: entry.method,
          ),
          opponentMoveHistory:
              entry.method == 's_disable' || entry.method == 's_encore'
                  ? PsdkBattleMoveHistory(
                      successes: <PsdkBattleMoveHistoryEntry>[
                        PsdkBattleMoveHistoryEntry(
                          moveId: 'tackle',
                          turn: 1,
                          targets: <PsdkBattleSlotRef>[psdkPlayerSlot],
                        ),
                      ],
                    )
                  : null,
        );

        final effect = _effect(
          result.state.battlerAt(psdkOpponentSlot),
          entry.effectId,
        );
        expect(effect.scope, isA<BattlerBattleEffectScope>());
        expect(effect.remainingTurns, entry.turns);
      });
    }

    test('s_magnet_rise installs a five-turn self floating marker', () {
      final result = _runMove(
        playerMove: _move(
          id: 'magnet_rise',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 0,
          battleEngineMethod: 's_magnet_rise',
          target: PsdkBattleMoveTarget.self,
        ),
      );

      final effect = _effect(
        result.state.battlerAt(psdkPlayerSlot),
        'magnet_rise',
      );
      expect(effect.scope, isA<BattlerBattleEffectScope>());
      expect(effect.remainingTurns, 4);
    });

    test('s_lucky_chant installs a five-turn user-bank marker', () {
      final result = _runMove(
        playerMove: _move(
          id: 'lucky_chant',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 0,
          battleEngineMethod: 's_lucky_chant',
          target: PsdkBattleMoveTarget.allAllies,
        ),
      );

      final effect = _effect(
        result.state.battlerAt(psdkPlayerSlot),
        'lucky_chant',
      );
      expect(effect.scope, isA<BankBattleEffectScope>());
      expect(effect.remainingTurns, 4);
    });

    test('s_destiny_bond KOs the attacker when the user faints to a foe move',
        () {
      final result = _runMove(
        playerMove: _move(
          id: 'destiny_bond',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 0,
          battleEngineMethod: 's_destiny_bond',
          target: PsdkBattleMoveTarget.self,
        ),
        opponentMove: _move(
          id: 'opponent_tackle',
          power: 40,
        ),
        playerCurrentHp: 1,
      );

      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 0);
      expect(result.state.battlerAt(psdkOpponentSlot).currentHp, 0);
      expect(
        _damageEvents(result, moveId: 'effect:destiny_bond'),
        hasLength(1),
      );
    });

    test('s_destiny_bond fails while the effect is already active', () {
      final engine = PsdkBattleEngine(
        setup: PsdkBattleSetup.singles(
          player: _combatant(
            id: 'player',
            types: const PsdkBattleTypes(primary: 'ghost'),
            speed: 100,
            move: _move(
              id: 'destiny_bond',
              category: PsdkBattleMoveCategory.status,
              power: 0,
              accuracy: 0,
              battleEngineMethod: 's_destiny_bond',
              target: PsdkBattleMoveTarget.self,
            ),
          ),
          opponent: _combatant(
            id: 'opponent',
            types: const PsdkBattleTypes(primary: 'normal'),
            speed: 10,
            move: _move(id: 'opponent_wait', power: 0, accuracy: 1),
          ),
          rngSeeds: const PsdkBattleRngSeeds(
            moveDamage: 1,
            moveCritical: 99999,
            moveAccuracy: 3,
            generic: 0,
          ),
        ),
      );

      engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      final second = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));

      final failures =
          second.timeline.events.whereType<PsdkBattleMoveFailedEvent>();
      expect(failures, hasLength(1));
      expect(failures.single.reason, 'destiny_bond_already_active');
    });

    test('s_destiny_bond clears on the owner next different move attempt', () {
      final engine = PsdkBattleEngine(
        setup: PsdkBattleSetup.singles(
          player: _combatant(
            id: 'player',
            types: const PsdkBattleTypes(primary: 'ghost'),
            speed: 100,
            move: _move(
              id: 'destiny_bond',
              category: PsdkBattleMoveCategory.status,
              power: 0,
              accuracy: 0,
              battleEngineMethod: 's_destiny_bond',
              target: PsdkBattleMoveTarget.self,
            ),
            extraMoves: <PsdkBattleMoveData>[
              _move(id: 'tackle', power: 40),
            ],
          ),
          opponent: _combatant(
            id: 'opponent',
            types: const PsdkBattleTypes(primary: 'normal'),
            speed: 10,
            move: _move(id: 'opponent_wait', power: 0, accuracy: 1),
          ),
          rngSeeds: const PsdkBattleRngSeeds(
            moveDamage: 1,
            moveCritical: 99999,
            moveAccuracy: 3,
            generic: 0,
          ),
        ),
      );

      final first = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      expect(
        first.state.battlerAt(psdkPlayerSlot).effects.contains('destiny_bond'),
        isTrue,
      );

      final second = engine.submit(const PsdkBattleDecision.fight(moveSlot: 1));
      expect(
        second.state.battlerAt(psdkPlayerSlot).effects.contains('destiny_bond'),
        isFalse,
      );
      expect(_damageEvents(second, moveId: 'tackle'), hasLength(1));
    });

    for (final entry in <({String method, String moveId})>[
      (method: 's_electrify', moveId: 'electrify'),
      (method: 's_ion_deluge', moveId: 'ion_deluge'),
      (method: 's_powder', moveId: 'powder'),
      (method: 's_snatch', moveId: 'snatch'),
    ]) {
      test('${entry.method} executes as a turn-scoped marker slice', () {
        final result = _runMove(
          playerMove: _move(
            id: entry.moveId,
            category: PsdkBattleMoveCategory.status,
            power: 0,
            accuracy: entry.method == 's_powder' ? 100 : 0,
            battleEngineMethod: entry.method,
            target: switch (entry.method) {
              's_grudge' || 's_snatch' => PsdkBattleMoveTarget.self,
              's_ion_deluge' => PsdkBattleMoveTarget.allBattlers,
              _ => PsdkBattleMoveTarget.adjacentFoe,
            },
          ),
        );

        expect(
          result.timeline.events.whereType<PsdkBattleMoveFailedEvent>(),
          isEmpty,
        );
      });
    }

    test('s_grudge drops the killer move PP to 0 when the user faints', () {
      final result = _runMove(
        playerMove: _move(
          id: 'grudge',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 0,
          battleEngineMethod: 's_grudge',
          target: PsdkBattleMoveTarget.self,
        ),
        opponentMove: _move(
          id: 'opponent_tackle',
          power: 40,
          currentPp: 5,
        ),
        playerCurrentHp: 1,
      );

      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 0);
      expect(
        result.state.battlerAt(psdkOpponentSlot).moves.single.currentPp,
        0,
      );
    });

    test('s_grudge fails while the effect is already active', () {
      final move = _move(
        id: 'grudge',
        category: PsdkBattleMoveCategory.status,
        power: 0,
        accuracy: 0,
        battleEngineMethod: 's_grudge',
        target: PsdkBattleMoveTarget.self,
      );
      final result = _resolveMoveOnState(
        move: move,
        target: psdkPlayerSlot,
        state: PsdkBattleState(
          combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
            psdkPlayerSlot: PsdkBattleCombatant.fromSetup(
              _combatant(
                id: 'player',
                types: const PsdkBattleTypes(primary: 'ghost'),
                speed: 100,
                move: move,
                effects: PsdkBattleEffectStack(
                  values: const <String>['grudge'],
                ),
              ),
            ),
            psdkOpponentSlot: PsdkBattleCombatant.fromSetup(
              _combatant(
                id: 'opponent',
                types: const PsdkBattleTypes(primary: 'normal'),
                speed: 10,
                move: _move(id: 'opponent_wait', power: 0, accuracy: 1),
              ),
            ),
          },
        ),
      );

      final failures = result.events.whereType<PsdkBattleMoveFailedEvent>();
      expect(failures, hasLength(1));
      expect(failures.single.reason, 'grudge_already_active');
    });

    for (final entry in <({String method, String moveId, String effectId})>[
      (method: 's_spike', moveId: 'spikes', effectId: 'spikes'),
      (
        method: 's_stealth_rock',
        moveId: 'stealth_rock',
        effectId: 'stealth_rock',
      ),
      (method: 's_sticky_web', moveId: 'sticky_web', effectId: 'sticky_web'),
      (
        method: 's_toxic_spike',
        moveId: 'toxic_spikes',
        effectId: 'toxic_spikes',
      ),
    ]) {
      test('${entry.method} installs a foe-bank hazard marker', () {
        final result = _runMove(
          playerMove: _move(
            id: entry.moveId,
            category: PsdkBattleMoveCategory.status,
            power: 0,
            accuracy: 0,
            battleEngineMethod: entry.method,
            target: PsdkBattleMoveTarget.foeSide,
          ),
        );

        final effect = _effect(
          result.state.battlerAt(psdkPlayerSlot),
          entry.effectId,
        );
        expect(effect.scope, isA<BankBattleEffectScope>());
        expect((effect.scope as BankBattleEffectScope).bank,
            psdkOpponentSlot.bank);
      });
    }

    for (final entry in <({String method, String moveId, String effectId})>[
      (method: 's_trick_room', moveId: 'trick_room', effectId: 'trick_room'),
      (method: 's_wonder_room', moveId: 'wonder_room', effectId: 'wonder_room'),
    ]) {
      test('${entry.method} installs a field marker', () {
        final result = _runMove(
          playerMove: _move(
            id: entry.moveId,
            category: PsdkBattleMoveCategory.status,
            power: 0,
            accuracy: 0,
            battleEngineMethod: entry.method,
            target: PsdkBattleMoveTarget.none,
          ),
        );

        final effect = _effect(
          result.state.battlerAt(psdkPlayerSlot),
          entry.effectId,
        );
        expect(effect.scope, isA<FieldBattleEffectScope>());
        expect(effect.remainingTurns, 4);
      });
    }

    test('s_wonder_room removes the active field marker when toggled', () {
      final result = _runMove(
        playerMove: _move(
          id: 'wonder_room',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 0,
          battleEngineMethod: 's_wonder_room',
          target: PsdkBattleMoveTarget.none,
        ),
        playerEffects: const PsdkBattleEffectStack.empty().addEffect(
          GenericBattleEffect(
            id: 'wonder_room',
            scope: FieldBattleEffectScope(),
            remainingTurns: 3,
          ),
        ),
      );

      expect(
        result.state.battlerAt(psdkPlayerSlot).effects.contains('wonder_room'),
        isFalse,
      );
    });

    for (final entry in <({String method, String moveId, String abilityId})>[
      (method: 's_simple_beam', moveId: 'simple_beam', abilityId: 'simple'),
      (method: 's_worry_seed', moveId: 'worry_seed', abilityId: 'insomnia'),
    ]) {
      test('${entry.method} rewrites the target ability', () {
        final result = _runMove(
          opponentAbilityId: 'overgrow',
          playerMove: _move(
            id: entry.moveId,
            category: PsdkBattleMoveCategory.status,
            power: 0,
            accuracy: 100,
            battleEngineMethod: entry.method,
          ),
        );

        expect(result.state.battlerAt(psdkOpponentSlot).abilityId,
            entry.abilityId);
      });
    }

    test('s_role_play copies the target ability onto the user', () {
      final result = _runMove(
        playerAbilityId: 'blaze',
        opponentAbilityId: 'levitate',
        playerMove: _move(
          id: 'role_play',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 100,
          battleEngineMethod: 's_role_play',
        ),
      );

      expect(result.state.battlerAt(psdkPlayerSlot).abilityId, 'levitate');
    });

    test('s_skill_swap swaps user and target abilities', () {
      final result = _runMove(
        playerAbilityId: 'blaze',
        opponentAbilityId: 'levitate',
        playerMove: _move(
          id: 'skill_swap',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 100,
          battleEngineMethod: 's_skill_swap',
        ),
      );

      expect(result.state.battlerAt(psdkPlayerSlot).abilityId, 'levitate');
      expect(result.state.battlerAt(psdkOpponentSlot).abilityId, 'blaze');
    });

    test('s_reflect_type copies visible target types onto the user', () {
      final result = _runMove(
        playerTypes: const PsdkBattleTypes(primary: 'normal'),
        opponentTypes: const PsdkBattleTypes(
          primary: 'dragon',
          secondary: 'flying',
        ),
        playerMove: _move(
          id: 'reflect_type',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 0,
          battleEngineMethod: 's_reflect_type',
        ),
      );

      expect(result.state.battlerAt(psdkPlayerSlot).types.primary, 'dragon');
      expect(result.state.battlerAt(psdkPlayerSlot).types.secondary, 'flying');
    });

    test('s_focus_energy installs a self critical marker', () {
      final result = _runMove(
        playerMove: _move(
          id: 'focus_energy',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 0,
          battleEngineMethod: 's_focus_energy',
          target: PsdkBattleMoveTarget.self,
        ),
      );

      expect(
        result.state.battlerAt(psdkPlayerSlot).effects.contains('focus_energy'),
        isTrue,
      );
    });

    test('s_laser_focus installs a timed self critical marker', () {
      final result = _runMove(
        playerMove: _move(
          id: 'laser_focus',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 0,
          battleEngineMethod: 's_laser_focus',
          target: PsdkBattleMoveTarget.self,
        ),
      );

      final effect = result.state
          .battlerAt(psdkPlayerSlot)
          .effects
          .effects
          .singleWhere((effect) => effect.id == 'laser_focus');
      expect(effect.remainingTurns, 1);
    });

    test('s_charge installs a timed marker and applies Special Defense', () {
      final result = _runMove(
        playerMove: _move(
          id: 'charge',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 0,
          battleEngineMethod: 's_charge',
          target: PsdkBattleMoveTarget.self,
          stageMods: const <PsdkBattleMoveStageMod>[
            PsdkBattleMoveStageMod(
              stat: 'specialDefense',
              stages: 1,
              chance: 100,
            ),
          ],
        ),
      );

      final player = result.state.battlerAt(psdkPlayerSlot);
      final effect = player.effects.effects.singleWhere(
        (effect) => effect.id == 'charge',
      );
      expect(effect.remainingTurns, 1);
      expect(player.statStages.valueOf('specialDefense'), 1);
    });

    test('s_autotomize installs a marker, boosts Speed and lowers weight', () {
      final result = _runMove(
        playerBaseWeightKg: 250,
        playerCurrentWeightKg: 250,
        playerMove: _move(
          id: 'autotomize',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 0,
          battleEngineMethod: 's_autotomize',
          target: PsdkBattleMoveTarget.self,
          stageMods: const <PsdkBattleMoveStageMod>[
            PsdkBattleMoveStageMod(
              stat: 'speed',
              stages: 2,
              chance: 100,
            ),
          ],
        ),
      );

      final player = result.state.battlerAt(psdkPlayerSlot);
      expect(player.effects.contains('autotomize'), isTrue);
      expect(player.statStages.valueOf('speed'), 2);
      expect(player.baseWeightKg, 250);
      expect(player.currentWeightKg, 150);
    });

    test('s_autotomize does not lower weight when Speed cannot rise', () {
      final result = _runMove(
        playerBaseWeightKg: 250,
        playerCurrentWeightKg: 250,
        playerStages: PsdkBattleStatStages(values: const <String, int>{
          'speed': 6,
        }),
        playerMove: _move(
          id: 'autotomize',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 0,
          battleEngineMethod: 's_autotomize',
          target: PsdkBattleMoveTarget.self,
          stageMods: const <PsdkBattleMoveStageMod>[
            PsdkBattleMoveStageMod(
              stat: 'speed',
              stages: 2,
              chance: 100,
            ),
          ],
        ),
      );

      final player = result.state.battlerAt(psdkPlayerSlot);
      expect(player.statStages.valueOf('speed'), 6);
      expect(player.currentWeightKg, 250);
    });

    test('s_gastro_acid installs an ability suppression marker on the target',
        () {
      final result = _runMove(
        opponentAbilityId: 'levitate',
        playerMove: _move(
          id: 'gastro_acid',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 100,
          battleEngineMethod: 's_gastro_acid',
        ),
      );

      final opponent = result.state.battlerAt(psdkOpponentSlot);
      expect(opponent.effects.contains('ability_suppressed'), isTrue);
      expect(opponent.abilityId, 'levitate');
    });

    test('s_gastro_acid fails against PSDK protected abilities', () {
      const protectedAbilityIds = <String>[
        'as_one',
        'battle_bond',
        'comatose',
        'commander',
        'disguise',
        'gulp_missile',
        'hadron_engine',
        'hunger_switch',
        'ice_face',
        'imposter',
        'multitype',
        'orichalcum_pulse',
        'power_construct',
        'protosynthesis',
        'quark_drive',
        'rks_system',
        'schooling',
        'shields_down',
        'stance_change',
        'wonder_guard',
        'zen_mode',
        'zero_to_hero',
      ];

      for (final abilityId in protectedAbilityIds) {
        final result = _runMove(
          opponentAbilityId: abilityId,
          playerMove: _move(
            id: 'gastro_acid',
            category: PsdkBattleMoveCategory.status,
            power: 0,
            accuracy: 100,
            battleEngineMethod: 's_gastro_acid',
          ),
        );

        final opponent = result.state.battlerAt(psdkOpponentSlot);
        final failure = result.timeline.events
            .whereType<PsdkBattleMoveFailedEvent>()
            .single;
        expect(
          opponent.effects.contains('ability_suppressed'),
          isFalse,
          reason: abilityId,
        );
        expect(failure.reason, BattleMoveFailureReason.immunity.jsonName);
      }
    });

    test('s_gastro_acid fails against Good as Gold status protection', () {
      final result = _runMove(
        opponentAbilityId: 'good_as_gold',
        playerMove: _move(
          id: 'gastro_acid',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 100,
          battleEngineMethod: 's_gastro_acid',
        ),
      );

      final opponent = result.state.battlerAt(psdkOpponentSlot);
      final failure =
          result.timeline.events.whereType<PsdkBattleMoveFailedEvent>().single;
      expect(opponent.effects.contains('ability_suppressed'), isFalse);
      expect(failure.reason, BattleMoveFailureReason.immunity.jsonName);
    });

    test('s_gastro_acid fails when the target ability is already suppressed',
        () {
      final result = _runMove(
        opponentAbilityId: 'levitate',
        opponentEffects: const PsdkBattleEffectStack.empty().addEffect(
          GenericBattleEffect(
            id: 'ability_suppressed',
            scope: BattlerBattleEffectScope(psdkOpponentSlot),
          ),
        ),
        playerMove: _move(
          id: 'gastro_acid',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 100,
          battleEngineMethod: 's_gastro_acid',
        ),
      );

      final opponent = result.state.battlerAt(psdkOpponentSlot);
      final failure =
          result.timeline.events.whereType<PsdkBattleMoveFailedEvent>().single;
      expect(opponent.effects.contains('ability_suppressed'), isTrue);
      expect(failure.reason, BattleMoveFailureReason.immunity.jsonName);
    });

    test('s_defog applies its imported evasion drop without damage', () {
      final result = _runMove(
        playerMove: _move(
          id: 'defog',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 0,
          battleEngineMethod: 's_defog',
          stageMods: const <PsdkBattleMoveStageMod>[
            PsdkBattleMoveStageMod(
              stat: 'evasion',
              stages: -1,
              chance: 100,
            ),
          ],
        ),
      );

      expect(_damageEvents(result, moveId: 'defog'), isEmpty);
      expect(
        result.state.battlerAt(psdkOpponentSlot).statStages.valueOf('evasion'),
        -1,
      );
    });

    test('s_change_type replaces the target visible types with the move type',
        () {
      final result = _runMove(
        playerMove: _move(
          id: 'soak',
          type: 'water',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 100,
          battleEngineMethod: 's_change_type',
        ),
        opponentTypes: const PsdkBattleTypes(
          primary: 'fire',
          secondary: 'flying',
        ),
      );

      final opponent = result.state.battlerAt(psdkOpponentSlot);
      expect(opponent.types.primary, 'water');
      expect(opponent.types.secondary, isNull);
      expect(opponent.type3, isNull);
      expect(opponent.temporaryTypes, isEmpty);
      expect(opponent.effects.contains('change_type'), isTrue);
    });

    test('s_conversion rewrites the user visible types to its first move type',
        () {
      final result = _runMove(
        playerMove: _move(
          id: 'conversion',
          type: 'electric',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 0,
          battleEngineMethod: 's_conversion',
          target: PsdkBattleMoveTarget.user,
        ),
        playerTypes: const PsdkBattleTypes(
          primary: 'normal',
          secondary: 'flying',
        ),
      );

      final player = result.state.battlerAt(psdkPlayerSlot);
      expect(player.types.primary, 'electric');
      expect(player.types.secondary, isNull);
      expect(player.type3, isNull);
      expect(player.temporaryTypes, isEmpty);
      expect(
        result.timeline.events.whereType<PsdkBattleMoveFailedEvent>(),
        isEmpty,
      );
    });

    test('s_conversion2 rewrites the user to a resistant type', () {
      final result = _runMove(
        playerMove: _move(
          id: 'conversion_2',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 0,
          battleEngineMethod: 's_conversion2',
          target: PsdkBattleMoveTarget.adjacentFoe,
        ),
        playerTypes: const PsdkBattleTypes(
          primary: 'normal',
          secondary: 'flying',
        ),
        opponentMove: _move(
          id: 'surf',
          type: 'water',
          category: PsdkBattleMoveCategory.special,
          power: 90,
        ),
        opponentMoveHistory: PsdkBattleMoveHistory(
          attempts: <PsdkBattleMoveHistoryEntry>[
            PsdkBattleMoveHistoryEntry(
              moveId: 'surf',
              turn: 0,
              targets: const <PsdkBattleSlotRef>[psdkPlayerSlot],
            ),
          ],
        ),
      );

      final player = result.state.battlerAt(psdkPlayerSlot);
      expect(
          <String>['water', 'grass', 'dragon'], contains(player.types.primary));
      expect(player.types.secondary, isNull);
      expect(player.type3, isNull);
      expect(player.temporaryTypes, isEmpty);
      expect(
        result.timeline.events.whereType<PsdkBattleMoveFailedEvent>(),
        isEmpty,
      );
    });

    test('s_conversion2 fails if the target has no eligible move history', () {
      final result = _runMove(
        playerMove: _move(
          id: 'conversion_2',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 0,
          battleEngineMethod: 's_conversion2',
          target: PsdkBattleMoveTarget.adjacentFoe,
        ),
      );

      final failures =
          result.timeline.events.whereType<PsdkBattleMoveFailedEvent>();
      expect(failures, hasLength(1));
      expect(failures.single.reason,
          BattleMoveFailureReason.unusableByUser.jsonName);
    });

    test('s_magic_powder replaces the target visible types with Psychic', () {
      final result = _runMove(
        playerMove: _move(
          id: 'magic_powder',
          type: 'psychic',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 100,
          battleEngineMethod: 's_magic_powder',
          target: PsdkBattleMoveTarget.adjacentFoe,
        ),
        opponentTypes: const PsdkBattleTypes(
          primary: 'fire',
          secondary: 'flying',
        ),
      );

      final opponent = result.state.battlerAt(psdkOpponentSlot);
      expect(opponent.types.primary, 'psychic');
      expect(opponent.types.secondary, isNull);
      expect(opponent.type3, isNull);
      expect(opponent.temporaryTypes, isEmpty);
    });

    test('s_stockpile marks the user and raises both defensive stages', () {
      final result = _runMove(
        playerMove: _move(
          id: 'stockpile',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 0,
          battleEngineMethod: 's_stockpile',
          target: PsdkBattleMoveTarget.self,
        ),
      );

      final player = result.state.battlerAt(psdkPlayerSlot);
      expect(player.effects.contains('stockpile'), isTrue);
      expect(player.statStages.valueOf('defense'), 1);
      expect(player.statStages.valueOf('specialDefense'), 1);
    });

    test('s_stockpile increments an existing stockpile up to three layers', () {
      final result = _runMove(
        playerMove: _move(
          id: 'stockpile',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 0,
          battleEngineMethod: 's_stockpile',
          target: PsdkBattleMoveTarget.self,
        ),
        playerStages: PsdkBattleStatStages(
          values: <String, int>{
            'defense': 2,
            'specialDefense': 2,
          },
        ),
        playerEffects: const PsdkBattleEffectStack.empty().addEffect(
          StockpileEffect(
            scope: BattlerBattleEffectScope(psdkPlayerSlot),
            stockpile: 2,
            defenseBonus: 2,
            specialDefenseBonus: 2,
          ),
        ),
      );

      final player = result.state.battlerAt(psdkPlayerSlot);
      final stockpile = player.effects.effects.singleWhere(
        (effect) => effect.id == 'stockpile',
      ) as StockpileEffect;
      expect(stockpile.stockpile, 3);
      expect(stockpile.defenseBonus, 3);
      expect(stockpile.specialDefenseBonus, 3);
      expect(player.statStages.valueOf('defense'), 3);
      expect(player.statStages.valueOf('specialDefense'), 3);
    });

    test('s_swallow heals from stockpile and clears its staged bonuses', () {
      final result = _runMove(
        playerCurrentHp: 40,
        playerMove: _move(
          id: 'swallow',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 0,
          battleEngineMethod: 's_swallow',
          target: PsdkBattleMoveTarget.self,
        ),
        playerStages: PsdkBattleStatStages(
          values: <String, int>{
            'defense': 2,
            'specialDefense': 2,
          },
        ),
        playerEffects: const PsdkBattleEffectStack.empty().addEffect(
          StockpileEffect(
            scope: BattlerBattleEffectScope(psdkPlayerSlot),
            stockpile: 2,
            defenseBonus: 2,
            specialDefenseBonus: 2,
          ),
        ),
      );

      final player = result.state.battlerAt(psdkPlayerSlot);
      expect(player.currentHp, 90);
      expect(player.effects.contains('stockpile'), isFalse);
      expect(player.statStages.valueOf('defense'), 0);
      expect(player.statStages.valueOf('specialDefense'), 0);
      expect(
        result.timeline.events.whereType<PsdkBattleMoveFailedEvent>(),
        isEmpty,
      );
    });

    test('s_swallow fails without a usable stockpile effect', () {
      final result = _runMove(
        playerMove: _move(
          id: 'swallow',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 0,
          battleEngineMethod: 's_swallow',
          target: PsdkBattleMoveTarget.self,
        ),
      );

      expect(
        result.timeline.events.whereType<PsdkBattleMoveFailedEvent>().single,
        isA<PsdkBattleMoveFailedEvent>()
            .having((event) => event.moveId, 'moveId', 'swallow')
            .having(
              (event) => event.reason,
              'reason',
              BattleMoveFailureReason.unusableByUser.jsonName,
            ),
      );
    });

    test('s_split_up scales damage from stockpile and clears the effect', () {
      final lowStockpile = _runMove(
        playerMove: _move(
          id: 'spit_up',
          type: 'normal',
          category: PsdkBattleMoveCategory.special,
          power: 0,
          accuracy: 100,
          battleEngineMethod: 's_split_up',
        ),
        playerStages: PsdkBattleStatStages(
          values: const <String, int>{
            'defense': 1,
            'specialDefense': 1,
          },
        ),
        playerEffects: const PsdkBattleEffectStack.empty().addEffect(
          StockpileEffect(
            scope: BattlerBattleEffectScope(psdkPlayerSlot),
            stockpile: 1,
            defenseBonus: 1,
            specialDefenseBonus: 1,
          ),
        ),
      );
      final highStockpile = _runMove(
        playerMove: _move(
          id: 'spit_up',
          type: 'normal',
          category: PsdkBattleMoveCategory.special,
          power: 0,
          accuracy: 100,
          battleEngineMethod: 's_split_up',
        ),
        playerStages: PsdkBattleStatStages(
          values: const <String, int>{
            'defense': 3,
            'specialDefense': 3,
          },
        ),
        playerEffects: const PsdkBattleEffectStack.empty().addEffect(
          StockpileEffect(
            scope: BattlerBattleEffectScope(psdkPlayerSlot),
            stockpile: 3,
            defenseBonus: 3,
            specialDefenseBonus: 3,
          ),
        ),
      );

      expect(_damage(highStockpile, moveId: 'spit_up'),
          greaterThan(_damage(lowStockpile, moveId: 'spit_up')));
      final player = highStockpile.state.battlerAt(psdkPlayerSlot);
      expect(player.effects.contains('stockpile'), isFalse);
      expect(player.statStages.valueOf('defense'), 0);
      expect(player.statStages.valueOf('specialDefense'), 0);
    });

    test('s_split_up fails without a usable stockpile effect', () {
      final result = _runMove(
        playerMove: _move(
          id: 'spit_up',
          type: 'normal',
          category: PsdkBattleMoveCategory.special,
          power: 0,
          accuracy: 100,
          battleEngineMethod: 's_split_up',
        ),
      );

      expect(
        result.timeline.events.whereType<PsdkBattleMoveFailedEvent>().single,
        isA<PsdkBattleMoveFailedEvent>()
            .having((event) => event.moveId, 'moveId', 'spit_up')
            .having(
              (event) => event.reason,
              'reason',
              BattleMoveFailureReason.unusableByUser.jsonName,
            ),
      );
    });

    test('s_geomancy uses the two-turn release boosts on its dedicated method',
        () {
      final engine = PsdkBattleEngine(
        setup: PsdkBattleSetup.singles(
          player: _combatant(
            id: 'player',
            types: const PsdkBattleTypes(primary: 'fairy'),
            speed: 100,
            move: _move(
              id: 'geomancy',
              type: 'fairy',
              category: PsdkBattleMoveCategory.status,
              power: 0,
              accuracy: 0,
              battleEngineMethod: 's_geomancy',
              target: PsdkBattleMoveTarget.self,
            ),
          ),
          opponent: _combatant(
            id: 'opponent',
            types: const PsdkBattleTypes(primary: 'normal'),
            speed: 1,
            move: _move(
              id: 'opponent_wait',
              power: 0,
              accuracy: 1,
            ),
          ),
          rngSeeds: const PsdkBattleRngSeeds(
            moveDamage: 1,
            moveCritical: 99999,
            moveAccuracy: 3,
            generic: 0,
          ),
        ),
      );

      final charge = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      final release =
          engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      final chargedPlayer = charge.state.battlerAt(psdkPlayerSlot);
      final player = release.state.battlerAt(psdkPlayerSlot);

      expect(chargedPlayer.effects.contains(PsdkBattleEffectIds.twoTurnCharge),
          isTrue);
      expect(chargedPlayer.statStages.valueOf('specialAttack'), 0);
      expect(chargedPlayer.statStages.valueOf('specialDefense'), 0);
      expect(chargedPlayer.statStages.valueOf('speed'), 0);
      expect(
          player.effects.contains(PsdkBattleEffectIds.twoTurnCharge), isFalse);
      expect(player.statStages.valueOf('specialAttack'), 2);
      expect(player.statStages.valueOf('specialDefense'), 2);
      expect(player.statStages.valueOf('speed'), 2);
    });

    test('s_core_enforcer suppresses abilities after a target already moved',
        () {
      final engine = PsdkBattleEngine(
        setup: PsdkBattleSetup.singles(
          player: _combatant(
            id: 'player',
            types: const PsdkBattleTypes(primary: 'dragon'),
            speed: 10,
            move: _move(
              id: 'core_enforcer',
              type: 'dragon',
              category: PsdkBattleMoveCategory.special,
              power: 100,
              accuracy: 100,
              battleEngineMethod: 's_core_enforcer',
            ),
          ),
          opponent: _combatant(
            id: 'opponent',
            types: const PsdkBattleTypes(primary: 'normal'),
            speed: 100,
            abilityId: 'levitate',
            move: _move(
              id: 'quick_attack',
              type: 'normal',
              category: PsdkBattleMoveCategory.physical,
              power: 40,
              accuracy: 100,
            ),
          ),
          rngSeeds: const PsdkBattleRngSeeds(
            moveDamage: 1,
            moveCritical: 99999,
            moveAccuracy: 3,
            generic: 0,
          ),
        ),
      );

      final result = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));

      expect(_damageEvents(result, moveId: 'core_enforcer'), hasLength(1));
      expect(
        result.state.battlerAt(psdkOpponentSlot).effects.contains(
              'ability_suppressed',
            ),
        isTrue,
      );
    });

    test('s_core_enforcer does not suppress abilities before the target acts',
        () {
      final result = _runMove(
        playerMove: _move(
          id: 'core_enforcer',
          type: 'dragon',
          category: PsdkBattleMoveCategory.special,
          power: 100,
          accuracy: 100,
          battleEngineMethod: 's_core_enforcer',
        ),
        opponentAbilityId: 'levitate',
      );

      expect(_damageEvents(result, moveId: 'core_enforcer'), hasLength(1));
      expect(
        result.state.battlerAt(psdkOpponentSlot).effects.contains(
              'ability_suppressed',
            ),
        isFalse,
      );
    });

    test('s_beat_up hits once per conscious status-free ally in the party', () {
      final result = _runMove(
        playerMove: _move(
          id: 'beat_up',
          category: PsdkBattleMoveCategory.physical,
          power: 1,
          battleEngineMethod: 's_beat_up',
        ),
        playerReserves: <PsdkBattleCombatantSetup>[
          _combatant(
            id: 'reserve-healthy',
            types: const PsdkBattleTypes(primary: 'normal'),
            speed: 40,
            currentHp: 100,
            move: _move(id: 'reserve_move_a', power: 40),
            stats: const PsdkBattleStats(
              attack: 255,
              defense: 50,
              specialAttack: 50,
              specialDefense: 50,
              speed: 40,
            ),
          ),
          _combatant(
            id: 'reserve-statused',
            types: const PsdkBattleTypes(primary: 'normal'),
            speed: 30,
            currentHp: 100,
            move: _move(id: 'reserve_move_b', power: 40),
            majorStatus: PsdkBattleMajorStatus.poison,
            stats: const PsdkBattleStats(
              attack: 120,
              defense: 50,
              specialAttack: 50,
              specialDefense: 50,
              speed: 30,
            ),
          ),
          _combatant(
            id: 'reserve-fainted',
            types: const PsdkBattleTypes(primary: 'normal'),
            speed: 20,
            currentHp: 0,
            move: _move(id: 'reserve_move_c', power: 40),
            stats: const PsdkBattleStats(
              attack: 150,
              defense: 50,
              specialAttack: 50,
              specialDefense: 50,
              speed: 20,
            ),
          ),
        ],
        playerStats: const PsdkBattleStats(
          attack: 1,
          defense: 50,
          specialAttack: 50,
          specialDefense: 50,
          speed: 100,
        ),
      );
      final baseline = _runMove(
        playerMove: _move(
          id: 'beat_up',
          category: PsdkBattleMoveCategory.physical,
          power: 1,
          battleEngineMethod: 's_beat_up',
        ),
        playerReserves: <PsdkBattleCombatantSetup>[
          _combatant(
            id: 'reserve-statused',
            types: const PsdkBattleTypes(primary: 'normal'),
            speed: 30,
            currentHp: 100,
            move: _move(id: 'reserve_move_b', power: 40),
            majorStatus: PsdkBattleMajorStatus.poison,
            stats: const PsdkBattleStats(
              attack: 120,
              defense: 50,
              specialAttack: 50,
              specialDefense: 50,
              speed: 30,
            ),
          ),
          _combatant(
            id: 'reserve-fainted',
            types: const PsdkBattleTypes(primary: 'normal'),
            speed: 20,
            currentHp: 0,
            move: _move(id: 'reserve_move_c', power: 40),
            stats: const PsdkBattleStats(
              attack: 150,
              defense: 50,
              specialAttack: 50,
              specialDefense: 50,
              speed: 20,
            ),
          ),
        ],
        playerStats: const PsdkBattleStats(
          attack: 1,
          defense: 50,
          specialAttack: 50,
          specialDefense: 50,
          speed: 100,
        ),
      );

      final hits = _damageEvents(result, moveId: 'beat_up');
      final baselineHits = _damageEvents(baseline, moveId: 'beat_up');

      expect(hits, hasLength(2));
      expect(baselineHits, hasLength(1));
      expect(
        hits.fold<int>(0, (sum, event) => sum + event.damage),
        greaterThan(
          baselineHits.fold<int>(0, (sum, event) => sum + event.damage),
        ),
      );
    });

    test('s_payday credits bonus money after a successful hit', () {
      final result = _runMove(
        playerMove: _move(
          id: 'pay_day',
          type: 'normal',
          category: PsdkBattleMoveCategory.physical,
          power: 40,
          battleEngineMethod: 's_payday',
        ),
      );

      expect(_damageEvents(result, moveId: 'pay_day'), hasLength(1));
      expect(result.state.field.additionalMoney, 100);
    });

    test('s_return scales damage with high loyalty', () {
      final lowLoyalty = _runMove(
        playerMove: _move(
          id: 'return',
          type: 'normal',
          category: PsdkBattleMoveCategory.physical,
          power: 1,
          battleEngineMethod: 's_return',
        ),
        playerLoyalty: 0,
      );
      final highLoyalty = _runMove(
        playerMove: _move(
          id: 'return',
          type: 'normal',
          category: PsdkBattleMoveCategory.physical,
          power: 1,
          battleEngineMethod: 's_return',
        ),
        playerLoyalty: 255,
      );

      expect(_damageEvents(lowLoyalty, moveId: 'return'), hasLength(1));
      expect(_damageEvents(highLoyalty, moveId: 'return'), hasLength(1));
      expect(
        _damage(highLoyalty, moveId: 'return'),
        greaterThan(_damage(lowLoyalty, moveId: 'return')),
      );
    });

    test('s_hidden_power uses the user IV parity to derive its type', () {
      final fireTyped = _runMove(
        playerMove: _move(
          id: 'hidden_power',
          type: 'normal',
          category: PsdkBattleMoveCategory.special,
          power: 60,
          battleEngineMethod: 's_hidden_power',
        ),
        opponentTypes: const PsdkBattleTypes(primary: 'grass'),
        playerIvAttack: 1,
        playerIvSpecialDefense: 1,
      );
      final neutralTyped = _runMove(
        playerMove: _move(
          id: 'hidden_power',
          type: 'normal',
          category: PsdkBattleMoveCategory.special,
          power: 60,
          battleEngineMethod: 's_hidden_power',
        ),
        opponentTypes: const PsdkBattleTypes(primary: 'grass'),
      );

      expect(_damageEvents(fireTyped, moveId: 'hidden_power'), hasLength(1));
      expect(_damageEvents(neutralTyped, moveId: 'hidden_power'), hasLength(1));
      expect(
        _damage(fireTyped, moveId: 'hidden_power'),
        greaterThan(_damage(neutralTyped, moveId: 'hidden_power')),
      );
    });

    test('s_aura_wheel uses Morpeko form to derive its type', () {
      final electric = _runMove(
        playerMove: _move(
          id: 'aura_wheel',
          type: 'electric',
          category: PsdkBattleMoveCategory.physical,
          power: 110,
          battleEngineMethod: 's_aura_wheel',
        ),
        opponentTypes: const PsdkBattleTypes(primary: 'water'),
        playerSpeciesId: 'morpeko',
        playerForm: 0,
      );
      final dark = _runMove(
        playerMove: _move(
          id: 'aura_wheel',
          type: 'electric',
          category: PsdkBattleMoveCategory.physical,
          power: 110,
          battleEngineMethod: 's_aura_wheel',
        ),
        opponentTypes: const PsdkBattleTypes(primary: 'water'),
        playerSpeciesId: 'morpeko',
        playerForm: 1,
      );

      expect(_damageEvents(electric, moveId: 'aura_wheel'), hasLength(1));
      expect(_damageEvents(dark, moveId: 'aura_wheel'), hasLength(1));
      expect(
        _damage(electric, moveId: 'aura_wheel'),
        greaterThan(_damage(dark, moveId: 'aura_wheel')),
      );
    });

    test('s_upper_hand succeeds against an announced damaging priority move',
        () {
      final result = _runMove(
        playerMove: _move(
          id: 'upper_hand',
          type: 'fighting',
          category: PsdkBattleMoveCategory.physical,
          power: 65,
          battleEngineMethod: 's_upper_hand',
          priority: 3,
        ),
        opponentMove: _move(
          id: 'quick_attack',
          type: 'normal',
          category: PsdkBattleMoveCategory.physical,
          power: 40,
          battleEngineMethod: 's_basic',
          priority: 1,
        ),
        playerSpeed: 100,
        opponentSpeed: 10,
      );

      expect(_damageEvents(result, moveId: 'upper_hand'), hasLength(1));
      expect(
        result.timeline.events.whereType<PsdkBattleEffectEvent>().where(
              (event) =>
                  event.action == 'added' &&
                  event.effectId == 'flinch' &&
                  event.target == psdkOpponentSlot,
            ),
        isNotEmpty,
      );
      expect(
        result.timeline.events
            .whereType<PsdkBattleMoveFailedEvent>()
            .where((event) => event.moveId == 'upper_hand'),
        isEmpty,
      );
    });

    test('s_upper_hand fails when the target is not using a priority attack',
        () {
      final result = _runMove(
        playerMove: _move(
          id: 'upper_hand',
          type: 'fighting',
          category: PsdkBattleMoveCategory.physical,
          power: 65,
          battleEngineMethod: 's_upper_hand',
          priority: 3,
        ),
        opponentMove: _move(
          id: 'tackle',
          type: 'normal',
          category: PsdkBattleMoveCategory.physical,
          power: 40,
          battleEngineMethod: 's_basic',
        ),
        playerSpeed: 100,
        opponentSpeed: 10,
      );

      expect(_damageEvents(result, moveId: 'upper_hand'), isEmpty);
      expect(
        result.timeline.events
            .whereType<PsdkBattleMoveFailedEvent>()
            .singleWhere((event) => event.moveId == 'upper_hand')
            .reason,
        'unusable_by_user',
      );
    });

    test('s_order_up boosts the user with its commanding Tatsugiri ally form',
        () {
      final move = _move(
        id: 'order_up',
        type: 'dragon',
        category: PsdkBattleMoveCategory.physical,
        power: 80,
        battleEngineMethod: 's_order_up',
      );
      final state = PsdkBattleState(
        combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
          psdkPlayerSlot: PsdkBattleCombatant.fromSetup(
            _combatant(
              id: 'player',
              types: const PsdkBattleTypes(primary: 'water'),
              speed: 100,
              move: move,
              speciesId: 'dondozo',
              effects: PsdkBattleEffectStack.empty().addEffect(
                GenericBattleEffect(
                  id: 'commanded',
                  scope: const BattlerBattleEffectScope(psdkPlayerSlot),
                ),
              ),
            ),
          ),
          const PsdkBattleSlotRef(bank: 0, position: 1):
              PsdkBattleCombatant.fromSetup(
            _combatant(
              id: 'ally',
              types: const PsdkBattleTypes(primary: 'dragon'),
              speed: 50,
              move: _move(id: 'ally_wait', power: 0, accuracy: 0),
              speciesId: 'tatsugiri',
              form: 2,
              effects: PsdkBattleEffectStack.empty().addEffect(
                GenericBattleEffect(
                  id: 'commanding',
                  scope: const BattlerBattleEffectScope(
                    PsdkBattleSlotRef(bank: 0, position: 1),
                  ),
                ),
              ),
            ),
          ),
          psdkOpponentSlot: PsdkBattleCombatant.fromSetup(
            _combatant(
              id: 'opponent',
              types: const PsdkBattleTypes(primary: 'normal'),
              speed: 10,
              move: _move(id: 'opponent_wait', power: 0, accuracy: 0),
            ),
          ),
        },
        parties: <int, List<PsdkBattleCombatant>>{
          0: <PsdkBattleCombatant>[
            PsdkBattleCombatant.fromSetup(
              _combatant(
                id: 'player',
                types: const PsdkBattleTypes(primary: 'water'),
                speed: 100,
                move: move,
                speciesId: 'dondozo',
                effects: PsdkBattleEffectStack.empty().addEffect(
                  GenericBattleEffect(
                    id: 'commanded',
                    scope: const BattlerBattleEffectScope(psdkPlayerSlot),
                  ),
                ),
              ),
            ),
            PsdkBattleCombatant.fromSetup(
              _combatant(
                id: 'ally',
                types: const PsdkBattleTypes(primary: 'dragon'),
                speed: 50,
                move: _move(id: 'ally_wait', power: 0, accuracy: 0),
                speciesId: 'tatsugiri',
                form: 2,
                effects: PsdkBattleEffectStack.empty().addEffect(
                  GenericBattleEffect(
                    id: 'commanding',
                    scope: const BattlerBattleEffectScope(
                      PsdkBattleSlotRef(bank: 0, position: 1),
                    ),
                  ),
                ),
              ),
            ),
          ],
          1: <PsdkBattleCombatant>[
            PsdkBattleCombatant.fromSetup(
              _combatant(
                id: 'opponent',
                types: const PsdkBattleTypes(primary: 'normal'),
                speed: 10,
                move: _move(id: 'opponent_wait', power: 0, accuracy: 0),
              ),
            ),
          ],
        },
      );

      final result = _resolveMoveOnState(move: move, state: state);

      expect(_damageEventsFrom(result, moveId: 'order_up'), hasLength(1));
      expect(
        result.state.battlerAt(psdkPlayerSlot).statStages.valueOf('speed'),
        1,
      );
    });

    test('s_dragon_darts hits the same target twice in singles', () {
      final move = _dragonDartsMove();
      final result = _resolveMoveOnState(
        move: move,
        state: _dragonDartsState(move: move),
      );

      expect(
        _damageEventsFrom(result, moveId: 'dragon_darts')
            .map((event) => event.target),
        <PsdkBattleSlotRef>[
          psdkOpponentSlot,
          psdkOpponentSlot,
        ],
      );
      expect(result.state.battlerAt(psdkOpponentSlot).currentHp, lessThan(100));
    });

    test('s_dragon_darts splits darts across the selected foe and one ally',
        () {
      final move = _dragonDartsMove();
      const opponentAlly = PsdkBattleSlotRef(bank: 1, position: 1);
      final result = _resolveMoveOnState(
        move: move,
        state: _dragonDartsState(
          move: move,
          opponentAllySlots: const <PsdkBattleSlotRef>[opponentAlly],
        ),
      );

      expect(
        _damageEventsFrom(result, moveId: 'dragon_darts')
            .map((event) => event.target),
        <PsdkBattleSlotRef>[
          psdkOpponentSlot,
          opponentAlly,
        ],
      );
    });

    test('s_dragon_darts samples one foe ally deterministically', () {
      final move = _dragonDartsMove();
      const firstAlly = PsdkBattleSlotRef(bank: 1, position: 1);
      const secondAlly = PsdkBattleSlotRef(bank: 1, position: 2);
      final result = _resolveMoveOnState(
        move: move,
        state: _dragonDartsState(
          move: move,
          opponentAllySlots: const <PsdkBattleSlotRef>[
            firstAlly,
            secondAlly,
          ],
        ),
      );

      expect(
        _damageEventsFrom(result, moveId: 'dragon_darts')
            .map((event) => event.target),
        <PsdkBattleSlotRef>[
          psdkOpponentSlot,
          firstAlly,
        ],
      );
      expect(result.state.battlerAt(secondAlly).currentHp, 100);
    });

    test('s_dragon_darts keeps both darts on center-of-attention targets', () {
      final move = _dragonDartsMove();
      const opponentAlly = PsdkBattleSlotRef(bank: 1, position: 1);
      final result = _resolveMoveOnState(
        move: move,
        state: _dragonDartsState(
          move: move,
          opponentEffects: const PsdkBattleEffectStack.empty().addEffect(
            GenericBattleEffect(
              id: PsdkBattleEffectIds.centerOfAttention,
              scope: BattlerBattleEffectScope(psdkOpponentSlot),
            ),
          ),
          opponentAllySlots: const <PsdkBattleSlotRef>[opponentAlly],
        ),
      );

      expect(
        _damageEventsFrom(result, moveId: 'dragon_darts')
            .map((event) => event.target),
        <PsdkBattleSlotRef>[
          psdkOpponentSlot,
          psdkOpponentSlot,
        ],
      );
      expect(result.state.battlerAt(opponentAlly).currentHp, 100);
    });

    test('s_dragon_darts falls back to an ally of an invalid foe target', () {
      final move = _dragonDartsMove();
      const opponentAlly = PsdkBattleSlotRef(bank: 1, position: 1);
      final result = _resolveMoveOnState(
        move: move,
        state: _dragonDartsState(
          move: move,
          opponentHp: 0,
          opponentAllySlots: const <PsdkBattleSlotRef>[opponentAlly],
        ),
      );

      expect(
        _damageEventsFrom(result, moveId: 'dragon_darts')
            .map((event) => event.target),
        <PsdkBattleSlotRef>[
          opponentAlly,
          opponentAlly,
        ],
      );
    });

    test('s_dragon_darts prechecks Protect before the split ally dart', () {
      final move = _dragonDartsMove();
      const opponentAlly = PsdkBattleSlotRef(bank: 1, position: 1);
      final result = _resolveMoveOnState(
        move: move,
        state: _dragonDartsState(
          move: move,
          opponentAllyEffects: <PsdkBattleSlotRef, PsdkBattleEffectStack>{
            opponentAlly: PsdkBattleEffectStack.empty().addEffect(
              const ProtectEffect(
                scope: BattlerBattleEffectScope(opponentAlly),
              ),
            ),
          },
          opponentAllySlots: const <PsdkBattleSlotRef>[opponentAlly],
        ),
      );

      expect(
        _damageEventsFrom(result, moveId: 'dragon_darts')
            .map((event) => event.target),
        <PsdkBattleSlotRef>[psdkOpponentSlot],
      );
      expect(result.state.battlerAt(opponentAlly).currentHp, 100);
      final failures = result.events.whereType<PsdkBattleMoveFailedEvent>();
      expect(failures, hasLength(1));
      expect(failures.single.target, opponentAlly);
      expect(
          failures.single.reason, BattleMoveFailureReason.protected.jsonName);
    });

    test('s_dragon_darts can fallback after the selected foe is missed', () {
      final move = _dragonDartsMove().copyWith(accuracy: 50);
      const opponentAlly = PsdkBattleSlotRef(bank: 1, position: 1);
      final result = _resolveMoveOnState(
        move: move,
        moveAccuracySeed: 53,
        state: _dragonDartsState(
          move: move,
          opponentAllySlots: const <PsdkBattleSlotRef>[opponentAlly],
        ),
      );

      expect(
        _damageEventsFrom(result, moveId: 'dragon_darts')
            .map((event) => event.target),
        <PsdkBattleSlotRef>[opponentAlly, psdkOpponentSlot],
      );
    });

    test('s_dragon_darts skips the second dart when the target is fainted', () {
      final move = _dragonDartsMove();
      final result = _resolveMoveOnState(
        move: move,
        state: _dragonDartsState(move: move, opponentHp: 1),
      );

      expect(_damageEventsFrom(result, moveId: 'dragon_darts'), hasLength(1));
      expect(result.state.battlerAt(psdkOpponentSlot).isFainted, isTrue);
    });

    test('s_frustration scales damage with low loyalty', () {
      final lowLoyalty = _runMove(
        playerMove: _move(
          id: 'frustration',
          type: 'normal',
          category: PsdkBattleMoveCategory.physical,
          power: 1,
          battleEngineMethod: 's_frustration',
        ),
        playerLoyalty: 0,
      );
      final highLoyalty = _runMove(
        playerMove: _move(
          id: 'frustration',
          type: 'normal',
          category: PsdkBattleMoveCategory.physical,
          power: 1,
          battleEngineMethod: 's_frustration',
        ),
        playerLoyalty: 255,
      );

      expect(_damageEvents(lowLoyalty, moveId: 'frustration'), hasLength(1));
      expect(_damageEvents(highLoyalty, moveId: 'frustration'), hasLength(1));
      expect(
        _damage(lowLoyalty, moveId: 'frustration'),
        greaterThan(_damage(highLoyalty, moveId: 'frustration')),
      );
    });

    for (final entry in <({String method, String moveId})>[
      (method: 's_after_you', moveId: 'after_you'),
    ]) {
      test('${entry.method} executes as a turn-scoped battler marker slice',
          () {
        final result = _runMove(
          playerMove: _move(
            id: entry.moveId,
            category: PsdkBattleMoveCategory.status,
            power: 0,
            accuracy: 0,
            battleEngineMethod: entry.method,
            target: entry.method == 's_after_you'
                ? PsdkBattleMoveTarget.adjacentFoe
                : PsdkBattleMoveTarget.self,
          ),
        );

        expect(
          result.timeline.events.whereType<PsdkBattleMoveFailedEvent>(),
          isEmpty,
        );
      });
    }

    test('s_magic_coat fails when the user would act last', () {
      final result = _runMove(
        playerSpeed: 1,
        opponentSpeed: 100,
        playerMove: _move(
          id: 'magic_coat',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 0,
          battleEngineMethod: 's_magic_coat',
          target: PsdkBattleMoveTarget.self,
        ),
      );

      expect(
        result.timeline.events.whereType<PsdkBattleMoveFailedEvent>().where(
              (event) => event.moveId == 'magic_coat',
            ),
        hasLength(1),
      );
      expect(
        result.state.battlerAt(psdkPlayerSlot).effects.contains('magic_coat'),
        isFalse,
      );
    });

    test('s_magic_coat reflects marked status moves back to the launcher', () {
      final result = _runMove(
        playerSpeed: 1,
        opponentSpeed: 100,
        playerMove: _move(
          id: 'magic_coat',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 0,
          priority: 4,
          battleEngineMethod: 's_magic_coat',
          target: PsdkBattleMoveTarget.self,
        ),
        opponentMove: _move(
          id: 'growl',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          battleEngineMethod: 's_stat',
          target: PsdkBattleMoveTarget.adjacentFoe,
          magicCoatAffected: true,
          effectChance: 100,
          stageMods: const <PsdkBattleMoveStageMod>[
            PsdkBattleMoveStageMod(stat: 'attack', stages: -1),
          ],
        ),
      );

      expect(
        result.state.battlerAt(psdkPlayerSlot).statStages.valueOf('attack'),
        0,
      );
      expect(
        result.state.battlerAt(psdkOpponentSlot).statStages.valueOf('attack'),
        -1,
      );
      expect(
        result.timeline.events
            .whereType<PsdkBattleStatStageEvent>()
            .single
            .target,
        psdkOpponentSlot,
      );
    });

    test('s_snatch steals a later snatchable self-stat move', () {
      final result = _runMove(
        playerSpeed: 1,
        opponentSpeed: 100,
        playerMove: _move(
          id: 'snatch',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 0,
          priority: 4,
          battleEngineMethod: 's_snatch',
          target: PsdkBattleMoveTarget.self,
        ),
        opponentMove: _move(
          id: 'swords_dance',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          battleEngineMethod: 's_self_stat',
          target: PsdkBattleMoveTarget.self,
          snatchable: true,
          effectChance: 100,
          stageMods: const <PsdkBattleMoveStageMod>[
            PsdkBattleMoveStageMod(stat: 'attack', stages: 2),
          ],
        ),
      );

      expect(
        result.state.battlerAt(psdkPlayerSlot).statStages.valueOf('attack'),
        2,
      );
      expect(
        result.state.battlerAt(psdkOpponentSlot).statStages.valueOf('attack'),
        0,
      );
      expect(
        result.timeline.events
            .whereType<PsdkBattleEffectEvent>()
            .where((event) => event.effectId == 'snatched'),
        hasLength(1),
      );
    });

    test('s_crafty_shield executes as a turn-scoped user-bank marker slice',
        () {
      final result = _runMove(
        playerMove: _move(
          id: 'crafty_shield',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 0,
          battleEngineMethod: 's_crafty_shield',
          target: PsdkBattleMoveTarget.allAllies,
        ),
      );

      expect(
        result.timeline.events.whereType<PsdkBattleMoveFailedEvent>(),
        isEmpty,
      );
    });

    test('s_captivate applies its imported Special Attack drop without damage',
        () {
      final result = _runMove(
        playerMove: _move(
          id: 'captivate',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 100,
          battleEngineMethod: 's_captivate',
          target: PsdkBattleMoveTarget.allAdjacentFoes,
          stageMods: const <PsdkBattleMoveStageMod>[
            PsdkBattleMoveStageMod(
              stat: 'specialAttack',
              stages: -2,
              chance: 100,
            ),
          ],
        ),
      );

      expect(_damageEvents(result, moveId: 'captivate'), isEmpty);
      expect(
        result.state
            .battlerAt(psdkOpponentSlot)
            .statStages
            .valueOf('specialAttack'),
        -2,
      );
    });

    test('s_parting_shot applies imported offensive drops without damage', () {
      final result = _runMove(
        playerMove: _move(
          id: 'parting_shot',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 100,
          battleEngineMethod: 's_parting_shot',
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
      );

      final opponent = result.state.battlerAt(psdkOpponentSlot);
      expect(_damageEvents(result, moveId: 'parting_shot'), isEmpty);
      expect(opponent.statStages.valueOf('attack'), -1);
      expect(opponent.statStages.valueOf('specialAttack'), -1);
    });

    test('s_struggle deals damage and recoils from user max HP', () {
      final result = _runMove(
        playerMove: _move(
          id: 'struggle',
          power: 50,
          accuracy: 0,
          battleEngineMethod: 's_struggle',
        ),
      );

      final damage = _damageEvents(result, moveId: 'struggle');
      expect(damage, hasLength(2));
      expect(damage.first.target, psdkOpponentSlot);
      expect(damage.last.target, psdkPlayerSlot);
      expect(damage.last.damage, 25);
      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 75);
    });

    for (final entry in <({String method, String moveId})>[
      (method: 's_lock_on', moveId: 'lock_on'),
      (method: 's_mind_reader', moveId: 'mind_reader'),
    ]) {
      test('${entry.method} installs a local lock-on marker on the user', () {
        final result = _runMove(
          playerMove: _move(
            id: entry.moveId,
            category: PsdkBattleMoveCategory.status,
            power: 0,
            accuracy: 0,
            battleEngineMethod: entry.method,
          ),
        );

        expect(
          result.state.battlerAt(psdkPlayerSlot).effects.contains('lock_on'),
          isTrue,
        );
      });
    }

    test('s_entrainment copies the user ability to the target', () {
      final result = _runMove(
        playerAbilityId: 'blaze',
        opponentAbilityId: 'overgrow',
        playerMove: _move(
          id: 'entrainment',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 100,
          battleEngineMethod: 's_entrainment',
        ),
      );

      expect(result.state.battlerAt(psdkOpponentSlot).abilityId, 'blaze');
    });

    test('s_doodle copies the target ability onto every same-bank battler', () {
      final allySlot = const PsdkBattleSlotRef(bank: 0, position: 1);
      final result = _resolveMoveOnState(
        move: _move(
          id: 'doodle',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 100,
          battleEngineMethod: 's_doodle',
        ),
        state: PsdkBattleState(
          combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
            psdkPlayerSlot: PsdkBattleCombatant.fromSetup(
              _combatant(
                id: 'player',
                types: const PsdkBattleTypes(primary: 'normal'),
                speed: 100,
                move: _move(
                  id: 'doodle',
                  category: PsdkBattleMoveCategory.status,
                  power: 0,
                  accuracy: 100,
                  battleEngineMethod: 's_doodle',
                ),
                abilityId: 'blaze',
              ),
            ),
            allySlot: PsdkBattleCombatant.fromSetup(
              _combatant(
                id: 'ally',
                types: const PsdkBattleTypes(primary: 'normal'),
                speed: 90,
                move: _move(id: 'ally_wait', power: 0, accuracy: 1),
                abilityId: 'torrent',
              ),
            ),
            psdkOpponentSlot: PsdkBattleCombatant.fromSetup(
              _combatant(
                id: 'opponent',
                types: const PsdkBattleTypes(primary: 'normal'),
                speed: 10,
                move: _move(id: 'opponent_wait', power: 0, accuracy: 1),
                abilityId: 'levitate',
              ),
            ),
          },
        ),
      );

      expect(result.state.battlerAt(psdkPlayerSlot).abilityId, 'levitate');
      expect(result.state.battlerAt(allySlot).abilityId, 'levitate');
      expect(result.state.battlerAt(psdkOpponentSlot).abilityId, 'levitate');
      expect(result.events.whereType<PsdkBattleMoveFailedEvent>(), isEmpty);
    });

    test('s_doodle fails when no same-bank battler can copy the target ability',
        () {
      final allySlot = const PsdkBattleSlotRef(bank: 0, position: 1);
      final result = _resolveMoveOnState(
        move: _move(
          id: 'doodle',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 100,
          battleEngineMethod: 's_doodle',
        ),
        state: PsdkBattleState(
          combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
            psdkPlayerSlot: PsdkBattleCombatant.fromSetup(
              _combatant(
                id: 'player',
                types: const PsdkBattleTypes(primary: 'normal'),
                speed: 100,
                move: _move(
                  id: 'doodle',
                  category: PsdkBattleMoveCategory.status,
                  power: 0,
                  accuracy: 100,
                  battleEngineMethod: 's_doodle',
                ),
                abilityId: 'levitate',
              ),
            ),
            allySlot: PsdkBattleCombatant.fromSetup(
              _combatant(
                id: 'ally',
                types: const PsdkBattleTypes(primary: 'normal'),
                speed: 90,
                move: _move(id: 'ally_wait', power: 0, accuracy: 1),
                abilityId: 'levitate',
              ),
            ),
            psdkOpponentSlot: PsdkBattleCombatant.fromSetup(
              _combatant(
                id: 'opponent',
                types: const PsdkBattleTypes(primary: 'normal'),
                speed: 10,
                move: _move(id: 'opponent_wait', power: 0, accuracy: 1),
                abilityId: 'levitate',
              ),
            ),
          },
        ),
      );

      expect(
        result.events.whereType<PsdkBattleMoveFailedEvent>().single.reason,
        BattleMoveFailureReason.unusableByUser.jsonName,
      );
      expect(result.state.battlerAt(psdkPlayerSlot).abilityId, 'levitate');
      expect(result.state.battlerAt(allySlot).abilityId, 'levitate');
    });

    test('s_memento applies imported offensive drops then knocks out user', () {
      final result = _runMove(
        playerMove: _move(
          id: 'memento',
          type: 'dark',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 100,
          battleEngineMethod: 's_memento',
          stageMods: const <PsdkBattleMoveStageMod>[
            PsdkBattleMoveStageMod(
              stat: 'attack',
              stages: -2,
              chance: 100,
            ),
            PsdkBattleMoveStageMod(
              stat: 'specialAttack',
              stages: -2,
              chance: 100,
            ),
          ],
        ),
      );

      final opponent = result.state.battlerAt(psdkOpponentSlot);
      expect(opponent.statStages.valueOf('attack'), -2);
      expect(opponent.statStages.valueOf('specialAttack'), -2);
      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 0);
    });

    for (final entry in <({String method, String moveId, String effectId})>[
      (method: 's_attract', moveId: 'attract', effectId: 'attract'),
      (method: 's_imprison', moveId: 'imprison', effectId: 'imprison'),
      (method: 's_nightmare', moveId: 'nightmare', effectId: 'nightmare'),
    ]) {
      test('${entry.method} installs a local target marker', () {
        final result = _runMove(
          playerGender: entry.method == 's_attract'
              ? PsdkBattleGender.male
              : PsdkBattleGender.unknown,
          opponentGender: entry.method == 's_attract'
              ? PsdkBattleGender.female
              : PsdkBattleGender.unknown,
          playerMove: _move(
            id: entry.moveId,
            category: PsdkBattleMoveCategory.status,
            power: 0,
            accuracy: 100,
            battleEngineMethod: entry.method,
          ),
        );

        expect(
          result.state
              .battlerAt(psdkOpponentSlot)
              .effects
              .contains(entry.effectId),
          isTrue,
        );
      });
    }

    for (final entry in <({String method, String moveId, String effectId})>[
      (method: 's_gravity', moveId: 'gravity', effectId: 'gravity'),
      (method: 's_happy_hour', moveId: 'happy_hour', effectId: 'happy_hour'),
    ]) {
      test('${entry.method} installs a local field marker', () {
        final result = _runMove(
          playerMove: _move(
            id: entry.moveId,
            category: PsdkBattleMoveCategory.status,
            power: 0,
            accuracy: 0,
            battleEngineMethod: entry.method,
            target: PsdkBattleMoveTarget.none,
          ),
        );

        expect(
          result.state
              .battlerAt(psdkPlayerSlot)
              .effects
              .contains(entry.effectId),
          isTrue,
        );
      });
    }

    test('s_gravity fails when gravity is already active on the field', () {
      final result = _runMove(
        playerEffects: const PsdkBattleEffectStack.empty().addEffect(
          GenericBattleEffect(
            id: 'gravity',
            scope: FieldBattleEffectScope(),
            remainingTurns: 5,
          ),
        ),
        playerMove: _move(
          id: 'gravity',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 0,
          battleEngineMethod: 's_gravity',
          target: PsdkBattleMoveTarget.none,
        ),
      );

      expect(
        result.timeline.events
            .whereType<PsdkBattleMoveFailedEvent>()
            .single
            .reason,
        'gravity_already_active',
      );
    });

    test('s_magic_room suppresses opposing held item effects battle-wide', () {
      final result = _runMove(
        playerMove: _move(
          id: 'magic_room',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 0,
          battleEngineMethod: 's_magic_room',
          target: PsdkBattleMoveTarget.none,
        ),
        opponentHeldItemId: 'loaded_dice',
        opponentCurrentHp: 200,
        opponentMove: _move(
          id: 'double_slap',
          power: 25,
          battleEngineMethod: 's_multi_hit',
        ),
      );

      expect(
        result.state.battlerAt(psdkPlayerSlot).effects.contains('magic_room'),
        isTrue,
      );
      expect(_damageEvents(result, moveId: 'double_slap'), hasLength(2));
    });

    test('s_substitute consumes one quarter of user HP and installs a marker',
        () {
      final result = _runMove(
        playerMove: _move(
          id: 'substitute',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 0,
          battleEngineMethod: 's_substitute',
          target: PsdkBattleMoveTarget.self,
        ),
      );

      final player = result.state.battlerAt(psdkPlayerSlot);
      expect(player.currentHp, 75);
      expect(player.effects.contains('substitute'), isTrue);
      expect(_damageEvents(result, moveId: 'substitute'), hasLength(1));
    });

    test('s_sky_drop charges first then strikes on the next submission', () {
      final engine = PsdkBattleEngine(
        setup: PsdkBattleSetup.singles(
          player: _combatant(
            id: 'player',
            types: const PsdkBattleTypes(primary: 'flying'),
            speed: 100,
            move: _move(
              id: 'sky_drop',
              type: 'flying',
              category: PsdkBattleMoveCategory.physical,
              power: 60,
              battleEngineMethod: 's_sky_drop',
            ),
          ),
          opponent: _combatant(
            id: 'opponent',
            types: const PsdkBattleTypes(primary: 'normal'),
            speed: 1,
            move: _move(
              id: 'opponent_wait',
              power: 0,
              accuracy: 1,
            ),
          ),
          rngSeeds: const PsdkBattleRngSeeds(
            moveDamage: 1,
            moveCritical: 99999,
            moveAccuracy: 3,
            generic: 0,
          ),
        ),
      );

      final first = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      expect(_damageEvents(first, moveId: 'sky_drop'), isEmpty);

      final second = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      expect(_damageEvents(second, moveId: 'sky_drop'), hasLength(1));
    });

    test('s_rage deals damage and installs the Rage marker on the user', () {
      final result = _runMove(
        playerMove: _move(
          id: 'rage',
          power: 20,
          battleEngineMethod: 's_rage',
        ),
      );

      expect(_damageEvents(result, moveId: 'rage'), hasLength(1));
      expect(
        result.state.battlerAt(psdkPlayerSlot).effects.contains('rage'),
        isTrue,
      );
    });

    test('s_glaive_rush deals damage and installs its marker on the user', () {
      final result = _runMove(
        playerMove: _move(
          id: 'glaive_rush',
          type: 'dragon',
          power: 120,
          battleEngineMethod: 's_glaive_rush',
        ),
      );

      expect(_damageEvents(result, moveId: 'glaive_rush'), hasLength(1));
      expect(
        result.state.battlerAt(psdkPlayerSlot).effects.contains('glaive_rush'),
        isTrue,
      );
    });

    test('s_glaive_rush doubles incoming damage while its marker is active',
        () {
      final normalIncoming = _runMove(
        playerMove: _move(id: 'basic_hit', power: 40),
        opponentMove: _move(id: 'opponent_tackle', power: 40),
      );
      final glaiveIncoming = _runMove(
        playerMove: _move(
          id: 'glaive_rush',
          type: 'dragon',
          power: 120,
          battleEngineMethod: 's_glaive_rush',
        ),
        opponentMove: _move(id: 'opponent_tackle', power: 40),
      );

      final normalDamage =
          _damageEvents(normalIncoming, moveId: 'opponent_tackle')
              .single
              .damage;
      final glaiveDamage =
          _damageEvents(glaiveIncoming, moveId: 'opponent_tackle')
              .single
              .damage;
      expect(glaiveDamage, normalDamage * 2);
    });

    test('s_fickle_beam can double its base power after accuracy', () {
      final regular = _runMove(
        playerMove: _move(
          id: 'fickle_beam',
          power: 80,
          battleEngineMethod: 's_fickle_beam',
        ),
        genericSeed: 30,
      );
      final empowered = _runMove(
        playerMove: _move(
          id: 'fickle_beam',
          power: 80,
          battleEngineMethod: 's_fickle_beam',
        ),
        genericSeed: 0,
      );

      final regularDamage =
          _damageEvents(regular, moveId: 'fickle_beam').single.damage;
      final empoweredDamage =
          _damageEvents(empowered, moveId: 'fickle_beam').single.damage;
      expect(empoweredDamage, greaterThan(regularDamage));
    });

    test('s_super_duper_effective boosts super-effective damage', () {
      final regular = _runMove(
        playerMove: _move(
          id: 'electric_hit',
          type: 'electric',
          power: 80,
        ),
        opponentTypes: const PsdkBattleTypes(primary: 'water'),
      );
      final boosted = _runMove(
        playerMove: _move(
          id: 'super_duper_effective',
          type: 'electric',
          power: 80,
          battleEngineMethod: 's_super_duper_effective',
        ),
        opponentTypes: const PsdkBattleTypes(primary: 'water'),
      );

      final regularDamage =
          _damageEvents(regular, moveId: 'electric_hit').single.damage;
      final boostedDamage =
          _damageEvents(boosted, moveId: 'super_duper_effective').single.damage;
      expect(boostedDamage, greaterThan(regularDamage));
    });

    test('s_present can roll a 120-power damage branch', () {
      final regular = _runMove(
        playerMove: _move(
          id: 'normal_hit',
          power: 80,
        ),
      );
      final present = _runMove(
        playerMove: _move(
          id: 'present',
          power: 1,
          battleEngineMethod: 's_present',
        ),
        genericSeed: 79,
      );

      final regularDamage =
          _damageEvents(regular, moveId: 'normal_hit').single.damage;
      final presentDamage =
          _damageEvents(present, moveId: 'present').single.damage;
      expect(presentDamage, greaterThan(regularDamage));
    });

    test('s_present can heal the target for a quarter of max HP', () {
      final result = _runMove(
        playerMove: _move(
          id: 'present',
          power: 1,
          battleEngineMethod: 's_present',
        ),
        opponentCurrentHp: 50,
        genericSeed: 80,
      );

      final opponent = result.state.battlerAt(psdkOpponentSlot);
      expect(_damageEvents(result, moveId: 'present'), isEmpty);
      expect(opponent.currentHp, 75);
    });

    test('s_triple_arrows installs a user crit marker after damage', () {
      final result = _runMove(
        playerMove: _move(
          id: 'triple_arrows',
          type: 'fighting',
          power: 90,
          battleEngineMethod: 's_triple_arrows',
        ),
      );

      final player = result.state.battlerAt(psdkPlayerSlot);
      expect(_damageEvents(result, moveId: 'triple_arrows'), hasLength(1));
      expect(player.effects.contains('triple_arrows'), isTrue);
    });

    test('s_genies_storm bypasses accuracy during rain', () {
      final dryMiss = _runMove(
        playerMove: _move(
          id: 'bleakwind_storm',
          type: 'flying',
          category: PsdkBattleMoveCategory.special,
          power: 100,
          accuracy: 80,
          battleEngineMethod: 's_genies_storm',
        ),
        moveAccuracySeed: 99,
      );
      final rainHit = _runMove(
        playerMove: _move(
          id: 'bleakwind_storm',
          type: 'flying',
          category: PsdkBattleMoveCategory.special,
          power: 100,
          accuracy: 80,
          battleEngineMethod: 's_genies_storm',
        ),
        field: const PsdkBattleFieldState(
          weather: PsdkBattleWeatherState(
            id: PsdkBattleWeatherId.rain,
            remainingTurns: 5,
          ),
        ),
        moveAccuracySeed: 99,
      );

      expect(_damageEvents(dryMiss, moveId: 'bleakwind_storm'), isEmpty);
      expect(_damageEvents(rainHit, moveId: 'bleakwind_storm'), hasLength(1));
    });

    test('s_eerie_spell removes 3 PP from the target last used move', () {
      final result = _runMove(
        playerMove: _move(
          id: 'eerie_spell',
          type: 'psychic',
          category: PsdkBattleMoveCategory.special,
          power: 80,
          battleEngineMethod: 's_eerie_spell',
        ),
        opponentMove: _move(
          id: 'opponent_tackle',
          power: 40,
          currentPp: 5,
        ),
        opponentMoveHistory: PsdkBattleMoveHistory(
          attempts: <PsdkBattleMoveHistoryEntry>[
            PsdkBattleMoveHistoryEntry(
              moveId: 'opponent_tackle',
              turn: 0,
              targets: const <PsdkBattleSlotRef>[psdkPlayerSlot],
            ),
          ],
        ),
        playerSpeed: 1,
        opponentSpeed: 100,
      );

      final targetMove = result.state.battlerAt(psdkOpponentSlot).moves.single;
      expect(_damageEvents(result, moveId: 'eerie_spell'), hasLength(1));
      expect(targetMove.currentPp, 1);
    });

    test('s_spite removes 4 PP from the target last used move', () {
      final move = _move(
        id: 'spite',
        category: PsdkBattleMoveCategory.status,
        power: 0,
        accuracy: 100,
        battleEngineMethod: 's_spite',
      );
      final result = _resolveMoveOnState(
        move: move,
        state: PsdkBattleState(
          combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
            psdkPlayerSlot: PsdkBattleCombatant.fromSetup(
              _combatant(
                id: 'player',
                types: const PsdkBattleTypes(primary: 'ghost'),
                speed: 100,
                move: move,
              ),
            ),
            psdkOpponentSlot: PsdkBattleCombatant.fromSetup(
              _combatant(
                id: 'opponent',
                types: const PsdkBattleTypes(primary: 'normal'),
                speed: 10,
                move: _move(
                  id: 'opponent_tackle',
                  power: 40,
                  currentPp: 5,
                ),
                moveHistory: PsdkBattleMoveHistory(
                  attempts: <PsdkBattleMoveHistoryEntry>[
                    PsdkBattleMoveHistoryEntry(
                      moveId: 'opponent_tackle',
                      turn: 0,
                      targets: const <PsdkBattleSlotRef>[psdkPlayerSlot],
                    ),
                  ],
                ),
              ),
            ),
          },
        ),
      );

      final targetMove = result.state.battlerAt(psdkOpponentSlot).moves.single;
      expect(
        result.events.whereType<PsdkBattleMoveFailedEvent>(),
        isEmpty,
      );
      expect(targetMove.currentPp, 1);
    });

    test('s_spite fails when the target has no usable last move PP', () {
      final move = _move(
        id: 'spite',
        category: PsdkBattleMoveCategory.status,
        power: 0,
        accuracy: 100,
        battleEngineMethod: 's_spite',
      );
      final result = _resolveMoveOnState(
        move: move,
        state: PsdkBattleState(
          combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
            psdkPlayerSlot: PsdkBattleCombatant.fromSetup(
              _combatant(
                id: 'player',
                types: const PsdkBattleTypes(primary: 'ghost'),
                speed: 100,
                move: move,
              ),
            ),
            psdkOpponentSlot: PsdkBattleCombatant.fromSetup(
              _combatant(
                id: 'opponent',
                types: const PsdkBattleTypes(primary: 'normal'),
                speed: 10,
                move: _move(
                  id: 'opponent_tackle',
                  power: 40,
                  currentPp: 0,
                ),
                moveHistory: PsdkBattleMoveHistory(
                  attempts: <PsdkBattleMoveHistoryEntry>[
                    PsdkBattleMoveHistoryEntry(
                      moveId: 'opponent_tackle',
                      turn: 0,
                      targets: const <PsdkBattleSlotRef>[psdkPlayerSlot],
                    ),
                  ],
                ),
              ),
            ),
          },
        ),
      );

      final failures = result.events.whereType<PsdkBattleMoveFailedEvent>();
      expect(failures, hasLength(1));
      expect(failures.single.moveId, 'spite');
      expect(
        failures.single.reason,
        BattleMoveFailureReason.unusableByUser.jsonName,
      );
      expect(
          result.state.battlerAt(psdkOpponentSlot).moves.single.currentPp, 0);
    });

    test('s_last_respects scales power with local KO count', () {
      final regular = _runMove(
        playerMove: _move(
          id: 'ghost_hit',
          type: 'ghost',
          power: 50,
        ),
        opponentTypes: const PsdkBattleTypes(primary: 'psychic'),
      );
      final boosted = _runMove(
        playerMove: _move(
          id: 'last_respects',
          type: 'ghost',
          power: 50,
          battleEngineMethod: 's_last_respects',
        ),
        opponentTypes: const PsdkBattleTypes(primary: 'psychic'),
        playerKoCount: 2,
      );

      final regularDamage =
          _damageEvents(regular, moveId: 'ghost_hit').single.damage;
      final boostedDamage =
          _damageEvents(boosted, moveId: 'last_respects').single.damage;
      expect(boostedDamage, greaterThan(regularDamage));
    });

    test('s_shell_side_arm chooses the stronger damage category', () {
      const playerStats = PsdkBattleStats(
        attack: 120,
        defense: 50,
        specialAttack: 40,
        specialDefense: 50,
        speed: 100,
      );
      const opponentStats = PsdkBattleStats(
        attack: 50,
        defense: 40,
        specialAttack: 50,
        specialDefense: 120,
        speed: 1,
      );
      final specialOnly = _runMove(
        playerMove: _move(
          id: 'poison_hit',
          type: 'poison',
          category: PsdkBattleMoveCategory.special,
          power: 90,
        ),
        playerStats: playerStats,
        opponentStats: opponentStats,
      );
      final shellSideArm = _runMove(
        playerMove: _move(
          id: 'shell_side_arm',
          type: 'poison',
          category: PsdkBattleMoveCategory.special,
          power: 90,
          battleEngineMethod: 's_shell_side_arm',
        ),
        playerStats: playerStats,
        opponentStats: opponentStats,
      );

      final specialDamage =
          _damageEvents(specialOnly, moveId: 'poison_hit').single.damage;
      final shellSideArmDamage =
          _damageEvents(shellSideArm, moveId: 'shell_side_arm').single.damage;
      expect(shellSideArmDamage, greaterThan(specialDamage));
    });

    test('s_spectral_thief steals positive target stat stages after damage',
        () {
      final result = _runMove(
        playerMove: _move(
          id: 'spectral_thief',
          type: 'ghost',
          power: 90,
          battleEngineMethod: 's_spectral_thief',
        ),
        opponentTypes: const PsdkBattleTypes(primary: 'psychic'),
        opponentStages: PsdkBattleStatStages(
          values: const <String, int>{
            'attack': 2,
            'defense': -1,
            'speed': 3,
          },
        ),
      );

      final player = result.state.battlerAt(psdkPlayerSlot);
      final opponent = result.state.battlerAt(psdkOpponentSlot);
      expect(_damageEvents(result, moveId: 'spectral_thief'), hasLength(1));
      expect(player.statStages.valueOf('attack'), 2);
      expect(player.statStages.valueOf('speed'), 3);
      expect(opponent.statStages.valueOf('attack'), 0);
      expect(opponent.statStages.valueOf('speed'), 0);
      expect(opponent.statStages.valueOf('defense'), -1);
    });

    test('s_last_resort fails until all other known moves were attempted', () {
      final extraMoves = <PsdkBattleMoveData>[
        _move(id: 'tackle', power: 40),
        _move(
          id: 'growl',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          battleEngineMethod: 's_stat',
        ),
      ];
      final noHistory = _runMove(
        playerMove: _move(
          id: 'last_resort',
          power: 140,
          battleEngineMethod: 's_last_resort',
        ),
        playerExtraMoves: extraMoves,
      );
      final missingGrowl = _runMove(
        playerMove: _move(
          id: 'last_resort',
          power: 140,
          battleEngineMethod: 's_last_resort',
        ),
        playerExtraMoves: extraMoves,
        playerMoveHistory: PsdkBattleMoveHistory(
          attempts: <PsdkBattleMoveHistoryEntry>[
            PsdkBattleMoveHistoryEntry(
              moveId: 'tackle',
              turn: 1,
              targets: <PsdkBattleSlotRef>[psdkOpponentSlot],
            ),
          ],
        ),
      );
      final onlyLastResortWasAttempted = _runMove(
        playerMove: _move(
          id: 'last_resort',
          power: 140,
          battleEngineMethod: 's_last_resort',
        ),
        playerExtraMoves: extraMoves,
        playerMoveHistory: PsdkBattleMoveHistory(
          attempts: <PsdkBattleMoveHistoryEntry>[
            PsdkBattleMoveHistoryEntry(
              moveId: 'last_resort',
              turn: 1,
              targets: <PsdkBattleSlotRef>[psdkOpponentSlot],
            ),
          ],
        ),
      );

      for (final result in <PsdkBattleTurnResult>[
        noHistory,
        missingGrowl,
        onlyLastResortWasAttempted,
      ]) {
        final failures =
            result.timeline.events.whereType<PsdkBattleMoveFailedEvent>();
        expect(failures, hasLength(1));
        expect(failures.single.moveId, 'last_resort');
        expect(failures.single.reason, 'last_resort_requirements_unmet');
        expect(_damageEvents(result, moveId: 'last_resort'), isEmpty);
      }
    });

    test('s_last_resort fails when it is the only known move', () {
      final result = _runMove(
        playerMove: _move(
          id: 'last_resort',
          power: 140,
          battleEngineMethod: 's_last_resort',
        ),
      );

      final failures =
          result.timeline.events.whereType<PsdkBattleMoveFailedEvent>();
      expect(failures, hasLength(1));
      expect(failures.single.reason, 'last_resort_requirements_unmet');
      expect(_damageEvents(result, moveId: 'last_resort'), isEmpty);
    });

    test('s_last_resort hits after all other known moves were attempted', () {
      final result = _runMove(
        playerMove: _move(
          id: 'last_resort',
          power: 140,
          battleEngineMethod: 's_last_resort',
        ),
        playerExtraMoves: <PsdkBattleMoveData>[
          _move(id: 'tackle', power: 40),
          _move(
            id: 'growl',
            category: PsdkBattleMoveCategory.status,
            power: 0,
            battleEngineMethod: 's_stat',
          ),
        ],
        playerMoveHistory: PsdkBattleMoveHistory(
          attempts: <PsdkBattleMoveHistoryEntry>[
            PsdkBattleMoveHistoryEntry(
              moveId: 'tackle',
              turn: 1,
              targets: <PsdkBattleSlotRef>[psdkOpponentSlot],
            ),
            PsdkBattleMoveHistoryEntry(
              moveId: 'growl',
              turn: 2,
              targets: <PsdkBattleSlotRef>[psdkOpponentSlot],
            ),
          ],
        ),
      );

      expect(result.timeline.events.whereType<PsdkBattleMoveFailedEvent>(),
          isEmpty);
      expect(_damageEvents(result, moveId: 'last_resort'), hasLength(1));
    });

    test('s_make_it_rain deals damage and applies stat drops to the user', () {
      final result = _runMove(
        playerMove: _move(
          id: 'make_it_rain',
          type: 'steel',
          category: PsdkBattleMoveCategory.special,
          power: 120,
          battleEngineMethod: 's_make_it_rain',
          stageMods: const <PsdkBattleMoveStageMod>[
            PsdkBattleMoveStageMod(stat: 'specialAttack', stages: -1),
          ],
        ),
      );

      expect(_damageEvents(result, moveId: 'make_it_rain'), hasLength(1));
      expect(
        result.state
            .battlerAt(psdkPlayerSlot)
            .statStages
            .valueOf('specialAttack'),
        -1,
      );
      expect(
        result.state
            .battlerAt(psdkOpponentSlot)
            .statStages
            .valueOf('specialAttack'),
        0,
      );
    });

    test('s_magnitude uses the PSDK random magnitude power table', () {
      final magnitude = _runMove(
        playerMove: _move(
          id: 'magnitude',
          type: 'ground',
          power: 70,
          battleEngineMethod: 's_magnitude',
        ),
        opponentTypes: const PsdkBattleTypes(primary: 'fire'),
      );
      final basic = _runMove(
        playerMove: _move(
          id: 'basic_ground',
          type: 'ground',
          power: 70,
        ),
        opponentTypes: const PsdkBattleTypes(primary: 'fire'),
      );

      expect(_damageEvents(magnitude, moveId: 'magnitude'), hasLength(1));
      expect(
        _damage(magnitude, moveId: 'magnitude'),
        lessThan(_damage(basic, moveId: 'basic_ground')),
      );
    });

    for (final method in <String>[
      's_avalanche',
      's_assurance',
      's_brick_break',
      's_flame_burst',
      's_flying_press',
      's_focus_punch',
      's_fusion_bolt',
      's_fusion_flare',
      's_judgment',
      's_multi_attack',
      's_payback',
      's_payday',
      's_pollen_puff',
      's_pursuit',
      's_rapid_spin',
      's_revenge',
      's_revelation_dance',
      's_round',
      's_stomping_tantrum',
    ]) {
      test('$method executes its Basic hit while extra PSDK effects stay open',
          () {
        final result = _runMove(
          playerMove: _move(
            id: method,
            power: 40,
            battleEngineMethod: method,
          ),
        );

        expect(_damageEvents(result, moveId: method), hasLength(1));
        expect(
            result.state.battlerAt(psdkOpponentSlot).currentHp, lessThan(100));
      });
    }

    test('random-foe partial Basic descendants resolve in singles', () {
      final result = _runMove(
        playerMove: _move(
          id: 'outrage',
          type: 'dragon',
          power: 120,
          battleEngineMethod: 's_outrage',
          target: PsdkBattleMoveTarget.randomFoe,
        ),
      );

      expect(_damageEvents(result, moveId: 'outrage'), hasLength(1));
    });

    test('all-adjacent-foe partial Basic descendants resolve in singles', () {
      final result = _runMove(
        playerMove: _move(
          id: 'thousand_arrows',
          type: 'ground',
          power: 90,
          battleEngineMethod: 's_smack_down',
          target: PsdkBattleMoveTarget.allAdjacentFoes,
        ),
        opponentTypes: const PsdkBattleTypes(primary: 'fire'),
      );

      expect(_damageEvents(result, moveId: 'thousand_arrows'), hasLength(1));
    });

    test('s_pursuit doubles damage against a switching target', () {
      final normal = _runMove(
        playerMove: _move(
          id: 'pursuit',
          power: 40,
          battleEngineMethod: 's_pursuit',
        ),
      );
      final switching = _runMove(
        opponentSwitching: true,
        opponentLastSentTurn: 0,
        playerMove: _move(
          id: 'pursuit',
          power: 40,
          battleEngineMethod: 's_pursuit',
        ),
      );

      expect(
        _damage(switching, moveId: 'pursuit'),
        greaterThan(_damage(normal, moveId: 'pursuit')),
      );
    });

    test('s_pursuit does not double a target sent this turn', () {
      final normal = _runMove(
        playerMove: _move(
          id: 'pursuit',
          power: 40,
          battleEngineMethod: 's_pursuit',
        ),
      );
      final justSent = _runMove(
        opponentSwitching: true,
        opponentLastSentTurn: 1,
        playerMove: _move(
          id: 'pursuit',
          power: 40,
          battleEngineMethod: 's_pursuit',
        ),
      );

      expect(
        _damage(justSent, moveId: 'pursuit'),
        _damage(normal, moveId: 'pursuit'),
      );
    });

    test('s_fusion_flare doubles after same-turn Fusion Bolt succeeds', () {
      final baseline = _runMove(
        playerSpeed: 1,
        opponentSpeed: 100,
        opponentMove: _move(id: 'opponent_wait', power: 0),
        playerMove: _move(
          id: 'fusion_flare',
          type: 'fire',
          category: PsdkBattleMoveCategory.special,
          power: 100,
          battleEngineMethod: 's_fusion_flare',
        ),
      );
      final boosted = _runMove(
        playerSpeed: 1,
        opponentSpeed: 100,
        opponentMove: _move(
          id: 'fusion_bolt',
          type: 'electric',
          power: 100,
          battleEngineMethod: 's_fusion_bolt',
        ),
        playerMove: _move(
          id: 'fusion_flare',
          type: 'fire',
          category: PsdkBattleMoveCategory.special,
          power: 100,
          battleEngineMethod: 's_fusion_flare',
        ),
      );

      expect(
        _damage(boosted, moveId: 'fusion_flare'),
        greaterThan(_damage(baseline, moveId: 'fusion_flare')),
      );
    });

    test('s_fusion_bolt ignores a counterpart success from an earlier turn',
        () {
      final baseline = _runMove(
        playerMove: _move(
          id: 'fusion_bolt',
          type: 'electric',
          power: 100,
          battleEngineMethod: 's_fusion_bolt',
        ),
      );
      final oldCounterpart = _runMove(
        opponentMoveHistory: PsdkBattleMoveHistory(
          successes: <PsdkBattleMoveHistoryEntry>[
            PsdkBattleMoveHistoryEntry(
              moveId: 'fusion_flare',
              turn: 0,
              targets: const <PsdkBattleSlotRef>[psdkPlayerSlot],
            ),
          ],
        ),
        playerMove: _move(
          id: 'fusion_bolt',
          type: 'electric',
          power: 100,
          battleEngineMethod: 's_fusion_bolt',
        ),
      );

      expect(
        _damage(oldCounterpart, moveId: 'fusion_bolt'),
        _damage(baseline, moveId: 'fusion_bolt'),
      );
    });

    test('formerly missing broad fallback methods are executable as partials',
        () {
      final entries = <({
        String method,
        String moveId,
        PsdkBattleMoveCategory category,
        int power,
      })>[
        (
          method: 's_beat_up',
          moveId: 'beat_up',
          category: PsdkBattleMoveCategory.physical,
          power: 40,
        ),
        (
          method: 's_conversion',
          moveId: 'conversion',
          category: PsdkBattleMoveCategory.status,
          power: 0,
        ),
        (
          method: 's_metronome',
          moveId: 'metronome',
          category: PsdkBattleMoveCategory.status,
          power: 0,
        ),
        (
          method: 's_teleport',
          moveId: 'teleport',
          category: PsdkBattleMoveCategory.status,
          power: 0,
        ),
        (
          method: 's_venom_drench',
          moveId: 'venom_drench',
          category: PsdkBattleMoveCategory.status,
          power: 0,
        ),
      ];

      for (final entry in entries) {
        final result = _runMove(
          playerMove: _move(
            id: entry.moveId,
            category: entry.category,
            power: entry.power,
            battleEngineMethod: entry.method,
          ),
          playerReserves:
              entry.method == 's_shed_tail' || entry.method == 's_teleport'
                  ? <PsdkBattleCombatantSetup>[
                      _combatant(
                        id: 'player-reserve',
                        types: const PsdkBattleTypes(primary: 'normal'),
                        speed: 50,
                        move: _move(
                          id: 'reserve_wait',
                          power: 0,
                          accuracy: 1,
                        ),
                      ),
                    ]
                  : const <PsdkBattleCombatantSetup>[],
        );

        expect(
          result.timeline.events.whereType<PsdkBattleMoveFailedEvent>(),
          isEmpty,
          reason: entry.method,
        );
      }
    });

    test('s_dragon_cheer installs a battler-scoped effect on the user', () {
      final result = _runMove(
        playerMove: _move(
          id: 'dragon_cheer',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 0,
          battleEngineMethod: 's_dragon_cheer',
          target: PsdkBattleMoveTarget.allAllies,
        ),
      );

      final effect =
          _effect(result.state.battlerAt(psdkPlayerSlot), 'dragon_cheer');
      expect(effect.scope, isA<BattlerBattleEffectScope>());
    });

    test('s_helping_hand marks the targeted ally for this turn', () {
      final move = _move(
        id: 'helping_hand',
        category: PsdkBattleMoveCategory.status,
        power: 0,
        accuracy: 0,
        battleEngineMethod: 's_helping_hand',
        target: PsdkBattleMoveTarget.adjacentAlly,
      );
      final allySlot = const PsdkBattleSlotRef(bank: 0, position: 1);
      final result = _resolveMoveOnState(
        move: move,
        state: PsdkBattleState(
          combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
            psdkPlayerSlot: PsdkBattleCombatant.fromSetup(
              _combatant(
                id: 'player',
                types: const PsdkBattleTypes(primary: 'normal'),
                speed: 100,
                move: move,
              ),
            ),
            allySlot: PsdkBattleCombatant.fromSetup(
              _combatant(
                id: 'ally',
                types: const PsdkBattleTypes(primary: 'normal'),
                speed: 90,
                move: _move(id: 'ally_wait', power: 0, accuracy: 1),
              ),
            ),
            psdkOpponentSlot: PsdkBattleCombatant.fromSetup(
              _combatant(
                id: 'opponent',
                types: const PsdkBattleTypes(primary: 'normal'),
                speed: 10,
                move: _move(id: 'opponent_wait', power: 0, accuracy: 1),
              ),
            ),
          },
        ),
        target: allySlot,
      );

      expect(
        result.state.battlerAt(allySlot).effects.contains('helping_hand_mark'),
        isTrue,
      );
      expect(result.events.whereType<PsdkBattleMoveFailedEvent>(), isEmpty);
    });

    test('s_helping_hand fails when the target ally is already marked', () {
      final move = _move(
        id: 'helping_hand',
        category: PsdkBattleMoveCategory.status,
        power: 0,
        accuracy: 0,
        battleEngineMethod: 's_helping_hand',
        target: PsdkBattleMoveTarget.adjacentAlly,
      );
      final allySlot = const PsdkBattleSlotRef(bank: 0, position: 1);
      final result = _resolveMoveOnState(
        move: move,
        state: PsdkBattleState(
          combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
            psdkPlayerSlot: PsdkBattleCombatant.fromSetup(
              _combatant(
                id: 'player',
                types: const PsdkBattleTypes(primary: 'normal'),
                speed: 100,
                move: move,
              ),
            ),
            allySlot: PsdkBattleCombatant.fromSetup(
              _combatant(
                id: 'ally',
                types: const PsdkBattleTypes(primary: 'normal'),
                speed: 90,
                move: _move(id: 'ally_wait', power: 0, accuracy: 1),
                effects: const PsdkBattleEffectStack.empty().addEffect(
                  GenericBattleEffect(
                    id: 'helping_hand_mark',
                    scope: BattlerBattleEffectScope(allySlot),
                    remainingTurns: 0,
                  ),
                ),
              ),
            ),
            psdkOpponentSlot: PsdkBattleCombatant.fromSetup(
              _combatant(
                id: 'opponent',
                types: const PsdkBattleTypes(primary: 'normal'),
                speed: 10,
                move: _move(id: 'opponent_wait', power: 0, accuracy: 1),
              ),
            ),
          },
        ),
        target: allySlot,
      );

      expect(
        result.events.whereType<PsdkBattleMoveFailedEvent>().single.reason,
        'helping_hand_already_active',
      );
    });

    test('s_stuff_cheeks consumes the user berry, heals and raises defense',
        () {
      final result = _runMove(
        playerCurrentHp: 40,
        playerHeldItemId: 'oran_berry',
        playerAbilityId: 'cheek_pouch',
        playerMove: _move(
          id: 'stuff_cheeks',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 0,
          target: PsdkBattleMoveTarget.self,
          battleEngineMethod: 's_stuff_cheeks',
        ),
      );

      final player = result.state.battlerAt(psdkPlayerSlot);
      expect(player.currentHp, 83);
      expect(player.heldItemId, isNull);
      expect(player.consumedItemId, 'oran_berry');
      expect(player.statStages.valueOf('defense'), 2);
      expect(_healEvents(result, moveId: 'item:oran_berry').single.amount, 10);
      expect(
        _healEvents(result, moveId: 'ability:cheek_pouch').single.amount,
        33,
      );
      expect(_itemEvents(result).single.itemId, 'oran_berry');
    });

    test('s_stuff_cheeks fails when the user has no berry to eat', () {
      final result = _runMove(
        playerMove: _move(
          id: 'stuff_cheeks',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 0,
          target: PsdkBattleMoveTarget.self,
          battleEngineMethod: 's_stuff_cheeks',
        ),
      );

      expect(
        result.timeline.events.whereType<PsdkBattleMoveFailedEvent>().single,
        isA<PsdkBattleMoveFailedEvent>()
            .having((event) => event.moveId, 'moveId', 'stuff_cheeks')
            .having((event) => event.reason, 'reason', 'unusable_by_user'),
      );
      expect(result.state.battlerAt(psdkPlayerSlot).heldItemId, isNull);
      expect(
          result.state.battlerAt(psdkPlayerSlot).statStages.valueOf('defense'),
          0);
      expect(_itemEvents(result), isEmpty);
    });

    test('s_teatime forces every berry holder on the field to eat it', () {
      final result = _runMove(
        playerCurrentHp: 40,
        opponentCurrentHp: 40,
        playerHeldItemId: 'oran_berry',
        opponentHeldItemId: 'sitrus_berry',
        playerAbilityId: 'cheek_pouch',
        playerMove: _move(
          id: 'teatime',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 0,
          target: PsdkBattleMoveTarget.allBattlers,
          battleEngineMethod: 's_teatime',
        ),
      );

      final player = result.state.battlerAt(psdkPlayerSlot);
      final opponent = result.state.battlerAt(psdkOpponentSlot);
      expect(player.currentHp, 83);
      expect(opponent.currentHp, 65);
      expect(player.heldItemId, isNull);
      expect(opponent.heldItemId, isNull);
      expect(player.consumedItemId, 'oran_berry');
      expect(opponent.consumedItemId, 'sitrus_berry');
      expect(
        _healEvents(result, moveId: 'item:oran_berry').single.target,
        psdkPlayerSlot,
      );
      expect(
        _healEvents(result, moveId: 'item:sitrus_berry').single.target,
        psdkOpponentSlot,
      );
      expect(
        _healEvents(result, moveId: 'ability:cheek_pouch').single.target,
        psdkPlayerSlot,
      );
      expect(
        _itemEvents(result).map((event) => event.itemId),
        containsAll(<String>['oran_berry', 'sitrus_berry']),
      );
    });

    test('s_teatime fails when no battler on the field holds a berry', () {
      final result = _runMove(
        playerMove: _move(
          id: 'teatime',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 0,
          target: PsdkBattleMoveTarget.allBattlers,
          battleEngineMethod: 's_teatime',
        ),
      );

      expect(
        result.timeline.events.whereType<PsdkBattleMoveFailedEvent>().single,
        isA<PsdkBattleMoveFailedEvent>()
            .having((event) => event.moveId, 'moveId', 'teatime')
            .having((event) => event.reason, 'reason', 'unusable_by_user'),
      );
      expect(_itemEvents(result), isEmpty);
      expect(_healEvents(result, moveId: 'item:oran_berry'), isEmpty);
      expect(_healEvents(result, moveId: 'item:sitrus_berry'), isEmpty);
    });

    test(
        's_dragon_cheer fails when an unstackable critical marker is already active',
        () {
      final result = _runMove(
        playerEffects: const PsdkBattleEffectStack.empty().addEffect(
          TripleArrowsEffect(
            scope: BattlerBattleEffectScope(psdkPlayerSlot),
            remainingTurns: 1,
          ),
        ),
        playerMove: _move(
          id: 'dragon_cheer',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 0,
          battleEngineMethod: 's_dragon_cheer',
          target: PsdkBattleMoveTarget.allAllies,
        ),
      );

      expect(
        result.timeline.events
            .whereType<PsdkBattleMoveFailedEvent>()
            .single
            .reason,
        'dragon_cheer_already_active',
      );
    });

    test('s_flower_shield boosts every Grass battler on the field', () {
      final move = _move(
        id: 'flower_shield',
        category: PsdkBattleMoveCategory.status,
        power: 0,
        accuracy: 0,
        battleEngineMethod: 's_flower_shield',
        target: PsdkBattleMoveTarget.allBattlers,
      );
      final result = _resolveMoveOnState(
        move: move,
        state: PsdkBattleState(
          combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
            psdkPlayerSlot: PsdkBattleCombatant.fromSetup(
              _combatant(
                id: 'player',
                types: const PsdkBattleTypes(primary: 'grass'),
                speed: 100,
                move: move,
              ),
            ),
            const PsdkBattleSlotRef(bank: 0, position: 1):
                PsdkBattleCombatant.fromSetup(
              _combatant(
                id: 'ally',
                types: const PsdkBattleTypes(primary: 'fire'),
                speed: 90,
                move: _move(id: 'ally_wait', power: 0, accuracy: 1),
              ),
            ),
            psdkOpponentSlot: PsdkBattleCombatant.fromSetup(
              _combatant(
                id: 'opponent',
                types: const PsdkBattleTypes(primary: 'grass'),
                speed: 10,
                move: _move(id: 'opponent_wait', power: 0, accuracy: 1),
              ),
            ),
            const PsdkBattleSlotRef(bank: 1, position: 1):
                PsdkBattleCombatant.fromSetup(
              _combatant(
                id: 'opponent_ally',
                types: const PsdkBattleTypes(primary: 'water'),
                speed: 5,
                move: _move(id: 'opponent_ally_wait', power: 0, accuracy: 1),
              ),
            ),
          },
        ),
      );

      expect(
          result.state.battlerAt(psdkPlayerSlot).statStages.valueOf('defense'),
          1);
      expect(
        result.state.battlerAt(psdkOpponentSlot).statStages.valueOf('defense'),
        1,
      );
      expect(
        result.state
            .battlerAt(const PsdkBattleSlotRef(bank: 0, position: 1))
            .statStages
            .valueOf('defense'),
        0,
      );
      expect(
        result.state
            .battlerAt(const PsdkBattleSlotRef(bank: 1, position: 1))
            .statStages
            .valueOf('defense'),
        0,
      );
      expect(result.events.whereType<PsdkBattleMoveFailedEvent>(), isEmpty);
    });

    test('s_gear_up boosts Plus and Minus allies on the user bank', () {
      final move = _move(
        id: 'gear_up',
        category: PsdkBattleMoveCategory.status,
        power: 0,
        accuracy: 0,
        battleEngineMethod: 's_gear_up',
      );
      final allySlot = const PsdkBattleSlotRef(bank: 0, position: 1);
      final result = _resolveMoveOnState(
        move: move,
        state: PsdkBattleState(
          combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
            psdkPlayerSlot: PsdkBattleCombatant.fromSetup(
              _combatant(
                id: 'player',
                types: const PsdkBattleTypes(primary: 'steel'),
                speed: 100,
                move: move,
                abilityId: 'plus',
              ),
            ),
            allySlot: PsdkBattleCombatant.fromSetup(
              _combatant(
                id: 'ally',
                types: const PsdkBattleTypes(primary: 'electric'),
                speed: 90,
                move: _move(id: 'ally_wait', power: 0, accuracy: 1),
                abilityId: 'minus',
              ),
            ),
            psdkOpponentSlot: PsdkBattleCombatant.fromSetup(
              _combatant(
                id: 'opponent',
                types: const PsdkBattleTypes(primary: 'normal'),
                speed: 10,
                move: _move(id: 'opponent_wait', power: 0, accuracy: 1),
                abilityId: 'plus',
              ),
            ),
          },
        ),
      );

      for (final slot in <PsdkBattleSlotRef>[psdkPlayerSlot, allySlot]) {
        expect(result.state.battlerAt(slot).statStages.valueOf('attack'), 1);
        expect(
          result.state.battlerAt(slot).statStages.valueOf('specialAttack'),
          1,
        );
      }
      expect(
          result.state.battlerAt(psdkOpponentSlot).statStages.valueOf('attack'),
          0);
      expect(
        result.state
            .battlerAt(psdkOpponentSlot)
            .statStages
            .valueOf('specialAttack'),
        0,
      );
    });

    test('s_gear_up fails when no Plus or Minus ally can be affected', () {
      final move = _move(
        id: 'gear_up',
        category: PsdkBattleMoveCategory.status,
        power: 0,
        accuracy: 0,
        battleEngineMethod: 's_gear_up',
      );
      final result = _resolveMoveOnState(
        move: move,
        state: PsdkBattleState(
          combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
            psdkPlayerSlot: PsdkBattleCombatant.fromSetup(
              _combatant(
                id: 'player',
                types: const PsdkBattleTypes(primary: 'steel'),
                speed: 100,
                move: move,
                abilityId: 'clear_body',
              ),
            ),
            psdkOpponentSlot: PsdkBattleCombatant.fromSetup(
              _combatant(
                id: 'opponent',
                types: const PsdkBattleTypes(primary: 'normal'),
                speed: 10,
                move: _move(id: 'opponent_wait', power: 0, accuracy: 1),
              ),
            ),
          },
        ),
      );

      expect(
        result.events.whereType<PsdkBattleMoveFailedEvent>().single.reason,
        BattleMoveFailureReason.unusableByUser.jsonName,
      );
    });

    test(
        's_magnetic_flux boosts Defense and Special Defense for Plus/Minus allies',
        () {
      final move = _move(
        id: 'magnetic_flux',
        category: PsdkBattleMoveCategory.status,
        power: 0,
        accuracy: 0,
        battleEngineMethod: 's_magnetic_flux',
      );
      final allySlot = const PsdkBattleSlotRef(bank: 0, position: 1);
      final result = _resolveMoveOnState(
        move: move,
        state: PsdkBattleState(
          combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
            psdkPlayerSlot: PsdkBattleCombatant.fromSetup(
              _combatant(
                id: 'player',
                types: const PsdkBattleTypes(primary: 'electric'),
                speed: 100,
                move: move,
                abilityId: 'plus',
              ),
            ),
            allySlot: PsdkBattleCombatant.fromSetup(
              _combatant(
                id: 'ally',
                types: const PsdkBattleTypes(primary: 'electric'),
                speed: 90,
                move: _move(id: 'ally_wait', power: 0, accuracy: 1),
                abilityId: 'minus',
              ),
            ),
            psdkOpponentSlot: PsdkBattleCombatant.fromSetup(
              _combatant(
                id: 'opponent',
                types: const PsdkBattleTypes(primary: 'normal'),
                speed: 10,
                move: _move(id: 'opponent_wait', power: 0, accuracy: 1),
              ),
            ),
          },
        ),
      );

      for (final slot in <PsdkBattleSlotRef>[psdkPlayerSlot, allySlot]) {
        expect(result.state.battlerAt(slot).statStages.valueOf('defense'), 1);
        expect(
          result.state.battlerAt(slot).statStages.valueOf('specialDefense'),
          1,
        );
      }
      expect(
          result.state
              .battlerAt(psdkOpponentSlot)
              .statStages
              .valueOf('defense'),
          0);
      expect(
        result.state
            .battlerAt(psdkOpponentSlot)
            .statStages
            .valueOf('specialDefense'),
        0,
      );
    });

    test('s_rototiller boosts only grounded Grass battlers', () {
      final move = _move(
        id: 'rototiller',
        type: 'ground',
        category: PsdkBattleMoveCategory.status,
        power: 0,
        accuracy: 0,
        battleEngineMethod: 's_rototiller',
        target: PsdkBattleMoveTarget.allBattlers,
      );
      final allySlot = const PsdkBattleSlotRef(bank: 0, position: 1);
      final result = _resolveMoveOnState(
        move: move,
        state: PsdkBattleState(
          combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
            psdkPlayerSlot: PsdkBattleCombatant.fromSetup(
              _combatant(
                id: 'player',
                types: const PsdkBattleTypes(primary: 'grass'),
                speed: 100,
                move: move,
              ),
            ),
            allySlot: PsdkBattleCombatant.fromSetup(
              _combatant(
                id: 'ally',
                types: const PsdkBattleTypes(
                    primary: 'grass', secondary: 'flying'),
                speed: 90,
                move: _move(id: 'ally_wait', power: 0, accuracy: 1),
              ),
            ),
            psdkOpponentSlot: PsdkBattleCombatant.fromSetup(
              _combatant(
                id: 'opponent',
                types: const PsdkBattleTypes(primary: 'grass'),
                speed: 10,
                move: _move(id: 'opponent_wait', power: 0, accuracy: 1),
              ),
            ),
          },
        ),
      );

      for (final slot in <PsdkBattleSlotRef>[
        psdkPlayerSlot,
        psdkOpponentSlot
      ]) {
        expect(result.state.battlerAt(slot).statStages.valueOf('attack'), 1);
        expect(
          result.state.battlerAt(slot).statStages.valueOf('specialAttack'),
          1,
        );
      }
      expect(result.state.battlerAt(allySlot).statStages.valueOf('attack'), 0);
      expect(
        result.state.battlerAt(allySlot).statStages.valueOf('specialAttack'),
        0,
      );
    });

    test('s_no_retreat fails for Ghost users and does not install the effect',
        () {
      final result = _runMove(
        playerTypes: const PsdkBattleTypes(primary: 'ghost'),
        playerMove: _move(
          id: 'no_retreat',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 0,
          battleEngineMethod: 's_no_retreat',
          target: PsdkBattleMoveTarget.self,
        ),
      );

      expect(
        result.timeline.events
            .whereType<PsdkBattleMoveFailedEvent>()
            .single
            .reason,
        'no_retreat_failed',
      );
      expect(
        result.state.battlerAt(psdkPlayerSlot).effects.contains('no_retreat'),
        isFalse,
      );
    });

    test('remaining Ruby-only missing methods are executable as partials', () {
      final entries = <({
        String method,
        String moveId,
        PsdkBattleMoveCategory category,
        int power,
      })>[
        (
          method: 's_chilly_reception',
          moveId: 'chilly_reception',
          category: PsdkBattleMoveCategory.status,
          power: 0,
        ),
        (
          method: 's_court_change',
          moveId: 'court_change',
          category: PsdkBattleMoveCategory.status,
          power: 0,
        ),
        (
          method: 's_dragon_cheer',
          moveId: 'dragon_cheer',
          category: PsdkBattleMoveCategory.status,
          power: 0,
        ),
        (
          method: 's_dragon_darts',
          moveId: 'dragon_darts',
          category: PsdkBattleMoveCategory.physical,
          power: 50,
        ),
        (
          method: 's_electro_shot',
          moveId: 'electro_shot',
          category: PsdkBattleMoveCategory.special,
          power: 130,
        ),
        (
          method: 's_expanding_force',
          moveId: 'expanding_force',
          category: PsdkBattleMoveCategory.special,
          power: 80,
        ),
        (
          method: 's_fairy_lock',
          moveId: 'fairy_lock',
          category: PsdkBattleMoveCategory.status,
          power: 0,
        ),
        (
          method: 's_fickle_beam',
          moveId: 'fickle_beam',
          category: PsdkBattleMoveCategory.special,
          power: 80,
        ),
        (
          method: 's_fishious_rend',
          moveId: 'fishious_rend',
          category: PsdkBattleMoveCategory.physical,
          power: 85,
        ),
        (
          method: 's_genies_storm',
          moveId: 'bleakwind_storm',
          category: PsdkBattleMoveCategory.special,
          power: 100,
        ),
        (
          method: 's_grassy_glide',
          moveId: 'grassy_glide',
          category: PsdkBattleMoveCategory.physical,
          power: 55,
        ),
        (
          method: 's_ivy_cudgel',
          moveId: 'ivy_cudgel',
          category: PsdkBattleMoveCategory.physical,
          power: 100,
        ),
        (
          method: 's_lash_out',
          moveId: 'lash_out',
          category: PsdkBattleMoveCategory.physical,
          power: 75,
        ),
        (
          method: 's_last_respects',
          moveId: 'last_respects',
          category: PsdkBattleMoveCategory.physical,
          power: 50,
        ),
        (
          method: 's_magic_powder',
          moveId: 'magic_powder',
          category: PsdkBattleMoveCategory.status,
          power: 0,
        ),
        (
          method: 's_no_retreat',
          moveId: 'no_retreat',
          category: PsdkBattleMoveCategory.status,
          power: 0,
        ),
        (
          method: 's_octolock',
          moveId: 'octolock',
          category: PsdkBattleMoveCategory.status,
          power: 0,
        ),
        (
          method: 's_pre_attack_base',
          moveId: 'beak_blast_base',
          category: PsdkBattleMoveCategory.physical,
          power: 100,
        ),
        (
          method: 's_rage_fist',
          moveId: 'rage_fist',
          category: PsdkBattleMoveCategory.physical,
          power: 50,
        ),
        (
          method: 's_rising_voltage',
          moveId: 'rising_voltage',
          category: PsdkBattleMoveCategory.special,
          power: 70,
        ),
        (
          method: 's_shed_tail',
          moveId: 'shed_tail',
          category: PsdkBattleMoveCategory.status,
          power: 0,
        ),
        (
          method: 's_shell_side_arm',
          moveId: 'shell_side_arm',
          category: PsdkBattleMoveCategory.special,
          power: 90,
        ),
        (
          method: 's_super_duper_effective',
          moveId: 'sizzly_slide',
          category: PsdkBattleMoveCategory.physical,
          power: 60,
        ),
        (
          method: 's_terrain_pulse',
          moveId: 'terrain_pulse',
          category: PsdkBattleMoveCategory.special,
          power: 50,
        ),
        (
          method: 's_tidy_up',
          moveId: 'tidy_up',
          category: PsdkBattleMoveCategory.status,
          power: 0,
        ),
      ];

      for (final entry in entries) {
        final result = _runMove(
          playerMove: _move(
            id: entry.moveId,
            category: entry.category,
            power: entry.power,
            battleEngineMethod: entry.method,
          ),
          playerReserves: entry.method == 's_shed_tail'
              ? <PsdkBattleCombatantSetup>[
                  _combatant(
                    id: 'player-reserve',
                    types: const PsdkBattleTypes(primary: 'normal'),
                    speed: 50,
                    move: _move(
                      id: 'reserve_wait',
                      power: 0,
                      accuracy: 1,
                    ),
                  ),
                ]
              : const <PsdkBattleCombatantSetup>[],
        );

        expect(
          result.timeline.events.whereType<PsdkBattleMoveFailedEvent>(),
          isEmpty,
          reason: entry.method,
        );
      }
    });
  });
}

PsdkBattleTurnResult _runMove({
  required PsdkBattleMoveData playerMove,
  PsdkBattleMajorStatus? playerMajorStatus,
  String? playerHeldItemId,
  String? opponentHeldItemId,
  String? playerAbilityId,
  String? opponentAbilityId,
  PsdkBattleTypes playerTypes = const PsdkBattleTypes(primary: 'fire'),
  PsdkBattleTypes opponentTypes = const PsdkBattleTypes(primary: 'normal'),
  List<PsdkBattleMoveData> playerExtraMoves = const <PsdkBattleMoveData>[],
  List<PsdkBattleCombatantSetup> playerReserves =
      const <PsdkBattleCombatantSetup>[],
  PsdkBattleMoveData? opponentMove,
  int genericSeed = 0,
  int moveAccuracySeed = 3,
  PsdkBattleFieldState field = const PsdkBattleFieldState(),
  int playerSpeed = 100,
  int opponentSpeed = 1,
  int playerCurrentHp = 100,
  int opponentCurrentHp = 100,
  int playerKoCount = 0,
  int opponentKoCount = 0,
  int playerLoyalty = 255,
  int opponentLoyalty = 255,
  String playerSpeciesId = 'player',
  String opponentSpeciesId = 'opponent',
  int playerForm = 0,
  int opponentForm = 0,
  int playerIvHp = 0,
  int playerIvAttack = 0,
  int playerIvDefense = 0,
  int playerIvSpeed = 0,
  int playerIvSpecialAttack = 0,
  int playerIvSpecialDefense = 0,
  int opponentIvHp = 0,
  int opponentIvAttack = 0,
  int opponentIvDefense = 0,
  int opponentIvSpeed = 0,
  int opponentIvSpecialAttack = 0,
  int opponentIvSpecialDefense = 0,
  bool opponentSwitching = false,
  int? opponentLastSentTurn,
  PsdkBattleGender playerGender = PsdkBattleGender.unknown,
  PsdkBattleGender opponentGender = PsdkBattleGender.unknown,
  double playerBaseWeightKg = 1,
  double? playerCurrentWeightKg,
  PsdkBattleStatStages? playerStages,
  PsdkBattleStatStages? opponentStages,
  PsdkBattleEffectStack? playerEffects,
  PsdkBattleEffectStack? opponentEffects,
  PsdkBattleStats? playerStats,
  PsdkBattleStats? opponentStats,
  PsdkBattleMoveHistory? playerMoveHistory,
  PsdkBattleMoveHistory? opponentMoveHistory,
}) {
  final engine = PsdkBattleEngine(
    setup: PsdkBattleSetup.singles(
      player: _combatant(
        id: 'player',
        speciesId: playerSpeciesId,
        types: playerTypes,
        speed: playerSpeed,
        currentHp: playerCurrentHp,
        move: playerMove,
        extraMoves: playerExtraMoves,
        stats: playerStats,
        statStages: playerStages,
        majorStatus: playerMajorStatus,
        form: playerForm,
        heldItemId: playerHeldItemId,
        abilityId: playerAbilityId,
        gender: playerGender,
        effects: playerEffects,
        koCount: playerKoCount,
        loyalty: playerLoyalty,
        ivHp: playerIvHp,
        ivAttack: playerIvAttack,
        ivDefense: playerIvDefense,
        ivSpeed: playerIvSpeed,
        ivSpecialAttack: playerIvSpecialAttack,
        ivSpecialDefense: playerIvSpecialDefense,
        baseWeightKg: playerBaseWeightKg,
        currentWeightKg: playerCurrentWeightKg,
        moveHistory: playerMoveHistory,
      ),
      opponent: _combatant(
        id: 'opponent',
        speciesId: opponentSpeciesId,
        types: opponentTypes,
        speed: opponentSpeed,
        currentHp: opponentCurrentHp,
        move: opponentMove ??
            _move(
              id: 'opponent_wait',
              power: 0,
              accuracy: 1,
            ),
        stats: opponentStats,
        statStages: opponentStages,
        form: opponentForm,
        heldItemId: opponentHeldItemId,
        abilityId: opponentAbilityId,
        gender: opponentGender,
        effects: opponentEffects,
        moveHistory: opponentMoveHistory,
        koCount: opponentKoCount,
        loyalty: opponentLoyalty,
        ivHp: opponentIvHp,
        ivAttack: opponentIvAttack,
        ivDefense: opponentIvDefense,
        ivSpeed: opponentIvSpeed,
        ivSpecialAttack: opponentIvSpecialAttack,
        ivSpecialDefense: opponentIvSpecialDefense,
        switching: opponentSwitching,
        lastSentTurn: opponentLastSentTurn,
      ),
      playerReserves: playerReserves,
      field: field,
      rngSeeds: PsdkBattleRngSeeds(
        moveDamage: 1,
        moveCritical: 99999,
        moveAccuracy: moveAccuracySeed,
        generic: genericSeed,
      ),
    ),
  );
  return engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  String? speciesId,
  required PsdkBattleTypes types,
  required int speed,
  int currentHp = 100,
  required PsdkBattleMoveData move,
  List<PsdkBattleMoveData> extraMoves = const <PsdkBattleMoveData>[],
  PsdkBattleStats? stats,
  PsdkBattleStatStages? statStages,
  PsdkBattleMajorStatus? majorStatus,
  String? heldItemId,
  String? abilityId,
  PsdkBattleGender gender = PsdkBattleGender.unknown,
  PsdkBattleEffectStack? effects,
  PsdkBattleMoveHistory? moveHistory,
  int koCount = 0,
  int loyalty = 255,
  int form = 0,
  int ivHp = 0,
  int ivAttack = 0,
  int ivDefense = 0,
  int ivSpeed = 0,
  int ivSpecialAttack = 0,
  int ivSpecialDefense = 0,
  bool switching = false,
  int? lastSentTurn,
  double baseWeightKg = 1,
  double? currentWeightKg,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: speciesId ?? id,
    displayName: speciesId ?? id,
    level: 20,
    maxHp: 100,
    currentHp: currentHp,
    types: types,
    stats: stats ??
        PsdkBattleStats(
          attack: 50,
          defense: 50,
          specialAttack: 50,
          specialDefense: 50,
          speed: speed,
        ),
    statStages: statStages,
    moves: <PsdkBattleMoveData>[move, ...extraMoves],
    form: form,
    majorStatus: majorStatus,
    heldItemId: heldItemId,
    abilityId: abilityId,
    gender: gender,
    effects: effects,
    moveHistory: moveHistory,
    koCount: koCount,
    loyalty: loyalty,
    ivHp: ivHp,
    ivAttack: ivAttack,
    ivDefense: ivDefense,
    ivSpeed: ivSpeed,
    ivSpecialAttack: ivSpecialAttack,
    ivSpecialDefense: ivSpecialDefense,
    switching: switching,
    lastSentTurn: lastSentTurn,
    baseWeightKg: baseWeightKg,
    currentWeightKg: currentWeightKg,
  );
}

PsdkBattleMoveData _move({
  required String id,
  String type = 'normal',
  PsdkBattleMoveCategory category = PsdkBattleMoveCategory.physical,
  required int power,
  int accuracy = 100,
  int priority = 0,
  int? currentPp,
  int? effectChance,
  String battleEngineMethod = 's_basic',
  PsdkBattleMoveTarget target = PsdkBattleMoveTarget.adjacentFoe,
  bool snatchable = false,
  bool magicCoatAffected = false,
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
    currentPp: currentPp,
    priority: priority,
    criticalRate: 1,
    effectChance: effectChance,
    battleEngineMethod: battleEngineMethod,
    target: target,
    snatchable: snatchable,
    magicCoatAffected: magicCoatAffected,
    statuses: statuses,
    stageMods: stageMods,
  );
}

PsdkBattleMoveData _dragonDartsMove() {
  return _move(
    id: 'dragon_darts',
    type: 'dragon',
    category: PsdkBattleMoveCategory.physical,
    power: 50,
    battleEngineMethod: 's_dragon_darts',
  );
}

PsdkBattleState _dragonDartsState({
  required PsdkBattleMoveData move,
  int opponentHp = 100,
  PsdkBattleEffectStack opponentEffects = const PsdkBattleEffectStack.empty(),
  Map<PsdkBattleSlotRef, PsdkBattleEffectStack> opponentAllyEffects =
      const <PsdkBattleSlotRef, PsdkBattleEffectStack>{},
  List<PsdkBattleSlotRef> opponentAllySlots = const <PsdkBattleSlotRef>[],
}) {
  return PsdkBattleState(
    combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
      psdkPlayerSlot: PsdkBattleCombatant.fromSetup(
        _combatant(
          id: 'player',
          types: const PsdkBattleTypes(primary: 'dragon'),
          speed: 100,
          move: move,
        ),
      ),
      psdkOpponentSlot: PsdkBattleCombatant.fromSetup(
        _combatant(
          id: 'opponent',
          types: const PsdkBattleTypes(primary: 'normal'),
          speed: 10,
          currentHp: opponentHp,
          move: _move(id: 'opponent_wait', power: 0, accuracy: 0),
          effects: opponentEffects,
        ),
      ),
      for (final slot in opponentAllySlots)
        slot: PsdkBattleCombatant.fromSetup(
          _combatant(
            id: 'opponent_ally_${slot.position}',
            types: const PsdkBattleTypes(primary: 'normal'),
            speed: 5,
            move: _move(id: 'opponent_ally_wait_${slot.position}', power: 0),
            effects: opponentAllyEffects[slot],
          ),
        ),
    },
  );
}

List<PsdkBattleEvent> _eventsFor(
  PsdkBattleTurnResult result, {
  required String moveId,
}) {
  return result.timeline.events
      .where((event) => event.toJson()['moveId'] == moveId)
      .toList(growable: false);
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

List<PsdkBattleDamageEvent> _damageEventsFrom(
  BattleMoveBehaviorResolution result, {
  required String moveId,
}) {
  return result.events
      .whereType<PsdkBattleDamageEvent>()
      .where((event) => event.moveId == moveId)
      .toList(growable: false);
}

int _damage(
  PsdkBattleTurnResult result, {
  required String moveId,
}) {
  return _damageEvents(result, moveId: moveId).single.damage;
}

List<PsdkBattleStatusEvent> _statusEvents(
  PsdkBattleTurnResult result, {
  required String moveId,
}) {
  return result.timeline.events
      .whereType<PsdkBattleStatusEvent>()
      .where((event) => event.moveId == moveId)
      .toList(growable: false);
}

List<PsdkBattleStatusCureEvent> _cureEvents(
  PsdkBattleTurnResult result, {
  required String moveId,
}) {
  return result.timeline.events
      .whereType<PsdkBattleStatusCureEvent>()
      .where((event) => event.moveId == moveId)
      .toList(growable: false);
}

List<PsdkBattleHealEvent> _healEvents(
  PsdkBattleTurnResult result, {
  required String moveId,
}) {
  return result.timeline.events
      .whereType<PsdkBattleHealEvent>()
      .where((event) => event.moveId == moveId)
      .toList(growable: false);
}

List<PsdkBattleItemEvent> _itemEvents(PsdkBattleTurnResult result) {
  return result.timeline.events
      .whereType<PsdkBattleItemEvent>()
      .toList(growable: false);
}

BattleEffect _effect(PsdkBattleCombatant battler, String effectId) {
  return battler.effects.effects.singleWhere((effect) => effect.id == effectId);
}

BattleMoveBehaviorResolution _resolveMoveOnState({
  required PsdkBattleMoveData move,
  required PsdkBattleState state,
  PsdkBattleSlotRef user = psdkPlayerSlot,
  PsdkBattleSlotRef target = psdkOpponentSlot,
  int moveAccuracySeed = 3,
}) {
  return createStaticBasicMoveRegistry()
      .resolve(move.battleEngineMethod)
      .resolve(
        BattleMoveBehaviorContext(
          state: state,
          rng: BattleRngStreams.fromSeeds(
            moveDamageSeed: 1,
            moveCriticalSeed: 2,
            moveAccuracySeed: moveAccuracySeed,
            genericSeed: 4,
          ),
          turn: 1,
          user: user,
          target: target,
          move: BattleMoveDefinition.fromPsdk(move),
        ),
      );
}
