import 'package:flutter/material.dart';

import '../../../features/pokemon/application/pokemon_workspace_controller.dart';
import '../../../features/pokemon/domain/pokemon_workspace_models.dart';

class PokemonWorkspaceTabs extends StatelessWidget {
  const PokemonWorkspaceTabs({super.key, required this.controller});

  final PokemonWorkspaceController controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (view, label) in const [
          (PokemonWorkspaceView.pokedex, 'Pokédex'),
          (PokemonWorkspaceView.moves, 'Attaques'),
          (PokemonWorkspaceView.items, 'Objets'),
          (PokemonWorkspaceView.shops, 'Boutiques'),
        ])
          Padding(
            padding: const EdgeInsets.only(right: 7),
            child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor: controller.view == view
                    ? colors.primaryContainer
                    : colors.surfaceContainer,
                foregroundColor: colors.onSurface,
              ),
              onPressed: () => controller.setView(view),
              child: Text(label),
            ),
          ),
      ],
    );
  }
}
