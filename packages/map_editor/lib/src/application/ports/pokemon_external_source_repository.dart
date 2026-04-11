/// Frontière applicative minimale pour lire les payloads Pokémon externes.
///
/// Cette abstraction reste volontairement petite pour les lots 34 à 36 :
/// - une espèce Showdown pour le core species ;
/// - un payload PokeAPI `/pokemon/{id}` pour le learnset ;
/// - une chaîne d'évolution PokeAPI pour les évolutions.
///
/// Non-objectifs explicites :
/// - pas de client HTTP concret ici ;
/// - pas de logique de retry ;
/// - pas de cache ;
/// - pas de batch API ;
/// - pas de détails réseau dans les use cases.
///
/// Les tests utilisent des fakes de ce port. Le lot ne dépend donc d'aucun
/// réseau réel pour rester rapide, stable et reviewable.
abstract class PokemonExternalSourceRepository {
  Future<Map<String, dynamic>> fetchShowdownSpeciesPayload(String speciesId);

  Future<Map<String, dynamic>> fetchPokeApiPokemonPayload(String speciesId);

  Future<Map<String, dynamic>> fetchPokeApiEvolutionChainPayload(
    String speciesId,
  );
}
