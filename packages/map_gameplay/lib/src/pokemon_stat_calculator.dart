import 'package:map_core/map_core.dart';

/// Nature policy selected by each stat consumer.
///
/// [neutral] remains available for deliberately nature-agnostic projections.
/// Battle/runtime fidelity must opt into [canonical] and provide the persisted
/// nature id, so an unknown value fails closed instead of becoming neutral.
enum PokemonNatureStatPolicy { neutral, canonical }

enum PokemonNatureStat {
  attack,
  defense,
  specialAttack,
  specialDefense,
  speed,
}

/// Canonical mainline-style 110/90 nature modifiers.
///
/// Detailed project authoring remains outside RM-028 (`FG-206`), but the pure
/// gameplay rule must still understand every persisted canonical nature.
final class PokemonNatureEffect {
  const PokemonNatureEffect({
    required this.id,
    this.increasedStat,
    this.decreasedStat,
  });

  final String id;
  final PokemonNatureStat? increasedStat;
  final PokemonNatureStat? decreasedStat;

  int apply(int value, PokemonNatureStat stat) {
    if (increasedStat == stat) {
      return (value * 110) ~/ 100;
    }
    if (decreasedStat == stat) {
      return (value * 90) ~/ 100;
    }
    return value;
  }
}

const canonicalPokemonNatureIds = <String>[
  'hardy',
  'lonely',
  'brave',
  'adamant',
  'naughty',
  'bold',
  'docile',
  'relaxed',
  'impish',
  'lax',
  'timid',
  'hasty',
  'serious',
  'jolly',
  'naive',
  'modest',
  'mild',
  'quiet',
  'bashful',
  'rash',
  'calm',
  'gentle',
  'sassy',
  'careful',
  'quirky',
];

const _canonicalPokemonNatureEffects = <String, PokemonNatureEffect>{
  'hardy': PokemonNatureEffect(id: 'hardy'),
  'lonely': PokemonNatureEffect(
    id: 'lonely',
    increasedStat: PokemonNatureStat.attack,
    decreasedStat: PokemonNatureStat.defense,
  ),
  'brave': PokemonNatureEffect(
    id: 'brave',
    increasedStat: PokemonNatureStat.attack,
    decreasedStat: PokemonNatureStat.speed,
  ),
  'adamant': PokemonNatureEffect(
    id: 'adamant',
    increasedStat: PokemonNatureStat.attack,
    decreasedStat: PokemonNatureStat.specialAttack,
  ),
  'naughty': PokemonNatureEffect(
    id: 'naughty',
    increasedStat: PokemonNatureStat.attack,
    decreasedStat: PokemonNatureStat.specialDefense,
  ),
  'bold': PokemonNatureEffect(
    id: 'bold',
    increasedStat: PokemonNatureStat.defense,
    decreasedStat: PokemonNatureStat.attack,
  ),
  'docile': PokemonNatureEffect(id: 'docile'),
  'relaxed': PokemonNatureEffect(
    id: 'relaxed',
    increasedStat: PokemonNatureStat.defense,
    decreasedStat: PokemonNatureStat.speed,
  ),
  'impish': PokemonNatureEffect(
    id: 'impish',
    increasedStat: PokemonNatureStat.defense,
    decreasedStat: PokemonNatureStat.specialAttack,
  ),
  'lax': PokemonNatureEffect(
    id: 'lax',
    increasedStat: PokemonNatureStat.defense,
    decreasedStat: PokemonNatureStat.specialDefense,
  ),
  'timid': PokemonNatureEffect(
    id: 'timid',
    increasedStat: PokemonNatureStat.speed,
    decreasedStat: PokemonNatureStat.attack,
  ),
  'hasty': PokemonNatureEffect(
    id: 'hasty',
    increasedStat: PokemonNatureStat.speed,
    decreasedStat: PokemonNatureStat.defense,
  ),
  'serious': PokemonNatureEffect(id: 'serious'),
  'jolly': PokemonNatureEffect(
    id: 'jolly',
    increasedStat: PokemonNatureStat.speed,
    decreasedStat: PokemonNatureStat.specialAttack,
  ),
  'naive': PokemonNatureEffect(
    id: 'naive',
    increasedStat: PokemonNatureStat.speed,
    decreasedStat: PokemonNatureStat.specialDefense,
  ),
  'modest': PokemonNatureEffect(
    id: 'modest',
    increasedStat: PokemonNatureStat.specialAttack,
    decreasedStat: PokemonNatureStat.attack,
  ),
  'mild': PokemonNatureEffect(
    id: 'mild',
    increasedStat: PokemonNatureStat.specialAttack,
    decreasedStat: PokemonNatureStat.defense,
  ),
  'quiet': PokemonNatureEffect(
    id: 'quiet',
    increasedStat: PokemonNatureStat.specialAttack,
    decreasedStat: PokemonNatureStat.speed,
  ),
  'bashful': PokemonNatureEffect(id: 'bashful'),
  'rash': PokemonNatureEffect(
    id: 'rash',
    increasedStat: PokemonNatureStat.specialAttack,
    decreasedStat: PokemonNatureStat.specialDefense,
  ),
  'calm': PokemonNatureEffect(
    id: 'calm',
    increasedStat: PokemonNatureStat.specialDefense,
    decreasedStat: PokemonNatureStat.attack,
  ),
  'gentle': PokemonNatureEffect(
    id: 'gentle',
    increasedStat: PokemonNatureStat.specialDefense,
    decreasedStat: PokemonNatureStat.defense,
  ),
  'sassy': PokemonNatureEffect(
    id: 'sassy',
    increasedStat: PokemonNatureStat.specialDefense,
    decreasedStat: PokemonNatureStat.speed,
  ),
  'careful': PokemonNatureEffect(
    id: 'careful',
    increasedStat: PokemonNatureStat.specialDefense,
    decreasedStat: PokemonNatureStat.specialAttack,
  ),
  'quirky': PokemonNatureEffect(id: 'quirky'),
};

PokemonNatureEffect canonicalPokemonNatureEffect(String natureId) {
  final normalizedId = natureId.trim().toLowerCase();
  final effect = _canonicalPokemonNatureEffects[normalizedId];
  if (effect == null) {
    throw ArgumentError.value(
      natureId,
      'natureId',
      'Unsupported canonical Pokemon nature.',
    );
  }
  return effect;
}

/// Deterministic opponent values until advanced stat authoring exists.
///
/// The trainer profile deliberately uses middle IVs rather than coupling
/// battle stats to `battleDifficulty`, whose contract only controls AI.
enum PokemonOpponentStatProfile {
  wildV0(
    profileId: 'pokemap-wild-zero-v0',
    natureId: 'hardy',
    ivs: PokemonStatSpread(),
    evs: PokemonStatSpread(),
  ),
  trainerV0(
    profileId: 'pokemap-trainer-balanced-v0',
    natureId: 'hardy',
    ivs: PokemonStatSpread(
      hp: 15,
      attack: 15,
      defense: 15,
      specialAttack: 15,
      specialDefense: 15,
      speed: 15,
    ),
    evs: PokemonStatSpread(),
  );

  const PokemonOpponentStatProfile({
    required this.profileId,
    required this.natureId,
    required this.ivs,
    required this.evs,
  });

  final String profileId;
  final String natureId;
  final PokemonStatSpread ivs;
  final PokemonStatSpread evs;
}

/// Typed base-stat row loaded from one Pokemon species record.
final class PokemonBaseStats {
  const PokemonBaseStats({
    required this.hp,
    required this.attack,
    required this.defense,
    required this.specialAttack,
    required this.specialDefense,
    required this.speed,
  });

  final int hp;
  final int attack;
  final int defense;
  final int specialAttack;
  final int specialDefense;
  final int speed;

  PokemonBaseStats validated() {
    for (final entry in <String, int>{
      'hp': hp,
      'attack': attack,
      'defense': defense,
      'specialAttack': specialAttack,
      'specialDefense': specialDefense,
      'speed': speed,
    }.entries) {
      RangeError.checkValueInInterval(entry.value, 1, 255, entry.key);
    }
    return this;
  }
}

/// Fully resolved level stats. Only [maxHp] is currently persisted indirectly
/// through current HP; the remaining values are exposed for battle/runtime
/// consumers without adding speculative save fields.
final class PokemonCalculatedStats {
  const PokemonCalculatedStats({
    required this.maxHp,
    required this.attack,
    required this.defense,
    required this.specialAttack,
    required this.specialDefense,
    required this.speed,
  });

  final int maxHp;
  final int attack;
  final int defense;
  final int specialAttack;
  final int specialDefense;
  final int speed;
}

/// Pure Pokemon-like stat formula shared by battle progression.
final class PokemonStatCalculator {
  const PokemonStatCalculator();

  PokemonCalculatedStats calculate({
    required PokemonBaseStats baseStats,
    required PokemonStatSpread ivs,
    required PokemonStatSpread evs,
    required int level,
    PokemonNatureStatPolicy naturePolicy = PokemonNatureStatPolicy.neutral,
    String? natureId,
  }) {
    final validatedBaseStats = baseStats.validated();
    RangeError.checkValueInInterval(level, 1, 100, 'level');
    _validateSpread(ivs, max: 31, name: 'ivs');
    _validateSpread(evs, max: 252, name: 'evs');

    final nature = switch (naturePolicy) {
      PokemonNatureStatPolicy.neutral =>
        const PokemonNatureEffect(id: 'neutral-policy'),
      PokemonNatureStatPolicy.canonical => canonicalPokemonNatureEffect(
          natureId ??
              (throw ArgumentError.notNull(
                'natureId',
              )),
        ),
    };

    return PokemonCalculatedStats(
      maxHp: _hp(
        base: validatedBaseStats.hp,
        iv: ivs.hp,
        ev: evs.hp,
        level: level,
      ),
      attack: nature.apply(
        _nonHp(
          base: validatedBaseStats.attack,
          iv: ivs.attack,
          ev: evs.attack,
          level: level,
        ),
        PokemonNatureStat.attack,
      ),
      defense: nature.apply(
        _nonHp(
          base: validatedBaseStats.defense,
          iv: ivs.defense,
          ev: evs.defense,
          level: level,
        ),
        PokemonNatureStat.defense,
      ),
      specialAttack: nature.apply(
        _nonHp(
          base: validatedBaseStats.specialAttack,
          iv: ivs.specialAttack,
          ev: evs.specialAttack,
          level: level,
        ),
        PokemonNatureStat.specialAttack,
      ),
      specialDefense: nature.apply(
        _nonHp(
          base: validatedBaseStats.specialDefense,
          iv: ivs.specialDefense,
          ev: evs.specialDefense,
          level: level,
        ),
        PokemonNatureStat.specialDefense,
      ),
      speed: nature.apply(
        _nonHp(
          base: validatedBaseStats.speed,
          iv: ivs.speed,
          ev: evs.speed,
          level: level,
        ),
        PokemonNatureStat.speed,
      ),
    );
  }
}

void _validateSpread(
  PokemonStatSpread spread, {
  required int max,
  required String name,
}) {
  for (final entry in <String, int>{
    'hp': spread.hp,
    'attack': spread.attack,
    'defense': spread.defense,
    'specialAttack': spread.specialAttack,
    'specialDefense': spread.specialDefense,
    'speed': spread.speed,
  }.entries) {
    RangeError.checkValueInInterval(
      entry.value,
      0,
      max,
      '$name.${entry.key}',
    );
  }
}

int _hp({
  required int base,
  required int iv,
  required int ev,
  required int level,
}) {
  return (((2 * base + iv + (ev ~/ 4)) * level) ~/ 100) + level + 10;
}

int _nonHp({
  required int base,
  required int iv,
  required int ev,
  required int level,
}) {
  return (((2 * base + iv + (ev ~/ 4)) * level) ~/ 100) + 5;
}
