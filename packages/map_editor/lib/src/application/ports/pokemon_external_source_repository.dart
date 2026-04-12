import 'dart:typed_data';

/// Frontière applicative unique pour lire les données Pokémon externes.
///
/// Cette abstraction reste volontairement concentrée sur le pipeline déjà en
/// place dans l'application :
/// - Showdown reste la source structurée complémentaire pour le core species ;
/// - PokeAPI reste la source live principale pour `pokemon`, `pokemon-species`
///   et `evolution-chain` ;
/// - les médias et cries sont aussi lus via cette même frontière pour éviter
///   de créer un second sous-système réseau à côté de l'import existant.
///
/// Important :
/// - on étend minimalement le port historique au lieu d'en créer un nouveau ;
/// - le use case garde ainsi une seule dépendance externe injectable ;
/// - l'UI ne voit jamais de client HTTP concret ni d'URL brutes.
abstract class PokemonExternalSourceRepository {
  Future<Map<String, dynamic>> fetchShowdownSpeciesPayload(String speciesId);

  Future<Map<String, dynamic>> fetchPokeApiPokemonPayload(String speciesId);

  Future<Map<String, dynamic>> fetchPokeApiPokemonSpeciesPayload(
    String speciesId,
  );

  Future<Map<String, dynamic>> fetchPokeApiEvolutionChainPayload(
    String speciesId,
  );

  Future<PokemonExternalBinaryAsset> fetchBinaryAsset(String sourceUrl);
}

/// Payload binaire téléchargé depuis une source externe.
///
/// On garde ici juste le strict nécessaire pour réécrire l'asset localement :
/// - l'URL source réellement utilisée ;
/// - les bytes ;
/// - le content-type quand la réponse HTTP en expose un.
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
