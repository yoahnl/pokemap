import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/editor/state/editor_selectors.dart';
import '../../features/editor/state/editor_state.dart';
import 'pokedex_workspace.dart';
import 'pokemon_catalogs_workspace/items_catalog_workspace.dart';
import 'pokemon_catalogs_workspace/moves_catalog_workspace.dart';

class PokemonCatalogsWorkspace extends ConsumerWidget {
  const PokemonCatalogsWorkspace({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final section = ref.watch(editorPokemonCatalogSectionProvider);

    return switch (section) {
      PokemonCatalogSection.pokedex => const Padding(
          padding: EdgeInsets.fromLTRB(4, 4, 4, 0),
          child: PokedexWorkspace(),
        ),
      PokemonCatalogSection.moves => const PokemonMovesCatalogWorkspace(),
      PokemonCatalogSection.items => const PokemonItemsCatalogWorkspace(),
    };
  }
}
