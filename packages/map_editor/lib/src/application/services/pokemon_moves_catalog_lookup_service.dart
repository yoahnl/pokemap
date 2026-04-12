import 'local_catalog_lookup_service.dart';
import '../use_cases/sync_pokemon_moves_catalog_use_case.dart';

/// Recherche locale ciblée sur le catalogue `moves` déjà synchronisé.
///
/// Le lot 5 l'avait introduit comme helper local `moves-first`. Le lot 6 le
/// fait désormais converger vers le contrat progressif commun de recherche
/// catalogue locale, sans changer son rôle produit :
/// - il reste branché exclusivement sur le catalogue `moves` existant ;
/// - il ne recharge rien depuis le disque ;
/// - il ne crée toujours aucune stack parallèle.
///
/// Le lot 5 en a besoin pour deux usages strictement locaux :
/// - retrouver rapidement un move connu par `id` exact ;
/// - filtrer des suggestions lisibles à partir du catalogue moves existant.
class PokemonMovesCatalogLookupService
    extends ProgressiveLocalCatalogLookupService<PokemonMoveCatalogEntryView> {
  const PokemonMovesCatalogLookupService()
      : super(
          idOf: _moveCatalogEntryId,
          labelOf: _moveCatalogEntryLabel,
          searchTermsOf: _moveCatalogEntrySearchTerms,
        );
}

String _moveCatalogEntryId(PokemonMoveCatalogEntryView entry) => entry.id;

String _moveCatalogEntryLabel(PokemonMoveCatalogEntryView entry) => entry.name;

Iterable<String> _moveCatalogEntrySearchTerms(
  PokemonMoveCatalogEntryView entry,
) {
  return <String>[
    entry.id,
    entry.name,
    entry.type ?? '',
    entry.category ?? '',
    entry.shortDesc ?? '',
  ];
}
