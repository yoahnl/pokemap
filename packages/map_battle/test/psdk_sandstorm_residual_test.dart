import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK sandstorm residual damage', () {
    for (final entry in <(int, int, int)>[
      (160, 160, 150),
      (15, 15, 14),
      (160, 3, 0),
    ]) {
      test('damages ${entry.$2}/${entry.$1} HP to ${entry.$3}', () {
        final context = _context(
          player: _combatant(maxHp: entry.$1, currentHp: entry.$2),
        );
        final result = const BattleEndTurnHandler().tickField(context);

        expect(result.state.battlerAt(psdkPlayerSlot).currentHp, entry.$3);
        expect(result.state.field.weather?.remainingTurns, 2);
        expect(result.rng, same(context.rng));
        expect(context.state.battlerAt(psdkPlayerSlot).currentHp, entry.$2);
      });
    }

    test('expires before applying any residual damage', () {
      final result = const BattleEndTurnHandler().tickField(
        _context(remainingTurns: 1),
      );

      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 160);
      expect(result.state.field.weather, isNull);
      expect(result.events.map((event) => event.kind), ['weather_changed']);
    });

    for (final type in ['rock', 'ground', 'steel']) {
      test('protects $type types', () {
        final result = const BattleEndTurnHandler().tickField(
          _context(player: _combatant(type: type)),
        );

        expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 160);
      });
    }

    for (final ability in [
      'magic_guard',
      'sand_veil',
      'sand_rush',
      'sand_force',
      'overcoat',
    ]) {
      test('protects effective $ability', () {
        final result = const BattleEndTurnHandler().tickField(
          _context(player: _combatant(abilityId: ability)),
        );

        expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 160);
      });

      test('does not protect suppressed $ability', () {
        final result = const BattleEndTurnHandler().tickField(
          _context(
            player: _combatant(
              abilityId: ability,
              effects: PsdkBattleEffectStack(values: ['ability_suppressed']),
            ),
          ),
        );

        expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 150);
      });
    }

    test('applies weather before Leftovers on a full health battler', () {
      final result = const BattleEndTurnHandler().resolveEndTurn(
        _context(player: _combatant(heldItemId: 'leftovers')),
      );

      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 160);
      expect(result.events.map((event) => event.kind),
          containsAllInOrder(['weather_damage', 'heal']));
    });

    test('does not heal a sandstorm KO through Leftovers', () {
      final result = const BattleEndTurnHandler().resolveEndTurn(
        _context(player: _combatant(currentHp: 5, heldItemId: 'leftovers')),
      );

      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 0);
      expect(result.events.whereType<PsdkBattleHealEvent>(), isEmpty);
    });

    test('emits typed slot damage with lossless timeline conversion', () {
      final result = const BattleEndTurnHandler().tickField(
        _context(player: _combatant(currentHp: 3)),
      );
      final event =
          result.events.whereType<PsdkBattleWeatherDamageEvent>().single;

      expect(event.toJson(), {
        'kind': 'weather_damage',
        'turn': 5,
        'target': psdkPlayerSlot.toJson(),
        'weather': 'sandstorm',
        'damage': 3,
        'remainingHp': 0,
      });
      final canonical = BattleTimelineEvent.fromPsdk(event);
      expect(canonical, isA<BattleWeatherDamageTimelineEvent>());
      expect(canonical.toJson(), event.toJson());
      expect(canonical.toPsdkEvent()!.toJson(), event.toJson());
    });

    test('supports an indefinite weather duration', () {
      final result = const BattleEndTurnHandler().tickField(
        _context(remainingTurns: null),
      );

      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 150);
      expect(result.state.field.weather?.remainingTurns, isNull);
    });

    test('leaves reserve and already fainted combatants unchanged', () {
      final result = const BattleEndTurnHandler().tickField(
        _context(
          player: _combatant(currentHp: 0),
          reserves: [_combatant(id: 'reserve')],
        ),
      );

      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 0);
      expect(result.state.partyForBank(0)[1].currentHp, 160);
      expect(result.events.whereType<PsdkBattleWeatherDamageEvent>(), isEmpty);
    });

    test('uses active third and temporary types for immunity', () {
      for (final player in [
        _combatant(type3: 'rock'),
        _combatant(temporaryTypes: ['steel']),
      ]) {
        final context = _context(player: player);
        final result = const BattleEndTurnHandler().tickField(context);

        expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 160);
      }
    });

    for (final ability in ['air_lock', 'cloud_nine']) {
      test('$ability suppresses damage while the weather still ticks', () {
        final result = const BattleEndTurnHandler().tickField(
          _context(opponent: _combatant(id: 'opponent', abilityId: ability)),
        );

        expect(
            result.state.combatants.values.map((battler) => battler.currentHp),
            [160, 160]);
        expect(result.state.field.weather?.remainingTurns, 2);
        expect(
            result.events.whereType<PsdkBattleWeatherDamageEvent>(), isEmpty);
      });

      test('suppressed $ability does not suppress damage', () {
        final result = const BattleEndTurnHandler().tickField(
          _context(
            opponent: _combatant(
              id: 'opponent',
              abilityId: ability,
              effects: PsdkBattleEffectStack(values: ['ability_suppressed']),
            ),
          ),
        );

        expect(
            result.state.combatants.values.map((battler) => battler.currentHp),
            [150, 150]);
        expect(
            result.events
                .whereType<PsdkBattleWeatherDamageEvent>()
                .map((event) => event.target),
            [psdkPlayerSlot, psdkOpponentSlot]);
      });
    }

    test('effective safety goggles prevent weather damage', () {
      final result = const BattleEndTurnHandler().tickField(
        _context(player: _combatant(heldItemId: 'safety_goggles')),
      );

      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 160);
    });

    for (final player in [
      _combatant(heldItemId: 'safety_goggles', itemConsumed: true),
      _combatant(heldItemId: 'safety_goggles', abilityId: 'klutz'),
      _combatant(
        heldItemId: 'safety_goggles',
        effects: PsdkBattleEffectStack(values: ['embargo']),
      ),
      _combatant(
        heldItemId: 'safety_goggles',
        effects: PsdkBattleEffectStack(values: ['magic_room']),
      ),
    ]) {
      test(
          'inactive safety goggles do not protect: ${player.abilityId} '
          '${player.itemConsumed} ${player.effects.values}', () {
        final result = const BattleEndTurnHandler().tickField(
          _context(player: player),
        );

        expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 150);
      });
    }

    test('suppressed Klutz restores goggles protection', () {
      final result = const BattleEndTurnHandler().tickField(
        _context(
          player: _combatant(
            heldItemId: 'safety_goggles',
            abilityId: 'klutz',
            effects: PsdkBattleEffectStack(values: ['ability_suppressed']),
          ),
        ),
      );

      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 160);
    });

    test('field Magic Room on another slot disables safety goggles', () {
      final result = const BattleEndTurnHandler().tickField(
        _context(
          player: _combatant(heldItemId: 'safety_goggles'),
          opponent: _combatant(
            id: 'opponent',
            type: 'rock',
            effects: const PsdkBattleEffectStack.empty().addEffect(
              const GenericBattleEffect(
                id: 'magic_room',
                scope: FieldBattleEffectScope(),
              ),
            ),
          ),
        ),
      );

      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 150);
    });

    test('does not add sandstorm residual to other or absent weather', () {
      for (final weather in <PsdkBattleWeatherId?>[
        null,
        PsdkBattleWeatherId.rain,
        PsdkBattleWeatherId.sunny,
      ]) {
        final result = const BattleEndTurnHandler().tickField(
          _context(weather: weather),
        );

        expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 160);
        expect(
            result.events.whereType<PsdkBattleWeatherDamageEvent>(), isEmpty);
      }
    });

    test('out of reach protects without inventing immunity for other effects',
        () {
      for (final effectId in ['out_of_reach_base', 'protect']) {
        final result = const BattleEndTurnHandler().tickField(
          _context(
            player: _combatant(
              effects: PsdkBattleEffectStack(values: [effectId]),
            ),
          ),
        );

        expect(result.state.battlerAt(psdkPlayerSlot).currentHp,
            effectId == 'out_of_reach_base' ? 160 : 150);
      }
    });

    test('bypasses attack survival and retaliation hooks without rolling RNG',
        () {
      for (final player in [
        _combatant(maxHp: 1, currentHp: 1, abilityId: 'sturdy'),
        _combatant(maxHp: 1, currentHp: 1, heldItemId: 'focus_sash'),
        _combatant(currentHp: 1, heldItemId: 'focus_band'),
        _combatant(currentHp: 1, abilityId: 'rough_skin'),
        _combatant(
          currentHp: 1,
          effects: PsdkBattleEffectStack(values: ['endure']),
        ),
      ]) {
        final context = _context(player: player);
        final result = const BattleEndTurnHandler().tickField(context);

        expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 0);
        expect(result.state.battlerAt(psdkOpponentSlot).currentHp, 160);
        expect(result.state.battlerAt(psdkPlayerSlot).itemConsumed, isFalse);
        expect(result.events.map((event) => event.kind), ['weather_damage']);
        expect(result.rng, same(context.rng));
      }
    });

    test('delays a weather-triggered berry until after terrain healing', () {
      final result = const BattleEndTurnHandler().resolveEndTurn(
        _context(
          player: _combatant(currentHp: 85, heldItemId: 'sitrus_berry'),
          terrain: const PsdkBattleTerrainState(
            id: PsdkBattleTerrainId.grassyTerrain,
            remainingTurns: 3,
          ),
        ),
      );

      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 85);
      expect(result.state.battlerAt(psdkPlayerSlot).itemConsumed, isFalse);
      expect(
          result.events.map((event) => event.kind), ['weather_damage', 'heal']);
      expect(result.events.whereType<PsdkBattleHealEvent>().single.moveId,
          'terrain:grassy_terrain');
    });

    test('consumes a berry crossed into range by weather during the item phase',
        () {
      final result = const BattleEndTurnHandler().resolveEndTurn(
        _context(
          player: _combatant(currentHp: 85, heldItemId: 'sitrus_berry'),
        ),
      );

      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 115);
      expect(result.state.battlerAt(psdkPlayerSlot).itemConsumed, isTrue);
      expect(result.events.map((event) => event.kind),
          containsAllInOrder(['weather_damage', 'heal', 'item_consumed']));
    });

    test('weather KO prevents later ability activation', () {
      final result = const BattleEndTurnHandler().resolveEndTurn(
        _context(
          player: _combatant(currentHp: 5, abilityId: 'speed_boost'),
        ),
      );

      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 0);
      expect(result.events.whereType<PsdkBattleStatStageEvent>(), isEmpty);
    });

    test('suppressed end-turn abilities stay inactive after weather damage',
        () {
      final result = const BattleEndTurnHandler().resolveEndTurn(
        _context(
          player: _combatant(
            abilityId: 'speed_boost',
            effects: PsdkBattleEffectStack(values: ['ability_suppressed']),
          ),
        ),
      );

      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 150);
      expect(result.events.whereType<PsdkBattleStatStageEvent>(), isEmpty);
    });

    test('inactive items cannot restore HP after weather damage', () {
      for (final context in [
        _context(
          player: _combatant(heldItemId: 'leftovers', abilityId: 'klutz'),
        ),
        _context(
          player: _combatant(
            heldItemId: 'leftovers',
            effects: PsdkBattleEffectStack(values: ['embargo']),
          ),
        ),
        _context(
          player: _combatant(heldItemId: 'leftovers'),
          opponent: _combatant(
            id: 'opponent',
            type: 'rock',
            effects: const PsdkBattleEffectStack.empty().addEffect(
              const GenericBattleEffect(
                id: 'magic_room',
                scope: FieldBattleEffectScope(),
              ),
            ),
          ),
        ),
      ]) {
        final result = const BattleEndTurnHandler().resolveEndTurn(context);

        expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 150);
        expect(result.events.whereType<PsdkBattleHealEvent>(), isEmpty);
      }
    });

    test('a weather KO cannot be rescued by terrain or a berry', () {
      final result = const BattleEndTurnHandler().resolveEndTurn(
        _context(
          player: _combatant(currentHp: 5, heldItemId: 'sitrus_berry'),
          terrain: const PsdkBattleTerrainState(
            id: PsdkBattleTerrainId.grassyTerrain,
            remainingTurns: 3,
          ),
        ),
      );

      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 0);
      expect(result.state.battlerAt(psdkPlayerSlot).itemConsumed, isFalse);
      expect(result.events.whereType<PsdkBattleHealEvent>(), isEmpty);
    });

    test('applies major status damage before weather', () {
      final result = const BattleEndTurnHandler().resolveEndTurn(
        _context(
          player: _combatant(majorStatus: PsdkBattleMajorStatus.burn),
        ),
      );

      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 130);
      expect(result.events.map((event) => event.kind),
          containsAllInOrder(['damage', 'weather_damage']));
    });

    test('resolves abilities and items by base speed after field damage', () {
      final result = const BattleEndTurnHandler().resolveEndTurn(
        _context(
          player: _combatant(
            speed: 50,
            abilityId: 'speed_boost',
            heldItemId: 'leftovers',
            statStages: PsdkBattleStatStages(values: {'speed': 5}),
            effects: const PsdkBattleEffectStack.empty().addEffect(
              const TrickRoomEffect(),
            ),
          ),
          opponent: _combatant(
            id: 'opponent',
            speed: 80,
            abilityId: 'speed_boost',
            heldItemId: 'leftovers',
            statStages: PsdkBattleStatStages(values: {'speed': -6}),
          ),
        ),
      );

      final damage = result.events.whereType<PsdkBattleWeatherDamageEvent>();
      final stages = result.events.whereType<PsdkBattleStatStageEvent>();
      final heals = result.events.whereType<PsdkBattleHealEvent>();
      expect(damage.map((event) => event.target),
          [psdkPlayerSlot, psdkOpponentSlot]);
      expect(stages.map((event) => event.target),
          [psdkOpponentSlot, psdkPlayerSlot]);
      expect(heals.map((event) => event.target),
          [psdkOpponentSlot, psdkPlayerSlot]);
      expect(result.events.map((event) => event.kind), [
        'effect_ticked',
        'weather_damage',
        'weather_damage',
        'stat_stage_change',
        'stat_stage_change',
        'heal',
        'heal',
      ]);
      expect(
        result.state
            .battlerAt(psdkPlayerSlot)
            .effects
            .effects
            .whereType<TrickRoomEffect>()
            .single
            .remainingTurns,
        4,
      );
    });

    test('a weather KO requests a reserve without charging a second turn', () {
      final session = _session(
        player: _combatant(currentHp: 5),
        reserves: [_combatant(id: 'reserve', type: 'steel')],
      );
      final result = session.submit(const BattleDecision.fight(moveSlot: 0));

      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 0);
      expect(result.nextRequest?.kind,
          BattleEngineDecisionRequestKind.forcedReplacement);
      expect(
          result.timeline.events.whereType<BattleWeatherDamageTimelineEvent>(),
          hasLength(1));
      final replaced = session.submit(
        const BattleDecision.switchPokemon(partyIndex: 1),
      );
      expect(replaced.state.battlerAt(psdkPlayerSlot).id, 'reserve');
      expect(replaced.state.turnNumber, 1);
      expect(
          replaced.timeline.events
              .whereType<BattleWeatherDamageTimelineEvent>(),
          isEmpty);
    });

    test('a final weather KO ends the battle without another choice', () {
      final session = _session(player: _combatant(currentHp: 5));
      final result = session.submit(const BattleDecision.fight(moveSlot: 0));

      expect(result.outcome?.kind, BattleEngineOutcomeKind.defeat);
      expect(result.nextRequest, isNull);
      expect(session.decisionRequest.kind,
          BattleEngineDecisionRequestKind.finished);
      expect(result.timeline.events.map((event) => event.kind),
          containsAllInOrder(['weather_damage', 'battle_ended']));
    });
  });
}

BattleHandlerContext _context({
  PsdkBattleCombatantSetup? player,
  PsdkBattleCombatantSetup? opponent,
  int? remainingTurns = 3,
  List<PsdkBattleCombatantSetup> reserves = const [],
  PsdkBattleTerrainState? terrain,
  PsdkBattleWeatherId? weather = PsdkBattleWeatherId.sandstorm,
}) {
  return BattleHandlerContext(
    state: PsdkBattleState.fromSetup(
      PsdkBattleSetup.singlesPokeMapBetaV1ForTest(
        player: player ?? _combatant(),
        opponent: opponent ?? _combatant(id: 'opponent', type: 'rock'),
        playerReserves: reserves,
        rngSeeds: const PsdkBattleRngSeeds(
          moveDamage: 1,
          moveCritical: 2,
          moveAccuracy: 3,
          generic: 4,
        ),
        field: PsdkBattleFieldState(
          terrain: terrain,
          weather: weather == null
              ? null
              : PsdkBattleWeatherState(
                  id: weather,
                  remainingTurns: remainingTurns,
                ),
        ),
      ),
    ),
    rng: BattleRngStreams.fromSeeds(
      moveDamageSeed: 1,
      moveCriticalSeed: 2,
      moveAccuracySeed: 3,
      genericSeed: 4,
    ),
    turn: 5,
    user: psdkPlayerSlot,
  );
}

PsdkBattleCombatantSetup _combatant({
  String id = 'player',
  String type = 'normal',
  int maxHp = 160,
  int currentHp = 160,
  String? abilityId,
  String? heldItemId,
  bool itemConsumed = false,
  int speed = 50,
  String? type3,
  List<String> temporaryTypes = const [],
  PsdkBattleMajorStatus? majorStatus,
  PsdkBattleStatStages? statStages,
  PsdkBattleEffectStack effects = const PsdkBattleEffectStack.empty(),
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 20,
    maxHp: maxHp,
    currentHp: currentHp,
    types: PsdkBattleTypes(primary: type),
    abilityId: abilityId,
    heldItemId: heldItemId,
    itemConsumed: itemConsumed,
    majorStatus: majorStatus,
    statStages: statStages,
    type3: type3,
    temporaryTypes: temporaryTypes,
    stats: PsdkBattleStats(
      attack: 50,
      defense: 50,
      specialAttack: 50,
      specialDefense: 50,
      speed: speed,
    ),
    moves: [
      PsdkBattleMoveData(
        id: 'splash',
        dbSymbol: 'splash',
        name: 'Splash',
        type: 'normal',
        category: PsdkBattleMoveCategory.status,
        power: 0,
        accuracy: 0,
        pp: 40,
        priority: 0,
        criticalRate: 1,
        battleEngineMethod: 's_splash',
        target: PsdkBattleMoveTarget.none,
      ),
    ],
    effects: effects,
  );
}

BattleSessionFacade _session({
  required PsdkBattleCombatantSetup player,
  List<PsdkBattleCombatantSetup> reserves = const [],
}) {
  return BattleSessionFacade.fromPsdkSetup(
    setup: PsdkBattleSetup.singlesPokeMapBetaV1ForTest(
      player: player,
      opponent: _combatant(id: 'opponent', type: 'rock'),
      playerReserves: reserves,
      rngSeeds: const PsdkBattleRngSeeds(
        moveDamage: 1,
        moveCritical: 2,
        moveAccuracy: 3,
        generic: 4,
      ),
      field: const PsdkBattleFieldState(
        weather: PsdkBattleWeatherState(
          id: PsdkBattleWeatherId.sandstorm,
          remainingTurns: 3,
        ),
      ),
    ),
  );
}
