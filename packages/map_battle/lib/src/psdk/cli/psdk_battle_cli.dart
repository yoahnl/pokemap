import 'dart:convert';

import '../psdk_battle.dart';

/// Tiny CLI harness for the parallel PSDK battle lane.
///
/// The CLI exists to smoke-test deterministic PSDK data without involving the
/// Flutter runtime or editor. It deliberately uses an embedded fixture until a
/// later migration lot defines file IO and import-pack plumbing.
class PsdkBattleCli {
  const PsdkBattleCli({
    required this.stdout,
    required this.stderr,
  });

  final void Function(String line) stdout;
  final void Function(String line) stderr;

  Future<int> run(List<String> args) async {
    final parseResult = _parseArgs(args);
    if (parseResult.error != null) {
      stderr(parseResult.error!);
      return 64;
    }

    final smoke = _runSmokeBattle(parseResult.scenario);
    switch (parseResult.format) {
      case _PsdkBattleCliFormat.json:
        stdout(jsonEncode(smoke.toJson()));
      case _PsdkBattleCliFormat.text:
        stdout(
          'outcome=${smoke.outcome} turns=${smoke.turns} '
          'playerHp=${smoke.playerHp} opponentHp=${smoke.opponentHp} '
          'terrain=${smoke.terrain} weather=${smoke.weather}',
        );
    }
    return 0;
  }

  _PsdkBattleCliParseResult _parseArgs(List<String> args) {
    var format = _PsdkBattleCliFormat.text;
    var scenario = _PsdkBattleCliScenario.defaultSmoke;
    var index = 0;
    while (index < args.length) {
      final arg = args[index];
      if (arg == '--format') {
        if (index + 1 >= args.length) {
          return const _PsdkBattleCliParseResult.error(
            'Missing value for --format.',
          );
        }
        final value = args[index + 1];
        if (value == 'json') {
          format = _PsdkBattleCliFormat.json;
        } else if (value == 'text') {
          format = _PsdkBattleCliFormat.text;
        } else {
          return _PsdkBattleCliParseResult.error(
            'Unknown --format value "$value". Expected json or text.',
          );
        }
        index += 2;
        continue;
      }
      if (arg == '--scenario') {
        if (index + 1 >= args.length) {
          return const _PsdkBattleCliParseResult.error(
            'Missing value for --scenario.',
          );
        }
        final value = args[index + 1];
        final parsed = _parseScenario(value);
        if (parsed == null) {
          return _PsdkBattleCliParseResult.error(
            'Unknown --scenario value "$value". Expected default, immunity, '
            'miss, super_effective, critical, secondary_effect, pp_empty, '
            'prevented, protect, fixed_damage, multi_hit, advanced_multi_hit, '
            'basic_specialization, direct_hp, healing, recoil, mind_blown, '
            'explosion, terrain_boosting, variable_power, custom_stat, '
            'weight_power, damp_ability, or loaded_dice.',
          );
        }
        scenario = parsed;
        index += 2;
        continue;
      }

      return _PsdkBattleCliParseResult.error('Unknown argument "$arg".');
    }

    return _PsdkBattleCliParseResult(format: format, scenario: scenario);
  }

  _PsdkBattleCliSmokeResult _runSmokeBattle(
    _PsdkBattleCliScenario scenario,
  ) {
    final config = _scenarioConfig(scenario);
    final engine = PsdkBattleEngine(
      setup: config.setup,
      moveProcedureHooks: config.moveProcedureHooks,
    );
    PsdkBattleTurnResult? result;
    var turns = 0;
    final events = <PsdkBattleEvent>[];

    while (engine.state.outcome == null && turns < config.turnLimit) {
      result = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      turns += 1;
      events.addAll(result.timeline.events);

      // Guardrail for this hard-coded smoke fixture: an infinite loop would
      // mean the deterministic fixture no longer proves a terminating battle.
      if (config.mustFinish &&
          result.state.outcome == null &&
          turns >= config.turnLimit) {
        throw StateError(
          'PSDK smoke battle did not finish within ${config.turnLimit} turns.',
        );
      }
    }

    final state = result?.state ?? engine.state;
    return _PsdkBattleCliSmokeResult(
      outcome: state.outcome?.kind.name ?? 'ongoing',
      turns: turns,
      playerHp: state
          .battlerAt(const PsdkBattleSlotRef(bank: 0, position: 0))
          .currentHp,
      opponentHp: state
          .battlerAt(const PsdkBattleSlotRef(bank: 1, position: 0))
          .currentHp,
      terrain: state.field.terrain?.id.jsonName ?? 'none',
      weather: state.field.weather?.id.jsonName ?? 'none',
      events: events,
    );
  }
}

enum _PsdkBattleCliFormat {
  json,
  text,
}

enum _PsdkBattleCliScenario {
  defaultSmoke,
  immunity,
  miss,
  superEffective,
  critical,
  secondaryEffect,
  ppEmpty,
  prevented,
  protect,
  fixedDamage,
  multiHit,
  advancedMultiHit,
  basicSpecialization,
  directHp,
  healing,
  recoil,
  mindBlown,
  explosion,
  terrainBoosting,
  variablePower,
  customStat,
  weightPower,
  dampAbility,
  loadedDice,
}

class _PsdkBattleCliParseResult {
  const _PsdkBattleCliParseResult({
    required this.format,
    required this.scenario,
  }) : error = null;

  const _PsdkBattleCliParseResult.error(this.error)
      : format = _PsdkBattleCliFormat.text,
        scenario = _PsdkBattleCliScenario.defaultSmoke;

  final _PsdkBattleCliFormat format;
  final _PsdkBattleCliScenario scenario;
  final String? error;
}

_PsdkBattleCliScenario? _parseScenario(String value) {
  return switch (value) {
    'default' || 'smoke' => _PsdkBattleCliScenario.defaultSmoke,
    'immunity' => _PsdkBattleCliScenario.immunity,
    'miss' => _PsdkBattleCliScenario.miss,
    'super_effective' ||
    'super-effective' =>
      _PsdkBattleCliScenario.superEffective,
    'critical' => _PsdkBattleCliScenario.critical,
    'secondary_effect' ||
    'secondary-effect' =>
      _PsdkBattleCliScenario.secondaryEffect,
    'pp_empty' || 'pp-empty' => _PsdkBattleCliScenario.ppEmpty,
    'prevented' => _PsdkBattleCliScenario.prevented,
    'protect' => _PsdkBattleCliScenario.protect,
    'fixed_damage' || 'fixed-damage' => _PsdkBattleCliScenario.fixedDamage,
    'multi_hit' || 'multi-hit' => _PsdkBattleCliScenario.multiHit,
    'advanced_multi_hit' ||
    'advanced-multi-hit' =>
      _PsdkBattleCliScenario.advancedMultiHit,
    'basic_specialization' ||
    'basic-specialization' =>
      _PsdkBattleCliScenario.basicSpecialization,
    'direct_hp' || 'direct-hp' => _PsdkBattleCliScenario.directHp,
    'healing' || 'heal' => _PsdkBattleCliScenario.healing,
    'recoil' => _PsdkBattleCliScenario.recoil,
    'mind_blown' || 'mind-blown' => _PsdkBattleCliScenario.mindBlown,
    'explosion' ||
    'self_destruct' ||
    'self-destruct' =>
      _PsdkBattleCliScenario.explosion,
    'terrain_boosting' ||
    'terrain-boosting' =>
      _PsdkBattleCliScenario.terrainBoosting,
    'variable_power' ||
    'variable-power' =>
      _PsdkBattleCliScenario.variablePower,
    'custom_stat' || 'custom-stat' => _PsdkBattleCliScenario.customStat,
    'weight_power' || 'weight-power' => _PsdkBattleCliScenario.weightPower,
    'damp_ability' || 'damp-ability' => _PsdkBattleCliScenario.dampAbility,
    'loaded_dice' || 'loaded-dice' => _PsdkBattleCliScenario.loadedDice,
    _ => null,
  };
}

class _PsdkBattleCliSmokeResult {
  const _PsdkBattleCliSmokeResult({
    required this.outcome,
    required this.turns,
    required this.playerHp,
    required this.opponentHp,
    required this.terrain,
    required this.weather,
    required this.events,
  });

  final String outcome;
  final int turns;
  final int playerHp;
  final int opponentHp;
  final String terrain;
  final String weather;
  final List<PsdkBattleEvent> events;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'outcome': outcome,
      'turns': turns,
      'playerHp': playerHp,
      'opponentHp': opponentHp,
      'terrain': terrain,
      'weather': weather,
      'events': events.map((event) => event.toJson()).toList(growable: false),
    };
  }
}

final class _PsdkBattleCliScenarioConfig {
  const _PsdkBattleCliScenarioConfig({
    required this.setup,
    required this.turnLimit,
    required this.mustFinish,
    this.moveProcedureHooks = BattleMoveProcedureHooks.none,
  });

  final PsdkBattleSetup setup;
  final int turnLimit;
  final bool mustFinish;
  final BattleMoveProcedureHooks moveProcedureHooks;
}

_PsdkBattleCliScenarioConfig _scenarioConfig(
  _PsdkBattleCliScenario scenario,
) {
  return switch (scenario) {
    _PsdkBattleCliScenario.defaultSmoke => _PsdkBattleCliScenarioConfig(
        setup: _smokeSetup(),
        turnLimit: 20,
        mustFinish: true,
      ),
    _PsdkBattleCliScenario.immunity => _PsdkBattleCliScenarioConfig(
        setup: _singleTurnSetup(
          playerTypes: const PsdkBattleTypes(primary: 'electric'),
          opponentTypes: const PsdkBattleTypes(primary: 'ground'),
          playerMove: _move(
            id: 'thunder_shock',
            type: 'electric',
            category: PsdkBattleMoveCategory.special,
            power: 40,
          ),
          rngSeeds: const PsdkBattleRngSeeds(
            moveDamage: 1,
            moveCritical: 99999,
            moveAccuracy: 3,
            generic: 4,
          ),
        ),
        turnLimit: 1,
        mustFinish: false,
      ),
    _PsdkBattleCliScenario.miss => _PsdkBattleCliScenarioConfig(
        setup: _singleTurnSetup(
          playerTypes: const PsdkBattleTypes(primary: 'normal'),
          opponentTypes: const PsdkBattleTypes(primary: 'water'),
          playerMove: _move(
            id: 'tackle',
            type: 'normal',
            power: 40,
            accuracy: 1,
          ),
          rngSeeds: const PsdkBattleRngSeeds(
            moveDamage: 1,
            moveCritical: 99999,
            moveAccuracy: 99,
            generic: 4,
          ),
        ),
        turnLimit: 1,
        mustFinish: false,
      ),
    _PsdkBattleCliScenario.superEffective => _PsdkBattleCliScenarioConfig(
        setup: _singleTurnSetup(
          playerTypes: const PsdkBattleTypes(primary: 'fire'),
          opponentTypes: const PsdkBattleTypes(primary: 'grass'),
          playerMove: _move(
            id: 'ember',
            type: 'fire',
            category: PsdkBattleMoveCategory.special,
            power: 40,
          ),
          rngSeeds: const PsdkBattleRngSeeds(
            moveDamage: 1,
            moveCritical: 99999,
            moveAccuracy: 3,
            generic: 4,
          ),
        ),
        turnLimit: 1,
        mustFinish: false,
      ),
    _PsdkBattleCliScenario.critical => _PsdkBattleCliScenarioConfig(
        setup: _singleTurnSetup(
          playerTypes: const PsdkBattleTypes(primary: 'normal'),
          opponentTypes: const PsdkBattleTypes(primary: 'water'),
          playerMove: _move(
            id: 'karate_chop',
            type: 'normal',
            power: 40,
            criticalRate: 4,
          ),
          rngSeeds: const PsdkBattleRngSeeds(
            moveDamage: 1,
            moveCritical: 2,
            moveAccuracy: 3,
            generic: 4,
          ),
        ),
        turnLimit: 1,
        mustFinish: false,
      ),
    _PsdkBattleCliScenario.secondaryEffect => _PsdkBattleCliScenarioConfig(
        setup: _singleTurnSetup(
          playerTypes: const PsdkBattleTypes(primary: 'fire'),
          opponentTypes: const PsdkBattleTypes(primary: 'grass'),
          playerMove: _move(
            id: 'flame_bite',
            type: 'fire',
            power: 40,
            statuses: <PsdkBattleMoveStatus>[
              PsdkBattleMoveStatus(
                status: PsdkBattleMajorStatus.burn,
                chance: 100,
              ),
            ],
            stageMods: const <PsdkBattleMoveStageMod>[
              PsdkBattleMoveStageMod(
                stat: 'defense',
                stages: -1,
                chance: 100,
              ),
            ],
          ),
          rngSeeds: const PsdkBattleRngSeeds(
            moveDamage: 1,
            moveCritical: 99999,
            moveAccuracy: 3,
            generic: 4,
          ),
        ),
        turnLimit: 1,
        mustFinish: false,
      ),
    _PsdkBattleCliScenario.ppEmpty => _PsdkBattleCliScenarioConfig(
        setup: _singleTurnSetup(
          playerTypes: const PsdkBattleTypes(primary: 'fire'),
          opponentTypes: const PsdkBattleTypes(primary: 'grass'),
          playerMove: _move(
            id: 'empty_ember',
            type: 'fire',
            category: PsdkBattleMoveCategory.special,
            power: 40,
            currentPp: 0,
          ),
          rngSeeds: const PsdkBattleRngSeeds(
            moveDamage: 1,
            moveCritical: 99999,
            moveAccuracy: 3,
            generic: 4,
          ),
        ),
        turnLimit: 1,
        mustFinish: false,
      ),
    _PsdkBattleCliScenario.prevented => _PsdkBattleCliScenarioConfig(
        setup: _singleTurnSetup(
          playerTypes: const PsdkBattleTypes(primary: 'normal'),
          opponentTypes: const PsdkBattleTypes(primary: 'water'),
          playerMove: _move(
            id: 'blocked_tackle',
            type: 'normal',
            power: 40,
          ),
          rngSeeds: const PsdkBattleRngSeeds(
            moveDamage: 1,
            moveCritical: 99999,
            moveAccuracy: 3,
            generic: 4,
          ),
        ),
        turnLimit: 1,
        mustFinish: false,
        moveProcedureHooks: BattleMoveProcedureHooks(
          userPreventionHooks: <BattleMoveUserPreventionHook>[
            (context) {
              if (context.move.id != 'blocked_tackle') {
                return null;
              }
              return const BattleMoveUserPreventionResult(
                reason: BattleMoveFailureReason.unusableByUser,
              );
            },
          ],
        ),
      ),
    _PsdkBattleCliScenario.protect => _PsdkBattleCliScenarioConfig(
        setup: _singleTurnSetup(
          playerTypes: const PsdkBattleTypes(primary: 'normal'),
          opponentTypes: const PsdkBattleTypes(primary: 'normal'),
          playerMove: _move(
            id: 'protect',
            type: 'normal',
            category: PsdkBattleMoveCategory.status,
            power: 0,
            accuracy: 0,
            priority: 4,
            battleEngineMethod: 's_protect',
            target: PsdkBattleMoveTarget.user,
          ),
          opponentMove: _move(
            id: 'opponent_tackle',
            type: 'normal',
            power: 40,
          ),
          rngSeeds: const PsdkBattleRngSeeds(
            moveDamage: 1,
            moveCritical: 99999,
            moveAccuracy: 3,
            generic: 4,
          ),
        ),
        turnLimit: 1,
        mustFinish: false,
      ),
    _PsdkBattleCliScenario.fixedDamage => _PsdkBattleCliScenarioConfig(
        setup: _singleTurnSetup(
          playerTypes: const PsdkBattleTypes(primary: 'dragon'),
          opponentTypes: const PsdkBattleTypes(primary: 'normal'),
          playerMove: _move(
            id: 'dragon_rage',
            type: 'dragon',
            category: PsdkBattleMoveCategory.special,
            power: 1,
            battleEngineMethod: 's_fixed_damage',
          ),
          rngSeeds: const PsdkBattleRngSeeds(
            moveDamage: 1,
            moveCritical: 99999,
            moveAccuracy: 3,
            generic: 4,
          ),
        ),
        turnLimit: 1,
        mustFinish: false,
      ),
    _PsdkBattleCliScenario.multiHit => _PsdkBattleCliScenarioConfig(
        setup: _singleTurnSetup(
          playerTypes: const PsdkBattleTypes(primary: 'normal'),
          opponentTypes: const PsdkBattleTypes(primary: 'water'),
          playerMove: _move(
            id: 'double_slap',
            type: 'normal',
            power: 25,
            battleEngineMethod: 's_multi_hit',
          ),
          rngSeeds: const PsdkBattleRngSeeds(
            moveDamage: 1,
            moveCritical: 99999,
            moveAccuracy: 3,
            generic: 5,
          ),
        ),
        turnLimit: 1,
        mustFinish: false,
      ),
    _PsdkBattleCliScenario.advancedMultiHit => _PsdkBattleCliScenarioConfig(
        setup: _singleTurnSetup(
          playerTypes: const PsdkBattleTypes(primary: 'fire'),
          opponentTypes: const PsdkBattleTypes(primary: 'fire'),
          playerMove: _move(
            id: 'triple_kick',
            type: 'normal',
            power: 10,
            battleEngineMethod: 's_triple_kick',
          ),
          rngSeeds: const PsdkBattleRngSeeds(
            moveDamage: 1,
            moveCritical: 99999,
            moveAccuracy: 3,
            generic: 4,
          ),
        ),
        turnLimit: 1,
        mustFinish: false,
      ),
    _PsdkBattleCliScenario.basicSpecialization => _PsdkBattleCliScenarioConfig(
        setup: _singleTurnSetup(
          playerTypes: const PsdkBattleTypes(primary: 'fire'),
          opponentTypes: const PsdkBattleTypes(primary: 'fire'),
          opponentCurrentHp: 30,
          playerMove: _move(
            id: 'false_swipe',
            type: 'normal',
            power: 200,
            battleEngineMethod: 's_false_swipe',
          ),
          opponentMove: _move(
            id: 'full_crit_slash',
            type: 'normal',
            power: 80,
            battleEngineMethod: 's_full_crit',
          ),
          rngSeeds: const PsdkBattleRngSeeds(
            moveDamage: 1,
            moveCritical: 99999,
            moveAccuracy: 3,
            generic: 4,
          ),
        ),
        turnLimit: 1,
        mustFinish: false,
      ),
    _PsdkBattleCliScenario.directHp => _PsdkBattleCliScenarioConfig(
        setup: _singleTurnSetup(
          playerTypes: const PsdkBattleTypes(primary: 'normal'),
          opponentTypes: const PsdkBattleTypes(primary: 'normal'),
          playerCurrentHp: 40,
          playerMove: _move(
            id: 'endeavor',
            type: 'normal',
            power: 1,
            battleEngineMethod: 's_endeavor',
          ),
          opponentMove: _move(
            id: 'splash',
            type: 'normal',
            category: PsdkBattleMoveCategory.status,
            power: 0,
            battleEngineMethod: 's_splash',
          ),
          rngSeeds: const PsdkBattleRngSeeds(
            moveDamage: 1,
            moveCritical: 99999,
            moveAccuracy: 3,
            generic: 4,
          ),
        ),
        turnLimit: 1,
        mustFinish: false,
      ),
    _PsdkBattleCliScenario.healing => _PsdkBattleCliScenarioConfig(
        setup: _singleTurnSetup(
          playerTypes: const PsdkBattleTypes(primary: 'fire'),
          opponentTypes: const PsdkBattleTypes(primary: 'fire'),
          playerCurrentHp: 10,
          field: const PsdkBattleFieldState(
            weather: PsdkBattleWeatherState(
              id: PsdkBattleWeatherId.sunny,
              remainingTurns: 5,
            ),
          ),
          playerMove: _move(
            id: 'moonlight',
            type: 'normal',
            category: PsdkBattleMoveCategory.status,
            power: 0,
            battleEngineMethod: 's_heal_weather',
            target: PsdkBattleMoveTarget.user,
          ),
          rngSeeds: const PsdkBattleRngSeeds(
            moveDamage: 1,
            moveCritical: 99999,
            moveAccuracy: 3,
            generic: 4,
          ),
        ),
        turnLimit: 1,
        mustFinish: false,
      ),
    _PsdkBattleCliScenario.recoil => _PsdkBattleCliScenarioConfig(
        setup: _singleTurnSetup(
          playerTypes: const PsdkBattleTypes(primary: 'fire'),
          opponentTypes: const PsdkBattleTypes(primary: 'fire'),
          playerMove: _move(
            id: 'take_down',
            type: 'normal',
            power: 40,
            battleEngineMethod: 's_recoil',
          ),
          rngSeeds: const PsdkBattleRngSeeds(
            moveDamage: 1,
            moveCritical: 99999,
            moveAccuracy: 3,
            generic: 4,
          ),
        ),
        turnLimit: 1,
        mustFinish: false,
      ),
    _PsdkBattleCliScenario.mindBlown => _PsdkBattleCliScenarioConfig(
        setup: _singleTurnSetup(
          playerTypes: const PsdkBattleTypes(primary: 'fire'),
          opponentTypes: const PsdkBattleTypes(primary: 'normal'),
          playerMove: _move(
            id: 'mind_blown',
            type: 'fire',
            category: PsdkBattleMoveCategory.special,
            power: 40,
            battleEngineMethod: 's_mind_blown',
          ),
          rngSeeds: const PsdkBattleRngSeeds(
            moveDamage: 1,
            moveCritical: 99999,
            moveAccuracy: 3,
            generic: 4,
          ),
        ),
        turnLimit: 1,
        mustFinish: false,
      ),
    _PsdkBattleCliScenario.explosion => _PsdkBattleCliScenarioConfig(
        setup: _singleTurnSetup(
          playerTypes: const PsdkBattleTypes(primary: 'fire'),
          opponentTypes: const PsdkBattleTypes(primary: 'fire'),
          playerMove: _move(
            id: 'explosion',
            type: 'normal',
            power: 40,
            battleEngineMethod: 's_explosion',
          ),
          rngSeeds: const PsdkBattleRngSeeds(
            moveDamage: 1,
            moveCritical: 99999,
            moveAccuracy: 3,
            generic: 4,
          ),
        ),
        turnLimit: 1,
        mustFinish: false,
      ),
    _PsdkBattleCliScenario.terrainBoosting => _PsdkBattleCliScenarioConfig(
        setup: _singleTurnSetup(
          playerTypes: const PsdkBattleTypes(primary: 'fire'),
          opponentTypes: const PsdkBattleTypes(primary: 'fire'),
          field: const PsdkBattleFieldState(
            terrain: PsdkBattleTerrainState(
              id: PsdkBattleTerrainId.electricTerrain,
              remainingTurns: 5,
            ),
          ),
          playerMove: _move(
            id: 'psyblade',
            type: 'psychic',
            power: 80,
            battleEngineMethod: 's_terrain_boosting',
          ),
          rngSeeds: const PsdkBattleRngSeeds(
            moveDamage: 1,
            moveCritical: 99999,
            moveAccuracy: 3,
            generic: 4,
          ),
        ),
        turnLimit: 1,
        mustFinish: false,
      ),
    _PsdkBattleCliScenario.variablePower => _PsdkBattleCliScenarioConfig(
        setup: _singleTurnSetup(
          playerTypes: const PsdkBattleTypes(primary: 'fire'),
          opponentTypes: const PsdkBattleTypes(primary: 'normal'),
          opponentCurrentHp: 50,
          playerMove: _move(
            id: 'brine',
            type: 'water',
            category: PsdkBattleMoveCategory.special,
            power: 65,
            battleEngineMethod: 's_brine',
          ),
          rngSeeds: const PsdkBattleRngSeeds(
            moveDamage: 1,
            moveCritical: 99999,
            moveAccuracy: 3,
            generic: 4,
          ),
        ),
        turnLimit: 1,
        mustFinish: false,
      ),
    _PsdkBattleCliScenario.customStat => _PsdkBattleCliScenarioConfig(
        setup: _singleTurnSetup(
          playerTypes: const PsdkBattleTypes(primary: 'fire'),
          opponentTypes: const PsdkBattleTypes(primary: 'fire'),
          playerStats: const PsdkBattleStats(
            attack: 10,
            defense: 100,
            specialAttack: 50,
            specialDefense: 50,
            speed: 100,
          ),
          playerMove: _move(
            id: 'body_press',
            type: 'normal',
            power: 80,
            battleEngineMethod: 's_body_press',
          ),
          rngSeeds: const PsdkBattleRngSeeds(
            moveDamage: 1,
            moveCritical: 99999,
            moveAccuracy: 3,
            generic: 4,
          ),
        ),
        turnLimit: 1,
        mustFinish: false,
      ),
    _PsdkBattleCliScenario.weightPower => _PsdkBattleCliScenarioConfig(
        setup: _singleTurnSetup(
          playerTypes: const PsdkBattleTypes(primary: 'fire'),
          opponentTypes: const PsdkBattleTypes(primary: 'fire'),
          playerWeightKg: 20,
          opponentWeightKg: 100,
          playerMove: _move(
            id: 'low_kick',
            type: 'normal',
            power: 1,
            battleEngineMethod: 's_low_kick',
          ),
          opponentMove: _move(
            id: 'heavy_slam',
            type: 'normal',
            power: 1,
            battleEngineMethod: 's_heavy_slam',
          ),
          rngSeeds: const PsdkBattleRngSeeds(
            moveDamage: 1,
            moveCritical: 99999,
            moveAccuracy: 3,
            generic: 4,
          ),
        ),
        turnLimit: 1,
        mustFinish: false,
      ),
    _PsdkBattleCliScenario.dampAbility => _PsdkBattleCliScenarioConfig(
        setup: _singleTurnSetup(
          playerTypes: const PsdkBattleTypes(primary: 'normal'),
          opponentTypes: const PsdkBattleTypes(primary: 'normal'),
          opponentAbilityId: 'damp',
          playerMove: _move(
            id: 'explosion',
            type: 'normal',
            power: 250,
            battleEngineMethod: 's_explosion',
          ),
          rngSeeds: const PsdkBattleRngSeeds(
            moveDamage: 1,
            moveCritical: 99999,
            moveAccuracy: 3,
            generic: 4,
          ),
        ),
        turnLimit: 1,
        mustFinish: false,
      ),
    _PsdkBattleCliScenario.loadedDice => _PsdkBattleCliScenarioConfig(
        setup: _singleTurnSetup(
          playerTypes: const PsdkBattleTypes(primary: 'normal'),
          opponentTypes: const PsdkBattleTypes(primary: 'normal'),
          opponentCurrentHp: 200,
          playerHeldItemId: 'loaded_dice',
          playerMove: _move(
            id: 'double_slap',
            type: 'normal',
            power: 25,
            battleEngineMethod: 's_multi_hit',
          ),
          rngSeeds: const PsdkBattleRngSeeds(
            moveDamage: 1,
            moveCritical: 99999,
            moveAccuracy: 3,
            generic: 0,
          ),
        ),
        turnLimit: 1,
        mustFinish: false,
      ),
  };
}

PsdkBattleSetup _smokeSetup() {
  return PsdkBattleSetup.singles(
    player: PsdkBattleCombatantSetup(
      id: 'player-charmander',
      speciesId: 'charmander',
      displayName: 'Charmander',
      level: 12,
      maxHp: 44,
      currentHp: 44,
      types: const PsdkBattleTypes(primary: 'fire'),
      stats: const PsdkBattleStats(
        attack: 64,
        defense: 43,
        specialAttack: 60,
        specialDefense: 50,
        speed: 65,
      ),
      moves: <PsdkBattleMoveData>[
        PsdkBattleMoveData(
          id: 'scratch',
          dbSymbol: 'scratch',
          name: 'Scratch',
          type: 'normal',
          category: PsdkBattleMoveCategory.physical,
          power: 180,
          accuracy: 100,
          pp: 35,
          priority: 0,
          battleEngineMethod: 's_basic',
          target: PsdkBattleMoveTarget.adjacentFoe,
        ),
      ],
    ),
    opponent: PsdkBattleCombatantSetup(
      id: 'opponent-bulbasaur',
      speciesId: 'bulbasaur',
      displayName: 'Bulbasaur',
      level: 10,
      maxHp: 18,
      currentHp: 18,
      types: const PsdkBattleTypes(primary: 'grass', secondary: 'poison'),
      stats: const PsdkBattleStats(
        attack: 49,
        defense: 49,
        specialAttack: 65,
        specialDefense: 65,
        speed: 45,
      ),
      moves: <PsdkBattleMoveData>[
        PsdkBattleMoveData(
          id: 'tackle',
          dbSymbol: 'tackle',
          name: 'Tackle',
          type: 'normal',
          category: PsdkBattleMoveCategory.physical,
          power: 20,
          accuracy: 100,
          pp: 35,
          priority: 0,
          battleEngineMethod: 's_basic',
          target: PsdkBattleMoveTarget.adjacentFoe,
        ),
      ],
    ),
    rngSeeds: const PsdkBattleRngSeeds(
      moveDamage: 1,
      moveCritical: 2,
      moveAccuracy: 3,
      generic: 4,
    ),
  );
}

PsdkBattleSetup _singleTurnSetup({
  required PsdkBattleTypes playerTypes,
  required PsdkBattleTypes opponentTypes,
  required PsdkBattleMoveData playerMove,
  required PsdkBattleRngSeeds rngSeeds,
  int playerCurrentHp = 100,
  int opponentCurrentHp = 100,
  double playerWeightKg = 50,
  double opponentWeightKg = 50,
  String? playerAbilityId,
  String? opponentAbilityId,
  String? playerHeldItemId,
  String? opponentHeldItemId,
  PsdkBattleFieldState field = const PsdkBattleFieldState(),
  PsdkBattleStats playerStats = const PsdkBattleStats(
    attack: 50,
    defense: 50,
    specialAttack: 50,
    specialDefense: 50,
    speed: 100,
  ),
  PsdkBattleMoveData? opponentMove,
}) {
  return PsdkBattleSetup.singles(
    player: PsdkBattleCombatantSetup(
      id: 'player',
      speciesId: 'player',
      displayName: 'Player',
      level: 20,
      maxHp: 100,
      currentHp: playerCurrentHp,
      types: playerTypes,
      stats: playerStats,
      abilityId: playerAbilityId,
      heldItemId: playerHeldItemId,
      baseWeightKg: playerWeightKg,
      moves: <PsdkBattleMoveData>[playerMove],
    ),
    opponent: PsdkBattleCombatantSetup(
      id: 'opponent',
      speciesId: 'opponent',
      displayName: 'Opponent',
      level: 20,
      maxHp: 100,
      currentHp: opponentCurrentHp,
      types: opponentTypes,
      stats: const PsdkBattleStats(
        attack: 50,
        defense: 50,
        specialAttack: 50,
        specialDefense: 50,
        speed: 1,
      ),
      abilityId: opponentAbilityId,
      heldItemId: opponentHeldItemId,
      baseWeightKg: opponentWeightKg,
      moves: <PsdkBattleMoveData>[
        opponentMove ??
            _move(
              id: 'opponent_wait',
              type: 'normal',
              power: 0,
              accuracy: 1,
            ),
      ],
    ),
    rngSeeds: rngSeeds,
    field: field,
  );
}

PsdkBattleMoveData _move({
  required String id,
  required String type,
  PsdkBattleMoveCategory category = PsdkBattleMoveCategory.physical,
  required int power,
  int accuracy = 100,
  int criticalRate = 1,
  int priority = 0,
  int? currentPp,
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
    currentPp: currentPp,
    priority: priority,
    criticalRate: criticalRate,
    effectChance: effectChance,
    battleEngineMethod: battleEngineMethod,
    target: target,
    statuses: statuses,
    stageMods: stageMods,
  );
}
