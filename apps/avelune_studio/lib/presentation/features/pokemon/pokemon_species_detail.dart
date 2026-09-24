import 'package:flutter/material.dart';

import '../../../features/pokemon/application/pokemon_workspace_controller.dart';
import '../../../features/pokemon/domain/pokemon_workspace_models.dart';
import 'pokemon_detail_tabs.dart';
import 'pokemon_species_evolution.dart';
import 'pokemon_species_forms.dart';
import 'pokemon_species_header.dart';
import 'pokemon_species_learnset.dart';
import 'pokemon_species_media.dart';
import 'pokemon_species_overview.dart';
import 'pokemon_ui_parts.dart';

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
      return const PokemonEmptyState(
        title: 'Ouvrez une fiche',
        description:
            'Sélectionnez une espèce dans le Pokédex pour voir ses données et ses médias.',
      );
    }
    final section = switch (controller.section) {
      PokemonDetailSection.overview => PokemonSpeciesOverview(
        controller: controller,
      ),
      PokemonDetailSection.forms => PokemonSpeciesFormsEditor(
        controller: controller,
      ),
      PokemonDetailSection.learnset => PokemonSpeciesLearnsetEditor(
        controller: controller,
      ),
      PokemonDetailSection.evolution => PokemonSpeciesEvolutionEditor(
        controller: controller,
      ),
      PokemonDetailSection.media => PokemonSpeciesMediaEditor(
        controller: controller,
        pickPng: pickPng,
      ),
    };
    final tabs = PokemonDetailTabs(controller: controller);
    final pageKey = PageStorageKey(
      'pokemon-detail-${draft.id}-${controller.section.name}',
    );
    return AbsorbPointer(
      absorbing: controller.mutationActive,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: LayoutBuilder(
          builder: (context, bounds) {
            if (bounds.maxHeight < 480 ||
                MediaQuery.textScalerOf(context).scale(14) > 21) {
              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      key: pageKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          PokemonSpeciesHeader(
                            controller: controller,
                            onBack: onBack,
                            showSaveControls: false,
                          ),
                          const SizedBox(height: 10),
                          tabs,
                          const SizedBox(height: 12),
                          section,
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  PokemonSurface(
                    child: PokemonSpeciesSaveControls(controller: controller),
                  ),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PokemonSpeciesHeader(controller: controller, onBack: onBack),
                const SizedBox(height: 10),
                tabs,
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(key: pageKey, child: section),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
