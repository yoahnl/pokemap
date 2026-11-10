import 'package:flutter/material.dart';

import '../../../features/pokemon/application/pokemon_workspace_controller.dart';

import '../../../features/pokemon/domain/pokemon_workspace_models.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import 'pokemon_ui_parts.dart';
import '../../../features/pokemon/application/pokemon_species_provenance.dart';

export '../../../features/pokemon/application/pokemon_species_provenance.dart';

class PokemonSpeciesProvenance extends StatelessWidget {
  const PokemonSpeciesProvenance({super.key, required this.controller});

  final PokemonWorkspaceController controller;

  @override
  Widget build(BuildContext context) {
    final draft = controller.selectedDraft!;
    final species = draft.document(PokemonDocumentFamily.species) ?? const {};
    final version = ((species['sourceMeta'] as Map?)?['seedVersion'] as num?)
        ?.toString();
    final corrections = pokemonDraftCorrections(draft);
    return StudioPanel(
      key: const ValueKey('pokemon-species-provenance'),
      title: 'Provenance et portée',
      children: [
        PokemonDataRow(label: 'Source', value: pokemonSpeciesSource(species)),
        if (version != null)
          PokemonDataRow(label: 'Version de la source', value: version),
        PokemonDataRow(
          label: 'Corrections en attente',
          value: corrections.isEmpty
              ? 'Aucune'
              : corrections.toSet().join(', '),
        ),
        PokemonDataRow(
          label: 'Portée',
          value: pokemonSpeciesScope(
            draft.id,
            controller.combat?.snapshot?.project,
          ),
        ),
        Text(
          'Une correction enregistrée remplace la valeur importée dans les '
          'données du projet. La version importée d’origine n’est pas '
          'conservée : les champs corrigés auparavant ne sont pas listés.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
