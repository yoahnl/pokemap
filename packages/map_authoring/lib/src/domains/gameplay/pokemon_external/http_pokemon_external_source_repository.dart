import 'pokemon_external_source_repository.dart';
import 'pokeapi_live_source.dart';
import 'showdown_snapshot_source.dart';

class HttpPokemonExternalSourceRepository
    implements PokemonExternalSourceRepository {
  const HttpPokemonExternalSourceRepository({
    required this.pokeApiSource,
    required this.showdownSource,
  });

  final PokeApiLiveSource pokeApiSource;
  final ShowdownSnapshotSource showdownSource;

  @override
  Future<Map<String, dynamic>> fetchShowdownPokedexSnapshot() {
    return showdownSource.fetchPokedexSnapshot();
  }

  @override
  Future<Map<String, dynamic>> fetchShowdownSpeciesPayload(
    String speciesId,
  ) {
    return showdownSource.fetchSpecies(speciesId);
  }

  @override
  Future<Map<String, dynamic>> fetchShowdownMovesSnapshot() {
    return showdownSource.fetchMovesSnapshot();
  }

  @override
  Future<Map<String, dynamic>> fetchPokeApiItemsResourceList({
    required int limit,
    required int offset,
  }) {
    return pokeApiSource.fetchItemsResourceList(
      limit: limit,
      offset: offset,
    );
  }

  @override
  Future<Map<String, dynamic>> fetchPokeApiItemPayload(
    String itemIdOrName,
  ) {
    return pokeApiSource.fetchItem(itemIdOrName);
  }

  @override
  Future<Map<String, dynamic>> fetchPokeApiPokemonPayload(
    String speciesId,
  ) {
    return pokeApiSource.fetchPokemon(speciesId);
  }

  @override
  Future<Map<String, dynamic>> fetchPokeApiPokemonSpeciesPayload(
    String speciesId,
  ) {
    return pokeApiSource.fetchPokemonSpecies(speciesId);
  }

  @override
  Future<Map<String, dynamic>> fetchPokeApiEvolutionChainPayload(
    String speciesId,
  ) {
    return pokeApiSource.fetchEvolutionChainForSpecies(speciesId);
  }

  @override
  Future<PokemonExternalBinaryAsset> fetchBinaryAsset(String sourceUrl) {
    return pokeApiSource.fetchBinaryAsset(sourceUrl);
  }
}
