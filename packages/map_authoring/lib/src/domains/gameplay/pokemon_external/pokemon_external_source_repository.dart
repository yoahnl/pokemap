import 'dart:typed_data';

abstract class PokemonExternalSourceRepository {
  Future<Map<String, dynamic>> fetchShowdownPokedexSnapshot();

  Future<Map<String, dynamic>> fetchShowdownSpeciesPayload(String speciesId);

  Future<Map<String, dynamic>> fetchShowdownMovesSnapshot();

  Future<Map<String, dynamic>> fetchPokeApiItemsResourceList({
    required int limit,
    required int offset,
  });

  Future<Map<String, dynamic>> fetchPokeApiItemPayload(String itemIdOrName);

  Future<Map<String, dynamic>> fetchPokeApiPokemonPayload(String speciesId);

  Future<Map<String, dynamic>> fetchPokeApiPokemonSpeciesPayload(
    String speciesId,
  );

  Future<Map<String, dynamic>> fetchPokeApiEvolutionChainPayload(
    String speciesId,
  );

  Future<PokemonExternalBinaryAsset> fetchBinaryAsset(String sourceUrl);
}

class PokemonExternalBinaryAsset {
  const PokemonExternalBinaryAsset({
    required this.sourceUrl,
    required this.bytes,
    this.contentType,
  });

  final String sourceUrl;
  final Uint8List bytes;
  final String? contentType;
}
