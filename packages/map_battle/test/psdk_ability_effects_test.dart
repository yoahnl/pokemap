import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK ability effects', () {
    test('hydrates known ability ids into the battler effect stack', () {
      final state = PsdkBattleState.fromSetup(
        BattleEngineSetup.singles(
          player: _combatant(
            id: 'player',
            abilityId: 'skill_link',
            move: _move(id: 'tackle', power: 40),
          ),
          opponent: _combatant(
            id: 'opponent',
            move: _move(id: 'tackle', power: 40),
          ),
          rngSeeds: const BattleRngSeeds(
            moveDamage: 1,
            moveCritical: 99999,
            moveAccuracy: 3,
            generic: 4,
          ).psdkSeeds,
        ).psdkSetup,
      );
      final battler = state.battlerAt(psdkPlayerSlot);

      expect(battler.abilityId, 'skill_link');
      expect(battler.effects.contains('ability:skill_link'), isTrue);
    });

    for (final move in <({String id, String method})>[
      (id: 'explosion', method: 's_explosion'),
      (id: 'misty_explosion', method: 's_misty_explosion'),
      (id: 'mind_blown', method: 's_mind_blown'),
      (id: 'steel_beam', method: 's_steel_beam'),
      (id: 'chloroblast', method: 's_chloroblast'),
    ]) {
      test('Damp prevents ${move.method} before PP and damage apply', () {
        final result = _runMove(
          opponentAbilityId: 'damp',
          playerMove: _move(
            id: move.id,
            power: 250,
            battleEngineMethod: move.method,
          ),
        );

        final events = _eventsFor(result, moveId: move.id);
        expect(events.map((event) => event.kind), <String>['move_failed']);
        expect((events.single as PsdkBattleMoveFailedEvent).reason,
            BattleMoveFailureReason.unusableByUser.jsonName);
        expect(_damageEvents(result, moveId: move.id), isEmpty);
        expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 100);
        expect(result.state.battlerAt(psdkOpponentSlot).currentHp, 100);
        expect(
          result.state.battlerAt(psdkPlayerSlot).moves.single.currentPp,
          35,
        );
      });
    }

    test('Shadow Tag prevents opposing non-Ghost switch attempts', () {
      final state = PsdkBattleState.fromSetup(
        BattleEngineSetup.singles(
          player: _combatant(
            id: 'player',
            move: _move(id: 'tackle', power: 40),
          ),
          opponent: _combatant(
            id: 'opponent',
            abilityId: 'shadow_tag',
            move: _move(id: 'opponent_wait', power: 0),
          ),
          rngSeeds: const BattleRngSeeds(
            moveDamage: 1,
            moveCritical: 99999,
            moveAccuracy: 3,
            generic: 4,
          ).psdkSeeds,
        ).psdkSetup,
      );

      final prevention = const BattleSwitchHandler().resolveSwitchPrevention(
        context: BattleHandlerContext(
          state: state,
          rng: _rng(),
          turn: 1,
          user: psdkPlayerSlot,
        ),
        target: psdkPlayerSlot,
      );

      expect(prevention.applied, isFalse);
      expect(prevention.reason, 'ability:shadow_tag');
    });

    test('Shadow Tag does not trap Ghost or opposing Shadow Tag battlers', () {
      final ghost = _switchPreventionFor(
        playerTypes: const PsdkBattleTypes(primary: 'ghost'),
        opponentAbilityId: 'shadow_tag',
      );
      final mirror = _switchPreventionFor(
        playerAbilityId: 'shadow_tag',
        opponentAbilityId: 'shadow_tag',
      );

      expect(ghost.applied, isTrue);
      expect(ghost.reason, isNull);
      expect(mirror.applied, isTrue);
      expect(mirror.reason, isNull);
    });

    test('Magnet Pull traps only opposing Steel battlers', () {
      final steel = _switchPreventionFor(
        playerTypes: const PsdkBattleTypes(primary: 'steel'),
        opponentAbilityId: 'magnet_pull',
      );
      final normal = _switchPreventionFor(
        opponentAbilityId: 'magnet_pull',
      );

      expect(steel.applied, isFalse);
      expect(steel.reason, 'ability:magnet_pull');
      expect(normal.applied, isTrue);
      expect(normal.reason, isNull);
    });

    test('Arena Trap traps only opposing grounded battlers', () {
      final grounded = _switchPreventionFor(
        opponentAbilityId: 'arena_trap',
      );
      final flying = _switchPreventionFor(
        playerTypes: const PsdkBattleTypes(primary: 'flying'),
        opponentAbilityId: 'arena_trap',
      );
      final levitate = _switchPreventionFor(
        playerAbilityId: 'levitate',
        opponentAbilityId: 'arena_trap',
      );

      expect(grounded.applied, isFalse);
      expect(grounded.reason, 'ability:arena_trap');
      expect(flying.applied, isTrue);
      expect(flying.reason, isNull);
      expect(levitate.applied, isTrue);
      expect(levitate.reason, isNull);
    });

    test('Drizzle sets rain on switch-in and respects Damp Rock duration', () {
      final result = _dispatchAbilitySwitchIn(
        playerAbilityId: 'drizzle',
        playerHeldItemId: 'damp_rock',
      );

      expect(result.applied, isTrue);
      expect(result.state.field.weather?.id, PsdkBattleWeatherId.rain);
      expect(result.state.field.weather?.remainingTurns, 8);
      expect(
        result.events.whereType<PsdkBattleWeatherChangedEvent>().single.weather,
        PsdkBattleWeatherId.rain,
      );
    });

    test('weather switch-in abilities map to their PSDK weather ids', () {
      for (final entry in <String, PsdkBattleWeatherId>{
        'drizzle': PsdkBattleWeatherId.rain,
        'drought': PsdkBattleWeatherId.sunny,
        'sand_stream': PsdkBattleWeatherId.sandstorm,
        'snow_warning': PsdkBattleWeatherId.hail,
      }.entries) {
        final result = _dispatchAbilitySwitchIn(playerAbilityId: entry.key);

        expect(result.applied, isTrue, reason: entry.key);
        expect(result.state.field.weather?.id, entry.value, reason: entry.key);
        expect(
          result.state.field.weather?.remainingTurns,
          5,
          reason: entry.key,
        );
      }
    });

    test('Psychic Surge sets terrain on switch-in with Terrain Extender', () {
      final result = _dispatchAbilitySwitchIn(
        playerAbilityId: 'psychic_surge',
        playerHeldItemId: 'terrain_extender',
      );

      expect(result.applied, isTrue);
      expect(
        result.state.field.terrain?.id,
        PsdkBattleTerrainId.psychicTerrain,
      );
      expect(result.state.field.terrain?.remainingTurns, 8);
      expect(
        result.events.whereType<PsdkBattleTerrainChangedEvent>().single.terrain,
        PsdkBattleTerrainId.psychicTerrain,
      );
    });

    test('terrain switch-in abilities map to their PSDK terrain ids', () {
      for (final entry in <String, PsdkBattleTerrainId>{
        'electric_surge': PsdkBattleTerrainId.electricTerrain,
        'grassy_surge': PsdkBattleTerrainId.grassyTerrain,
        'misty_surge': PsdkBattleTerrainId.mistyTerrain,
        'psychic_surge': PsdkBattleTerrainId.psychicTerrain,
      }.entries) {
        final result = _dispatchAbilitySwitchIn(playerAbilityId: entry.key);

        expect(result.applied, isTrue, reason: entry.key);
        expect(result.state.field.terrain?.id, entry.value, reason: entry.key);
        expect(
          result.state.field.terrain?.remainingTurns,
          5,
          reason: entry.key,
        );
      }
    });

    test('Intimidate lowers opposing active attack on switch-in', () {
      final result = _dispatchAbilitySwitchIn(playerAbilityId: 'intimidate');

      expect(result.applied, isTrue);
      expect(
        result.state.battlerAt(psdkOpponentSlot).statStages.valueOf('attack'),
        -1,
      );
      expect(
        result.events.whereType<PsdkBattleStatStageEvent>().single.amount,
        -1,
      );
    });

    test('Intimidate does not lower Gen 8 immune abilities', () {
      final result = _dispatchAbilitySwitchIn(
        playerAbilityId: 'intimidate',
        opponentAbilityId: 'inner_focus',
      );

      expect(result.applied, isFalse);
      expect(result.reason, 'no_switch_events');
      expect(
        result.state.battlerAt(psdkOpponentSlot).statStages.valueOf('attack'),
        0,
      );
      expect(result.events.whereType<PsdkBattleStatStageEvent>(), isEmpty);
    });

    test('Rattled gains Speed after an activated Intimidate stat drop', () {
      final result = _dispatchAbilitySwitchIn(
        playerAbilityId: 'intimidate',
        opponentAbilityId: 'rattled',
      );

      expect(result.applied, isTrue);
      expect(
        result.state.battlerAt(psdkOpponentSlot).statStages.valueOf('attack'),
        -1,
      );
      expect(
        result.state.battlerAt(psdkOpponentSlot).statStages.valueOf('speed'),
        1,
      );
      expect(
        result.events.whereType<PsdkBattleStatStageEvent>().map(
              (event) => event.stat,
            ),
        <String>['attack', 'speed'],
      );
    });

    test('Rattled does not react to non-Intimidate stat changes', () {
      final state = PsdkBattleState.fromSetup(
        BattleEngineSetup.singles(
          player: _combatant(
            id: 'player',
            abilityId: 'intimidate',
            move: _move(id: 'fake_drop', power: 0),
          ),
          opponent: _combatant(
            id: 'opponent',
            abilityId: 'rattled',
            move: _move(id: 'opponent_wait', power: 0),
          ),
          rngSeeds: const BattleRngSeeds(
            moveDamage: 1,
            moveCritical: 99999,
            moveAccuracy: 3,
            generic: 4,
          ).psdkSeeds,
        ).psdkSetup,
      );

      final result = const BattleStatChangeHandler().applyStatChange(
        context: BattleHandlerContext(
          state: state,
          rng: _rng(),
          turn: 1,
          user: psdkPlayerSlot,
        ),
        target: psdkOpponentSlot,
        stat: 'attack',
        stages: -1,
      );

      expect(result.state.battlerAt(psdkOpponentSlot).abilityId, 'rattled');
      expect(
        result.state.battlerAt(psdkOpponentSlot).statStages.valueOf('attack'),
        -1,
      );
      expect(
        result.state.battlerAt(psdkOpponentSlot).statStages.valueOf('speed'),
        0,
      );
      expect(
        result.events.whereType<PsdkBattleStatStageEvent>().map(
              (event) => event.stat,
            ),
        <String>['attack'],
      );
    });

    test('Contrary and Simple transform incoming stat stage changes', () {
      final contraryDrop = _applyPlayerStatDrop(
        playerAbilityId: 'contrary',
        stat: 'attack',
      );
      final contraryBoost = _applyPlayerStatDrop(
        playerAbilityId: 'contrary',
        stat: 'attack',
        stages: 1,
      );
      final simpleDrop = _applyPlayerStatDrop(
        playerAbilityId: 'simple',
        stat: 'defense',
      );
      final simpleBoost = _applyPlayerStatDrop(
        playerAbilityId: 'simple',
        stat: 'speed',
        stages: 1,
      );

      expect(
        contraryDrop.state.battlerAt(psdkPlayerSlot).statStages.valueOf(
              'attack',
            ),
        1,
      );
      expect(_statEventsForHandler(contraryDrop).single.amount, 1);

      expect(
        contraryBoost.state.battlerAt(psdkPlayerSlot).statStages.valueOf(
              'attack',
            ),
        -1,
      );
      expect(_statEventsForHandler(contraryBoost).single.amount, -1);

      expect(
        simpleDrop.state.battlerAt(psdkPlayerSlot).statStages.valueOf(
              'defense',
            ),
        -2,
      );
      expect(_statEventsForHandler(simpleDrop).single.amount, -2);

      expect(
        simpleBoost.state.battlerAt(psdkPlayerSlot).statStages.valueOf(
              'speed',
            ),
        2,
      );
      expect(_statEventsForHandler(simpleBoost).single.amount, 2);
    });

    test('Defiant and Competitive punish opposing stat drops', () {
      final defiant = _applyPlayerStatDrop(
        playerAbilityId: 'defiant',
        stat: 'defense',
      );
      final competitive = _applyPlayerStatDrop(
        playerAbilityId: 'competitive',
        stat: 'defense',
      );
      final selfDrop = _applyPlayerStatDrop(
        playerAbilityId: 'defiant',
        stat: 'defense',
        user: psdkPlayerSlot,
      );

      expect(
        defiant.state.battlerAt(psdkPlayerSlot).statStages.valueOf('defense'),
        -1,
      );
      expect(
        defiant.state.battlerAt(psdkPlayerSlot).statStages.valueOf('attack'),
        2,
      );
      expect(
        _statEventsForHandler(defiant).map((event) => event.stat),
        <String>['defense', 'attack'],
      );

      expect(
        competitive.state
            .battlerAt(psdkPlayerSlot)
            .statStages
            .valueOf('specialAttack'),
        2,
      );
      expect(
        _statEventsForHandler(competitive).map((event) => event.stat),
        <String>['defense', 'specialAttack'],
      );

      expect(
        selfDrop.state.battlerAt(psdkPlayerSlot).statStages.valueOf('attack'),
        0,
      );
      expect(_statEventsForHandler(selfDrop), hasLength(1));
    });

    test('Guard Dog turns activated Intimidate into an Attack boost', () {
      final result = _dispatchAbilitySwitchIn(
        playerAbilityId: 'intimidate',
        opponentAbilityId: 'guard_dog',
      );

      expect(result.applied, isTrue);
      expect(
        result.state.battlerAt(psdkOpponentSlot).statStages.valueOf('attack'),
        1,
      );
      expect(
        result.events.whereType<PsdkBattleStatStageEvent>().single.amount,
        1,
      );
    });

    test('switch-in stat boost abilities raise the owner stat', () {
      final dauntless =
          _dispatchAbilitySwitchIn(playerAbilityId: 'dauntless_shield');
      final intrepid =
          _dispatchAbilitySwitchIn(playerAbilityId: 'intrepid_sword');

      expect(dauntless.applied, isTrue);
      expect(
        dauntless.state.battlerAt(psdkPlayerSlot).statStages.valueOf('defense'),
        1,
      );
      expect(
        dauntless.events.whereType<PsdkBattleStatStageEvent>().single.stat,
        'defense',
      );

      expect(intrepid.applied, isTrue);
      expect(
        intrepid.state.battlerAt(psdkPlayerSlot).statStages.valueOf('attack'),
        1,
      );
      expect(
        intrepid.events.whereType<PsdkBattleStatStageEvent>().single.stat,
        'attack',
      );
    });

    test('Download chooses Attack or Special Attack from foe defenses', () {
      final attackBoost = _dispatchAbilitySwitchIn(
        playerAbilityId: 'download',
        opponentStats: const PsdkBattleStats(
          attack: 70,
          defense: 40,
          specialAttack: 70,
          specialDefense: 80,
          speed: 70,
        ),
      );
      final specialAttackBoost = _dispatchAbilitySwitchIn(
        playerAbilityId: 'download',
        opponentStats: const PsdkBattleStats(
          attack: 70,
          defense: 90,
          specialAttack: 70,
          specialDefense: 80,
          speed: 70,
        ),
      );

      expect(attackBoost.applied, isTrue);
      expect(
        attackBoost.state
            .battlerAt(psdkPlayerSlot)
            .statStages
            .valueOf('attack'),
        1,
      );
      expect(
        attackBoost.events.whereType<PsdkBattleStatStageEvent>().single.stat,
        'attack',
      );

      expect(specialAttackBoost.applied, isTrue);
      expect(
        specialAttackBoost.state
            .battlerAt(psdkPlayerSlot)
            .statStages
            .valueOf('specialAttack'),
        1,
      );
      expect(
        specialAttackBoost.events
            .whereType<PsdkBattleStatStageEvent>()
            .single
            .stat,
        'specialAttack',
      );
    });

    test('Frisk reveals the first living opposing held item on switch-in', () {
      final result = _dispatchAbilitySwitchIn(
        playerAbilityId: 'frisk',
        opponentHeldItemId: 'leftovers',
      );
      final noItem = _dispatchAbilitySwitchIn(playerAbilityId: 'frisk');

      expect(result.applied, isTrue);
      expect(
        result.events.whereType<PsdkBattleEffectEvent>().single.toJson(),
        containsPair('effectId', 'frisk:item:leftovers'),
      );
      expect(noItem.applied, isFalse);
      expect(noItem.reason, 'no_switch_events');
    });

    test('Forewarn reveals the strongest opposing damaging move', () {
      final result = _dispatchAbilitySwitchIn(
        playerAbilityId: 'forewarn',
        opponentMoves: <PsdkBattleMoveData>[
          _move(id: 'growl', power: 0),
          _move(id: 'ember', type: 'fire', power: 40),
          _move(id: 'hyper_beam', power: 150),
        ],
      );
      final statusOnly = _dispatchAbilitySwitchIn(
        playerAbilityId: 'forewarn',
        opponentMoves: <PsdkBattleMoveData>[
          _move(id: 'splash', power: 0),
          _move(id: 'protect', power: 0),
        ],
      );

      expect(result.applied, isTrue);
      expect(
        result.events.whereType<PsdkBattleEffectEvent>().single.toJson(),
        containsPair('effectId', 'forewarn:move:hyper_beam'),
      );
      expect(statusOnly.applied, isFalse);
      expect(statusOnly.reason, 'no_switch_events');
    });

    test('Trace copies a valid opposing ability and hydrates its effect', () {
      final result = _dispatchAbilitySwitchIn(
        playerAbilityId: 'trace',
        opponentAbilityId: 'water_absorb',
      );
      final forbidden = _dispatchAbilitySwitchIn(
        playerAbilityId: 'trace',
        opponentAbilityId: 'wonder_guard',
      );

      expect(result.applied, isTrue);
      expect(result.state.battlerAt(psdkPlayerSlot).abilityId, 'water_absorb');
      expect(
        result.state
            .battlerAt(psdkPlayerSlot)
            .effects
            .contains('ability:water_absorb'),
        isTrue,
      );
      expect(
        result.events.whereType<PsdkBattleEffectEvent>().first.toJson(),
        containsPair('effectId', 'trace:ability:water_absorb'),
      );
      expect(forbidden.applied, isFalse);
      expect(forbidden.reason, 'no_switch_events');
      expect(forbidden.state.battlerAt(psdkPlayerSlot).abilityId, 'trace');
    });

    test('Trace triggers the copied switch-in ability like PSDK', () {
      final result = _dispatchAbilitySwitchIn(
        playerAbilityId: 'trace',
        opponentAbilityId: 'intimidate',
      );

      expect(result.state.battlerAt(psdkPlayerSlot).abilityId, 'intimidate');
      expect(
        result.state.battlerAt(psdkOpponentSlot).statStages.valueOf('attack'),
        -1,
      );
      expect(
        result.events.whereType<PsdkBattleStatStageEvent>().single.stat,
        'attack',
      );
    });

    test('Imposter copies opposing active battler on switch-in', () {
      final result = _dispatchAbilitySwitchIn(
        playerAbilityId: 'imposter',
        opponentAbilityId: 'water_absorb',
        opponentSpeciesId: 'vaporeon',
        opponentDisplayName: 'Vaporeon',
        opponentTypes: const PsdkBattleTypes(primary: 'water'),
        opponentStats: const PsdkBattleStats(
          attack: 65,
          defense: 60,
          specialAttack: 110,
          specialDefense: 95,
          speed: 65,
        ),
        opponentStatStages: PsdkBattleStatStages(
          values: const <String, int>{'attack': 2, 'speed': -1},
        ),
        opponentCurrentWeightKg: 29,
        opponentMoves: <PsdkBattleMoveData>[
          _move(
            id: 'splash',
            power: 0,
            category: PsdkBattleMoveCategory.status,
            battleEngineMethod: 's_splash',
            target: PsdkBattleMoveTarget.none,
          ),
          _move(
            id: 'water_gun',
            type: 'water',
            category: PsdkBattleMoveCategory.special,
            power: 40,
          ),
        ],
      );

      final player = result.state.battlerAt(psdkPlayerSlot);
      expect(result.applied, isTrue);
      expect(player.speciesId, 'vaporeon');
      expect(player.displayName, 'Vaporeon');
      expect(player.abilityId, 'water_absorb');
      expect(player.types.primary, 'water');
      expect(player.stats.specialAttack, 110);
      expect(player.statStages.valueOf('attack'), 2);
      expect(player.statStages.valueOf('speed'), -1);
      expect(player.currentHp, 100);
      expect(player.currentWeightKg, 29);
      expect(player.transformState.isTransformed, isTrue);
      expect(player.transformState.transformedFromSpeciesId, 'player');
      expect(player.effects.contains('transform'), isTrue);
      expect(player.moves.map((move) => move.id), <String>[
        'splash',
        'water_gun',
      ]);
      expect(player.moves.every((move) => move.pp == 5), isTrue);
      expect(player.moves.every((move) => move.currentPp == 5), isTrue);
    });

    test('Imposter does not copy a target that is already transformed', () {
      final result = _dispatchAbilitySwitchIn(
        playerAbilityId: 'imposter',
        opponentAbilityId: 'water_absorb',
        opponentSpeciesId: 'vaporeon',
        opponentDisplayName: 'Vaporeon',
        opponentTransformState: const PsdkBattleTransformState(
          transformedFromSpeciesId: 'eevee',
        ),
      );

      final player = result.state.battlerAt(psdkPlayerSlot);
      expect(result.applied, isFalse);
      expect(result.reason, 'no_switch_events');
      expect(player.speciesId, 'player');
      expect(player.transformState.isTransformed, isFalse);
      expect(player.effects.contains('transform'), isFalse);
    });

    test('Speed Boost raises Speed at end turn', () {
      final result = _resolveAbilityEndTurn(playerAbilityId: 'speed_boost');

      expect(result.applied, isTrue);
      expect(
        result.state.battlerAt(psdkPlayerSlot).statStages.valueOf('speed'),
        1,
      );
      expect(
        result.events.whereType<PsdkBattleStatStageEvent>().single.stat,
        'speed',
      );
    });

    test('Moody raises one available stat and lowers another at end turn', () {
      final result = _resolveAbilityEndTurn(playerAbilityId: 'moody');

      expect(result.applied, isTrue);
      expect(
        result.state.battlerAt(psdkPlayerSlot).statStages.valueOf(
              'specialAttack',
            ),
        2,
      );
      expect(
        result.state.battlerAt(psdkPlayerSlot).statStages.valueOf(
              'specialDefense',
            ),
        -1,
      );
      expect(
        result.events.whereType<PsdkBattleStatStageEvent>().map(
              (event) => event.stat,
            ),
        <String>['specialAttack', 'specialDefense'],
      );
    });

    test('Healer can cure an adjacent ally status at end turn', () {
      final cured = _resolveHealerEndTurn(genericSeed: 0);
      final missed = _resolveHealerEndTurn(genericSeed: 99);

      expect(cured.applied, isTrue);
      expect(cured.state.battlerAt(_psdkPlayerAllySlot).majorStatus, isNull);
      expect(
        cured.events.whereType<PsdkBattleStatusCureEvent>().single.moveId,
        'ability:healer',
      );
      expect(
        missed.state.battlerAt(_psdkPlayerAllySlot).majorStatus,
        PsdkBattleMajorStatus.paralysis,
      );
    });

    test('Surge Surfer doubles Speed while Electric Terrain is active', () {
      final inactive = _fightActionForAbility(abilityId: 'surge_surfer');
      final active = _fightActionForAbility(
        abilityId: 'surge_surfer',
        field: const PsdkBattleFieldState(
          terrain: PsdkBattleTerrainState(
            id: PsdkBattleTerrainId.electricTerrain,
            remainingTurns: 5,
          ),
        ),
      );

      expect(inactive.speed, 50);
      expect(active.speed, 100);
    });

    test('stat modifier abilities affect damage formula like PSDK', () {
      final baseline = _runMove(
        playerMove: _move(id: 'tackle', power: 60),
      );
      final purePower = _runMove(
        playerAbilityId: 'pure_power',
        playerMove: _move(id: 'tackle', power: 60),
      );
      final hugePower = _runMove(
        playerAbilityId: 'huge_power',
        playerMove: _move(id: 'tackle', power: 60),
      );
      final gutsInactive = _runMove(
        playerAbilityId: 'guts',
        playerMove: _move(id: 'tackle', power: 60),
      );
      final gutsActive = _runMove(
        playerAbilityId: 'guts',
        playerMajorStatus: PsdkBattleMajorStatus.poison,
        playerMove: _move(id: 'tackle', power: 60),
      );
      final hustle = _runMove(
        playerAbilityId: 'hustle',
        playerMove: _move(id: 'hustle_tackle', power: 60),
      );

      expect(
        _damageEvents(purePower, moveId: 'tackle').single.damage,
        greaterThan(_damageEvents(baseline, moveId: 'tackle').single.damage),
      );
      expect(
        _damageEvents(hugePower, moveId: 'tackle').single.damage,
        _damageEvents(purePower, moveId: 'tackle').single.damage,
      );
      expect(
        _damageEvents(gutsInactive, moveId: 'tackle').single.damage,
        _damageEvents(baseline, moveId: 'tackle').single.damage,
      );
      expect(
        _damageEvents(gutsActive, moveId: 'tackle').single.damage,
        greaterThan(_damageEvents(baseline, moveId: 'tackle').single.damage),
      );
      expect(
        _damageEvents(hustle, moveId: 'hustle_tackle').single.damage,
        greaterThan(_damageEvents(baseline, moveId: 'tackle').single.damage),
      );
    });

    test('defensive stat modifier abilities reduce matching physical damage',
        () {
      final baseline = _runMove(
        playerMove: _move(id: 'tackle', power: 60),
      );
      final furCoat = _runMove(
        opponentAbilityId: 'fur_coat',
        playerMove: _move(id: 'tackle', power: 60),
      );
      final marvelScaleInactive = _runMove(
        opponentAbilityId: 'marvel_scale',
        playerMove: _move(id: 'tackle', power: 60),
      );
      final marvelScaleActive = _runMove(
        opponentAbilityId: 'marvel_scale',
        opponentMajorStatus: PsdkBattleMajorStatus.burn,
        playerMove: _move(id: 'tackle', power: 60),
      );
      final grassPeltInactive = _runMove(
        opponentAbilityId: 'grass_pelt',
        playerMove: _move(id: 'tackle', power: 60),
      );
      final grassPeltActive = _runMove(
        opponentAbilityId: 'grass_pelt',
        field: const PsdkBattleFieldState(
          terrain: PsdkBattleTerrainState(
            id: PsdkBattleTerrainId.grassyTerrain,
            remainingTurns: 5,
          ),
        ),
        playerMove: _move(id: 'tackle', power: 60),
      );

      final baselineDamage =
          _damageEvents(baseline, moveId: 'tackle').single.damage;
      expect(_damageEvents(furCoat, moveId: 'tackle').single.damage,
          lessThan(baselineDamage));
      expect(
        _damageEvents(marvelScaleInactive, moveId: 'tackle').single.damage,
        baselineDamage,
      );
      expect(
        _damageEvents(marvelScaleActive, moveId: 'tackle').single.damage,
        lessThan(baselineDamage),
      );
      expect(
        _damageEvents(grassPeltInactive, moveId: 'tackle').single.damage,
        baselineDamage,
      );
      expect(
        _damageEvents(grassPeltActive, moveId: 'tackle').single.damage,
        lessThan(baselineDamage),
      );
    });

    test('base-power damage modifier abilities follow PSDK gates', () {
      final baseline = _calculatedDamage();
      final defeatistHighHp = _calculatedDamage(
        abilityId: 'defeatist',
        playerCurrentHp: 50,
      );
      final defeatistLowHp = _calculatedDamage(
        abilityId: 'defeatist',
        playerCurrentHp: 49,
      );
      final fluffyContact = _calculatedDamage(
        opponentAbilityId: 'fluffy',
        flags: const BattleMoveFlags(contact: true),
      );
      final fluffyFire = _calculatedDamage(
        opponentAbilityId: 'fluffy',
        moveType: 'fire',
      );
      final heatproofFire = _calculatedDamage(
        opponentAbilityId: 'heatproof',
        moveType: 'fire',
      );
      final iceScalesSpecial = _calculatedDamage(
        opponentAbilityId: 'ice_scales',
        category: PsdkBattleMoveCategory.special,
      );
      final stakeoutInactiveTurn = _calculatedDamage(
        abilityId: 'stakeout',
        playerBattleTurnCount: 0,
        opponentSwitching: true,
      );
      final stakeoutInactiveSwitch = _calculatedDamage(
        abilityId: 'stakeout',
        playerBattleTurnCount: 1,
        opponentSwitching: false,
      );
      final stakeoutActive = _calculatedDamage(
        abilityId: 'stakeout',
        playerBattleTurnCount: 1,
        opponentSwitching: true,
      );
      final analyticInactive = _calculatedDamage(
        abilityId: 'analytic',
        isLastActionOfTurn: false,
      );
      final analyticActive = _calculatedDamage(
        abilityId: 'analytic',
        isLastActionOfTurn: true,
      );
      final darkBaseline = _calculatedDamage(moveType: 'dark');
      final darkAura = _calculatedDamage(
        abilityId: 'dark_aura',
        moveType: 'dark',
      );
      final fairyBaseline = _calculatedDamage(moveType: 'fairy');
      final fairyAura = _calculatedDamage(
        abilityId: 'fairy_aura',
        moveType: 'fairy',
      );
      final mismatchedAura = _calculatedDamage(
        abilityId: 'dark_aura',
        moveType: 'normal',
      );
      final auraBreakOnly = _calculatedDamage(
        abilityId: 'aura_break',
        moveType: 'dark',
      );
      final darkAuraBroken = _calculatedDamage(
        abilityId: 'dark_aura',
        opponentAbilityId: 'aura_break',
        moveType: 'dark',
      );

      expect(defeatistHighHp, baseline);
      expect(defeatistLowHp, lessThan(baseline));
      expect(fluffyContact, lessThan(baseline));
      expect(fluffyFire, greaterThan(baseline));
      expect(heatproofFire, lessThan(fluffyFire));
      expect(
          iceScalesSpecial,
          lessThan(_calculatedDamage(
            category: PsdkBattleMoveCategory.special,
          )));
      expect(stakeoutInactiveTurn, baseline);
      expect(stakeoutInactiveSwitch, baseline);
      expect(stakeoutActive, greaterThan(baseline));
      expect(analyticInactive, baseline);
      expect(analyticActive, greaterThan(baseline));
      expect(darkAura, greaterThan(darkBaseline));
      expect(fairyAura, greaterThan(fairyBaseline));
      expect(mismatchedAura, baseline);
      expect(auraBreakOnly, darkBaseline);
      expect(darkAuraBroken, lessThan(darkBaseline));
    });

    test('special/final damage modifier abilities follow PSDK gates', () {
      final specialBaseline = _runMove(
        playerMove: _move(
          id: 'swift',
          power: 60,
          category: PsdkBattleMoveCategory.special,
        ),
      );
      final flareInactive = _runMove(
        playerAbilityId: 'flare_boost',
        playerMove: _move(
          id: 'swift',
          power: 60,
          category: PsdkBattleMoveCategory.special,
        ),
      );
      final flareActive = _runMove(
        playerAbilityId: 'flare_boost',
        playerMajorStatus: PsdkBattleMajorStatus.burn,
        playerMove: _move(
          id: 'swift',
          power: 60,
          category: PsdkBattleMoveCategory.special,
        ),
      );
      final neuroforceNeutral = _runMove(
        playerAbilityId: 'neuroforce',
        playerMove: _move(id: 'tackle', power: 60),
      );
      final neuroforceStrong = _runMove(
        playerAbilityId: 'neuroforce',
        playerMove: _move(id: 'ember', type: 'fire', power: 60),
        opponentTypes: const PsdkBattleTypes(primary: 'grass'),
      );
      final strongBaseline = _runMove(
        playerMove: _move(id: 'ember', type: 'fire', power: 60),
        opponentTypes: const PsdkBattleTypes(primary: 'grass'),
      );

      final specialDamage =
          _damageEvents(specialBaseline, moveId: 'swift').single.damage;
      expect(
        _damageEvents(flareInactive, moveId: 'swift').single.damage,
        specialDamage,
      );
      expect(
        _damageEvents(flareActive, moveId: 'swift').single.damage,
        greaterThan(specialDamage),
      );
      expect(
        _damageEvents(neuroforceNeutral, moveId: 'tackle').single.damage,
        _damageEvents(_runMove(playerMove: _move(id: 'tackle', power: 60)),
                moveId: 'tackle')
            .single
            .damage,
      );
      expect(
        _damageEvents(neuroforceStrong, moveId: 'ember').single.damage,
        greaterThan(
            _damageEvents(strongBaseline, moveId: 'ember').single.damage),
      );
    });

    test('speed modifier abilities affect action speed in matching fields', () {
      const cases = <({
        String abilityId,
        PsdkBattleFieldState field,
        PsdkBattleMajorStatus? status,
        int expectedSpeed,
      })>[
        (
          abilityId: 'chlorophyll',
          field: PsdkBattleFieldState(
            weather: PsdkBattleWeatherState(
              id: PsdkBattleWeatherId.sunny,
              remainingTurns: 5,
            ),
          ),
          status: null,
          expectedSpeed: 100,
        ),
        (
          abilityId: 'swift_swim',
          field: PsdkBattleFieldState(
            weather: PsdkBattleWeatherState(
              id: PsdkBattleWeatherId.rain,
              remainingTurns: 5,
            ),
          ),
          status: null,
          expectedSpeed: 100,
        ),
        (
          abilityId: 'sand_rush',
          field: PsdkBattleFieldState(
            weather: PsdkBattleWeatherState(
              id: PsdkBattleWeatherId.sandstorm,
              remainingTurns: 5,
            ),
          ),
          status: null,
          expectedSpeed: 100,
        ),
        (
          abilityId: 'slush_rush',
          field: PsdkBattleFieldState(
            weather: PsdkBattleWeatherState(
              id: PsdkBattleWeatherId.snow,
              remainingTurns: 5,
            ),
          ),
          status: null,
          expectedSpeed: 100,
        ),
        (
          abilityId: 'quick_feet',
          field: PsdkBattleFieldState(),
          status: PsdkBattleMajorStatus.paralysis,
          expectedSpeed: 75,
        ),
      ];

      for (final entry in cases) {
        final action = _fightActionForAbility(
          abilityId: entry.abilityId,
          field: entry.field,
          majorStatus: entry.status,
        );

        expect(action.speed, entry.expectedSpeed, reason: entry.abilityId);
      }

      final inactive = _fightActionForAbility(abilityId: 'chlorophyll');
      expect(inactive.speed, 50);
    });

    test('Rain Dish heals one sixteenth in rain', () {
      final result = _resolveAbilityEndTurn(
        playerAbilityId: 'rain_dish',
        playerCurrentHp: 80,
        field: const PsdkBattleFieldState(
          weather: PsdkBattleWeatherState(
            id: PsdkBattleWeatherId.rain,
            remainingTurns: 5,
          ),
        ),
      );

      expect(result.applied, isTrue);
      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 86);
      expect(result.events.whereType<PsdkBattleHealEvent>().single.amount, 6);
    });

    test('Hydration cures its owner status at end turn in rain only', () {
      final rain = _resolveAbilityEndTurn(
        playerAbilityId: 'hydration',
        playerMajorStatus: PsdkBattleMajorStatus.burn,
        field: const PsdkBattleFieldState(
          weather: PsdkBattleWeatherState(
            id: PsdkBattleWeatherId.rain,
            remainingTurns: 5,
          ),
        ),
      );
      final clear = _resolveAbilityEndTurn(
        playerAbilityId: 'hydration',
        playerMajorStatus: PsdkBattleMajorStatus.burn,
      );

      expect(rain.state.battlerAt(psdkPlayerSlot).majorStatus, isNull);
      expect(
        rain.events.whereType<PsdkBattleStatusCureEvent>().single.moveId,
        'ability:hydration',
      );
      expect(
        clear.state.battlerAt(psdkPlayerSlot).majorStatus,
        PsdkBattleMajorStatus.burn,
      );
    });

    test('Ice Body heals one sixteenth in snow and hail', () {
      for (final weather in <PsdkBattleWeatherId>[
        PsdkBattleWeatherId.snow,
        PsdkBattleWeatherId.hail,
      ]) {
        final result = _resolveAbilityEndTurn(
          playerAbilityId: 'ice_body',
          playerCurrentHp: 80,
          field: PsdkBattleFieldState(
            weather: PsdkBattleWeatherState(
              id: weather,
              remainingTurns: 5,
            ),
          ),
        );

        expect(
          result.state.battlerAt(psdkPlayerSlot).currentHp,
          86,
          reason: weather.jsonName,
        );
        expect(
          result.events.whereType<PsdkBattleHealEvent>().single.amount,
          6,
          reason: weather.jsonName,
        );
      }
    });

    test('Dry Skin heals in rain and is hurt in sun at end turn', () {
      final rain = _resolveAbilityEndTurn(
        playerAbilityId: 'dry_skin',
        playerCurrentHp: 80,
        field: const PsdkBattleFieldState(
          weather: PsdkBattleWeatherState(
            id: PsdkBattleWeatherId.rain,
            remainingTurns: 5,
          ),
        ),
      );
      final sun = _resolveAbilityEndTurn(
        playerAbilityId: 'dry_skin',
        playerCurrentHp: 80,
        field: const PsdkBattleFieldState(
          weather: PsdkBattleWeatherState(
            id: PsdkBattleWeatherId.sunny,
            remainingTurns: 5,
          ),
        ),
      );

      expect(rain.state.battlerAt(psdkPlayerSlot).currentHp, 92);
      expect(rain.events.whereType<PsdkBattleHealEvent>().single.amount, 12);
      expect(sun.state.battlerAt(psdkPlayerSlot).currentHp, 68);
      expect(sun.events.whereType<PsdkBattleDamageEvent>().single.damage, 12);
    });

    test('Solar Power boosts special damage in sun and hurts at end turn', () {
      const sun = PsdkBattleFieldState(
        weather: PsdkBattleWeatherState(
          id: PsdkBattleWeatherId.sunny,
          remainingTurns: 5,
        ),
      );
      final baseline = _calculatedDamage(
        category: PsdkBattleMoveCategory.special,
        field: sun,
      );
      final boosted = _calculatedDamage(
        abilityId: 'solar_power',
        category: PsdkBattleMoveCategory.special,
        field: sun,
      );
      final endTurn = _resolveAbilityEndTurn(
        playerAbilityId: 'solar_power',
        playerCurrentHp: 80,
        field: sun,
      );

      expect(boosted, greaterThan(baseline));
      expect(endTurn.state.battlerAt(psdkPlayerSlot).currentHp, 68);
      expect(
        endTurn.events.whereType<PsdkBattleDamageEvent>().single.moveId,
        'ability:solar_power',
      );
    });

    test('Shed Skin can cure its own major status at end turn', () {
      final cured = _resolveAbilityEndTurn(
        playerAbilityId: 'shed_skin',
        playerMajorStatus: PsdkBattleMajorStatus.burn,
        rngSeeds: const BattleRngSeeds(
          moveDamage: 1,
          moveCritical: 99999,
          moveAccuracy: 3,
          generic: 0,
        ),
      );
      final missed = _resolveAbilityEndTurn(
        playerAbilityId: 'shed_skin',
        playerMajorStatus: PsdkBattleMajorStatus.burn,
        rngSeeds: const BattleRngSeeds(
          moveDamage: 1,
          moveCritical: 99999,
          moveAccuracy: 3,
          generic: 1,
        ),
      );

      expect(cured.state.battlerAt(psdkPlayerSlot).majorStatus, isNull);
      expect(
        cured.events.whereType<PsdkBattleStatusCureEvent>().single.moveId,
        'ability:shed_skin',
      );
      expect(
        missed.state.battlerAt(psdkPlayerSlot).majorStatus,
        PsdkBattleMajorStatus.burn,
      );
    });

    test('Bad Dreams damages sleeping foes at end turn', () {
      final result = _resolveAbilityEndTurn(
        playerAbilityId: 'bad_dreams',
        opponentMajorStatus: PsdkBattleMajorStatus.sleep,
      );

      expect(result.state.battlerAt(psdkOpponentSlot).currentHp, 88);
      expect(
        result.events.whereType<PsdkBattleDamageEvent>().single.moveId,
        'ability:bad_dreams',
      );
    });

    test('Dry Skin absorbs Water damage and heals a quarter HP', () {
      final result = _applyDirectAbilityDamage(
        opponentAbilityId: 'dry_skin',
        moveType: 'water',
        opponentCurrentHp: 80,
      );

      expect(result.reason, BattleMoveFailureReason.immunity.jsonName);
      expect(result.state.battlerAt(psdkOpponentSlot).currentHp, 100);
      expect(_damageEventsForHandler(result), isEmpty);
      expect(result.events.whereType<PsdkBattleHealEvent>().single.amount, 20);
    });

    test('Well-Baked Body absorbs Fire damage and sharply raises Defense', () {
      final result = _applyDirectAbilityDamage(
        opponentAbilityId: 'well_baked_body',
        moveType: 'fire',
      );
      final turn = _runMove(
        opponentAbilityId: 'well_baked_body',
        playerMove: _move(id: 'ember', type: 'fire', power: 60),
      );

      expect(result.reason, BattleMoveFailureReason.immunity.jsonName);
      expect(result.state.battlerAt(psdkOpponentSlot).currentHp, 100);
      expect(
        result.state.battlerAt(psdkOpponentSlot).statStages.valueOf('defense'),
        2,
      );
      expect(
        result.events.whereType<PsdkBattleStatStageEvent>().single.amount,
        2,
      );
      expect(_damageEventsForHandler(result), isEmpty);
      expect(_damageEvents(turn, moveId: 'ember'), isEmpty);
      expect(
        turn.state.battlerAt(psdkOpponentSlot).statStages.valueOf('defense'),
        2,
      );
    });

    test('Thermal Exchange raises Attack after Fire damage and prevents burn',
        () {
      final hit = _applyDirectAbilityDamage(
        opponentAbilityId: 'thermal_exchange',
        moveType: 'fire',
      );
      final burn = _applyStatusToPlayer(
        playerAbilityId: 'thermal_exchange',
        status: PsdkBattleMajorStatus.burn,
      );

      expect(hit.state.battlerAt(psdkOpponentSlot).currentHp, 70);
      expect(
        hit.state.battlerAt(psdkOpponentSlot).statStages.valueOf('attack'),
        1,
      );
      expect(
        hit.events.whereType<PsdkBattleStatStageEvent>().single.stat,
        'attack',
      );
      expect(burn.applied, isFalse);
      expect(burn.reason, 'ability:thermal_exchange');
      expect(burn.state.battlerAt(psdkPlayerSlot).majorStatus, isNull);
    });

    test('Sand Spit and Seed Sower set field effects after taking damage', () {
      final sand = _runMove(
        opponentAbilityId: 'sand_spit',
        playerMove: _move(id: 'tackle', power: 60),
      );
      final grass = _runMove(
        opponentAbilityId: 'seed_sower',
        playerMove: _move(id: 'tackle', power: 60),
      );

      expect(sand.state.field.weather?.id, PsdkBattleWeatherId.sandstorm);
      expect(sand.state.field.weather?.remainingTurns, 4);
      expect(grass.state.field.terrain?.id, PsdkBattleTerrainId.grassyTerrain);
      expect(grass.state.field.terrain?.remainingTurns, 4);
    });

    test('Innards Out damages the attacker by the fainted HP amount', () {
      final result = _runMove(
        opponentAbilityId: 'innards_out',
        opponentCurrentHp: 30,
        playerMove: _move(id: 'heavy_hit', power: 250),
      );

      final retaliation = _damageEvents(result, moveId: 'effect:innards_out');
      expect(retaliation.single.damage, 30);
      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 70);
    });

    test('Synchronize mirrors burn, paralysis, poison and toxic only', () {
      final burn = _applyStatusToOpponent(
        opponentAbilityId: 'synchronize',
        status: PsdkBattleMajorStatus.burn,
      );
      final sleep = _applyStatusToOpponent(
        opponentAbilityId: 'synchronize',
        status: PsdkBattleMajorStatus.sleep,
      );

      expect(burn.state.battlerAt(psdkPlayerSlot).majorStatus,
          PsdkBattleMajorStatus.burn);
      expect(
        burn.events.whereType<PsdkBattleStatusEvent>().map(
              (event) => event.moveId,
            ),
        <String>['test:status', 'ability:synchronize'],
      );
      expect(sleep.state.battlerAt(psdkPlayerSlot).majorStatus, isNull);
    });

    test('Hospitality heals an ally on switch-in', () {
      final result = _dispatchHospitalitySwitchIn();

      expect(result.applied, isTrue);
      expect(result.state.battlerAt(_psdkPlayerAllySlot).currentHp, 75);
      expect(
        result.events.whereType<PsdkBattleHealEvent>().single.moveId,
        'ability:hospitality',
      );
    });

    test('Cotton Down partially lowers every other battler Speed', () {
      final result = _runMove(
        opponentAbilityId: 'cotton_down',
        playerMove: _move(id: 'tackle', power: 60),
      );

      expect(result.state.battlerAt(psdkPlayerSlot).statStages.valueOf('speed'),
          -1);
      expect(
        result.timeline.events
            .whereType<PsdkBattleStatStageEvent>()
            .single
            .stat,
        'speed',
      );
    });

    test('Telepathy prevents damaging moves from same-bank allies', () {
      const userSlot = PsdkBattleSlotRef(bank: 0, position: 0);
      const allySlot = PsdkBattleSlotRef(bank: 0, position: 1);
      const foeSlot = PsdkBattleSlotRef(bank: 1, position: 0);
      final state = PsdkBattleState(
        combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
          userSlot: PsdkBattleCombatant.fromSetup(
            _combatant(id: 'user', move: _move(id: 'surf', power: 60)),
          ),
          allySlot: PsdkBattleCombatant.fromSetup(
            _combatant(
              id: 'ally',
              abilityId: 'telepathy',
              move: _move(id: 'ally_wait', power: 0),
            ),
          ),
          foeSlot: PsdkBattleCombatant.fromSetup(
            _combatant(id: 'foe', move: _move(id: 'foe_wait', power: 0)),
          ),
        },
      );

      final result = const BattleDamageHandler().applyDamage(
        context: BattleHandlerContext(
          state: state,
          rng: _rng(),
          turn: 1,
          user: userSlot,
        ),
        target: allySlot,
        moveId: 'surf',
        rawDamage: 30,
        move: _definition(
          id: 'surf',
          power: 60,
          category: PsdkBattleMoveCategory.special,
        ),
      );

      expect(result.reason, BattleMoveFailureReason.immunity.jsonName);
      expect(result.state.battlerAt(allySlot).currentHp, 100);
      expect(_damageEventsForHandler(result), isEmpty);
    });

    test('Dry Skin increases incoming Fire base power', () {
      final normal = _calculatedDamage(
        moveType: 'fire',
        opponentAbilityId: null,
      );
      final drySkin = _calculatedDamage(
        moveType: 'fire',
        opponentAbilityId: 'dry_skin',
      );

      expect(drySkin, greaterThan(normal));
    });

    test('No Guard on either battler bypasses the accuracy roll', () {
      final result = _runMove(
        playerAbilityId: 'no_guard',
        playerMove: _move(
          id: 'zap_cannon',
          type: 'electric',
          category: PsdkBattleMoveCategory.special,
          power: 40,
          accuracy: 1,
        ),
        rngSeeds: const BattleRngSeeds(
          moveDamage: 1,
          moveCritical: 99999,
          moveAccuracy: 99,
          generic: 4,
        ),
      );

      expect(_damageEvents(result, moveId: 'zap_cannon'), hasLength(1));
      expect(
        _eventsFor(result, moveId: 'zap_cannon').map((event) => event.kind),
        isNot(contains('miss')),
      );
    });

    test('No Guard on the target also bypasses the accuracy roll', () {
      final result = _runMove(
        opponentAbilityId: 'no_guard',
        playerMove: _move(
          id: 'dynamic_punch',
          power: 40,
          accuracy: 1,
        ),
        rngSeeds: const BattleRngSeeds(
          moveDamage: 1,
          moveCritical: 99999,
          moveAccuracy: 99,
          generic: 4,
        ),
      );

      expect(_damageEvents(result, moveId: 'dynamic_punch'), hasLength(1));
      expect(
        _eventsFor(result, moveId: 'dynamic_punch').map((event) => event.kind),
        isNot(contains('miss')),
      );
    });

    test('accuracy modifier abilities follow PSDK chance gates', () {
      const highAccuracyRoll = BattleRngSeeds(
        moveDamage: 1,
        moveCritical: 99999,
        moveAccuracy: 90,
        generic: 4,
      );
      final baseline = _runMove(
        playerMove: _move(
          id: 'baseline_hit',
          power: 40,
          accuracy: 80,
        ),
        rngSeeds: highAccuracyRoll,
      );
      final compoundEyes = _runMove(
        playerAbilityId: 'compound_eyes',
        playerMove: _move(
          id: 'compound_hit',
          power: 40,
          accuracy: 80,
        ),
        rngSeeds: highAccuracyRoll,
      );
      final victoryStar = _runMove(
        playerAbilityId: 'victory_star',
        playerMove: _move(
          id: 'victory_hit',
          power: 40,
          accuracy: 83,
        ),
        rngSeeds: highAccuracyRoll,
      );
      final sandVeil = _runMove(
        opponentAbilityId: 'sand_veil',
        playerMove: _move(
          id: 'sand_miss',
          power: 40,
          accuracy: 100,
        ),
        field: const PsdkBattleFieldState(
          weather: PsdkBattleWeatherState(
            id: PsdkBattleWeatherId.sandstorm,
            remainingTurns: 5,
          ),
        ),
        rngSeeds: highAccuracyRoll,
      );
      final snowCloak = _runMove(
        opponentAbilityId: 'snow_cloak',
        playerMove: _move(
          id: 'snow_miss',
          power: 40,
          accuracy: 100,
        ),
        field: const PsdkBattleFieldState(
          weather: PsdkBattleWeatherState(
            id: PsdkBattleWeatherId.snow,
            remainingTurns: 5,
          ),
        ),
        rngSeeds: highAccuracyRoll,
      );
      final wonderSkin = _runMove(
        opponentAbilityId: 'wonder_skin',
        playerMove: _move(
          id: 'status_probe',
          power: 0,
          category: PsdkBattleMoveCategory.status,
          accuracy: 100,
        ),
        rngSeeds: highAccuracyRoll,
      );
      final hustleMiss = _runMove(
        playerAbilityId: 'hustle',
        playerMove: _move(
          id: 'hustle_miss',
          power: 40,
          accuracy: 100,
        ),
        rngSeeds: highAccuracyRoll,
      );

      expect(_damageEvents(baseline, moveId: 'baseline_hit'), isEmpty);
      expect(_damageEvents(compoundEyes, moveId: 'compound_hit'), hasLength(1));
      expect(_damageEvents(victoryStar, moveId: 'victory_hit'), hasLength(1));
      expect(_damageEvents(sandVeil, moveId: 'sand_miss'), isEmpty);
      expect(_damageEvents(snowCloak, moveId: 'snow_miss'), isEmpty);
      expect(
        _eventsFor(wonderSkin, moveId: 'status_probe')
            .map((event) => event.kind),
        contains('miss'),
      );
      expect(_damageEvents(hustleMiss, moveId: 'hustle_miss'), isEmpty);
    });

    test('Skill Link forces random two-to-five multi-hit moves to five hits',
        () {
      final result = _runMove(
        playerAbilityId: 'skill_link',
        playerMove: _move(
          id: 'double_slap',
          power: 25,
          battleEngineMethod: 's_multi_hit',
        ),
        opponentCurrentHp: 200,
        rngSeeds: const BattleRngSeeds(
          moveDamage: 1,
          moveCritical: 99999,
          moveAccuracy: 3,
          generic: 0,
        ),
      );

      expect(_damageEvents(result, moveId: 'double_slap'), hasLength(5));
    });

    test('Skill Link forces Scale Shot to five hits', () {
      final result = _runMove(
        playerAbilityId: 'skill_link',
        playerMove: _move(
          id: 'scale_shot',
          power: 25,
          battleEngineMethod: 's_scale_shot',
        ),
        opponentCurrentHp: 200,
        rngSeeds: const BattleRngSeeds(
          moveDamage: 1,
          moveCritical: 99999,
          moveAccuracy: 3,
          generic: 0,
        ),
      );

      expect(_damageEvents(result, moveId: 'scale_shot'), hasLength(5));
    });

    test('Skill Link keeps Triple Kick at three hits and skips rechecks', () {
      final result = _runMove(
        playerAbilityId: 'skill_link',
        playerMove: _move(
          id: 'triple_kick',
          power: 10,
          accuracy: 90,
          battleEngineMethod: 's_triple_kick',
        ),
        rngSeeds: const BattleRngSeeds(
          moveDamage: 1,
          moveCritical: 99999,
          moveAccuracy: 3,
          generic: 4,
        ),
      );

      expect(_damageEvents(result, moveId: 'triple_kick'), hasLength(3));
      expect(
        _eventsFor(result, moveId: 'triple_kick').map((event) => event.kind),
        isNot(contains('miss')),
      );
    });

    test('Skill Link lets Population Bomb continue through rechecks', () {
      final result = _runMove(
        playerAbilityId: 'skill_link',
        opponentCurrentHp: 200,
        playerMove: _move(
          id: 'population_bomb',
          power: 20,
          accuracy: 90,
          battleEngineMethod: 's_population_bomb',
        ),
        rngSeeds: const BattleRngSeeds(
          moveDamage: 1,
          moveCritical: 99999,
          moveAccuracy: 3,
          generic: 4,
        ),
      );

      expect(_damageEvents(result, moveId: 'population_bomb'), hasLength(10));
      expect(
        _eventsFor(result, moveId: 'population_bomb')
            .map((event) => event.kind),
        isNot(contains('miss')),
      );
    });

    test('Rock Head prevents regular recoil damage', () {
      final result = _runMove(
        playerAbilityId: 'rock_head',
        playerMove: _move(
          id: 'take_down',
          power: 40,
          battleEngineMethod: 's_recoil',
        ),
      );

      final damage = _damageEvents(result, moveId: 'take_down');
      expect(damage, hasLength(1));
      expect(damage.single.target, psdkOpponentSlot);
      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 100);
    });

    test('Reckless boosts recoil move target damage', () {
      final normal = _runMove(
        playerMove: _move(
          id: 'take_down',
          power: 40,
          battleEngineMethod: 's_recoil',
        ),
      );
      final reckless = _runMove(
        playerAbilityId: 'reckless',
        playerMove: _move(
          id: 'take_down',
          power: 40,
          battleEngineMethod: 's_recoil',
        ),
      );

      expect(
        _damageEvents(reckless, moveId: 'take_down').first.damage,
        greaterThan(_damageEvents(normal, moveId: 'take_down').first.damage),
      );
    });

    test('type boosting abilities follow PSDK type and HP gates', () {
      const cases = <({
        String abilityId,
        String moveType,
        bool lowHpGate,
      })>[
        (abilityId: 'blaze', moveType: 'fire', lowHpGate: true),
        (abilityId: 'overgrow', moveType: 'grass', lowHpGate: true),
        (abilityId: 'torrent', moveType: 'water', lowHpGate: true),
        (abilityId: 'swarm', moveType: 'bug', lowHpGate: true),
        (abilityId: 'dragon_s_maw', moveType: 'dragon', lowHpGate: false),
        (abilityId: 'steelworker', moveType: 'steel', lowHpGate: false),
        (abilityId: 'transistor', moveType: 'electric', lowHpGate: false),
        (abilityId: 'rocky_payload', moveType: 'rock', lowHpGate: false),
      ];

      for (final entry in cases) {
        final matching = _runMove(
          playerAbilityId: entry.abilityId,
          playerCurrentHp: entry.lowHpGate ? 33 : 100,
          playerMove: _move(
            id: '${entry.abilityId}_matching',
            type: entry.moveType,
            power: 60,
          ),
        );
        final matchingNormal = _runMove(
          playerCurrentHp: entry.lowHpGate ? 33 : 100,
          playerMove: _move(
            id: '${entry.abilityId}_matching',
            type: entry.moveType,
            power: 60,
          ),
        );
        final mismatching = _runMove(
          playerAbilityId: entry.abilityId,
          playerCurrentHp: entry.lowHpGate ? 33 : 100,
          playerMove: _move(
            id: '${entry.abilityId}_mismatch',
            type: 'normal',
            power: 60,
          ),
        );
        final mismatchingNormal = _runMove(
          playerCurrentHp: entry.lowHpGate ? 33 : 100,
          playerMove: _move(
            id: '${entry.abilityId}_mismatch',
            type: 'normal',
            power: 60,
          ),
        );

        expect(
          _damageEvents(matching, moveId: '${entry.abilityId}_matching')
              .single
              .damage,
          greaterThan(
            _damageEvents(matchingNormal, moveId: '${entry.abilityId}_matching')
                .single
                .damage,
          ),
          reason: entry.abilityId,
        );
        expect(
          _damageEvents(mismatching, moveId: '${entry.abilityId}_mismatch')
              .single
              .damage,
          _damageEvents(mismatchingNormal,
                  moveId: '${entry.abilityId}_mismatch')
              .single
              .damage,
          reason: entry.abilityId,
        );
      }
    });

    test('starter type boosts stay inactive above the PSDK low HP gate', () {
      final normal = _runMove(
        playerMove: _move(id: 'ember', type: 'fire', power: 60),
      );
      final blaze = _runMove(
        playerAbilityId: 'blaze',
        playerCurrentHp: 34,
        playerMove: _move(id: 'ember', type: 'fire', power: 60),
      );

      expect(
        _damageEvents(blaze, moveId: 'ember').single.damage,
        _damageEvents(normal, moveId: 'ember').single.damage,
      );
    });

    test('changing move type abilities convert Normal moves and boost them',
        () {
      const cases = <({
        String abilityId,
        String convertedType,
        PsdkBattleTypes targetTypes,
      })>[
        (
          abilityId: 'aerilate',
          convertedType: 'flying',
          targetTypes: PsdkBattleTypes(primary: 'grass'),
        ),
        (
          abilityId: 'galvanize',
          convertedType: 'electric',
          targetTypes: PsdkBattleTypes(primary: 'water'),
        ),
        (
          abilityId: 'pixilate',
          convertedType: 'fairy',
          targetTypes: PsdkBattleTypes(primary: 'dragon'),
        ),
        (
          abilityId: 'refrigerate',
          convertedType: 'ice',
          targetTypes: PsdkBattleTypes(primary: 'dragon'),
        ),
      ];

      for (final entry in cases) {
        final converted = _calculatedDamage(
          abilityId: entry.abilityId,
          moveType: 'normal',
          opponentTypes: entry.targetTypes,
        );
        final alreadyTyped = _calculatedDamage(
          abilityId: entry.abilityId,
          moveType: entry.convertedType,
          opponentTypes: entry.targetTypes,
        );
        final baseline = _calculatedDamage(
          moveType: 'normal',
          opponentTypes: entry.targetTypes,
        );

        expect(converted, greaterThan(baseline), reason: entry.abilityId);
        expect(alreadyTyped, lessThan(converted), reason: entry.abilityId);
      }
    });

    test('changing move type abilities preserve Weather Ball type', () {
      final weatherBall = _calculatedDamage(
        abilityId: 'pixilate',
        moveType: 'normal',
        opponentTypes: const PsdkBattleTypes(primary: 'ghost'),
        battleEngineMethod: 's_weather_ball',
      );

      expect(weatherBall, 0);
    });

    test('Normalize turns all non-Weather Ball attacks into Normal type', () {
      final normalized = _calculatedDamage(
        abilityId: 'normalize',
        moveType: 'fire',
        opponentTypes: const PsdkBattleTypes(primary: 'grass'),
      );
      final baseline = _calculatedDamage(
        moveType: 'fire',
        opponentTypes: const PsdkBattleTypes(primary: 'grass'),
      );
      final weatherBall = _calculatedDamage(
        abilityId: 'normalize',
        moveType: 'fire',
        opponentTypes: const PsdkBattleTypes(primary: 'grass'),
        battleEngineMethod: 's_weather_ball',
      );

      expect(normalized, lessThan(baseline));
      expect(weatherBall, baseline);
    });

    test('Liquid Voice turns sound attacks into Water type only', () {
      final sound = _calculatedDamage(
        abilityId: 'liquid_voice',
        flags: const BattleMoveFlags(sound: true),
        category: PsdkBattleMoveCategory.special,
        opponentTypes: const PsdkBattleTypes(primary: 'fire'),
      );
      final baselineSound = _calculatedDamage(
        flags: const BattleMoveFlags(sound: true),
        category: PsdkBattleMoveCategory.special,
        opponentTypes: const PsdkBattleTypes(primary: 'fire'),
      );
      final nonSound = _calculatedDamage(
        abilityId: 'liquid_voice',
        category: PsdkBattleMoveCategory.special,
        opponentTypes: const PsdkBattleTypes(primary: 'fire'),
      );
      final baselineNonSound = _calculatedDamage(
        category: PsdkBattleMoveCategory.special,
        opponentTypes: const PsdkBattleTypes(primary: 'fire'),
      );

      expect(sound, greaterThan(baselineSound));
      expect(nonSound, baselineNonSound);
    });

    test('Technician boosts only moves with base power at most sixty', () {
      final boosted = _runMove(
        playerAbilityId: 'technician',
        playerMove: _move(id: 'mach_punch', power: 60),
      );
      final boostedNormal = _runMove(
        playerMove: _move(id: 'mach_punch', power: 60),
      );
      final tooStrong = _runMove(
        playerAbilityId: 'technician',
        playerMove: _move(id: 'slash', power: 70),
      );
      final tooStrongNormal = _runMove(
        playerMove: _move(id: 'slash', power: 70),
      );

      expect(
        _damageEvents(boosted, moveId: 'mach_punch').single.damage,
        greaterThan(
            _damageEvents(boostedNormal, moveId: 'mach_punch').single.damage),
      );
      expect(
        _damageEvents(tooStrong, moveId: 'slash').single.damage,
        _damageEvents(tooStrongNormal, moveId: 'slash').single.damage,
      );
    });

    test('flag-based damage abilities boost matching PSDK move shapes', () {
      const cases = <({
        String abilityId,
        BattleMoveFlags matchingFlags,
        PsdkBattleMoveCategory category,
      })>[
        (
          abilityId: 'iron_fist',
          matchingFlags: BattleMoveFlags(punch: true),
          category: PsdkBattleMoveCategory.physical,
        ),
        (
          abilityId: 'tough_claws',
          matchingFlags: BattleMoveFlags(contact: true),
          category: PsdkBattleMoveCategory.physical,
        ),
        (
          abilityId: 'sharpness',
          matchingFlags: BattleMoveFlags(slicing: true),
          category: PsdkBattleMoveCategory.physical,
        ),
        (
          abilityId: 'punk_rock',
          matchingFlags: BattleMoveFlags(sound: true),
          category: PsdkBattleMoveCategory.special,
        ),
        (
          abilityId: 'strong_jaw',
          matchingFlags: BattleMoveFlags(bite: true),
          category: PsdkBattleMoveCategory.physical,
        ),
        (
          abilityId: 'mega_launcher',
          matchingFlags: BattleMoveFlags(pulse: true),
          category: PsdkBattleMoveCategory.special,
        ),
      ];

      for (final entry in cases) {
        final boosted = _calculatedDamage(
          abilityId: entry.abilityId,
          flags: entry.matchingFlags,
          category: entry.category,
        );
        final normal = _calculatedDamage(
          flags: entry.matchingFlags,
          category: entry.category,
        );
        final nonMatching = _calculatedDamage(
          abilityId: entry.abilityId,
          category: entry.category,
        );
        final nonMatchingNormal = _calculatedDamage(category: entry.category);

        expect(boosted, greaterThan(normal), reason: entry.abilityId);
        expect(nonMatching, nonMatchingNormal, reason: entry.abilityId);
      }
    });

    test('ally damage abilities affect same-bank doubles partners', () {
      final normalSpecial = _calculatedDoublesDamage(
        category: PsdkBattleMoveCategory.special,
      );
      final normalPhysical = _calculatedDoublesDamage();
      final normalSteel = _calculatedDoublesDamage(moveType: 'steel');

      expect(
        _calculatedDoublesDamage(
          userAllyAbilityId: 'battery',
          category: PsdkBattleMoveCategory.special,
        ),
        greaterThan(normalSpecial),
      );
      expect(
        _calculatedDoublesDamage(userAllyAbilityId: 'battery'),
        normalPhysical,
      );
      expect(
        _calculatedDoublesDamage(userAllyAbilityId: 'power_spot'),
        greaterThan(normalPhysical),
      );
      expect(
        _calculatedDoublesDamage(
          userAllyAbilityId: 'steely_spirit',
          moveType: 'steel',
        ),
        greaterThan(normalSteel),
      );
      expect(
        _calculatedDoublesDamage(userAllyAbilityId: 'steely_spirit'),
        normalPhysical,
      );
      expect(
        _calculatedDoublesDamage(targetAllyAbilityId: 'friend_guard'),
        lessThan(normalPhysical),
      );
    });

    test('super-effective reduction abilities reduce only strong hits', () {
      for (final abilityId in <String>[
        'solid_rock',
        'filter',
        'prism_armor',
      ]) {
        final reduced = _calculatedDamage(
          opponentAbilityId: abilityId,
          moveType: 'fire',
          opponentTypes: const PsdkBattleTypes(primary: 'grass'),
        );
        final baseline = _calculatedDamage(
          moveType: 'fire',
          opponentTypes: const PsdkBattleTypes(primary: 'grass'),
        );
        final neutral = _calculatedDamage(
          opponentAbilityId: abilityId,
          moveType: 'normal',
        );
        final neutralBaseline = _calculatedDamage(moveType: 'normal');

        expect(reduced, lessThan(baseline), reason: abilityId);
        expect(neutral, neutralBaseline, reason: abilityId);
      }
    });

    test('Tinted Lens boosts only not very effective hits', () {
      final resisted = _calculatedDamage(
        abilityId: 'tinted_lens',
        moveType: 'fire',
        opponentTypes: const PsdkBattleTypes(primary: 'water'),
      );
      final resistedBaseline = _calculatedDamage(
        moveType: 'fire',
        opponentTypes: const PsdkBattleTypes(primary: 'water'),
      );
      final neutral = _calculatedDamage(
        abilityId: 'tinted_lens',
        moveType: 'normal',
      );
      final neutralBaseline = _calculatedDamage(moveType: 'normal');

      expect(resisted, greaterThan(resistedBaseline));
      expect(neutral, neutralBaseline);
    });

    test('Multiscale and Shadow Shield reduce full HP incoming damage', () {
      for (final abilityId in <String>['multiscale', 'shadow_shield']) {
        final fullHp = _calculatedDamage(opponentAbilityId: abilityId);
        final baseline = _calculatedDamage();
        final damaged = _calculatedDamage(
          opponentAbilityId: abilityId,
          opponentCurrentHp: 99,
        );

        expect(fullHp, lessThan(baseline), reason: abilityId);
        expect(damaged, baseline, reason: abilityId);
      }
    });

    test('PSDK weather and status damage ability modifiers match their gates',
        () {
      final fireBaseline = _calculatedDamage(moveType: 'fire');
      final iceBaseline = _calculatedDamage(moveType: 'ice');
      final normalBaseline = _calculatedDamage(moveType: 'normal');

      expect(
        _calculatedDamage(
          opponentAbilityId: 'thick_fat',
          moveType: 'fire',
        ),
        lessThan(fireBaseline),
      );
      expect(
        _calculatedDamage(
          opponentAbilityId: 'thick_fat',
          moveType: 'ice',
        ),
        lessThan(iceBaseline),
      );
      expect(
        _calculatedDamage(
          opponentAbilityId: 'thick_fat',
          moveType: 'normal',
        ),
        normalBaseline,
      );

      final poisonedToxicBoost = _calculatedDamage(
        abilityId: 'toxic_boost',
        playerMajorStatus: PsdkBattleMajorStatus.toxic,
      );
      final inactiveToxicBoost = _calculatedDamage(abilityId: 'toxic_boost');
      final poisonBaseline = _calculatedDamage(
        playerMajorStatus: PsdkBattleMajorStatus.toxic,
      );
      expect(poisonedToxicBoost, greaterThan(poisonBaseline));
      expect(inactiveToxicBoost, normalBaseline);

      const sandstorm = PsdkBattleFieldState(
        weather: PsdkBattleWeatherState(
          id: PsdkBattleWeatherId.sandstorm,
          remainingTurns: 5,
        ),
      );
      final sandForce = _calculatedDamage(
        abilityId: 'sand_force',
        moveType: 'rock',
        field: sandstorm,
      );
      final sandBaseline = _calculatedDamage(
        moveType: 'rock',
        field: sandstorm,
      );
      final noWeather = _calculatedDamage(
        abilityId: 'sand_force',
        moveType: 'rock',
      );
      final wrongType = _calculatedDamage(
        abilityId: 'sand_force',
        moveType: 'water',
        field: sandstorm,
      );

      expect(sandForce, greaterThan(sandBaseline));
      expect(noWeather, _calculatedDamage(moveType: 'rock'));
      expect(wrongType, _calculatedDamage(moveType: 'water', field: sandstorm));
    });

    test('Rough Skin and Iron Barbs punish opposing contact damage', () {
      for (final abilityId in <String>['rough_skin', 'iron_barbs']) {
        final state = PsdkBattleState.fromSetup(
          BattleEngineSetup.singles(
            player: _combatant(
              id: 'player',
              move: _move(id: 'scratch', power: 40),
            ),
            opponent: _combatant(
              id: 'opponent',
              abilityId: abilityId,
              move: _move(id: 'opponent_wait', power: 0),
            ),
            rngSeeds: const BattleRngSeeds(
              moveDamage: 1,
              moveCritical: 99999,
              moveAccuracy: 3,
              generic: 4,
            ).psdkSeeds,
          ).psdkSetup,
        );

        final result = const BattleDamageHandler().applyDamage(
          context: BattleHandlerContext(
            state: state,
            rng: BattleRngStreams.fromSeeds(
              moveDamageSeed: 1,
              moveCriticalSeed: 2,
              moveAccuracySeed: 3,
              genericSeed: 4,
            ),
            turn: 1,
            user: psdkPlayerSlot,
          ),
          target: psdkOpponentSlot,
          moveId: 'scratch',
          rawDamage: 20,
          move: BattleMoveDefinition(
            id: 'scratch',
            dbSymbol: 'scratch',
            name: 'scratch',
            type: 'normal',
            category: PsdkBattleMoveCategory.physical,
            power: 40,
            accuracy: 100,
            pp: 35,
            priority: 0,
            battleEngineMethod: 's_basic',
            target: PsdkBattleMoveTarget.adjacentFoe,
            flags: const BattleMoveFlags(contact: true),
          ),
        );
        final damages =
            result.events.whereType<PsdkBattleDamageEvent>().toList();

        expect(result.state.battlerAt(psdkOpponentSlot).currentHp, 80);
        expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 88);
        expect(damages.map((event) => event.moveId), <String>[
          'scratch',
          'effect:$abilityId',
        ]);
      }
    });

    test('type immunity abilities prevent matching damaging moves', () {
      const cases = <({String abilityId, String moveType})>[
        (abilityId: 'water_absorb', moveType: 'water'),
        (abilityId: 'volt_absorb', moveType: 'electric'),
        (abilityId: 'earth_eater', moveType: 'ground'),
        (abilityId: 'flash_fire', moveType: 'fire'),
        (abilityId: 'motor_drive', moveType: 'electric'),
        (abilityId: 'lightning_rod', moveType: 'electric'),
        (abilityId: 'storm_drain', moveType: 'water'),
        (abilityId: 'sap_sipper', moveType: 'grass'),
      ];

      for (final entry in cases) {
        final blocked = _runMove(
          opponentAbilityId: entry.abilityId,
          playerMove: _move(
            id: '${entry.abilityId}_blocked',
            type: entry.moveType,
            power: 60,
          ),
        );
        final neutral = _runMove(
          opponentAbilityId: entry.abilityId,
          playerMove: _move(
            id: '${entry.abilityId}_neutral',
            type: 'normal',
            power: 60,
          ),
        );

        expect(
          _damageEvents(blocked, moveId: '${entry.abilityId}_blocked'),
          isEmpty,
          reason: entry.abilityId,
        );
        expect(
          _eventsFor(blocked, moveId: '${entry.abilityId}_blocked')
              .whereType<PsdkBattleMoveFailedEvent>()
              .single
              .reason,
          BattleMoveFailureReason.immunity.jsonName,
          reason: entry.abilityId,
        );
        expect(
          _damageEvents(neutral, moveId: '${entry.abilityId}_neutral'),
          hasLength(1),
          reason: entry.abilityId,
        );
      }
    });

    test('priority blocker abilities stop opposing protectable priority moves',
        () {
      for (final abilityId in <String>['queenly_majesty', 'dazzling']) {
        final blocked = _runMove(
          opponentAbilityId: abilityId,
          playerMove: _move(
            id: '${abilityId}_quick_attack',
            power: 40,
            priority: 1,
          ),
        );
        final neutralPriority = _runMove(
          opponentAbilityId: abilityId,
          playerMove: _move(
            id: '${abilityId}_tackle',
            power: 40,
          ),
        );
        final unprotectablePriority = _runMove(
          opponentAbilityId: abilityId,
          playerMove: _move(
            id: '${abilityId}_unprotectable',
            power: 40,
            priority: 1,
            protectable: false,
          ),
        );

        expect(
          _damageEvents(blocked, moveId: '${abilityId}_quick_attack'),
          isEmpty,
          reason: abilityId,
        );
        expect(
          _eventsFor(blocked, moveId: '${abilityId}_quick_attack')
              .whereType<PsdkBattleMoveFailedEvent>()
              .single
              .reason,
          BattleMoveFailureReason.immunity.jsonName,
          reason: abilityId,
        );
        expect(
          _damageEvents(neutralPriority, moveId: '${abilityId}_tackle'),
          hasLength(1),
          reason: abilityId,
        );
        expect(
          _damageEvents(
            unprotectablePriority,
            moveId: '${abilityId}_unprotectable',
          ),
          hasLength(1),
          reason: abilityId,
        );
      }
    });

    test('Armor Tail blocks opposing single-target priority moves', () {
      final blocked = _runMove(
        opponentAbilityId: 'armor_tail',
        playerMove: _move(
          id: 'armor_tail_unprotectable',
          power: 40,
          priority: 1,
          protectable: false,
        ),
      );
      final spreadPriority = _runMove(
        opponentAbilityId: 'armor_tail',
        playerMove: _move(
          id: 'armor_tail_spread',
          power: 40,
          priority: 1,
          target: PsdkBattleMoveTarget.allAdjacentFoes,
        ),
      );
      final moldBreaker = _runMove(
        playerAbilityId: 'mold_breaker',
        opponentAbilityId: 'armor_tail',
        playerMove: _move(
          id: 'armor_tail_mold_breaker',
          power: 40,
          priority: 1,
          protectable: false,
        ),
      );

      expect(
          _damageEvents(blocked, moveId: 'armor_tail_unprotectable'), isEmpty);
      expect(
        _eventsFor(blocked, moveId: 'armor_tail_unprotectable')
            .whereType<PsdkBattleMoveFailedEvent>()
            .single
            .reason,
        BattleMoveFailureReason.immunity.jsonName,
      );
      expect(_damageEvents(spreadPriority, moveId: 'armor_tail_spread'),
          hasLength(1));
      expect(_damageEvents(moldBreaker, moveId: 'armor_tail_mold_breaker'),
          hasLength(1));
    });

    test('Bulletproof blocks ballistic moves', () {
      final blocked = _runMove(
        opponentAbilityId: 'bulletproof',
        playerMove: _move(
          id: 'aura_sphere',
          category: PsdkBattleMoveCategory.special,
          power: 80,
          ballistics: true,
        ),
      );
      final neutral = _runMove(
        opponentAbilityId: 'bulletproof',
        playerMove: _move(
          id: 'swift',
          category: PsdkBattleMoveCategory.special,
          power: 60,
        ),
      );
      final moldBreaker = _runMove(
        playerAbilityId: 'mold_breaker',
        opponentAbilityId: 'bulletproof',
        playerMove: _move(
          id: 'bulletproof_mold_breaker',
          category: PsdkBattleMoveCategory.special,
          power: 80,
          ballistics: true,
        ),
      );

      expect(_damageEvents(blocked, moveId: 'aura_sphere'), isEmpty);
      expect(
        _eventsFor(blocked, moveId: 'aura_sphere')
            .whereType<PsdkBattleMoveFailedEvent>()
            .single
            .reason,
        BattleMoveFailureReason.immunity.jsonName,
      );
      expect(_damageEvents(neutral, moveId: 'swift'), hasLength(1));
      expect(_damageEvents(moldBreaker, moveId: 'bulletproof_mold_breaker'),
          hasLength(1));
    });

    test('Good as Gold blocks opposing single-target status moves', () {
      final blocked = _runMove(
        opponentAbilityId: 'good_as_gold',
        playerMove: _move(
          id: 'taunt',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          battleEngineMethod: 's_taunt',
        ),
      );
      final damaging = _runMove(
        opponentAbilityId: 'good_as_gold',
        playerMove: _move(id: 'tackle', power: 40),
      );
      final spreadStatus = _runMove(
        opponentAbilityId: 'good_as_gold',
        playerMove: _move(
          id: 'spread_taunt',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          battleEngineMethod: 's_taunt',
          target: PsdkBattleMoveTarget.allAdjacentFoes,
        ),
      );
      final moldBreaker = _runMove(
        playerAbilityId: 'mold_breaker',
        opponentAbilityId: 'good_as_gold',
        playerMove: _move(
          id: 'mold_breaker_taunt',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          battleEngineMethod: 's_taunt',
        ),
      );

      expect(
        _eventsFor(blocked, moveId: 'taunt')
            .whereType<PsdkBattleMoveFailedEvent>()
            .single
            .reason,
        BattleMoveFailureReason.immunity.jsonName,
      );
      expect(_damageEvents(damaging, moveId: 'tackle'), hasLength(1));
      expect(
        spreadStatus.state.battlerAt(psdkOpponentSlot).effects.contains(
              'taunt',
            ),
        isTrue,
      );
      expect(
        moldBreaker.state.battlerAt(psdkOpponentSlot).effects.contains(
              'taunt',
            ),
        isTrue,
      );
    });

    test('type absorb damage prevention heals instead of taking damage', () {
      final result = _applyDirectAbilityDamage(
        opponentAbilityId: 'water_absorb',
        opponentCurrentHp: 50,
        moveType: 'water',
      );
      final heals = result.events.whereType<PsdkBattleHealEvent>().toList();

      expect(result.applied, isTrue);
      expect(result.reason, BattleMoveFailureReason.immunity.jsonName);
      expect(result.state.battlerAt(psdkOpponentSlot).currentHp, 75);
      expect(heals, hasLength(1));
      expect(heals.single.amount, 25);
      expect(heals.single.moveId, 'effect:water_absorb');
    });

    test('stat absorb damage prevention raises the matching stat', () {
      const cases = <({String abilityId, String moveType, String stat})>[
        (abilityId: 'motor_drive', moveType: 'electric', stat: 'speed'),
        (
          abilityId: 'lightning_rod',
          moveType: 'electric',
          stat: 'special_attack'
        ),
        (abilityId: 'storm_drain', moveType: 'water', stat: 'special_attack'),
        (abilityId: 'sap_sipper', moveType: 'grass', stat: 'attack'),
      ];

      for (final entry in cases) {
        final result = _applyDirectAbilityDamage(
          opponentAbilityId: entry.abilityId,
          moveType: entry.moveType,
        );

        expect(result.reason, BattleMoveFailureReason.immunity.jsonName);
        expect(result.state.battlerAt(psdkOpponentSlot).currentHp, 100);
        expect(
          result.state
              .battlerAt(psdkOpponentSlot)
              .statStages
              .valueOf(entry.stat),
          1,
          reason: entry.abilityId,
        );
        expect(
          result.events.whereType<PsdkBattleStatStageEvent>().single.stat,
          entry.stat,
          reason: entry.abilityId,
        );
      }
    });

    test('post-damage stat abilities follow their PSDK gates', () {
      final stamina = _applyDirectAbilityDamage(opponentAbilityId: 'stamina');
      final weakArmor = _applyDirectAbilityDamage(
        opponentAbilityId: 'weak_armor',
        category: PsdkBattleMoveCategory.physical,
      );
      final weakArmorSpecial = _applyDirectAbilityDamage(
        opponentAbilityId: 'weak_armor',
      );
      final waterCompaction = _applyDirectAbilityDamage(
        opponentAbilityId: 'water_compaction',
        moveType: 'water',
      );
      final steamEngineFire = _applyDirectAbilityDamage(
        opponentAbilityId: 'steam_engine',
        moveType: 'fire',
      );
      final justified = _applyDirectAbilityDamage(
        opponentAbilityId: 'justified',
        moveType: 'dark',
      );
      final rattledDark = _applyDirectAbilityDamage(
        opponentAbilityId: 'rattled',
        moveType: 'dark',
      );
      final rattledBug = _applyDirectAbilityDamage(
        opponentAbilityId: 'rattled',
        moveType: 'bug',
      );
      final rattledNormal = _applyDirectAbilityDamage(
        opponentAbilityId: 'rattled',
      );
      final gooey = _applyDirectAbilityDamage(
        opponentAbilityId: 'gooey',
        category: PsdkBattleMoveCategory.physical,
        flags: const BattleMoveFlags(contact: true),
      );
      final tanglingHair = _applyDirectAbilityDamage(
        opponentAbilityId: 'tangling_hair',
        category: PsdkBattleMoveCategory.physical,
        flags: const BattleMoveFlags(contact: true),
      );
      final nonContactGooey = _applyDirectAbilityDamage(
        opponentAbilityId: 'gooey',
        category: PsdkBattleMoveCategory.physical,
      );
      final lethalStamina = _applyDirectAbilityDamage(
        opponentAbilityId: 'stamina',
        opponentCurrentHp: 10,
        rawDamage: 30,
      );

      expect(_statEventsForHandler(stamina).single.stat, 'defense');
      expect(_statEventsForHandler(stamina).single.amount, 1);
      expect(_statEventsForHandler(stamina).single.target, psdkOpponentSlot);
      expect(
        stamina.state.battlerAt(psdkOpponentSlot).statStages.valueOf('defense'),
        1,
      );

      expect(
        _statEventsForHandler(weakArmor).map((event) => event.stat),
        <String>['defense', 'speed'],
      );
      expect(
        _statEventsForHandler(weakArmor).map((event) => event.amount),
        <int>[-1, 1],
      );
      expect(_statEventsForHandler(weakArmorSpecial), isEmpty);

      expect(_statEventsForHandler(waterCompaction).single.stat, 'defense');
      expect(_statEventsForHandler(waterCompaction).single.amount, 2);

      expect(_statEventsForHandler(steamEngineFire).single.stat, 'speed');
      expect(_statEventsForHandler(steamEngineFire).single.amount, 3);

      expect(_statEventsForHandler(justified).single.stat, 'attack');
      expect(_statEventsForHandler(justified).single.amount, 1);
      expect(_statEventsForHandler(rattledDark).single.stat, 'speed');
      expect(_statEventsForHandler(rattledDark).single.amount, 1);
      expect(_statEventsForHandler(rattledBug).single.stat, 'speed');
      expect(_statEventsForHandler(rattledNormal), isEmpty);

      expect(_statEventsForHandler(gooey).single.target, psdkPlayerSlot);
      expect(_statEventsForHandler(gooey).single.stat, 'speed');
      expect(_statEventsForHandler(gooey).single.amount, -1);
      expect(_statEventsForHandler(tanglingHair).single.target, psdkPlayerSlot);
      expect(_statEventsForHandler(nonContactGooey), isEmpty);
      expect(_statEventsForHandler(lethalStamina), isEmpty);
    });

    test('KO stat boost abilities trigger after the owner knocks out a target',
        () {
      const cases = <({String abilityId, String stat})>[
        (abilityId: 'moxie', stat: 'attack'),
        (abilityId: 'chilling_neigh', stat: 'attack'),
        (abilityId: 'grim_neigh', stat: 'specialAttack'),
        (abilityId: 'beast_boost', stat: 'speed'),
      ];

      for (final entry in cases) {
        final result = _applyDirectAbilityDamage(
          playerAbilityId: entry.abilityId,
          opponentCurrentHp: 10,
          rawDamage: 30,
        );
        final event = _statEventsForHandler(result).single;

        expect(event.target, psdkPlayerSlot, reason: entry.abilityId);
        expect(event.stat, entry.stat, reason: entry.abilityId);
        expect(event.amount, 1, reason: entry.abilityId);
      }

      final nonLethal = _applyDirectAbilityDamage(
        playerAbilityId: 'moxie',
        opponentCurrentHp: 100,
        rawDamage: 30,
      );

      expect(_statEventsForHandler(nonLethal), isEmpty);
    });

    test('Aftermath damages contact attackers after a KO unless Damp is alive',
        () {
      const contactFlags = BattleMoveFlags(contact: true);
      final aftermath = _applyDirectAbilityDamage(
        opponentAbilityId: 'aftermath',
        opponentCurrentHp: 10,
        rawDamage: 30,
        flags: contactFlags,
      );
      final nonContact = _applyDirectAbilityDamage(
        opponentAbilityId: 'aftermath',
        opponentCurrentHp: 10,
        rawDamage: 30,
      );
      final dampBlocked = _applyDirectAbilityDamage(
        playerAbilityId: 'damp',
        opponentAbilityId: 'aftermath',
        opponentCurrentHp: 10,
        rawDamage: 30,
        flags: contactFlags,
      );

      final aftermathDamage = _damageEventsForHandler(aftermath)
          .where((event) => event.moveId == 'effect:aftermath')
          .single;
      expect(aftermathDamage.target, psdkPlayerSlot);
      expect(aftermathDamage.damage, 25);
      expect(aftermath.state.battlerAt(psdkPlayerSlot).currentHp, 75);

      expect(
        _damageEventsForHandler(nonContact)
            .where((event) => event.moveId == 'effect:aftermath'),
        isEmpty,
      );
      expect(
        _damageEventsForHandler(dampBlocked)
            .where((event) => event.moveId == 'effect:aftermath'),
        isEmpty,
      );
    });

    test('half HP threshold stat abilities apply their core PSDK boosts', () {
      final berserk = _applyDirectAbilityDamage(
        opponentAbilityId: 'berserk',
        opponentCurrentHp: 60,
        rawDamage: 20,
      );
      final angerShell = _applyDirectAbilityDamage(
        opponentAbilityId: 'anger_shell',
        opponentCurrentHp: 60,
        rawDamage: 20,
      );
      final alreadyBelowHalf = _applyDirectAbilityDamage(
        opponentAbilityId: 'berserk',
        opponentCurrentHp: 45,
        rawDamage: 10,
      );

      expect(
        _statEventsForHandler(berserk).map((event) => event.stat),
        <String>['specialAttack'],
      );
      expect(
        _statEventsForHandler(berserk).map((event) => event.amount),
        <int>[1],
      );
      expect(
        _statEventsForHandler(angerShell).map((event) => event.stat),
        <String>[
          'attack',
          'specialAttack',
          'speed',
          'defense',
          'specialDefense',
        ],
      );
      expect(
        _statEventsForHandler(angerShell).map((event) => event.amount),
        <int>[1, 1, 1, -1, -1],
      );
      expect(_statEventsForHandler(alreadyBelowHalf), isEmpty);
    });

    test('contact status abilities follow their PSDK contact rolls', () {
      const hitSeeds = BattleRngSeeds(
        moveDamage: 1,
        moveCritical: 99999,
        moveAccuracy: 3,
        generic: 0,
      );
      const missSeeds = BattleRngSeeds(
        moveDamage: 1,
        moveCritical: 99999,
        moveAccuracy: 3,
        generic: 9,
      );
      const contactFlags = BattleMoveFlags(contact: true);

      for (final entry in <({String abilityId, PsdkBattleMajorStatus status})>[
        (abilityId: 'flame_body', status: PsdkBattleMajorStatus.burn),
        (abilityId: 'static', status: PsdkBattleMajorStatus.paralysis),
        (abilityId: 'poison_point', status: PsdkBattleMajorStatus.poison),
      ]) {
        final result = _applyDirectAbilityDamage(
          opponentAbilityId: entry.abilityId,
          category: PsdkBattleMoveCategory.physical,
          flags: contactFlags,
          rngSeeds: hitSeeds,
        );
        final statusEvents = result.events.whereType<PsdkBattleStatusEvent>();

        expect(
          result.state.battlerAt(psdkPlayerSlot).majorStatus,
          entry.status,
          reason: entry.abilityId,
        );
        expect(statusEvents.single.target, psdkPlayerSlot);
        expect(statusEvents.single.status, entry.status);
        expect(statusEvents.single.moveId, 'effect:${entry.abilityId}');
      }

      final missed = _applyDirectAbilityDamage(
        opponentAbilityId: 'flame_body',
        category: PsdkBattleMoveCategory.physical,
        flags: contactFlags,
        rngSeeds: missSeeds,
      );
      final nonContact = _applyDirectAbilityDamage(
        opponentAbilityId: 'static',
        category: PsdkBattleMoveCategory.physical,
        rngSeeds: hitSeeds,
      );
      final effectSporePoison = _applyDirectAbilityDamage(
        opponentAbilityId: 'effect_spore',
        category: PsdkBattleMoveCategory.physical,
        flags: contactFlags,
        rngSeeds: hitSeeds,
      );
      final effectSporeSleep = _applyDirectAbilityDamage(
        opponentAbilityId: 'effect_spore',
        category: PsdkBattleMoveCategory.physical,
        flags: contactFlags,
        rngSeeds: const BattleRngSeeds(
          moveDamage: 1,
          moveCritical: 99999,
          moveAccuracy: 3,
          generic: 1,
        ),
      );
      final effectSporeParalysis = _applyDirectAbilityDamage(
        opponentAbilityId: 'effect_spore',
        category: PsdkBattleMoveCategory.physical,
        flags: contactFlags,
        rngSeeds: const BattleRngSeeds(
          moveDamage: 1,
          moveCritical: 99999,
          moveAccuracy: 3,
          generic: 2,
        ),
      );
      final overcoatBlocked = _applyDirectAbilityDamage(
        opponentAbilityId: 'effect_spore',
        playerAbilityId: 'overcoat',
        category: PsdkBattleMoveCategory.physical,
        flags: contactFlags,
        rngSeeds: hitSeeds,
      );
      final grassBlocked = _applyDirectAbilityDamage(
        opponentAbilityId: 'effect_spore',
        playerTypes: const PsdkBattleTypes(primary: 'grass'),
        category: PsdkBattleMoveCategory.physical,
        flags: contactFlags,
        rngSeeds: hitSeeds,
      );
      final gogglesBlocked = _applyDirectAbilityDamage(
        opponentAbilityId: 'effect_spore',
        playerHeldItemId: 'safety_goggles',
        category: PsdkBattleMoveCategory.physical,
        flags: contactFlags,
        rngSeeds: hitSeeds,
      );

      expect(missed.state.battlerAt(psdkPlayerSlot).majorStatus, isNull);
      expect(nonContact.state.battlerAt(psdkPlayerSlot).majorStatus, isNull);
      expect(
        effectSporePoison.state.battlerAt(psdkPlayerSlot).majorStatus,
        PsdkBattleMajorStatus.poison,
      );
      expect(
        effectSporeSleep.state.battlerAt(psdkPlayerSlot).majorStatus,
        PsdkBattleMajorStatus.sleep,
      );
      expect(
        effectSporeParalysis.state.battlerAt(psdkPlayerSlot).majorStatus,
        PsdkBattleMajorStatus.paralysis,
      );
      expect(
          overcoatBlocked.state.battlerAt(psdkPlayerSlot).majorStatus, isNull);
      expect(grassBlocked.state.battlerAt(psdkPlayerSlot).majorStatus, isNull);
      expect(
          gogglesBlocked.state.battlerAt(psdkPlayerSlot).majorStatus, isNull);
    });

    test('offensive status abilities apply status to damaged move targets', () {
      const hitSeeds = BattleRngSeeds(
        moveDamage: 1,
        moveCritical: 99999,
        moveAccuracy: 3,
        generic: 0,
      );
      const missSeeds = BattleRngSeeds(
        moveDamage: 1,
        moveCritical: 99999,
        moveAccuracy: 3,
        generic: 9,
      );
      const contactFlags = BattleMoveFlags(contact: true);

      final poisonTouch = _applyDirectAbilityDamage(
        opponentAbilityId: 'none',
        playerAbilityId: 'poison_touch',
        category: PsdkBattleMoveCategory.physical,
        flags: contactFlags,
        rngSeeds: hitSeeds,
      );
      final poisonTouchNonContact = _applyDirectAbilityDamage(
        opponentAbilityId: 'none',
        playerAbilityId: 'poison_touch',
        category: PsdkBattleMoveCategory.physical,
        rngSeeds: hitSeeds,
      );
      final poisonTouchMiss = _applyDirectAbilityDamage(
        opponentAbilityId: 'none',
        playerAbilityId: 'poison_touch',
        category: PsdkBattleMoveCategory.physical,
        flags: contactFlags,
        rngSeeds: missSeeds,
      );
      final poisonTouchImmune = _applyDirectAbilityDamage(
        opponentAbilityId: 'none',
        playerAbilityId: 'poison_touch',
        opponentTypes: const PsdkBattleTypes(primary: 'poison'),
        category: PsdkBattleMoveCategory.physical,
        flags: contactFlags,
        rngSeeds: hitSeeds,
      );
      final toxicChain = _applyDirectAbilityDamage(
        opponentAbilityId: 'none',
        playerAbilityId: 'toxic_chain',
        category: PsdkBattleMoveCategory.special,
        rngSeeds: hitSeeds,
      );
      final toxicChainMiss = _applyDirectAbilityDamage(
        opponentAbilityId: 'none',
        playerAbilityId: 'toxic_chain',
        category: PsdkBattleMoveCategory.special,
        rngSeeds: missSeeds,
      );

      expect(
        poisonTouch.state.battlerAt(psdkOpponentSlot).majorStatus,
        PsdkBattleMajorStatus.poison,
      );
      expect(
        poisonTouch.events.whereType<PsdkBattleStatusEvent>().single.target,
        psdkOpponentSlot,
      );
      expect(
        poisonTouch.events.whereType<PsdkBattleStatusEvent>().single.moveId,
        'effect:poison_touch',
      );

      expect(
          poisonTouchNonContact.state.battlerAt(psdkOpponentSlot).majorStatus,
          isNull);
      expect(poisonTouchMiss.state.battlerAt(psdkOpponentSlot).majorStatus,
          isNull);
      expect(poisonTouchImmune.state.battlerAt(psdkOpponentSlot).majorStatus,
          isNull);

      expect(
        toxicChain.state.battlerAt(psdkOpponentSlot).majorStatus,
        PsdkBattleMajorStatus.toxic,
      );
      expect(
        toxicChain.events.whereType<PsdkBattleStatusEvent>().single.moveId,
        'effect:toxic_chain',
      );
      expect(
          toxicChainMiss.state.battlerAt(psdkOpponentSlot).majorStatus, isNull);
    });

    test('Cursed Body disables contact moves on its PSDK roll', () {
      const contactFlags = BattleMoveFlags(contact: true);
      const hitSeeds = BattleRngSeeds(
        moveDamage: 1,
        moveCritical: 99999,
        moveAccuracy: 3,
        generic: 0,
      );
      const missSeeds = BattleRngSeeds(
        moveDamage: 1,
        moveCritical: 99999,
        moveAccuracy: 3,
        generic: 9,
      );

      final disabled = _applyDirectAbilityDamage(
        opponentAbilityId: 'cursed_body',
        category: PsdkBattleMoveCategory.physical,
        flags: contactFlags,
        rngSeeds: hitSeeds,
      );
      final missed = _applyDirectAbilityDamage(
        opponentAbilityId: 'cursed_body',
        category: PsdkBattleMoveCategory.physical,
        flags: contactFlags,
        rngSeeds: missSeeds,
      );
      final nonContact = _applyDirectAbilityDamage(
        opponentAbilityId: 'cursed_body',
        category: PsdkBattleMoveCategory.physical,
        rngSeeds: hitSeeds,
      );

      expect(
        disabled.state.battlerAt(psdkPlayerSlot).effects.contains('disable'),
        isTrue,
      );
      expect(
        disabled.events.whereType<PsdkBattleEffectEvent>().single.effectId,
        'disable',
      );
      expect(
        disabled.events.whereType<PsdkBattleEffectEvent>().single.reason,
        'ability:cursed_body',
      );
      expect(
        missed.state.battlerAt(psdkPlayerSlot).effects.contains('disable'),
        isFalse,
      );
      expect(
        nonContact.state.battlerAt(psdkPlayerSlot).effects.contains('disable'),
        isFalse,
      );
    });

    test('Flash Fire prevents burn status in addition to Fire damage', () {
      final result = const BattleStatusChangeHandler().applyMajorStatus(
        context: BattleHandlerContext(
          state: PsdkBattleState.fromSetup(
            BattleEngineSetup.singles(
              player: _combatant(
                id: 'player',
                abilityId: 'flash_fire',
                move: _move(id: 'tackle', power: 40),
              ),
              opponent: _combatant(
                id: 'opponent',
                move: _move(id: 'will_o_wisp', power: 0),
              ),
              rngSeeds: const BattleRngSeeds(
                moveDamage: 1,
                moveCritical: 99999,
                moveAccuracy: 3,
                generic: 4,
              ).psdkSeeds,
            ).psdkSetup,
          ),
          rng: _rng(),
          turn: 1,
          user: psdkOpponentSlot,
        ),
        target: psdkPlayerSlot,
        moveId: 'will_o_wisp',
        status: PsdkBattleMajorStatus.burn,
      );

      expect(result.applied, isFalse);
      expect(result.reason, 'status_immune');
      expect(result.state.battlerAt(psdkPlayerSlot).majorStatus, isNull);
    });

    test('Levitate makes a non-grounded target immune to Ground moves', () {
      final result = _runMove(
        opponentAbilityId: 'levitate',
        playerMove: _move(
          id: 'earthquake',
          type: 'ground',
          power: 80,
        ),
      );

      expect(_damageEvents(result, moveId: 'earthquake'), isEmpty);
      expect(
        _eventsFor(result, moveId: 'earthquake').map((event) => event.kind),
        contains('move_immune'),
      );
      expect(result.state.battlerAt(psdkOpponentSlot).currentHp, 100);
    });

    test('Overcoat blocks powder moves through the ability immunity hook', () {
      final effect = _abilityEffectForOpponent('overcoat');

      final blocked = effect.onMovePreventionTarget(
        BattleEffectMoveContext(
          user: const BattlePositionRef(bank: 0, position: 0),
          target: const BattlePositionRef(bank: 1, position: 0),
          move: _definition(
            id: 'sleep_powder',
            category: PsdkBattleMoveCategory.status,
            power: 0,
            flags: const BattleMoveFlags(powder: true),
          ),
        ),
      );
      final neutral = effect.onMovePreventionTarget(
        BattleEffectMoveContext(
          user: const BattlePositionRef(bank: 0, position: 0),
          target: const BattlePositionRef(bank: 1, position: 0),
          move: _definition(
            id: 'growl',
            category: PsdkBattleMoveCategory.status,
            power: 0,
          ),
        ),
      );

      expect(blocked, BattleMoveFailureReason.immunity);
      expect(neutral, isNull);
    });

    test('Wonder Guard blocks only non-super-effective damaging moves', () {
      final blocked = _applyDirectAbilityDamage(
        opponentAbilityId: 'wonder_guard',
        moveType: 'normal',
      );
      final allowed = _applyDirectAbilityDamage(
        opponentAbilityId: 'wonder_guard',
        moveType: 'fire',
        opponentTypes: const PsdkBattleTypes(primary: 'grass'),
      );

      expect(blocked.applied, isTrue);
      expect(blocked.reason, BattleMoveFailureReason.immunity.jsonName);
      expect(_damageEventsForHandler(blocked), isEmpty);
      expect(allowed.applied, isTrue);
      expect(_damageEventsForHandler(allowed), hasLength(1));
    });

    test('Sturdy blocks OHKO moves and leaves full HP targets at one HP', () {
      final effect = _abilityEffectForOpponent('sturdy');

      final ohko = effect.onMovePreventionTarget(
        BattleEffectMoveContext(
          user: const BattlePositionRef(bank: 0, position: 0),
          target: const BattlePositionRef(bank: 1, position: 0),
          move: _definition(
            id: 'fissure',
            power: 1,
            battleEngineMethod: 's_ohko',
          ),
        ),
      );
      final regular = effect.onMovePreventionTarget(
        BattleEffectMoveContext(
          user: const BattlePositionRef(bank: 0, position: 0),
          target: const BattlePositionRef(bank: 1, position: 0),
          move: _definition(id: 'tackle', power: 40),
        ),
      );
      final lethal = _applyDirectAbilityDamage(
        opponentAbilityId: 'sturdy',
        rawDamage: 120,
      );
      final damaged = _applyDirectAbilityDamage(
        opponentAbilityId: 'sturdy',
        opponentCurrentHp: 99,
        rawDamage: 120,
      );

      expect(ohko, BattleMoveFailureReason.immunity);
      expect(regular, isNull);
      expect(lethal.state.battlerAt(psdkOpponentSlot).currentHp, 1);
      expect(_damageEventsForHandler(lethal).single.damage, 99);
      expect(damaged.state.battlerAt(psdkOpponentSlot).currentHp, 0);
    });

    test('stat drop prevention abilities block matching opposing drops', () {
      const cases = <({String abilityId, String blockedStat})>[
        (abilityId: 'big_pecks', blockedStat: 'defense'),
        (abilityId: 'hyper_cutter', blockedStat: 'attack'),
        (abilityId: 'keen_eye', blockedStat: 'accuracy'),
        (abilityId: 'mind_s_eye', blockedStat: 'accuracy'),
        (abilityId: 'clear_body', blockedStat: 'defense'),
        (abilityId: 'full_metal_body', blockedStat: 'specialDefense'),
        (abilityId: 'white_smoke', blockedStat: 'speed'),
      ];

      for (final entry in cases) {
        final result = _applyPlayerStatDrop(
          playerAbilityId: entry.abilityId,
          stat: entry.blockedStat,
        );

        expect(result.applied, isFalse, reason: entry.abilityId);
        expect(result.reason, 'ability:${entry.abilityId}');
        expect(
          result.state.battlerAt(psdkPlayerSlot).statStages.valueOf(
                entry.blockedStat,
              ),
          0,
          reason: entry.abilityId,
        );
      }

      final flowerVeilGrass = _applyPlayerStatDrop(
        playerAbilityId: 'flower_veil',
        playerTypes: const PsdkBattleTypes(primary: 'grass'),
        stat: 'defense',
      );
      final flowerVeilNonGrass = _applyPlayerStatDrop(
        playerAbilityId: 'flower_veil',
        stat: 'defense',
      );

      expect(flowerVeilGrass.applied, isFalse);
      expect(flowerVeilGrass.reason, 'ability:flower_veil');
      expect(flowerVeilNonGrass.applied, isTrue);
    });

    test('stat drop prevention abilities allow unmatched and self drops', () {
      final unmatched = _applyPlayerStatDrop(
        playerAbilityId: 'big_pecks',
        stat: 'attack',
      );
      final selfDrop = _applyPlayerStatDrop(
        playerAbilityId: 'clear_body',
        stat: 'defense',
        user: psdkPlayerSlot,
      );

      expect(unmatched.applied, isTrue);
      expect(
        unmatched.state.battlerAt(psdkPlayerSlot).statStages.valueOf('attack'),
        -1,
      );
      expect(selfDrop.applied, isTrue);
      expect(
        selfDrop.state.battlerAt(psdkPlayerSlot).statStages.valueOf('defense'),
        -1,
      );
    });

    test('Air Lock prevents new weather from being applied', () {
      final result = _runMove(
        opponentAbilityId: 'air_lock',
        playerMove: _move(
          id: 'rain_dance',
          dbSymbol: 'rain_dance',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 0,
          battleEngineMethod: 's_weather',
          target: PsdkBattleMoveTarget.none,
        ),
      );

      expect(result.state.field.weather, isNull);
      expect(
        result.timeline.events.whereType<PsdkBattleWeatherChangedEvent>(),
        isEmpty,
      );
    });

    test('Air Lock and Cloud Nine clear active weather on switch-in', () {
      for (final abilityId in <String>['air_lock', 'cloud_nine']) {
        final result = _dispatchAbilitySwitchIn(
          playerAbilityId: abilityId,
          field: const PsdkBattleFieldState(
            weather: PsdkBattleWeatherState(
              id: PsdkBattleWeatherId.rain,
              remainingTurns: 5,
            ),
          ),
        );

        expect(result.applied, isTrue, reason: abilityId);
        expect(result.state.field.weather, isNull, reason: abilityId);
        expect(
          result.events
              .whereType<PsdkBattleWeatherChangedEvent>()
              .single
              .reason,
          'ability:$abilityId',
          reason: abilityId,
        );
      }
    });

    test('non-volatile status immunity abilities prevent matching status', () {
      const cases = <({String abilityId, PsdkBattleMajorStatus status})>[
        (abilityId: 'immunity', status: PsdkBattleMajorStatus.poison),
        (abilityId: 'immunity', status: PsdkBattleMajorStatus.toxic),
        (abilityId: 'insomnia', status: PsdkBattleMajorStatus.sleep),
        (abilityId: 'vital_spirit', status: PsdkBattleMajorStatus.sleep),
        (abilityId: 'limber', status: PsdkBattleMajorStatus.paralysis),
        (abilityId: 'magma_armor', status: PsdkBattleMajorStatus.freeze),
        (abilityId: 'water_veil', status: PsdkBattleMajorStatus.burn),
        (abilityId: 'comatose', status: PsdkBattleMajorStatus.poison),
        (abilityId: 'comatose', status: PsdkBattleMajorStatus.toxic),
        (abilityId: 'comatose', status: PsdkBattleMajorStatus.burn),
        (abilityId: 'comatose', status: PsdkBattleMajorStatus.paralysis),
        (abilityId: 'comatose', status: PsdkBattleMajorStatus.freeze),
        (abilityId: 'comatose', status: PsdkBattleMajorStatus.sleep),
      ];

      for (final entry in cases) {
        final result = const BattleStatusChangeHandler().applyMajorStatus(
          context: BattleHandlerContext(
            state: PsdkBattleState.fromSetup(
              BattleEngineSetup.singles(
                player: _combatant(
                  id: 'player',
                  abilityId: entry.abilityId,
                  move: _move(id: 'tackle', power: 40),
                ),
                opponent: _combatant(
                  id: 'opponent',
                  move: _move(id: 'tackle', power: 40),
                ),
                rngSeeds: const BattleRngSeeds(
                  moveDamage: 1,
                  moveCritical: 99999,
                  moveAccuracy: 3,
                  generic: 4,
                ).psdkSeeds,
              ).psdkSetup,
            ),
            rng: BattleRngStreams.fromSeedSnapshot(
              const BattleRngSeeds(
                moveDamage: 1,
                moveCritical: 99999,
                moveAccuracy: 3,
                generic: 4,
              ),
            ),
            turn: 1,
            user: psdkOpponentSlot,
          ),
          target: psdkPlayerSlot,
          moveId: 'status_probe',
          status: entry.status,
        );

        expect(result.applied, isFalse, reason: entry.abilityId);
        expect(result.reason, 'status_immune', reason: entry.abilityId);
        expect(
          result.state.battlerAt(psdkPlayerSlot).majorStatus,
          isNull,
          reason: entry.abilityId,
        );
      }
    });

    test(
        'non-volatile status immunity abilities cure matching status on switch-in',
        () {
      final result = _dispatchAbilitySwitchIn(
        playerAbilityId: 'water_veil',
        playerMajorStatus: PsdkBattleMajorStatus.burn,
      );

      expect(result.applied, isTrue);
      expect(result.state.battlerAt(psdkPlayerSlot).majorStatus, isNull);
      expect(
          result.events.whereType<PsdkBattleStatusCureEvent>(), hasLength(1));
      expect(
        result.events.whereType<PsdkBattleStatusCureEvent>().single.moveId,
        'effect:water_veil',
      );
    });

    test('advanced status prevention abilities follow PSDK gates', () {
      final sunLeafGuard = _applyStatusToPlayer(
        playerAbilityId: 'leaf_guard',
        status: PsdkBattleMajorStatus.burn,
        field: const PsdkBattleFieldState(
          weather: PsdkBattleWeatherState(
            id: PsdkBattleWeatherId.sunny,
            remainingTurns: 5,
          ),
        ),
      );
      final inactiveLeafGuard = _applyStatusToPlayer(
        playerAbilityId: 'leaf_guard',
        status: PsdkBattleMajorStatus.burn,
      );
      final sweetVeil = _applyStatusToPlayer(
        playerAbilityId: 'sweet_veil',
        status: PsdkBattleMajorStatus.sleep,
      );
      final pastelVeil = _applyStatusToPlayer(
        playerAbilityId: 'pastel_veil',
        status: PsdkBattleMajorStatus.toxic,
      );
      final flowerVeilGrass = _applyStatusToPlayer(
        playerAbilityId: 'flower_veil',
        playerTypes: const PsdkBattleTypes(primary: 'grass'),
        status: PsdkBattleMajorStatus.paralysis,
      );
      final flowerVeilNonGrass = _applyStatusToPlayer(
        playerAbilityId: 'flower_veil',
        status: PsdkBattleMajorStatus.paralysis,
      );

      expect(sunLeafGuard.applied, isFalse);
      expect(sunLeafGuard.reason, 'ability:leaf_guard');
      expect(inactiveLeafGuard.applied, isTrue);
      expect(sweetVeil.applied, isFalse);
      expect(sweetVeil.reason, 'ability:sweet_veil');
      expect(pastelVeil.applied, isFalse);
      expect(pastelVeil.reason, 'ability:pastel_veil');
      expect(flowerVeilGrass.applied, isFalse);
      expect(flowerVeilGrass.reason, 'ability:flower_veil');
      expect(flowerVeilNonGrass.applied, isTrue);
    });

    test('Water Bubble and Purifying Salt combine status and damage gates', () {
      final waterBaseline = _calculatedDamage(moveType: 'water');
      final waterBubbleWater = _calculatedDamage(
        abilityId: 'water_bubble',
        moveType: 'water',
      );
      final fireBaseline = _calculatedDamage(moveType: 'fire');
      final waterBubbleFire = _calculatedDamage(
        opponentAbilityId: 'water_bubble',
        moveType: 'fire',
      );
      final ghostBaseline = _calculatedDamage(moveType: 'ghost');
      final ghostTargetBaseline = _calculatedDamage(
        moveType: 'ghost',
        opponentTypes: const PsdkBattleTypes(primary: 'psychic'),
      );
      final purifyingGhost = _calculatedDamage(
        opponentAbilityId: 'purifying_salt',
        moveType: 'ghost',
        opponentTypes: const PsdkBattleTypes(primary: 'psychic'),
      );
      final waterBubbleBurn = _applyStatusToPlayer(
        playerAbilityId: 'water_bubble',
        status: PsdkBattleMajorStatus.burn,
      );
      final purifyingSleep = _applyStatusToPlayer(
        playerAbilityId: 'purifying_salt',
        status: PsdkBattleMajorStatus.sleep,
      );
      final purifyingSalt = _abilityEffectForOpponent('purifying_salt');
      final statusMove = purifyingSalt.onMovePreventionTarget(
        BattleEffectMoveContext(
          user: const BattlePositionRef(bank: 0, position: 0),
          target: const BattlePositionRef(bank: 1, position: 0),
          move: _definition(
            id: 'sleep_powder',
            power: 0,
            category: PsdkBattleMoveCategory.status,
            statuses: <PsdkBattleMoveStatus>[
              PsdkBattleMoveStatus(
                status: PsdkBattleMajorStatus.sleep,
                chance: 100,
              ),
            ],
          ),
        ),
      );
      final neutralMove = purifyingSalt.onMovePreventionTarget(
        BattleEffectMoveContext(
          user: const BattlePositionRef(bank: 0, position: 0),
          target: const BattlePositionRef(bank: 1, position: 0),
          move: _definition(
            id: 'growl',
            power: 0,
            category: PsdkBattleMoveCategory.status,
          ),
        ),
      );

      expect(waterBubbleWater, greaterThan(waterBaseline));
      expect(waterBubbleFire, lessThan(fireBaseline));
      expect(ghostBaseline, 0);
      expect(purifyingGhost, lessThan(ghostTargetBaseline));
      expect(waterBubbleBurn.applied, isFalse);
      expect(waterBubbleBurn.reason, 'ability:water_bubble');
      expect(purifyingSleep.applied, isFalse);
      expect(purifyingSleep.reason, 'ability:purifying_salt');
      expect(statusMove, BattleMoveFailureReason.immunity);
      expect(neutralMove, isNull);
    });

    test('Comatose prevents new statuses without curing bypassed statuses', () {
      final switchIn = _dispatchAbilitySwitchIn(
        playerAbilityId: 'comatose',
        playerMajorStatus: PsdkBattleMajorStatus.sleep,
      );
      final state = PsdkBattleState.fromSetup(
        BattleEngineSetup.singles(
          player: _combatant(
            id: 'player',
            abilityId: 'comatose',
            majorStatus: PsdkBattleMajorStatus.sleep,
            move: _move(id: 'tackle', power: 40),
          ),
          opponent: _combatant(
            id: 'opponent',
            move: _move(id: 'tackle', power: 40),
          ),
          rngSeeds: const BattleRngSeeds(
            moveDamage: 1,
            moveCritical: 99999,
            moveAccuracy: 3,
            generic: 4,
          ).psdkSeeds,
        ).psdkSetup,
      );
      final effect = state.battlerAt(psdkPlayerSlot).abilityEffects.single;
      final postStatus = effect.onPostStatusChange(
        BattleEffectStatusChangeContext(
          state: state,
          rng: _rng(),
          turn: 1,
          owner: psdkPlayerSlot,
          user: psdkOpponentSlot,
          target: psdkPlayerSlot,
          status: PsdkBattleMajorStatus.sleep,
          cured: false,
          moveId: 'bypass_probe',
        ),
      );

      expect(switchIn.applied, isFalse);
      expect(
        switchIn.state.battlerAt(psdkPlayerSlot).majorStatus,
        PsdkBattleMajorStatus.sleep,
      );
      expect(postStatus, isNull);
    });

    test('non-volatile status immunity abilities cure bypassed status hooks',
        () {
      final state = PsdkBattleState.fromSetup(
        BattleEngineSetup.singles(
          player: _combatant(
            id: 'player',
            abilityId: 'limber',
            majorStatus: PsdkBattleMajorStatus.paralysis,
            move: _move(id: 'tackle', power: 40),
          ),
          opponent: _combatant(
            id: 'opponent',
            move: _move(id: 'tackle', power: 40),
          ),
          rngSeeds: const BattleRngSeeds(
            moveDamage: 1,
            moveCritical: 99999,
            moveAccuracy: 3,
            generic: 4,
          ).psdkSeeds,
        ).psdkSetup,
      );
      final effect = state.battlerAt(psdkPlayerSlot).abilityEffects.single;

      final result = effect.onPostStatusChange(
        BattleEffectStatusChangeContext(
          state: state,
          rng: _rng(),
          turn: 1,
          owner: psdkPlayerSlot,
          user: psdkOpponentSlot,
          target: psdkPlayerSlot,
          status: PsdkBattleMajorStatus.paralysis,
          cured: false,
          moveId: 'bypass_probe',
        ),
      );

      expect(result, isNotNull);
      expect(result!.state.battlerAt(psdkPlayerSlot).majorStatus, isNull);
      expect(
          result.events.whereType<PsdkBattleStatusCureEvent>(), hasLength(1));
      expect(
        result.events.whereType<PsdkBattleStatusCureEvent>().single.moveId,
        'effect:limber',
      );
    });
  });
}

PsdkBattleTurnResult _runMove({
  required PsdkBattleMoveData playerMove,
  String? playerAbilityId,
  String? opponentAbilityId,
  PsdkBattleMajorStatus? playerMajorStatus,
  PsdkBattleMajorStatus? opponentMajorStatus,
  PsdkBattleTypes opponentTypes = const PsdkBattleTypes(primary: 'normal'),
  int playerCurrentHp = 100,
  int opponentCurrentHp = 100,
  PsdkBattleFieldState field = const PsdkBattleFieldState(),
  BattleRngSeeds rngSeeds = const BattleRngSeeds(
    moveDamage: 1,
    moveCritical: 99999,
    moveAccuracy: 3,
    generic: 4,
  ),
}) {
  final engine = PsdkBattleEngine(
    setup: BattleEngineSetup.singles(
      player: _combatant(
        id: 'player',
        currentHp: playerCurrentHp,
        abilityId: playerAbilityId,
        majorStatus: playerMajorStatus,
        speed: 100,
        move: playerMove,
      ),
      opponent: _combatant(
        id: 'opponent',
        currentHp: opponentCurrentHp,
        abilityId: opponentAbilityId,
        majorStatus: opponentMajorStatus,
        types: opponentTypes,
        speed: 1,
        move: _move(
          id: 'opponent_wait',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 1,
          battleEngineMethod: 's_splash',
        ),
      ),
      rngSeeds: rngSeeds.psdkSeeds,
      field: field,
    ).psdkSetup,
  );
  return engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
}

PsdkBattleFightAction _fightActionForAbility({
  required String abilityId,
  PsdkBattleFieldState field = const PsdkBattleFieldState(),
  PsdkBattleMajorStatus? majorStatus,
}) {
  final state = PsdkBattleState.fromSetup(
    BattleEngineSetup.singles(
      player: _combatant(
        id: 'player',
        abilityId: abilityId,
        majorStatus: majorStatus,
        speed: 50,
        move: _move(id: 'tackle', power: 40),
      ),
      opponent: _combatant(
        id: 'opponent',
        speed: 80,
        move: _move(id: 'opponent_wait', power: 0),
      ),
      rngSeeds: const BattleRngSeeds(
        moveDamage: 1,
        moveCritical: 99999,
        moveAccuracy: 3,
        generic: 4,
      ).psdkSeeds,
      field: field,
    ).psdkSetup,
  );

  return const PsdkBattleActionDecisionMapper().map(
    state: state,
    user: psdkPlayerSlot,
    decision: const BattleFightDecision(moveSlot: 0),
  ) as PsdkBattleFightAction;
}

BattleHandlerResult _switchPreventionFor({
  String? playerAbilityId,
  String? opponentAbilityId,
  PsdkBattleTypes playerTypes = const PsdkBattleTypes(primary: 'normal'),
}) {
  final state = PsdkBattleState.fromSetup(
    BattleEngineSetup.singles(
      player: _combatant(
        id: 'player',
        abilityId: playerAbilityId,
        types: playerTypes,
        move: _move(id: 'tackle', power: 40),
      ),
      opponent: _combatant(
        id: 'opponent',
        abilityId: opponentAbilityId,
        move: _move(id: 'opponent_wait', power: 0),
      ),
      rngSeeds: const BattleRngSeeds(
        moveDamage: 1,
        moveCritical: 99999,
        moveAccuracy: 3,
        generic: 4,
      ).psdkSeeds,
    ).psdkSetup,
  );

  return const BattleSwitchHandler().resolveSwitchPrevention(
    context: BattleHandlerContext(
      state: state,
      rng: _rng(),
      turn: 1,
      user: psdkPlayerSlot,
    ),
    target: psdkPlayerSlot,
  );
}

BattleHandlerResult _dispatchAbilitySwitchIn({
  required String playerAbilityId,
  String? playerHeldItemId,
  PsdkBattleMajorStatus? playerMajorStatus,
  String? opponentAbilityId,
  String? opponentHeldItemId,
  String opponentSpeciesId = 'opponent',
  String opponentDisplayName = 'opponent',
  PsdkBattleTypes opponentTypes = const PsdkBattleTypes(primary: 'normal'),
  PsdkBattleStats? opponentStats,
  PsdkBattleStatStages? opponentStatStages,
  PsdkBattleTransformState opponentTransformState =
      const PsdkBattleTransformState(),
  double opponentCurrentWeightKg = 1,
  List<PsdkBattleMoveData>? opponentMoves,
  PsdkBattleFieldState field = const PsdkBattleFieldState(),
}) {
  const benchSlot = PsdkBattleSlotRef(bank: 0, position: -1);
  final state = PsdkBattleState.fromSetup(
    BattleEngineSetup.singles(
      player: _combatant(
        id: 'player',
        abilityId: playerAbilityId,
        heldItemId: playerHeldItemId,
        majorStatus: playerMajorStatus,
        move: _move(id: 'tackle', power: 40),
      ),
      opponent: _combatant(
        id: 'opponent',
        speciesId: opponentSpeciesId,
        displayName: opponentDisplayName,
        abilityId: opponentAbilityId,
        heldItemId: opponentHeldItemId,
        types: opponentTypes,
        stats: opponentStats,
        statStages: opponentStatStages,
        transformState: opponentTransformState,
        currentWeightKg: opponentCurrentWeightKg,
        moves: opponentMoves,
        move: _move(id: 'opponent_wait', power: 0),
      ),
      rngSeeds: const BattleRngSeeds(
        moveDamage: 1,
        moveCritical: 99999,
        moveAccuracy: 3,
        generic: 4,
      ).psdkSeeds,
      field: field,
    ).psdkSetup,
  );

  return const BattleSwitchHandler().dispatchSwitchEvents(
    context: BattleHandlerContext(
      state: state,
      rng: _rng(),
      turn: 1,
      user: psdkPlayerSlot,
    ),
    who: benchSlot,
    replacement: psdkPlayerSlot,
  );
}

BattleHandlerResult _resolveAbilityEndTurn({
  required String playerAbilityId,
  int playerCurrentHp = 100,
  PsdkBattleMajorStatus? playerMajorStatus,
  int opponentCurrentHp = 100,
  PsdkBattleMajorStatus? opponentMajorStatus,
  PsdkBattleFieldState field = const PsdkBattleFieldState(),
  BattleRngSeeds rngSeeds = const BattleRngSeeds(
    moveDamage: 1,
    moveCritical: 99999,
    moveAccuracy: 3,
    generic: 4,
  ),
}) {
  final state = PsdkBattleState.fromSetup(
    BattleEngineSetup.singles(
      player: _combatant(
        id: 'player',
        abilityId: playerAbilityId,
        currentHp: playerCurrentHp,
        majorStatus: playerMajorStatus,
        move: _move(id: 'tackle', power: 40),
      ),
      opponent: _combatant(
        id: 'opponent',
        currentHp: opponentCurrentHp,
        majorStatus: opponentMajorStatus,
        move: _move(id: 'opponent_wait', power: 0),
      ),
      rngSeeds: rngSeeds.psdkSeeds,
      field: field,
    ).psdkSetup,
  );

  return const BattleEndTurnHandler().resolveEndTurn(
    BattleHandlerContext(
      state: state,
      rng: BattleRngStreams.fromSeedSnapshot(rngSeeds),
      turn: 1,
      user: psdkPlayerSlot,
    ),
  );
}

const _psdkPlayerAllySlot = PsdkBattleSlotRef(bank: 0, position: 1);

BattleHandlerResult _resolveHealerEndTurn({required int genericSeed}) {
  final state = PsdkBattleState(
    combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
      psdkPlayerSlot: PsdkBattleCombatant.fromSetup(
        _combatant(
          id: 'player',
          abilityId: 'healer',
          move: _move(id: 'tackle', power: 40),
        ),
      ),
      _psdkPlayerAllySlot: PsdkBattleCombatant.fromSetup(
        _combatant(
          id: 'ally',
          majorStatus: PsdkBattleMajorStatus.paralysis,
          move: _move(id: 'ally_wait', power: 0),
        ),
      ),
      psdkOpponentSlot: PsdkBattleCombatant.fromSetup(
        _combatant(id: 'opponent', move: _move(id: 'opponent_wait', power: 0)),
      ),
    },
  );

  return const BattleEndTurnHandler().resolveEndTurn(
    BattleHandlerContext(
      state: state,
      rng: BattleRngStreams.fromSeeds(
        moveDamageSeed: 1,
        moveCriticalSeed: 99999,
        moveAccuracySeed: 3,
        genericSeed: genericSeed,
      ),
      turn: 1,
      user: psdkPlayerSlot,
    ),
  );
}

BattleHandlerResult _dispatchHospitalitySwitchIn() {
  final state = PsdkBattleState(
    combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
      psdkPlayerSlot: PsdkBattleCombatant.fromSetup(
        _combatant(
          id: 'player',
          abilityId: 'hospitality',
          move: _move(id: 'tackle', power: 40),
        ),
      ),
      _psdkPlayerAllySlot: PsdkBattleCombatant.fromSetup(
        _combatant(
          id: 'ally',
          currentHp: 50,
          move: _move(id: 'ally_wait', power: 0),
        ),
      ),
      psdkOpponentSlot: PsdkBattleCombatant.fromSetup(
        _combatant(id: 'opponent', move: _move(id: 'opponent_wait', power: 0)),
      ),
    },
  );

  return const BattleSwitchHandler().dispatchSwitchEvents(
    context: BattleHandlerContext(
      state: state,
      rng: _rng(),
      turn: 1,
      user: psdkPlayerSlot,
    ),
    who: const PsdkBattleSlotRef(bank: 0, position: -1),
    replacement: psdkPlayerSlot,
  );
}

BattleHandlerResult _applyStatusToOpponent({
  required String opponentAbilityId,
  required PsdkBattleMajorStatus status,
}) {
  final state = PsdkBattleState.fromSetup(
    BattleEngineSetup.singles(
      player: _combatant(id: 'player', move: _move(id: 'tackle', power: 40)),
      opponent: _combatant(
        id: 'opponent',
        abilityId: opponentAbilityId,
        move: _move(id: 'opponent_wait', power: 0),
      ),
      rngSeeds: const BattleRngSeeds(
        moveDamage: 1,
        moveCritical: 99999,
        moveAccuracy: 3,
        generic: 4,
      ).psdkSeeds,
    ).psdkSetup,
  );

  return const BattleStatusChangeHandler().applyMajorStatus(
    context: BattleHandlerContext(
      state: state,
      rng: _rng(),
      turn: 1,
      user: psdkPlayerSlot,
    ),
    target: psdkOpponentSlot,
    moveId: 'test:status',
    status: status,
  );
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  String? speciesId,
  String? displayName,
  String? abilityId,
  String? heldItemId,
  int currentHp = 100,
  int battleTurnCount = 0,
  bool switching = false,
  int speed = 50,
  PsdkBattleTypes types = const PsdkBattleTypes(primary: 'normal'),
  PsdkBattleStats? stats,
  PsdkBattleStatStages? statStages,
  PsdkBattleTransformState transformState = const PsdkBattleTransformState(),
  PsdkBattleMajorStatus? majorStatus,
  double currentWeightKg = 1,
  List<PsdkBattleMoveData>? moves,
  required PsdkBattleMoveData move,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: speciesId ?? id,
    displayName: displayName ?? id,
    level: 20,
    maxHp: 100,
    currentHp: currentHp,
    battleTurnCount: battleTurnCount,
    types: types,
    stats: stats ??
        PsdkBattleStats(
          attack: 50,
          defense: 50,
          specialAttack: 50,
          specialDefense: 50,
          speed: speed,
        ),
    abilityId: abilityId,
    heldItemId: heldItemId,
    statStages: statStages,
    transformState: transformState,
    majorStatus: majorStatus,
    baseWeightKg: currentWeightKg,
    currentWeightKg: currentWeightKg,
    switching: switching,
    moves: moves ?? <PsdkBattleMoveData>[move],
  );
}

PsdkBattleMoveData _move({
  required String id,
  String? dbSymbol,
  String type = 'normal',
  PsdkBattleMoveCategory category = PsdkBattleMoveCategory.physical,
  required int power,
  int accuracy = 100,
  int priority = 0,
  String battleEngineMethod = 's_basic',
  PsdkBattleMoveTarget target = PsdkBattleMoveTarget.adjacentFoe,
  bool protectable = true,
  bool sound = false,
  bool ballistics = false,
}) {
  return PsdkBattleMoveData(
    id: id,
    dbSymbol: dbSymbol ?? id,
    name: id,
    type: type,
    category: category,
    power: power,
    accuracy: accuracy,
    pp: 35,
    priority: priority,
    criticalRate: 1,
    battleEngineMethod: battleEngineMethod,
    target: target,
    protectable: protectable,
    sound: sound,
    ballistics: ballistics,
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

List<PsdkBattleDamageEvent> _damageEventsForHandler(
  BattleHandlerResult result,
) {
  return result.events.whereType<PsdkBattleDamageEvent>().toList(
        growable: false,
      );
}

BattleRngStreams _rng() {
  return BattleRngStreams.fromSeeds(
    moveDamageSeed: 1,
    moveCriticalSeed: 2,
    moveAccuracySeed: 3,
    genericSeed: 4,
  );
}

int _calculatedDamage({
  String? abilityId,
  String? opponentAbilityId,
  String moveType = 'normal',
  PsdkBattleTypes opponentTypes = const PsdkBattleTypes(primary: 'normal'),
  int playerCurrentHp = 100,
  int opponentCurrentHp = 100,
  int playerBattleTurnCount = 0,
  bool opponentSwitching = false,
  PsdkBattleMajorStatus? playerMajorStatus,
  PsdkBattleFieldState field = const PsdkBattleFieldState(),
  BattleMoveFlags flags = const BattleMoveFlags(),
  PsdkBattleMoveCategory category = PsdkBattleMoveCategory.physical,
  String battleEngineMethod = 's_basic',
  bool isLastActionOfTurn = false,
}) {
  final state = PsdkBattleState.fromSetup(
    BattleEngineSetup.singles(
      player: _combatant(
        id: 'player',
        abilityId: abilityId,
        currentHp: playerCurrentHp,
        battleTurnCount: playerBattleTurnCount,
        majorStatus: playerMajorStatus,
        move: _move(id: 'shape_test', power: 60, category: category),
      ),
      opponent: _combatant(
        id: 'opponent',
        abilityId: opponentAbilityId,
        currentHp: opponentCurrentHp,
        switching: opponentSwitching,
        types: opponentTypes,
        move: _move(id: 'opponent_wait', power: 0),
      ),
      rngSeeds: const BattleRngSeeds(
        moveDamage: 1,
        moveCritical: 99999,
        moveAccuracy: 3,
        generic: 4,
      ).psdkSeeds,
      field: field,
    ).psdkSetup,
  );

  return const BattleMoveDamageCalculator()
      .calculate(
        BattleMoveDamageContext(
          user: state.battlerAt(psdkPlayerSlot),
          target: state.battlerAt(psdkOpponentSlot),
          move: BattleMoveDefinition(
            id: 'shape_test',
            dbSymbol: 'shape_test',
            name: 'shape_test',
            type: moveType,
            category: category,
            power: 60,
            accuracy: 100,
            pp: 35,
            priority: 0,
            criticalRate: 1,
            battleEngineMethod: battleEngineMethod,
            target: PsdkBattleMoveTarget.adjacentFoe,
            flags: flags,
          ),
          rng: _rng(),
          field: field,
          isLastActionOfTurn: isLastActionOfTurn,
        ),
      )
      .damage;
}

int _calculatedDoublesDamage({
  String? userAllyAbilityId,
  String? targetAllyAbilityId,
  String moveType = 'normal',
  PsdkBattleMoveCategory category = PsdkBattleMoveCategory.physical,
}) {
  const userSlot = PsdkBattleSlotRef(bank: 0, position: 0);
  const userAllySlot = PsdkBattleSlotRef(bank: 0, position: 1);
  const targetSlot = PsdkBattleSlotRef(bank: 1, position: 0);
  const targetAllySlot = PsdkBattleSlotRef(bank: 1, position: 1);
  final state = PsdkBattleState(
    combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
      userSlot: PsdkBattleCombatant.fromSetup(
        _combatant(id: 'user', move: _move(id: 'doubles_move', power: 60)),
      ),
      userAllySlot: PsdkBattleCombatant.fromSetup(
        _combatant(
          id: 'user_ally',
          abilityId: userAllyAbilityId,
          move: _move(id: 'user_ally_wait', power: 0),
        ),
      ),
      targetSlot: PsdkBattleCombatant.fromSetup(
        _combatant(id: 'target', move: _move(id: 'target_wait', power: 0)),
      ),
      targetAllySlot: PsdkBattleCombatant.fromSetup(
        _combatant(
          id: 'target_ally',
          abilityId: targetAllyAbilityId,
          move: _move(id: 'target_ally_wait', power: 0),
        ),
      ),
    },
  );

  return const BattleMoveDamageCalculator()
      .calculate(
        BattleMoveDamageContext(
          state: state,
          userSlot: userSlot,
          targetSlot: targetSlot,
          user: state.battlerAt(userSlot),
          target: state.battlerAt(targetSlot),
          move: BattleMoveDefinition(
            id: 'doubles_move',
            dbSymbol: 'doubles_move',
            name: 'doubles_move',
            type: moveType,
            category: category,
            power: 60,
            accuracy: 100,
            pp: 35,
            priority: 0,
            criticalRate: 1,
            battleEngineMethod: 's_basic',
            target: PsdkBattleMoveTarget.adjacentFoe,
          ),
          rng: _rng(),
          field: state.field,
        ),
      )
      .damage;
}

BattleHandlerResult _applyDirectAbilityDamage({
  String? opponentAbilityId,
  String? playerAbilityId,
  String moveType = 'normal',
  PsdkBattleMoveCategory category = PsdkBattleMoveCategory.special,
  BattleMoveFlags flags = const BattleMoveFlags(),
  int opponentCurrentHp = 100,
  int rawDamage = 30,
  PsdkBattleTypes playerTypes = const PsdkBattleTypes(primary: 'normal'),
  PsdkBattleTypes opponentTypes = const PsdkBattleTypes(primary: 'normal'),
  String? playerHeldItemId,
  PsdkBattleMajorStatus? playerMajorStatus,
  BattleRngSeeds rngSeeds = const BattleRngSeeds(
    moveDamage: 1,
    moveCritical: 99999,
    moveAccuracy: 3,
    generic: 4,
  ),
}) {
  final state = PsdkBattleState.fromSetup(
    BattleEngineSetup.singles(
      player: _combatant(
        id: 'player',
        abilityId: playerAbilityId,
        types: playerTypes,
        heldItemId: playerHeldItemId,
        majorStatus: playerMajorStatus,
        move: _move(id: 'typed_hit', type: moveType, power: 60),
      ),
      opponent: _combatant(
        id: 'opponent',
        currentHp: opponentCurrentHp,
        types: opponentTypes,
        abilityId: opponentAbilityId,
        move: _move(id: 'opponent_wait', power: 0),
      ),
      rngSeeds: rngSeeds.psdkSeeds,
    ).psdkSetup,
  );

  return const BattleDamageHandler().applyDamage(
    context: BattleHandlerContext(
      state: state,
      rng: BattleRngStreams.fromSeedSnapshot(rngSeeds),
      turn: 1,
      user: psdkPlayerSlot,
    ),
    target: psdkOpponentSlot,
    moveId: 'typed_hit',
    rawDamage: rawDamage,
    move: BattleMoveDefinition(
      id: 'typed_hit',
      dbSymbol: 'typed_hit',
      name: 'typed_hit',
      type: moveType,
      category: category,
      power: 60,
      accuracy: 100,
      pp: 35,
      priority: 0,
      battleEngineMethod: 's_basic',
      target: PsdkBattleMoveTarget.adjacentFoe,
      flags: flags,
    ),
  );
}

List<PsdkBattleStatStageEvent> _statEventsForHandler(
  BattleHandlerResult result,
) {
  return result.events.whereType<PsdkBattleStatStageEvent>().toList();
}

BattleEffect _abilityEffectForOpponent(String abilityId) {
  final state = PsdkBattleState.fromSetup(
    BattleEngineSetup.singles(
      player: _combatant(
        id: 'player',
        move: _move(id: 'tackle', power: 40),
      ),
      opponent: _combatant(
        id: 'opponent',
        abilityId: abilityId,
        move: _move(id: 'opponent_wait', power: 0),
      ),
      rngSeeds: const BattleRngSeeds(
        moveDamage: 1,
        moveCritical: 99999,
        moveAccuracy: 3,
        generic: 4,
      ).psdkSeeds,
    ).psdkSetup,
  );
  final effects = state.battlerAt(psdkOpponentSlot).abilityEffects.toList();
  expect(effects, isNotEmpty, reason: abilityId);
  return effects.single;
}

BattleHandlerResult _applyPlayerStatDrop({
  required String playerAbilityId,
  required String stat,
  int stages = -1,
  PsdkBattleTypes playerTypes = const PsdkBattleTypes(primary: 'normal'),
  PsdkBattleSlotRef user = psdkOpponentSlot,
}) {
  final state = PsdkBattleState.fromSetup(
    BattleEngineSetup.singles(
      player: _combatant(
        id: 'player',
        abilityId: playerAbilityId,
        types: playerTypes,
        move: _move(id: 'tackle', power: 40),
      ),
      opponent: _combatant(
        id: 'opponent',
        move: _move(id: 'opponent_wait', power: 0),
      ),
      rngSeeds: const BattleRngSeeds(
        moveDamage: 1,
        moveCritical: 99999,
        moveAccuracy: 3,
        generic: 4,
      ).psdkSeeds,
    ).psdkSetup,
  );

  return const BattleStatChangeHandler().applyStatChange(
    context: BattleHandlerContext(
      state: state,
      rng: _rng(),
      turn: 1,
      user: user,
    ),
    target: psdkPlayerSlot,
    stat: stat,
    stages: stages,
  );
}

BattleHandlerResult _applyStatusToPlayer({
  required String playerAbilityId,
  required PsdkBattleMajorStatus status,
  PsdkBattleTypes playerTypes = const PsdkBattleTypes(primary: 'normal'),
  PsdkBattleFieldState field = const PsdkBattleFieldState(),
}) {
  final state = PsdkBattleState.fromSetup(
    BattleEngineSetup.singles(
      player: _combatant(
        id: 'player',
        abilityId: playerAbilityId,
        types: playerTypes,
        move: _move(id: 'tackle', power: 40),
      ),
      opponent: _combatant(
        id: 'opponent',
        move: _move(id: 'status_probe', power: 0),
      ),
      rngSeeds: const BattleRngSeeds(
        moveDamage: 1,
        moveCritical: 99999,
        moveAccuracy: 3,
        generic: 4,
      ).psdkSeeds,
      field: field,
    ).psdkSetup,
  );

  return const BattleStatusChangeHandler().applyMajorStatus(
    context: BattleHandlerContext(
      state: state,
      rng: _rng(),
      turn: 1,
      user: psdkOpponentSlot,
    ),
    target: psdkPlayerSlot,
    moveId: 'status_probe',
    status: status,
  );
}

BattleMoveDefinition _definition({
  required String id,
  String type = 'normal',
  PsdkBattleMoveCategory category = PsdkBattleMoveCategory.physical,
  required int power,
  String battleEngineMethod = 's_basic',
  BattleMoveFlags flags = const BattleMoveFlags(),
  List<PsdkBattleMoveStatus> statuses = const <PsdkBattleMoveStatus>[],
}) {
  return BattleMoveDefinition(
    id: id,
    dbSymbol: id,
    name: id,
    type: type,
    category: category,
    power: power,
    accuracy: 100,
    pp: 35,
    priority: 0,
    battleEngineMethod: battleEngineMethod,
    target: PsdkBattleMoveTarget.adjacentFoe,
    flags: flags,
    statuses: statuses,
  );
}
