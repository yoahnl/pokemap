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
        playerMove: _move(
          id: 'catastropika',
          type: 'electric',
          category: PsdkBattleMoveCategory.physical,
          power: 210,
          accuracy: 0,
          battleEngineMethod: 's_z_move',
        ),
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
      (method: 's_wish', moveId: 'wish', effectId: 'wish'),
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

    test('s_destiny_bond installs a user marker until its hook exists', () {
      final result = _runMove(
        playerMove: _move(
          id: 'destiny_bond',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 0,
          battleEngineMethod: 's_destiny_bond',
          target: PsdkBattleMoveTarget.self,
        ),
      );

      final effect = _effect(
        result.state.battlerAt(psdkPlayerSlot),
        'destiny_bond',
      );
      expect(effect.scope, isA<BattlerBattleEffectScope>());
    });

    for (final entry in <({String method, String moveId})>[
      (method: 's_electrify', moveId: 'electrify'),
      (method: 's_grudge', moveId: 'grudge'),
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

    test('s_autotomize installs a marker and applies its Speed boost', () {
      final result = _runMove(
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

    for (final entry in <({String method, String moveId})>[
      (method: 's_after_you', moveId: 'after_you'),
      (method: 's_ally_switch', moveId: 'ally_switch'),
      (method: 's_magic_coat', moveId: 'magic_coat'),
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
      (method: 's_quash', moveId: 'quash', effectId: 'quash'),
    ]) {
      test('${entry.method} installs a local target marker', () {
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
      (method: 's_magic_room', moveId: 'magic_room', effectId: 'magic_room'),
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

    for (final method in <String>[
      's_avalanche',
      's_assurance',
      's_beak_blast',
      's_brick_break',
      's_core_enforcer',
      's_fake_out',
      's_feint',
      's_fell_stinger',
      's_flame_burst',
      's_flying_press',
      's_focus_punch',
      's_fusion_bolt',
      's_fusion_flare',
      's_hidden_power',
      's_judgment',
      's_jump_kick',
      's_last_resort',
      's_multi_attack',
      's_payback',
      's_payday',
      's_photon_geyser',
      's_pollen_puff',
      's_pursuit',
      's_rage',
      's_rapid_spin',
      's_revenge',
      's_revelation_dance',
      's_round',
      's_shell_trap',
      's_spectral_thief',
      's_stomp',
      's_stomping_tantrum',
      's_u_turn',
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

    test('formerly missing broad fallback methods are executable as partials',
        () {
      final entries = <({
        String method,
        String moveId,
        PsdkBattleMoveCategory category,
        int power,
      })>[
        (
          method: 's_assist',
          moveId: 'assist',
          category: PsdkBattleMoveCategory.status,
          power: 0,
        ),
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
          method: 's_frustration',
          moveId: 'frustration',
          category: PsdkBattleMoveCategory.physical,
          power: 40,
        ),
        (
          method: 's_healing_wish',
          moveId: 'healing_wish',
          category: PsdkBattleMoveCategory.status,
          power: 0,
        ),
        (
          method: 's_magnitude',
          moveId: 'magnitude',
          category: PsdkBattleMoveCategory.physical,
          power: 70,
        ),
        (
          method: 's_metronome',
          moveId: 'metronome',
          category: PsdkBattleMoveCategory.status,
          power: 0,
        ),
        (
          method: 's_mirror_move',
          moveId: 'mirror_move',
          category: PsdkBattleMoveCategory.status,
          power: 0,
        ),
        (
          method: 's_return',
          moveId: 'return',
          category: PsdkBattleMoveCategory.physical,
          power: 40,
        ),
        (
          method: 's_sleep_talk',
          moveId: 'sleep_talk',
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
        );

        expect(
          result.timeline.events.whereType<PsdkBattleMoveFailedEvent>(),
          isEmpty,
          reason: entry.method,
        );
      }
    });

    test('remaining Ruby-only missing methods are executable as partials', () {
      final entries = <({
        String method,
        String moveId,
        PsdkBattleMoveCategory category,
        int power,
      })>[
        (
          method: 's_aura_wheel',
          moveId: 'aura_wheel',
          category: PsdkBattleMoveCategory.physical,
          power: 110,
        ),
        (
          method: 's_baddy_bad',
          moveId: 'baddy_bad',
          category: PsdkBattleMoveCategory.special,
          power: 80,
        ),
        (
          method: 's_chilly_reception',
          moveId: 'chilly_reception',
          category: PsdkBattleMoveCategory.status,
          power: 0,
        ),
        (
          method: 's_corrosive_gas',
          moveId: 'corrosive_gas',
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
          method: 's_doodle',
          moveId: 'doodle',
          category: PsdkBattleMoveCategory.status,
          power: 0,
        ),
        (
          method: 's_double_iron_bash',
          moveId: 'double_iron_bash',
          category: PsdkBattleMoveCategory.physical,
          power: 60,
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
          method: 's_eerie_spell',
          moveId: 'eerie_spell',
          category: PsdkBattleMoveCategory.special,
          power: 80,
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
          method: 's_freezy_frost',
          moveId: 'freezy_frost',
          category: PsdkBattleMoveCategory.special,
          power: 100,
        ),
        (
          method: 's_genies_storm',
          moveId: 'bleakwind_storm',
          category: PsdkBattleMoveCategory.special,
          power: 100,
        ),
        (
          method: 's_geomancy',
          moveId: 'geomancy',
          category: PsdkBattleMoveCategory.status,
          power: 0,
        ),
        (
          method: 's_glaive_rush',
          moveId: 'glaive_rush',
          category: PsdkBattleMoveCategory.physical,
          power: 120,
        ),
        (
          method: 's_glitzy_glow',
          moveId: 'glitzy_glow',
          category: PsdkBattleMoveCategory.special,
          power: 80,
        ),
        (
          method: 's_grassy_glide',
          moveId: 'grassy_glide',
          category: PsdkBattleMoveCategory.physical,
          power: 55,
        ),
        (
          method: 's_grav_apple',
          moveId: 'grav_apple',
          category: PsdkBattleMoveCategory.physical,
          power: 80,
        ),
        (
          method: 's_ice_spinner',
          moveId: 'ice_spinner',
          category: PsdkBattleMoveCategory.physical,
          power: 80,
        ),
        (
          method: 's_ivy_cudgel',
          moveId: 'ivy_cudgel',
          category: PsdkBattleMoveCategory.physical,
          power: 100,
        ),
        (
          method: 's_jaw_lock',
          moveId: 'jaw_lock',
          category: PsdkBattleMoveCategory.physical,
          power: 80,
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
          method: 's_make_it_rain',
          moveId: 'make_it_rain',
          category: PsdkBattleMoveCategory.special,
          power: 120,
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
          method: 's_order_up',
          moveId: 'order_up',
          category: PsdkBattleMoveCategory.physical,
          power: 80,
        ),
        (
          method: 's_poltergeist',
          moveId: 'poltergeist',
          category: PsdkBattleMoveCategory.physical,
          power: 110,
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
          method: 's_raging_bull',
          moveId: 'raging_bull',
          category: PsdkBattleMoveCategory.physical,
          power: 90,
        ),
        (
          method: 's_revival_blessing',
          moveId: 'revival_blessing',
          category: PsdkBattleMoveCategory.status,
          power: 0,
        ),
        (
          method: 's_rising_voltage',
          moveId: 'rising_voltage',
          category: PsdkBattleMoveCategory.special,
          power: 70,
        ),
        (
          method: 's_sappy_seed',
          moveId: 'sappy_seed',
          category: PsdkBattleMoveCategory.physical,
          power: 100,
        ),
        (
          method: 's_scale_shot',
          moveId: 'scale_shot',
          category: PsdkBattleMoveCategory.physical,
          power: 25,
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
          method: 's_steel_roller',
          moveId: 'steel_roller',
          category: PsdkBattleMoveCategory.physical,
          power: 130,
        ),
        (
          method: 's_stuff_cheeks',
          moveId: 'stuff_cheeks',
          category: PsdkBattleMoveCategory.status,
          power: 0,
        ),
        (
          method: 's_super_duper_effective',
          moveId: 'sizzly_slide',
          category: PsdkBattleMoveCategory.physical,
          power: 60,
        ),
        (
          method: 's_teatime',
          moveId: 'teatime',
          category: PsdkBattleMoveCategory.status,
          power: 0,
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
        (
          method: 's_triple_arrows',
          moveId: 'triple_arrows',
          category: PsdkBattleMoveCategory.physical,
          power: 90,
        ),
        (
          method: 's_upper_hand',
          moveId: 'upper_hand',
          category: PsdkBattleMoveCategory.physical,
          power: 65,
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
  PsdkBattleStatStages? playerStages,
  PsdkBattleStatStages? opponentStages,
  PsdkBattleMoveHistory? opponentMoveHistory,
}) {
  final engine = PsdkBattleEngine(
    setup: PsdkBattleSetup.singles(
      player: _combatant(
        id: 'player',
        types: playerTypes,
        speed: 100,
        move: playerMove,
        statStages: playerStages,
        majorStatus: playerMajorStatus,
        heldItemId: playerHeldItemId,
        abilityId: playerAbilityId,
      ),
      opponent: _combatant(
        id: 'opponent',
        types: opponentTypes,
        speed: 1,
        move: _move(
          id: 'opponent_wait',
          power: 0,
          accuracy: 1,
        ),
        statStages: opponentStages,
        heldItemId: opponentHeldItemId,
        abilityId: opponentAbilityId,
        moveHistory: opponentMoveHistory,
      ),
      rngSeeds: const PsdkBattleRngSeeds(
        moveDamage: 1,
        moveCritical: 99999,
        moveAccuracy: 3,
        generic: 0,
      ),
    ),
  );
  return engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  required PsdkBattleTypes types,
  required int speed,
  required PsdkBattleMoveData move,
  PsdkBattleStatStages? statStages,
  PsdkBattleMajorStatus? majorStatus,
  String? heldItemId,
  String? abilityId,
  PsdkBattleMoveHistory? moveHistory,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 20,
    maxHp: 100,
    currentHp: 100,
    types: types,
    stats: PsdkBattleStats(
      attack: 50,
      defense: 50,
      specialAttack: 50,
      specialDefense: 50,
      speed: speed,
    ),
    statStages: statStages,
    moves: <PsdkBattleMoveData>[move],
    majorStatus: majorStatus,
    heldItemId: heldItemId,
    abilityId: abilityId,
    moveHistory: moveHistory,
  );
}

PsdkBattleMoveData _move({
  required String id,
  String type = 'normal',
  PsdkBattleMoveCategory category = PsdkBattleMoveCategory.physical,
  required int power,
  int accuracy = 100,
  int? effectChance,
  String battleEngineMethod = 's_basic',
  PsdkBattleMoveTarget target = PsdkBattleMoveTarget.adjacentFoe,
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
    effectChance: effectChance,
    battleEngineMethod: battleEngineMethod,
    target: target,
    statuses: statuses,
    stageMods: stageMods,
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

BattleEffect _effect(PsdkBattleCombatant battler, String effectId) {
  return battler.effects.effects.singleWhere((effect) => effect.id == effectId);
}
