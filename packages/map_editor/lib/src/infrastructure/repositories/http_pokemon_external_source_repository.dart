import '../../application/ports/pokemon_external_source_repository.dart';
import '../external/pokeapi_live_source.dart';
import '../external/showdown_snapshot_source.dart';

/// Implémentation concrète du port externe déjà existant.
///
/// Cette classe est volontairement mince :
/// - elle compose l'adaptateur PokeAPI live et l'adaptateur Showdown snapshot ;
/// - elle ne convertit aucun payload ;
/// - elle expose au use case une façade unique pour éviter toute stack
///   d'import parallèle dans l'application.
class HttpPokemonExternalSourceRepository
    implements PokemonExternalSourceRepository {
  const HttpPokemonExternalSourceRepository({
    required this.pokeApiSource,
    required this.showdownSource,
  });

  final PokeApiLiveSource pokeApiSource;
  final ShowdownSnapshotSource showdownSource;

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
