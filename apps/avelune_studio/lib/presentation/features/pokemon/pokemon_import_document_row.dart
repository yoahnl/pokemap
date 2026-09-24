import 'package:flutter/material.dart';

import '../../../features/pokemon/domain/pokemon_workspace_models.dart';
import 'pokemon_ui_parts.dart';

class PokemonImportDocumentRow extends StatelessWidget {
  const PokemonImportDocumentRow({
    super.key,
    required this.family,
    required this.relativePath,
    required this.conflict,
  });

  final PokemonDocumentFamily family;
  final String relativePath;
  final bool conflict;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: PokemonSurface(
        padding: EdgeInsets.zero,
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          leading: Icon(_icon(family), color: colors.primary),
          title: Text(pokemonDocumentFamilyLabel(family)),
          subtitle: Text(
            conflict
                ? 'Ce document existe déjà · décision requise'
                : 'Nouveau document',
          ),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          children: [
            SelectableText(
              relativePath,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

String pokemonDocumentFamilyLabel(PokemonDocumentFamily family) =>
    switch (family) {
      PokemonDocumentFamily.species => 'Espèce',
      PokemonDocumentFamily.learnset => 'Apprentissages',
      PokemonDocumentFamily.evolution => 'Évolution',
      PokemonDocumentFamily.media => 'Références média',
    };

IconData _icon(PokemonDocumentFamily family) => switch (family) {
  PokemonDocumentFamily.species => Icons.pets_outlined,
  PokemonDocumentFamily.learnset => Icons.menu_book_outlined,
  PokemonDocumentFamily.evolution => Icons.account_tree_outlined,
  PokemonDocumentFamily.media => Icons.image_outlined,
};
