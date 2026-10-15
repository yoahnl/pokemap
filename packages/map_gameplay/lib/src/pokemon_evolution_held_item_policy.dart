import 'package:map_core/map_core.dart';

import 'items/item_catalog_snapshot.dart';

final class PokemonEvolutionHeldItemPolicy {
  PokemonEvolutionHeldItemPolicy._(
      this.knownIds, this.preventingIds, this.unsupportedIds);
  factory PokemonEvolutionHeldItemPolicy.fromCatalog(
      ItemCatalogSnapshot catalog,
      {Set<String>? supportedHeldEffectIds}) {
    final known = <String>{}, preventing = <String>{}, unsupported = <String>{};
    for (final item in catalog.definitions) {
      known.add(item.id);
      final effect = item.heldEffectId;
      if (PokemonPassiveHeldEffect.fromId(effect) ==
          PokemonPassiveHeldEffect.preventEvolution) {
        preventing.add(item.id);
      } else if (effect != null &&
          !(supportedHeldEffectIds ??
                  itemSystemV1CapabilityTruth.supportedHeldEffectIds)
              .contains(effect)) {
        unsupported.add(item.id);
      }
    }
    return PokemonEvolutionHeldItemPolicy._(Set.unmodifiable(known),
        Set.unmodifiable(preventing), Set.unmodifiable(unsupported));
  }
  final Set<String> knownIds, preventingIds, unsupportedIds;
  bool recognizes(String? itemId) =>
      itemId == null ||
      itemId.isEmpty ||
      (knownIds.contains(itemId) && !unsupportedIds.contains(itemId));
  bool preventsEvolution(String? itemId) =>
      itemId != null && preventingIds.contains(itemId);
}
