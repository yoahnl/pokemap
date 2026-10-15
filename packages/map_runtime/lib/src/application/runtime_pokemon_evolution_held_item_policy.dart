import 'package:map_gameplay/map_gameplay.dart';

import 'runtime_battle_combatant_seed_builder.dart';

PokemonEvolutionHeldItemPolicy resolveRuntimeEvolutionHeldItemPolicy(
  ItemCatalogSnapshot catalog,
) => PokemonEvolutionHeldItemPolicy.fromCatalog(
  catalog,
  supportedHeldEffectIds: {
    for (final item in catalog.definitions)
      if (item.heldEffectId != null &&
          resolveRuntimeHeldItemEffect(
            itemCatalog: catalog,
            itemId: item.id,
          ).isRuntimeSupported)
        item.heldEffectId!,
  },
);
