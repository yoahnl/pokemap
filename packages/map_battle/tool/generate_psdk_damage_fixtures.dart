// Génère les fixtures golden de la formule de dégâts (BETA-BAT-002).
//
// Le ticket demande des vecteurs « sérialisables et réutilisables dans la CI ».
// Les valeurs attendues viennent de `psdkReferenceDamage`, transcrit du Ruby de
// PSDK, JAMAIS du calculateur Dart. Le moteur n'est rejoué que pour capturer la
// forme de la timeline, qui n'est pas ce que ces vecteurs certifient.
//
// LE GÉNÉRATEUR EST LUI-MÊME UNE PORTE DE PARITÉ : si l'oracle et le moteur ne
// tombent pas d'accord sur les dégâts, il refuse d'écrire et sort en erreur.
// Régénérer les fixtures ne peut donc pas servir à faire taire un écart, ce qui
// est exactement le risque que le ticket nomme.
//
// Usage :
//   dart run tool/generate_psdk_damage_fixtures.dart [--check]
//
// `--check` ne récrit rien et échoue si un fichier committé a dérivé.

import 'dart:convert';
import 'dart:io';

import 'package:map_battle/map_battle.dart';

const _seeds = PsdkBattleRngSeeds(
  moveDamage: 1,
  moveCritical: 99999,
  moveAccuracy: 3,
  generic: 4,
);

/// Roll produit par `moveDamage: 1`.
final int _roll = psdkDamageRollForSeed(_seeds.moveDamage);

const String _psdkVersion = 'pokemonsdk-development-local-2026-05-16';
const String _damageCalcSource = '10 Move/101 Damage_Calc.rb';
const String _basicSource = '10 Move/1 Mechanics/100 Basic.rb';
const String _burnSource = '06 Effects/03 Status Effects/103 Burn.rb';
const String _rainSource = '06 Effects/06 Weather Effects/100 Rain.rb';
const String _sunSource = '06 Effects/06 Weather Effects/100 Sunny.rb';

final class _Vector {
  const _Vector({
    required this.id,
    required this.purpose,
    required this.tags,
    required this.sources,
    required this.move,
    required this.attackerTypes,
    required this.defenderTypes,
    this.level = 20,
    this.offensiveStat = 50,
    this.defensiveStat = 50,
    this.mod1 = 1,
    this.criticalMultiplier = 1,
    this.stab = 1,
    this.combinedTypeMultiplier = 1,
    this.referencePower,
    this.attackerStatus,
    this.attackerAbility,
    this.attackerHeldItem,
    this.weather,
    this.decoyPhysicalStat,
  });

  final String id;
  final String purpose;
  final List<String> tags;
  final List<String> sources;
  final _Move move;
  final List<String> attackerTypes;
  final List<String> defenderTypes;
  final int level;
  final int offensiveStat;
  final int defensiveStat;
  final double mod1;
  final double criticalMultiplier;
  final double stab;
  final double combinedTypeMultiplier;

  /// Puissance vue par la formule quand un talent ou un objet l'a déjà modifiée.
  final int? referencePower;
  final PsdkBattleMajorStatus? attackerStatus;
  final String? attackerAbility;
  final String? attackerHeldItem;
  final PsdkBattleWeatherId? weather;

  /// Statistique physique volontairement énorme, pour qu'un vecteur spécial
  /// explose si le calculateur lit la mauvaise colonne.
  final int? decoyPhysicalStat;

  int get expectedDamage => psdkReferenceDamage(
        roll: _roll,
        level: level,
        power: referencePower ?? move.power,
        offensiveStat: offensiveStat,
        defensiveStat: defensiveStat,
        mod1: mod1,
        criticalMultiplier: criticalMultiplier,
        stab: stab,
        combinedTypeMultiplier: combinedTypeMultiplier,
      );
}

final class _Move {
  const _Move({
    required this.id,
    required this.type,
    required this.power,
    this.category = PsdkBattleMoveCategory.physical,
    this.criticalRate = 1,
  });

  final String id;
  final String type;
  final int power;
  final PsdkBattleMoveCategory category;
  final int criticalRate;
}

const _tackle = _Move(id: 'tackle', type: 'normal', power: 40);
const _swift = _Move(
  id: 'swift',
  type: 'normal',
  power: 40,
  category: PsdkBattleMoveCategory.special,
);
const _ember = _Move(id: 'ember', type: 'fire', power: 40);
const _emberSpecial = _Move(
  id: 'ember',
  type: 'fire',
  power: 40,
  category: PsdkBattleMoveCategory.special,
);

final List<_Vector> _vectors = <_Vector>[
  const _Vector(
    id: 'damage_physical_neutral',
    purpose: 'Physical hit with no modifier, the baseline of the chain.',
    tags: <String>['move_method', 'damage'],
    sources: <String>[_basicSource, _damageCalcSource],
    move: _tackle,
    attackerTypes: <String>['water'],
    defenderTypes: <String>['normal'],
  ),
  const _Vector(
    id: 'damage_special_reads_special_stats',
    purpose:
        'Special hit with a decoy physical stat of 200 on both sides: reading '
        'the wrong column would blow the value far out of range.',
    tags: <String>['move_method', 'damage'],
    sources: <String>[_basicSource, _damageCalcSource],
    move: _swift,
    attackerTypes: <String>['water'],
    defenderTypes: <String>['normal'],
    decoyPhysicalStat: 200,
  ),
  const _Vector(
    id: 'damage_awkward_truncations',
    purpose:
        'Level 23, power 43, 53 against 17: no step lands round, so a one '
        'point error at any truncation survives to the end.',
    tags: <String>['move_method', 'damage'],
    sources: <String>[_basicSource, _damageCalcSource],
    move: _Move(id: 'ember', type: 'fire', power: 43),
    attackerTypes: <String>['fire'],
    defenderTypes: <String>['normal'],
    level: 23,
    offensiveStat: 53,
    defensiveStat: 17,
    stab: 1.5,
  ),
  const _Vector(
    id: 'damage_stab_primary_type',
    purpose: 'STAB from the primary type.',
    tags: <String>['move_method', 'damage'],
    sources: <String>[_basicSource, _damageCalcSource],
    move: _ember,
    attackerTypes: <String>['fire'],
    defenderTypes: <String>['normal'],
    stab: 1.5,
  ),
  const _Vector(
    id: 'damage_stab_secondary_type',
    purpose: 'STAB from the secondary type, applied exactly once.',
    tags: <String>['move_method', 'damage'],
    sources: <String>[_basicSource, _damageCalcSource],
    move: _ember,
    attackerTypes: <String>['rock', 'fire'],
    defenderTypes: <String>['normal'],
    stab: 1.5,
  ),
  const _Vector(
    id: 'damage_type_weakness',
    purpose: 'Super effective hit.',
    tags: <String>['move_method', 'damage'],
    sources: <String>[_basicSource, _damageCalcSource],
    move: _ember,
    attackerTypes: <String>['water'],
    defenderTypes: <String>['grass'],
    combinedTypeMultiplier: 2,
  ),
  const _Vector(
    id: 'damage_type_resistance',
    purpose: 'Resisted hit.',
    tags: <String>['move_method', 'damage'],
    sources: <String>[_basicSource, _damageCalcSource],
    move: _ember,
    attackerTypes: <String>['water'],
    defenderTypes: <String>['water'],
    combinedTypeMultiplier: 0.5,
  ),
  const _Vector(
    id: 'damage_critical_hit',
    purpose: 'Guaranteed critical, multiplied by 1.5 before the roll.',
    tags: <String>['move_method', 'damage'],
    sources: <String>[_basicSource, _damageCalcSource],
    move: _Move(id: 'slash', type: 'normal', power: 40, criticalRate: 6),
    attackerTypes: <String>['water'],
    defenderTypes: <String>['normal'],
    criticalMultiplier: 1.5,
  ),
  const _Vector(
    id: 'damage_burn_halves_physical',
    purpose: 'Burn as a Mod1 multiplier, applied before the +2.',
    tags: <String>['move_method', 'status', 'damage'],
    sources: <String>[_burnSource, _damageCalcSource],
    move: _tackle,
    attackerTypes: <String>['water'],
    defenderTypes: <String>['normal'],
    attackerStatus: PsdkBattleMajorStatus.burn,
    mod1: 0.5,
  ),
  const _Vector(
    id: 'damage_burn_spares_special',
    purpose: 'Burn leaves a special hit alone.',
    tags: <String>['move_method', 'status', 'damage'],
    sources: <String>[_burnSource, _damageCalcSource],
    move: _swift,
    attackerTypes: <String>['water'],
    defenderTypes: <String>['normal'],
    attackerStatus: PsdkBattleMajorStatus.burn,
  ),
  const _Vector(
    id: 'damage_rain_boosts_water',
    purpose: 'Rain as a Mod1 multiplier on a water move.',
    tags: <String>['field', 'damage'],
    sources: <String>[_rainSource, _damageCalcSource],
    move: _Move(id: 'water_gun', type: 'water', power: 40),
    attackerTypes: <String>['normal'],
    defenderTypes: <String>['normal'],
    weather: PsdkBattleWeatherId.rain,
    mod1: 1.5,
  ),
  const _Vector(
    id: 'damage_rain_weakens_fire',
    purpose: 'Rain halves a fire move through the same Mod1 slot.',
    tags: <String>['field', 'damage'],
    sources: <String>[_rainSource, _damageCalcSource],
    move: _ember,
    attackerTypes: <String>['normal'],
    defenderTypes: <String>['normal'],
    weather: PsdkBattleWeatherId.rain,
    mod1: 0.5,
  ),
  const _Vector(
    id: 'damage_sun_boosts_fire',
    purpose: 'Sun as a Mod1 multiplier on a fire move.',
    tags: <String>['field', 'damage'],
    sources: <String>[_sunSource, _damageCalcSource],
    move: _ember,
    attackerTypes: <String>['normal'],
    defenderTypes: <String>['normal'],
    weather: PsdkBattleWeatherId.sunny,
    mod1: 1.5,
  ),
  const _Vector(
    id: 'damage_sun_weakens_water',
    purpose: 'Sun halves a water move.',
    tags: <String>['field', 'damage'],
    sources: <String>[_sunSource, _damageCalcSource],
    move: _Move(id: 'water_gun', type: 'water', power: 40),
    attackerTypes: <String>['normal'],
    defenderTypes: <String>['normal'],
    weather: PsdkBattleWeatherId.sunny,
    mod1: 0.5,
  ),
  const _Vector(
    id: 'damage_ability_boosts_base_power',
    purpose:
        'Technician multiplies the base power upstream of the chain, so the '
        'reference takes 60 rather than an extra multiplier at the end.',
    tags: <String>['ability', 'damage'],
    sources: <String>[_basicSource, _damageCalcSource],
    move: _tackle,
    attackerTypes: <String>['water'],
    defenderTypes: <String>['normal'],
    attackerAbility: 'technician',
    referencePower: 60,
  ),
  const _Vector(
    id: 'damage_held_item_boosts_its_type',
    purpose: 'Charcoal multiplies the base power of fire moves by 1.2.',
    tags: <String>['item', 'damage'],
    sources: <String>[_basicSource, _damageCalcSource],
    move: _ember,
    attackerTypes: <String>['water'],
    defenderTypes: <String>['normal'],
    attackerHeldItem: 'charcoal',
    referencePower: 48,
  ),
  const _Vector(
    id: 'damage_held_item_ignores_other_types',
    purpose: 'Charcoal leaves a move of another type alone.',
    tags: <String>['item', 'damage'],
    sources: <String>[_basicSource, _damageCalcSource],
    move: _tackle,
    attackerTypes: <String>['water'],
    defenderTypes: <String>['normal'],
    attackerHeldItem: 'charcoal',
  ),
  const _Vector(
    id: 'damage_combined_type_multiplier_variance',
    purpose:
        'Water/Grass target hit by Fire, 0.5 then 2. The engine combines both '
        'into one multiplier and truncates once, the declared variance from '
        'PSDK. PSDK would yield 10 here.',
    tags: <String>['move_method', 'damage'],
    sources: <String>[_basicSource, _damageCalcSource],
    move: _emberSpecial,
    attackerTypes: <String>['normal'],
    defenderTypes: <String>['water', 'grass'],
    defensiveStat: 35,
  ),
];

Future<void> main(List<String> args) async {
  final checkOnly = args.contains('--check');
  final directory = Directory('test/fixtures/psdk_golden');
  if (!directory.existsSync()) {
    stderr.writeln('Run this from packages/map_battle.');
    exitCode = 2;
    return;
  }

  final mismatches = <String>[];
  final drifted = <String>[];
  var written = 0;

  for (final vector in _vectors) {
    final replay = _replay(vector);
    final expected = vector.expectedDamage;
    if (replay.damage != expected) {
      mismatches.add(
        '${vector.id}: reference says $expected, engine says ${replay.damage}',
      );
      continue;
    }

    final json = _fixtureJson(vector, replay);
    final encoded = '${const JsonEncoder.withIndent('  ').convert(json)}\n';
    final file = File('${directory.path}/${vector.id}.json');
    if (checkOnly) {
      if (!file.existsSync() || file.readAsStringSync() != encoded) {
        drifted.add(vector.id);
      }
      continue;
    }
    file.writeAsStringSync(encoded);
    written += 1;
  }

  if (mismatches.isNotEmpty) {
    stderr.writeln(
      'PARITY GATE: the reference formula and the engine disagree. Nothing was '
      'written, because regenerating fixtures from the engine would silence '
      'the very question these vectors exist to ask.',
    );
    for (final mismatch in mismatches) {
      stderr.writeln('  $mismatch');
    }
    exitCode = 1;
    return;
  }

  if (checkOnly) {
    if (drifted.isEmpty) {
      stdout.writeln('${_vectors.length} fixtures match the reference.');
      return;
    }
    stderr.writeln('Committed fixtures drifted: ${drifted.join(', ')}');
    exitCode = 1;
    return;
  }

  stdout.writeln('Wrote $written damage fixtures with roll $_roll.');
  stdout.writeln(_indexRows());
}

final class _Replay {
  const _Replay({
    required this.damage,
    required this.eventKinds,
    required this.damageEvents,
    required this.playerHp,
    required this.opponentHp,
  });

  final int damage;
  final List<String> eventKinds;

  /// Tous les événements de dégâts du tour, résiduels de statut inclus.
  final List<PsdkBattleDamageEvent> damageEvents;
  final int playerHp;
  final int opponentHp;
}

_Replay _replay(_Vector vector) {
  final setup = PsdkBattleSetup.singlesPokeMapBetaV1ForTest(
    player: _combatant(vector, isAttacker: true),
    opponent: _combatant(vector, isAttacker: false),
    rngSeeds: _seeds,
    field: vector.weather == null
        ? const PsdkBattleFieldState()
        : PsdkBattleFieldState(
            weather: PsdkBattleWeatherState(
              id: vector.weather!,
              remainingTurns: 3,
            ),
          ),
  );
  final result = PsdkBattleEngine(setup: setup)
      .submit(const PsdkBattleDecision.fight(moveSlot: 0));
  final opponentHp = result.state.battlerAt(psdkOpponentSlot).currentHp;

  final moveDamage = result.timeline.events
      .whereType<PsdkBattleDamageEvent>()
      .where((event) => event.moveId == vector.move.id);

  return _Replay(
    damage: moveDamage.isEmpty ? 0 : moveDamage.first.damage,
    eventKinds: result.timeline.events
        .map((event) => event.kind)
        .toList(growable: false),
    damageEvents: result.timeline.events
        .whereType<PsdkBattleDamageEvent>()
        .toList(growable: false),
    playerHp: result.state.battlerAt(psdkPlayerSlot).currentHp,
    opponentHp: opponentHp,
  );
}

const int _maxHp = 400;

/// Reprise locale de `psdkGoldenGateTags`, que le paquet n'exporte pas.
const Set<String> _gateTags = <String>{
  'move_method',
  'effect_family',
  'ability',
  'item',
  'status',
  'field',
  'doubles',
  'runtime_bridge',
};

PsdkBattleCombatantSetup _combatant(_Vector vector, {required bool isAttacker}) {
  final types = isAttacker ? vector.attackerTypes : vector.defenderTypes;
  return PsdkBattleCombatantSetup(
    id: isAttacker ? 'attacker' : 'defender',
    speciesId: isAttacker ? 'attacker' : 'defender',
    displayName: isAttacker ? 'Attacker' : 'Defender',
    level: vector.level,
    maxHp: _maxHp,
    currentHp: _maxHp,
    types: PsdkBattleTypes(
      primary: types.first,
      secondary: types.length > 1 ? types[1] : null,
    ),
    stats: PsdkBattleStats(
      attack: isAttacker
          ? (vector.decoyPhysicalStat ?? vector.offensiveStat)
          : 50,
      defense: isAttacker
          ? 50
          : (vector.decoyPhysicalStat ?? vector.defensiveStat),
      specialAttack: isAttacker ? vector.offensiveStat : 50,
      specialDefense: isAttacker ? 50 : vector.defensiveStat,
      speed: isAttacker ? 100 : 1,
    ),
    majorStatus: isAttacker ? vector.attackerStatus : null,
    abilityId: isAttacker ? vector.attackerAbility : null,
    heldItemId: isAttacker ? vector.attackerHeldItem : null,
    moves: <PsdkBattleMoveData>[
      if (isAttacker)
        PsdkBattleMoveData(
          id: vector.move.id,
          dbSymbol: vector.move.id,
          name: vector.move.id,
          type: vector.move.type,
          category: vector.move.category,
          power: vector.move.power,
          accuracy: 100,
          pp: 35,
          priority: 0,
          criticalRate: vector.move.criticalRate,
          battleEngineMethod: 's_basic',
          target: PsdkBattleMoveTarget.adjacentFoe,
        )
      else
        PsdkBattleMoveData(
          id: 'hold_hands',
          dbSymbol: 'hold_hands',
          name: 'Hold Hands',
          type: 'normal',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 100,
          pp: 40,
          priority: 0,
          battleEngineMethod: 's_do_nothing',
          target: PsdkBattleMoveTarget.self,
        ),
    ],
  );
}

Map<String, Object?> _fixtureJson(_Vector vector, _Replay replay) {
  return <String, Object?>{
    'scenarioId': vector.id,
    'tags': vector.tags,
    'psdkSourcePaths': vector.sources,
    'sourcePsdkVersion': _psdkVersion,
    'initialBattle': <String, Object?>{
      'rngSeeds': <String, Object?>{
        'moveDamage': _seeds.moveDamage,
        'moveCritical': _seeds.moveCritical,
        'moveAccuracy': _seeds.moveAccuracy,
        'generic': _seeds.generic,
      },
      if (vector.weather != null)
        'field': <String, Object?>{
          'weather': <String, Object?>{
            'id': vector.weather!.name,
            'remainingTurns': 3,
          },
        },
      'player': _combatantJson(vector, isAttacker: true),
      'opponent': _combatantJson(vector, isAttacker: false),
    },
    'actions': <Object?>[
      <String, Object?>{'actor': 'player', 'kind': 'fight', 'moveSlot': 0},
    ],
    'expectedFinalState': <String, Object?>{
      'player': <String, Object?>{'currentHp': replay.playerHp},
      'opponent': <String, Object?>{'currentHp': replay.opponentHp},
    },
    'expectedTimeline': <String, Object?>{
      'eventKinds': replay.eventKinds,
      // L'oracle n'impose que l'événement de la capacité. Les résiduels de
      // statut appartiennent à BETA-BAT-004 et sont repris du rejeu ; comme
      // leur `remainingHp` découle des dégâts de la capacité, une erreur en
      // amont les ferait tomber aussi.
      'damageEvents': <Object?>[
        for (final event in replay.damageEvents)
          <String, Object?>{
            'moveId': event.moveId,
            'damage': event.moveId == vector.move.id
                ? vector.expectedDamage
                : event.damage,
            'remainingHp': event.remainingHp,
          },
      ],
    },
    'notes': <String>[
      vector.purpose,
      'Generated by tool/generate_psdk_damage_fixtures.dart for BETA-BAT-002. '
          'The expected damage comes from psdkReferenceDamage, transcribed from '
          'the PSDK Ruby formula, never from the Dart calculator. The generator '
          'refuses to write when the two disagree.',
      'Damage roll $_roll, from seed ${_seeds.moveDamage} through '
          '85 + (value % 16).',
    ],
  };
}

Map<String, Object?> _combatantJson(_Vector vector, {required bool isAttacker}) {
  final setup = _combatant(vector, isAttacker: isAttacker);
  return <String, Object?>{
    'id': setup.id,
    'speciesId': setup.speciesId,
    'displayName': setup.displayName,
    'level': setup.level,
    'maxHp': setup.maxHp,
    'currentHp': setup.currentHp,
    'types': <String, Object?>{
      'primary': setup.types.primary,
      if (setup.types.secondary != null) 'secondary': setup.types.secondary,
    },
    'stats': <String, Object?>{
      'attack': setup.stats.attack,
      'defense': setup.stats.defense,
      'specialAttack': setup.stats.specialAttack,
      'specialDefense': setup.stats.specialDefense,
      'speed': setup.stats.speed,
    },
    if (setup.majorStatus != null) 'majorStatus': setup.majorStatus!.name,
    if (setup.abilityId != null) 'ability': setup.abilityId,
    if (setup.heldItemId != null) 'heldItem': setup.heldItemId,
    'moves': <Object?>[
      for (final move in setup.moves)
        <String, Object?>{
          'id': move.id,
          'dbSymbol': move.dbSymbol,
          'name': move.name,
          'type': move.type,
          'category': move.category.name,
          'power': move.power,
          'accuracy': move.accuracy,
          'pp': move.pp,
          'priority': move.priority,
          if (move.criticalRate != 1) 'criticalRate': move.criticalRate,
          'battleEngineMethod': move.battleEngineMethod,
          'target': move.target.name,
        },
    ],
  };
}

String _indexRows() {
  final rows = <String>[];
  for (final vector in _vectors) {
    final gate = vector.tags.where(_gateTags.contains);
    final focus = vector.tags.where((tag) => !_gateTags.contains(tag));
    rows.add(
      '| `${vector.id}.json` '
      '| ${gate.map((tag) => '`$tag`').join(', ')} '
      '| ${focus.isEmpty ? '-' : focus.map((tag) => '`$tag`').join(', ')} '
      '| ${vector.sources.map((path) => '`$path`').join(', ')} '
      '| `strictAttacks: 0`, `portedMethods: 0`, `portedEffects: 0` '
      '| ${vector.purpose} |',
    );
  }
  return rows.join('\n');
}
