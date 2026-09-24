import 'package:flutter/material.dart';

import '../../../features/pokemon/application/pokemon_workspace_controller.dart';
import '../../../features/pokemon/domain/pokemon_workspace_models.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/inputs/studio_tabs.dart';
import 'pokemon_species_overview.dart';
import 'pokemon_species_forms.dart';
import 'pokemon_species_learnset.dart';
import 'pokemon_species_evolution.dart';
import 'pokemon_species_media.dart';

class PokemonSpeciesDetail extends StatelessWidget {
  const PokemonSpeciesDetail({
    super.key,
    required this.controller,
    this.onBack,
    this.pickPng,
  });

  final PokemonWorkspaceController controller;
  final VoidCallback? onBack;
  final Future<String?> Function()? pickPng;

  @override
  Widget build(BuildContext context) {
    final draft = controller.selectedDraft;
    if (draft == null) {
      return const Center(
        child: Text('Sélectionnez une espèce pour ouvrir sa fiche.'),
      );
    }
    final species = draft.document(PokemonDocumentFamily.species)!;
    final names = (species['names'] as Map?)?.cast<String, dynamic>() ?? {};
    final name = names['fr'] ?? names['en'] ?? draft.id;
    return AbsorbPointer(
      absorbing: controller.mutationActive,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (onBack != null)
              StudioButton(
                label: 'Retour au Pokédex',
                secondary: true,
                icon: Icons.arrow_back,
                onPressed: onBack,
              ),
            Wrap(
              spacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('$name', style: Theme.of(context).textTheme.titleLarge),
                Text(
                  '#${species['nationalDex']} · ${draft.id}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (draft.dirty)
                  const Chip(label: Text('Brouillon non enregistré')),
                IconButton(
                  tooltip: 'Annuler',
                  icon: const Icon(Icons.undo),
                  onPressed: draft.canUndo ? controller.undo : null,
                ),
                IconButton(
                  tooltip: 'Rétablir',
                  icon: const Icon(Icons.redo),
                  onPressed: draft.canRedo ? controller.redo : null,
                ),
              ],
            ),
            const SizedBox(height: 12),
            StudioTabs<PokemonDetailSection>(
              items: const {
                PokemonDetailSection.overview: 'Vue d’ensemble',
                PokemonDetailSection.forms: 'Formes',
                PokemonDetailSection.learnset: 'Apprentissages',
                PokemonDetailSection.evolution: 'Évolutions',
                PokemonDetailSection.media: 'Médias',
              },
              selected: controller.section,
              onChanged: controller.setSection,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                key: PageStorageKey(
                  'pokemon-detail-${draft.id}-${controller.section.name}',
                ),
                child: switch (controller.section) {
                  PokemonDetailSection.overview => PokemonSpeciesOverview(
                    controller: controller,
                  ),
                  PokemonDetailSection.forms => PokemonSpeciesFormsEditor(
                    controller: controller,
                  ),
                  PokemonDetailSection.learnset => PokemonSpeciesLearnsetEditor(
                    controller: controller,
                  ),
                  PokemonDetailSection.evolution =>
                    PokemonSpeciesEvolutionEditor(controller: controller),
                  PokemonDetailSection.media => PokemonSpeciesMediaEditor(
                    controller: controller,
                    pickPng: pickPng,
                  ),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
