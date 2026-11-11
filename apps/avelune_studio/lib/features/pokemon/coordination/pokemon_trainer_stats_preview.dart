import 'package:map_core/map_core_domain.dart';
import 'package:map_gameplay/map_gameplay.dart' as gameplay;

bool pokemonTrainerStatsAdvanced(ProjectTrainerPokemonEntry member) =>
    member.natureId != null || member.ivs != null || member.evs != null;

int? pokemonTrainerEvTotal(
  ProjectTrainerPokemonEntry member,
  Iterable<String> fieldErrorKeys,
  int index,
) {
  final invalidDraft = fieldErrorKeys.any(
    (key) => key.startsWith('team$index:evs:') && key != 'team$index:evs:total',
  );
  if (invalidDraft) return null;
  final evs = member.evs ?? standardTrainerPokemonEvs;
  return evs.toJson().values.cast<int>().fold<int>(0, (a, b) => a + b);
}

bool pokemonTrainerStatsPreviewValid(
  ProjectTrainerPokemonEntry member,
  Iterable<String> fieldErrorKeys,
  int index,
) =>
    !fieldErrorKeys.any((key) => key.startsWith('team$index:')) &&
    validateTrainerPokemonStats(member).isEmpty &&
    member.level >= 1 &&
    member.level <= 100;

gameplay.PokemonCalculatedStats? pokemonTrainerStatsPreview({
  required ProjectTrainerPokemonEntry member,
  required PokemonSpeciesFile? species,
  required bool valid,
}) {
  if (!valid || species == null || species.id != member.speciesId) return null;
  try {
    return gameplay.calculateTrainerPokemonStats(
      member: member,
      baseStats: gameplay.pokemonBaseStatsOf(species.baseStats),
    );
  } on ArgumentError {
    return null;
  }
}
