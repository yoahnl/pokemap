import 'package:flutter/material.dart';

import '../../../features/pokemon/application/pokemon_workspace_controller.dart';
import '../../../features/pokemon/domain/pokemon_workspace_models.dart';

class PokemonDetailTabs extends StatelessWidget {
  const PokemonDetailTabs({super.key, required this.controller});

  final PokemonWorkspaceController controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final (section, label) in const [
              (PokemonDetailSection.overview, 'Vue d’ensemble'),
              (PokemonDetailSection.forms, 'Formes'),
              (PokemonDetailSection.learnset, 'Apprentissages'),
              (PokemonDetailSection.evolution, 'Évolutions'),
              (PokemonDetailSection.media, 'Médias'),
            ])
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: controller.section == section
                          ? colors.primary
                          : colors.primary.withValues(alpha: 0),
                      width: 2,
                    ),
                  ),
                ),
                child: TextButton(
                  onPressed: () => controller.setSection(section),
                  child: Text(label),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
