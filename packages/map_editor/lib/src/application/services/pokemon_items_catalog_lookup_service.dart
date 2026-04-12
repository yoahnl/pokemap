import '../use_cases/load_pokemon_items_catalog_use_case.dart';
import 'local_catalog_lookup_service.dart';

/// Recherche locale ciblée sur le catalogue `items` quand il est disponible.
///
/// Ce service ne fait qu'appliquer le socle du lot 6 à une projection locale
/// très simple des objets :
/// - id ;
/// - libellé lisible ;
/// - quelques termes de recherche utiles.
///
/// Il n'introduit donc ni nouveau store, ni nouveau loader, ni logique de
/// fusion parallèle.
class PokemonItemsCatalogLookupService
    extends ProgressiveLocalCatalogLookupService<PokemonItemCatalogEntryView> {
  const PokemonItemsCatalogLookupService()
      : super(
          idOf: _itemEntryId,
          labelOf: _itemEntryLabel,
          searchTermsOf: _itemEntrySearchTerms,
        );
}

String _itemEntryId(PokemonItemCatalogEntryView entry) => entry.id;

String _itemEntryLabel(PokemonItemCatalogEntryView entry) => entry.name;

Iterable<String> _itemEntrySearchTerms(PokemonItemCatalogEntryView entry) {
  return <String>[
    entry.id,
    entry.name,
    entry.shortDesc ?? '',
    ...entry.aliases,
  ];
}
