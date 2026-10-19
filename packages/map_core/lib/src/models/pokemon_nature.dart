enum PokemonNatureStat {
  attack,
  defense,
  specialAttack,
  specialDefense,
  speed,
}

final class PokemonNatureEffect {
  const PokemonNatureEffect({
    required this.id,
    this.increasedStat,
    this.decreasedStat,
  });

  final String id;
  final PokemonNatureStat? increasedStat;
  final PokemonNatureStat? decreasedStat;
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
