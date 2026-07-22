import 'package:map_core/map_core.dart';

/// Nature policy available to the MVP stat calculator.
///
/// Nature ids are persisted, but no canonical nature-to-stat catalogue is
/// available at this pure gameplay boundary yet. The calculator therefore
/// applies an explicit neutral multiplier instead of inventing a partial
/// lookup. A later lot may extend this enum together with a typed catalogue.
enum PokemonNatureStatPolicy { neutral }

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
  }) {
    final validatedBaseStats = baseStats.validated();
    RangeError.checkValueInInterval(level, 1, 100, 'level');
    _validateSpread(ivs, max: 31, name: 'ivs');
    _validateSpread(evs, max: 252, name: 'evs');

    // Exhaustive by design: no nature lookup is silently inferred.
    switch (naturePolicy) {
      case PokemonNatureStatPolicy.neutral:
        break;
    }

    return PokemonCalculatedStats(
      maxHp: _hp(
        base: validatedBaseStats.hp,
        iv: ivs.hp,
        ev: evs.hp,
        level: level,
      ),
      attack: _nonHp(
        base: validatedBaseStats.attack,
        iv: ivs.attack,
        ev: evs.attack,
        level: level,
      ),
      defense: _nonHp(
        base: validatedBaseStats.defense,
        iv: ivs.defense,
        ev: evs.defense,
        level: level,
      ),
      specialAttack: _nonHp(
        base: validatedBaseStats.specialAttack,
        iv: ivs.specialAttack,
        ev: evs.specialAttack,
        level: level,
      ),
      specialDefense: _nonHp(
        base: validatedBaseStats.specialDefense,
        iv: ivs.specialDefense,
        ev: evs.specialDefense,
        level: level,
      ),
      speed: _nonHp(
        base: validatedBaseStats.speed,
        iv: ivs.speed,
        ev: evs.speed,
        level: level,
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
