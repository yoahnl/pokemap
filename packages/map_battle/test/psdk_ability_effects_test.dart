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

    test('Damp prevents self-destruct moves before PP and damage apply', () {
      final result = _runMove(
        opponentAbilityId: 'damp',
        playerMove: _move(
          id: 'explosion',
          power: 250,
          battleEngineMethod: 's_explosion',
        ),
      );

      final events = _eventsFor(result, moveId: 'explosion');
      expect(events.map((event) => event.kind), <String>['move_failed']);
      expect((events.single as PsdkBattleMoveFailedEvent).reason,
          BattleMoveFailureReason.unusableByUser.jsonName);
      expect(_damageEvents(result, moveId: 'explosion'), isEmpty);
      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 100);
      expect(result.state.battlerAt(psdkOpponentSlot).currentHp, 100);
      expect(
        result.state.battlerAt(psdkPlayerSlot).moves.single.currentPp,
        35,
      );
    });

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

    test('non-volatile status immunity abilities prevent matching status', () {
      final result = const BattleStatusChangeHandler().applyMajorStatus(
        context: BattleHandlerContext(
          state: PsdkBattleState.fromSetup(
            BattleEngineSetup.singles(
              player: _combatant(
                id: 'player',
                abilityId: 'water_veil',
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
        moveId: 'will_o_wisp',
        status: PsdkBattleMajorStatus.burn,
      );

      expect(result.applied, isFalse);
      expect(result.reason, 'status_immune');
      expect(
        result.state.battlerAt(psdkPlayerSlot).majorStatus,
        isNull,
      );
    });
  });
}

PsdkBattleTurnResult _runMove({
  required PsdkBattleMoveData playerMove,
  String? playerAbilityId,
  String? opponentAbilityId,
  int playerCurrentHp = 100,
  int opponentCurrentHp = 100,
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
        speed: 100,
        move: playerMove,
      ),
      opponent: _combatant(
        id: 'opponent',
        currentHp: opponentCurrentHp,
        abilityId: opponentAbilityId,
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
    ).psdkSetup,
  );
  return engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
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
  String? opponentAbilityId,
  String opponentSpeciesId = 'opponent',
  String opponentDisplayName = 'opponent',
  PsdkBattleTypes opponentTypes = const PsdkBattleTypes(primary: 'normal'),
  PsdkBattleStats? opponentStats,
  PsdkBattleStatStages? opponentStatStages,
  PsdkBattleTransformState opponentTransformState =
      const PsdkBattleTransformState(),
  double opponentCurrentWeightKg = 1,
  List<PsdkBattleMoveData>? opponentMoves,
}) {
  const benchSlot = PsdkBattleSlotRef(bank: 0, position: -1);
  final state = PsdkBattleState.fromSetup(
    BattleEngineSetup.singles(
      player: _combatant(
        id: 'player',
        abilityId: playerAbilityId,
        heldItemId: playerHeldItemId,
        move: _move(id: 'tackle', power: 40),
      ),
      opponent: _combatant(
        id: 'opponent',
        speciesId: opponentSpeciesId,
        displayName: opponentDisplayName,
        abilityId: opponentAbilityId,
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
  PsdkBattleFieldState field = const PsdkBattleFieldState(),
}) {
  final state = PsdkBattleState.fromSetup(
    BattleEngineSetup.singles(
      player: _combatant(
        id: 'player',
        abilityId: playerAbilityId,
        currentHp: playerCurrentHp,
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
      field: field,
    ).psdkSetup,
  );

  return const BattleEndTurnHandler().resolveEndTurn(
    BattleHandlerContext(
      state: state,
      rng: _rng(),
      turn: 1,
      user: psdkPlayerSlot,
    ),
  );
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  String? speciesId,
  String? displayName,
  String? abilityId,
  String? heldItemId,
  int currentHp = 100,
  int speed = 50,
  PsdkBattleTypes types = const PsdkBattleTypes(primary: 'normal'),
  PsdkBattleStats? stats,
  PsdkBattleStatStages? statStages,
  PsdkBattleTransformState transformState = const PsdkBattleTransformState(),
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
    baseWeightKg: currentWeightKg,
    currentWeightKg: currentWeightKg,
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
  String battleEngineMethod = 's_basic',
  PsdkBattleMoveTarget target = PsdkBattleMoveTarget.adjacentFoe,
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
    priority: 0,
    criticalRate: 1,
    battleEngineMethod: battleEngineMethod,
    target: target,
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
  BattleMoveFlags flags = const BattleMoveFlags(),
  PsdkBattleMoveCategory category = PsdkBattleMoveCategory.physical,
}) {
  final state = PsdkBattleState.fromSetup(
    BattleEngineSetup.singles(
      player: _combatant(
        id: 'player',
        abilityId: abilityId,
        move: _move(id: 'shape_test', power: 60, category: category),
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

  return const BattleMoveDamageCalculator()
      .calculate(
        BattleMoveDamageContext(
          user: state.battlerAt(psdkPlayerSlot),
          target: state.battlerAt(psdkOpponentSlot),
          move: BattleMoveDefinition(
            id: 'shape_test',
            dbSymbol: 'shape_test',
            name: 'shape_test',
            type: 'normal',
            category: category,
            power: 60,
            accuracy: 100,
            pp: 35,
            priority: 0,
            criticalRate: 1,
            battleEngineMethod: 's_basic',
            target: PsdkBattleMoveTarget.adjacentFoe,
            flags: flags,
          ),
          rng: _rng(),
        ),
      )
      .damage;
}

BattleHandlerResult _applyDirectAbilityDamage({
  required String opponentAbilityId,
  required String moveType,
  int opponentCurrentHp = 100,
}) {
  final state = PsdkBattleState.fromSetup(
    BattleEngineSetup.singles(
      player: _combatant(
        id: 'player',
        move: _move(id: 'typed_hit', type: moveType, power: 60),
      ),
      opponent: _combatant(
        id: 'opponent',
        currentHp: opponentCurrentHp,
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

  return const BattleDamageHandler().applyDamage(
    context: BattleHandlerContext(
      state: state,
      rng: _rng(),
      turn: 1,
      user: psdkPlayerSlot,
    ),
    target: psdkOpponentSlot,
    moveId: 'typed_hit',
    rawDamage: 30,
    move: BattleMoveDefinition(
      id: 'typed_hit',
      dbSymbol: 'typed_hit',
      name: 'typed_hit',
      type: moveType,
      category: PsdkBattleMoveCategory.special,
      power: 60,
      accuracy: 100,
      pp: 35,
      priority: 0,
      battleEngineMethod: 's_basic',
      target: PsdkBattleMoveTarget.adjacentFoe,
    ),
  );
}
