import 'package:map_core/map_core_domain.dart';

const pokemonStatLabels = {
  'hp': 'PV',
  'attack': 'Attaque',
  'defense': 'Défense',
  'specialAttack': 'Attaque Spé.',
  'specialDefense': 'Défense Spé.',
  'speed': 'Vitesse',
};

String pokemonNatureLabel(String id) {
  final effect = canonicalPokemonNatureEffect(id);
  final name = '${id[0].toUpperCase()}${id.substring(1)}';
  if (effect.increasedStat == null) return '$name — neutre';
  return '$name — ${pokemonStatLabels[effect.increasedStat!.name]} +10%, ${pokemonStatLabels[effect.decreasedStat!.name]} −10%';
}
