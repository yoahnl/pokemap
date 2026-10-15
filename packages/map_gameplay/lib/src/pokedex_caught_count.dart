import 'package:map_core/map_core.dart';

final class PokedexCaughtCountUnavailable implements Exception {
  PokedexCaughtCountUnavailable(Iterable<String> speciesIds)
      : speciesIds = List.unmodifiable(speciesIds);
  final List<String> speciesIds;
}

int countPokedexCaughtSpecies(
    {required GameState gameState,
    required PokemonSpeciesIndex speciesIndex,
    required PokedexSpeciesRange range}) {
  final numbers = <int>{};
  final unresolved = <String>{};
  for (final id in gameState.progression.caughtSpeciesIds.toSet()) {
    final species = speciesIndex.byId(id);
    if (species == null || species.nationalDex <= 0) {
      unresolved.add(id);
      continue;
    }
    if (range.contains(species.nationalDex)) numbers.add(species.nationalDex);
  }
  if (unresolved.isNotEmpty) {
    throw PokedexCaughtCountUnavailable(unresolved.toList()..sort());
  }
  return numbers.length;
}

bool evaluateScenePokedexCaughtCondition(
    {required SceneConditionSource source,
    required GameState gameState,
    required PokemonSpeciesIndex speciesIndex}) {
  final range = source.pokedexSpeciesRange;
  final minimum = source.pokedexMinimumCaughtCount;
  if (range == null || minimum == null) {
    throw ArgumentError.value(
        source, 'source', 'Invalid caught species condition.');
  }
  final enough = countPokedexCaughtSpecies(
          gameState: gameState, speciesIndex: speciesIndex, range: range) >=
      minimum;
  return source.operator == SceneConditionOperator.isTrue ? enough : !enough;
}
