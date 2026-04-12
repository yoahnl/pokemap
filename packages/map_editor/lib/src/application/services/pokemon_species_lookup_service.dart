import '../models/pokemon_database_index.dart';
import 'local_catalog_lookup_service.dart';

/// Recherche locale ciblée sur les espèces déjà présentes dans le projet.
///
/// Ce service reste volontairement très petit :
/// - il ne relit rien depuis le disque ;
/// - il ne crée aucun index parallèle ;
/// - il s'appuie uniquement sur la projection légère déjà utilisée ailleurs
///   dans le Pokédex local.
///
/// Le lot 7 l'utilise pour assister la saisie d'espèce dans la surface
/// dresseurs sans réinventer un deuxième pipeline Pokédex.
class PokemonSpeciesLookupService
    extends ProgressiveLocalCatalogLookupService<PokemonDatabaseIndexEntry> {
  const PokemonSpeciesLookupService()
      : super(
          idOf: _speciesEntryId,
          labelOf: _speciesEntryLabel,
          searchTermsOf: _speciesEntrySearchTerms,
        );
}

String _speciesEntryId(PokemonDatabaseIndexEntry entry) => entry.id;

String _speciesEntryLabel(PokemonDatabaseIndexEntry entry) => entry.primaryName;

Iterable<String> _speciesEntrySearchTerms(PokemonDatabaseIndexEntry entry) {
  final dex = entry.nationalDex <= 0 ? '' : entry.nationalDex.toString();
  final dexPadded = entry.nationalDex <= 0
      ? ''
      : entry.nationalDex.toString().padLeft(4, '0');
  return <String>[
    entry.id,
    entry.primaryName,
    dex,
    dexPadded,
    '#$dexPadded',
    ...entry.types,
  ];
}
