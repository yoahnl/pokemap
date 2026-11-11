import 'package:flutter/material.dart';

import '../../../features/pokemon/application/pokemon_workspace_controller.dart';
import '../../../features/pokemon/domain/pokemon_workspace_models.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/layout/studio_panel.dart';

class PokemonMoveRecipePanel extends StatelessWidget {
  const PokemonMoveRecipePanel({
    super.key,
    required this.controller,
    required this.move,
  });

  final PokemonWorkspaceController controller;
  final PokemonMoveSummary move;

  @override
  Widget build(BuildContext context) {
    if (!controller.recipePanelAvailableFor(move)) {
      return const SizedBox.shrink();
    }
    final choices = controller.recipeChoices;
    return StudioPanel(
      title: 'Animation de combat',
      children: [
        const Text(
          'Recherchez les animations disponibles pour cette attaque. '
          'Les animations compatibles sont incluses dans les jeux exportés.',
        ),
        if (controller.hasPendingChanges)
          const Text(
            'Enregistrez ou annulez les modifications en cours avant l’import.',
          ),
        const SizedBox(height: 10),
        if (!controller.recipeReady)
          StudioButton(
            label: 'Préparer les animations',
            icon: Icons.refresh,
            secondary: true,
            loading: controller.recipePreparing,
            onPressed: controller.recipePreparing
                ? null
                : controller.prepareMoveRecipes,
          )
        else
          StudioButton(
            label: choices == null
                ? 'Rechercher des animations'
                : 'Actualiser les animations',
            icon: Icons.search,
            secondary: true,
            loading: controller.recipeBusy,
            onPressed:
                controller.operationActive || controller.hasPendingChanges
                ? null
                : controller.findMoveRecipes,
          ),
        if (controller.recipeError case final error?) ...[
          const SizedBox(height: 10),
          Text(error),
        ],
        if (controller.recipeNotice case final notice?) ...[
          const SizedBox(height: 10),
          Text(notice),
        ],
        if (choices != null && choices.isEmpty) ...[
          const SizedBox(height: 10),
          const Text('Aucune animation disponible pour cette attaque.'),
        ],
        if (choices != null)
          for (final choice in choices) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  '${_styleLabel(choice.style)} · ${_variantLabel(choice.variant)} · v${choice.revision}',
                ),
                StudioButton(
                  label: 'Ajouter au projet',
                  onPressed:
                      controller.operationActive || controller.hasPendingChanges
                      ? null
                      : () => controller.importMoveRecipe(choice),
                ),
              ],
            ),
          ],
      ],
    );
  }
}

String _styleLabel(String style) => switch (style) {
  'gen5-bw2' => 'Noir et Blanc 2',
  'gen5-pilot' => 'Noir et Blanc · pilote',
  'gen5' => 'Noir et Blanc',
  'gen4' => 'Quatrième génération',
  'gen3' => 'Troisième génération',
  _ => 'Animation du catalogue',
};

String _variantLabel(String variant) =>
    variant == 'default' ? 'Version par défaut' : variant.replaceAll('-', ' ');
