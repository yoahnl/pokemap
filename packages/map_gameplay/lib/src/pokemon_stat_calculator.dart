import 'package:map_core/map_core.dart';

export 'package:map_core/map_core.dart'
    show
        PokemonNatureStat,
        PokemonNatureEffect,
        canonicalPokemonNatureIds,
        canonicalPokemonNatureEffect;

/// Nature policy selected by each stat consumer.
///
/// [neutral] remains available for deliberately nature-agnostic projections.
/// Battle/runtime fidelity must opt into [canonical] and provide the persisted
/// nature id, so an unknown value fails closed instead of becoming neutral.
enum PokemonNatureStatPolicy { neutral, canonical }

extension PokemonNatureStatModifier on PokemonNatureEffect {
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

enum PokemonOpponentStatProfile {
  wildV0(
    profileId: 'pokemap-wild-zero-v0',
    natureId: 'hardy',
    ivs: PokemonStatSpread(),
    evs: PokemonStatSpread(),
  ),
  trainerV0(
    profileId: 'pokemap-trainer-balanced-v0',
    natureId: standardTrainerPokemonNatureId,
    ivs: standardTrainerPokemonIvs,
    evs: standardTrainerPokemonEvs,
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

PokemonCalculatedStats calculateTrainerPokemonStats({
  required ProjectTrainerPokemonEntry member,
  required PokemonBaseStats baseStats,
}) {
  final configuration = resolveTrainerPokemonStats(member);
  return const PokemonStatCalculator().calculate(
    baseStats: baseStats,
    ivs: configuration.ivs,
    evs: configuration.evs,
    level: member.level,
    naturePolicy: PokemonNatureStatPolicy.canonical,
    natureId: configuration.natureId,
  );
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
